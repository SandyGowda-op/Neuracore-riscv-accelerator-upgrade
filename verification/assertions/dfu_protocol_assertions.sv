//==============================================================
// File : dfu_protocol_assertions.sv
//
// Description:
// Protocol assertions for the Descriptor Fetch Unit.
//
// Verifies:
//   - Memory interface protocol
//   - Busy/Done protocol
//   - Descriptor index stability
//   - Memory addressing protocol
//   - Output stability
//==============================================================

`timescale 1ns/1ps

import descriptor_pkg::*;

module dfu_protocol_assertions
(
    input logic clk,

    input dfu_state_t current_state,

    input logic busy,
    input logic done,

    input logic dfu_re,

    input logic [DESC_INDEX_WIDTH-1:0] descriptor_index_reg,
    input logic [DESC_INDEX_WIDTH-1:0] dfu_desc_idx,

    input logic [WORD_COUNTER_WIDTH-1:0] word_counter,
    input logic [WORD_COUNTER_WIDTH-1:0] dfu_word_offset,

    input descriptor_t descriptor_out,

    input logic commit_descriptor
);


`ifndef DFU_PROTOCOL_ASSERTIONS_SV
`define DFU_PROTOCOL_ASSERTIONS_SV

//==============================================================
// 1. Memory Read Enable Protocol
//==============================================================
// Requirement:
// Memory read enable shall only be asserted during ISSUE_READ.
//==============================================================

property p_dfu_re_only_issue_read;
    @(posedge clk)
    dfu_re
    |->
    (current_state == DFU_ISSUE_READ);
endproperty

assert property(p_dfu_re_only_issue_read)
    else $error("dfu_re asserted outside ISSUE_READ.");


//==============================================================
// 2. Done Protocol
//==============================================================
// Requirement:
// Done shall only be asserted while the FSM is in COMPLETE.
//==============================================================

property p_done_only_complete;
    @(posedge clk)
    done
    |->
    (current_state == DFU_COMPLETE);
endproperty

assert property(p_done_only_complete)
    else $error("Done asserted outside COMPLETE state.");


//==============================================================
// 3. Descriptor Index Stability
//==============================================================
// Requirement:
// Descriptor index register shall remain constant while busy.
//==============================================================

property p_descriptor_index_stable;
    @(posedge clk)
    busy
    |->
    $stable(descriptor_index_reg);
endproperty

assert property(p_descriptor_index_stable)
    else $error("Descriptor index changed while DFU was busy.");


//==============================================================
// 4. Busy Protocol
//==============================================================
// Requirement:
// Whenever the FSM is not IDLE,
// busy shall be asserted.
//==============================================================

property p_busy_when_active;
    @(posedge clk)
    (current_state != DFU_IDLE)
    |->
    busy;
endproperty

assert property(p_busy_when_active)
    else $error("Busy not asserted during active transaction.");


//==============================================================
// 5. Idle Protocol
//==============================================================
// Requirement:
// Whenever the FSM is IDLE,
// busy shall be deasserted.
//==============================================================

property p_not_busy_when_idle;
    @(posedge clk)
    (current_state == DFU_IDLE)
    |->
    (!busy);
endproperty

assert property(p_not_busy_when_idle)
    else $error("Busy asserted while DFU is IDLE.");


//==============================================================
// 6. Memory Address Protocol
//==============================================================
// Requirement:
// Descriptor memory index shall always equal the
// registered descriptor index.
//==============================================================

property p_memory_index_matches_register;
    @(posedge clk)
    dfu_desc_idx == descriptor_index_reg;
endproperty

assert property(p_memory_index_matches_register)
    else $error("Descriptor memory index mismatch.");


//==============================================================
// 7. Word Offset Protocol
//==============================================================
// Requirement:
// Memory word offset shall always equal the word counter.
//==============================================================

property p_word_offset_matches_counter;
    @(posedge clk)
    dfu_word_offset == word_counter;
endproperty

assert property(p_word_offset_matches_counter)
    else $error("Word offset does not match word counter.");


//==============================================================
// 8. Descriptor Output Stability
//==============================================================
// Requirement:
// Descriptor output shall not change while busy,
// except during commit.
//==============================================================

property p_descriptor_output_stable;
    @(posedge clk)
    (busy && !commit_descriptor)
    |->
    $stable(descriptor_out);
endproperty

assert property(p_descriptor_output_stable)
    else $error("Descriptor output changed unexpectedly.");


//==============================================================
// 9. Last Word Detection
//==============================================================
// Requirement:
// last_word shall only be asserted when the counter
// reaches the final descriptor word.
//==============================================================

property p_last_word_detection;
    @(posedge clk)
    last_word
    |->
    (word_counter == WORDS_PER_DESCRIPTOR-1);
endproperty

assert property(p_last_word_detection)
    else $error("Incorrect last_word indication.");


//==============================================================
// 10. Done Pulse Width
//==============================================================
// Requirement:
// Done shall be a single-cycle pulse.
//==============================================================

property p_done_single_cycle;
    @(posedge clk)
    done
    |=>
    !done;
endproperty

assert property(p_done_single_cycle)
    else $error("Done pulse wider than one clock.");

`endif

endmodule