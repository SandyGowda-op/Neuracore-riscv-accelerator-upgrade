`timescale 1ns/1ps
`default_nettype none

import tile_pkg::*;

module dense_transfer_scratchpad_integration_tb;

    //==========================================================
    // Parameters
    //==========================================================

    localparam int DATA_WIDTH = 64;
    localparam int SPAD_WIDTH = 32;
    localparam int SPAD_DEPTH = 64;
    localparam int SPAD_ADDR_WIDTH = 6;

    //==========================================================
    // Clock / Reset
    //==========================================================

    logic clk;
    logic rst;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //==========================================================
    // Transfer Engine ↔ Scheduler
    //==========================================================

    tile_request_t tile_request;

    logic tile_request_valid;
    logic tile_request_ready;

    //==========================================================
    // Transfer Engine ↔ Main Memory
    //==========================================================

    logic        mem_req_valid;
    logic        mem_req_ready;
    logic [31:0] mem_req_addr;
    logic [31:0] mem_req_bytes;

    logic        mem_rvalid;
    logic [63:0] mem_rdata;
    logic        mem_rlast;

    //==========================================================
    // Transfer Engine ↔ Scratchpad Controller
    //==========================================================

    logic        spad_write_enable;
    logic [3:0]  spad_bank;
    logic [31:0] spad_address;
    logic [63:0] spad_write_data;

    logic        spad_ready;

    //==========================================================
    // Scratchpad Controller ↔ Scratchpad
    //==========================================================

    logic [1:0] spad_bank_sel;
    logic       spad_en;
    logic       spad_we;

    logic [SPAD_ADDR_WIDTH-1:0] spad_addr;
    logic [SPAD_WIDTH-1:0]      spad_wdata;

    //==========================================================
    // Compute Read Interface
    //==========================================================

    logic [1:0] compute_bank_sel;
    logic       compute_en;
    logic       compute_we;

    logic [SPAD_ADDR_WIDTH-1:0] compute_addr;
    logic [SPAD_WIDTH-1:0]      compute_wdata;
    logic [SPAD_WIDTH-1:0]      compute_rdata;

    //==========================================================
    // Status
    //==========================================================

    logic transfer_busy;
    logic transfer_done;

    //==========================================================
    // Test Statistics
    //==========================================================

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    integer test_failed;

    integer mon_mem_request_count;
    integer mon_mem_beat_count;
    integer mon_spad_write_count;

    //==========================================================
    // DUT : Transfer Engine
    //==========================================================

    transfer_engine #(
        .BURST_BYTES(128),
        .DATA_WIDTH (64)
    ) TRANSFER_ENGINE (

        .clk(clk),
        .rst(rst),

        // Scheduler
        .tile_request(tile_request),
        .tile_request_valid(tile_request_valid),
        .tile_request_ready(tile_request_ready),

        // Main Memory
        .mem_req_valid(mem_req_valid),
        .mem_req_ready(mem_req_ready),
        .mem_req_addr(mem_req_addr),
        .mem_req_bytes(mem_req_bytes),

        .mem_rvalid(mem_rvalid),
        .mem_rdata(mem_rdata),
        .mem_rlast(mem_rlast),

        // Scratchpad Controller
        .spad_write_enable(spad_write_enable),
        .spad_bank(spad_bank),
        .spad_address(spad_address),
        .spad_write_data(spad_write_data),
        .spad_ready(spad_ready),

        // Status
        .transfer_busy(transfer_busy),
        .transfer_done(transfer_done)
    );

    //==========================================================
    // DUT : Scratchpad Controller
    //==========================================================

    scratchpad_controller #(
        .DMA_DATA_WIDTH (64),
        .SPAD_DATA_WIDTH(32),
        .SPAD_ADDR_WIDTH(SPAD_ADDR_WIDTH)
    ) SPAD_CONTROLLER (

        .clk(clk),
        .rst(rst),

        // Transfer Engine
        .dma_write_enable(spad_write_enable),
        .dma_bank(spad_bank),
        .dma_address(spad_address),
        .dma_write_data(spad_write_data),
        .dma_ready(spad_ready),

        // Scratchpad
        .spad_bank_sel(spad_bank_sel),
        .spad_en(spad_en),
        .spad_we(spad_we),
        .spad_addr(spad_addr),
        .spad_wdata(spad_wdata)
    );

    //==========================================================
    // DUT : Scratchpad
    //==========================================================

    scratchpad #(
        .DATA_WIDTH(DATA_WIDTH / 2),
        .MATRIX_DIM(8),
        .DEPTH(SPAD_DEPTH),
        .ADDR_WIDTH(SPAD_ADDR_WIDTH)
    ) SCRATCHPAD (

        .clk(clk),
        .rst(rst),

        // DMA
        .dma_bank_sel(spad_bank_sel),
        .dma_en(spad_en),
        .dma_we(spad_we),
        .dma_addr(spad_addr),
        .dma_wdata(spad_wdata),
        .dma_rdata(),

        // Compute
        .compute_bank_sel(compute_bank_sel),
        .compute_en(compute_en),
        .compute_we(compute_we),
        .compute_addr(compute_addr),
        .compute_wdata(compute_wdata),
        .compute_rdata(compute_rdata)
    );

    //----------------------------------------------------------
// Main Memory Model
//----------------------------------------------------------

main_memory_model #(
    .DATA_WIDTH     (64),
    .MEMORY_SIZE    (65536),
    .MEMORY_LATENCY (3)
) MAIN_MEMORY (

    .clk(clk),
    .rst(rst),

    //------------------------------------------------------
    // DMA Request
    //------------------------------------------------------

    .mem_req_valid(mem_req_valid),
    .mem_req_ready(mem_req_ready),

    .mem_req_addr(mem_req_addr),
    .mem_req_bytes(mem_req_bytes),

    // Current DMA phase is READ ONLY
    .mem_req_write(1'b0),

    //------------------------------------------------------
    // DMA Read Data
    //------------------------------------------------------

    .mem_rvalid(mem_rvalid),
    .mem_rdata(mem_rdata),
    .mem_rlast(mem_rlast)

);
    //==========================================================
    // Memory Request Monitor
    //==========================================================

    always_ff @(posedge clk) begin

        if (!rst) begin

            if (mem_req_valid && mem_req_ready)
                mon_mem_request_count++;

        end

    end

    //==========================================================
    // Memory Beat Monitor
    //==========================================================

    always_ff @(posedge clk) begin

        if (!rst) begin

            if (mem_rvalid)
                mon_mem_beat_count++;

        end

    end

    //==========================================================
    // Scratchpad Write Monitor
    //==========================================================

    always_ff @(posedge clk) begin

        if (!rst) begin

            if (spad_write_enable && spad_ready)
                mon_spad_write_count++;

        end

    end

    //==========================================================
    // Check Helper
    //==========================================================

    task automatic check_equal;

        input integer expected;
        input integer observed;
        input string  name;

        begin

            if (expected == observed) begin

                $display(
                    "[PASS] %s : Expected=%0d Observed=%0d",
                    name,
                    expected,
                    observed
                );

            end
            else begin

                $display(
                    "[FAIL] %s : Expected=%0d Observed=%0d",
                    name,
                    expected,
                    observed
                );

                test_failed = 1;

            end

        end

    endtask

    //==========================================================
    // Wait for Transfer Completion
    //==========================================================

    task automatic wait_for_completion;

        integer timeout;

        begin

            timeout = 0;

            while (!transfer_done && timeout < 1000) begin

                @(posedge clk);
                timeout++;
                
            end

            if (timeout >= 1000) begin

                $display("[FATAL] Transfer timeout");
                $finish;

            end

        end

    endtask

    //==========================================================
    // Test 1
    //==========================================================

    task automatic test_single_dense_tile;

        begin

            test_failed = 0;

            mon_mem_request_count = 0;
            mon_mem_beat_count    = 0;
            mon_spad_write_count  = 0;

            $display("");
            $display("====================================================");
            $display("TEST 1 : DENSE TILE → TRANSFER → SCRATCHPAD");
            $display("====================================================");
            $display("");

            //--------------------------------------------------
            // Construct tile request
            //--------------------------------------------------

            tile_request = '0;

            tile_request.valid          = 1'b1;
            tile_request.last_tile      = 1'b1;

            tile_request.addr_a         = 32'h1000_0000;
            tile_request.addr_b         = 32'h2000_0000;
            tile_request.addr_c         = 32'h3000_0000;

            tile_request.transfer_bytes = 128;

            tile_request.rows           = 16;
            tile_request.cols           = 8;
            tile_request.k_size         = 8;

            tile_request.bank_a         = 4'd0;
            tile_request.bank_b         = 4'd1;
            tile_request.bank_c         = 4'd2;

            //--------------------------------------------------
            // Send request
            //--------------------------------------------------

            $display("[INFO] Sending Dense Tile Request");

            tile_request_valid = 1'b1;

            while (!tile_request_ready)
                @(posedge clk);

            @(posedge clk);

            tile_request_valid = 1'b0;

            $display("[PASS] Tile Request Accepted");

            //--------------------------------------------------
            // Wait for DMA completion
            //--------------------------------------------------

            wait_for_completion();

            //--------------------------------------------------
            // Transaction checks
            //--------------------------------------------------

            check_equal(
                1,
                mon_mem_request_count,
                "Memory Request Count"
            );

            check_equal(
                16,
                mon_mem_beat_count,
                "Memory Beat Count"
            );

            check_equal(
                32,
                mon_spad_write_count,
                "Scratchpad Write Count"
            );

            //--------------------------------------------------
            // Result
            //--------------------------------------------------

            if (!test_failed) begin

                $display("");
                $display("--------------------------------------------");
                $display("RESULT : PASS");
                $display("--------------------------------------------");

                passed_tests++;

            end
            else begin

                $display("");
                $display("--------------------------------------------");
                $display("RESULT : FAIL");
                $display("--------------------------------------------");

                failed_tests++;

            end

            total_tests++;

        end

    endtask

    //==========================================================
    // Reset
    //==========================================================

    task automatic reset_dut;

        begin

            rst = 1'b1;

            tile_request       = '0;
            tile_request_valid = 1'b0;

            compute_bank_sel = '0;
            compute_en       = 1'b0;
            compute_we       = 1'b0;
            compute_addr     = '0;
            compute_wdata    = '0;

            mon_mem_request_count = 0;
            mon_mem_beat_count    = 0;
            mon_spad_write_count  = 0;

            repeat (5)
                @(posedge clk);

            rst = 1'b0;

            repeat (2)
                @(posedge clk);

        end

    endtask

    //==========================================================
    // Main Regression
    //==========================================================

    initial begin

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        reset_dut();

        test_single_dense_tile();

        $display("");
        $display("====================================================");
        $display("DENSE TRANSFER + SCRATCHPAD INTEGRATION REGRESSION");
        $display("====================================================");

        $display(
            "Tests Executed : %0d",
            total_tests
        );

        $display(
            "Tests Passed   : %0d",
            passed_tests
        );

        $display(
            "Tests Failed   : %0d",
            failed_tests
        );

        if (failed_tests == 0)
            $display("OVERALL RESULT : PASS");
        else
            $display("OVERALL RESULT : FAIL");

        $display("====================================================");

        $finish;

    end

endmodule

`default_nettype wire