`default_nettype none
`timescale 1ns / 1ps

//module here
module transmit (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,

    output logic [1:0] axiod,
    output logic axiov,
    
);
    
endmodule

`default_nettype wire