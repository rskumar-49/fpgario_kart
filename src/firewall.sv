`default_nettype none
`timescale 1ns / 1ps

//module here
module firewall (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,

    output logic [1:0] axiod,
    output logic axiov
);
    logic check_header;
    logic wait_header;
    logic output_data;
    logic ignore; 
    logic destination;

    logic [47:0] buffer;
    logic [15:0] h_counter; 

    logic [47:0] dest;
    logic [47:0] mac;

    always_comb begin
        case ({check_header, wait_header, output_data, ignore})
            4'b1000: begin
                axiov = 0;
            end
            4'b0100: begin
                axiov = 0;
            end
            4'b0010: begin
                if (axiiv) begin
                    axiod = axiid;
                    axiov = 1;
                end else begin
                    axiov = 0;
                    axiod = 0;
                end
            end
            4'b0001: begin
                axiod = 0;
                axiov = 0;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            check_header <= 1;
            output_data <= 0;
            ignore <= 0;
            wait_header <= 0;
            h_counter <= 0;
            destination <= 0;
            buffer <= 0;
            mac <= 48'h6969_5A06_5491;
            dest <= 48'hFFFF_FFFF_FFFF;
        end else begin
            case ({check_header, wait_header, output_data, ignore})
                4'b1000: begin
                    if (axiiv) begin
                        if (h_counter < 23) begin
                            h_counter <= h_counter + 1;
                            buffer <= {buffer[45:0], axiid}; 
                        end else if (h_counter < 24) begin
                            h_counter <= h_counter + 1;
                            if ({buffer[45:0], axiid} == dest | {buffer[45:0], axiid} == mac) begin
                                check_header <= 0;
                                wait_header <= 1;
                            end else begin
                                check_header <= 0;
                                ignore <= 1;
                            end
                        end
                    end else begin
                        buffer <= 0;
                        h_counter <= 0;
                    end
                end
                4'b0100: begin
                    if (axiiv) begin
                        h_counter <= h_counter + 1;
                        if (h_counter >= 55) begin
                            wait_header <= 0;
                            output_data <= 1;
                        end
                    end else begin
                        buffer <= 0;
                        h_counter <= 0;
                        check_header <= 1;
                        wait_header <= 0;
                    end
                end
                4'b0010: begin
                    if (~axiiv) begin
                        buffer <= 0;
                        h_counter <= 0;
                        output_data <= 0;
                        check_header <= 1;
                    end
                end
                4'b0001: begin
                    if (~axiiv) begin
                        buffer <= 0;
                        h_counter <= 0;
                        ignore <= 0;
                        check_header <= 1;
                    end
                end
            endcase
        end
    end
endmodule

`default_nettype wire