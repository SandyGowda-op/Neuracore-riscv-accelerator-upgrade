/******************************************************************************
 *
 * Module      : dma_pkg
 *
 * Version     : 1.0
 *
 * Description :
 *      Common package for the Intelligent DMA Controller.
 *
 *      Contains:
 *          • Global Parameters
 *          • Scheduler Modes
 *          • DMA FSM Definitions
 *          • Transfer Types
 *          • Tile Descriptor
 *          • Scheduler Commands
 *          • DMA Status Structures
 *          • Error Codes
 *
 ******************************************************************************/
`timescale 1ns/1ps
package dma_pkg;

    //==========================================================
    // Section 1
    // Global Parameters
    //==========================================================

    // Address/Data Bus Widths
    parameter int DMA_ADDR_WIDTH  = 32;
    parameter int DMA_DATA_WIDTH  = 32;

    // Tile Parameters
    parameter int TILE_ROWS       = 8;
    parameter int TILE_COLS       = 8;

    parameter int TILE_DIM_WIDTH  = 16;
    parameter int STRIDE_WIDTH    = 16;

    // DMA Parameters
    parameter int MAX_BURST_LENGTH = 16;

    parameter int DMA_QUEUE_DEPTH  = 4;

    parameter int DMA_QUEUE_INDEX_WIDTH =
                    $clog2(DMA_QUEUE_DEPTH);

    //==========================================================
    // Section 2
    // DMA Top-Level FSM States
    //==========================================================

    typedef enum logic [2:0]
    {
        DMA_IDLE,

        DMA_FETCH_DESCRIPTOR,

        DMA_SCHEDULE,

        DMA_TRANSFER,

        DMA_WAIT_COMPUTE,

        DMA_COMPLETE

    } dma_state_t;

    //==========================================================
    // Section 3
    // Scheduler Mode
    //==========================================================

    typedef enum logic
    {
        SCHEDULER_DENSE,

        SCHEDULER_SPARSE

    } scheduler_mode_t;

    //==========================================================
    // Section 4
    // Transfer Type
    //==========================================================

    typedef enum logic [1:0]
    {
        TRANSFER_SRC_A,

        TRANSFER_SRC_B,

        TRANSFER_METADATA,

        TRANSFER_DST

    } transfer_type_t;

    //==========================================================
    // Section 5
    // Tile Descriptor
    //==========================================================

    typedef struct packed
    {
        // External memory starting address
        logic [DMA_ADDR_WIDTH-1:0] base_addr;

        // Tile dimensions
        logic [TILE_DIM_WIDTH-1:0] rows;
        logic [TILE_DIM_WIDTH-1:0] cols;

        // Memory stride
        logic [STRIDE_WIDTH-1:0] stride;

        // Scratchpad destination bank
        logic [3:0] scratchpad_bank;

        // What data this tile represents
        transfer_type_t transfer_type;

    } tile_descriptor_t;

    //==========================================================
    // Section 6
    // Scheduler Commands
    //==========================================================

    typedef enum logic [2:0]
    {
        CMD_IDLE,

        CMD_START,

        CMD_NEXT_TILE,

        CMD_WAIT,

        CMD_FINISH

    } scheduler_cmd_t;

    //==========================================================
    // Section 7
    // DMA Status
    //==========================================================

    typedef struct packed
    {
        logic busy;

        logic done;

        logic error;

        logic stall;

    } dma_status_t;

    //==========================================================
    // Scheduler Status
    //==========================================================

    typedef struct packed
    {
        logic busy;

        logic tile_ready;

        logic done;

    } scheduler_status_t;

    //==========================================================
    // Transfer Engine Status
    //==========================================================

    typedef struct packed
    {
        logic busy;

        logic burst_done;

        logic transfer_done;

        logic error;

    } transfer_status_t;

    //==========================================================
    // Section 8
    // DMA Error Codes
    //==========================================================

    typedef enum logic [3:0]
    {
        DMA_NO_ERROR,

        DMA_DESCRIPTOR_ERROR,

        DMA_ALIGNMENT_ERROR,

        DMA_TRANSFER_ERROR,

        DMA_SCRATCHPAD_ERROR,

        DMA_TIMEOUT_ERROR,

        DMA_SCHEDULER_ERROR,

        DMA_UNKNOWN_ERROR

    } dma_error_t;

//==========================================================
// Descriptor Execution Status
//==========================================================

typedef enum logic [1:0]
{
    JOB_PENDING,

    JOB_RUNNING,

    JOB_COMPLETED,

    JOB_FAILED

} job_status_t;

endpackage