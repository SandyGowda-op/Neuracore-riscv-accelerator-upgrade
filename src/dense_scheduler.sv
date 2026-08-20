/******************************************************************************
 *
 * Module      : dense_scheduler
 *
 * Description :
 *      Scheduler for dense GEMM descriptors.
 *
 * Responsibilities:
 *      - Compute tile traversal limits
 *      - Start and advance Tile Walker
 *      - Accept generated tile requests
 *      - Hold accepted tile request during transfer/compute
 *      - Handshake with Transfer Engine
 *      - Launch Compute Controller
 *      - Signal descriptor completion
 *
 ******************************************************************************/

`timescale 1ns/1ps

import descriptor_pkg::*;
import tile_pkg::*;

module dense_scheduler
(
    //--------------------------------------------------
    // Global
    //--------------------------------------------------

    input  logic clk,
    input  logic rst_n,

    //--------------------------------------------------
    // Descriptor Controller
    //--------------------------------------------------

    input  logic        start,
    input  descriptor_t descriptor,

    output logic        dense_done,

    //--------------------------------------------------
    // Tile Walker Control
    //--------------------------------------------------

    output logic walker_start,
    output logic walker_next,

    //--------------------------------------------------
    // Tile Walker Limits
    //--------------------------------------------------

    output logic [15:0] max_tile_rows,
    output logic [15:0] max_tile_cols,
    output logic [15:0] max_tile_k,

    //--------------------------------------------------
    // Tile Walker Status
    //--------------------------------------------------

    input tile_context_t current_tile,

    input logic first_tile,
    input logic last_tile,
    input logic walker_done,

    //--------------------------------------------------
    // Tile Generator
    //--------------------------------------------------

    input tile_request_t generated_request,

    //--------------------------------------------------
    // Transfer Engine
    //--------------------------------------------------

    input  logic          transfer_ready,
    input  logic          transfer_done,

    output logic          transfer_valid,
    output tile_request_t transfer_request,

    //--------------------------------------------------
    // Compute Controller
    //--------------------------------------------------
    
    output logic          compute_start,
    input  logic          compute_done,

    output tile_request_t  compute_request

);


//==============================================================================
// Scheduler State Machine
//==============================================================================

typedef enum logic [3:0]
{
    IDLE,

    START_WALKER,

    ISSUE_TILE,

    WAIT_TRANSFER,

    WAIT_TRANSFER_DONE,

    START_COMPUTE,

    WAIT_COMPUTE_DONE,

    ADVANCE_TILE,

    COMPLETE

} dense_state_t;


dense_state_t state;
dense_state_t next_state;


//==============================================================================
// Latched Tile Request
//==============================================================================
//
// Once a transfer handshake occurs, the request is preserved here.
//
// This is important because the Tile Generator / Tile Walker may move
// to another tile while the current tile is still being transferred
// or computed.
//
//==============================================================================

tile_request_t current_request;


//==============================================================================
// Tile Count Calculation
//==============================================================================
//
// Number of tiles required in each dimension:
//
// ceil(rows / TILE_M)
// ceil(cols / TILE_N)
// ceil(k    / TILE_K)
//
//==============================================================================

always_comb
begin

    max_tile_rows =
        (descriptor.rows + TILE_M - 1) / TILE_M;

    max_tile_cols =
        (descriptor.cols + TILE_N - 1) / TILE_N;

    max_tile_k =
        (descriptor.k + TILE_K - 1) / TILE_K;

end


//==============================================================================
// State Register
//==============================================================================

always_ff @(posedge clk or negedge rst_n)
begin

    if (!rst_n)
    begin

        state <= IDLE;

        current_request <= '0;

    end

    else
    begin

        state <= next_state;

        //--------------------------------------------------------------
        // Capture tile request when transfer handshake occurs.
        //--------------------------------------------------------------

        if (((state == ISSUE_TILE) ||
            (state == WAIT_TRANSFER)) &&
            transfer_valid &&
            transfer_ready)
        begin

            current_request <= generated_request;

        end

    end

end


//==============================================================================
// Next-State Logic
//==============================================================================

always_comb
begin

    next_state = state;

    case (state)

        //======================================================================
        // IDLE
        //======================================================================

        IDLE:
        begin

            if (start)
                next_state = START_WALKER;

        end


        //======================================================================
        // START_WALKER
        //======================================================================

        START_WALKER:
        begin

            next_state = ISSUE_TILE;

        end


        //======================================================================
        // ISSUE_TILE
        //======================================================================
        //
        // One cycle allowing the generated tile request to become visible.
        //
        //======================================================================

        ISSUE_TILE:
begin

    if (generated_request.valid && transfer_ready)
        next_state = WAIT_TRANSFER_DONE;

    else
        next_state = WAIT_TRANSFER;

end


        //======================================================================
        // WAIT_TRANSFER
        //======================================================================
        //
        // Hold transfer_valid and transfer_request until the Transfer
        // Engine accepts the request.
        //
        //======================================================================

        WAIT_TRANSFER:
        begin

            if (generated_request.valid &&
                transfer_ready)
            begin

                next_state = WAIT_TRANSFER_DONE;

            end

        end


        //======================================================================
        // WAIT_TRANSFER_DONE
        //======================================================================
        //
        // Transfer Engine has accepted the request.
        //
        // Wait until the actual data movement is complete.
        //
        //======================================================================

        WAIT_TRANSFER_DONE:
        begin

            if (transfer_done)
                next_state = START_COMPUTE;

        end


        //======================================================================
        // START_COMPUTE
        //======================================================================
        //
        // One-cycle pulse to Compute Controller.
        //
        //======================================================================

        START_COMPUTE:
        begin

            next_state = WAIT_COMPUTE_DONE;

        end


        //======================================================================
        // WAIT_COMPUTE_DONE
        //======================================================================
        //
        // Hold the current tile request while computation is occurring.
        //
        //======================================================================

        WAIT_COMPUTE_DONE:
        begin

            if (compute_done)
                next_state = ADVANCE_TILE;

        end


        //======================================================================
        // ADVANCE_TILE
        //======================================================================

        ADVANCE_TILE:
        begin

            if (current_request.last_tile)
                next_state = COMPLETE;

            else
                next_state = ISSUE_TILE;

        end


        //======================================================================
        // COMPLETE
        //======================================================================

        COMPLETE:
        begin

            next_state = IDLE;

        end


        //======================================================================
        // Safety
        //======================================================================

        default:
        begin

            next_state = IDLE;

        end

    endcase

end


//==============================================================================
// Output Logic
//==============================================================================

always_comb
begin

    //--------------------------------------------------------------
    // Default outputs
    //--------------------------------------------------------------

    walker_start = 1'b0;
    walker_next  = 1'b0;

    compute_request = '0;

    dense_done = 1'b0;

    transfer_valid   = 1'b0;
    transfer_request = '0;

    compute_start = 1'b0;


    case (state)

        //======================================================================
        // START_WALKER
        //======================================================================

        START_WALKER:
        begin

            walker_start = 1'b1;

        end


        //======================================================================
        // ISSUE_TILE
        //======================================================================

        ISSUE_TILE:
        begin

            transfer_request = generated_request;

            transfer_valid =
                generated_request.valid;

        end


        //======================================================================
        // WAIT_TRANSFER
        //======================================================================
        //
        // Request remains stable while waiting for ready.
        //
        //======================================================================

        WAIT_TRANSFER:
        begin

            transfer_request = generated_request;

            transfer_valid =
                generated_request.valid;

        end


        //======================================================================
        // WAIT_TRANSFER_DONE
        //======================================================================
        //
        // Transfer has been accepted.
        //
        // Keep the accepted request visible.
        //
        //======================================================================

        WAIT_TRANSFER_DONE:
        begin

            transfer_request = current_request;

        end


        //======================================================================
        // START_COMPUTE
        //======================================================================
        //
        // Launch compute for the accepted tile.
        //
        // Keep current_request visible.
        //
        //======================================================================

        START_COMPUTE:
        begin

            compute_start = 1'b1;
            compute_request = current_request;

        end


        //======================================================================
        // WAIT_COMPUTE_DONE
        //======================================================================
        //
        // Compute Controller is processing this tile.
        //
        // Keep current request available.
        //
        //======================================================================

        WAIT_COMPUTE_DONE:
        begin

            compute_request = current_request;

            transfer_request = current_request;

        end


        //======================================================================
        // ADVANCE_TILE
        //======================================================================

        ADVANCE_TILE:
        begin

            compute_request = current_request;

            transfer_request = current_request;

            if (!current_request.last_tile)
                walker_next = 1'b1;

        end


        //======================================================================
        // COMPLETE
        //======================================================================

        COMPLETE:
        begin

            dense_done = 1'b1;

        end


        //======================================================================
        // Default
        //======================================================================

        default:
        begin

        end

    endcase

end


//==============================================================================
// Simulation Instrumentation
//==============================================================================

`ifndef SYNTHESIS

always_ff @(posedge clk)
begin

    $display(
        "[SCHED_DEBUG] t=%0t state=%0d start=%0b walker_start=%0b walker_next=%0b transfer_valid=%0b transfer_ready=%0b transfer_done=%0b compute_start=%0b compute_done=%0b last_tile=%0b dense_done=%0b",
        $time,
        state,
        start,
        walker_start,
        walker_next,
        transfer_valid,
        transfer_ready,
        transfer_done,
        compute_start,
        compute_done,
        current_request.last_tile,
        dense_done
    );

end

`endif


endmodule