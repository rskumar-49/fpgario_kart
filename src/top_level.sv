`timescale 1ns / 1ps
`default_nettype none

module top_level(
    input wire clk_100mhz, //clock @ 100 mhz
    input wire [15:0] sw, //switches
    input wire btnc, //btnc (used for reset)
    input wire btnr,

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
    assign sys_rst = btnc; //just done to make sys_rst more obvious
    //assign led = sw; //switches drive LED (change if you want)

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
    logic [3:0][11:0] pixel_out_track_pipe;
    logic [11:0] pixel_out_racer;
    logic [11:0] pixel_out_racer_pipe;
    logic [11:0] pixel_out_forward;

    logic receive_axiov;
    logic [43:0] receive_axiod;
    logic [43:0] buffer;
    logic [10:0] hcount_f;    // pixel on current line
    logic [9:0] vcount_f;     // line number

    logic [10:0] opponent_x;
    logic [10:0] opponent_y;
    logic [8:0] opponent_dir; 
    logic [2:0] opponent_game; 
    logic opponent_reset;

    assign opponent_x = receive_axiod[43:33];
    assign opponent_y = receive_axiod[31:21];
    assign opponent_dir = receive_axiod[19:11];
    assign opponent_game = receive_axiod[7:5];
    assign opponent_reset = receive_axiod[3];

    logic clk_65mhz;

    clk_wiz_0_clk_wiz clk_maker(
        .clk_in1(clk_100mhz),
        .eth_clk(eth_refclk),
        .vga_clk(clk_65mhz));
    
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

    forward_view forward_viewer(
        .clk_in(clk_65mhz),
        .rst_in(sys_rst),
        .hcount_in(hcount),
        .vcount_in(vcount),
        .player_x(11'd1372),
        .player_y(11'd191),
        .direction(270),
        .opponent_x(11'd1500),
        .opponent_y(11'd191),
        .pixel_out(pixel_out_forward));

    receive r1(.eth_refclk(eth_refclk),
               .btnc(btnc),
               .eth_crsdv(eth_crsdv),
               .eth_rxd(eth_rxd),
               .axiov(receive_axiov),
               .axiod(receive_axiod),
               .eth_rstn(eth_rstn));
    
    transmit t1(.eth_clk(eth_refclk),
                .eth_rst(btnc),
                .hcount(hcount_f),
                .vcount(vcount_f),
                .player_x(11'd191),
                .player_y(11'd191),
                .direction(270),
                .game_stat(1),
                .eth_txd(eth_txd),
                .eth_txen(eth_txen));

    always_ff @(posedge clk_65mhz)begin

        blank_pipe[0] <= blank;
        hcount_pipe[0] <= hcount;
        vcount_pipe[0] <= vcount;
        hsync_pipe[0] <= hsync;
        vsync_pipe[0] <= vsync;

        pixel_out_track_pipe[0] <= pixel_out_track;
        pixel_out_track_pipe[1] <= pixel_out_track_pipe[0];
        pixel_out_track_pipe[2] <= pixel_out_track_pipe[1];
        pixel_out_track_pipe[3] <= pixel_out_track_pipe[2];

        pixel_out_racer_pipe <= pixel_out_racer;

        for (int i=1; i<9; i = i+1)begin
            hcount_pipe[i] <= hcount_pipe[i-1];
            vcount_pipe[i] <= vcount_pipe[i-1];
            hsync_pipe[i] <= hsync_pipe[i-1];
            vsync_pipe[i] <= vsync_pipe[i-1];
            blank_pipe[i] <= blank_pipe[i-1];
        end
    end

    always_ff @(posedge clk_65mhz)begin
        vga_r <= ~blank_pipe[7] ? (hcount_pipe[7] < 512 ? (vcount_pipe[7] < 512 ? pixel_out_track_pipe[3][11:8] : 4'h0) : (vcount_pipe[7] < 384 ? pixel_out_racer_pipe[11:8] : (vcount_pipe[5] < 512 ? 4'h0 : pixel_out_forward[11:8]))) : 4'h0;
        vga_g <= ~blank_pipe[7] ? (hcount_pipe[7] < 512 ? (vcount_pipe[7] < 512 ? pixel_out_track_pipe[3][7 :4] : 4'h0) : (vcount_pipe[7] < 384 ? pixel_out_racer_pipe[7 :4] : (vcount_pipe[5] < 512 ? 4'h0 : pixel_out_forward[7: 4]))) : 4'h0;
        vga_b <= ~blank_pipe[7] ? (hcount_pipe[7] < 512 ? (vcount_pipe[7] < 512 ? pixel_out_track_pipe[3][3 :0] : 4'h0) : (vcount_pipe[7] < 384 ? pixel_out_racer_pipe[3 :0] : (vcount_pipe[5] < 512 ? 4'h0 : pixel_out_forward[3: 0]))) : 4'h0;
    end

    assign vga_hs = ~hsync_pipe[8];
    assign vga_vs = ~vsync_pipe[8];

    always_ff @(posedge eth_refclk) begin
        if (btnc || opponent_reset) begin
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