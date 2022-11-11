`default_nettype none
`timescale 1ns / 1ps

//module here
module ether (
    input wire clk,
    input wire rst,
    input wire [1:0] rxd,
    input wire crsdv,

    output logic [1:0] axiod,
    output logic axiov
);
    logic reset_state;
    logic wait_state;
    logic check_rxd_state; 
    logic validate_state;
    logic transmit_state;
    logic ignore_state; 

    logic [7:0] preamble;
    logic [7:0] SFD;

    logic [15:0] counter;
    logic [32:0] total_counter;
    always_ff @(posedge clk) begin
        if (rst) begin
            reset_state <= 0;
            wait_state <= 1;
            validate_state <= 0;
            transmit_state <= 0;
            ignore_state <= 0;
            check_rxd_state <= 0;
            preamble <= 8'b01010101;
            SFD <= 8'b11010101;
            counter <= 0;
            axiov <= 0;
            total_counter <= 0;
        end else begin
            case ({reset_state, wait_state, validate_state, transmit_state, ignore_state, check_rxd_state})
                6'b010000: begin
                    if (crsdv) begin
                        check_rxd_state <= 1;
                        wait_state <= 0;
                    end
                end 
                6'b000001: begin
                    if (rxd == 2'b01) begin
                        check_rxd_state <= 0;
                        validate_state <= 1;
                        total_counter <= total_counter + 1;
                    end
                end
                6'b001000: begin
                    if ((rxd == 2'b01) && total_counter < 28) begin
                        total_counter <= total_counter + 1;
                    end else if ((rxd == 2'b01) && total_counter >= 28 && total_counter < 31) begin
                        total_counter <= total_counter + 1;
                    end else if ((rxd == 2'b11) && total_counter == 31) begin
                        total_counter <= total_counter + 1;
                    end else if (total_counter == 32) begin
                        axiod <= rxd;
                        axiov <= 1;
                        validate_state <= 0;
                        transmit_state <= 1;
                    end else begin
                        validate_state <= 0;
                        ignore_state <= 1;
                    end
                end
                6'b000100: begin
                    axiod <= rxd;
                    axiov <= 1;
                    if (~crsdv) begin
                        axiov <= 0;
                        transmit_state <= 0;
                        reset_state <= 1;
                    end
                end
                6'b100000: begin
                    counter <= 0;
                    total_counter <= 0;
                    axiov <= 0;
                    reset_state <= 0;
                    wait_state <= 1;
                end
                6'b000010: begin
                    counter <= 0;
                    total_counter <= 0;
                    axiov <= 0;
                    if (!crsdv) begin
                        ignore_state <= 0;
                        wait_state <= 1;
                    end
                end
            endcase
        end
    end

endmodule

`default_nettype wire