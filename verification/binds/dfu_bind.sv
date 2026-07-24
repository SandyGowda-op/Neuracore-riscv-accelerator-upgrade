`timescale 1ns/1ps

import descriptor_pkg::*;

//==========================================================
// Bind State Assertions
//==========================================================

bind descriptor_fetch_unit
dfu_state_assertions u_state_assertions
(
    .clk(clk),
    .rst(rst),
    .start(start),

    .last_word(last_word),

    .current_state(current_state),
    .next_state(next_state)
);

//==========================================================
// Bind Protocol Assertions
//==========================================================

bind descriptor_fetch_unit
dfu_protocol_assertions u_protocol_assertions
(
    .clk(clk),

    .current_state(current_state),

    .busy(busy),
    .done(done),

    .dfu_re(dfu_re),

    .descriptor_index_reg(descriptor_index_reg),
    .dfu_desc_idx(dfu_desc_idx),

    .word_counter(word_counter),
    .dfu_word_offset(dfu_word_offset),

    .descriptor_out(descriptor_out),

    .commit_descriptor(commit_descriptor)
);

//==========================================================
// Bind Counter Assertions
//==========================================================

bind descriptor_fetch_unit
dfu_counter_assertions u_counter_assertions
(
    .clk(clk),

    .clear_word_counter(clear_word_counter),
    .increment_word_counter(increment_word_counter),

    .start(start),
    .last_word(last_word),

    .word_counter(word_counter),

    .current_state(current_state)
);

//==========================================================
// Bind Output Assertions
//==========================================================

bind descriptor_fetch_unit
dfu_output_assertions u_output_assertions
(
    .clk(clk),

    .busy(busy),
    .done(done),

    .commit_descriptor(commit_descriptor),

    .current_state(current_state),

    .working_desc(working_desc),

    .descriptor_out(descriptor_out)
);

//==========================================================
// Bind Liveness Assertions
//==========================================================

bind descriptor_fetch_unit
dfu_liveness_assertions u_liveness_assertions
(
    .clk(clk),

    .start(start),

    .busy(busy),
    .done(done),

    .commit_descriptor(commit_descriptor),

    .current_state(current_state)
);