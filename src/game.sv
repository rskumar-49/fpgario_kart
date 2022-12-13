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
    input wire [10:0] r_opp_x,          // is this necessary
    input wire [10:0] r_opp_y,          // is this necessary
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

logic signed [10:0] p_c;
logic signed [10:0] p_s;
logic signed [10:0] o_c;
logic signed [10:0] o_s;

logic signed [11:0] i_opp_x;
logic signed [11:0] i_opp_y;
logic [8:0] opp_dir;
logic [2:0] o_game_status;
logic [2:0] o_laps;

logic signed [11:0] i_player_x;
logic signed [11:0] i_player_y;
logic [2:0] game_status;
logic [2:0] laps;

logic [10:0] speed;
assign speed = 6;

xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(11),
    .RAM_DEPTH(360),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(`FPATH(cos.mem))                    
) p_cos (
    .addra(player_direction),
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
    .addra(player_direction),
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
    //.addra(r_opp_dir),
    .addra(opp_dir),
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
    //.addra(r_opp_dir),
    .addra(opp_dir),
    .dina(11'b0),       
    .clka(clk),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(rst),
    .regcea(1'b1),
    .douta(o_s)
);

always_ff @(posedge clk) begin
    if (rst) begin
        game_state <= 0;
        game_status <= 0;
        laps <= 0;
        
        // set player and opponent to initial starting locations
        player_x <= 128;
        player_y <= 100;
        opponent_x <= 256;
        opponent_y <= 100;
        player_direction <= 0;
        opp_dir <= 0;
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
            if (r_opp_game) begin
                game_state <= 1;
                game_status <= 1;
            end

            // Check if completed lap (checks range of position (which will be in track) %% direction (to check they are going right way))
            if (~player_x == 0 && player_y && player_direction >= 0 && player_direction <= 180) begin
                laps <= laps + 1;
            end

            // win condition
            if (laps == 3) begin
                game_status <= 1; 
                game_state <= 1;
            end

            // Turning Mechanic
            if (sw[15] && ~sw[0]) begin
                if (player_direction == 359)    player_direction <= 0;
                else                            player_direction <= player_direction + 1;
            end else if (sw[0] && ~sw[15]) begin
                if (player_direction == 0)      player_direction <= 359;
                else                            player_direction <= player_direction - 1;
            end

            // Player x
            if ($signed(player_x + i_player_x) >= 1984)     player_x <= 1984;
            else if ($signed(player_x + i_player_x) <= 64)  player_x <= 64;
            else                                            player_x <= player_x + i_player_x;

            // Player y
            if ($signed(player_y + i_player_y) >= 1984)     player_y <= 1984;
            else if ($signed(player_y + i_player_y) <= 64)  player_y <= 64;
            else                                            player_y <= player_y + i_player_y;

            // Opponent x
            if ($signed(opponent_x + i_opp_x) >= 1984)      opponent_x <= 1984;
            else if ($signed(opponent_x + i_opp_x) <= 64)   opponent_x <= 64;
            else                                            opponent_x <= r_opp_x + i_opp_x;
            
            // Opponent y
            if ($signed(opponent_y + i_opp_y) >= 1984)      opponent_y <= 1984;
            else if ($signed(opponent_y + i_opp_y) <= 64)   opponent_y <= 64;
            else                                            opponent_y <= r_opp_y + i_opp_y;

            opp_dir <= r_opp_dir;
            
        end

        //Collisions
        if (hcount == 1180 && vcount == 800) begin
            // Check collisions
            if ((player_x + i_player_x + 96 >= opponent_x + i_opp_x - 96) && (player_x + i_player_x - 96 <= opponent_x + i_opp_x + 96)) begin
                if ((player_y + i_player_y + 96 >= opponent_y + i_opp_y - 96) && (player_y + i_player_y - 96 <= opponent_y + i_opp_y + 96)) begin
                    opp_dir <= player_direction;
                    player_direction <= opp_dir;
                end 
            end
        end 

        if (hcount == 1198 && vcount == 800) begin
            i_player_x <= $signed(speed) * p_c / 512;
            i_player_y <= $signed(-1 * speed) * p_s / 512;
            i_opp_x <= $signed(speed) * o_c / 512;
            i_opp_y <= $signed(-1 * speed) * o_s / 512;
        end 
    end
end
    
endmodule

`default_nettype wire