`default_nettype none
`timescale 1ns / 1ps

//module here
module receive (
    input wire eth_refclk,
    input wire btnc,
    input wire eth_crsdv,
    input wire [1:0] eth_rxd,

    output logic eth_rstn,
    output logic axiov,
    output logic [31:0] axiod 
);

assign eth_rstn = !btnc; //just done to make sys_rst more obvious
logic done;
logic kill;

logic [1:0] eth_axiod;
logic eth_axiov;
logic eth_axiov_p;

logic bit_axiov;
logic [1:0] bit_axiod;

logic fire_axiov;
logic [1:0] fire_axiod;

logic agg_axiov;
logic [31:0] agg_axiod;
logic [31:0] buffer;

assign axiov = agg_axiov;
assign axiod = agg_axiod; 

ether e1(.clk(eth_refclk),
         .rst(btnc),
         .rxd(eth_rxd),
         .crsdv(eth_crsdv),
         .axiod(eth_axiod),
         .axiov(eth_axiov));

bitorder b1(.clk(eth_refclk),
            .rst(btnc),
            .axiiv(eth_axiov),
            .axiid(eth_axiod),
            .axiod(bit_axiod),
            .axiov(bit_axiov));

firewall f1(.clk(eth_refclk),
            .rst(btnc),
            .axiiv(bit_axiov),
            .axiid(bit_axiod),
            .axiod(fire_axiod),
            .axiov(fire_axiov));

cksum c1(.clk(eth_refclk),
         .rst(btnc),
         .axiiv(eth_axiov),
         .axiid(eth_axiod),
         .done(done),
         .kill(kill));

aggregate a1(.clk(eth_refclk),
             .rst(btnc),
             .axiiv(fire_axiov),
             .axiid(fire_axiod), //only packet data and FCS are coming in;
             .axiod(agg_axiod),
             .axiov(agg_axiov));
    
endmodule

`default_nettype wire