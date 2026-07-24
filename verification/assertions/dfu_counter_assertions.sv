//==============================================================
// File : dfu_counter_assertions.sv
//
// Description:
// Assertions for verification of the DFU word counter.
//
// Verifies:
//     • Counter Reset
//     • Counter Increment
//     • Counter Hold
//     • Counter Bounds
//     • Counter State Restrictions
//     • Counter Initialization
//==============================================================

`timescale 1ns/1ps

import descriptor_pkg::*;

module dfu_counter_assertions
(
    input logic clk,

    input logic clear_word_counter,
    input logic increment_word_counter,

    input logic start,
    input logic last_word,

    input logic [WORD_COUNTER_WIDTH-1:0] word_counter,

    input dfu_state_t current_state
);


`ifndef DFU_COUNTER_ASSERTIONS_SV
`define DFU_COUNTER_ASSERTIONS_SV

//--------------------------------------------------------------
// Assertion 1
// Requirement:
// Whenever clear_word_counter is asserted,
// the counter shall become zero on the next cycle.
//--------------------------------------------------------------

property p_counter_clear;

    @(posedge clk)

    clear_word_counter
    |=>
    (word_counter == '0);

endproperty

assert property(p_counter_clear)
    else $error("Word counter failed to clear.");


//--------------------------------------------------------------
// Assertion 2
// Requirement:
// Whenever increment_word_counter is asserted,
// the counter shall increment by exactly one.
//--------------------------------------------------------------

property p_counter_increment;

    @(posedge clk)

    increment_word_counter
    |=>
    (word_counter == ($past(word_counter) + 1));

endproperty

assert property(p_counter_increment)
    else $error("Word counter failed to increment correctly.");


//--------------------------------------------------------------
// Assertion 3
// Requirement:
// If neither clear nor increment is asserted,
// the counter shall remain unchanged.
//--------------------------------------------------------------

property p_counter_hold;

    @(posedge clk)

    (!clear_word_counter && !increment_word_counter)
    |=>
    $stable(word_counter);

endproperty

assert property(p_counter_hold)
    else $error("Word counter changed unexpectedly.");


//--------------------------------------------------------------
// Assertion 4
// Requirement:
// Counter shall never exceed the final descriptor word.
//--------------------------------------------------------------

property p_counter_within_bounds;

    @(posedge clk)

    word_counter <= (WORDS_PER_DESCRIPTOR-1);

endproperty

assert property(p_counter_within_bounds)
    else $error("Word counter exceeded descriptor size.");


//--------------------------------------------------------------
// Assertion 5
// Requirement:
// Counter may increment only during CAPTURE.
//--------------------------------------------------------------

property p_counter_increment_only_capture;

    @(posedge clk)

    increment_word_counter
    |->
    (current_state == DFU_CAPTURE);

endproperty

assert property(p_counter_increment_only_capture)
    else $error("Counter incremented outside CAPTURE state.");


//--------------------------------------------------------------
// Assertion 6
// Requirement:
// After a new transaction starts,
// the counter shall begin at zero.
//--------------------------------------------------------------

property p_counter_zero_after_start;

    @(posedge clk)

    $rose(start)
    |=>
    (word_counter == '0);

endproperty

assert property(p_counter_zero_after_start)
    else $error("Counter not initialized after start.");


//--------------------------------------------------------------
// Assertion 7
// Requirement:
// If the FSM reaches COMPLETE,
// the previous counter value must have been the
// final descriptor word.
//--------------------------------------------------------------

property p_complete_after_last_word;

    @(posedge clk)

    (current_state == DFU_COMPLETE)
    |->
    ($past(word_counter) == (WORDS_PER_DESCRIPTOR-1));

endproperty

assert property(p_complete_after_last_word)
    else $error("COMPLETE reached before final descriptor word.");


//--------------------------------------------------------------
// Assertion 8
// Requirement:
// Counter shall never be cleared and incremented
// simultaneously.
//--------------------------------------------------------------

property p_clear_increment_mutually_exclusive;

    @(posedge clk)

    !(clear_word_counter && increment_word_counter);

endproperty

assert property(p_clear_increment_mutually_exclusive)
    else $error("Counter clear and increment asserted together.");

`endif

endmodule