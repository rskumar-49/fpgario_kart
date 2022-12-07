`timescale 1ns / 1ps
`default_nettype none

module top_level(
    input wire clk_100mhz, //clock @ 100 mhz
    input wire [15:0] sw, //switches
    input wire btnc, //btnc (used for reset)
    input wire btnr,
    input wire btnu,

    //ethernet things
    input wire eth_crsdv,
    input wire [1:0] eth_rxd,
    output logic eth_txen,
    output logic [1:0] eth_txd,
    output logic eth_rstn,
    output logic eth_refclk,

    output logic [15:0] led, //just here for the funs

    output logic [3:0] vga_r, vga_g, vga_b,
    output logic vga_hs, vga_vs,
    output logic [7:0] an,
    output logic caa,cab,cac,cad,cae,caf,cag
    );

    logic sys_rst; //global system reset
    assign sys_rst = btnc || r_opponent_reset; //just done to make sys_rst more obvious
    //assign led = sw; //switches drive LED (change if you want)

    //vga module generation signals:
    logic [10:0] hcount;    // pixel on current line
    logic [9:0] vcount;     // line number
    logic hsync, vsync, blank; //control signals for vga

    logic [6:0] blank_pipe;
    logic [6:0][10:0] hcount_pipe;
    logic [6:0][9:0] vcount_pipe;
    logic [6:0] hsync_pipe;
    logic [6:0] vsync_pipe;

    logic [11:0] pixel_out_track;
    logic [1:0][11:0] pixel_out_track_pipe;
    logic [11:0] pixel_out_racer;
    logic [1:0][11:0] pixel_out_racer_pipe;
    logic [11:0] pixel_out_forward;

    logic receive_axiov;
    logic [43:0] receive_axiod;
    logic [43:0] buffer;
    logic [10:0] hcount_f;    // pixel on current line
    logic [9:0] vcount_f;     // line number

    logic [10:0] r_opponent_x;
    logic [10:0] r_opponent_y;
    logic [8:0] r_opponent_dir; 
    logic [2:0] r_opponent_game; 
    logic r_opponent_reset;
    assign r_opponent_x = receive_axiod[43:33];
    assign r_opponent_y = receive_axiod[31:21];
    assign r_opponent_dir = receive_axiod[19:11];
    assign r_opponent_game = receive_axiod[7:5];
    assign r_opponent_reset = receive_axiod[3];

    logic [10:0] player_x;
    logic [10:0] player_y;
    logic [8:0] player_dir;
    logic [10:0] opponent_x;
    logic [10:0] opponent_y;
    logic [2:0] p_game_stat;

    logic clk_65mhz;

    divider clk_gen1(
        .clk(clk_100mhz),
        .ethclk(eth_refclk));

    // clk_wiz_lab3 clk_gen(
    //     .clk_in1(clk_100mhz),
    //     .clk_out1(clk_65mhz));
    
    vga vga_gen(
        .pixel_clk_in(eth_refclk),
        .hcount_out(hcount),
        .vcount_out(vcount),
        .hsync_out(hsync),
        .vsync_out(vsync),
        .blank_out(blank));

    track_view track_viewer(
        .clk_in(eth_refclk),
        .rst_in(sys_rst),
        .hcount_in(hcount),
        .vcount_in(vcount),
        .player_x(player_x),
        .player_y(player_y),
        .opponent_x(opponent_x),
        .opponent_y(opponent_y),
        .pixel_out(pixel_out_track));

    racer_view racer_viewer(
        .clk_in(eth_refclk),
        .rst_in(sys_rst),
        .hcount_in(hcount),
        .vcount_in(vcount),
        .player_x(player_x),
        .player_y(player_y),
        .direction(player_dir),
        .opponent_x(opponent_x),
        .opponent_y(opponent_y),
        .pixel_out(pixel_out_racer));

    forward_view forward_viewer(
        .clk_in(eth_refclk),
        .rst_in(sys_rst),
        .hcount_in(hcount),
        .vcount_in(vcount),
        .player_x(player_x),
        .player_y(player_y),
        .direction(player_dir),
        .opponent_x(opponent_x),
        .opponent_y(opponent_y),
        .pixel_out(pixel_out_forward));

    receive r1(.eth_refclk(eth_refclk),
               .btnc(sys_rst),
               .eth_crsdv(eth_crsdv),
               .eth_rxd(eth_rxd),
               .axiov(receive_axiov),
               .axiod(receive_axiod),
               .eth_rstn(eth_rstn));
    
    transmit t1(.eth_clk(eth_refclk),
                .eth_rst(sys_rst),
                .hcount(hcount_f),
                .vcount(vcount_f),
                .player_x(player_x),
                .player_y(player_x),
                .direction(player_dir),
                .game_stat(p_game_stat),
                .eth_txd(eth_txd),
                .eth_txen(eth_txen));

    game g1(.clk(eth_refclk),
            .sw(sw),
            .btnc(sys_rst),
            .btnu(btnu),
            .receive_axiov(receive_axiov),
            .r_opp_x(r_opponent_x),
            .r_opp_y(r_opponent_y),
            .r_opp_dir(r_opponent_dir),
            .r_opp_game(r_opponent_game),
            .player_x(player_x),
            .player_y(player_y),
            .player_direction(player_dir),
            .opponent_x(opponent_x),
            .opponent_y(opponent_y),
            .game_stat(p_game_stat)
            );

    always_ff @(posedge eth_refclk)begin

        blank_pipe[0] <= blank;
        hcount_pipe[0] <= hcount;
        vcount_pipe[0] <= vcount;
        hsync_pipe[0] <= hsync;
        vsync_pipe[0] <= vsync;

        for (int i=1; i<7; i = i+1)begin
            hcount_pipe[i] <= hcount_pipe[i-1];
            vcount_pipe[i] <= vcount_pipe[i-1];
            hsync_pipe[i] <= hsync_pipe[i-1];
            vsync_pipe[i] <= vsync_pipe[i-1];
            blank_pipe[i] <= blank_pipe[i-1];
        end
    end

    always_ff @(posedge clk_65mhz)begin
        vga_r <= ~blank_pipe[5] ? (hcount_pipe[5] < 512 ? (vcount_pipe[5] < 512 ? pixel_out_track[11:8] : 4'h0) : (vcount_pipe[5] < 384 ? pixel_out_racer[11:8] : pixel_out_forward[11:8])) : 4'h0;     //TODO: needs to use pipelined signal (PS6)      /////
        vga_g <= ~blank_pipe[5] ? (hcount_pipe[5] < 512 ? (vcount_pipe[5] < 512 ? pixel_out_track[7 :4] : 4'h0) : (vcount_pipe[5] < 384 ? pixel_out_racer[7 :4] : pixel_out_forward[7 :4])) : 4'h0;      //TODO: needs to use pipelined signal (PS6)      /////
        vga_b <= ~blank_pipe[5] ? (hcount_pipe[5] < 512 ? (vcount_pipe[5] < 512 ? pixel_out_track[3 :0] : 4'h0) : (vcount_pipe[5] < 384 ? pixel_out_racer[3 :0] : pixel_out_forward[3 :0])) : 4'h0;      //TODO: needs to use pipelined signal (PS6)      /////
    end

    assign vga_hs = ~hsync_pipe[6];  //TODO: needs to use pipelined signal (PS7)                  /////
    assign vga_vs = ~vsync_pipe[6];  //TODO: needs to use pipelined signal (PS7)                  /////

    always_ff @(posedge eth_refclk) begin
        if (sys_rst) begin
            led[13:0] <= 0;
            buffer <= 0;
            hcount_f <= 0;
            vcount_f <= 0;
        end else begin 
            if (btnr) begin
                hcount_f <= 1024;
                vcount_f <= 768;
            end

            if (buffer != receive_axiod & receive_axiod != 0) begin
                buffer <= receive_axiod;
            end

            led[15:0] <= buffer[31:16];
        end
    end

    // add logic to formulate message 

endmodule 