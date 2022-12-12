`default_nettype none
`timescale 1ns / 1ps

//module here
module transmit (
    input wire eth_clk,
    input wire eth_rst,
    input wire sys_rst,

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

logic [1:0] bit_axiid;
logic bit_axiiv; 
logic [1:0] bit_axiod;
logic bit_axiov;

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
logic [43:0] data;
assign data = {{player_x, 1'b0}, {player_y, 1'b0}, {direction, 3'd0}, {game_stat, 1'b0}, {sys_rst, 3'b0}};

//TODO: Parsing Ethernet Data
//4096 + 1024 + 512 + 256 + 128 + 64 + 32 + 1

assign message = {preamble, sfd, dest_addr, source_addr, len, data, 260'b0, fcs}; //, source_addr, len, message, fcs}; //263'b0, 

// Might Need this
bitorder b1(.clk(eth_clk),
            .rst(eth_rst),
            .axiiv(bit_axiiv),
            .axiid(bit_axiid),
            .axiod(bit_axiod),
            .axiov(bit_axiov));

always_ff @(posedge eth_clk) begin
    if (eth_rst) begin
        counter <= 0;
        state <= 0;
        bit_axiiv <= 0;
        bit_axiid <= 0;
    end else begin
        case (state)
            2'b00: begin
                eth_txen <= 0;
                eth_txd <= 0;
                if (hcount[10:0] == 1024 && vcount[9:0] == 768) begin
                    //$displayh(message);
                    buffer <= message;
                    state <= 1;
                end
            end
            2'b01: begin
                if (buffer != 0) begin
                    bit_axiiv <= 1;
                    bit_axiid <= buffer[511:510];
                    buffer <= {buffer[509:0], 2'b0};
                end else if (buffer == 0) begin
                    bit_axiiv <= 0;
                    bit_axiid <= 0;
                end

                if (bit_axiov == 1) begin
                    eth_txen <= 1;
                    eth_txd <= bit_axiod;
                end else if (bit_axiov == 0 && buffer == 0) begin
                    state <= 0;
                    eth_txen <= 0;
                    eth_txd <= 0;
                end
            end
        endcase
    end
end
    
endmodule

`default_nettype wire