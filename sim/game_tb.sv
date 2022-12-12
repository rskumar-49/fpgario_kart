`timescale 1ns / 1ps
`default_nettype none

module game_tb;


    logic clk;
    logic [15:0] sw; 
    logic rst;
    logic btnu;
    logic [10:0] hcount; 
    logic [9:0] vcount;
    // logic receive_axiiv;
    // logic [10:0] r_opp_x;
    // logic [10:0] r_opp_y; 
    logic [8:0] r_opp_dir;
    logic [2:0] r_opp_game;
    logic r_opp_rst;

    logic [10:0] player_x;
    logic [10:0] player_y;
    logic [8:0] player_direction;
    logic [10:0] opponent_x;
    logic [10:0] opponent_y;
    logic [2:0] game_stat;

    game uut(.clk(clk), .rst(rst),
                        .btnu(btnu),
                        .sw(sw),
                         .hcount(hcount),
                         .vcount(vcount),
                         .r_opp_dir(r_opp_dir),
                         .r_opp_rst(r_opp_rst),
                         .r_opp_game(r_opp_game),
                         .player_x(player_x),
                         .player_y(player_y),
                         .player_direction(player_direction),
                         .opponent_x(opponent_x),
                         .opponent_y(opponent_y),
                         .game_stat(game_stat));

    always begin
        #10;  //every 10 ns switch...so period of clock is 20 ns...50 MHz clock
        clk = !clk;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("game.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,game_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk = 0; //initialize clk (super important)
        rst = 1; //reset system
        #20; //hold high for a few clock cycles
        rst = 0;
        #20;

        btnu = 0;
        r_opp_dir = 0;
        r_opp_rst = 0;
        r_opp_game = 0;
        sw = 0;

        // player_x = 400;
        // player_y = 400;
        // opponent_x = 224;
        // opponent_y = 224;
        // player_direction = 90;
        // hcount = 1198;
        vcount = 800;
        #20;
        
        for (int i = 0; i < 10; i = i+1) begin
            for (int j = 1198; j < 1201; j = j+1) begin
                hcount = j;
                #20;
            end
        end

        #10000;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire
