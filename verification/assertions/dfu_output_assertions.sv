//==============================================================
// File : dfu_output_assertions.sv
//
// Description:
// Assertions for verification of DFU output behavior.
//
// Verifies:
//     • Descriptor commit
//     • Done protocol
//     • Output stability
//     • Output correctness
//==============================================================

`timescale 1ns/1ps

import descriptor_pkg::*;

module dfu_output_assertions
(
    input logic clk,

    input logic busy,
    input logic done,

    input logic commit_descriptor,

    input dfu_state_t current_state,

    input descriptor_t working_desc,
    input descriptor_t descriptor_out
);


`ifndef DFU_OUTPUT_ASSERTIONS_SV
`define DFU_OUTPUT_ASSERTIONS_SV

//--------------------------------------------------------------
// Assertion 1
// Requirement:
// Descriptor output shall only change when a commit occurs.
//--------------------------------------------------------------

property p_output_changes_only_on_commit;

    @(posedge clk)

    (!commit_descriptor)
    |->
    $stable(descriptor_out);

endproperty

assert property(p_output_changes_only_on_commit)
    else $error("Descriptor output changed without commit.");


//--------------------------------------------------------------
// Assertion 2
// Requirement:
// Done shall only occur after a descriptor commit.
//--------------------------------------------------------------

property p_done_after_commit;

    @(posedge clk)

    done
    |->
    $past(commit_descriptor);

endproperty

assert property(p_done_after_commit)
    else $error("Done asserted without descriptor commit.");


//--------------------------------------------------------------
// Assertion 3
// Requirement:
// Once the DFU becomes idle,
// descriptor_out shall remain unchanged.
//--------------------------------------------------------------

property p_output_stable_when_idle;

    @(posedge clk)

    (!busy)
    |->
    $stable(descriptor_out);

endproperty

assert property(p_output_stable_when_idle)
    else $error("Descriptor output changed while DFU was idle.");


//--------------------------------------------------------------
// Assertion 4
// Requirement:
// Commit shall only occur during COMPLETE.
//--------------------------------------------------------------

property p_commit_only_complete;

    @(posedge clk)

    commit_descriptor
    |->
    (current_state == DFU_COMPLETE);

endproperty

assert property(p_commit_only_complete)
    else $error("Descriptor committed outside COMPLETE state.");


//--------------------------------------------------------------
// Assertion 5
// Requirement:
// Done shall only be generated during COMPLETE.
//--------------------------------------------------------------

property p_done_only_complete;

    @(posedge clk)

    done
    |->
    (current_state == DFU_COMPLETE);

endproperty

assert property(p_done_only_complete)
    else $error("Done asserted outside COMPLETE state.");


//--------------------------------------------------------------
// Assertion 6
// Requirement:
// Descriptor output shall equal the completed working descriptor
// immediately after commit.
//--------------------------------------------------------------

property p_output_matches_working_descriptor;

    @(posedge clk)

    commit_descriptor
    |=>
    (descriptor_out == $past(working_desc));

endproperty

assert property(p_output_matches_working_descriptor)
    else $error("Committed descriptor does not match working descriptor.");


//--------------------------------------------------------------
// Assertion 7
// Requirement:
// Descriptor output shall never change while the
// DFU is actively processing, except during commit.
//--------------------------------------------------------------

property p_output_stable_while_busy;

    @(posedge clk)

    (busy && !commit_descriptor)
    |->
    $stable(descriptor_out);

endproperty

assert property(p_output_stable_while_busy)
    else $error("Descriptor output changed unexpectedly while busy.");


//--------------------------------------------------------------
// Assertion 8
// Requirement:
// Done shall be a single-cycle pulse.
//--------------------------------------------------------------

property p_done_single_cycle;

    @(posedge clk)

    done
    |=>
    !done;

endproperty

assert property(p_done_single_cycle)
    else $error("Done pulse wider than one cycle.");

`endif

endmodule