/******************************************************************************
 *
 * Module      : scheduler_engine
 *
 * Description :
 *      Central execution controller for the Intelligent DMA.
 *
 *      Responsibilities:
 *   - Receive execution request from Descriptor Controller
 *   - Select Dense or Sparse Scheduler
 *   - Start selected Scheduler
 *   - Monitor scheduler execution
 *   - Report completion/error back to Descriptor Controller
 ******************************************************************************/

`timescale 1ns/1ps

import descriptor_pkg::*;
import dma_pkg::*;

module scheduler_engine
(
    //----------------------------------------------------------
    // Global Signals
    //----------------------------------------------------------

    input logic clk,
    input logic rst,

    //----------------------------------------------------------
    // Descriptor Controller Interface
    //----------------------------------------------------------

    input logic scheduler_start,

    input scheduler_mode_t scheduler_mode,

    input descriptor_t descriptor_in,

    //----------------------------------------------------------
    // Status Outputs
    //----------------------------------------------------------

    output logic scheduler_busy,

    output logic scheduler_done,

    output logic scheduler_error

);

//----------------------------------------------------------
// Scheduler Engine FSM States
//----------------------------------------------------------

typedef enum logic [2:0]
{
    SCHED_IDLE,

    SCHED_SELECT,

    SCHED_START,

    SCHED_WAIT,

    SCHED_COMPLETE,

    SCHED_ERROR

} scheduler_state_t;

//----------------------------------------------------------
// Internal Registers
//----------------------------------------------------------

scheduler_state_t current_state;
scheduler_state_t next_state;

descriptor_t descriptor_reg;

scheduler_mode_t active_scheduler;

//----------------------------------------------------------
// Dense Scheduler Interface
//----------------------------------------------------------

logic dense_start;

logic dense_busy;

logic dense_done;

logic dense_error;

//----------------------------------------------------------
// Sparse Scheduler Interface
//----------------------------------------------------------

logic sparse_start;

logic sparse_busy;

logic sparse_done;

logic sparse_error;

//----------------------------------------------------------
// State Register
//----------------------------------------------------------

always_ff @(posedge clk)
begin

    if (rst)
    begin

        current_state <= SCHED_IDLE;

    end

    else
    begin

        current_state <= next_state;

    end

end

//----------------------------------------------------------
// Descriptor Register
//----------------------------------------------------------

always_ff @(posedge clk)
begin

    if (rst)
    begin

        descriptor_reg <= '0;

    end

    else if (current_state == SCHED_SELECT)
    begin

        descriptor_reg <= descriptor_in;

    end

end

//----------------------------------------------------------
// Selected Scheduler Register
//----------------------------------------------------------

always_ff @(posedge clk)
begin

    if (rst)
    begin

        active_scheduler <= SCHEDULER_DENSE;

    end

    else if (current_state == SCHED_SELECT)
    begin

        active_scheduler <= scheduler_mode;

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

    next_state = current_state;

    case (current_state)

        //--------------------------------------------------
        // Wait for Descriptor Controller
        //--------------------------------------------------

        SCHED_IDLE:
        begin

            if (scheduler_start)
            begin

                next_state = SCHED_SELECT;

            end

        end

        //--------------------------------------------------
        // Select Dense/Sparse Scheduler
        //--------------------------------------------------

        SCHED_SELECT:
        begin

            next_state = SCHED_START;

        end

        //--------------------------------------------------
        // Generate Start Pulse
        //--------------------------------------------------

        SCHED_START:
        begin

            next_state = SCHED_WAIT;

        end

        //--------------------------------------------------
        // Wait for Scheduler Completion
        //--------------------------------------------------

        SCHED_WAIT:
        begin

            if (active_scheduler == SCHEDULER_DENSE)
            begin

            if (dense_error)
                next_state = SCHED_ERROR;

            else if (dense_done)
                next_state = SCHED_COMPLETE;

        end

            else
        begin

            if (sparse_error)
                next_state = SCHED_ERROR;

            else if (sparse_done)
                next_state = SCHED_COMPLETE;

        end

        end

        //--------------------------------------------------
        // Job Finished
        //--------------------------------------------------

        SCHED_COMPLETE:
        begin

            next_state = SCHED_IDLE;

        end

        //--------------------------------------------------
        // Job Failed
        //--------------------------------------------------

        SCHED_ERROR:
        begin

            next_state = SCHED_IDLE;

        end

        //--------------------------------------------------
        // Safety
        //--------------------------------------------------

        default:
        begin

            next_state = SCHED_IDLE;

        end

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

    scheduler_busy  = 1'b0;
    scheduler_done  = 1'b0;
    scheduler_error = 1'b0;

    dense_start  = 1'b0;
    sparse_start = 1'b0;

    case (current_state)

        //--------------------------------------------------
        // Idle
        //--------------------------------------------------

        SCHED_IDLE:
        begin

            // Default outputs already assigned

        end

        //--------------------------------------------------
        // Select Scheduler
        //--------------------------------------------------

        SCHED_SELECT:
        begin

            scheduler_busy = 1'b1;

        end

        //--------------------------------------------------
        // Generate One-Cycle Start Pulse
        //--------------------------------------------------

        SCHED_START:
        begin

            scheduler_busy = 1'b1;

            if (active_scheduler == SCHEDULER_DENSE)
                dense_start = 1'b1;
            else
                sparse_start = 1'b1;

        end

        //--------------------------------------------------
        // Wait for Scheduler
        //--------------------------------------------------

        SCHED_WAIT:
        begin

            scheduler_busy = 1'b1;

        end

        //--------------------------------------------------
        // Completed
        //--------------------------------------------------

        SCHED_COMPLETE:
        begin

            scheduler_done = 1'b1;

        end

        //--------------------------------------------------
        // Error
        //--------------------------------------------------

        SCHED_ERROR:
        begin

            scheduler_error = 1'b1;

        end

        default:
        begin

            // Default outputs already assigned

        end

    endcase

end

endmodule