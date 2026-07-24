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

package descriptor_pkg;

    //======================================================================
    // Global Architecture Parameters
    //======================================================================

    parameter int WORD_WIDTH           = 32;

    parameter int NUM_DESCRIPTORS      = 128;

    parameter int WORDS_PER_DESCRIPTOR = 10;


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
    // Word 0 : Source A Address
    // Word 1 : Source B Address
    // Word 2 : Destination Address
    // Word 3 : Rows | Cols
    // Word 4 : K | Stride A
    // Word 5 : Stride B | Stride C
    // Word 6 : Datatype
    // Word 7 : Flags
    // Word 8 : Status
    // Word 9 : Reserved
    //======================================================================

    typedef enum logic [3:0] {

        DESC_WORD_SRCA       = 4'd0,

        DESC_WORD_SRCB       = 4'd1,

        DESC_WORD_DST        = 4'd2,

        DESC_WORD_ROWS_COLS  = 4'd3,

        DESC_WORD_K_STRIDEA  = 4'd4,

        DESC_WORD_STRIDEB_C  = 4'd5,

        DESC_WORD_DATATYPE   = 4'd6,

        DESC_WORD_FLAGS      = 4'd7,

        DESC_WORD_STATUS     = 4'd8,

        DESC_WORD_RESERVED   = 4'd9

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
    // Supported Matrix Datatypes
    //======================================================================

    typedef enum logic [1:0] {

        DATA_INT8      = 2'b00,

        DATA_INT16     = 2'b01,

        DATA_FP16      = 2'b10,

        DATA_RESERVED  = 2'b11

    } datatype_t;


    //======================================================================
    // Descriptor Structure
    //
    // Packed so the descriptor behaves as one contiguous vector while still
    // allowing field-based access.
    //======================================================================

    typedef struct packed {

        //------------------------------------------------------------------
        // Matrix Addresses
        //------------------------------------------------------------------

        logic [31:0] srcA_addr;

        logic [31:0] srcB_addr;

        logic [31:0] dst_addr;


        //------------------------------------------------------------------
        // Matrix Dimensions
        //------------------------------------------------------------------

        logic [15:0] rows;

        logic [15:0] cols;

        logic [15:0] k;


        //------------------------------------------------------------------
        // Memory Strides
        //------------------------------------------------------------------

        logic [15:0] strideA;

        logic [15:0] strideB;

        logic [15:0] strideC;


        //------------------------------------------------------------------
        // Datatype
        //------------------------------------------------------------------

        datatype_t datatype;

        logic [29:0] reserved0;


        //------------------------------------------------------------------
        // Control
        //------------------------------------------------------------------

        logic [31:0] flags;

        logic [31:0] status;


        //------------------------------------------------------------------
        // Reserved
        //------------------------------------------------------------------

        logic [31:0] reserved1;

    } descriptor_t;

endpackage
