// `default_nettype none
// `timescale 1ns / 1ps

// //module here
// module game (
//     input wire clk,
//     input wire btnc,
//     input wire [65:0] message,  \\ this is what's coming in for the opponent 
//     input wire [10:0] hcount,
//     input wire [9:0] vcount, 

//     output logic player_x,
//     output logic player_y,
//     output logic opponnet_x,
//     output logic opponent_y,
//     output logic game_status
// );

// logic wait_state;
// logic reset_state;
// logic game_state; 

// logic prev_opponent_x;
// logic prev_opponent_y;
// logic prev_opponent_dir; 

// logic opponent_x;
// assign opponent_x = message[65:55];
// logic opponent_y;
// assign opponent_y = message[54:44];
// logic opponent_dir;
// assign opponent_x = message[43:35];

// logic opp_game_status; // 0 (000) for idle, 1 (001) for start, 2 (010) for end
// assign opp_game_status = message[34:32];

// logic game_stat;

// logic [1:0] laps;

// always_ff @(posedge clk) begin
//     if (btnc) begin
//         wait_state <= 1;
//         reset_state <= 0;
//         game_state <= 0;
//         game_stat <= 0;
//         laps <= 0;
//     end else begin
//         case {wait_state, reset_state, game_state} 
//             3'b100: begin
//                 if (forward button is pressed) begin
//                     game_stat <= 1;
//                 end else begin
//                     game_stat <= 0;
//                 end
//                 if (game_stat == 1 & opp_game_status == 1) begin //what happens if one of them let's go before this switch happens? 
//                     wait_state <= 0;
//                     game_state <= 1;
//                 end
//             end
//             3'b001: begin
//                 if (opp_game_status == 2) begin
//                     //display something about losing
//                     game_state <= 0;
//                     reset_state <= 1;
//                 end
//                 if (player_x and player_y cross finish line threshold) begin
//                     laps <= laps + 1; // only once per cross, one direction only 
//                 end
//                 if (laps == 3) begin
//                     game_stat <= 2; 
//                 end

//                 // calculation for next position
//                 // when previous != current, update current to match, won't be at 0,0 h and v but should 
//                 // still be fine? 
//             end
//             3'b010: begin
//                 //reset everything and switch back to wait state
//             end
//         endcase
//     end
// end
    
// endmodule

// `default_nettype wire