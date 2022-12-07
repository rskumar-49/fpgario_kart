`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

//module here
module game (
    input wire clk,
    input wire [15:0] sw,
    input wire btnc,
    input wire btnu,
    input wire receive_axiov,
    input wire [10:0] r_opp_x,
    input wire [10:0] r_opp_y,
    input wire [8:0] r_opp_dir,
    input wire [2:0] r_opp_game,

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
        .rsta(btnc),
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
        .rsta(btnc),
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
        .rsta(btnc),
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
        .rsta(btnc),
        .regcea(1'b1),
        .douta(o_s)
    );

always_ff @(posedge clk) begin
    if (btnc) begin
        wait_state <= 1;
        reset_state <= 0;
        game_state <= 0;
        game_status <= 0;
        laps <= 0;
        
        // set player and opponent to initial starting locations
        player_x <= 100;
        player_y <= 100;
        opponent_x <= 300;
        opponent_y <= 100;
        player_dir <= 0;
        opp_dir <= 0;
        i_player_x <= 0;
        i_player_y <= 0;
        i_opp_x <= 0;
        i_opp_y <= 0;
    end else begin
        case ({wait_state, reset_state, game_state})
            3'b100: begin
                i_player_x <= 0;
                i_player_y <= 0;
                i_opp_x <= 0;
                i_opp_y <= 0;

                //might be a syncing issue here
                if (btnu) begin
                    game_status <= 1;
                end else begin
                    game_status <= 0;
                end
                if (game_status == 1 & r_opp_game == 1) begin
                    wait_state <= 0;
                    game_state <= 1;
                end
            end
            3'b001: begin
                // loss condition
                if (r_opp_game == 2) begin
                    game_state <= 0;
                    reset_state <= 1;
                end

                // Check if completed lap (checks range of position (which will be in track) %% direction (to check they are going right way))
                if ((player_x == 0 && player_y == 1) && (player_dir >= 0 && player_dir <= 180)) begin
                    laps <= laps + 1; 
                end

                // win condition
                if (laps == 3) begin
                    game_status <= 2; 
                    game_state <= 0;
                    reset_state <= 1;
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

                if (receive_axiov) begin
                    i_player_x <= speed * p_c;
                    i_player_y <= speed * p_s;
                    i_opp_x <= speed * o_c;
                    i_opp_y <= speed * o_s;
                end else begin
                    i_player_x <= 0;
                    i_player_y <= 0;
                    i_opp_x <= 0;
                    i_opp_y <= 0;
                end

                player_x <= player_x + i_player_x;
                player_y <= player_y + i_player_y;
                player_direction <= player_dir;
                opponent_x <= opponent_x + i_opp_x;
                opponent_y <= opponent_y + i_opp_y; 
            end
            3'b010: begin
                //reset everything and switch back to wait state
                // check to make sure other user has reset too
            end
        endcase
    end
end
    
endmodule

`default_nettype wire