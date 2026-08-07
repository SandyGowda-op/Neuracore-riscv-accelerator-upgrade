`timescale 1ns/1ps

import descriptor_pkg::*;
import tile_pkg::*;

module sparse_tile_generator_tb;

//----------------------------------------------------------
// Inputs
//----------------------------------------------------------

descriptor_t descriptor;

tile_context_t current_tile;

logic [15:0] num_k_tiles;

logic last_tile;

//----------------------------------------------------------
// Output
//----------------------------------------------------------

sparse_tile_request_t sparse_tile_request;

sparse_tile_generator dut
(
    .descriptor(descriptor),

    .current_tile(current_tile),

    .num_k_tiles(num_k_tiles),

    .last_tile(last_tile),

    .sparse_tile_request(sparse_tile_request)
);

//----------------------------------------------------------
// Test Stimulus
//----------------------------------------------------------

initial
begin

    //------------------------------------------------------
    // Descriptor
    //------------------------------------------------------

    descriptor.srcA_addr     = 32'h1000_0000;
    descriptor.srcB_addr     = 32'h2000_0000;
    descriptor.metadata_addr = 32'h3000_0000;
    descriptor.dst_addr      = 32'h4000_0000;

    descriptor.rows = 16'd128;
    descriptor.cols = 16'd128;
    descriptor.k    = 16'd128;

    descriptor.strideA = 32'd512;
    descriptor.strideB = 32'd512;
    descriptor.strideC = 32'd512;

    descriptor.bytes_per_element = 8'd1;

    descriptor.flags = 32'd0;

    //------------------------------------------------------
    // Number of K Tiles
    //------------------------------------------------------

    num_k_tiles = 16'd2;

    //------------------------------------------------------
    // First Tile
    //------------------------------------------------------

    current_tile.tile_row = 16'd0;
    current_tile.tile_col = 16'd0;
    current_tile.tile_k   = 16'd0;

    last_tile = 1'b0;

    #10;

    $display("---------------------------------------------");
    $display("Tile (0,0,0)");
    $display("---------------------------------------------");

    $display("Values A Address   : %h", sparse_tile_request.values_addr_a);
    $display("Values B Address   : %h", sparse_tile_request.values_addr_b);
    $display("Metadata Address   : %h", sparse_tile_request.metadata_addr_a);
    $display("Destination Address: %h", sparse_tile_request.addr_c);

    $display("Rows=%0d Cols=%0d K=%0d",
        sparse_tile_request.rows,
        sparse_tile_request.cols,
        sparse_tile_request.k_size);

    //------------------------------------------------------
    // Tile (0,0,1)
    //------------------------------------------------------

    current_tile.tile_row = 16'd0;
    current_tile.tile_col = 16'd0;
    current_tile.tile_k   = 16'd1;

    #10;

    $display("---------------------------------------------");
    $display("Tile (0,0,1)");
    $display("---------------------------------------------");

    $display("Values A Address   : %h", sparse_tile_request.values_addr_a);
    $display("Values B Address   : %h", sparse_tile_request.values_addr_b);
    $display("Metadata Address   : %h", sparse_tile_request.metadata_addr_a);
    $display("Destination Address: %h", sparse_tile_request.addr_c);

        //------------------------------------------------------
    // Tile (1,0,0)
    //------------------------------------------------------

    current_tile.tile_row = 16'd1;
    current_tile.tile_col = 16'd0;
    current_tile.tile_k   = 16'd0;

    #10;

    $display("---------------------------------------------");
    $display("Tile (1,0,0)");
    $display("---------------------------------------------");

    $display("Values A Address   : %h", sparse_tile_request.values_addr_a);
    $display("Values B Address   : %h", sparse_tile_request.values_addr_b);
    $display("Metadata Address   : %h", sparse_tile_request.metadata_addr_a);
    $display("Destination Address: %h", sparse_tile_request.addr_c);

        $display("---------------------------------------------");
    $display("Sparse Tile Generator Test Complete");
    $display("---------------------------------------------");

    $finish;

end

endmodule