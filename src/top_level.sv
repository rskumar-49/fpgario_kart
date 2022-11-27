`timescale 1ns / 1ps
`default_nettype none

module top_level(
    input wire clk_100mhz, //clock @ 100 mhz
    input wire [15:0] sw, //switches
    input wire btnc, //btnc (used for reset)

    output logic [15:0] led, //just here for the funs

    output logic [3:0] vga_r, vga_g, vga_b,
    output logic vga_hs, vga_vs,
    output logic [7:0] an,
    output logic caa,cab,cac,cad,cae,caf,cag

    );

    logic sys_rst; //global system reset
    assign sys_rst = btnc; //just done to make sys_rst more obvious
    assign led = sw; //switches drive LED (change if you want)

    //vga module generation signals:
    logic [10:0] hcount;    // pixel on current line
    logic [9:0] vcount;     // line number
    logic hsync, vsync, blank; //control signals for vga

    logic [8:0] blank_pipe;
    logic [8:0][10:0] hcount_pipe;
    logic [8:0][9:0] vcount_pipe;
    logic [8:0] hsync_pipe;
    logic [8:0] vsync_pipe;

    logic [11:0] pixel_out_track;
    logic [1:0][11:0] pixel_out_track_pipe;
    logic [11:0] pixel_out_racer;

    logic clk_65mhz;

    clk_wiz_lab3 clk_gen(
        .clk_in1(clk_100mhz),
        .clk_out1(clk_65mhz));
    
    vga vga_gen(
        .pixel_clk_in(clk_65mhz),
        .hcount_out(hcount),
        .vcount_out(vcount),
        .hsync_out(hsync),
        .vsync_out(vsync),
        .blank_out(blank));

    track_view track_viewer(
        .clk_in(clk_65mhz),
        .rst_in(sys_rst),
        .hcount_in(hcount),
        .vcount_in(vcount),
        .player_x(11'd191),
        .player_y(11'd191),
        .opponent_x(11'd319),
        .opponent_y(11'd319),
        .pixel_out(pixel_out_track));

    racer_view racer_viewer(
        .clk_in(clk_65mhz),
        .rst_in(sys_rst),
        .hcount_in(hcount),
        .vcount_in(vcount),
        .player_x(11'd191),
        .player_y(11'd191),
        .direction(270),
        .opponent_x(11'd320),
        .opponent_y(11'd320),
        .pixel_out(pixel_out_racer));

    always_ff @(posedge clk_65mhz)begin

        blank_pipe[0] <= blank;
        hcount_pipe[0] <= hcount;
        vcount_pipe[0] <= vcount;
        hsync_pipe[0] <= hsync;
        vsync_pipe[0] <= vsync;

        pixel_out_track_pipe[0] <= pixel_out_track;
        pixel_out_track_pipe[1] <= pixel_out_track_pipe[0];

        for (int i=1; i<9; i = i+1)begin
            hcount_pipe[i] <= hcount_pipe[i-1];
            vcount_pipe[i] <= vcount_pipe[i-1];
            hsync_pipe[i] <= hsync_pipe[i-1];
            vsync_pipe[i] <= vsync_pipe[i-1];
            blank_pipe[i] <= blank_pipe[i-1];
        end
    end

    always_ff @(posedge clk_65mhz)begin
        vga_r <= ~blank_pipe[7] ? (vcount_pipe[7] < 512 ? (hcount_pipe[7] >= 512 ? (vcount_pipe[7] < 384 ? pixel_out_racer[11:8] : 4'h0) : pixel_out_track_pipe[1][11:8]) : 4'h0) : 4'h0;     //TODO: needs to use pipelined signal (PS6)      /////
        vga_g <= ~blank_pipe[7] ? (vcount_pipe[7] < 512 ? (hcount_pipe[7] >= 512 ? (vcount_pipe[7] < 384 ? pixel_out_racer[7 :4] : 4'h0) : pixel_out_track_pipe[1][7: 4]) : 4'h0) : 4'h0;      //TODO: needs to use pipelined signal (PS6)      /////
        vga_b <= ~blank_pipe[7] ? (vcount_pipe[7] < 512 ? (hcount_pipe[7] >= 512 ? (vcount_pipe[7] < 384 ? pixel_out_racer[3 :0] : 4'h0) : pixel_out_track_pipe[1][3: 0]) : 4'h0) : 4'h0;      //TODO: needs to use pipelined signal (PS6)      /////
    end

    assign vga_hs = ~hsync_pipe[7];  //TODO: needs to use pipelined signal (PS7)                  /////
    assign vga_vs = ~vsync_pipe[7];  //TODO: needs to use pipelined signal (PS7)                  /////

endmodule 