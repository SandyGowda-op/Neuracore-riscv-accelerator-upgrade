//==============================================================
// File: dfu_state_assertions.sv
// Description:
//     State transition assertions for Descriptor Fetch Unit FSM
//
// Verification Goal:
//     Ensure every legal FSM transition occurs correctly.
//==============================================================

`timescale 1ns/1ps

import descriptor_pkg::*;

module dfu_state_assertions
(
    input logic clk,
    input logic rst,
    input logic start,

    input logic last_word,

    input dfu_state_t current_state,
    input dfu_state_t next_state
);

    
`ifndef DFU_STATE_ASSERTIONS_SV
`define DFU_STATE_ASSERTIONS_SV

//--------------------------------------------------------------
// Assertion 1
// Requirement:
// After reset is asserted, the FSM shall return to DFU_IDLE.
//--------------------------------------------------------------
property p_reset_to_idle;
    @(posedge clk)
    rst
    |=>
    (current_state == DFU_IDLE);
endproperty

assert property (p_reset_to_idle)
    else $error("DFU FSM failed to return to IDLE after reset.");


//--------------------------------------------------------------
// Assertion 2 (Designed by You)
// Requirement:
// If the FSM is in IDLE and a start request arrives,
// it shall transition to ISSUE_READ.
//--------------------------------------------------------------
property p_idle_to_issue_read;
    @(posedge clk)
    (current_state == DFU_IDLE && $rose(start))
    |->
    (next_state == DFU_ISSUE_READ);
endproperty

assert property (p_idle_to_issue_read)
    else $error("DFU failed to transition from IDLE to ISSUE_READ.");


//--------------------------------------------------------------
// Assertion 3 (Designed by You)
// Requirement:
// If CAPTURE is processing the last word,
// the FSM shall enter COMPLETE.
//--------------------------------------------------------------
property p_capture_to_complete;
    @(posedge clk)
    (current_state == DFU_CAPTURE && last_word)
    |=>
    (current_state == DFU_COMPLETE);
endproperty

assert property (p_capture_to_complete)
    else $error("DFU failed to transition from CAPTURE to COMPLETE.");


//--------------------------------------------------------------
// Assertion 4
// Requirement:
// If CAPTURE is not processing the last word,
// the FSM shall continue fetching descriptors by
// returning to ISSUE_READ.
//--------------------------------------------------------------
property p_capture_to_issue_read;
    @(posedge clk)
    (current_state == DFU_CAPTURE && !last_word)
    |->
    (next_state == DFU_ISSUE_READ);
endproperty

assert property (p_capture_to_issue_read)
    else $error("DFU failed to return to ISSUE_READ from CAPTURE.");


//--------------------------------------------------------------
// Assertion 5
// Requirement:
// COMPLETE is a terminal state.
// The controller shall return to IDLE on the next cycle.
//--------------------------------------------------------------
property p_complete_to_idle;
    @(posedge clk)
    (current_state == DFU_COMPLETE)
    |=>
    (current_state == DFU_IDLE);
endproperty

assert property (p_complete_to_idle)
    else $error("DFU failed to return to IDLE after COMPLETE.");

`endif

endmodule