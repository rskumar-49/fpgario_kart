`timescale 1ns / 1ps
`default_nettype none

module racer_view_tb;

    //make logics for inputs and outputs!
    logic clk_in;
    logic rst_in;
    logic [10:0] hcount_in;
    logic [9:0] vcount_in;
    logic [8:0] direction;
    logic [10:0] player_x;
    logic [10:0] player_y;
    logic [10:0] opponent_x;
    logic [10:0] opponent_y;
    logic [11:0] pixel_out;

    real pi;

    racer_view uut(.clk_in(clk_in), .rst_in(rst_in),
                         .hcount_in(hcount_in),
                         .vcount_in(vcount_in),
                         .direction(direction),
                         .player_x(player_x),
                         .player_y(player_y),
                         .opponent_x(opponent_x),
                         .opponent_y(opponent_y),
                         .pixel_out(pixel_out));
    always begin
        #10;  //every 10 ns switch...so period of clock is 20 ns...50 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("racer_view.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,racer_view_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 1; //reset system
        #20; //hold high for a few clock cycles
        rst_in=0;
        player_x = 192;
        player_y = 192;
        opponent_x = 224;
        opponent_y = 224;
        direction = 90;
        pi = 8'b11001001;
        #20;

        $display(512 * $sin(pi / (2**(6)) * 90 / 180));
        
        for (int i = 256; i < 320; i = i+1)begin
            for (int j = 640; j < 896; j = j+1) begin
                hcount_in = j;
                vcount_in = i;
                // sprite_type = 0;
                #20;
            end
        end


        #10000;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire
