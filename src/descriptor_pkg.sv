/******************************************************************************
 *
 * Package     : descriptor_pkg
 *
 * Version     : 2.0
 *
 * Description :
 *      Global package containing all common definitions used by the
 *      Descriptor Subsystem.
 *
 *      This package is the single source of truth for:
 *
 *          • Global architecture parameters
 *          • Derived widths
 *          • Descriptor memory organization
 *          • Descriptor word numbering
 *          • Common datatypes
 *          • Descriptor Fetch Unit FSM
 *          • Descriptor structure
 *
 * Notes
 * -----
 * Packages are compile-time constructs only.
 * They DO NOT generate hardware.
 *
 ******************************************************************************/
`timescale 1ns/1ps
package descriptor_pkg;

    //======================================================================
    // Global Architecture Parameters
    //======================================================================

    parameter int WORD_WIDTH           = 32;

    parameter int NUM_DESCRIPTORS      = 128;

    parameter int WORDS_PER_DESCRIPTOR = 8;


    //======================================================================
    // Derived Parameters
    //======================================================================

    parameter int DESCRIPTOR_WIDTH =
        WORD_WIDTH * WORDS_PER_DESCRIPTOR;

    parameter int DESCRIPTOR_MEM_DEPTH =
        NUM_DESCRIPTORS * WORDS_PER_DESCRIPTOR;

    parameter int DESC_INDEX_WIDTH =
        $clog2(NUM_DESCRIPTORS);

    parameter int WORD_COUNTER_WIDTH =
        $clog2(WORDS_PER_DESCRIPTOR);

    parameter int MEM_ADDR_WIDTH =
        $clog2(DESCRIPTOR_MEM_DEPTH);


    //======================================================================
    // Descriptor Memory Word
    //
    // Represents one physical 32-bit word stored inside Descriptor Memory.
    //======================================================================

    typedef logic [WORD_WIDTH-1:0] descriptor_mem_word_t;


    //======================================================================
    // Descriptor Word Numbers
    //
    // Defines the order of words inside one descriptor.
    //
    // Descriptor Layout
    //
    // Word 0 : srcA_addr
    // Word 1 : srcB_addr
    // Word 2 : metadata_addr
    // Word 3 : dst_addr
    // Word 4 : rows, cols
    // Word 5 : k, strideA  
    // Word 6 : strideB, strideC
    // Word 7 : flags
    //======================================================================

    typedef enum logic [2:0] {

        DESC_WORD_SRCA       = 3'd0,

        DESC_WORD_SRCB       = 3'd1,

        DESC_WORD_METADATA   = 3'd2,

        DESC_WORD_DST        = 3'd3,

        DESC_WORD_ROWS_COLS  = 3'd4,

        DESC_WORD_K_STRIDEA  = 3'd5,

        DESC_WORD_STRIDEB_C  = 3'd6,

        DESC_WORD_FLAGS      = 3'd7

    } descriptor_word_index_t;


    //======================================================================
    // Descriptor Fetch Unit FSM
    //
    // ISSUE_READ
    //      Generates synchronous BRAM read.
    //
    // CAPTURE
    //      Captures returned memory word.
    //======================================================================

    typedef enum logic [1:0] {

        DFU_IDLE,

        DFU_ISSUE_READ,

        DFU_CAPTURE,

        DFU_COMPLETE

    } dfu_state_t;

    //======================================================================
    // Descriptor Structure
    //
    // Packed so the descriptor behaves as one contiguous vector while still
    // allowing field-based access.
    //======================================================================

    typedef struct packed {

    //----------------------------------------------------------
    // Matrix Base Addresses
    //----------------------------------------------------------

    logic [31:0] srcA_addr;

    logic [31:0] srcB_addr;

    //----------------------------------------------------------
    // Sparse Metadata Address
    //----------------------------------------------------------

    logic [31:0] metadata_addr;

    //----------------------------------------------------------
    // Destination Matrix
    //----------------------------------------------------------

    logic [31:0] dst_addr;

    //----------------------------------------------------------
    // Matrix Dimensions
    //----------------------------------------------------------

    logic [15:0] rows;

    logic [15:0] cols;

    logic [15:0] k;

    //----------------------------------------------------------
    // Memory Strides (Bytes)
    //----------------------------------------------------------

    logic [31:0] strideA;

    logic [31:0] strideB;

    logic [31:0] strideC;

    //----------------------------------------------------------
    // Element Size
    //----------------------------------------------------------

    logic [7:0] bytes_per_element;

    //----------------------------------------------------------
    // Control Flags
    //----------------------------------------------------------

    logic [31:0] flags;

} descriptor_t;

//==============================================================
// Descriptor Error Codes
//==============================================================

typedef enum logic [3:0]
{
    DESC_NO_ERROR,

    DESC_ERR_ROWS_ZERO,

    DESC_ERR_COLS_ZERO,

    DESC_ERR_K_ZERO

} descriptor_error_t;

//======================================================================
// Descriptor Flag Bit Definitions
//======================================================================
//
// flags[0] : Sparse Scheduler Enable
// flags[1] : Interrupt on Completion
// flags[2] : Transpose Matrix A
// flags[3] : Transpose Matrix B
// flags[4] : Accumulate into Destination
//

localparam int FLAG_SPARSE_ENABLE = 0;

localparam int FLAG_INTERRUPT     = 1;

localparam int FLAG_TRANSPOSE_A   = 2;

localparam int FLAG_TRANSPOSE_B   = 3;

localparam int FLAG_ACCUMULATE    = 4;

localparam int FLAG_RELU_ENABLE = 5;

endpackage
