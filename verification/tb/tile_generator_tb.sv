`timescale 1ns/1ps

import descriptor_pkg::*;
import tile_pkg::*;

module tile_generator_tb;

    //======================================================================
    // DUT Inputs
    //======================================================================

    descriptor_t   descriptor;
    tile_context_t current_tile;
    logic          last_tile;

    //======================================================================
    // DUT Output
    //======================================================================

    tile_request_t tile_request;

    //======================================================================
    // DUT
    //======================================================================

    tile_generator dut (

        .descriptor   (descriptor),
        .current_tile(current_tile),
        .last_tile    (last_tile),
        .tile_request (tile_request)

    );

    //======================================================================
    // Test Counters
    //======================================================================

    integer tests_executed;
    integer tests_passed;
    integer tests_failed;

    //======================================================================
    // Check Task
    //======================================================================

    task automatic check;

        input logic condition;
        input [255:0] message;

        begin

            tests_executed = tests_executed + 1;

            if (condition) begin

                tests_passed = tests_passed + 1;

                $display(
                    "[PASS] %0s",
                    message
                );

            end

            else begin

                tests_failed = tests_failed + 1;

                $display(
                    "[FAIL] %0s",
                    message
                );

            end

        end

    endtask

    //======================================================================
    // Descriptor Setup
    //
    // 128 x 128 x 128 GEMM
    //
    // A base = 0x1000
    // B base = 0x8000
    // C base = 0x10000
    //
    // Element size = 4 bytes
    //
    // Row stride = 128 elements * 4 = 512 bytes
    //
    //======================================================================

    task automatic initialize_descriptor;

        begin

            descriptor = '0;

            descriptor.srcA_addr =
                32'h0000_1000;

            descriptor.srcB_addr =
                32'h0000_8000;

            descriptor.dst_addr =
                32'h0001_0000;

            descriptor.rows =
                16'd128;

            descriptor.cols =
                16'd128;

            descriptor.k =
                16'd128;

            descriptor.strideA =
                16'd512;

            descriptor.strideB =
                16'd512;

            descriptor.strideC =
                16'd512;

            descriptor.bytes_per_element =
                16'd4;

        end

    endtask

    //======================================================================
    // Set Tile
    //======================================================================

    task automatic set_tile;

        input integer row;
        input integer col;
        input integer k_index;

        begin

            current_tile.tile_row = row;
            current_tile.tile_col = col;
            current_tile.tile_k   = k_index;

        end

    endtask

    //======================================================================
    // TEST 1
    //
    // First full tile: (0,0,0)
    //
    //======================================================================

    task automatic test_first_tile;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 1 : FIRST FULL TILE");
            $display("====================================================");

            set_tile(0, 0, 0);

            last_tile = 1'b0;

            #1;

            check(
                tile_request.valid == 1'b1,
                "Tile request valid"
            );

            check(
                tile_request.addr_a == 32'h0000_1000,
                "Tile A base address correct"
            );

            check(
                tile_request.addr_b == 32'h0000_8000,
                "Tile B base address correct"
            );

            check(
                tile_request.addr_c == 32'h0001_0000,
                "Tile C base address correct"
            );

            check(
                tile_request.rows == 16'd64,
                "Tile rows = 64"
            );

            check(
                tile_request.cols == 16'd64,
                "Tile cols = 64"
            );

            check(
                tile_request.k_size == 16'd64,
                "Tile K = 64"
            );

            check(
                tile_request.stride_a == 16'd512,
                "A stride propagated"
            );

            check(
                tile_request.stride_b == 16'd512,
                "B stride propagated"
            );

        end

    endtask

    //======================================================================
    // TEST 2
    //
    // Tile context propagation
    //
    //======================================================================

    task automatic test_context;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 2 : TILE CONTEXT");
            $display("====================================================");

            set_tile(1, 0, 0);

            last_tile = 1'b0;

            #1;

            check(
                tile_request.tile_context.tile_row == 16'd1,
                "Tile row propagated"
            );

            check(
                tile_request.tile_context.tile_col == 16'd0,
                "Tile col propagated"
            );

            check(
                tile_request.tile_context.tile_k == 16'd0,
                "Tile K index propagated"
            );

        end

    endtask

    //======================================================================
    // TEST 3
    //
    // Row/column tile address calculation
    //
    // Tile = (1,1,0)
    //
    // A offset = 1 * 64 * 512
    //          = 32768 bytes
    //
    // A address = 0x1000 + 0x8000
    //           = 0x9000
    //
    // B offset = 1 * 64 * 4
    //          = 256 bytes
    //
    // B address = 0x8000 + 0x100
    //           = 0x8100
    //
    // C offset:
    //   row = 1 * 64 * 512 = 32768
    //   col = 1 * 64 * 4   = 256
    //
    // C = 0x10000 + 32768 + 256
    //   = 0x18200
    //
    //======================================================================

    task automatic test_spatial_addressing;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 3 : SPATIAL TILE ADDRESSING");
            $display("====================================================");

            set_tile(1, 1, 0);

            last_tile = 1'b0;

            #1;

            check(
                tile_request.addr_a == 32'h0000_9000,
                "Tile (1,1,0) A address correct"
            );

            check(
                tile_request.addr_b == 32'h0000_8100,
                "Tile (1,1,0) B address correct"
            );

            check(
                tile_request.addr_c == 32'h0001_8100,
                "Tile (1,1,0) C address correct"
            );

        end

    endtask

    //======================================================================
    // TEST 4
    //
    // K-tile addressing
    //
    // Tile = (0,0,1)
    //
    // A offset = 64 * 4 = 256
    // B offset = 64 * 512 = 32768
    //
    //======================================================================

    task automatic test_k_tile;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 4 : K TILE ADDRESSING");
            $display("====================================================");

            set_tile(0, 0, 1);

            last_tile = 1'b0;

            #1;

            check(
                tile_request.addr_a == 32'h0000_1100,
                "K tile A address correct"
            );

            check(
                tile_request.addr_b == 32'h0001_0000,
                "K tile B address correct"
            );

            check(
                tile_request.rows == 16'd64,
                "K tile rows correct"
            );

            check(
                tile_request.cols == 16'd64,
                "K tile cols correct"
            );

            check(
                tile_request.k_size == 16'd64,
                "K tile K size correct"
            );

        end

    endtask

    //======================================================================
    // TEST 5
    //
    // Combined spatial + K addressing
    //
    // Tile = (1,1,1)
    //
    //======================================================================

    task automatic test_combined_tile;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 5 : COMBINED TILE ADDRESSING");
            $display("====================================================");

            set_tile(1, 1, 1);

            last_tile = 1'b0;

            #1;

            check(
                tile_request.addr_a == 32'h0000_9100,
                "Combined A address correct"
            );

            check(
                tile_request.addr_b == 32'h0001_0100,
                "Combined B address correct"
            );

            check(
                tile_request.addr_c == 32'h0001_8100,
                "Combined C address correct"
            );

        end

    endtask

    //======================================================================
    // TEST 6
    //
    // Transfer size
    //
    // 64 * 64 * 4 = 16384 bytes
    //
    //======================================================================

    task automatic test_transfer_size;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 6 : TRANSFER SIZE");
            $display("====================================================");

            set_tile(0, 0, 0);

            last_tile = 1'b0;

            #1;

            check(
                tile_request.transfer_bytes == 32'd16384,
                "Transfer size correct"
            );

        end

    endtask

    //======================================================================
    // TEST 7
    //
    // Last tile propagation
    //
    //======================================================================

    task automatic test_last_tile;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 7 : LAST TILE");
            $display("====================================================");

            set_tile(1, 1, 1);

            last_tile = 1'b1;

            #1;

            check(
                tile_request.valid == 1'b1,
                "Final tile request valid"
            );

            check(
                tile_request.last_tile == 1'b1,
                "Last tile flag propagated"
            );

        end

    endtask

    //======================================================================
    // TEST 8
    //
    // Scratchpad bank assignment
    //
    //======================================================================

    task automatic test_bank_assignment;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 8 : SCRATCHPAD BANK ASSIGNMENT");
            $display("====================================================");

            set_tile(0, 0, 0);

            last_tile = 1'b0;

            #1;

            check(
                tile_request.bank_a == 4'd0,
                "A bank assignment correct"
            );

            check(
                tile_request.bank_b == 4'd1,
                "B bank assignment correct"
            );

            check(
                tile_request.bank_c == 4'd2,
                "C bank assignment correct"
            );

        end

    endtask

    //======================================================================
    // TEST 9
    //
    // Partial boundary tile
    //
    // Descriptor:
    //
    // 130 x 130 x 130
    //
    // Tile = (2,2,2)
    //
    // Remaining dimension = 2
    //
    //======================================================================

    task automatic test_partial_tile;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 9 : PARTIAL BOUNDARY TILE");
            $display("====================================================");

            descriptor.rows = 16'd130;
            descriptor.cols = 16'd130;
            descriptor.k    = 16'd130;

            set_tile(2, 2, 2);

            last_tile = 1'b1;

            #1;

            check(
                tile_request.rows == 16'd2,
                "Partial tile rows correct"
            );

            check(
                tile_request.cols == 16'd2,
                "Partial tile cols correct"
            );

            check(
                tile_request.k_size == 16'd2,
                "Partial tile K size correct"
            );

            check(
                tile_request.transfer_bytes == 32'd16,
                "Partial tile transfer size correct"
            );

        end

    endtask

    //======================================================================
    // TEST 10
    //
    // Restore descriptor and verify valid output
    //
    //======================================================================

    task automatic test_valid_output;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 10 : OUTPUT VALIDITY");
            $display("====================================================");

            initialize_descriptor();

            set_tile(0, 0, 0);

            last_tile = 1'b0;

            #1;

            check(
                tile_request.valid == 1'b1,
                "Generator always produces valid request"
            );

            check(
                tile_request.last_tile == 1'b0,
                "Non-final tile marked correctly"
            );

        end

    endtask

    //======================================================================
    // Main Test
    //======================================================================

    initial begin

        tests_executed = 0;
        tests_passed   = 0;
        tests_failed   = 0;

        initialize_descriptor();

        current_tile = '0;
        last_tile    = 1'b0;

        #1;

        test_first_tile();

        test_context();

        test_spatial_addressing();

        test_k_tile();

        test_combined_tile();

        test_transfer_size();

        test_last_tile();

        test_bank_assignment();

        test_partial_tile();

        test_valid_output();

        $display("");
        $display("====================================================");
        $display("TILE GENERATOR REGRESSION");
        $display("====================================================");

        $display(
            "Tests Executed : %0d",
            tests_executed
        );

        $display(
            "Tests Passed   : %0d",
            tests_passed
        );

        $display(
            "Tests Failed   : %0d",
            tests_failed
        );

        if (tests_failed == 0) begin

            $display(
                "OVERALL RESULT : PASS"
            );

        end

        else begin

            $display(
                "OVERALL RESULT : FAIL"
            );

        end

        $display(
            "===================================================="
        );

        $finish;

    end

endmodule