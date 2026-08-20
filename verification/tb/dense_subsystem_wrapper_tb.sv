//==============================================================================
// Testbench    : dense_subsystem_wrapper_tb
// Project      : Descriptor-Driven RISC-V AI Accelerator
//
// Milestone 1 Verification:
//
//   Descriptor
//       |
//       v
//   Dense Scheduler
//       |
//       v
//   Tile Walker / Generator
//       |
//       v
//   Transfer Engine
//       |
//       +---- Main Memory
//       |
//       +---- Scratchpad Controller
//                    |
//                    v
//                Scratchpad
//
// Verification focus:
//   1. Descriptor-driven tile generation
//   2. A memory request
//   3. B memory request
//   4. Burst sizes
//   5. Memory beat flow
//   6. Scratchpad bank selection
//   7. Transfer completion
//   8. Dense scheduler completion
//
// Sparse datapath is intentionally NOT included in this milestone.
//
//==============================================================================

`timescale 1ns/1ps

import descriptor_pkg::*;
import tile_pkg::*;

module dense_subsystem_wrapper_tb;

    //==========================================================================
    // Parameters
    //==========================================================================

    localparam integer CLK_PERIOD = 10;

    //==========================================================================
    // Clock / Reset
    //==========================================================================

    logic clk;
    logic rst;

    //==========================================================================
    // Descriptor Interface
    //==========================================================================

    logic       start;
    descriptor_t descriptor;

    logic dense_done;

    //==========================================================================
    // Transfer Status
    //==========================================================================

    logic transfer_busy;
    logic transfer_done;

    //==========================================================================
    // Scratchpad Debug Outputs
    //==========================================================================

    logic [3:0]  debug_spad_bank;
    logic [31:0] debug_spad_address;
    logic [63:0] debug_spad_write_data;
    logic        debug_spad_write_enable;

    logic completion_seen;

    //==========================================================================
    // DUT
    //==========================================================================

    dense_subsystem_wrapper #(
        .DATA_WIDTH      (32),
        .SPAD_DEPTH      (64),
        .SPAD_ADDR_WIDTH (6)
    ) dut (

        .clk   (clk),
        .rst   (rst),

        .start      (start),
        .descriptor (descriptor),

        .dense_done (dense_done),

        .transfer_busy (transfer_busy),
        .transfer_done(transfer_done),

        .debug_spad_bank        (debug_spad_bank),
        .debug_spad_address     (debug_spad_address),
        .debug_spad_write_data  (debug_spad_write_data),
        .debug_spad_write_enable(debug_spad_write_enable)
    );

    //==========================================================================
    // Clock Generation
    //==========================================================================

    initial begin
        clk = 1'b0;

        forever #(CLK_PERIOD / 2)
            clk = ~clk;
    end

    //==========================================================================
    // Descriptor Initialization
    //==========================================================================

    task automatic build_descriptor;

        begin

            descriptor = '0;

            //--------------------------------------------------------------
            // Main memory addresses
            //--------------------------------------------------------------

            descriptor.srcA_addr = 32'h1000_0000;
            descriptor.srcB_addr = 32'h1000_0100;

            //--------------------------------------------------------------
            // Destination
            //--------------------------------------------------------------

            descriptor.dst_addr = 32'h1000_0200;

            //--------------------------------------------------------------
            // Matrix dimensions
            //
            // One 8x8x8 tile for the first integration milestone.
            //--------------------------------------------------------------

            descriptor.rows = 16'd8;
            descriptor.cols = 16'd8;
            descriptor.k    = 16'd8;

            //--------------------------------------------------------------
            // Byte strides
            //
            // 8 elements × 4 bytes = 32 bytes per row.
            //--------------------------------------------------------------

            descriptor.strideA = 32'd32;
            descriptor.strideB = 32'd32;
            descriptor.strideC = 32'd32;

            //--------------------------------------------------------------
            // 32-bit elements
            //--------------------------------------------------------------

            descriptor.bytes_per_element = 8'd4;

            //--------------------------------------------------------------
            // Dense execution
            //--------------------------------------------------------------

            descriptor.flags = 32'd0;

        end

    endtask

    //==========================================================================
    // Reset
    //==========================================================================

    task automatic reset_dut;

        begin

            rst   = 1'b1;
            start = 1'b0;

            descriptor = '0;

            repeat (4)
                @(posedge clk);

            rst = 1'b0;

            @(posedge clk);

        end

    endtask

    //==========================================================================
    // Test Start
    //==========================================================================

    task automatic start_descriptor;

        begin

            build_descriptor();

            @(posedge clk);

            start = 1'b1;

            start = 1'b1;

$display(
    "[TB_START_DEBUG] t=%0t start=%b rst=%b",
    $time,
    start,
    rst
);


            @(posedge clk);

            start = 1'b0;

        end

    endtask

        //==========================================================================
    // Verification Counters
    //==========================================================================

    integer mem_request_count;
    integer mem_beat_count;
    integer rlast_count;

    integer spad_write_count;

    integer a_request_count;
    integer b_request_count;

    integer a_write_count;
    integer b_write_count;

    logic [31:0] first_mem_addr;
    logic [31:0] second_mem_addr;

    logic [31:0] first_mem_bytes;
    logic [31:0] second_mem_bytes;

    logic [3:0] first_spad_bank;
    logic [3:0] second_spad_bank;

    //==========================================================================
    // Expected Values
    //==========================================================================

    localparam integer EXPECTED_BURST_BYTES = 128;

    // 8x8 matrix:
    //
    // 64 elements × 4 bytes = 256 bytes.
    //
    // Therefore:
    //
    // A = 256 bytes = 2 × 128-byte bursts
    // B = 256 bytes = 2 × 128-byte bursts
    //
    // Total:
    //   Requests = 4
    //   Beats    = 4 × 16 = 64
    //   RLAST    = 4
    //
    localparam integer EXPECTED_MEM_REQUESTS = 4;
    localparam integer EXPECTED_MEM_BEATS    = 64;
    localparam integer EXPECTED_RLAST        = 4;
    localparam integer EXPECTED_SPAD_WRITES  = 64;

    //==========================================================================
    // Monitor
    //==========================================================================
    //
    // Observe the actual interfaces generated by the integrated subsystem.
    //
    // No DUT signal is modified here.
    //
    //==========================================================================

    always @(posedge clk)
    begin

        if (!rst)
        begin

            //--------------------------------------------------------------
            // Memory request monitor
            //--------------------------------------------------------------

            if (dut.mem_req_valid &&
                dut.mem_req_ready)
            begin

                mem_request_count = mem_request_count + 1;

                if (mem_request_count == 1)
                begin
                    first_mem_addr  = dut.mem_req_addr;
                    first_mem_bytes = dut.mem_req_bytes;
                end

                else if (mem_request_count == 2)
                begin
                    second_mem_addr  = dut.mem_req_addr;
                    second_mem_bytes = dut.mem_req_bytes;
                end

                //----------------------------------------------------------
                // Identify A/B request based on address range.
                // A occupies 0x10000000 - 0x100000FF
                // B occupies 0x10000100 - 0x100001FF
                //----------------------------------------------------------

                if ((dut.mem_req_addr >= 32'h1000_0000) &&
                (dut.mem_req_addr <  32'h1000_0100))
                begin
                    a_request_count = a_request_count + 1;
                end

                else if ((dut.mem_req_addr >= 32'h1000_0100) &&
                        (dut.mem_req_addr <  32'h1000_0200))
                begin
                    b_request_count = b_request_count + 1;
                end

                
            end

            //----------------------------------------------------------
            // Completion monitor
            //----------------------------------------------------------

            if (dut.transfer_done || dut.dense_done)
                completion_seen = 1'b1;

            //--------------------------------------------------------------
            // Memory beat monitor
            //--------------------------------------------------------------

            if (dut.mem_rvalid)
            begin

                mem_beat_count = mem_beat_count + 1;

                if (dut.mem_rlast)
                    rlast_count = rlast_count + 1;

            end

            //--------------------------------------------------------------
            // Scratchpad write monitor
            //--------------------------------------------------------------

            if (dut.debug_spad_write_enable)
            begin

                spad_write_count = spad_write_count + 1;

                //----------------------------------------------------------
                // Bank identification
                //----------------------------------------------------------

                if (dut.debug_spad_bank == 4'd0)
                    a_write_count = a_write_count + 1;

                else if (dut.debug_spad_bank == 4'd1)
                    b_write_count = b_write_count + 1;

                //----------------------------------------------------------
                // Capture first two writes for visibility.
                //----------------------------------------------------------

                if (spad_write_count == 1)
                    first_spad_bank = dut.debug_spad_bank;

                else if (spad_write_count == 17)
                    second_spad_bank = dut.debug_spad_bank;

            end

        end

    end

    //==========================================================================
    // Counter Reset
    //==========================================================================

    task automatic clear_counters;

        begin

            mem_request_count = 0;
            mem_beat_count    = 0;
            rlast_count       = 0;

            spad_write_count  = 0;

            completion_seen = 1'b0;

            a_request_count   = 0;
            b_request_count   = 0;

            a_write_count     = 0;
            b_write_count     = 0;

            first_mem_addr    = '0;
            second_mem_addr   = '0;

            first_mem_bytes   = '0;
            second_mem_bytes  = '0;

            first_spad_bank   = '0;
            second_spad_bank  = '0;

        end

    endtask

    //==========================================================================
    // Integer Check
    //==========================================================================

    task automatic check_equal_integer;

        input integer expected;
        input integer observed;
        input string  name;

        begin

            if (expected == observed)
            begin

                $display(
                    "[PASS] %s expected=%0d observed=%0d",
                    name,
                    expected,
                    observed
                );

            end

            else
            begin

                $display(
                    "[FAIL] %s expected=%0d observed=%0d",
                    name,
                    expected,
                    observed
                );

            end

        end

    endtask

    //==========================================================================
    // Hex Check
    //==========================================================================

    task automatic check_equal_hex;

        input logic [31:0] expected;
        input logic [31:0] observed;
        input string       name;

        begin

            if (expected == observed)
            begin

                $display(
                    "[PASS] %s expected=%08h observed=%08h",
                    name,
                    expected,
                    observed
                );

            end

            else
            begin

                $display(
                    "[FAIL] %s expected=%08h observed=%08h",
                    name,
                    expected,
                    observed
                );

            end

        end

    endtask

    //==========================================================================
    // Completion Wait
    //==========================================================================

    task automatic wait_for_completion;

        integer timeout_count;

        begin

            timeout_count = 0;

            while (!dense_done)
            begin

                @(posedge clk);

                timeout_count = timeout_count + 1;

                if (timeout_count > 5000)
                begin

                    $display("");
                    $display("[FATAL] Dense subsystem timeout");
                    $display(
                        "        Scheduler did not assert dense_done."
                    );

                    $finish;

                end

            end

        end

    endtask

    //==========================================================================
    // Final Verification
    //==========================================================================

    task automatic run_checks;

        integer failures;

        begin

            failures = 0;

            $display("");
            $display("====================================================");
            $display("DENSE SUBSYSTEM INTEGRATION RESULTS");
            $display("====================================================");

            //--------------------------------------------------------------
            // Memory requests
            //--------------------------------------------------------------

            check_equal_integer(
                EXPECTED_MEM_REQUESTS,
                mem_request_count,
                "Memory request count"
            );

            if (EXPECTED_MEM_REQUESTS != mem_request_count)
                failures = failures + 1;

            //--------------------------------------------------------------
            // Memory beats
            //--------------------------------------------------------------

            check_equal_integer(
                EXPECTED_MEM_BEATS,
                mem_beat_count,
                "Memory beat count"
            );

            if (EXPECTED_MEM_BEATS != mem_beat_count)
                failures = failures + 1;

            //--------------------------------------------------------------
            // RLAST
            //--------------------------------------------------------------

            check_equal_integer(
                EXPECTED_RLAST,
                rlast_count,
                "RLAST count"
            );

            if (EXPECTED_RLAST != rlast_count)
                failures = failures + 1;

            //--------------------------------------------------------------
            // Scratchpad writes
            //--------------------------------------------------------------

            check_equal_integer(
                EXPECTED_SPAD_WRITES,
                spad_write_count,
                "Scratchpad write count"
            );

            if (EXPECTED_SPAD_WRITES != spad_write_count)
                failures = failures + 1;

            //--------------------------------------------------------------
            // A requests
            //--------------------------------------------------------------

            check_equal_integer(
                2,
                a_request_count,
                "Matrix A request count"
            );

            if (a_request_count != 2)
                failures = failures + 1;

            //--------------------------------------------------------------
            // B requests
            //--------------------------------------------------------------

            check_equal_integer(
                2,
                b_request_count,
                "Matrix B request count"
            );

            if (b_request_count != 2)
                failures = failures + 1;

            //--------------------------------------------------------------
            // A scratchpad writes
            //--------------------------------------------------------------

            check_equal_integer(
                32,
                a_write_count,
                "Matrix A scratchpad writes"
            );

            if (a_write_count != 32)
                failures = failures + 1;

            //--------------------------------------------------------------
            // B scratchpad writes
            //--------------------------------------------------------------

            check_equal_integer(
                32,
                b_write_count,
                "Matrix B scratchpad writes"
            );

            if (b_write_count != 32)
                failures = failures + 1;

            //--------------------------------------------------------------
            // First memory address
            //--------------------------------------------------------------

            check_equal_hex(
                32'h1000_0000,
                first_mem_addr,
                "First memory request is A"
            );

            if (first_mem_addr != 32'h1000_0000)
                failures = failures + 1;

            //--------------------------------------------------------------
            // First burst size
            //--------------------------------------------------------------

            check_equal_hex(
                32'd128,
                first_mem_bytes,
                "First burst size"
            );

            if (first_mem_bytes != 32'd128)
                failures = failures + 1;

            //--------------------------------------------------------------
            // Second memory request
            //
            // The second request is still expected to be A because
            // A is 256 bytes and therefore requires two bursts.
            //--------------------------------------------------------------

            check_equal_hex(
                32'h1000_0080,
                second_mem_addr,
                "Second memory request is A burst 2"
            );

            if (second_mem_addr != 32'h1000_0080)
                failures = failures + 1;

            //--------------------------------------------------------------
            // Second burst size
            //--------------------------------------------------------------

            check_equal_hex(
                32'd128,
                second_mem_bytes,
                "Second burst size"
            );

            if (second_mem_bytes != 32'd128)
                failures = failures + 1;

            //--------------------------------------------------------------
            // Transfer completion
            //--------------------------------------------------------------

            if (completion_seen)
            begin

                $display(
                    "[PASS] Dense transfer/scheduler completion observed"
                );

            end

            else
            begin

                $display(
                    "[FAIL] Dense transfer/scheduler completion"
                );

                failures = failures + 1;

            end

            //--------------------------------------------------------------
            // Summary
            //--------------------------------------------------------------

            $display("");
            $display("====================================================");

            if (failures == 0)
            begin

                $display("DENSE SUBSYSTEM MILESTONE 1 : PASS");

            end

            else
            begin

                $display(
                    "DENSE SUBSYSTEM MILESTONE 1 : FAIL (%0d checks)",
                    failures
                );

            end

            $display("====================================================");

        end

    endtask

    //==========================================================================
    // Replace the temporary ending of Part 1 with this final test sequence.
    //==========================================================================

    initial
    begin

        // Reinitialize counters before starting the actual test.
        clear_counters();

        reset_dut();

        start_descriptor();

        wait_for_completion();

        // Allow completion-related signals to settle.
        @(posedge clk);

        run_checks();

        $finish;

    end

endmodule