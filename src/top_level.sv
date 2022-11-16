xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(3),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH())                    // Specify track1 mem file
    ) track1_type (
        .addra(image_lookup_addr),
        .dina(0),       
        .clka(pixel_clk_in),
        .wea(0),
        .ena(1),
        .rsta(rst_in),
        .regcea(1),
        .douta(sprite_type_pipe[0])
    );