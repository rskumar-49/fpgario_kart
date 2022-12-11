// `timescale 1ns / 1ps
// `default_nettype none

// module game_tb;


//     logic clk;
//     logic [15:0] sw; 
//     logic btnc;
//     logic btnu;
//     logic receive_axiov;
//     logic [10:0] r_opp_x;
//     logic [10:0] r_opp_y; 
//     logic [8:0] r_opp_dir;
//     logic [2:0] r_opp_game;

//     logic [10:0] player_x;
//     logic [10:0] player_y;
//     logic [8:0] player_dir;
//     logic [10:0] opp_x;
//     logic [10:0] opp_y;
//     logic [2:0] game_status;

//     always begin
//         #10;  //every 10 ns switch...so period of clock is 20 ns...50 MHz clock
//         clk = !clk;
//     end

//     //initial block...this is our test simulation
//     initial begin
//         $dumpfile("game.vcd"); //file to store value change dump (vcd)
//         $dumpvars(0,game_tb); //store everything at the current level and below
//         $display("Starting Sim"); //print nice message
//         clk = 0; //initialize clk (super important)
//         btnc = 1; //reset system
//         #20; //hold high for a few clock cycles
//         btnc=0;
//         #20;

//         #10000;
//         $display("Finishing Sim"); //print nice message
//         $finish;

//     end
// endmodule //counter_tb

// `default_nettype wire
