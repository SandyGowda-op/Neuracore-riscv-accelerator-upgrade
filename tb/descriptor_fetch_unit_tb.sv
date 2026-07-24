/******************************************************************************
 *
 * Testbench : descriptor_fetch_unit_tb
 *
 * Version : 2.0
 *
 * Description:
 *
 *     Verification Environment for the Descriptor Fetch Unit.
 *
 *     TB Version 2.0 contains:
 *
 *         ✓ Clock Generation
 *         ✓ Reset Generation
 *         ✓ DUT Instantiation
 *         ✓ Descriptor Memory Instantiation
 *         ✓ CPU Driver Tasks
 *
 ******************************************************************************/

`timescale 1ns/1ps

import descriptor_pkg::*;

module descriptor_fetch_unit_tb;

    logic test_done;

    //==========================================================
    // Clock / Reset
    //==========================================================

    logic clk;
    logic rst;

    //==========================================================
    // CPU Interface
    //==========================================================

    logic cpu_re;
    logic cpu_we;

    logic [DESC_INDEX_WIDTH-1:0]
          cpu_desc_idx;

    logic [WORD_COUNTER_WIDTH-1:0]
          cpu_word_offset;

    descriptor_mem_word_t cpu_wdata;
    descriptor_mem_word_t cpu_rdata;

    //==========================================================
    // DFU Control Interface
    //==========================================================

    logic start;

    logic [DESC_INDEX_WIDTH-1:0]
          descriptor_index;

    //==========================================================
    // DFU <-> Descriptor Memory
    //==========================================================

    logic dfu_re;

    logic [DESC_INDEX_WIDTH-1:0]
          dfu_desc_idx;

    logic [WORD_COUNTER_WIDTH-1:0]
          dfu_word_offset;

    descriptor_mem_word_t dfu_rdata;

    //==========================================================
    // DFU Outputs
    //==========================================================

    logic busy;

    logic done;

    descriptor_t descriptor_out;

    //==========================================================
    // Descriptor Memory
    //==========================================================

    descriptor_memory
    u_descriptor_memory
    (

        .clk(clk),

        .cpu_re(cpu_re),
        .cpu_we(cpu_we),

        .cpu_desc_idx(cpu_desc_idx),
        .cpu_word_offset(cpu_word_offset),

        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),

        .dfu_re(dfu_re),
        .dfu_desc_idx(dfu_desc_idx),
        .dfu_word_offset(dfu_word_offset),

        .dfu_rdata(dfu_rdata)

    );

    //==========================================================
    // Descriptor Fetch Unit
    //==========================================================

    descriptor_fetch_unit
    u_descriptor_fetch_unit
    (

        .clk(clk),
        .rst(rst),

        .start(start),

        .descriptor_index(descriptor_index),

        .dfu_re(dfu_re),

        .dfu_desc_idx(dfu_desc_idx),

        .dfu_word_offset(dfu_word_offset),

        .dfu_rdata(dfu_rdata),

        .busy(busy),

        .done(done),

        .descriptor_out(descriptor_out)

    );

dfu_state_assertions state_asserts
(
    .clk(dut.clk),
    .rst(dut.rst),
    .start(dut.start),

    .last_word(dut.last_word),

    .current_state(dut.current_state),
    .next_state(dut.next_state)
);


  //==========================================================
// Task : Write One Descriptor Word
//==========================================================

task automatic write_descriptor_word
(

    input logic [DESC_INDEX_WIDTH-1:0]
                desc_idx,

    input logic [WORD_COUNTER_WIDTH-1:0]
                word_idx,

    input descriptor_mem_word_t
                data

);

begin

    //------------------------------------------------------
    // Drive signals BEFORE sampling edge
    //------------------------------------------------------

    @(negedge clk);

    cpu_desc_idx    = desc_idx;

    cpu_word_offset = word_idx;

    cpu_wdata       = data;

    cpu_we          = 1'b1;

    $display(
        "[%0t] WRITE REQUEST  Desc=%0d Word=%0d Data=%h",
        $time,
        desc_idx,
        word_idx,
        data
    );

    //------------------------------------------------------
    // Memory samples at next rising edge
    //------------------------------------------------------

    @(posedge clk);

    //------------------------------------------------------
    // Hold WE until after sampling edge
    //------------------------------------------------------

    @(negedge clk);

    cpu_we = 1'b0;

end

endtask

    //==========================================================
// Task : Read One Descriptor Word
//==========================================================

task automatic read_descriptor_word
(

    input logic [DESC_INDEX_WIDTH-1:0]
                desc_idx,

    input logic [WORD_COUNTER_WIDTH-1:0]
                word_idx

);

begin

    //------------------------------------------------------
    // Drive address BEFORE sampling edge
    //------------------------------------------------------

    @(negedge clk);

    cpu_desc_idx    = desc_idx;

    cpu_word_offset = word_idx;

    cpu_re          = 1'b1;

    //------------------------------------------------------
    // Memory performs synchronous read
    //------------------------------------------------------

    @(posedge clk);

    //------------------------------------------------------
    // Wait one cycle for registered output
    //------------------------------------------------------

    @(posedge clk);

    #1;

    $display(
        "[%0t] READ RESPONSE Desc=%0d Word=%0d Data=%h",
        $time,
        desc_idx,
        word_idx,
        cpu_rdata
    );

    //------------------------------------------------------
    // Deassert read
    //------------------------------------------------------

    @(negedge clk);

    cpu_re = 1'b0;

end

endtask

    //==========================================================
    // Clock Generator
    //==========================================================

    initial
        clk = 1'b0;

    always
        #5 clk = ~clk;

    //==========================================================
    // Reset Generator
    //==========================================================

    initial
    begin

        rst = 1'b1;
        test_done = 1'b0;
        //------------------------------------------------------
        // CPU Interface
        //------------------------------------------------------

        cpu_re = 1'b0;
        cpu_we = 1'b0;

        cpu_desc_idx = '0;
        cpu_word_offset = '0;

        cpu_wdata = '0;

        //------------------------------------------------------
        // DFU Interface
        //------------------------------------------------------

        start = 1'b0;

        descriptor_index = '0;

        //------------------------------------------------------
        // Apply Reset
        //------------------------------------------------------

        repeat(5)
            @(posedge clk);

        rst = 1'b0;

        $display("[%0t] RESET RELEASED", $time);

    end

        //==========================================================
    // Directed Test #1
    //
    // Objective:
    //     Verify that
    //
    //         CPU
    //             ↓
    //     Descriptor Memory
    //             ↓
    //          DFU Fetch
    //
    // operates correctly for one descriptor.
    //==========================================================

    initial
    begin

        //------------------------------------------------------
        // Wait for reset release
        //------------------------------------------------------

        @(negedge rst);

        $display("");
        $display("===============================================");
        $display(" Descriptor Fetch Unit Verification");
        $display("===============================================");
        $display("");

        //------------------------------------------------------
        // Load Descriptor 0
        //------------------------------------------------------

        write_descriptor_word(
            0,
            DESC_WORD_SRCA,
            32'h1000_0000
        );

        write_descriptor_word(
            0,
            DESC_WORD_SRCB,
            32'h2000_0000
        );

        write_descriptor_word(
            0,
            DESC_WORD_DST,
            32'h3000_0000
        );

        write_descriptor_word(
            0,
            DESC_WORD_ROWS_COLS,
            {16'd64,16'd32}
        );

        write_descriptor_word(
            0,
            DESC_WORD_K_STRIDEA,
            {16'd16,16'd64}
        );

        write_descriptor_word(
            0,
            DESC_WORD_STRIDEB_C,
            {16'd32,16'd64}
        );

        write_descriptor_word(
            0,
            DESC_WORD_DATATYPE,
            32'h0000_0000
        );

        write_descriptor_word(
            0,
            DESC_WORD_FLAGS,
            32'h0000_0001
        );

        write_descriptor_word(
            0,
            DESC_WORD_STATUS,
            32'h0000_0000
        );

        write_descriptor_word(
            0,
            DESC_WORD_RESERVED,
            32'hDEAD_BEEF
        );

        //------------------------------------------------------
        // Verify Memory Contents
        //------------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display(" Reading Descriptor Back");
        $display("-----------------------------------------------");

        read_descriptor_word(0, DESC_WORD_SRCA);
        read_descriptor_word(0, DESC_WORD_SRCB);
        read_descriptor_word(0, DESC_WORD_DST);
        read_descriptor_word(0, DESC_WORD_ROWS_COLS);
        read_descriptor_word(0, DESC_WORD_K_STRIDEA);
        read_descriptor_word(0, DESC_WORD_STRIDEB_C);
        read_descriptor_word(0, DESC_WORD_DATATYPE);
        read_descriptor_word(0, DESC_WORD_FLAGS);
        read_descriptor_word(0, DESC_WORD_STATUS);
        read_descriptor_word(0, DESC_WORD_RESERVED);

        //------------------------------------------------------
        // Start DFU
        //------------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display(" Starting Descriptor Fetch");
        $display("-----------------------------------------------");

        descriptor_index = 0;

        @(posedge clk);

        start = 1'b1;

        @(posedge clk);

        start = 1'b0;
        test_done = 1'b1;
        //------------------------------------------------------
        // Wait for Completion
        //------------------------------------------------------

        wait(done);

        @(posedge clk);

        //------------------------------------------------------
        // Print Descriptor
        //------------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display(" Descriptor Returned By DFU");
        $display("-----------------------------------------------");

        $display("srcA      = %h", descriptor_out.srcA_addr);
        $display("srcB      = %h", descriptor_out.srcB_addr);
        $display("dst       = %h", descriptor_out.dst_addr);

        $display("rows      = %0d", descriptor_out.rows);
        $display("cols      = %0d", descriptor_out.cols);
        $display("k         = %0d", descriptor_out.k);

        $display("strideA   = %0d", descriptor_out.strideA);
        $display("strideB   = %0d", descriptor_out.strideB);
        $display("strideC   = %0d", descriptor_out.strideC);

        $display("datatype  = %0d", descriptor_out.datatype);

        $display("flags     = %h", descriptor_out.flags);
        $display("status    = %h", descriptor_out.status);

        $display("reserved  = %h", descriptor_out.reserved1);

        $display("");
        $display("===============================================");
        $display(" Directed Test Completed");
        $display("===============================================");

    end

    //==========================================================
    // Waveform Dump
    //==========================================================

    initial
    begin

        $dumpfile("tb/waveforms/dfu_tb.vcd");

        $dumpvars(0, descriptor_fetch_unit_tb);

    end

    //==========================================================
// Timeout Monitor
//==========================================================

initial
begin : timeout_thread

    repeat(300)
    begin

        @(posedge clk);

        if (test_done)
            disable timeout_thread;

    end

    $fatal(1, "TEST FAILED : TIMEOUT");

end

endmodule