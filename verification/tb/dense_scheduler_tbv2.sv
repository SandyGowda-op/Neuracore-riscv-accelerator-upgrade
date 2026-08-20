/******************************************************************************
 *
 * Testbench : dense_scheduler_tb
 *
 * Project   : Descriptor-Driven RISC-V AI Accelerator
 *
 * Purpose   :
 *      Unit verification of dense_scheduler.
 *
 *      The following blocks are mocked:
 *
 *          - Descriptor Controller
 *          - Tile Walker
 *          - Tile Generator
 *          - Transfer Engine
 *          - Compute Controller
 *
 *      This testbench verifies scheduler control sequencing.
 *
 ******************************************************************************/

`timescale 1ns/1ps

import descriptor_pkg::*;
import tile_pkg::*;

module dense_scheduler_tbv2;

    //======================================================================
    // Parameters
    //======================================================================

    localparam int CLK_PERIOD = 10;


    //======================================================================
    // Clock / Reset
    //======================================================================

    logic clk;
    logic rst_n;

    initial begin

        clk = 1'b0;

        forever #(CLK_PERIOD/2)
            clk = ~clk;

    end


    //======================================================================
    // Descriptor Interface
    //======================================================================

    logic        start;
    descriptor_t descriptor;

    logic dense_done;


    //======================================================================
    // Tile Walker Interface
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
    // Tile Generator Interface
    //======================================================================

    tile_request_t generated_request;


    //======================================================================
    // Transfer Engine Interface
    //======================================================================

    logic transfer_ready;
    logic transfer_done;

    logic transfer_valid;
    tile_request_t transfer_request;


    //======================================================================
    // Compute Controller Interface
    //======================================================================

    logic compute_start;
    logic compute_done;


    //======================================================================
    // Test Counters
    //======================================================================

    integer tests_executed;
    integer tests_passed;
    integer tests_failed;


    //======================================================================
    // Synthetic Tile Walker
    //======================================================================
    //
    // We model three tiles:
    //
    //      tile 0
    //      tile 1
    //      tile 2 = last tile
    //
    // The scheduler itself does not implement the walker.
    // Therefore the TB changes tile_number when walker_next occurs.
    //
    //======================================================================

    integer tile_number;


    always_comb begin

        //--------------------------------------------------------------
        // Current tile context
        //--------------------------------------------------------------

        current_tile = '0;

        current_tile.tile_row = tile_number;
        current_tile.tile_col = 16'd0;
        current_tile.tile_k   = 16'd0;


        //--------------------------------------------------------------
        // First / last tile indicators
        //--------------------------------------------------------------

        first_tile = (tile_number == 0);

        last_tile  = (tile_number == 2);


        //--------------------------------------------------------------
        // Walker done is not required for this scheduler protocol.
        //--------------------------------------------------------------

        walker_done = 1'b0;

    end


    //======================================================================
    // Synthetic Tile Generator
    //======================================================================
    //
    // Generates a request corresponding to the current tile.
    //
    // Strides are explicitly included because the tile request now
    // carries stride information.
    //
    //======================================================================

    always_comb begin

        generated_request = '0;


        //--------------------------------------------------------------
        // Request valid
        //--------------------------------------------------------------

        generated_request.valid = 1'b1;


        //--------------------------------------------------------------
        // Tile context
        //--------------------------------------------------------------

        generated_request.tile_context.tile_row =
            tile_number;

        generated_request.tile_context.tile_col =
            16'd0;

        generated_request.tile_context.tile_k =
            16'd0;


        //--------------------------------------------------------------
        // Addresses
        //--------------------------------------------------------------

        generated_request.addr_a =
            32'h0000_0100 +
            (tile_number * 32);

        generated_request.addr_b =
            32'h0000_0200 +
            (tile_number * 32);

        generated_request.addr_c =
            32'h0000_0300 +
            (tile_number * 32);


        //--------------------------------------------------------------
        // Tile dimensions
        //--------------------------------------------------------------

        generated_request.rows   = 16'd64;
        generated_request.cols   = 16'd64;
        generated_request.k_size = 16'd64;


        //--------------------------------------------------------------
        // Strides
        //--------------------------------------------------------------

        generated_request.stride_a = 16'd64;
        generated_request.stride_b = 16'd64;


        //--------------------------------------------------------------
        // Transfer size
        //--------------------------------------------------------------

        generated_request.transfer_bytes = 32'd4096;


        //--------------------------------------------------------------
        // Scratchpad banks
        //--------------------------------------------------------------

        generated_request.bank_a = 4'd0;
        generated_request.bank_b = 4'd1;
        generated_request.bank_c = 4'd2;


        //--------------------------------------------------------------
        // Last tile
        //--------------------------------------------------------------

        if (tile_number == 2)
            generated_request.last_tile = 1'b1;

        else
            generated_request.last_tile = 1'b0;

    end


    //======================================================================
    // DUT
    //======================================================================

    dense_scheduler dut
    (

        //--------------------------------------------------------------
        // Global
        //--------------------------------------------------------------

        .clk                (clk),
        .rst_n              (rst_n),


        //--------------------------------------------------------------
        // Descriptor
        //--------------------------------------------------------------

        .start              (start),
        .descriptor         (descriptor),
        .dense_done         (dense_done),


        //--------------------------------------------------------------
        // Walker
        //--------------------------------------------------------------

        .walker_start       (walker_start),
        .walker_next        (walker_next),

        .max_tile_rows      (max_tile_rows),
        .max_tile_cols      (max_tile_cols),
        .max_tile_k         (max_tile_k),

        .current_tile       (current_tile),
        .first_tile         (first_tile),
        .last_tile          (last_tile),
        .walker_done        (walker_done),


        //--------------------------------------------------------------
        // Tile Generator
        //--------------------------------------------------------------

        .generated_request  (generated_request),


        //--------------------------------------------------------------
        // Transfer Engine
        //--------------------------------------------------------------

        .transfer_ready     (transfer_ready),
        .transfer_done      (transfer_done),

        .transfer_valid     (transfer_valid),
        .transfer_request   (transfer_request),


        //--------------------------------------------------------------
        // Compute Controller
        //--------------------------------------------------------------

        .compute_start     (compute_start),
        .compute_done      (compute_done)

    );


    //======================================================================
    // Basic Check Task
    //======================================================================

    task automatic check;

        input logic condition;
        input [255:0] message;

        begin

            tests_executed =
                tests_executed + 1;

            if (condition) begin

                tests_passed =
                    tests_passed + 1;

                $display(
                    "[PASS] %0s",
                    message
                );

            end

            else begin

                tests_failed =
                    tests_failed + 1;

                $display(
                    "[FAIL] %0s",
                    message
                );

            end

        end

    endtask


    //======================================================================
    // Descriptor Preparation
    //======================================================================

    task automatic initialize_descriptor;

        begin

            descriptor = '0;

            descriptor.rows = 128;
            descriptor.cols = 128;
            descriptor.k    = 128;

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

            compute_done = 1'b0;

            tile_number = 0;

            repeat (3)
                @(posedge clk);

            rst_n = 1'b1;

            @(posedge clk);

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


    task automatic accept_transfer;

    begin

        //----------------------------------------------------------
        // Wait until scheduler presents a valid transfer request
        //----------------------------------------------------------

        while (!transfer_valid)
            @(posedge clk);

        //----------------------------------------------------------
        // Assert ready before the next rising edge
        //----------------------------------------------------------

        @(negedge clk);

        transfer_ready = 1'b1;

        //----------------------------------------------------------
        // Handshake occurs here
        //----------------------------------------------------------

        @(posedge clk);

        //----------------------------------------------------------
        // Remove ready after handshake
        //----------------------------------------------------------

        #1;

        transfer_ready = 1'b0;

    end

endtask


    //======================================================================
    // Complete Transfer
    //======================================================================

    task automatic complete_transfer;

        begin

            @(negedge clk);

            transfer_done = 1'b1;

            @(posedge clk);

            #1;

            transfer_done = 1'b0;

        end

    endtask


    //======================================================================
    // Complete Compute
    //======================================================================

    task automatic complete_compute;

        begin

            @(negedge clk);

            compute_done = 1'b1;

            @(posedge clk);

            #1;

            compute_done = 1'b0;

        end

    endtask


    //======================================================================
    // TEST 1
    //
    // Tile Limit Calculation
    //======================================================================

    task automatic test_tile_limits;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 1 : TILE LIMIT CALCULATION");
            $display("====================================================");


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

        end

    endtask


    //======================================================================
// TEST 2
//
// Descriptor Start -> Walker Start
//======================================================================

task automatic test_walker_start;

    begin

        $display("");
        $display("====================================================");
        $display("TEST 2 : WALKER START");
        $display("====================================================");

        start_descriptor();

        //--------------------------------------------------------------
        // Wait until scheduler enters START_WALKER
        //--------------------------------------------------------------

        while (dut.state != dut.START_WALKER)
            @(posedge clk);

        #1;

        check(
            dut.state == dut.START_WALKER,
            "Scheduler entered START_WALKER"
        );

        check(
            walker_start == 1'b1,
            "Walker start pulse generated"
        );

        //--------------------------------------------------------------
        // Walker start must disappear after one cycle
        //--------------------------------------------------------------

        @(posedge clk);
        #1;

        check(
            walker_start == 1'b0,
            "Walker start pulse is one cycle"
        );

    end

endtask

    //======================================================================
    // TEST 3
    //
    // Tile Request + Transfer Backpressure
    //======================================================================

    task automatic test_transfer_handshake;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 3 : TRANSFER HANDSHAKE");
            $display("====================================================");


            //--------------------------------------------------------------
            // Move into ISSUE_TILE
            //--------------------------------------------------------------

            @(posedge clk);

            #1;


            check(
                transfer_valid == 1'b1,
                "Tile 0 transfer request valid"
            );


            //--------------------------------------------------------------
            // Address verification
            //--------------------------------------------------------------

            check(
                transfer_request.addr_a ==
                32'h0000_0100,

                "Tile 0 A address correct"
            );


            check(
                transfer_request.addr_b ==
                32'h0000_0200,

                "Tile 0 B address correct"
            );


            check(
                transfer_request.addr_c ==
                32'h0000_0300,

                "Tile 0 C address correct"
            );


            //--------------------------------------------------------------
            // Dimension verification
            //--------------------------------------------------------------

            check(
                transfer_request.rows == 16'd64,

                "Tile 0 rows correct"
            );


            check(
                transfer_request.cols == 16'd64,

                "Tile 0 cols correct"
            );


            check(
                transfer_request.k_size == 16'd64,

                "Tile 0 K size correct"
            );


            //--------------------------------------------------------------
            // Stride verification
            //--------------------------------------------------------------

            check(
                transfer_request.stride_a == 16'd64,

                "Tile 0 A stride correct"
            );


            check(
                transfer_request.stride_b == 16'd64,

                "Tile 0 B stride correct"
            );


            //--------------------------------------------------------------
            // Backpressure test
            //
            // Keep transfer_ready low for several cycles.
            // transfer_valid and request must remain asserted/stable.
            //--------------------------------------------------------------

            repeat (3) begin

                @(posedge clk);

                #1;

                check(
                    transfer_valid == 1'b1,

                    "Transfer request held during backpressure"
                );

                check(
                    transfer_request.addr_a ==
                    32'h0000_0100,

                    "Transfer A address stable under backpressure"
                );

            end


            //--------------------------------------------------------------
            // Accept transfer
            //--------------------------------------------------------------

            accept_transfer();


            //--------------------------------------------------------------
            // Scheduler should now wait for transfer_done.
            //--------------------------------------------------------------

            @(posedge clk);

            #1;


            check(
                transfer_valid == 1'b0,

                "Transfer valid deasserted after acceptance"
            );


            check(
                dut.state == dut.WAIT_TRANSFER_DONE,

                "Scheduler waits for transfer completion"
            );

        end

    endtask


    //======================================================================
    // TEST 4
    //
    // Transfer Completion -> Compute Start
    //======================================================================

    task automatic test_compute_launch;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 4 : COMPUTE LAUNCH");
            $display("====================================================");


            //--------------------------------------------------------------
            // Transfer completes
            //--------------------------------------------------------------

            complete_transfer();


            //--------------------------------------------------------------
            // Scheduler should enter START_COMPUTE
            //--------------------------------------------------------------

            #1;


            check(
                compute_start == 1'b1,

                "Compute start pulse generated"
            );


            check(
                dut.state == dut.START_COMPUTE,

                "Scheduler entered START_COMPUTE"
            );


            //--------------------------------------------------------------
            // Verify the latched transfer request is still available.
            //
            // The scheduler's current implementation does not expose
            // separate compute_base/stride outputs. Therefore the tile
            // request itself is the source of these parameters.
            //--------------------------------------------------------------

            check(
                transfer_request.addr_a ==
                32'h0000_0100,

                "Compute tile A base preserved"
            );


            check(
                transfer_request.addr_b ==
                32'h0000_0200,

                "Compute tile B base preserved"
            );


            check(
                transfer_request.stride_a ==
                16'd64,

                "Compute A stride preserved"
            );


            check(
                transfer_request.stride_b ==
                16'd64,

                "Compute B stride preserved"
            );


            check(
                transfer_request.rows ==
                16'd64,

                "Compute rows preserved"
            );


            check(
                transfer_request.cols ==
                16'd64,

                "Compute cols preserved"
            );


            check(
                transfer_request.k_size ==
                16'd64,

                "Compute K size preserved"
            );


            //--------------------------------------------------------------
            // Compute start must be one cycle
            //--------------------------------------------------------------

            @(posedge clk);

            #1;


            check(
                compute_start == 1'b0,

                "Compute start pulse ends"
            );


            check(
                dut.state == dut.WAIT_COMPUTE_DONE,

                "Scheduler waits for compute completion"
            );

        end

    endtask


    //======================================================================
    // TEST 5
    //
    // Compute Completion -> Walker Advance
    //======================================================================

    task automatic test_next_tile;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 5 : COMPUTE COMPLETION -> NEXT TILE");
            $display("====================================================");


            //--------------------------------------------------------------
            // Complete tile computation
            //--------------------------------------------------------------

            complete_compute();


            //--------------------------------------------------------------
            // Scheduler should now be in ADVANCE_TILE
            //--------------------------------------------------------------

            #1;


            check(
                dut.state == dut.ADVANCE_TILE,

                "Scheduler entered ADVANCE_TILE"
            );


            check(
                walker_next == 1'b1,

                "Walker next pulse generated"
            );


            //--------------------------------------------------------------
            // walker_next must be one cycle
            //--------------------------------------------------------------

            @(posedge clk);

            #1;


            check(
                walker_next == 1'b0,

                "Walker next pulse is one cycle"
            );


            //--------------------------------------------------------------
            // Move synthetic walker to tile 1.
            //
            // This models the actual Tile Walker responding to
            // walker_next.
            //--------------------------------------------------------------

            tile_number = 1;


            @(posedge clk);

            #1;


            check(
                transfer_valid == 1'b1,

                "Tile 1 transfer request valid"
            );


            check(
                transfer_request.addr_a ==
                32'h0000_0120,

                "Tile 1 A address correct"
            );


            check(
                transfer_request.addr_b ==
                32'h0000_0220,

                "Tile 1 B address correct"
            );


            check(
                transfer_request.last_tile == 1'b0,

                "Tile 1 is not final"
            );

        end

    endtask


    //======================================================================
    // TEST 6
    //
    // Final Tile -> Complete
    //======================================================================

    task automatic test_last_tile;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 6 : LAST TILE COMPLETION");
            $display("====================================================");


            //--------------------------------------------------------------
            // Accept tile 1
            //--------------------------------------------------------------

            accept_transfer();


            @(posedge clk);

            #1;


            check(
                transfer_valid == 1'b0,

                "Tile 1 transfer accepted"
            );


            //--------------------------------------------------------------
            // Complete tile 1 transfer
            //--------------------------------------------------------------

            complete_transfer();


            //--------------------------------------------------------------
            // Compute tile 1
            //--------------------------------------------------------------

            #1;


            check(
                compute_start == 1'b1,

                "Tile 1 compute start generated"
            );


            @(posedge clk);

            #1;


            check(
                compute_start == 1'b0,

                "Tile 1 compute start pulse ends"
            );


            //--------------------------------------------------------------
            // Complete tile 1 compute
            //--------------------------------------------------------------

            complete_compute();


            #1;


            check(
                walker_next == 1'b1,

                "Walker advances from tile 1"
            );


            //--------------------------------------------------------------
            // Move walker to final synthetic tile
            //--------------------------------------------------------------

            tile_number = 2;


            @(posedge clk);

            #1;


            check(
                transfer_valid == 1'b1,

                "Final tile request valid"
            );


            check(
                transfer_request.last_tile == 1'b1,

                "Final tile marked last"
            );


            check(
                transfer_request.addr_a ==
                32'h0000_0140,

                "Final tile A address correct"
            );


            check(
                transfer_request.addr_b ==
                32'h0000_0240,

                "Final tile B address correct"
            );


            //--------------------------------------------------------------
            // Accept final transfer
            //--------------------------------------------------------------

            accept_transfer();


            @(posedge clk);

            #1;


            check(
                transfer_valid == 1'b0,

                "Final transfer accepted"
            );


            //--------------------------------------------------------------
            // Complete final transfer
            //--------------------------------------------------------------

            complete_transfer();


            #1;


            check(
                compute_start == 1'b1,

                "Final compute start generated"
            );


            //--------------------------------------------------------------
            // Compute final tile
            //--------------------------------------------------------------

            @(posedge clk);

            #1;


            check(
                compute_start == 1'b0,

                "Final compute start pulse ends"
            );


            complete_compute();


            //--------------------------------------------------------------
            // Final tile must NOT generate walker_next.
            //--------------------------------------------------------------

            #1;


            check(
                dut.state == dut.ADVANCE_TILE,

                "Scheduler entered final ADVANCE_TILE"
            );


            check(
                walker_next == 1'b0,

                "Walker does not advance after final tile"
            );


            //--------------------------------------------------------------
            // Next cycle should enter COMPLETE.
            //--------------------------------------------------------------

            @(posedge clk);

            #1;


            check(
                dense_done == 1'b1,

                "Dense descriptor completion generated"
            );


            check(
                dut.state == dut.COMPLETE,

                "Scheduler entered COMPLETE"
            );


            //--------------------------------------------------------------
            // dense_done must be one cycle.
            //--------------------------------------------------------------

            @(posedge clk);

            #1;


            check(
                dense_done == 1'b0,

                "Dense completion pulse is one cycle"
            );


            check(
                dut.state == dut.IDLE,

                "Scheduler returned to IDLE"
            );

        end

    endtask


    //======================================================================
    // TEST 7
    //
    // No Spurious Control Signals
    //======================================================================

    task automatic test_idle_outputs;

        begin

            $display("");
            $display("====================================================");
            $display("TEST 7 : IDLE OUTPUT SAFETY");
            $display("====================================================");


            check(
                walker_start == 1'b0,

                "No walker_start in IDLE"
            );


            check(
                walker_next == 1'b0,

                "No walker_next in IDLE"
            );


            check(
                transfer_valid == 1'b0,

                "No transfer request in IDLE"
            );


            check(
                compute_start == 1'b0,

                "No compute start in IDLE"
            );


            check(
                dense_done == 1'b0,

                "No dense_done in IDLE"
            );

        end

    endtask


    //======================================================================
    // Main Test Sequence
    //======================================================================

    initial begin

        //--------------------------------------------------------------
        // Initialize counters
        //--------------------------------------------------------------

        tests_executed = 0;
        tests_passed   = 0;
        tests_failed   = 0;


        //--------------------------------------------------------------
        // Initialize environment
        //--------------------------------------------------------------

        tile_number = 0;

        initialize_descriptor();

        reset_dut();


        //--------------------------------------------------------------
        // Run regression
        //--------------------------------------------------------------

        test_tile_limits();

        test_walker_start();

        test_transfer_handshake();

        test_compute_launch();

        test_next_tile();

        test_last_tile();

        test_idle_outputs();


        //--------------------------------------------------------------
        // Summary
        //--------------------------------------------------------------

        $display("");

        $display("====================================================");
        $display("DENSE SCHEDULER REGRESSION");
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


        $display("====================================================");

        $finish;

    end


    //======================================================================
    // Scheduler Debug
    //======================================================================

    always @(posedge clk) begin

        #1;

        $display(
            "[SCHED_DEBUG] t=%0t state=%0d start=%b walker_start=%b walker_next=%b transfer_valid=%b transfer_ready=%b transfer_done=%b compute_start=%b compute_done=%b last_tile=%b dense_done=%b",
            $time,
            dut.state,
            start,
            walker_start,
            walker_next,
            transfer_valid,
            transfer_ready,
            transfer_done,
            compute_start,
            compute_done,
            last_tile,
            dense_done
        );

    end

endmodule