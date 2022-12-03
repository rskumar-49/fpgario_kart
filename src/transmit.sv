`default_nettype none
`timescale 1ns / 1ps

//module here
module transmit (
    input wire eth_clk,
    input wire eth_rst,

    input wire [10:0] hcount,
    input wire [9:0] vcount, 
    input wire [10:0] player_x,
    input wire [10:0] player_y,
    input wire [8:0] direction,
    input wire [2:0] game_stat, 

    output logic [1:0] eth_txd,
    output logic eth_txen
);

//TODO: checksum, bitorder swap? 

logic [511:0] message; 
logic [511:0] buffer;
logic counter;
logic [1:0] state; 

logic [55:0] preamble;
assign preamble = 56'h55_55_55_55_55_55_55;
logic [7:0] sfd;
assign sfd = 8'b11010101;
logic [47:0] dest_addr;
assign dest_addr = 48'hFF_FF_FF_FF_FF_FF; 
logic [47:0] source_addr;
assign source_addr = 48'hFF_FF_FF_FF_FF_FF; 
logic [15:0] len;
assign len = 16'h00_00;
logic [31:0] fcs;
assign fcs = 32'hCBF43926; //needs to be determined from checksum 
logic [39:0] data;
assign data = {{player_x, 1'b0}, {player_y, 1'b0}, {direction, 3'd0}, {game_stat, 1'b0}};

assign message = {preamble, sfd, dest_addr, source_addr, len, data, 264'b0, fcs}; //, source_addr, len, message, fcs}; //263'b0, 

// Might Need this
// bitorder b1(.clk(eth_clk),
//             .rst(btnc),
//             .axiiv(eth_axiov),
//             .axiid(eth_axiod),
//             .axiod(bit_axiod),
//             .axiov(bit_axiov));

always_ff @(posedge eth_clk) begin
    if (eth_rst) begin
        counter <= 0;
        state <= 0;
    end else begin
        case (state)
            2'b00: begin
                eth_txen <= 0;
                eth_txd <= 0;
                if (hcount[10:0] == 1024 && vcount[9:0] == 768) begin
                    $displayh(message);
                    buffer <= message;
                    state <= 1;
                end
            end
            2'b01: begin
                if (buffer != 0) begin
                    eth_txen <= 1;
                    eth_txd <= buffer[511:510];
                    buffer <= {buffer[509:0], 2'b0};
                end else begin
                    state <= 0;
                    eth_txen <= 0;
                    eth_txd <= 0;
                end
            end
        endcase
        // $display(hcount);
        // $display(vcount);
        // $display(counter);
        // if (hcount[10:0] == 1024 && vcount[9:0] == 768) begin
        //     $display("in");
        //     counter <= counter + 242;
        //     buffer2 <= buffer1;
        //     $display(counter);
        // end else if (counter > 0) begin
        //     eth_txen <= 1;
        //     eth_txd <= buffer2[241:240];
        //     buffer2 <= {buffer2[239:238], 2'b0};
        //     counter <= counter - 2;
        // end else begin
        //     eth_txen <= 0;
        //     eth_txd <= 0;
        //     buffer2 <= buffer1;
        // end
    end
end
    
endmodule

`default_nettype wire