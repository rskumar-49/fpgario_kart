`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

module racer_view (
    input wire clk_in,
    input wire rst_in,
    input wire [10:0] hcount_in,
    input wire [9:0]  vcount_in,
    input wire [8:0]  direction,
    input wire [10:0]  player_x,
    input wire [10:0]  player_y,
    input wire [10:0]  opponent_x,
    input wire [10:0]  opponent_y,
    output logic [11:0] pixel_out);

    // Edit this to only act if hcount_in is between 512 and 1023, and vcount is between 0 and 511
    // Edit this to enable displaying opponents
    // Note, 0 degrees is up vertically (with vcount decreasing)

    logic in_player;
    logic [1:0] in_player_pipe;
    logic [9:0] player_addr;
    logic [1:0][9:0] player_addr_pipe;

    logic in_opponent;
    logic [1:0] in_opponent_pipe;
    logic [9:0] opponent_addr;
    logic [1:0][9:0] opponent_addr_pipe;

    logic [7:0] track_addr;

    logic [9:0] sprite_addr;
    logic [1:0][9:0] sprite_addr_pipe;

    logic [9:0][7:0] palette_addr;
    logic [15:0][11:0] output_color;
    logic [3:0] sprite_type;
    logic [3:0][3:0] sprite_type_pipe;

    real pi = 8'b11001001;
    logic signed [10:0] cos;
    logic signed [10:0] sin;
    logic signed [21:0] delta_x;
    logic signed [1:0][21:0] delta_x_pipe;
    logic signed [21:0] delta_y;
    logic signed [1:0][21:0] delta_y_pipe;
    logic signed [11:0] loc_x;
    logic signed [11:0] loc_y;

    assign delta_x = $signed(767 - hcount_in);
    assign delta_y = $signed(383 - vcount_in);

    assign loc_x = $signed($signed(delta_x_pipe[1]) * cos - $signed(delta_y_pipe[1]) * sin) / 512 + player_x;
    assign loc_y = $signed($signed(delta_x_pipe[1]) * sin + $signed(delta_y_pipe[1]) * cos) / 512 + player_y;

    always_ff @(posedge clk_in)begin

        if (in_player)          sprite_type_pipe[0] <= 8;
        else if (in_opponent)   sprite_type_pipe[0] <= 9;
        else                    sprite_type_pipe[0] <= sprite_type;  

        in_player_pipe[0] <= in_player;
        in_player_pipe[1] <= in_player_pipe[0];

        player_addr_pipe[0] <= player_addr;
        player_addr_pipe[1] <= player_addr_pipe[0];

        in_opponent_pipe[0] <= in_opponent;
        in_opponent_pipe[1] <= in_opponent_pipe[0];

        opponent_addr_pipe[0] <= opponent_addr;
        opponent_addr_pipe[1] <= opponent_addr_pipe[0];

        sprite_addr_pipe[0] <= sprite_addr;
        sprite_addr_pipe[1] <= sprite_addr_pipe[0];

        delta_y_pipe[0] <= delta_y;
        delta_y_pipe[1] <= delta_y_pipe[0];

        delta_x_pipe[0] <= delta_x;
        delta_x_pipe[1] <= delta_x_pipe[0];

        for (int i = 1; i < 4; i = i+1) begin
            sprite_type_pipe[i] <= sprite_type_pipe[i-1];
        end
    end


    assign in_player   = (hcount_in >= 704  && hcount_in <= 831) && (vcount_in >= 320 && vcount_in <= 447);
    assign player_addr = {(vcount_in[6:0] - 7'h64) >> 2, (hcount_in[6:0] - 7'h64) >> 2};
    assign in_opponent = 0;
    assign opponent_addr = 0;

    assign track_addr  = {loc_y[11] == 1 ? 4'b0 : loc_y[10:7], loc_x[11] == 1 ? 4'b0 : loc_x[10:7]};
    // The sprite address doesn't use the lowest two bits because our images are 32 by 32.
    assign sprite_addr = {loc_y[6:2], loc_x[6:2]};
    assign pixel_out = output_color[sprite_type_pipe[3]];

    
    // Track BRAM

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(4),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(track.mem))                    // Specify track mem file
    ) track (
        .addra(track_addr),
        .dina(4'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(sprite_type)
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(11),
        .RAM_DEPTH(360),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(cos.mem))                    // Specify track mem file
    ) cosine (
        .addra(direction),
        .dina(11'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(cos)
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(11),
        .RAM_DEPTH(360),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(sin.mem))                    // Specify track mem file
    ) sine (
        .addra(direction),
        .dina(11'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(sin)
    );

    // Normal Sprites
    
    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(black_square.mem))
    ) i0_type (
        .addra(sprite_addr_pipe[1]),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 0 && ~in_player_pipe[1] && ~in_opponent_pipe[1]),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[0])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(black_square_pal.mem))
    ) p0_black_square_pal (
        .addra(palette_addr[0]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 0),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[0])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(grey_square.mem))
    ) i1_type (
        .addra(sprite_addr_pipe[1]),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 1 && ~in_player_pipe[1] && ~in_opponent_pipe[1]),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[1])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(grey_square_pal.mem))
    ) p1_type (
        .addra(palette_addr[1]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 1),
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
    ) i2_type (
        .addra(sprite_addr_pipe[1]),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 2 && ~in_player_pipe[1] && ~in_opponent_pipe[1]),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[2])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        // Specify p2 mem file
    ) p2_type (
        .addra(palette_addr[2]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 2),
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
    ) i3_type (
        .addra(sprite_addr_pipe[1]),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 3 && ~in_player_pipe[1] && ~in_opponent_pipe[1]),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[3])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        // Specify p2 mem file
    ) p3_type (
        .addra(palette_addr[3]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 3),
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
    ) i4_type (
        .addra(sprite_addr_pipe[1]),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 4 && ~in_player_pipe[1] && ~in_opponent_pipe[1]),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[4])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        // Specify p2 mem file
    ) p4_type (
        .addra(palette_addr[4]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 4),
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
    ) i5_type (
        .addra(sprite_addr_pipe[1]),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 5 && ~in_player_pipe[1] && ~in_opponent_pipe[1]),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[5])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        // Specify p2 mem file
    ) p5_type (
        .addra(palette_addr[5]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 5),
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
    ) i6_type (
        .addra(sprite_addr_pipe[1]),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 6 && ~in_player_pipe[1] && ~in_opponent_pipe[1]),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[6])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        // Specify p2 mem file
    ) p6_type (
        .addra(palette_addr[6]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 6),
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
    ) i7_type (
        .addra(sprite_addr_pipe[1]),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 7 && ~in_player_pipe[1] && ~in_opponent_pipe[1]),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[7])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        // Specify p2 mem file
    ) p7_type (
        .addra(palette_addr[7]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 7),
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
    ) i8_mario (
        .addra(player_addr_pipe[1]),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(in_player_pipe[1]),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[8])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(red_square_pal.mem))                        // Specify p2 mem file
    ) p8_mario (
        .addra(palette_addr[8]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 8),
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
    ) i9_luigi (
        .addra(opponent_addr_pipe[1]),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(in_opponent_pipe[1]),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[9])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(red_square_pal.mem))                        // Specify p2 mem file
    ) p9_luigi (
        .addra(palette_addr[9]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type_pipe[1] == 9),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[9])
    );

endmodule

`default_nettype none
