/******************************************************************************
 *
 * Module      : dense_scheduler
 *
 * Description :
 *      Scheduler for dense GEMM descriptors.
 *
 * Responsibilities:
 *      - Compute tile traversal limits
 *      - Control Tile Walker
 *      - Accept generated tile requests
 *      - Handshake with Transfer Engine
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

    input logic transfer_ready,

    output tile_request_t transfer_request
);


//------------------------------------------------------
// Scheduler State Machine
//------------------------------------------------------

typedef enum logic [2:0]
{
    IDLE,
    START_WALKER,
    ISSUE_TILE,
    WAIT_READY,
    COMPLETE

} dense_state_t;

dense_state_t state;
dense_state_t next_state;


//------------------------------------------------------
// Tile Count Calculation
//------------------------------------------------------
//
// ceil(rows / TILE_M)
// ceil(cols / TILE_N)
// ceil(k / TILE_K)
//
// Example:
//
// rows = 130
// TILE_M = 64
//
// (130 + 63) / 64 = 3 tiles
//
//------------------------------------------------------

always_comb
begin

    max_tile_rows =
        (descriptor.rows + TILE_M - 1) / TILE_M;

    max_tile_cols =
        (descriptor.cols + TILE_N - 1) / TILE_N;

    max_tile_k =
        (descriptor.k + TILE_K - 1) / TILE_K;

end


//------------------------------------------------------
// State Register
//------------------------------------------------------

always_ff @(posedge clk or negedge rst_n)
begin

    if (!rst_n)
        state <= IDLE;

    else
        state <= next_state;

end

//------------------------------------------------------
// Next-State Logic
//------------------------------------------------------

always_comb
begin

    //--------------------------------------------------
    // Default
    //--------------------------------------------------

    next_state = state;

    case (state)

        //--------------------------------------------------
        // Wait for a descriptor
        //--------------------------------------------------

        IDLE:
        begin

            if (start)
                next_state = START_WALKER;

        end


        //--------------------------------------------------
        // Initialize Tile Walker
        //--------------------------------------------------

        START_WALKER:
        begin

            //--------------------------------------------------
            // Tile Walker receives a one-cycle start pulse.
            // The Tile Generator immediately computes the
            // request for tile (0,0,0).
            //--------------------------------------------------

            next_state = ISSUE_TILE;

        end


        //--------------------------------------------------
        // Allow Tile Generator to settle
        //--------------------------------------------------

        ISSUE_TILE:
        begin

            //--------------------------------------------------
            // Tile Generator is purely combinational.
            // Move directly to the transfer handshake.
            //--------------------------------------------------

            next_state = WAIT_READY;

        end


        //--------------------------------------------------
        // Wait until Transfer Engine accepts request
        //--------------------------------------------------

        WAIT_READY:
        begin

            if (transfer_ready)
            begin

                //--------------------------------------------------
                // Current tile accepted.
                //--------------------------------------------------

                if (last_tile)
                    next_state = COMPLETE;

                else
                    next_state = ISSUE_TILE;

            end

        end


        //--------------------------------------------------
        // Descriptor Completed
        //--------------------------------------------------

        COMPLETE:
        begin

            //--------------------------------------------------
            // Raise completion for one cycle.
            //--------------------------------------------------

            next_state = IDLE;

        end


        //--------------------------------------------------

        default:
        begin

            next_state = IDLE;

        end

    endcase

end

//------------------------------------------------------
// Output Logic
//------------------------------------------------------

always_comb
begin

    //--------------------------------------------------
    // Default Outputs
    //--------------------------------------------------

    walker_start     = 1'b0;
    walker_next      = 1'b0;

    dense_done       = 1'b0;

    transfer_request = '0;

    //--------------------------------------------------
    // State Outputs
    //--------------------------------------------------

    case (state)

        //--------------------------------------------------
        // Initialize Tile Walker
        //--------------------------------------------------

        START_WALKER:
        begin

            //--------------------------------------------------
            // One-cycle pulse to initialize traversal
            //--------------------------------------------------

            walker_start = 1'b1;

        end


        //--------------------------------------------------
        // Tile Generator Output
        //--------------------------------------------------

        ISSUE_TILE:
        begin

            //--------------------------------------------------
            // Tile Generator is purely combinational.
            // Forward its generated request.
            //--------------------------------------------------

            transfer_request = generated_request;

        end


        //--------------------------------------------------
        // Wait for Transfer Engine
        //--------------------------------------------------

        WAIT_READY:
        begin

            //--------------------------------------------------
            // Hold request until accepted.
            //--------------------------------------------------

            transfer_request = generated_request;

            if (transfer_ready)
            begin

                //--------------------------------------------------
                // Advance Tile Walker only if more tiles remain.
                //--------------------------------------------------

                if (!last_tile)
                    walker_next = 1'b1;

            end

        end


        //--------------------------------------------------
        // Descriptor Complete
        //--------------------------------------------------

        COMPLETE:
        begin

            dense_done = 1'b1;

        end


        //--------------------------------------------------

        default:
        begin

        end

    endcase

end

endmodule