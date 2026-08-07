/******************************************************************************
 *
 * Package     : tile_pkg
 *
 * Description :
 *      Common package for all tile-based scheduling modules.
 *
 ******************************************************************************/

`timescale 1ns/1ps

package tile_pkg;

    //----------------------------------------------------------
    // Tile Configuration
    //----------------------------------------------------------

    localparam int TILE_M = 64;
    localparam int TILE_N = 64;
    localparam int TILE_K = 64;

    //----------------------------------------------------------
    // Tile Context
    //----------------------------------------------------------

    typedef struct packed
    {
        logic [15:0] tile_row;
        logic [15:0] tile_col;
        logic [15:0] tile_k;

    } tile_context_t;

    //----------------------------------------------------------
    // Tile Request
    //----------------------------------------------------------

    typedef struct packed
    {
        logic valid;

        logic last_tile;

        tile_context_t tile_context;

        logic [31:0] addr_a;
        logic [31:0] addr_b;
        logic [31:0] addr_c;

        logic [31:0] transfer_bytes;

        logic [15:0] rows;
        logic [15:0] cols;
        logic [15:0] k_size;

        logic [3:0] bank_a;
        logic [3:0] bank_b;
        logic [3:0] bank_c;


    } tile_request_t;

//----------------------------------------------------------
// Sparse Tile Request
//----------------------------------------------------------

typedef struct packed
{
    //------------------------------------------------------
    // Control
    //------------------------------------------------------

    logic valid;

    logic last_tile;

    //------------------------------------------------------
    // Tile Context
    //------------------------------------------------------

    tile_context_t tile_context;

    //------------------------------------------------------
    // Matrix Addresses
    //------------------------------------------------------

    logic [31:0] values_addr_a;

    logic [31:0] values_addr_b;

    logic [31:0] metadata_addr_a;

    //------------------------------------------------------
    // Destination Matrix
    //------------------------------------------------------

    logic [31:0] addr_c;

    //------------------------------------------------------
    // Tile Dimensions
    //------------------------------------------------------

    logic [15:0] rows;

    logic [15:0] cols;

    logic [15:0] k_size;

    //------------------------------------------------------
    // Scratchpad Banks
    //------------------------------------------------------

    logic [3:0] bank_a;

    logic [3:0] bank_b;

    logic [3:0] bank_c;

    logic [31:0] transfer_bytes;

} sparse_tile_request_t;

endpackage