`timescale 1ns / 1ps
`default_nettype none

module graphics (
    input wire clk_in,
    input wire rst_in,
    input wire [10:0] hcount_in,
    input wire [9:0]  vcount_in,
    input wire [8:0]  direction,
    input wire [10:0]  player_x,
    input wire [10:0]  player_y,
    input wire [10:0]  opponent_x,
    input wire [10:0]  opponent_y,
    output logic [11:0] pixel_out);


    logic [11:0] pixel_out_track;
    logic [3:0][11:0] pixel_out_track_pipe;
    logic [11:0] pixel_out_racer;
    logic [11:0] pixel_out_racer_pipe;
    logic [11:0] pixel_out_forward;

    logic [8:0][10:0] hcount_pipe;
    logic [8:0][9:0] vcount_pipe;


    track_view track_viewer(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .hcount_in(hcount_in),
        .vcount_in(vcount_in),
        .player_x(player_x),
        .player_y(player_y),
        .opponent_x(opponent_x),
        .opponent_y(opponent_y),
        .pixel_out(pixel_out_track));

    racer_view racer_viewer(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .hcount_in(hcount_in),
        .vcount_in(vcount_in),
        .player_x(player_x),
        .player_y(player_y),
        .direction(direction),
        .opponent_x(opponent_x),
        .opponent_y(opponent_y),
        .pixel_out(pixel_out_racer));

    forward_view forward_viewer(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .hcount_in(hcount_in),
        .vcount_in(vcount_in),
        .player_x(player_x),
        .player_y(player_y),
        .direction(direction),
        .opponent_x(opponent_x),
        .opponent_y(opponent_y),
        .pixel_out(pixel_out_forward));


    always_ff @(posedge clk_in)begin

        pixel_out_track_pipe[0] <= pixel_out_track;
        pixel_out_track_pipe[1] <= pixel_out_track_pipe[0];
        pixel_out_track_pipe[2] <= pixel_out_track_pipe[1];
        pixel_out_track_pipe[3] <= pixel_out_track_pipe[2];

        pixel_out_racer_pipe <= pixel_out_racer;

        hcount_pipe[0] <= hcount_in;
        vcount_pipe[0] <= vcount_in;

        for (int i=1; i<9; i = i+1)begin
            hcount_pipe[i] <= hcount_pipe[i-1];
            vcount_pipe[i] <= vcount_pipe[i-1];
        end

        pixel_out <= hcount_pipe[7] < 512 ? (vcount_pipe[7] < 512 ? pixel_out_track_pipe[3] : 12'h0) : (vcount_pipe[7] < 384 ? pixel_out_racer_pipe : (vcount_pipe[5] < 512 ? 12'h0 : pixel_out_forward));
    end

endmodule

`default_nettype none