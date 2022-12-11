`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

//module here
module game (
    input wire clk,
    input wire [15:0] sw,
    input wire rst,
    input wire btnu,
    input wire [10:0] hcount, 
    input wire [9:0] vcount,
    input wire receive_axiiv,
    input wire [10:0] r_opp_x,
    input wire [10:0] r_opp_y,
    input wire [8:0] r_opp_dir,
    input wire [2:0] r_opp_game,
    input wire r_opp_rst,

    output logic [10:0] player_x,
    output logic [10:0] player_y,
    output logic [8:0] player_direction,
    output logic [10:0] opponent_x,
    output logic [10:0] opponent_y,
    output logic [2:0] game_stat
);

logic wait_state;
logic reset_state;
logic game_state; 

logic [10:0] p_c;
logic [10:0] p_s;
logic [10:0] o_c;
logic [10:0] o_s;

logic [10:0] i_opp_x;
logic [10:0] i_opp_y;
logic [8:0] opp_dir;
logic [2:0] o_game_status;
logic [2:0] o_laps;

logic [10:0] i_player_x;
logic [10:0] i_player_y;
logic [8:0] player_dir;
logic [2:0] game_status;
logic [2:0] laps;

logic [3:0] speed;
assign speed = 6;

xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(11),
    .RAM_DEPTH(360),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(`FPATH(cos.mem))                    
) p_cos (
    .addra(player_dir),
    .dina(11'b0),       
    .clka(clk),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(rst),
    .regcea(1'b1),
    .douta(p_c)
);

xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(11),
    .RAM_DEPTH(360),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(`FPATH(sin.mem))                    
) p_sin (
    .addra(player_dir),
    .dina(11'b0),       
    .clka(clk),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(rst),
    .regcea(1'b1),
    .douta(p_s)
);

xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(11),
    .RAM_DEPTH(360),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(`FPATH(cos.mem))                    
) o_cos (
    .addra(r_opp_dir),
    .dina(11'b0),       
    .clka(clk),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(rst),
    .regcea(1'b1),
    .douta(o_c)
);

xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(11),
    .RAM_DEPTH(360),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(`FPATH(sin.mem))                    
) o_sin (
    .addra(r_opp_dir),
    .dina(11'b0),       
    .clka(clk),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(rst),
    .regcea(1'b1),
    .douta(o_s)
);

always_ff @(posedge clk) begin
    if (rst || r_opp_rst) begin
        game_state <= 0;
        game_status <= 0;
        laps <= 0;
        
        // set player and opponent to initial starting locations
        player_x <= 100;
        player_y <= 100;
        opponent_x <= 300;
        opponent_y <= 100;
        player_direction <= 90;
        opp_dir <= 90;
        i_player_x <= 0;
        i_player_y <= 0;
        i_opp_x <= 0;
        i_opp_y <= 0;
    end else if (game_state) begin
        game_state <= 1;
        game_status <= 1;
    end else begin
        if (hcount == 1200 & vcount == 800) begin
            // loss condition
            if (r_opp_game == 1) begin
                game_state <= 1;
                game_status <= 1;
            end

            // Check if completed lap (checks range of position (which will be in track) %% direction (to check they are going right way))
            if ((player_x == 0 && player_y == 1) && (player_dir >= 0 && player_dir <= 180)) begin
                laps <= laps + 1;
            end

            // win condition
            if (laps == 3) begin
                game_status <= 1; 
                game_state <= 1;
            end

            // Turning Mechanic
            if ((sw[15] == 1 && sw[0] == 1) || (sw[15] == 0 && sw[0] == 0)) begin
                player_dir <= player_dir;
            end else if (sw[15] == 1) begin
                player_dir <= player_dir + 1;
                if (player_dir == 359) begin
                    player_dir <= 0;
                end
            end else if (sw[0] == 1) begin
                player_dir <= player_dir -1;
                if (player_dir == 1) begin
                    player_dir <= 360;
                end
            end

            // Player x
            if (player_x + i_player_x >= 1024 - 32) begin 
                player_x <= 1024 - 32;
            end else if (player_x + i_player_x <= 0 + 32) begin
                player_x <= 0 + 32;
            end else begin
                player_x <= player_x + i_player_x;
            end
            // Player y
            if (player_y + i_player_y >= 768 - 32) begin 
                player_y <= 768 - 32;
            end else if (player_y + i_player_y <= 0 + 32) begin
                player_y <= 0 + 32;
            end else begin
                player_y <= player_y + i_player_y;
            end

            // Opponent x
            if (opponent_x + i_opp_x >= 1024 - 32) begin 
                opponent_x <= 1024 - 32;
            end else if (opponent_x + i_opp_x <= 0 + 32) begin
                opponent_x <= 0 + 32;
            end else begin
                opponent_x <= opponent_x + i_opp_x;
            end

            // Opponent y
            if (opponent_y + i_opp_y >= 768 - 32) begin 
                opponent_y <= 768 - 32;
            end else if (opponent_y + i_opp_y <= 0 + 32) begin
                opponent_y <= 0 + 32;
            end else begin
                opponent_y <= opponent_y + i_opp_y;
            end

            player_direction <= player_dir;
        end

        //Collisions
        // if (receive_axiiv) begin
        //     // Check collision right side
        //     if (player_x + i_player_x + 32 >= opponent_x + i_opp_x - 32 && player_x + i_player_x + 32 >= opponent_x + i_opp_x - 32) begin
            
        //     end else if (player_x + i_player_x + 32 >= opponent_x + i_opp_x - 32) begin

        //     end else begin
        //         i_player_x <= $signed(speed * p_c);
        //         i_player_y <= $signed(-1 * speed * p_s);
        //         i_opp_x <= $signed(speed * o_c);
        //         i_opp_y <= $signed(-1 * speed * o_s);
        //     end
        // end 

        if (receive_axiiv) begin
            i_player_x <= $signed(speed * p_c);
            i_player_y <= $signed(-1 * speed * p_s);
            i_opp_x <= $signed(speed * o_c);
            i_opp_y <= $signed(-1 * speed * o_s);
        end
    end
end
    
endmodule

`default_nettype wire