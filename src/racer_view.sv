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

    // Note, 0 degrees is up vertically (with vcount decreasing)

    logic in_player;
    logic in_opponent;
    logic [5:0] in_player_pipe;
    logic [3:0] in_opponent_pipe;
    
    logic [3:0] sprite_type;
    logic [3:0] obstacle_type;
    logic [9:0] player_addr;
    logic [9:0] opponent_addr;
    logic [9:0] sprite_addr;
    logic [1:0][3:0] sprite_type_pipe;
    logic [1:0][3:0] obstacle_type_pipe;

    logic signed [10:0] cos;
    logic signed [10:0] sin;
    logic signed [11:0] loc_x;
    logic signed [11:0] loc_y;
    
    logic signed [21:0] delta_x;
    logic signed [1:0][21:0] delta_x_pipe;
    logic signed [21:0] delta_y;
    logic signed [1:0][21:0] delta_y_pipe;

    logic [7:0] track_addr;
    logic [9:0][7:0] palette_addr;
    logic [15:0][11:0] output_color;

    logic [13:0] player_counter;

    assign delta_x = $signed(hcount_in - 767);
    assign delta_y = $signed(vcount_in - 255);

    always_ff @(posedge clk_in)begin  

        // Make sure this doesn't go out of the bounds between 0 and 2047
        // This is actually right. It checks that we're not negative.
        loc_x <= $signed($signed(delta_x_pipe[1]) * sin - $signed(delta_y_pipe[1]) * cos) / 512 + player_x;
        loc_y <= $signed($signed(delta_x_pipe[1]) * cos + $signed(delta_y_pipe[1]) * sin) / 512 + player_y;

        sprite_type_pipe[0] <= sprite_type;
        sprite_type_pipe[1] <= sprite_type_pipe[0];

        obstacle_type_pipe[0] <= obstacle_type;
        obstacle_type_pipe[1] <= obstacle_type_pipe[0];

        if (hcount_in == 0 && vcount_in == 0) player_counter <= 0;
        if (in_player) player_counter <= player_counter + 1;

        in_player_pipe[0] <= in_player;
        in_opponent_pipe[0] <= in_opponent;

        delta_y_pipe[0] <= delta_y;
        delta_y_pipe[1] <= delta_y_pipe[0];

        delta_x_pipe[0] <= delta_x;
        delta_x_pipe[1] <= delta_x_pipe[0];

        for (int i = 1; i < 6; i = i+1) in_player_pipe[i] <= in_player_pipe[i-1];
        for (int i = 1; i < 4; i = i+1) in_opponent_pipe[i] <= in_opponent_pipe[i-1];

        if (in_player_pipe[5]) begin
            if (output_color[8] == 12'h406) pixel_out <= output_color[sprite_type_pipe[1]];
            else pixel_out <= output_color[8];
        end else if (in_opponent_pipe[3]) begin
            if (output_color[9] == 12'h406) pixel_out <= output_color[sprite_type_pipe[1]];
            else pixel_out <= output_color[9];
        end else if (obstacle_type_pipe[1] != 0) begin
            if (output_color[obstacle_type_pipe[1]] == 12'h406) pixel_out <= output_color[sprite_type_pipe[1]];
            else pixel_out <= output_color[obstacle_type_pipe[1]];
        end else pixel_out <= output_color[sprite_type_pipe[1]];
    end

    // Player_addr and Opponent_addr work properly when they're in the player or opponent. Otherwise, it can spew garbage, but it doesn't matter.
    assign in_player   = (hcount_in >= 704  && hcount_in <= 831) && (vcount_in >= 192 && vcount_in <= 319);
    assign in_opponent = (loc_x + 63 >= opponent_x && opponent_x + 64 >= loc_x) && (loc_y + 63 >= opponent_y && opponent_y + 64 >= loc_y);
    assign opponent_addr = {loc_y[6:2] + 5'd15 - opponent_y[6:2], loc_x[6:2] + 5'd15 - opponent_x[6:2]};
    assign player_addr = {player_counter[13:9], player_counter[6:2]};

    assign track_addr  = {loc_y[11] == 1 ? 4'b0 : loc_y[10:7], loc_x[11] == 1 ? 4'b0 : loc_x[10:7]};
    // The sprite address doesn't use the lowest two bits because our images are 32 by 32.
    assign sprite_addr = {loc_y[6:2], loc_x[6:2]};
    
    // Track BRAM

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(4),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(track.mem))                    
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
        .RAM_WIDTH(4),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(track_obstacles.mem))                    
    ) track_obstacles (
        .addra(track_addr),
        .dina(4'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(obstacle_type)
    );

    xilinx_true_dual_port_read_first_1_clock_ram #(
        .RAM_WIDTH(11),
        .RAM_DEPTH(360),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(cos.mem))  
    ) trig (
    // Cosine Side
        .addra(direction),
        .dina(11'b0),
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(cos),
    // Sine Side
        .addrb((direction > 9'd90) ? direction - 9'd90 : 9'd90 - direction),
        .dinb(11'b0),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(sin)
    );




    // Normal Sprites
    
    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(00_road_vert.mem))
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
        .INIT_FILE(`FPATH(00_road_vert_pal.mem))
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
        .INIT_FILE(`FPATH(02_road_horiz.mem))                    
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
        .INIT_FILE(`FPATH(02_road_horiz_pal.mem))                        
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
        .INIT_FILE(`FPATH(05_finish.mem))                    
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
        .INIT_FILE(`FPATH(05_finish_pal.mem))                        
    ) p5_type (
        .addra(palette_addr[5]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(obstacle_type == 5),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(output_color[5])
    );

    /////

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(1024),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(06_oil_spill.mem))                    
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
        .INIT_FILE(`FPATH(06_oil_spill_pal.mem))                        
    ) p6_type (
        .addra(palette_addr[6]),
        .dina(12'b0),       
        .clka(clk_in),
        .wea(1'b0),
        .ena(obstacle_type == 6),
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
        .ena(obstacle_type == 7),
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
        .ena(in_player_pipe[1]),
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
        .ena(in_player_pipe[3]),
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
