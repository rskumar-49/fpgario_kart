`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

module forward_view (
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

    // Note, 0 degrees is normal to the right and going counterclockwise.

    logic in_player;
    logic in_opponent;
    logic [3:0] in_player_pipe;
    logic [3:0] in_opponent_pipe;
    
    logic [3:0] sprite_type;
    logic [9:0] player_addr;
    logic [9:0] opponent_addr;
    logic [9:0] sprite_addr;
    logic [1:0][3:0] sprite_type_pipe;
    logic [1:0][9:0] player_addr_pipe;

    logic signed [10:0] cos;
    logic signed [10:0] sin;
    logic signed [11:0] loc_x;
    logic signed [11:0] loc_y;

    logic [7:0] track_addr;
    logic [9:0][7:0] palette_addr;
    logic [15:0][11:0] output_color;

    logic signed [21:0] conv_x;
    logic signed [21:0] conv_y;
    logic signed [12:0] log;

    logic [1:0][9:0]  vcount_pipe;
    logic [1:0][10:0] hcount_pipe;

    always_ff @(posedge clk_in)begin

        sprite_type_pipe[0] <= sprite_type;  

        if (in_player_pipe[3]) begin
            if (output_color[8] == 12'h406) pixel_out <= output_color[sprite_type_pipe[1]];
            else pixel_out <= output_color[8];
        end else if (in_opponent_pipe[3]) begin
            if (output_color[9] == 12'h406) pixel_out <= output_color[sprite_type_pipe[1]];
            else pixel_out <= output_color[9];
        end else pixel_out <= output_color[sprite_type_pipe[1]];
    
        conv_y <= $signed(1056 - log / 4);
        conv_x <= $signed(767 - hcount_pipe[1]) * conv_y / 256;

        loc_x <= $signed(-1 * conv_x * sin + conv_y * cos) / 512 + player_x;
        loc_y <= $signed(-1 * conv_x * cos - conv_y * sin) / 512 + player_y;

        in_player_pipe[0] <= in_player;
        in_player_pipe[1] <= in_player_pipe[0];
        in_player_pipe[2] <= in_player_pipe[1];
        in_player_pipe[3] <= in_player_pipe[2];

        player_addr_pipe[0] <= player_addr;
        player_addr_pipe[1] <= player_addr_pipe[0];

        in_opponent_pipe[0] <= in_opponent;
        in_opponent_pipe[1] <= in_opponent_pipe[0];
        in_opponent_pipe[2] <= in_opponent_pipe[1];
        in_opponent_pipe[3] <= in_opponent_pipe[2];

        vcount_pipe[0] <= vcount_in;
        vcount_pipe[1] <= vcount_pipe[0];

        hcount_pipe[0] <= hcount_in;
        hcount_pipe[1] <= hcount_pipe[0];

        for (int i = 1; i < 2; i = i+1) begin
            sprite_type_pipe[i] <= sprite_type_pipe[i-1];
        end
    end


    assign in_player     = (loc_x + 63 >=   player_x    &&  player_x   + 64 >= loc_x)  &&  (loc_y + 63 >=   player_y   &&  player_y   + 64 >= loc_y);
    assign in_opponent   = (loc_x + 63 >=   opponent_x  &&  opponent_x + 64 >= loc_x)  &&  (loc_y + 63 >=   opponent_y &&  opponent_y + 64 >= loc_y);
    assign player_addr   = {loc_y[6:2] + 5'd15 - player_y[6:2],   loc_x[6:2] + 5'd15 - player_x[6:2]};
    assign opponent_addr = {loc_y[6:2] + 5'd15 - opponent_y[6:2], loc_x[6:2] + 5'd15 - opponent_x[6:2]};

    assign track_addr  = {loc_y[11] == 1 ? 4'b0 : loc_y[10:7], loc_x[11] == 1 ? 4'b0 : loc_x[10:7]};
    // The sprite address doesn't use the lowest two bits because our images are 32 by 32.
    assign sprite_addr = {loc_y[6:2], loc_x[6:2]};

    // Track BRAM

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(13),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(log.mem))                    
    ) logarithm (
        .addra(8'd255 - vcount_in[7:0]),
        .dina(13'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(log)
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(4),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(track.mem))                    
    ) track_2 (
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
        .INIT_FILE(`FPATH(cos.mem))                    
    ) cosine_2 (
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
        .INIT_FILE(`FPATH(sin.mem))                    
    ) sine_2 (
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
        .INIT_FILE(`FPATH(00_road.mem))
    ) i0_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[0])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(00_road_pal.mem))
    ) p0_black_square_pal (
        .addra(palette_addr[0]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 0),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[0])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(01_normal_sand.mem))
    ) i1_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[1])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(01_normal_sand_pal.mem))
    ) p1_type (
        .addra(palette_addr[1]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[1])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                    
    ) i2_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[2])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        
    ) p2_type (
        .addra(palette_addr[2]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 2),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[2])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                    
    ) i3_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[3])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        
    ) p3_type (
        .addra(palette_addr[3]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 3),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[3])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                    
    ) i4_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[4])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        
    ) p4_type (
        .addra(palette_addr[4]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 4),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[4])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                    
    ) i5_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[5])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        
    ) p5_type (
        .addra(palette_addr[5]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 5),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[5])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                    
    ) i6_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[6])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        
    ) p6_type (
        .addra(palette_addr[6]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 6),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[6])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                    
    ) i7_type (
        .addra(sprite_addr),
        .dina(8'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(palette_addr[7])
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(12),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                        
    ) p7_type (
        .addra(palette_addr[7]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(sprite_type == 7),
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
        .INIT_FILE(`FPATH(08_mario_icon.mem))                    
    ) i8_mario (
        .addra(player_addr),
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
        .INIT_FILE(`FPATH(08_mario_icon_pal.mem))                        
    ) p8_mario (
        .addra(palette_addr[8]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(in_player_pipe[1]),
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
        .INIT_FILE(`FPATH(09_luigi_icon.mem))                    
    ) i9_luigi (
        .addra(opponent_addr),
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
        .INIT_FILE(`FPATH(09_luigi_icon_pal.mem))                        
    ) p9_luigi (
        .addra(palette_addr[9]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(in_opponent_pipe[1]),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[9])
    );

endmodule

`default_nettype none