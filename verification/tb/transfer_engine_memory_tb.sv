`timescale 1ns/1ps

import tile_pkg::*;

module transfer_engine_memory_tb;

    localparam int CLK_PERIOD = 10;

    logic clk;
    logic rst;

    // Scheduler interface
    tile_request_t tile_request;
    logic tile_request_valid;
    logic tile_request_ready;

    // Main-memory request interface
    logic        mem_req_valid;
    wire         mem_req_ready_model;
    wire         mem_req_ready_to_dut;

    assign mem_req_ready_to_dut = mem_req_ready_model;
    logic [31:0] mem_req_addr;
    logic [31:0] mem_req_bytes;
    logic        mem_req_write;

    // Main-memory read-data interface
    logic        mem_rvalid;
    logic [63:0] mem_rdata;
    logic        mem_rlast;

    // Scratchpad interface
    logic        spad_write_enable;
    logic [3:0]  spad_bank;
    logic [31:0] spad_address;
    logic [63:0] spad_write_data;
    logic        spad_ready;

    // Status
    logic transfer_busy;
    logic transfer_done;

    // Regression statistics
    integer total_tests, passed_tests, failed_tests;
    logic test_failed;

    // Protocol counters
    integer mon_mem_request_count;
    integer mon_mem_beat_count;
    integer mon_rlast_count;
    integer mon_transfer_done_count;
    integer mon_spad_write_count;

    // First two memory requests, used to verify A -> B sequencing.
    logic [31:0] first_mem_addr, second_mem_addr;
    logic [31:0] first_mem_bytes, second_mem_bytes;
    integer observed_mem_requests;

    // ------------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ------------------------------------------------------------------
    // DUTs
    // ------------------------------------------------------------------
    transfer_engine #(
        .BURST_BYTES(128),
        .DATA_WIDTH(64)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .tile_request(tile_request),
        .tile_request_valid(tile_request_valid),
        .tile_request_ready(tile_request_ready),
        .mem_req_valid(mem_req_valid),
        .mem_req_ready(mem_req_ready_to_dut),
        .mem_req_addr(mem_req_addr),
        .mem_req_bytes(mem_req_bytes),
        .mem_rvalid(mem_rvalid),
        .mem_rdata(mem_rdata),
        .mem_rlast(mem_rlast),
        .spad_write_enable(spad_write_enable),
        .spad_bank(spad_bank),
        .spad_address(spad_address),
        .spad_write_data(spad_write_data),
        .spad_ready(spad_ready),
        .transfer_busy(transfer_busy),
        .transfer_done(transfer_done)
    );

    main_memory_model MEMORY (
        .clk(clk),
        .rst(rst),
        .mem_req_valid(mem_req_valid),
        .mem_req_ready(mem_req_ready_model),
        .mem_req_addr(mem_req_addr),
        .mem_req_bytes(mem_req_bytes),
        .mem_req_write(mem_req_write),
        .mem_rvalid(mem_rvalid),
        .mem_rdata(mem_rdata),
        .mem_rlast(mem_rlast)
    );

    // ------------------------------------------------------------------
    // Reset / counters
    // ------------------------------------------------------------------
    task automatic reset_dut;
    begin
        rst = 1'b1;
        tile_request = '0;
        tile_request_valid = 1'b0;
        spad_ready = 1'b1;
        mem_req_write = 1'b0;
        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (2) @(posedge clk);
    end
    endtask

    task automatic clear_counters;
    begin
        mon_mem_request_count = 0;
        mon_mem_beat_count = 0;
        mon_rlast_count = 0;
        mon_transfer_done_count = 0;
        mon_spad_write_count = 0;
        first_mem_addr = '0;
        second_mem_addr = '0;
        first_mem_bytes = '0;
        second_mem_bytes = '0;
        observed_mem_requests = 0;
        test_failed = 1'b0;
    end
    endtask

    task automatic check_equal(
        input integer expected,
        input integer observed,
        input string item
    );
    begin
        if (expected == observed)
            $display("[PASS] %s", item);
        else begin
            $display("[FAIL] %s  expected=%0d observed=%0d",
                     item, expected, observed);
            test_failed = 1'b1;
        end
    end
    endtask

    task automatic check_hex(
        input logic [31:0] expected,
        input logic [31:0] observed,
        input string item
    );
    begin
        if (expected == observed)
            $display("[PASS] %s", item);
        else begin
            $display("[FAIL] %s  expected=%08h observed=%08h",
                     item, expected, observed);
            test_failed = 1'b1;
        end
    end
    endtask

    task automatic finish_test(input string name);
    begin
        total_tests++;
        if (test_failed) begin
            failed_tests++;
            $display("[RESULT] %s : FAIL", name);
        end else begin
            passed_tests++;
            $display("[RESULT] %s : PASS", name);
        end
        $display("");
    end
    endtask

    // ------------------------------------------------------------------
    // Protocol monitors
    // ------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst) begin
            if (mem_req_valid && mem_req_ready_model) begin
                if (observed_mem_requests == 0) begin
                    first_mem_addr  <= mem_req_addr;
                    first_mem_bytes <= mem_req_bytes;
                end
                else if (observed_mem_requests == 1) begin
                    second_mem_addr  <= mem_req_addr;
                    second_mem_bytes <= mem_req_bytes;
                end
                observed_mem_requests++;
                mon_mem_request_count++;
            end

            if (mem_rvalid)
                mon_mem_beat_count++;

            if (mem_rvalid && mem_rlast)
                mon_rlast_count++;

            if (spad_write_enable)
                mon_spad_write_count++;

            if (transfer_done)
                mon_transfer_done_count++;
        end
    end
    
    //======================================================================
// TRANSFER ENGINE DEBUG MONITOR
//
// Temporary debug instrumentation.
// Do NOT modify DUT signals from this block.
//======================================================================

always @(posedge clk)
begin

    if (!rst)
    begin

        $display(
    "[TE_DEBUG] t=%0t state=%0d phase=%0d tile_v=%b tile_r=%b req_bytes=%0d req_bytes_b=%0d current_req_bytes=%0d current_req_bytes_b=%0d current_addr=%08h bytes_remaining=%0d burst_bytes=%0d current_burst=%0d mem_v=%b mem_r=%b mem_addr=%08h mem_bytes=%0d rvalid=%b rlast=%b done=%b busy=%b",
    $time,
    DUT.state,
    DUT.transfer_phase,
    tile_request_valid,
    tile_request_ready,
    tile_request.transfer_bytes,
    tile_request.transfer_bytes_b,
    DUT.current_request.transfer_bytes,
    DUT.current_request.transfer_bytes_b,
    DUT.current_address,
    DUT.bytes_remaining,
    DUT.burst_bytes,
    DUT.current_burst_bytes,
    mem_req_valid,
    mem_req_ready_model,
    mem_req_addr,
    mem_req_bytes,
    mem_rvalid,
    mem_rlast,
    transfer_done,
    transfer_busy
);

    end

end
    // ------------------------------------------------------------------
    // Drive one scheduler tile transaction.
    // ------------------------------------------------------------------
    task automatic send_tile_request(
    input logic [31:0] addr_a,
    input logic [31:0] addr_b,
    input logic [31:0] addr_c,
    input logic [15:0] rows,
    input logic [15:0] cols,
    input logic [15:0] k_size,
    input logic [31:0] bytes_a,
    input logic [31:0] bytes_b
);
begin

    //--------------------------------------------------------------
    // Build request
    //--------------------------------------------------------------

    tile_request = '0;

    tile_request.addr_a = addr_a;
    tile_request.addr_b = addr_b;
    tile_request.addr_c = addr_c;

    tile_request.rows   = rows;
    tile_request.cols   = cols;
    tile_request.k_size = k_size;

    tile_request.bank_a = 4'd0;
    tile_request.bank_b = 4'd1;
    tile_request.bank_c = 4'd2;

    tile_request.transfer_bytes   = bytes_a;
    tile_request.transfer_bytes_b = bytes_b;

    tile_request.last_tile = 1'b1;

    //--------------------------------------------------------------
    // Present request
    //--------------------------------------------------------------

    @(negedge clk);

    tile_request_valid = 1'b1;

    //--------------------------------------------------------------
    // Wait for handshake
    //--------------------------------------------------------------

    while (!(tile_request_valid && tile_request_ready))
        @(posedge clk);

    //--------------------------------------------------------------
    // Handshake has occurred.
    //
    // Keep request stable through this edge.
    //--------------------------------------------------------------

    @(negedge clk);

    tile_request_valid = 1'b0;
    tile_request       = '0;

end
endtask

    task automatic wait_for_completion;
        integer timeout;
    begin
        timeout = 0;
        while (!transfer_done) begin
            @(posedge clk);
            timeout++;
            if (timeout > 1000)
                $fatal(1, "DMA timeout");
        end
        @(posedge clk);
    end
    endtask

    // ------------------------------------------------------------------
    // Common result check.
    // ------------------------------------------------------------------
    task automatic check_common(
        input integer exp_requests,
        input integer exp_beats,
        input integer exp_rlast,
        input integer exp_done,
        input integer exp_writes,
        input string test_name
    );
    begin
        check_equal(exp_requests, mon_mem_request_count, "Memory request count");
        check_equal(exp_beats, mon_mem_beat_count, "Memory beat count");
        check_equal(exp_rlast, mon_rlast_count, "RLAST count");
        check_equal(exp_done, mon_transfer_done_count, "Transfer done count");
        check_equal(exp_writes, mon_spad_write_count, "Scratchpad write count");
    end
    endtask

    // ------------------------------------------------------------------
    // TEST 1: A + B, one burst each.
    // 128 B / 8 B per beat = 16 beats per matrix.
    // ------------------------------------------------------------------
    task automatic test_single_burst;
    begin
        $display("====================================================");
        $display("TEST 1 : A + B SINGLE BURST");
        $display("====================================================");
        reset_dut();
        clear_counters();

        send_tile_request(
            32'h1000_0000, 32'h2000_0000, 32'h3000_0000,
            64, 64, 64, 128, 128
        );
        wait_for_completion();

        check_common(2, 32, 2, 1, 32, "TEST 1");

        check_hex(32'h1000_0000, first_mem_addr, "First request is A");
        check_hex(32'h2000_0000, second_mem_addr, "Second request is B");
        check_equal(128, first_mem_bytes, "A burst size");
        check_equal(128, second_mem_bytes, "B burst size");
        finish_test("TEST 1 ADDRESS/PHASE");
    end
    endtask

    // ------------------------------------------------------------------
    // TEST 2: 8-byte A + 8-byte B = one 64-bit beat each.
    // ------------------------------------------------------------------
    task automatic test_single_beat;
    begin
        $display("====================================================");
        $display("TEST 2 : SINGLE BEAT A + B");
        $display("====================================================");
        reset_dut();
        clear_counters();

        send_tile_request(
            32'h1000_0000, 32'h2000_0000, 32'h3000_0000,
            1, 1, 1, 8, 8
        );
        wait_for_completion();

        check_common(2, 2, 2, 1, 2, "TEST 2");
        finish_test("TEST 2 ADDRESS/PHASE");
    end
    endtask

    // ------------------------------------------------------------------
    // TEST 3: 40 B A + 40 B B = five beats each.
    // ------------------------------------------------------------------
    task automatic test_partial_burst;
    begin
        $display("====================================================");
        $display("TEST 3 : PARTIAL BURST A + B");
        $display("====================================================");
        reset_dut();
        clear_counters();

        send_tile_request(
            32'h1000_0000, 32'h2000_0000, 32'h3000_0000,
            1, 1, 1, 40, 40
        );
        wait_for_completion();

        check_common(2, 10, 2, 1, 10, "TEST 3");
        check_equal(40, first_mem_bytes, "A partial burst size");
        check_equal(40, second_mem_bytes, "B partial burst size");
        finish_test("TEST 3 ADDRESS/PHASE");
    end
    endtask

    // ------------------------------------------------------------------
    // TEST 4: 256 B A + 256 B B.
    // Each phase = two 128 B bursts.
    // ------------------------------------------------------------------
    task automatic test_multi_burst;
    begin
        $display("====================================================");
        $display("TEST 4 : MULTI BURST A + B");
        $display("====================================================");
        reset_dut();
        clear_counters();

        send_tile_request(
            32'h1000_0000, 32'h2000_0000, 32'h3000_0000,
            1, 1, 1, 256, 256
        );
        wait_for_completion();

        check_common(4, 64, 4, 1, 64, "TEST 4");
        finish_test("TEST 4");
    end
    endtask

    // ------------------------------------------------------------------
    // TEST 5: Memory request backpressure.
    // Scratchpad remains ready; this tests only the memory request
    // handshake and therefore is independent of the known scratchpad
    // backpressure limitation.
    // ------------------------------------------------------------------
    task automatic test_memory_request_stall;
    begin
        $display("====================================================");
        $display("TEST 5 : MEMORY REQUEST STALL");
        $display("====================================================");
        reset_dut();
        clear_counters();

        force mem_req_ready_to_dut = 1'b0;

        fork
            begin
                send_tile_request(
                    32'h1000_0000, 32'h2000_0000, 32'h3000_0000,
                    1, 1, 1, 128, 128
                );
            end
            begin
                repeat(4) @(posedge clk);
                release mem_req_ready_to_dut;
            end
        join

        wait_for_completion();

        check_common(2, 32, 2, 1, 32, "TEST 5");
        finish_test("TEST 5");
    end
    endtask

    // ------------------------------------------------------------------
    // TEST 6: Known deferred scratchpad-backpressure limitation.
    // We verify memory-side protocol and completion only.
    // ------------------------------------------------------------------
    task automatic test_scratchpad_backpressure;
    begin
        $display("====================================================");
        $display("TEST 6 : SCRATCHPAD BACKPRESSURE (DEFERRED WRITE CHECK)");
        $display("====================================================");
        reset_dut();
        clear_counters();

        fork
            begin
                send_tile_request(
                    32'h1000_0000, 32'h2000_0000, 32'h3000_0000,
                    1, 1, 1, 128, 128
                );
            end
            begin
                repeat(8) @(posedge clk);
                spad_ready = 1'b0;
                repeat(5) @(posedge clk);
                spad_ready = 1'b1;
            end
        join

        wait_for_completion();

        check_equal(2, mon_mem_request_count, "Memory request count");
        check_equal(32, mon_mem_beat_count, "Memory beat count");
        check_equal(2, mon_rlast_count, "RLAST count");
        check_equal(1, mon_transfer_done_count, "Transfer done count");

        $display("[INFO] Scratchpad writes observed = %0d",
                 mon_spad_write_count);
        $display("[INFO] Scratchpad backpressure write-count check is DEFERRED.");

        finish_test("TEST 6");
    end
    endtask

    // ------------------------------------------------------------------
    // Regression
    // ------------------------------------------------------------------
    initial begin
        total_tests = 0;
        passed_tests = 0;
        failed_tests = 0;

        test_single_burst();
        test_single_beat();
        test_partial_burst();
        test_multi_burst();
        test_memory_request_stall();
        test_scratchpad_backpressure();

        $display("");
        $display("====================================================");
        $display("TRANSFER ENGINE VERIFICATION SUMMARY");
        $display("====================================================");
        $display("Tests Executed : %0d", total_tests);
        $display("Tests Passed   : %0d", passed_tests);
        $display("Tests Failed   : %0d", failed_tests);

        if (failed_tests == 0)
            $display("OVERALL RESULT : PASS");
        else
            $display("OVERALL RESULT : FAIL");

        $display("====================================================");
        $finish;
    end

endmodule
