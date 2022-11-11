`default_nettype none
`timescale 1ns / 1ps

//module here
module cksum (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,

    output logic done, 
    output logic kill
);

    logic [31:0] crc_axiod;
    logic crc_axiov;
    logic crc_rst;

    crc32 c1(.clk(clk),
             .rst(crc_rst),
             .axiiv(axiiv),
             .axiid(axiid),
             .axiov(crc_axiov),
             .axiod(crc_axiod)
             );

    logic assert_s;
    logic check_s;
    logic kill_check;
    logic done_check;

    always_ff @(posedge clk) begin
        if (rst) begin
            assert_s <= 1;
            check_s <= 0;
            kill_check <= 0;
            done_check <= 0;
            crc_rst <= 1;
            done <= 0;
            kill <= 0;
        end else begin
            case ({check_s, assert_s}) 
                2'b10: begin
                    if (~axiiv) begin
                        if (crc_axiod == 32'h38_fb_22_84) begin
                            kill <= 0;
                            done <= 1;
                        end else begin
                            done <= 1;
                            kill <= 1;
                        end
                        check_s <= 0;
                        assert_s <= 1;
                        crc_rst <= 1;
                    end
                end
                2'b01: begin
                    crc_rst <= 0;
                    done <= done;
                    kill <= kill;
                    if (axiiv) begin
                        done <= 0;
                        kill <= 0;
                        assert_s <= 0;
                        check_s <= 1;
                    end
                end
            endcase
        end
    end

endmodule

`default_nettype wire