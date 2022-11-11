`default_nettype none
`timescale 1ns / 1ps

//module here
module bitorder (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,

    output logic [1:0] axiod,
    output logic axiov
);
    //read1 -> flip1 and read2 -> flip2 and output1 -> output2  
    logic read_buff1; 
    logic readout_buff1;
    logic readout_buff2;
    logic read_buff2; 

    logic [15:0] b1_count; 
    logic [15:0] b2_count;

    logic [7:0] buff1;
    logic [7:0] buff2;

    always_comb begin
        if (rst) begin
            axiov = 0;
            axiod = 0;
        end else begin
            case ({read_buff1, readout_buff1, readout_buff2, read_buff2})
                4'b1000: begin
                    axiov = 0;
                end
                4'b0100: begin
                    if (b1_count > 0) begin
                        axiov = 1;
                        if (b1_count > 3) begin
                            axiod = buff1[7:6];
                        end else if (b1_count > 2) begin
                            axiod = buff1[5:4];
                        end else if (b1_count > 1) begin
                            axiod = buff1[3:2];
                        end else if (b1_count > 0) begin
                            axiod = buff1[1:0];
                        end
                    end else begin
                        axiov = 0;
                    end
                end
                4'b0010: begin
                    if (b2_count > 0) begin
                        axiov = 1;
                        if (b2_count > 3) begin
                            axiod = buff2[7:6];
                        end else if (b2_count > 2) begin
                            axiod = buff2[5:4];
                        end else if (b2_count > 1) begin
                            axiod = buff2[3:2];
                        end else if (b2_count > 0) begin
                            axiod = buff2[1:0];
                        end
                    end else begin
                        axiov = 0;
                    end
                end
                4'b0001: begin
                    axiov = 0;
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            buff1 <= 8'd0;
            buff2 <= 8'd0;
            b1_count <= 0;
            b2_count <= 0;
            read_buff1 <= 1;
            read_buff2 <= 0;
            readout_buff1 <= 0;
            readout_buff2 <= 0;
        end else begin
            case ({read_buff1, readout_buff1, readout_buff2, read_buff2})
                4'b1000: begin
                    if (axiiv) begin
                        b1_count <= b1_count + 1;
                        if (b1_count < 1) begin
                            buff1[1:0] <= axiid; 
                        end else if (b1_count < 2) begin
                            buff1[3:2] <= axiid; 
                        end else if (b1_count < 3) begin
                            buff1[5:4] <= axiid; 
                        end else if (b1_count < 4) begin
                            buff1[7:6] <= axiid; 
                            read_buff1 <= 0;
                            readout_buff1 <= 1;
                        end
                    end else begin
                        b1_count <=0;
                        buff1 <= 8'd0;
                        buff2 <= 8'd0;
                    end
                end
                4'b0100: begin
                    if (b1_count > 0) begin
                        b1_count <= b1_count - 1;
                    end
                    if (axiiv) begin
                        b2_count <= b2_count + 1;
                        if (b2_count < 1) begin
                            buff2[1:0] <= axiid; 
                        end else if (b2_count < 2) begin
                            buff2[3:2] <= axiid; 
                        end else if (b2_count < 3) begin
                            buff2[5:4] <= axiid; 
                        end else if (b2_count < 4) begin
                            buff2[7:6] <= axiid; 
                            readout_buff1 <= 0;
                            readout_buff2 <= 1;
                        end
                    end else if (b1_count == 0 & b2_count < 3) begin
                        b2_count <= 0;
                        buff2 <= 8'd0;
                        readout_buff1 <= 0;
                        read_buff2 <= 1;
                    end else begin
                        buff2 <= 0;
                        b2_count <= 0;
                    end
                end
                4'b0010: begin
                    if (b2_count > 0) begin
                        b2_count <= b2_count - 1;
                    end
                    if (axiiv) begin
                        b1_count <= b1_count + 1;
                        if (b1_count < 1) begin
                            buff1[1:0] <= axiid; 
                        end else if (b1_count < 2) begin
                            buff1[3:2] <= axiid; 
                        end else if (b1_count < 3) begin
                            buff1[5:4] <= axiid; 
                        end else if (b1_count < 4) begin
                            buff1[7:6] <= axiid; 
                            readout_buff1 <= 1;
                            readout_buff2 <= 0;
                        end
                    end else if (b2_count == 0 & b1_count < 3) begin
                        b1_count <= 0;
                        buff1 <= 8'd0;
                        readout_buff2 <= 0;
                        read_buff1 <= 1;
                    end else begin
                        buff1 <= 0;
                        b1_count <= 0;
                    end
                end
                4'b0001: begin
                    if (axiiv) begin
                        b2_count <= b2_count + 1;
                        if (b2_count < 1) begin
                            buff2[1:0] <= axiid; 
                        end else if (b2_count < 2) begin
                            buff2[3:2] <= axiid; 
                        end else if (b2_count < 3) begin
                            buff2[5:4] <= axiid; 
                        end else if (b2_count < 4) begin
                            buff2[7:6] <= axiid; 
                            read_buff2 <= 0;
                            readout_buff2 <= 1;
                        end
                    end else begin
                        b2_count <= 0;
                        buff2 <= 8'd0;
                        buff1 <= 8'd0;
                    end
                end
            endcase
        end
    end
endmodule

`default_nettype wire