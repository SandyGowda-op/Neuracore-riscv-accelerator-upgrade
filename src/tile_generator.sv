/******************************************************************************
 *
 * Module      : tile_generator
 *
 * Description :
 *      Generates a complete tile transfer request from the
 *      current tile context and descriptor.
 *
 ******************************************************************************/

`timescale 1ns/1ps

import descriptor_pkg::*;
import tile_pkg::*;

module tile_generator
(
    //----------------------------------------------------------
    // Inputs
    //----------------------------------------------------------

    input descriptor_t   descriptor,

    input tile_context_t current_tile,

    input logic          last_tile,

    //----------------------------------------------------------
    // Output
    //----------------------------------------------------------

    output tile_request_t tile_request
);

    //----------------------------------------------------------
    // Intermediate Tile Sizes
    //----------------------------------------------------------

    logic [15:0] remaining_rows;
    logic [15:0] remaining_cols;
    logic [15:0] remaining_k;
    
    //----------------------------------------------------------
    // Address Calculation Variables
    //----------------------------------------------------------

    logic [31:0] row_offset_a;
    logic [31:0] col_offset_a;

    logic [31:0] row_offset_b;
    logic [31:0] col_offset_b;

    logic [31:0] row_offset_c;
    logic [31:0] col_offset_c;

    //----------------------------------------------------------
    // Tile Generation Logic
    //----------------------------------------------------------

    always_comb
    begin

        //------------------------------------------------------
        // Defaults
        //------------------------------------------------------

        tile_request = '0;

        remaining_rows = '0;
        remaining_cols = '0;
        remaining_k    = '0;

        row_offset_a = '0;
        col_offset_a = '0;

        row_offset_b = '0;
        col_offset_b = '0;

        row_offset_c = '0;
        col_offset_c = '0;

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
        // Matrix A Address Calculation
        //------------------------------------------------------

        row_offset_a =
            current_tile.tile_row *
            TILE_M *
            descriptor.strideA;

        col_offset_a =
            current_tile.tile_k *
            TILE_K *
            descriptor.bytes_per_element;

        tile_request.addr_a =
            descriptor.srcA_addr +
            row_offset_a +
            col_offset_a;

        //------------------------------------------------------
        // Matrix B Address Calculation
        //------------------------------------------------------

        row_offset_b =
            current_tile.tile_k *
            TILE_K *
            descriptor.strideB;

        col_offset_b =
            current_tile.tile_col *
            TILE_N *
            descriptor.bytes_per_element;

        tile_request.addr_b =
            descriptor.srcB_addr +
            row_offset_b +
            col_offset_b;

        //------------------------------------------------------
        // Matrix C Address Calculation
        //------------------------------------------------------

        row_offset_c =
            current_tile.tile_row *
            TILE_M *
            descriptor.strideC;

        col_offset_c =
            current_tile.tile_col *
            TILE_N *
            descriptor.bytes_per_element;

        tile_request.addr_c =
            descriptor.dst_addr +
            row_offset_c +
            col_offset_c;

        //------------------------------------------------------
        // Tile Dimensions
        //------------------------------------------------------

        if (remaining_rows >= TILE_M)
            tile_request.rows = TILE_M;
        else
            tile_request.rows = remaining_rows;

        if (remaining_cols >= TILE_N)
            tile_request.cols = TILE_N;
        else
            tile_request.cols = remaining_cols;

        if (remaining_k >= TILE_K)
            tile_request.k_size = TILE_K;
        else
            tile_request.k_size = remaining_k;

        //------------------------------------------------------
        // Tile Strides
        //------------------------------------------------------

        tile_request.stride_a =
            descriptor.strideA;

        tile_request.stride_b =
            descriptor.strideB;

        //------------------------------------------------------
// Transfer Size
//------------------------------------------------------

// Matrix A tile:
// rows × k_size × bytes_per_element

tile_request.transfer_bytes =
    tile_request.rows *
    tile_request.k_size *
    descriptor.bytes_per_element;

// Matrix B tile:
// k_size × cols × bytes_per_element

tile_request.transfer_bytes_b =
    tile_request.k_size *
    tile_request.cols *
    descriptor.bytes_per_element;

        //------------------------------------------------------
        // Tile Context
        //------------------------------------------------------

        tile_request.tile_context = current_tile;

        //------------------------------------------------------
        // Control
        //------------------------------------------------------

        tile_request.valid     = 1'b1;
        tile_request.last_tile = last_tile;

        //------------------------------------------------------
        // Scratchpad Bank Assignment
        //------------------------------------------------------

        tile_request.bank_a = 4'd0;
        tile_request.bank_b = 4'd1;
        tile_request.bank_c = 4'd2;

    end

endmodule