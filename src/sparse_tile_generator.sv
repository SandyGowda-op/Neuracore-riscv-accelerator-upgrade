/******************************************************************************
 *
 * Module      : sparse_tile_generator
 *
 * Description :
 *      Generates a sparse tile transfer request from the
 *      current tile context and descriptor.
 *
 * Responsibilities :
 *      - Compute compressed value addresses
 *      - Compute metadata address
 *      - Compute destination address
 *      - Compute edge tile dimensions
 *      - Populate sparse_tile_request_t
 *
 ******************************************************************************/

`timescale 1ns/1ps

import descriptor_pkg::*;
import tile_pkg::*;

module sparse_tile_generator
(

    input descriptor_t descriptor,

    input tile_context_t current_tile,

    //----------------------------------------------------------
    // Number of Tile Blocks Along K Dimension
    //----------------------------------------------------------

    input logic [15:0] num_k_tiles,

    input logic last_tile,

    //----------------------------------------------------------
    // Output
    //----------------------------------------------------------

    output sparse_tile_request_t sparse_tile_request

);

//----------------------------------------------------------
// Remaining Tile Dimensions
//----------------------------------------------------------

logic [15:0] remaining_rows;
logic [15:0] remaining_cols;
logic [15:0] remaining_k;

//----------------------------------------------------------
// Value Address Offsets
//----------------------------------------------------------

logic [31:0] value_row_offset_a;
logic [31:0] value_col_offset_a;

logic [31:0] value_row_offset_b;
logic [31:0] value_col_offset_b;

//----------------------------------------------------------
// Destination Address Offsets
//----------------------------------------------------------

logic [31:0] dest_row_offset;
logic [31:0] dest_col_offset;

//----------------------------------------------------------
// Metadata Address Offsets
//----------------------------------------------------------

logic [31:0] metadata_row_offset;
logic [31:0] metadata_k_offset;
logic [31:0] metadata_tile_offset;

//----------------------------------------------------------
// Metadata Organization
//----------------------------------------------------------

localparam int METADATA_BYTES_PER_GROUP = 1;

localparam int GROUP_SIZE = 4;

localparam int METADATA_BYTES_PER_TILE =
(TILE_M*TILE_K)/GROUP_SIZE;

//----------------------------------------------------------
// Sparse Tile Generation Logic
//----------------------------------------------------------

always_comb
begin

    //------------------------------------------------------
    // Defaults
    //------------------------------------------------------

    sparse_tile_request = '0;

    remaining_rows = '0;
    remaining_cols = '0;
    remaining_k    = '0;

    value_row_offset_a = '0;
    value_col_offset_a = '0;

    value_row_offset_b = '0;
    value_col_offset_b = '0;

    dest_row_offset = '0;
    dest_col_offset = '0;

    metadata_row_offset = '0;
    metadata_k_offset   = '0;

    //------------------------------------------------------
    // Remaining Matrix Dimensions
    //------------------------------------------------------

    if ((current_tile.tile_row * TILE_M) >= descriptor.rows)
        remaining_rows = 16'd0;
    else
        remaining_rows =
            descriptor.rows -
            (current_tile.tile_row * TILE_M);

    if ((current_tile.tile_col * TILE_N) >= descriptor.cols)
        remaining_cols = 16'd0;
    else
        remaining_cols =
            descriptor.cols -
            (current_tile.tile_col * TILE_N);

    if ((current_tile.tile_k * TILE_K) >= descriptor.k)
        remaining_k = 16'd0;
    else
        remaining_k =
            descriptor.k -
            (current_tile.tile_k * TILE_K);

    //------------------------------------------------------
    // Compressed Values A Address
    //------------------------------------------------------

    value_row_offset_a =
        current_tile.tile_row *
        TILE_M *
        descriptor.strideA;

    value_col_offset_a =
        current_tile.tile_k *
        TILE_K *
        descriptor.bytes_per_element;

    sparse_tile_request.values_addr_a =
        descriptor.srcA_addr +
        value_row_offset_a +
        value_col_offset_a;

    //------------------------------------------------------
    // Values B Address
    //------------------------------------------------------

    value_row_offset_b =
        current_tile.tile_k *
        TILE_K *
        descriptor.strideB;

    value_col_offset_b =
        current_tile.tile_col *
        TILE_N *
        descriptor.bytes_per_element;

    sparse_tile_request.values_addr_b =
        descriptor.srcB_addr +
        value_row_offset_b +
        value_col_offset_b;

    //------------------------------------------------------
    // Destination Address
    //------------------------------------------------------

    dest_row_offset =
        current_tile.tile_row *
        TILE_M *
        descriptor.strideC;

    dest_col_offset =
        current_tile.tile_col *
        TILE_N *
        descriptor.bytes_per_element;

    sparse_tile_request.addr_c =
        descriptor.dst_addr +
        dest_row_offset +
        dest_col_offset;

//------------------------------------------------------
// Metadata Address
//------------------------------------------------------

//------------------------------------------------------
// Each metadata block corresponds to one tile.
//
// Metadata memory layout:
//
// Tile(0,0)
// Tile(0,1)
// Tile(0,2)
// ...
// Tile(1,0)
// Tile(1,1)
// ...
//
// Therefore:
//
// Tile Index =
// (tile_row × num_k_tiles)
// +
// tile_k
//------------------------------------------------------

metadata_tile_offset =
(
    (current_tile.tile_row * num_k_tiles)
    +
    current_tile.tile_k
)
*
METADATA_BYTES_PER_TILE;

sparse_tile_request.metadata_addr_a =
    descriptor.metadata_addr +
    metadata_tile_offset;

//------------------------------------------------------
// Tile Dimensions
//------------------------------------------------------

if (remaining_rows >= TILE_M)
    sparse_tile_request.rows = TILE_M;
else
    sparse_tile_request.rows = remaining_rows;

if (remaining_cols >= TILE_N)
    sparse_tile_request.cols = TILE_N;
else
    sparse_tile_request.cols = remaining_cols;

if (remaining_k >= TILE_K)
    sparse_tile_request.k_size = TILE_K;
else
    sparse_tile_request.k_size = remaining_k;

//------------------------------------------------------
// Transfer Size
//------------------------------------------------------

// Sparse transfer currently refers to the values array.
// Metadata has its own transfer and will be handled later.

sparse_tile_request.transfer_bytes =
    sparse_tile_request.rows *
    sparse_tile_request.k_size *
    descriptor.bytes_per_element;

//------------------------------------------------------
// Tile Context
//------------------------------------------------------

sparse_tile_request.tile_context = current_tile;

//------------------------------------------------------
// Control
//------------------------------------------------------

sparse_tile_request.valid     = 1'b1;
sparse_tile_request.last_tile = last_tile;

//------------------------------------------------------
// Scratchpad Banks
//------------------------------------------------------

sparse_tile_request.bank_a = 4'd0;
sparse_tile_request.bank_b = 4'd1;
sparse_tile_request.bank_c = 4'd2;

end


endmodule