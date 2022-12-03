`timescale 1ns / 1ps
`default_nettype none

module transmit_tb;
    logic eth_clk;
    logic eth_rst;

    logic [10:0] hcount;
    logic [9:0] vcount;
    logic [10:0] player_x;
    logic [10:0] player_y;
    logic [8:0] dir;
    logic [2:0] game_stat; 

    logic [1:0] eth_txd;
    logic eth_txen;

    transmit t1(.eth_clk(eth_clk),
                .eth_rst(eth_rst),
                .hcount(hcount),
                .vcount(vcount),
                .player_x(player_x),
                .player_y(player_y),
                .direction(dir),
                .game_stat(game_stat),
                .eth_txd(eth_txd),
                .eth_txen(eth_txen));

    
    always begin
        #10;  //every 10 ns switch...so period of clock is 20 ns...50 MHz clock
        eth_clk = !eth_clk;
        // 1 clock cycle = 20
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("transmit.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,transmit_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        eth_clk = 0; //initialize clk (super important)
        eth_rst = 1; //reset system
        #20; //hold high for a few clock cycles
        eth_rst=0;
        hcount=0;
        vcount=0;
        player_x = 8;
        player_y = 8;
        dir = 90;
        game_stat = 1;
        #20;

        hcount = 1024;
        vcount = 768;
        #20;

        hcount = 0;
        vcount = 0;

        #40; 
        hcount = 1024;
        vcount = 768;

        #10000;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire
