/******************************************************************************
 *
 * Testbench : dense_scheduler_tb
 *
 * Description :
 *      Integration testbench for
 *
 *          Dense Scheduler
 *          Tile Walker
 *          Tile Generator
 *
 ******************************************************************************/

`timescale 1ns/1ps

import descriptor_pkg::*;
import tile_pkg::*;

module dense_scheduler_tb;

    //----------------------------------------------------------
    // Clock / Reset
    //----------------------------------------------------------

    logic clk;
    logic rst_n;

    //----------------------------------------------------------
    // Descriptor Controller
    //----------------------------------------------------------

    logic start;
    logic dense_done;

    descriptor_t descriptor;

    //----------------------------------------------------------
    // Tile Walker Interface
    //----------------------------------------------------------

    logic walker_start;
    logic walker_next;

    logic [15:0] max_tile_rows;
    logic [15:0] max_tile_cols;
    logic [15:0] max_tile_k;

    tile_context_t current_tile;

    logic first_tile;
    logic last_tile;
    logic walker_done;

    //----------------------------------------------------------
    // Tile Generator
    //----------------------------------------------------------

    tile_request_t generated_request;

    //----------------------------------------------------------
    // Transfer Engine
    //----------------------------------------------------------

    logic transfer_ready;

    tile_request_t transfer_request;

    //----------------------------------------------------------
    // DUT
    //----------------------------------------------------------

    dense_scheduler scheduler
    (
        .clk(clk),
        .rst_n(rst_n),

        .start(start),
        .descriptor(descriptor),

        .dense_done(dense_done),

        .walker_start(walker_start),
        .walker_next(walker_next),

        .max_tile_rows(max_tile_rows),
        .max_tile_cols(max_tile_cols),
        .max_tile_k(max_tile_k),

        .current_tile(current_tile),
        .first_tile(first_tile),
        .last_tile(last_tile),
        .walker_done(walker_done),

        .generated_request(generated_request),

        .transfer_ready(transfer_ready),
        .transfer_request(transfer_request)
    );

    //----------------------------------------------------------
    // Tile Walker
    //----------------------------------------------------------

    tile_walker walker
    (
        .clk(clk),
        .rst(~rst_n),

        .start(walker_start),
        .advance(walker_next),

        .max_tile_rows(max_tile_rows),
        .max_tile_cols(max_tile_cols),
        .max_tile_k(max_tile_k),

        .current_tile(current_tile),

        .first_tile(first_tile),
        .last_tile(last_tile),
        .done(walker_done)
    );

    //----------------------------------------------------------
    // Tile Generator
    //----------------------------------------------------------

    tile_generator generator
    (
        .descriptor(descriptor),

        .current_tile(current_tile),

        .last_tile(last_tile),

        .tile_request(generated_request)
    );

    //----------------------------------------------------------
    // Clock
    //----------------------------------------------------------

    initial
        clk = 0;

    always #5 clk = ~clk;

    //----------------------------------------------------------
    // Dump Waves
    //----------------------------------------------------------

    initial
    begin

        $dumpfile("build/dense_scheduler_tb.vcd");
        $dumpvars(0, dense_scheduler_tb);

    end

    //----------------------------------------------------------
    // Reset
    //----------------------------------------------------------

    initial
    begin

        rst_n = 0;

        start = 0;

        transfer_ready = 1;

        #20;

        rst_n = 1;

    end

    //----------------------------------------------------------
    // Stimulus
    //----------------------------------------------------------

    initial
    begin

        //------------------------------------------------------
        // Wait for reset
        //------------------------------------------------------

        @(posedge rst_n);

        @(posedge clk);

        //------------------------------------------------------
        // Example Descriptor
        //------------------------------------------------------

        descriptor.rows = 128;
        descriptor.cols = 128;
        descriptor.k    = 128;

        descriptor.srcA_addr = 32'h1000_0000;
        descriptor.srcB_addr = 32'h2000_0000;
        descriptor.dst_addr  = 32'h3000_0000;

        descriptor.strideA = 128;
        descriptor.strideB = 128;
        descriptor.strideC = 128;

        descriptor.bytes_per_element = 2;

        //------------------------------------------------------
        // Start Scheduler
        //------------------------------------------------------

        start = 1;

        @(posedge clk);

        start = 0;

        //------------------------------------------------------
        // Wait until finished
        //------------------------------------------------------

        wait(dense_done);

        $display("----------------------------------------");
        $display("Dense Scheduler Completed");
        $display("----------------------------------------");

        #20;

        $finish;

    end

    //----------------------------------------------------------
    // Monitor
    //----------------------------------------------------------

    always @(posedge clk)
    begin

        $display(
            "T=%0t  STATE=%0d  ROW=%0d COL=%0d K=%0d  READY=%0b  DONE=%0b",
            $time,
            scheduler.state,
            current_tile.tile_row,
            current_tile.tile_col,
            current_tile.tile_k,
            transfer_ready,
            dense_done
        );

    end

endmodule