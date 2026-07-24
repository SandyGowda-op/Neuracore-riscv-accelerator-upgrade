//==============================================================
// File : dfu_liveness_assertions.sv
//
// Description:
// Liveness / Progress Assertions
//
// Verifies:
//     • No deadlock
//     • Eventual completion
//     • FSM forward progress
//==============================================================

`timescale 1ns/1ps

import descriptor_pkg::*;

module dfu_liveness_assertions
(
    input logic clk,

    input logic start,

    input logic busy,
    input logic done,

    input logic commit_descriptor,

    input dfu_state_t current_state
);

`ifndef DFU_LIVENESS_ASSERTIONS_SV
`define DFU_LIVENESS_ASSERTIONS_SV


//--------------------------------------------------------------
// Assertion 1
// Requirement:
// Every start request shall eventually complete.
//--------------------------------------------------------------

property p_start_eventually_done;

    @(posedge clk)

    $rose(start)
    |->

    ##[1:$] done;

endproperty

assert property(p_start_eventually_done)
    else $error("Transaction never completed.");


//--------------------------------------------------------------
// Assertion 2
// Requirement:
// ISSUE_READ shall always progress to CAPTURE.
//--------------------------------------------------------------

property p_issue_read_progress;

    @(posedge clk)

    current_state == DFU_ISSUE_READ

    |=>

    current_state == DFU_CAPTURE;

endproperty

assert property(p_issue_read_progress)
    else $error("ISSUE_READ failed to progress.");


//--------------------------------------------------------------
// Assertion 3
// Requirement:
// COMPLETE shall always return to IDLE.
//--------------------------------------------------------------

property p_complete_progress;

    @(posedge clk)

    current_state == DFU_COMPLETE

    |=>

    current_state == DFU_IDLE;

endproperty

assert property(p_complete_progress)
    else $error("COMPLETE failed to return to IDLE.");


//--------------------------------------------------------------
// Assertion 4
// Requirement:
// CAPTURE shall eventually leave CAPTURE.
//--------------------------------------------------------------

property p_capture_not_stuck;

    @(posedge clk)

    current_state == DFU_CAPTURE

    |->

    ##[1:$]

    current_state != DFU_CAPTURE;

endproperty

assert property(p_capture_not_stuck)
    else $error("FSM stuck in CAPTURE.");


//--------------------------------------------------------------
// Assertion 5
// Requirement:
// Once COMPLETE occurs,
// the DFU shall eventually become idle.
//--------------------------------------------------------------

property p_eventually_idle;

    @(posedge clk)

    current_state == DFU_COMPLETE

    |->

    ##1

    !busy;

endproperty

assert property(p_eventually_idle)
    else $error("Busy never deasserted.");


//--------------------------------------------------------------
// Assertion 6
// Requirement:
// Every descriptor fetch eventually produces
// a committed descriptor.
//--------------------------------------------------------------

property p_eventually_commit;

    @(posedge clk)

    $rose(start)

    |->

    ##[1:$]

    commit_descriptor;

endproperty

assert property(p_eventually_commit)
    else $error("Descriptor never committed.");


//--------------------------------------------------------------
// Assertion 7
// Requirement:
// Every descriptor commit eventually generates done.
//--------------------------------------------------------------

property p_commit_to_done;

    @(posedge clk)

    commit_descriptor

    |=>

    done;

endproperty

assert property(p_commit_to_done)
    else $error("Commit did not generate done.");


//--------------------------------------------------------------
// Assertion 8
// Requirement:
// DFU shall never remain busy forever.
//--------------------------------------------------------------

property p_busy_eventually_clears;

    @(posedge clk)

    busy

    |->

    ##[1:$]

    !busy;

endproperty

assert property(p_busy_eventually_clears)
    else $error("Busy never cleared.");

`endif

endmodule