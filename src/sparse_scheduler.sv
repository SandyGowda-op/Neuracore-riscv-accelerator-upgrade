/******************************************************************************
 *
 * Module      : sparse_scheduler
 *
 * Description :
 *      Top-level controller for structured sparse matrix execution.
 *
 * Responsibilities :
 *      - Control sparse tile traversal
 *      - Coordinate compressed value transfers
 *      - Coordinate metadata transfers
 *      - Trigger metadata decoder
 *      - Launch sparse matrix engine
 *      - Advance Tile Walker
 *      - Signal descriptor completion
 *
 ******************************************************************************/

`timescale 1ns/1ps

import descriptor_pkg::*;
import tile_pkg::*;

module sparse_scheduler
(

    //----------------------------------------------------------
    // Global
    //----------------------------------------------------------

    input logic clk,
    input logic rst,

    //----------------------------------------------------------
    // Number of K Tiles
    //----------------------------------------------------------

    logic [15:0] num_k_tiles;

    //----------------------------------------------------------
    // Descriptor Controller
    //----------------------------------------------------------

    input logic start,
    input descriptor_t descriptor,

    output logic sparse_done,

    //----------------------------------------------------------
    // Tile Walker
    //----------------------------------------------------------

    output logic walker_start,
    output logic walker_next,

    input tile_context_t current_tile,

    input logic first_tile,
    input logic last_tile,
    input logic walker_done,

    //----------------------------------------------------------
    // Sparse Tile Generator
    //----------------------------------------------------------

    output logic generator_enable,

    input sparse_tile_request_t generated_request,

    //----------------------------------------------------------
    // Sparse DMA
    //----------------------------------------------------------

    output logic start_value_dma,
    output logic start_metadata_dma,

    input logic value_dma_done,
    input logic metadata_dma_done,

    //----------------------------------------------------------
    // Metadata Decoder
    //----------------------------------------------------------

    output logic decoder_enable,

    input logic decoder_done,

    //----------------------------------------------------------
    // Sparse Matrix Engine
    //----------------------------------------------------------

    output logic compute_enable,

    input logic compute_done

);

//----------------------------------------------------------
// Sparse Scheduler FSM
//----------------------------------------------------------

typedef enum logic [3:0]
{
    IDLE,

    START_WALKER,

    GENERATE_TILE,

    LAUNCH_DMA,

    WAIT_DMA,

    DECODE_METADATA,

    START_COMPUTE,

    WAIT_COMPUTE,

    NEXT_TILE,

    COMPLETE,

    ERROR

} sparse_state_t;

//----------------------------------------------------------
// State Registers
//----------------------------------------------------------

sparse_state_t state;
sparse_state_t next_state;

//----------------------------------------------------------
// DMA Completion Registers
//----------------------------------------------------------

logic value_dma_complete;

logic metadata_dma_complete;


always_comb
begin

    num_k_tiles =
        (descriptor.k + TILE_K - 1) / TILE_K;

end
//----------------------------------------------------------
// State Register
//----------------------------------------------------------

always_ff @(posedge clk)
begin

    if (rst)
        state <= IDLE;
    else
        state <= next_state;

end

//----------------------------------------------------------
// DMA Completion Registers
//----------------------------------------------------------

always_ff @(posedge clk)
begin

    if (rst)
    begin

        value_dma_complete    <= 1'b0;
        metadata_dma_complete <= 1'b0;

    end

    else
    begin

        //--------------------------------------------------
        // Clear when starting a new tile
        //--------------------------------------------------

        if (state == START_WALKER)
        begin

            value_dma_complete    <= 1'b0;
            metadata_dma_complete <= 1'b0;

        end

        //--------------------------------------------------
        // Latch DMA completions
        //--------------------------------------------------

        else
        begin

            if (value_dma_done)
                value_dma_complete <= 1'b1;

            if (metadata_dma_done)
                metadata_dma_complete <= 1'b1;

        end

    end

end

//----------------------------------------------------------
// Next-State Logic
//----------------------------------------------------------

always_comb
begin

    //------------------------------------------------------
    // Default
    //------------------------------------------------------

    next_state = state;

    case (state)

        //--------------------------------------------------
        // Wait for new sparse descriptor
        //--------------------------------------------------

        IDLE:
        begin

            if (start)
                next_state = START_WALKER;

        end

        //--------------------------------------------------
        // Reset Tile Walker
        //--------------------------------------------------

        START_WALKER:
        begin

            next_state = GENERATE_TILE;

        end

        //--------------------------------------------------
        // Generate Sparse Tile Request
        //--------------------------------------------------

        GENERATE_TILE:
        begin

            next_state = LAUNCH_DMA;

        end

        //--------------------------------------------------
        // Launch Both DMA Transfers
        //--------------------------------------------------

        LAUNCH_DMA:
        begin

            next_state = WAIT_DMA;

        end

        //--------------------------------------------------
        // Wait for Both DMAs
        //--------------------------------------------------

        WAIT_DMA:
        begin

            if (value_dma_complete &&
                metadata_dma_complete)
            begin

                next_state = DECODE_METADATA;

            end

        end

        //--------------------------------------------------
        // Decode Metadata
        //--------------------------------------------------

        DECODE_METADATA:
        begin

            if (decoder_done)
                next_state = START_COMPUTE;

        end

        //--------------------------------------------------
        // Launch Sparse Compute
        //--------------------------------------------------

        START_COMPUTE:
        begin

            next_state = WAIT_COMPUTE;

        end

        //--------------------------------------------------
        // Wait for Matrix Engine
        //--------------------------------------------------

        WAIT_COMPUTE:
        begin

            if (compute_done)
                next_state = NEXT_TILE;

        end

        //--------------------------------------------------
        // Decide Whether More Tiles Exist
        //--------------------------------------------------

        NEXT_TILE:
        begin

            if (last_tile)
                next_state = COMPLETE;
            else
                next_state = START_WALKER;

        end

        //--------------------------------------------------
        // Descriptor Finished
        //--------------------------------------------------

        COMPLETE:
        begin

            next_state = IDLE;

        end

        //--------------------------------------------------
        // Error Recovery
        //--------------------------------------------------

        ERROR:
        begin

            next_state = IDLE;

        end

        //--------------------------------------------------

        default:
            next_state = IDLE;

    endcase

end

//----------------------------------------------------------
// Output Logic
//----------------------------------------------------------

always_comb
begin

    //------------------------------------------------------
    // Default Outputs
    //------------------------------------------------------

    walker_start       = 1'b0;
    walker_next        = 1'b0;

    generator_enable   = 1'b0;

    start_value_dma    = 1'b0;
    start_metadata_dma = 1'b0;

    decoder_enable     = 1'b0;

    compute_enable     = 1'b0;

    sparse_done        = 1'b0;

    //------------------------------------------------------
    // State Outputs
    //------------------------------------------------------

    case (state)

        //----------------------------------------------
        // Start Tile Walker
        //----------------------------------------------

        START_WALKER:
        begin

            walker_start = 1'b1;

        end

        //----------------------------------------------
        // Generate Sparse Tile Request
        //----------------------------------------------

        GENERATE_TILE:
        begin

            generator_enable = 1'b1;

        end

        //----------------------------------------------
        // Launch DMA Transfers
        //----------------------------------------------

        LAUNCH_DMA:
        begin

            start_value_dma    = 1'b1;
            start_metadata_dma = 1'b1;

        end

        //----------------------------------------------
        // Decode Metadata
        //----------------------------------------------

        DECODE_METADATA:
        begin

            decoder_enable = 1'b1;

        end

        //----------------------------------------------
        // Start Sparse Matrix Engine
        //----------------------------------------------

        START_COMPUTE:
        begin

            compute_enable = 1'b1;

        end

        //----------------------------------------------
        // Advance Tile Walker
        //----------------------------------------------

        NEXT_TILE:
        begin

            if (!last_tile)
                walker_next = 1'b1;

        end

        //----------------------------------------------
        // Descriptor Complete
        //----------------------------------------------

        COMPLETE:
        begin

            sparse_done = 1'b1;

        end

        //----------------------------------------------

        default:
        begin
        end

    endcase

end

endmodule