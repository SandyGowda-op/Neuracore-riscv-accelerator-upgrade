/******************************************************************************
 *
 * Module      : descriptor_controller
 *
 * Description :
 *      Controls the execution lifecycle of descriptors.
 *
 * Responsibilities:
 *      - Accept descriptors from Descriptor Fetch Unit
 *      - Validate descriptors
 *      - Latch descriptor information
 *      - Select Dense/Sparse scheduler
 *      - Start Scheduler Engine
 *      - Monitor Scheduler completion
 *      - Report completion/error
 *      - Request next descriptor
 *
 ******************************************************************************/
`timescale 1ns/1ps

import descriptor_pkg::*;
import dma_pkg::*;

module descriptor_controller
(
    //----------------------------------------------------------
    // Global Signals
    //----------------------------------------------------------
    input  logic clk,
    input  logic rst,

    //----------------------------------------------------------
    // Descriptor Fetch Unit Interface
    //----------------------------------------------------------
    input  descriptor_pkg::descriptor_t        descriptor_in,
    input  logic                               descriptor_valid,
    input  logic                               descriptor_error,
    input  descriptor_pkg::descriptor_error_t  descriptor_error_code,

    output logic                               fetch_next_descriptor,

    //----------------------------------------------------------
    // Scheduler Engine Interface
    //----------------------------------------------------------
    output logic                               scheduler_start,
    output dma_pkg::scheduler_mode_t           scheduler_mode,

    output descriptor_pkg::descriptor_t        descriptor_out,

    input  logic                               scheduler_busy,
    input  logic                               scheduler_done,
    input  logic                               scheduler_error,

    //----------------------------------------------------------
    // Status Outputs
    //----------------------------------------------------------
    output dma_pkg::job_status_t               job_status,

    output logic                               controller_busy,
    output logic                               controller_done,
    output logic                               controller_error
);

//----------------------------------------------------------
// Controller FSM States
//----------------------------------------------------------

typedef enum logic [2:0]
{
    CTRL_IDLE,

    CTRL_VALIDATE,

    CTRL_LOAD,

    CTRL_SELECT,

    CTRL_START,

    CTRL_WAIT,

    CTRL_COMPLETE,

    CTRL_ERROR

} controller_state_t;

//----------------------------------------------------------
// Internal Registers
//----------------------------------------------------------

controller_state_t current_state;
controller_state_t next_state;

descriptor_t descriptor_reg;

//----------------------------------------------------------
// State Register
//----------------------------------------------------------

always_ff @(posedge clk)
begin

    if (rst)
    begin

        current_state <= CTRL_IDLE;

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

    else if (current_state == CTRL_LOAD)
    begin

        descriptor_reg <= descriptor_in;

    end

end

//----------------------------------------------------------
// Next State Logic
//----------------------------------------------------------

always_comb
begin

    //------------------------------------------------------
    // Default
    //------------------------------------------------------

    next_state = current_state;

    case (current_state)

    CTRL_IDLE:
        begin
            if (descriptor_valid)
                next_state = CTRL_VALIDATE;
        end

        CTRL_VALIDATE:
        begin
            if (descriptor_error)
                next_state = CTRL_ERROR;
            else
                next_state = CTRL_LOAD;
        end

        CTRL_LOAD:
        begin
            next_state = CTRL_SELECT;
        end

        CTRL_SELECT:
        begin
            next_state = CTRL_START;
        end

        CTRL_START:
        begin
            next_state = CTRL_WAIT;
        end

        CTRL_WAIT:
        begin
            if (scheduler_error)
                next_state = CTRL_ERROR;
            else if (scheduler_done)
                next_state = CTRL_COMPLETE;
        end

        CTRL_COMPLETE:
        begin
            next_state = CTRL_IDLE;
        end

        CTRL_ERROR:
        begin
            next_state = CTRL_IDLE;
        end

        default:
        begin
            next_state = CTRL_IDLE;
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

    scheduler_start       = 1'b0;
    fetch_next_descriptor = 1'b0;

    controller_busy =
       (current_state != CTRL_IDLE)
    && (current_state != CTRL_COMPLETE)
    && (current_state != CTRL_ERROR);

    controller_done       = 1'b0;
    controller_error      = 1'b0;

    job_status            = JOB_PENDING;

descriptor_out = descriptor_reg;

if (descriptor_reg.flags[FLAG_SPARSE_ENABLE])
begin
    scheduler_mode = SCHEDULER_SPARSE;
end
else
begin
    scheduler_mode = SCHEDULER_DENSE;
end

    case(current_state)

        CTRL_IDLE:
begin

    job_status = JOB_PENDING;

end

        CTRL_VALIDATE:
begin

    job_status = JOB_RUNNING;

end

        CTRL_LOAD:
begin

    job_status      = JOB_RUNNING;

end

        CTRL_SELECT:
begin

    job_status      = JOB_RUNNING;

end

        CTRL_START:
begin

    job_status      = JOB_RUNNING;

    scheduler_start = 1'b1;

end

        CTRL_WAIT:
begin

    job_status      = JOB_RUNNING;

end

        CTRL_COMPLETE:
begin

    controller_done       = 1'b1;

    fetch_next_descriptor = 1'b1;

    job_status            = JOB_COMPLETED;

end

        CTRL_ERROR:
begin

    controller_error      = 1'b1;

    fetch_next_descriptor = 1'b1;

    job_status            = JOB_FAILED;

end

    endcase

end
endmodule