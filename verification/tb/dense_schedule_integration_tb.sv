`timescale 1ns/1ps

import descriptor_pkg::*;
import tile_pkg::*;

module dense_schedule_integration_tb;

    //======================================================================
    // Clock / Reset
    //======================================================================

    logic clk;
    logic rst_n;

    initial clk = 1'b0;
    always #5 clk = ~clk;


    //======================================================================
    // Descriptor Interface
    //======================================================================

    logic        start;
    descriptor_t descriptor;

    logic dense_done;


    //======================================================================
    // Scheduler <-> Tile Walker
    //======================================================================

    logic walker_start;
    logic walker_next;

    logic [15:0] max_tile_rows;
    logic [15:0] max_tile_cols;
    logic [15:0] max_tile_k;

    tile_context_t current_tile;

    logic first_tile;
    logic last_tile;
    logic walker_done;


    //======================================================================
    // Tile Walker <-> Tile Generator
    //======================================================================

    tile_request_t generated_request;


    //======================================================================
    // Scheduler <-> Transfer Engine
    //======================================================================

    logic transfer_valid;
    logic transfer_ready;
    logic transfer_done;

    tile_request_t transfer_request;


    //======================================================================
    // Scheduler <-> Compute Controller
    //======================================================================

    logic compute_start;
    logic compute_done;


    //======================================================================
    // DUT : Dense Scheduler
    //======================================================================

    dense_scheduler scheduler_dut
    (
        .clk               (clk),
        .rst_n             (rst_n),

        .start             (start),
        .descriptor        (descriptor),

        .dense_done        (dense_done),

        .walker_start      (walker_start),
        .walker_next       (walker_next),

        .max_tile_rows     (max_tile_rows),
        .max_tile_cols     (max_tile_cols),
        .max_tile_k        (max_tile_k),

        .current_tile      (current_tile),

        .first_tile        (first_tile),
        .last_tile         (last_tile),
        .walker_done       (walker_done),

        .generated_request (generated_request),

        .transfer_ready    (transfer_ready),
        .transfer_valid    (transfer_valid),
        .transfer_done     (transfer_done),

        .transfer_request  (transfer_request),

        .compute_start     (compute_start),
        .compute_done      (compute_done)
    );


    //======================================================================
    // DUT : Tile Walker
    //======================================================================

    tile_walker walker_dut
    (
        .clk            (clk),
        .rst            (!rst_n),

        .start          (walker_start),
        .advance        (walker_next),

        .max_tile_rows  (max_tile_rows),
        .max_tile_cols  (max_tile_cols),
        .max_tile_k     (max_tile_k),

        .current_tile   (current_tile),

        .first_tile     (first_tile),
        .last_tile      (last_tile),
        .done           (walker_done)
    );


    //======================================================================
    // DUT : Tile Generator
    //======================================================================

    tile_generator generator_dut
    (
        .descriptor     (descriptor),
        .current_tile   (current_tile),
        .last_tile      (last_tile),

        .tile_request   (generated_request)
    );


    //======================================================================
    // Regression Counters
    //======================================================================

    integer tests_executed;
    integer tests_passed;
    integer tests_failed;

    integer tile_count;

    integer expected_row;
    integer expected_col;
    integer expected_k;

    integer timeout_count;


    //======================================================================
    // Basic Check
    //======================================================================

    task automatic check;

        input logic condition;
        input [255:0] message;

        begin

            tests_executed = tests_executed + 1;

            if (condition)
            begin

                tests_passed = tests_passed + 1;

                $display(
                    "[PASS] %0s",
                    message
                );

            end

            else
            begin

                tests_failed = tests_failed + 1;

                $display(
                    "[FAIL] %0s",
                    message
                );

            end

        end

    endtask


    //======================================================================
    // Reset
    //======================================================================

    task automatic reset_dut;

        begin

            rst_n = 1'b0;

            start = 1'b0;

            transfer_ready = 1'b0;
            transfer_done  = 1'b0;

            compute_done   = 1'b0;


            repeat (3)
                @(posedge clk);

            rst_n = 1'b1;

            @(posedge clk);

            #1;

        end

    endtask


    //======================================================================
    // Descriptor Configuration
    //======================================================================

    task automatic configure_descriptor;

        begin

            descriptor = '0;

            descriptor.rows = 16'd128;
            descriptor.cols = 16'd128;
            descriptor.k    = 16'd128;

            descriptor.srcA_addr = 32'h0000_1000;
            descriptor.srcB_addr = 32'h0000_2000;
            descriptor.dst_addr  = 32'h0000_3000;

            //--------------------------------------------------------------
            // Strides are in BYTES.
            //
            // 128 elements × 4 bytes = 512 bytes/row.
            //--------------------------------------------------------------

            descriptor.strideA = 32'd512;
            descriptor.strideB = 32'd512;
            descriptor.strideC = 32'd512;

            descriptor.bytes_per_element = 8'd4;

        end

    endtask


    //======================================================================
    // Start Descriptor
    //======================================================================

    task automatic start_descriptor;

        begin

            @(negedge clk);

            start = 1'b1;

            @(negedge clk);

            start = 1'b0;

        end

    endtask


    //======================================================================
    // Wait For Walker Start
    //======================================================================

    task automatic wait_for_walker_start;

        begin

            timeout_count = 0;

            while (!walker_start && timeout_count < 20)
            begin

                @(posedge clk);

                timeout_count = timeout_count + 1;

            end

            check(
                walker_start == 1'b1,
                "Walker start generated"
            );

        end

    endtask


    //======================================================================
    // Wait For Transfer Request
    //======================================================================

    task automatic wait_for_transfer;

        begin

            timeout_count = 0;

            while (!transfer_valid && timeout_count < 30)
            begin

                @(posedge clk);

                timeout_count = timeout_count + 1;

            end

            check(
                transfer_valid == 1'b1,
                "Transfer request generated"
            );

            if (!transfer_valid)
            begin

                $display(
                    "[FATAL] Timeout waiting for transfer request"
                );

                $finish;

            end

        end

    endtask


    //======================================================================
    // Transfer Engine Model
    //
    // Behavior:
    //
    //   1. Wait for VALID
    //   2. Assert READY
    //   3. Complete handshake
    //   4. Remove READY
    //   5. Generate DONE
    //
    // This models the external Transfer Engine only.
    //======================================================================

    task automatic execute_transfer;

        begin

            //--------------------------------------------------------------
            // Wait until scheduler presents a request.
            //--------------------------------------------------------------

            while (!transfer_valid)
                @(posedge clk);


            //--------------------------------------------------------------
            // Present READY before handshake edge.
            //--------------------------------------------------------------

            @(negedge clk);

            transfer_ready = 1'b1;


            //--------------------------------------------------------------
            // Handshake occurs here.
            //--------------------------------------------------------------

            @(posedge clk);

            #1;

            transfer_ready = 1'b0;


            //--------------------------------------------------------------
            // Simulate a small transfer-engine latency.
            //--------------------------------------------------------------

            @(negedge clk);

            transfer_done = 1'b1;


            //--------------------------------------------------------------
            // Transfer completion sampled by scheduler.
            //--------------------------------------------------------------

            @(posedge clk);

            #1;

            transfer_done = 1'b0;

        end

    endtask


    //======================================================================
    // Wait For Compute Start
    //======================================================================

    task automatic wait_for_compute_start;

        begin

            timeout_count = 0;

            while (!compute_start && timeout_count < 30)
            begin

                @(posedge clk);

                timeout_count = timeout_count + 1;

            end

            check(
                compute_start == 1'b1,
                "Compute start generated"
            );

            if (!compute_start)
            begin

                $display(
                    "[FATAL] Timeout waiting for compute start"
                );

                $finish;

            end

        end

    endtask


    //======================================================================
    // Compute Controller Model
    //
    // Behavior:
    //
    //   1. Wait for COMPUTE_START
    //   2. Simulate compute latency
    //   3. Generate COMPUTE_DONE
    //
    // The real compute_controller will replace this model later.
    //======================================================================

    task automatic execute_compute;

    begin

        //----------------------------------------------------------
        // Wait until scheduler launches compute.
        //----------------------------------------------------------

        while (!compute_start)
            @(posedge clk);


        //----------------------------------------------------------
        // The scheduler is currently in START_COMPUTE.
        //
        // Wait one clock so that the scheduler enters
        // WAIT_COMPUTE before we generate compute_done.
        //----------------------------------------------------------

        @(posedge clk);

        #1;


        //----------------------------------------------------------
        // Simulate compute latency.
        //----------------------------------------------------------

        @(negedge clk);

        compute_done = 1'b1;


        //----------------------------------------------------------
        // Scheduler samples compute_done while in WAIT_COMPUTE.
        //----------------------------------------------------------

        @(posedge clk);

        #1;

        compute_done = 1'b0;

    end

endtask


    //======================================================================
    // Check Current Tile
    //======================================================================

    task automatic check_tile;

        begin

            $display(
                "[INTEGRATION_TILE] count=%0d row=%0d col=%0d k=%0d last=%0d",
                tile_count,
                transfer_request.tile_context.tile_row,
                transfer_request.tile_context.tile_col,
                transfer_request.tile_context.tile_k,
                transfer_request.last_tile
            );


            //--------------------------------------------------------------
            // Tile coordinates
            //--------------------------------------------------------------

            check(
                transfer_request.tile_context.tile_row ==
                expected_row,

                "Tile row correct"
            );


            check(
                transfer_request.tile_context.tile_col ==
                expected_col,

                "Tile column correct"
            );


            check(
                transfer_request.tile_context.tile_k ==
                expected_k,

                "Tile K correct"
            );


            //--------------------------------------------------------------
            // Tile dimensions
            //--------------------------------------------------------------

            check(
                transfer_request.rows == 16'd64,

                "Tile rows correct"
            );


            check(
                transfer_request.cols == 16'd64,

                "Tile cols correct"
            );


            check(
                transfer_request.k_size == 16'd64,

                "Tile K size correct"
            );


            //--------------------------------------------------------------
            // Strides
            //--------------------------------------------------------------

            check(
                transfer_request.stride_a == 16'd512,

                "A stride correct"
            );


            check(
                transfer_request.stride_b == 16'd512,

                "B stride correct"
            );


            //--------------------------------------------------------------
            // Last tile
            //--------------------------------------------------------------

            if (tile_count == 7)
            begin

                check(
                    transfer_request.last_tile == 1'b1,

                    "Final tile marked last"
                );

            end

            else
            begin

                check(
                    transfer_request.last_tile == 1'b0,

                    "Non-final tile not marked last"
                );

            end

        end

    endtask


    //======================================================================
    // Scheduler Debug Monitor
    //======================================================================

    always @(posedge clk)
    begin

        #1;

        $display(
            "[SCHED_DEBUG] t=%0t state=%0d start=%0d "   ,
            $time,
            scheduler_dut.state,
            start
        );

        $display(
            "               walker_start=%0d walker_next=%0d " ,
            walker_start,
            walker_next
        );

        $display(
            "               transfer_valid=%0d transfer_ready=%0d " ,
            transfer_valid,
            transfer_ready
        );

        $display(
            "               transfer_done=%0d compute_start=%0d " ,
            transfer_done,
            compute_start
        );

        $display(
            "               compute_done=%0d last_tile=%0d dense_done=%0d",
            compute_done,
            last_tile,
            dense_done
        );

    end


    //======================================================================
    // Main Regression
    //======================================================================

    initial
    begin

        tests_executed = 0;
        tests_passed   = 0;
        tests_failed   = 0;

        tile_count = 0;

        $display("");
        $display("====================================================");
        $display("DENSE SCHEDULER SUBSYSTEM INTEGRATION");
        $display("====================================================");


        //==================================================================
        // Configuration / Reset
        //==================================================================

        configure_descriptor();

        reset_dut();

        //--------------------------------------------------------------
        // Allow combinational descriptor-dependent logic to settle.
        //--------------------------------------------------------------

        #1;


        //==================================================================
        // TEST 1 : Tile Limits
        //==================================================================

        $display("");
        $display("TEST 1 : TILE LIMITS");

        check(
            max_tile_rows == 16'd2,

            "Rows tile count = 2"
        );

        check(
            max_tile_cols == 16'd2,

            "Cols tile count = 2"
        );

        check(
            max_tile_k == 16'd2,

            "K tile count = 2"
        );


        //==================================================================
        // TEST 2 : Descriptor Start
        //==================================================================

        $display("");
        $display("TEST 2 : START");

        start_descriptor();

        wait_for_walker_start();


        //==================================================================
        // TEST 3 : Full 2x2x2 Tile Traversal
        //==================================================================

        $display("");
        $display("TEST 3 : TILE TRAVERSAL");


        for (
            tile_count = 0;
            tile_count < 8;
            tile_count = tile_count + 1
        )
        begin

            //--------------------------------------------------------------
            // Expected traversal:
            //
            // K changes fastest
            // then column
            // then row
            //
            // 0: (0,0,0)
            // 1: (0,0,1)
            // 2: (0,1,0)
            // 3: (0,1,1)
            // 4: (1,0,0)
            // 5: (1,0,1)
            // 6: (1,1,0)
            // 7: (1,1,1)
            //--------------------------------------------------------------

            expected_k   = tile_count % 2;
            expected_col = (tile_count / 2) % 2;
            expected_row = tile_count / 4;


            //--------------------------------------------------------------
            // Wait for tile request.
            //--------------------------------------------------------------

            wait_for_transfer();


            //--------------------------------------------------------------
            // Verify generated transfer request.
            //--------------------------------------------------------------

            check_tile();


            //--------------------------------------------------------------
            // Transfer Engine accepts and completes transfer.
            //--------------------------------------------------------------

            execute_transfer();


            //--------------------------------------------------------------
            // Wait for compute launch.
            //--------------------------------------------------------------

            wait_for_compute_start();


            //--------------------------------------------------------------
            // Compute Engine completes.
            //--------------------------------------------------------------

            execute_compute();


            //--------------------------------------------------------------
            // Give scheduler/walker time to advance.
            //--------------------------------------------------------------

            @(posedge clk);

            #1;

        end


        //==================================================================
        // TEST 4 : Final State
        //==================================================================

        $display("");
        $display("TEST 4 : FINAL STATE");


        //--------------------------------------------------------------
        // Scheduler should eventually assert dense_done.
        //--------------------------------------------------------------

        timeout_count = 0;

        while (!dense_done && timeout_count < 20)
        begin

            @(posedge clk);

            timeout_count = timeout_count + 1;

        end


        check(
            dense_done == 1'b1,

            "Dense descriptor completion generated"
        );


        //--------------------------------------------------------------
        // Walker must remain on final tile.
        //--------------------------------------------------------------

        check(
            current_tile.tile_row == 16'd1,

            "Final tile row = 1"
        );


        check(
            current_tile.tile_col == 16'd1,

            "Final tile column = 1"
        );


        check(
            current_tile.tile_k == 16'd1,

            "Final tile K = 1"
        );


        check(
            last_tile == 1'b1,

            "Walker remains on final tile"
        );


        //==================================================================
        // Regression Summary
        //==================================================================

        $display("");
        $display("====================================================");
        $display("DENSE SUBSYSTEM INTEGRATION REGRESSION");
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