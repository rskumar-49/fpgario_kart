`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

module track_view (
    input wire clk_in,
    input wire rst_in,
    input wire [10:0] hcount_in,
    input wire [9:0]  vcount_in,
    input wire [3:0]  sprite_type,
    input wire [8:0]  player_x,
    input wire [8:0]  player_y,
    input wire [8:0]  opponent_x,
    input wire [8:0]  opponent_y,
    output logic [11:0] pixel_out);

    logic [9:0] sprite_addr;
    logic in_player;
    logic in_opponent;
    logic [9:0][7:0] palette_addr;
    logic [15:0][11:0] output_color;
    logic [3:0][3:0] sprite_type_pipe;

    always_ff @(posedge clk_in)begin
        for (int i = 1; i < 4; i = i+1) begin
            sprite_type_pipe[i] <= sprite_type_pipe[i-1];
        end

        if (in_player)          sprite_type_pipe[0] <= 9;
        else if (in_opponent)   sprite_type_pipe[0] <= 10;
        else                    sprite_type_pipe[0] <= sprite_type;  
    end

    assign sprite_addr = hcount_in[4:0] + 32 * vcount_in[4:0];
    assign pixel_out = output_color[sprite_type_pipe[3]-1];
    assign in_player   = (player_x   <= hcount_in && hcount_in <= player_x   + 31) && (player_y   <= vcount_in && vcount_in <= player_y + 31);
    assign in_opponent = (opponent_x <= hcount_in && hcount_in <= opponent_x + 31) && (opponent_y <= vcount_in && vcount_in <= opponent_y + 31);

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(black_square.mem))                    // Specify i1 mem file
    ) i1_black_square (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 1 && ~in_player && ~in_opponent),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[0])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(black_square_pal.mem))                        // Specify p1 mem file
    ) p1_black_square_pal (
        .addra(palette_addr[0]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[0])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(grey_square.mem))                    // Specify i2 mem file
    ) i2_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 2 && ~in_player && ~in_opponent),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[1])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(grey_square_pal.mem))                        // Specify p2 mem file
    ) p2_type (
        .addra(palette_addr[1]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 2),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[1])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                    // Specify i2 mem file
    ) i3_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 3 && ~in_player && ~in_opponent),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[2])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        // Specify p2 mem file
    ) p3_type (
        .addra(palette_addr[2]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 3),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[2])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                    // Specify i2 mem file
    ) i4_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 4 && ~in_player && ~in_opponent),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[3])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        // Specify p2 mem file
    ) p4_type (
        .addra(palette_addr[3]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 4),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[3])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                    // Specify i2 mem file
    ) i5_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 5 && ~in_player && ~in_opponent),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[4])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        // Specify p2 mem file
    ) p5_type (
        .addra(palette_addr[4]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 5),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[4])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                    // Specify i2 mem file
    ) i6_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 6 && ~in_player && ~in_opponent),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[5])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        // Specify p2 mem file
    ) p6_type (
        .addra(palette_addr[5]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 6),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[5])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                    // Specify i2 mem file
    ) i7_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 7 && ~in_player && ~in_opponent),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[6])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        // Specify p2 mem file
    ) p7_type (
        .addra(palette_addr[6]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 7),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[6])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                    // Specify i2 mem file
    ) i8_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 8 && ~in_player && ~in_opponent),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[7])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        // Specify p2 mem file
    ) p8_type (
        .addra(palette_addr[7]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 8),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[7])
    );

    /////
    /////
    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(red_square.mem))                    // Specify i2 mem file
    ) i9_mario (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(in_player),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[8])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(red_square_pal.mem))                        // Specify p2 mem file
    ) p9_mario (
        .addra(palette_addr[8]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 9),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[8])
    );

    /////
    /////
    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(red_square.mem))                    // Specify i2 mem file
    ) i10_luigi (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(in_opponent),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[9])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(red_square_pal.mem))                        // Specify p2 mem file
    ) p10_luigi (
        .addra(palette_addr[9]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 10),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[9])
    );

endmodule

`default_nettype none
