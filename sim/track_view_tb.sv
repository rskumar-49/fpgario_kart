`timescale 1ns / 1ps
`default_nettype none

module track_view_tb;

    //make logics for inputs and outputs!
    logic clk_in;
    logic rst_in;
    logic [10:0] hcount_in;
    logic [9:0] vcount_in;
    logic [3:0] sprite_type;
    logic [8:0] player_x;
    logic [8:0] player_y;
    logic [8:0] opponent_x;
    logic [8:0] opponent_y;
    logic [11:0] pixel_out;

    track_view uut(.clk_in(clk_in), .rst_in(rst_in),
                         .hcount_in(hcount_in),
                         .vcount_in(vcount_in),
                         .sprite_type(sprite_type),
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
        $dumpfile("track_view.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,track_view_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 1; //reset system
        #20; //hold high for a few clock cycles
        rst_in=0;
        player_x = 0;
        player_y = 0;
        opponent_x = 40;
        opponent_y = 40;
        #20;
        
        for (int i = 0; i < 80; i = i+1)begin
            for (int j = 0; j < 80; j = j+1) begin
                hcount_in = i;
                vcount_in = j;
                sprite_type = 1;
                #20;
            end
        end


        #10000;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire
