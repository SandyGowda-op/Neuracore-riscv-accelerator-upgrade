`timescale 1ns/1ps

import tile_pkg::*;

module tile_walker_tb;

    //======================================================================
    // Clock / Reset
    //======================================================================

    logic clk;
    logic rst;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //======================================================================
    // DUT Inputs
    //======================================================================

    logic start;
    logic advance;

    logic [15:0] max_tile_rows;
    logic [15:0] max_tile_cols;
    logic [15:0] max_tile_k;

    //======================================================================
    // DUT Outputs
    //======================================================================

    tile_context_t current_tile;

    logic first_tile;
    logic last_tile;
    logic done;

    //======================================================================
    // DUT
    //======================================================================

    tile_walker dut (

        .clk           (clk),
        .rst           (rst),

        .start         (start),
        .advance       (advance),

        .max_tile_rows (max_tile_rows),
        .max_tile_cols (max_tile_cols),
        .max_tile_k    (max_tile_k),

        .current_tile  (current_tile),
        .first_tile    (first_tile),
        .last_tile     (last_tile),
        .done          (done)

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
    // Reset DUT
    //======================================================================

    task automatic reset_dut;

        begin

            rst     = 1'b1;
            start   = 1'b0;
            advance = 1'b0;

            repeat (2)
                @(posedge clk);

            #1;

            rst = 1'b0;

            @(posedge clk);
            #1;

        end

    endtask

    //======================================================================
    // Start Walker
    //======================================================================

    task automatic start_walker;

        begin

            @(negedge clk);

            start = 1'b1;

            @(posedge clk);

            #1;

            start = 1'b0;

        end

    endtask

    //======================================================================
    // Advance Walker
    //======================================================================

    task automatic advance_walker;

        begin

            @(negedge clk);

            advance = 1'b1;

            @(posedge clk);

            #1;

            advance = 1'b0;

        end

    endtask

    //======================================================================
    // Check Current Tile
    //======================================================================

    task automatic check_tile;

        input integer expected_row;
        input integer expected_col;
        input integer expected_k;

        begin

            check(
                current_tile.tile_row == expected_row,
                "Tile row correct"
            );

            check(
                current_tile.tile_col == expected_col,
                "Tile column correct"
            );

            check(
                current_tile.tile_k == expected_k,
                "Tile K index correct"
            );

        end

    endtask

    //======================================================================
    // TEST 1
    //
    // Reset state
    //======================================================================

    task automatic test_reset;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 1 : RESET STATE");
            $display("====================================================");

            check(
                current_tile.tile_row == 16'd0,
                "Reset tile row = 0"
            );

            check(
                current_tile.tile_col == 16'd0,
                "Reset tile col = 0"
            );

            check(
                current_tile.tile_k == 16'd0,
                "Reset tile K = 0"
            );

            check(
                first_tile == 1'b1,
                "Reset position is first tile"
            );

            check(
                last_tile == 1'b0,
                "Reset position is not last tile"
            );

            check(
                done == 1'b0,
                "Reset done = 0"
            );

        end

    endtask

    //======================================================================
    // TEST 2
    //
    // Start traversal
    //======================================================================

    task automatic test_start;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 2 : START TRAVERSAL");
            $display("====================================================");

            start_walker();

            check(
                current_tile.tile_row == 16'd0,
                "Started tile row = 0"
            );

            check(
                current_tile.tile_col == 16'd0,
                "Started tile col = 0"
            );

            check(
                current_tile.tile_k == 16'd0,
                "Started tile K = 0"
            );

            check(
                first_tile == 1'b1,
                "First tile asserted"
            );

            check(
                last_tile == 1'b0,
                "First tile is not final"
            );

            check(
                done == 1'b0,
                "Walker not done after start"
            );

        end

    endtask

    //======================================================================
    // TEST 3
    //
    // K dimension advances first
    //
    // Expected:
    //
    // (0,0,0)
    //      ↓ advance
    // (0,0,1)
    //
    //======================================================================

    task automatic test_k_advance;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 3 : K DIMENSION ADVANCE");
            $display("====================================================");

            advance_walker();

            check_tile(
                0,
                0,
                1
            );

            check(
                first_tile == 1'b0,
                "First tile deasserted after advance"
            );

            check(
                last_tile == 1'b0,
                "Second K tile is not final"
            );

        end

    endtask

    //======================================================================
    // TEST 4
    //
    // K wraps, column increments
    //
    // (0,0,1)
    //      ↓
    // (0,1,0)
    //
    //======================================================================

    task automatic test_column_advance;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 4 : COLUMN ADVANCE");
            $display("====================================================");

            advance_walker();

            check_tile(
                0,
                1,
                0
            );

            check(
                first_tile == 1'b0,
                "First tile remains deasserted"
            );

            check(
                last_tile == 1'b0,
                "Column-advanced tile is not final"
            );

        end

    endtask

    //======================================================================
    // TEST 5
    //
    // Verify complete 2x2x2 traversal sequence.
    //
    // Current position is already (0,1,0).
    //
    // Remaining:
    //
    // (0,1,1)
    // (1,0,0)
    // (1,0,1)
    // (1,1,0)
    // (1,1,1)
    //
    //======================================================================

    task automatic test_remaining_sequence;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 5 : COMPLETE TILE SEQUENCE");
            $display("====================================================");

            //--------------------------------------------------------------
            // (0,1,1)
            //--------------------------------------------------------------

            advance_walker();

            check_tile(0, 1, 1);

            check(
                last_tile == 1'b0,
                "(0,1,1) is not final"
            );

            //--------------------------------------------------------------
            // (1,0,0)
            //--------------------------------------------------------------

            advance_walker();

            check_tile(1, 0, 0);

            check(
                last_tile == 1'b0,
                "(1,0,0) is not final"
            );

            //--------------------------------------------------------------
            // (1,0,1)
            //--------------------------------------------------------------

            advance_walker();

            check_tile(1, 0, 1);

            check(
                last_tile == 1'b0,
                "(1,0,1) is not final"
            );

            //--------------------------------------------------------------
            // (1,1,0)
            //--------------------------------------------------------------

            advance_walker();

            check_tile(1, 1, 0);

            check(
                last_tile == 1'b0,
                "(1,1,0) is not final"
            );

            //--------------------------------------------------------------
            // (1,1,1)
            //--------------------------------------------------------------

            advance_walker();

            check_tile(1, 1, 1);

            check(
                last_tile == 1'b1,
                "Final tile detected"
            );

            check(
                done == 1'b0,
                "Walker not done while sitting on final tile"
            );

        end

    endtask

    //======================================================================
    // TEST 6
    //
    // Advance beyond final tile
    //
    // According to the RTL, done becomes asserted only after advancing
    // while already positioned on the final tile.
    //
    //======================================================================

    task automatic test_completion;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 6 : WALKER COMPLETION");
            $display("====================================================");

            advance_walker();

            $display(
    "[TB_WALKER_DEBUG] after completion: row=%0d col=%0d k=%0d first=%0d last=%0d done=%0d",
    current_tile.tile_row,
    current_tile.tile_col,
    current_tile.tile_k,
    first_tile,
    last_tile,
    done
);

            check(
                done == 1'b1,
                "Walker done asserted"
            );

            check(
                current_tile.tile_row == 16'd1,
                "Final row remains unchanged"
            );

            check(
                current_tile.tile_col == 16'd1,
                "Final column remains unchanged"
            );

            check(
                current_tile.tile_k == 16'd1,
                "Final K remains unchanged"
            );

            check(
                last_tile == 1'b1,
                "Final tile remains indicated"
            );

        end

    endtask

    //======================================================================
    // TEST 7
    //
    // No advancement after done
    //======================================================================

    task automatic test_done_hold;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 7 : DONE HOLD");
            $display("====================================================");

            advance_walker();

            $display(
    "[TB_WALKER_DEBUG] after done hold: row=%0d col=%0d k=%0d first=%0d last=%0d done=%0d",
    current_tile.tile_row,
    current_tile.tile_col,
    current_tile.tile_k,
    first_tile,
    last_tile,
    done
);

            check(
                done == 1'b1,
                "Done remains asserted"
            );

            check(
                current_tile.tile_row == 16'd1,
                "Row remains final after done"
            );

            check(
                current_tile.tile_col == 16'd1,
                "Column remains final after done"
            );

            check(
                current_tile.tile_k == 16'd1,
                "K remains final after done"
            );

        end

    endtask

    //======================================================================
    // TEST 8
    //
    // Restart traversal after completion
    //======================================================================

    task automatic test_restart;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 8 : RESTART AFTER COMPLETION");
            $display("====================================================");

            start_walker();

            check_tile(
                0,
                0,
                0
            );

            check(
                first_tile == 1'b1,
                "First tile restored after restart"
            );

            check(
                last_tile == 1'b0,
                "Last tile deasserted after restart"
            );

            check(
                done == 1'b0,
                "Done cleared after restart"
            );

        end

    endtask

    //======================================================================
    // TEST 9
    //
    // Single-tile configuration
    //
    // max_tile_rows = 1
    // max_tile_cols = 1
    // max_tile_k    = 1
    //
    // The only tile is simultaneously first and last.
    //======================================================================

    task automatic test_single_tile;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 9 : SINGLE TILE");
            $display("====================================================");

            max_tile_rows = 16'd1;
            max_tile_cols = 16'd1;
            max_tile_k    = 16'd1;

            start_walker();

            check(
                first_tile == 1'b1,
                "Single tile is first tile"
            );

            check(
                last_tile == 1'b1,
                "Single tile is last tile"
            );

            check(
                done == 1'b0,
                "Walker not done before advance"
            );

            advance_walker();

            check(
                done == 1'b1,
                "Single tile walker completes"
            );

        end

    endtask

    //======================================================================
    // TEST 10
    //
    // Restart with 2x2x2 configuration
    //======================================================================

    task automatic test_restore_configuration;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 10 : RESTORE 2x2x2 CONFIGURATION");
            $display("====================================================");

            max_tile_rows = 16'd2;
            max_tile_cols = 16'd2;
            max_tile_k    = 16'd2;

            start_walker();

            check_tile(
                0,
                0,
                0
            );

            check(
                first_tile == 1'b1,
                "Restored configuration starts correctly"
            );

            check(
                last_tile == 1'b0,
                "Restored first tile is not final"
            );

            check(
                done == 1'b0,
                "Restored walker not done"
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

        //--------------------------------------------------------------
        // Default configuration: 2x2x2 tile space
        //--------------------------------------------------------------

        max_tile_rows = 16'd2;
        max_tile_cols = 16'd2;
        max_tile_k    = 16'd2;

        rst     = 1'b0;
        start   = 1'b0;
        advance = 1'b0;

        //--------------------------------------------------------------
        // Apply reset
        //--------------------------------------------------------------

        reset_dut();

        //--------------------------------------------------------------
        // Tests
        //--------------------------------------------------------------

        test_reset();

        test_start();

        test_k_advance();

        test_column_advance();

        test_remaining_sequence();

        test_completion();

        test_done_hold();

        test_restart();

        test_single_tile();

        test_restore_configuration();

        //--------------------------------------------------------------
        // Regression Summary
        //--------------------------------------------------------------

        $display("");
        $display("====================================================");
        $display("TILE WALKER REGRESSION");
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

        if (tests_failed == 0)
            $display("OVERALL RESULT : PASS");
        else
            $display("OVERALL RESULT : FAIL");

        $display("====================================================");

        $finish;

    end

endmodule