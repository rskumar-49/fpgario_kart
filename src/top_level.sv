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

    logic [9:0] blank_pipe;
    logic [9:0][10:0] hcount_pipe;
    logic [9:0][9:0] vcount_pipe;
    logic [9:0] hsync_pipe;
    logic [9:0] vsync_pipe;

    logic [11:0] pixel_out;

    logic receive_axiov;
    logic [43:0] receive_axiod;
    logic [43:0] buffer;
    logic [10:0] hcount_f;    // pixel on current line
    logic [9:0] vcount_f;     // line number

    logic r_axiov;
    logic [10:0] r_opponent_x;
    logic [10:0] r_opponent_y;
    logic [8:0] r_opponent_dir; 
    logic [2:0] r_opponent_game; 
    logic r_opponent_reset;
    assign r_opponent_x = sync_receive[43:33];
    assign r_opponent_y = sync_receive[31:21];
    assign r_opponent_dir = sync_receive[19:11];
    assign r_opponent_game = sync_receive[7:5];
    assign r_opponent_reset = sync_receive[3];
    assign r_axiov = sync_receive[44];

    logic [10:0] player_x;
    logic [10:0] player_y;
    logic [8:0] player_dir;
    logic [10:0] opponent_x;
    logic [10:0] opponent_y;
    logic [2:0] p_game_stat;

    logic clk_65mhz;

    logic [44:0] sync_receive; 

    clk_wiz_0_clk_wiz clk_maker(
        .clk_in1(clk_100mhz),
        .eth_clk(eth_refclk),
        .vga_clk(clk_65mhz));
    
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(45),
        .RAM_DEPTH(2))
    eth_buffer (
        //Write Side (50MHz)
        .addra(0),
        .clka(eth_refclk), //NEW FOR LAB 04B
        .wea(1),
        .dina({receive_axiov, receive_axiod}),
        .ena(receive_axiov),
        .regcea(1'b1),
        .rsta(btnc),
        .douta(),
        //Read Side (65 MHz)
        .addrb(0),
        .dinb(44'b0),
        .clkb(clk_65mhz),
        .web(1'b0),
        .enb(1'b1),
        .rstb(btnc),
        .regceb(1'b1),
        .doutb(sync_receive)
    );

    logic [20:0] screen_sync; 
    logic [10:0] sync_hcount; 
    assign sync_hcount = screen_sync[20:10];

    logic [9:0] sync_vcount; 
    assign sync_vcount = screen_sync[9:0];

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(21),
        .RAM_DEPTH(2))
    vga_buffer (
        //Write Side (.67MHz)
        .addra(0),
        .clka(clk_65mhz), //NEW FOR LAB 04B
        .wea(1),
        .dina({hcount, vcount}),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(btnc),
        .douta(),
        //Read Side (50 MHz)
        .addrb(0),
        .dinb(21'b0),
        .clkb(eth_refclk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(btnc),
        .regceb(1'b1),
        .doutb(screen_sync)
    );
    
    vga vga_gen(
        .pixel_clk_in(clk_65mhz),
        .hcount_out(hcount),
        .vcount_out(vcount),
        .hsync_out(hsync),
        .vsync_out(vsync),
        .blank_out(blank));

    graphics grapher(
        .clk_in(clk_65mhz),
        .rst_in(sys_rst),
        .hcount_in(hcount),
        .vcount_in(vcount),
        .player_x(player_x),
        .player_y(player_y),
        .direction(player_dir),
        .opponent_x(opponent_x),
        .opponent_y(opponent_y),
        .pixel_out(pixel_out));

    receive r1(.eth_refclk(eth_refclk),
               //.btnc(sys_rst),
               .btnc(btnu),
               .eth_crsdv(eth_crsdv),
               .eth_rxd(eth_rxd),
               .axiov(receive_axiov),
               .axiod(receive_axiod),
               .eth_rstn(eth_rstn));
    
    transmit t1(.eth_clk(eth_refclk),
                //.eth_rst(sys_rst),
                .eth_rst(btnu),
                // .hcount(hcount),
                // .vcount(vcount),
                .hcount(sync_hcount),
                .vcount(sync_vcount),
                .player_x(p_x_sync),
                .player_y(p_y_sync),
                .direction(p_dir_sync),
                .game_stat(p_game_sync),
                // .player_x(11'd191),
                // .player_y(11'd191),
                // .direction(270),
                // .game_stat(1),
                .eth_txd(eth_txd),
                .eth_txen(eth_txen));

    logic [33:0] game_out_sync;
    logic [10:0] p_x_sync;
    logic [10:0] p_y_sync;
    logic [8:0] p_dir_sync;
    logic [2:0] p_game_sync;
    assign p_x_sync = game_out_sync[33:23];
    assign p_y_sync = game_out_sync[22:12];
    assign p_dir_sync = game_out_sync[11:3];
    assign p_game_sync = game_out_sync[2:0];

    logic flag;
    always_ff @(posedge clk_65mhz) begin
        if (sys_rst) begin
            flag <= 0;
        end else begin
            if (hcount == 1250 && vcount == 850) begin
                flag <= 1;
            end else begin
                flag <= 0;
            end
        end
    end

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(34),
        .RAM_DEPTH(2))
    transmit_buffer (
        //Write Side (.67MHz)
        .addra(0),
        .clka(clk_65mhz), //NEW FOR LAB 04B
        .wea(flag),
        .dina({player_x, player_y, player_dir, p_game_stat}),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(sys_rst),
        .douta(),
        //Read Side (50 MHz)
        .addrb(0),
        .dinb(34'b0),
        .clkb(eth_refclk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb(game_out_sync)
    );

    game g1(.clk(clk_65mhz),
            .sw(sw),
            .rst(sys_rst),
            .btnu(btnu),
            .hcount(hcount),
            .vcount(vcount),
            .receive_axiiv(r_axiov),
            .r_opp_x(r_opponent_x),
            .r_opp_y(r_opponent_y),
            .r_opp_dir(r_opponent_dir),
            .r_opp_game(r_opponent_game),
            .r_opp_rst(r_opponent_reset),
            // .receive_axiiv(1),
            // .r_opp_x(100),
            // .r_opp_y(100),
            // .r_opp_dir(270),
            // .r_opp_game(1),
            // .r_opp_rst(0),
            .player_x(player_x),
            .player_y(player_y),
            .player_direction(player_dir),
            .opponent_x(opponent_x),
            .opponent_y(opponent_y),
            .game_stat(p_game_stat)
            );

    always_ff @(posedge clk_65mhz)begin

        blank_pipe[0] <= blank;
        hcount_pipe[0] <= hcount;
        vcount_pipe[0] <= vcount;
        hsync_pipe[0] <= hsync;
        vsync_pipe[0] <= vsync;

        for (int i=1; i<10; i = i+1)begin
            hcount_pipe[i] <= hcount_pipe[i-1];
            vcount_pipe[i] <= vcount_pipe[i-1];
            hsync_pipe[i] <= hsync_pipe[i-1];
            vsync_pipe[i] <= vsync_pipe[i-1];
            blank_pipe[i] <= blank_pipe[i-1];
        end
    end

    always_ff @(posedge clk_65mhz)begin
        vga_r <= ~blank_pipe[8] ? pixel_out[11:8] : 4'h0;
        vga_g <= ~blank_pipe[8] ? pixel_out[7 :4] : 4'h0;
        vga_b <= ~blank_pipe[8] ? pixel_out[3 :0] : 4'h0;
    end

    assign vga_hs = ~hsync_pipe[9];
    assign vga_vs = ~vsync_pipe[9];

    logic [2:0] receive_o_counter;

    always_ff @(posedge eth_refclk) begin
        //if (sys_rst) begin
        if (btnc) begin
            led[13:0] <= 0;
            buffer <= 0;
        end else begin 
            if (buffer != receive_axiod & receive_axiod != 0) begin
                buffer <= receive_axiod;
            end

            led[7:0] <= buffer[7:0];
        end
    end

    // add logic to formulate message 

endmodule 