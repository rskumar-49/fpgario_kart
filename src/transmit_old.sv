// `default_nettype none
// `timescale 1ns / 1ps

// //module here
// module transmit_old (
//     input wire eth_clk,
//     input wire eth_rst,

//     input wire [10:0] hcount,
//     input wire [9:0] vcount, 
//     input wire [10:0] player_x,
//     input wire [10:0] player_y,
//     input wire [8:0] direction,
//     input wire [2:0] game_stat, 

//     output logic [1:0] eth_txd,
//     output logic eth_txen
// );

// logic [241:0] buffer1; 
// logic counter;

// logic [55:0] preamble;
// assign preamble = 56'h55_55_55_55_55_55_55;
// logic [7:0] sfd;
// assign sfd = 8'b11010101;
// logic [47:0] dest_addr;
// assign dest_addr = 48'hFF_FF_FF_FF_FF_FF; 
// logic [47:0] source_addr;
// assign source_addr = 48'hFF_FF_FF_FF_FF_FF; 
// logic [15:0] len;
// assign len = 16'h00_00;
// logic [31:0] fcs;
// assign fcs = 32'hCBF43926;
// logic [33:0] message;
// assign message = {player_x, player_y, direction, game_stat};

// assign buffer1 = {preamble, sfd, dest_addr, source_addr, len, message, fcs};

// always_ff @(posedge eth_clk) begin
//     if (eth_rst) begin
//         counter <= 0;
//     end else begin
//         if (hcount == 1024 && vcount == 768) begin
//             for (int i = 241; i > 0; i = i-1) begin
//                 eth_txen <= 1;
//                 eth_txd <= buffer1[i:i-1];
//             end
//             //counter <= 242;
//         end else if (counter > 0) begin
//             // eth_txen <= 1;
//             // eth_txd <= buffer1[endi:starti];
//             // counter <= counter - 2;
//         end else begin
//             eth_txen <= 0;
//             eth_txd <= 0;
//         end
//     end
// end
    
// endmodule

// `default_nettype wire