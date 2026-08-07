/******************************************************************************
 *
 * Module      : transfer_engine_memory_tb
 *
 * Description :
 *      Directed verification environment for the DMA Transfer Engine and
 *      Behavioral Main Memory Model.
 *
 * Verification Objectives:
 *
 *      • Verify Scheduler → DMA handshake
 *      • Verify DMA request generation
 *      • Verify Main Memory request acceptance
 *      • Verify burst streaming protocol
 *      • Verify RLAST generation
 *      • Verify scratchpad write interface
 *      • Verify DMA completion
 *
 * Notes:
 *
 *      This testbench verifies ONLY:
 *
 *          - transfer_engine.sv
 *          - main_memory_model.sv
 *
 *      Scratchpad controller, scratchpad banks, scheduler integration,
 *      and full subsystem verification are performed in later phases.
 *
 ******************************************************************************/

`timescale 1ns/1ps

import tile_pkg::*;

module transfer_engine_memory_tb;

////////////////////////////////////////////////////////////
// Parameters
////////////////////////////////////////////////////////////

localparam CLK_PERIOD = 10;

////////////////////////////////////////////////////////////
// Clock / Reset
////////////////////////////////////////////////////////////

logic clk;
logic rst;

////////////////////////////////////////////////////////////
// Scheduler Interface
////////////////////////////////////////////////////////////

tile_request_t tile_request;

logic tile_request_valid;
logic tile_request_ready;

////////////////////////////////////////////////////////////
// Main Memory Request Interface
////////////////////////////////////////////////////////////

logic        mem_req_valid;
logic        mem_req_ready;

logic [31:0] mem_req_addr;
logic [31:0] mem_req_bytes;

logic        mem_req_write;

////////////////////////////////////////////////////////////
// Main Memory Read Data Interface
////////////////////////////////////////////////////////////

logic        mem_rvalid;
logic [63:0] mem_rdata;
logic        mem_rlast;

////////////////////////////////////////////////////////////
// Scratchpad Interface
////////////////////////////////////////////////////////////

logic        spad_write_enable;

logic [3:0]  spad_bank;

logic [31:0] spad_address;

logic [63:0] spad_write_data;

logic        spad_ready;

////////////////////////////////////////////////////////////
// DMA Status Interface
////////////////////////////////////////////////////////////

logic transfer_busy;

logic transfer_done;

//------------------------------------------------------
// Memory Stall Control
//------------------------------------------------------

logic mem_req_ready_model;

logic force_mem_request_stall;

logic mem_req_ready_tb;

assign mem_req_ready_tb =
    force_mem_request_stall ?
    1'b0 :
    mem_req_ready_model;

////////////////////////////////////////////////////////////
// Verification Statistics
////////////////////////////////////////////////////////////
//
// Global regression statistics.
//
// These counters summarize the overall regression results
// after all directed tests have completed.
//
////////////////////////////////////////////////////////////

integer total_tests;

integer passed_tests;

integer failed_tests;

////////////////////////////////////////////////////////////
// Transaction Counters
////////////////////////////////////////////////////////////
//
// These counters are automatically updated by protocol
// monitors during simulation.
//
////////////////////////////////////////////////////////////

integer mon_mem_request_count;

integer mon_mem_beat_count;

integer mon_rlast_count;

integer mon_transfer_done_count;

integer mon_spad_write_count;


////////////////////////////////////////////////////////////
// Expected Results
////////////////////////////////////////////////////////////
//
// Expected values for the currently executing test.
//
// Each test initializes these before starting.
//
////////////////////////////////////////////////////////////

integer exp_mem_requests;

integer exp_mem_beats;

integer exp_rlast_count;

integer exp_transfer_done;

integer exp_spad_writes;

////////////////////////////////////////////////////////////
// Actual Results
////////////////////////////////////////////////////////////
//
// Actual values copied from the monitors after a test
// completes.
//
////////////////////////////////////////////////////////////

integer act_mem_requests;

integer act_mem_beats;

integer act_rlast_count;

integer act_transfer_done;

integer act_spad_writes;

////////////////////////////////////////////////////////////
// Test Information
////////////////////////////////////////////////////////////

string current_test_name;

logic test_failed;

////////////////////////////////////////////////////////////
// Clock Generation
////////////////////////////////////////////////////////////

initial
begin

    clk = 1'b0;

    forever #(CLK_PERIOD/2)
        clk = ~clk;

end

////////////////////////////////////////////////////////////
// Reset Task
////////////////////////////////////////////////////////////
//
// Resets the DUT and initializes all testbench-driven
// interface signals.
//
// Every test shall begin by calling:
//
//      reset_dut();
//
// This guarantees that each test starts from a known,
// independent state.
//
////////////////////////////////////////////////////////////

task automatic reset_dut;

begin

    //------------------------------------------------------
    // Assert Reset
    //------------------------------------------------------

    rst = 1'b1;

    //------------------------------------------------------
    // Initialize Scheduler Interface
    //------------------------------------------------------

    tile_request       = '0;

    tile_request_valid = 1'b0;

    //------------------------------------------------------
    // Initialize Scratchpad Interface
    //------------------------------------------------------

    spad_ready = 1'b1;

    //------------------------------------------------------
    // Initialize Memory Interface
    //------------------------------------------------------

    mem_req_write = 1'b0;

    force_mem_request_stall = 1'b0;

    //------------------------------------------------------
    // Hold Reset
    //------------------------------------------------------

    repeat(5)
        @(posedge clk);

    //------------------------------------------------------
    // Release Reset
    //------------------------------------------------------

    rst = 1'b0;

    repeat(2)
        @(posedge clk);

end

endtask

////////////////////////////////////////////////////////////
// Utility Tasks
////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
// Clear Verification Counters
////////////////////////////////////////////////////////////

task automatic clear_counters;

begin

    //------------------------------------------------------
    // Monitor Counters
    //------------------------------------------------------

    mon_mem_request_count   = 0;

    mon_mem_beat_count      = 0;

    mon_rlast_count         = 0;

    mon_transfer_done_count = 0;

    mon_spad_write_count    = 0;

    //------------------------------------------------------
    // Actual Results
    //------------------------------------------------------

    act_mem_requests   = 0;

    act_mem_beats      = 0;

    act_rlast_count    = 0;

    act_transfer_done  = 0;

    act_spad_writes    = 0;

    //------------------------------------------------------
    // Test Status
    //------------------------------------------------------

    test_failed = 1'b0;

end

endtask

////////////////////////////////////////////////////////////
// Test Banner
////////////////////////////////////////////////////////////

task automatic util_banner
(
    input string test_name
);

begin

    current_test_name = test_name;

    $display("");
    $display("====================================================");
    $display("%s", test_name);
    $display("====================================================");
    $display("");

end

endtask

////////////////////////////////////////////////////////////
// PASS Message
////////////////////////////////////////////////////////////

task automatic util_pass
(
    input string item
);

begin

    $display("[PASS] %s", item);

end

endtask

////////////////////////////////////////////////////////////
// Reset Monitor Statistics
////////////////////////////////////////////////////////////

task automatic reset_statistics;

begin

    mon_mem_request_count = 0;
    mon_mem_beat_count    = 0;
    mon_rlast_count       = 0;
    mon_spad_write_count  = 0;

end

endtask

////////////////////////////////////////////////////////////
// FAIL Message
////////////////////////////////////////////////////////////

task automatic util_fail
(
    input string item,
    input integer expected,
    input integer observed
);

begin

    test_failed = 1'b1;

    $display("[FAIL] %s", item);
    $display("       Expected : %0d", expected);
    $display("       Observed : %0d", observed);
    $display("");

end

endtask

////////////////////////////////////////////////////////////
// Generic Checker
////////////////////////////////////////////////////////////

task automatic check_equal
(
    input integer expected,
    input integer observed,
    input string item
);

begin

    if(expected == observed)
    begin

        util_pass(item);

    end
    else
    begin

        util_fail(item, expected, observed);

    end

end

endtask

////////////////////////////////////////////////////////////
// Test Result
////////////////////////////////////////////////////////////

task automatic finish_test;

begin

    total_tests = total_tests + 1;

    if(test_failed)
    begin

        failed_tests = failed_tests + 1;

        $display("");
        $display("----------------------------------------------------");
        $display("RESULT : FAIL");
        $display("----------------------------------------------------");
        $display("");

    end
    else
    begin

        passed_tests = passed_tests + 1;

        $display("");
        $display("----------------------------------------------------");
        $display("RESULT : PASS");
        $display("----------------------------------------------------");
        $display("");

    end

end

endtask

////////////////////////////////////////////////////////////
// Regression Summary
////////////////////////////////////////////////////////////

task automatic regression_summary;

begin

    $display("");
    $display("====================================================");
    $display("TRANSFER ENGINE VERIFICATION SUMMARY");
    $display("====================================================");
    $display("");

    $display("Tests Executed : %0d", total_tests);

    $display("Tests Passed   : %0d", passed_tests);

    $display("Tests Failed   : %0d", failed_tests);

    if(failed_tests == 0)
        $display("\nOVERALL RESULT : PASS");
    else
        $display("\nOVERALL RESULT : FAIL");

    $display("");
    $display("====================================================");
    $display("");

end

endtask

////////////////////////////////////////////////////////////
// Protocol Monitors
////////////////////////////////////////////////////////////
//
// These monitors passively observe DUT interfaces and
// update verification counters.
//
// They never modify DUT signals.
//
////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
// Memory Request Monitor
////////////////////////////////////////////////////////////

always_ff @(posedge clk)
begin

    if(!rst)
    begin

        if(mem_req_valid && mem_req_ready_tb)
        begin

            mon_mem_request_count++;

        end

    end

end

////////////////////////////////////////////////////////////
// Memory Beat Monitor
////////////////////////////////////////////////////////////

always_ff @(posedge clk)
begin

    if(!rst)
    begin

        if(mem_rvalid)
        begin

            mon_mem_beat_count++;

        end

    end

end

////////////////////////////////////////////////////////////
// RLAST Monitor
////////////////////////////////////////////////////////////

always_ff @(posedge clk)
begin

    if(!rst)
    begin

        if(mem_rvalid && mem_rlast)
        begin

            mon_rlast_count++;

        end

    end

end

////////////////////////////////////////////////////////////
// Scratchpad Write Monitor
////////////////////////////////////////////////////////////

always_ff @(posedge clk)
begin

    if(!rst)
    begin

        if(spad_write_enable)
        begin

            mon_spad_write_count++;

        end

    end

end

////////////////////////////////////////////////////////////
// DMA Completion Monitor
////////////////////////////////////////////////////////////

always_ff @(posedge clk)
begin

    if(!rst)
    begin

        if(transfer_done)
        begin

            mon_transfer_done_count++;

        end

    end

end

////////////////////////////////////////////////////////////
// Driver Tasks
////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
// Information Message
////////////////////////////////////////////////////////////

task automatic util_info
(
    input string message
);

begin

    $display("[INFO] %s", message);

end

endtask

////////////////////////////////////////////////////////////
// Send Tile Request
////////////////////////////////////////////////////////////
//
// Drives one scheduler transaction into the DMA.
//
// Implements the VALID / READY protocol.
//
////////////////////////////////////////////////////////////

task automatic send_tile_request
(
    input logic [31:0] addr_a,
    input logic [31:0] addr_b,
    input logic [31:0] addr_c,

    input logic [15:0] rows,
    input logic [15:0] cols,
    input logic [15:0] k_size,

    input logic [31:0] transfer_bytes
);

begin

    util_info("Sending Tile Request");

    //------------------------------------------------------
    // Populate Transaction
    //------------------------------------------------------

    tile_request = '0;

    tile_request.addr_a = addr_a;
    tile_request.addr_b = addr_b;
    tile_request.addr_c = addr_c;

    tile_request.rows = rows;
    tile_request.cols = cols;
    tile_request.k_size = k_size;

    tile_request.bank_a = 0;
    tile_request.bank_b = 1;
    tile_request.bank_c = 2;

    tile_request.transfer_bytes = transfer_bytes;

    tile_request.last_tile = 1'b1;

    //------------------------------------------------------
    // Drive request before handshake
    //------------------------------------------------------

    $display("");
    $display("------------------------------------------");
    $display("Scheduler Request");
    $display("------------------------------------------");
    $display("Addr A : %08h", addr_a);
    $display("Bytes  : %0d", transfer_bytes);
    $display("");

    tile_request_valid = 1'b1;

    // Give request one cycle to settle
    @(posedge clk);

    // Wait until handshake occurs
    while (!(tile_request_valid && tile_request_ready))
    @(posedge clk);

    // Hold for one more clock
    @(posedge clk);

    // Remove request
    tile_request_valid = 1'b0;
    tile_request = '0;

    util_info("Tile Request Accepted");

end

endtask

////////////////////////////////////////////////////////////
// Wait For DMA Completion
////////////////////////////////////////////////////////////

task automatic wait_for_completion;

    integer timeout;

begin

    util_info("Waiting For DMA Completion");

    timeout = 0;

    while (!transfer_done)
    begin

        @(posedge clk);

        timeout++;

        if (timeout > 1000)
        begin
            $fatal(1, "DMA Timeout");
        end

    end

    @(posedge clk);

    util_info("DMA Transfer Complete");

end

endtask

////////////////////////////////////////////////////////////
// DUT : Transfer Engine
////////////////////////////////////////////////////////////

transfer_engine DUT
(
    .clk(clk),
    .rst(rst),

    .tile_request(tile_request),
    .tile_request_valid(tile_request_valid),
    .tile_request_ready(tile_request_ready),

    .mem_req_valid(mem_req_valid),
    .mem_req_ready(mem_req_ready_tb),
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

////////////////////////////////////////////////////////////
// DUT : Main Memory Model
////////////////////////////////////////////////////////////

main_memory_model MEMORY
(
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

////////////////////////////////////////////////////////////
// Expected Result Setup
////////////////////////////////////////////////////////////

task automatic setup_expected_results
(
    input integer mem_requests,
    input integer mem_beats,
    input integer rlast_count,
    input integer transfer_done,
    input integer spad_writes
);

begin

    exp_mem_requests  = mem_requests;

    exp_mem_beats     = mem_beats;

    exp_rlast_count   = rlast_count;

    exp_transfer_done = transfer_done;

    exp_spad_writes   = spad_writes;

end

endtask

////////////////////////////////////////////////////////////
// Verify Test Results
////////////////////////////////////////////////////////////

task automatic verify_results;

begin

    //------------------------------------------------------
    // Copy Monitor Results
    //------------------------------------------------------

    act_mem_requests  = mon_mem_request_count;

    act_mem_beats     = mon_mem_beat_count;

    act_rlast_count   = mon_rlast_count;

    act_transfer_done = mon_transfer_done_count;

    act_spad_writes   = mon_spad_write_count;

    //------------------------------------------------------
    // Perform Checks
    //------------------------------------------------------

    check_equal(
        exp_mem_requests,
        act_mem_requests,
        "Memory Request Count"
    );

    check_equal(
        exp_mem_beats,
        act_mem_beats,
        "Memory Beat Count"
    );

    check_equal(
        exp_rlast_count,
        act_rlast_count,
        "RLAST Count"
    );

    check_equal(
        exp_transfer_done,
        act_transfer_done,
        "Transfer Done Count"
    );

    check_equal(
        exp_spad_writes,
        act_spad_writes,
        "Scratchpad Write Count"
    );

end

endtask

////////////////////////////////////////////////////////////
// TEST 1 : SINGLE BURST
////////////////////////////////////////////////////////////

task automatic test_single_burst;

begin

    util_banner("TEST 1 : SINGLE BURST");

    //------------------------------------------------------
    // Test Initialization
    //------------------------------------------------------

    reset_dut();

    clear_counters();

    //------------------------------------------------------
    // Expected Results
    //------------------------------------------------------

    setup_expected_results
    (
        1,      // Memory Requests

        16,     // Memory Beats

        1,      // RLAST

        1,      // Transfer Done

        16      // Scratchpad Writes
    );

    //------------------------------------------------------
    // Execute Transaction
    //------------------------------------------------------

    send_tile_request
    (
        32'h1000_0000,
        32'h2000_0000,
        32'h3000_0000,

        64,
        64,
        64,

        128
    );

    wait_for_completion();

    //------------------------------------------------------
    // Verify
    //------------------------------------------------------

    verify_results();

    finish_test();

end

endtask

////////////////////////////////////////////////////////////
// TEST 2 : SINGLE BEAT
////////////////////////////////////////////////////////////

task automatic test_single_beat;

begin

    //------------------------------------------------------
    // Reset Test Status
    //------------------------------------------------------

    test_failed = 0;

    //------------------------------------------------------
    // Reset Monitor Counters
    //------------------------------------------------------

    mon_mem_request_count = 0;
    mon_mem_beat_count    = 0;
    mon_rlast_count       = 0;
    mon_spad_write_count  = 0;
    mon_transfer_done_count = 0;

    //------------------------------------------------------
    // Display Test Header
    //------------------------------------------------------

    $display("");
    $display("====================================================");
    $display("TEST 2 : SINGLE BEAT");
    $display("====================================================");
    $display("");

    //------------------------------------------------------
    // Send Request
    //------------------------------------------------------

    send_tile_request
    (
        32'h1000_0000,
        32'h2000_0000,
        32'h3000_0000,

        1,
        1,
        1,

        8
    );

    //------------------------------------------------------
    // Wait for DMA Completion
    //------------------------------------------------------

    wait_for_completion();

    //------------------------------------------------------
    // Check Results
    //------------------------------------------------------

    check_equal(
        1,
        mon_mem_request_count,
        "Memory Request Count"
    );

    check_equal(
        1,
        mon_mem_beat_count,
        "Memory Beat Count"
    );

    check_equal(
        1,
        mon_rlast_count,
        "RLAST Count"
    );

    check_equal(
        1,
        mon_transfer_done_count,
        "Transfer Done Count"
    );

    check_equal(
        1,
        mon_spad_write_count,
        "Scratchpad Write Count"
    );

finish_test();

end

endtask


////////////////////////////////////////////////////////////
// TEST 2 : PARTIAL BURST
////////////////////////////////////////////////////////////

task automatic test_partial_burst;

begin

    //------------------------------------------------------
    // Reset Test Status
    //------------------------------------------------------

    test_failed = 0;

    //------------------------------------------------------
    // Reset Monitor Counters
    //------------------------------------------------------

    mon_mem_request_count = 0;
    mon_mem_beat_count    = 0;
    mon_rlast_count       = 0;
    mon_spad_write_count  = 0;
    mon_transfer_done_count = 0;

    //------------------------------------------------------
    // Display Test Header
    //------------------------------------------------------

    $display("");
    $display("====================================================");
    $display("TEST 3 : PARTIAL BURST (40 BYTES)");
    $display("====================================================");
    $display("");

    //------------------------------------------------------
    // Send Request
    //------------------------------------------------------

    send_tile_request
    (
        32'h1000_0000,
        32'h2000_0000,
        32'h3000_0000,

        1,
        1,
        1,

        40
    );

    //------------------------------------------------------
    // Wait for DMA Completion
    //------------------------------------------------------

    wait_for_completion();

    //------------------------------------------------------
    // Check Results
    //------------------------------------------------------

    check_equal(
        1,
        mon_mem_request_count,
        "Memory Request Count"
    );

    check_equal(
        5,
        mon_mem_beat_count,
        "Memory Beat Count"
    );

    check_equal(
        1,
        mon_rlast_count,
        "RLAST Count"
    );

    check_equal(
        1,
        mon_transfer_done_count,
        "Transfer Done Count"
    );

    check_equal(
        5,
        mon_spad_write_count,
        "Scratchpad Write Count"
    );

finish_test();

end

endtask

////////////////////////////////////////////////////////////
// TEST 4 : MULTI BURST (256 BYTES)
////////////////////////////////////////////////////////////

task automatic test_multi_burst;

begin

    //------------------------------------------------------
    // Reset Test Status
    //------------------------------------------------------

    test_failed = 0;

    //------------------------------------------------------
    // Reset Monitor Counters
    //------------------------------------------------------

    mon_mem_request_count   = 0;
    mon_mem_beat_count      = 0;
    mon_rlast_count         = 0;
    mon_transfer_done_count = 0;
    mon_spad_write_count    = 0;

    //------------------------------------------------------
    // Display Test Header
    //------------------------------------------------------

    $display("");
    $display("====================================================");
    $display("TEST 4 : MULTI BURST (256 BYTES)");
    $display("====================================================");
    $display("");

    //------------------------------------------------------
    // Send Scheduler Request
    //------------------------------------------------------

    send_tile_request
    (
        32'h1000_0000,
        32'h2000_0000,
        32'h3000_0000,

        1,
        1,
        1,

        256
    );

    //------------------------------------------------------
    // Wait for DMA Completion
    //------------------------------------------------------

    wait_for_completion();

    //------------------------------------------------------
    // Check Results
    //------------------------------------------------------

    check_equal(
        2,
        mon_mem_request_count,
        "Memory Request Count"
    );

    check_equal(
        32,
        mon_mem_beat_count,
        "Memory Beat Count"
    );

    check_equal(
        2,
        mon_rlast_count,
        "RLAST Count"
    );

    check_equal(
        1,
        mon_transfer_done_count,
        "Transfer Done Count"
    );

    check_equal(
        32,
        mon_spad_write_count,
        "Scratchpad Write Count"
    );

    //------------------------------------------------------
    // Finish Test
    //------------------------------------------------------

    finish_test();

end

endtask

////////////////////////////////////////////////////////////
// TEST 5 : MEMORY REQUEST STALL
////////////////////////////////////////////////////////////

task automatic test_memory_request_stall;

begin

//------------------------------------------------------
// Reset Counters
//------------------------------------------------------

mon_mem_request_count   = 0;
mon_mem_beat_count      = 0;
mon_rlast_count         = 0;
mon_transfer_done_count = 0;
mon_spad_write_count    = 0;

test_failed = 0;

force_mem_request_stall = 1'b1;

$display("");
$display("====================================================");
$display("TEST 5 : MEMORY REQUEST STALL");
$display("====================================================");
$display("");

fork

begin
    repeat(4)
        @(posedge clk);

    force_mem_request_stall = 1'b0;

    $display("");
    $display("[INFO] Memory Request Stall Released");
    $display("");
end

begin
    send_tile_request
    (
        32'h1000_0000,
        32'h2000_0000,
        32'h3000_0000,

        1,
        1,
        1,

        128
    );
end

join

wait_for_completion();

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
    1,
    mon_rlast_count,
    "RLAST Count"
);

check_equal(
    1,
    mon_transfer_done_count,
    "Transfer Done Count"
);

check_equal(
    16,
    mon_spad_write_count,
    "Scratchpad Write Count"
);


finish_test();



end
endtask


////////////////////////////////////////////////////////////
// TEST 6 : SCRATCHPAD BACKPRESSURE
////////////////////////////////////////////////////////////

task automatic test_scratchpad_backpressure;

begin

    //------------------------------------------------------
    // Reset Counters
    //------------------------------------------------------

    mon_mem_request_count   = 0;
    mon_mem_beat_count      = 0;
    mon_rlast_count         = 0;
    mon_transfer_done_count = 0;
    mon_spad_write_count    = 0;

    test_failed = 0;

    //------------------------------------------------------
    // Header
    //------------------------------------------------------

    $display("");
    $display("====================================================");
    $display("TEST 6 : SCRATCHPAD BACKPRESSURE");
    $display("====================================================");
    $display("");

    //------------------------------------------------------
    // Scratchpad initially ready
    //------------------------------------------------------

    spad_ready = 1'b1;

    fork

//--------------------------------------------------
// Create Backpressure
//--------------------------------------------------

begin

    repeat(8)
        @(posedge clk);

    spad_ready = 1'b0;

    $display("");
    $display("[INFO] Scratchpad Stalled");
    $display("");

    repeat(5)
        @(posedge clk);

    spad_ready = 1'b1;

    $display("");
    $display("[INFO] Scratchpad Ready");
    $display("");

end

//--------------------------------------------------
// Start DMA
//--------------------------------------------------

begin

    send_tile_request
    (
        32'h1000_0000,
        32'h2000_0000,
        32'h3000_0000,

        1,
        1,
        1,

        128
    );

end

join

//------------------------------------------------------
// Wait
//------------------------------------------------------

wait_for_completion();

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
    1,
    mon_rlast_count,
    "RLAST Count"
);

check_equal(
    1,
    mon_transfer_done_count,
    "Transfer Done Count"
);

check_equal(
    16,
    mon_spad_write_count,
    "Scratchpad Write Count"
);

finish_test();

end
endtask

////////////////////////////////////////////////////////////
// Main Regression
////////////////////////////////////////////////////////////

initial
begin

    //------------------------------------------------------
    // Initialize Regression Statistics
    //------------------------------------------------------

    total_tests  = 0;
    passed_tests = 0;
    failed_tests = 0;

    //------------------------------------------------------
    // Execute Tests
    //------------------------------------------------------

    test_single_burst();

    test_single_beat();

    test_partial_burst();

    test_multi_burst();

    test_memory_request_stall();

    test_scratchpad_backpressure();

    //------------------------------------------------------
    // Regression Summary
    //------------------------------------------------------

    regression_summary();

    $finish;

end

endmodule