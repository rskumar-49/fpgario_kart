`timescale 1ns / 1ps
`default_nettype none

module sin_tb;

    //make logics for inputs and outputs!
    logic clk_in;
    logic rst_in;
    logic signed [10:0] num;

    real pi;

    always begin
        #10;  //every 10 ns switch...so period of clock is 20 ns...50 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("sin.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,sin_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 1; //reset system
        #20; //hold high for a few clock cycles
        rst_in=0;
        pi = 8'b11001001;
        #20;
        for (int i = 0; i < 360; i = i+1) begin
            num = 512 * $sin(pi / (2**(6)) * i / 180);
            $display("x_out=%3d     %11b", i, num);
            #20;
        end
        // $display(512 * $cos(pi / (2**(6)) * 120 / 180)); //print nice message
        // $display(num);

        #10000;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire
