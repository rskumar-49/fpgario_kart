`timescale 1ns / 1ps
`default_nettype none

module receive_tb;
    logic eth_clk;
    logic btnc;
    logic eth_crsdv;
    logic [1:0] eth_rxd;

    logic eth_rstn;
    logic axiov;
    logic [1:0] axiod;

    logic bit_axiiv;
    logic [1:0] bit_axiid;
    logic bit_axiov;
    logic [1:0] bit_axiod;

    logic [511:0] message = 512'h55555555555555d5ffffffffffffffffffffffff00000100102d02000000000000000000000000000000000000000000000000000000000000000000cbf43926;

    receive r1(.eth_refclk(eth_clk),
                .btnc(btnc),
                .eth_crsdv(eth_crsdv),
                .eth_rxd(eth_rxd),
                .eth_rstn(eth_rstn),
                .axiov(axiov),
                .axiod(axiod));

    bitorder b1(.clk(eth_clk),
                .rst(btnc),
                .axiiv(bit_axiiv),
                .axiid(bit_axiid),
                .axiod(bit_axiod),
                .axiov(bit_axiov));

    
    always begin
        #10;  //every 10 ns switch...so period of clock is 20 ns...50 MHz clock
        eth_clk = !eth_clk;
        // 1 clock cycle = 20
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("receive.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,receive_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        eth_clk = 0; //initialize clk (super important)
        btnc = 1; //reset system
        #20; //hold high for a few clock cycles
        btnc=0;
        eth_crsdv = 0;
        eth_rxd = 0;
        #20;

        while (message != 0) begin
            eth_crsdv = 1;
            eth_rxd = message[511:510];
            message = {message[509:0], 2'b00};
            #20;
        end

        eth_crsdv = 0;
        eth_rxd = 0;

        #40; 

        #10000;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire
