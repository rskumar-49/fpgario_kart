`default_nettype none
`timescale 1ns / 1ps

//module here
module aggregate (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid, //only packet data and FCS are coming in;

    output logic [31:0] axiod,
    output logic axiov
);

logic load_data_s;
logic check_rest_s;
logic output_s;
logic reset_s;

logic [63:0] counter;
logic [31:0] data;

always_ff @(posedge clk) begin
    if (rst) begin
        load_data_s <= 1;
        check_rest_s <= 0;
        output_s <= 0;
        reset_s <= 0;
        counter <= 0;
        data <= 0;
        axiov <= 0;
        axiod <= 0;
    end else begin
        case ({load_data_s, check_rest_s, output_s, reset_s})
            4'b1000: begin
                if (axiiv) begin
                    counter <= counter + 1;
                    data <= {data[29:0], axiid};
                    if (counter == 15) begin
                        load_data_s <= 0;
                        check_rest_s <= 1;
                    end
                end else begin
                    counter <= 0;
                    data <= 0;
                end
            end
            4'b0100: begin
                if (axiiv) begin
                    counter <= counter + 1;
                    if (counter == 31) begin
                        axiov <= 1;
                        axiod <= data;
                        check_rest_s <= 0;
                        output_s <= 1;
                    end
                end else begin
                    counter <= 0;
                    data <= 0;
                    check_rest_s <= 0;
                    load_data_s <= 1;
                end
            end
            4'b0010: begin
                axiov <= 0;
                axiod <= 0;
                if (~axiiv) begin
                    load_data_s <= 1;
                    output_s <= 0;
                end 
            end
            4'b0001: begin
                axiov <= 0;
                axiod <= 0;
                counter <= 0;
                reset_s <= 0;
                load_data_s <= 1;
            end
        endcase
    end
end
    
endmodule

`default_nettype wire