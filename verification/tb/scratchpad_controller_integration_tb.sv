`timescale 1ns/1ps
`default_nettype none

module scratchpad_controller_integration_tb;

    //==========================================================
    // Parameters
    //==========================================================

    localparam int DMA_DATA_WIDTH  = 64;
    localparam int SPAD_DATA_WIDTH = 32;

    localparam int MATRIX_DIM      = 8;
    localparam int DEPTH           = MATRIX_DIM * MATRIX_DIM;
    localparam int ADDR_WIDTH      = $clog2(DEPTH);

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
    // DMA → Controller Interface
    //==========================================================

    logic                      dma_write_enable;
    logic [3:0]                dma_bank;
    logic [31:0]               dma_address;
    logic [DMA_DATA_WIDTH-1:0] dma_write_data;

    logic                      dma_ready;

    //==========================================================
    // Controller → Scratchpad Interface
    //==========================================================

    logic [1:0]                spad_bank_sel;
    logic                      spad_en;
    logic                      spad_we;
    logic [ADDR_WIDTH-1:0]     spad_addr;
    logic [SPAD_DATA_WIDTH-1:0] spad_wdata;

    //==========================================================
    // Scratchpad Compute Read Interface
    //
    // Used only for verification/readback.
    //==========================================================

    logic [1:0]                compute_bank_sel;
    logic                      compute_en;
    logic                      compute_we;
    logic [ADDR_WIDTH-1:0]     compute_addr;
    logic [SPAD_DATA_WIDTH-1:0] compute_wdata;

    logic [SPAD_DATA_WIDTH-1:0] compute_rdata;

    //==========================================================
    // DUT : Scratchpad Controller
    //==========================================================

    scratchpad_controller #(
        .DMA_DATA_WIDTH  (DMA_DATA_WIDTH),
        .SPAD_DATA_WIDTH (SPAD_DATA_WIDTH),
        .SPAD_ADDR_WIDTH (ADDR_WIDTH)
    )
    CONTROLLER (

        .clk              (clk),
        .rst              (rst),

        .dma_write_enable (dma_write_enable),
        .dma_bank         (dma_bank),
        .dma_address      (dma_address),
        .dma_write_data   (dma_write_data),

        .dma_ready        (dma_ready),

        .spad_bank_sel    (spad_bank_sel),
        .spad_en          (spad_en),
        .spad_we          (spad_we),
        .spad_addr        (spad_addr),
        .spad_wdata       (spad_wdata)

    );

    //==========================================================
    // DUT : Real Scratchpad
    //==========================================================

    scratchpad #(
        .DATA_WIDTH (SPAD_DATA_WIDTH),
        .MATRIX_DIM (MATRIX_DIM),
        .DEPTH      (DEPTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    )
    SPAD (

        .clk (clk),
        .rst (rst),

        //------------------------------------------------------
        // DMA Port
        //------------------------------------------------------

        .dma_bank_sel (spad_bank_sel),
        .dma_en       (spad_en),
        .dma_we       (spad_we),
        .dma_addr     (spad_addr),
        .dma_wdata    (spad_wdata),
        .dma_rdata    (),

        //------------------------------------------------------
        // Compute Port
        //------------------------------------------------------

        .compute_bank_sel (compute_bank_sel),
        .compute_en       (compute_en),
        .compute_we       (compute_we),
        .compute_addr     (compute_addr),
        .compute_wdata    (compute_wdata),
        .compute_rdata    (compute_rdata)

    );

    //==========================================================
    // Test Statistics
    //==========================================================

    integer total_tests;
    integer passed_tests;
    integer failed_tests;
    logic test_failed;
    //==========================================================
    // Reset
    //==========================================================

    task automatic reset_dut;

    begin

        rst = 1'b1;

        dma_write_enable = 1'b0;
        dma_bank         = '0;
        dma_address      = '0;
        dma_write_data   = '0;

        compute_bank_sel = '0;
        compute_en       = 1'b0;
        compute_we       = 1'b0;
        compute_addr     = '0;
        compute_wdata    = '0;

        repeat (5)
            @(posedge clk);

        rst = 1'b0;

        repeat (2)
            @(posedge clk);

    end

    endtask

    //==========================================================
    // Send DMA Beat
    //==========================================================

    task automatic send_dma_beat
    (
        input logic [3:0]                bank,
        input logic [31:0]               address,
        input logic [DMA_DATA_WIDTH-1:0] data
    );

    begin

        //------------------------------------------------------
        // Wait until controller can accept transaction
        //------------------------------------------------------

        @(posedge clk);

        while (!dma_ready)
            @(posedge clk);

        //------------------------------------------------------
        // Present transaction
        //------------------------------------------------------

        dma_bank         = bank;
        dma_address      = address;
        dma_write_data   = data;
        dma_write_enable = 1'b1;

        //------------------------------------------------------
        // Hold for one clock
        //------------------------------------------------------

        @(posedge clk);

        dma_write_enable = 1'b0;

        //------------------------------------------------------
        // Allow controller to complete both writes
        //------------------------------------------------------

        repeat (3)
            @(posedge clk);

    end

    endtask

    //==========================================================
// Scratchpad Read
//
// Scratchpad compute-read path contains:
//
//     memory → stage1 → stage2 → compute_rdata
//
// Therefore the testbench waits for the output register
// update before sampling the result.
//==========================================================

task automatic read_spad_word
(
    input  logic [1:0]             bank,
    input  logic [ADDR_WIDTH-1:0]  address,
    output logic [31:0]            data
);

begin

    //------------------------------------------------------
    // Present read request
    //------------------------------------------------------

    @(posedge clk);

    compute_bank_sel = bank;
    compute_addr     = address;
    compute_en       = 1'b1;
    compute_we       = 1'b0;

    //------------------------------------------------------
    // Memory access
    //------------------------------------------------------

    @(posedge clk);

    compute_en = 1'b0;

    //------------------------------------------------------
    // Stage 2 update
    //------------------------------------------------------

    @(posedge clk);

    //------------------------------------------------------
    // Allow NBA update of compute_rdata_stage2
    // to become visible before sampling.
    //------------------------------------------------------

    @(posedge clk);

    data = compute_rdata;

end

endtask

    //==========================================================
    // Check Helper
    //==========================================================

    task automatic check_equal
    (
        input logic [63:0] expected,
        input logic [63:0] actual,
        input string       description
    );

    begin

        if (expected === actual) begin

            $display(
                "[PASS] %s : Expected=%h Observed=%h",
                description,
                expected,
                actual
            );

        end
        else begin

            $display(
                "[FAIL] %s : Expected=%h Observed=%h",
                description,
                expected,
                actual
            );

            test_failed = 1'b1;

        end

    end

    endtask

    //==========================================================
    // Finish Test
    //==========================================================

    task automatic finish_test;

    begin

        total_tests = total_tests + 1;

        if (test_failed) begin

            failed_tests = failed_tests + 1;

            $display("");
            $display("----------------------------------------------------");
            $display("RESULT : FAIL");
            $display("----------------------------------------------------");
            $display("");

        end
        else begin

            passed_tests = passed_tests + 1;

            $display("");
            $display("----------------------------------------------------");
            $display("RESULT : PASS");
            $display("----------------------------------------------------");
            $display("");

        end

    end

    endtask

    //==========================================================
    // TEST 1 : BANK A END-TO-END
    //==========================================================

    task automatic test_bank_a;

        logic [31:0] low_data;
        logic [31:0] high_data;

    begin

        test_failed = 1'b0;

        $display("");
        $display("====================================================");
        $display("TEST 1 : BANK A END-TO-END");
        $display("====================================================");

        reset_dut();

        //------------------------------------------------------
        // Send:
        //
        // 11223344_55667788
        //------------------------------------------------------

        send_dma_beat(
            4'd0,
            32'h0000_0000,
            64'h1122_3344_5566_7788
        );

        //------------------------------------------------------
        // Read lower word
        //------------------------------------------------------

        read_spad_word(
            2'd0,
            6'd0,
            low_data
        );

        //------------------------------------------------------
        // Read upper word
        //------------------------------------------------------

        read_spad_word(
            2'd0,
            6'd1,
            high_data
        );

        //------------------------------------------------------
        // Verify
        //------------------------------------------------------

        check_equal(
            32'h5566_7788,
            low_data,
            "Bank A LOW Word"
        );

        check_equal(
            32'h1122_3344,
            high_data,
            "Bank A HIGH Word"
        );

        finish_test();

    end

    endtask

    //==========================================================
    // TEST 2 : BANK B END-TO-END
    //==========================================================

    task automatic test_bank_b;

        logic [31:0] low_data;
        logic [31:0] high_data;

    begin

        test_failed = 1'b0;

        $display("");
        $display("====================================================");
        $display("TEST 2 : BANK B END-TO-END");
        $display("====================================================");

        reset_dut();

        send_dma_beat(
            4'd1,
            32'h0000_0000,
            64'hAABB_CCDD_1122_3344
        );

        read_spad_word(
            2'd1,
            6'd0,
            low_data
        );

        read_spad_word(
            2'd1,
            6'd1,
            high_data
        );

        check_equal(
            32'h1122_3344,
            low_data,
            "Bank B LOW Word"
        );

        check_equal(
            32'hAABB_CCDD,
            high_data,
            "Bank B HIGH Word"
        );

        finish_test();

    end

    endtask

    //==========================================================
    // TEST 3 : BANK C END-TO-END
    //==========================================================

    task automatic test_bank_c;

        logic [31:0] low_data;
        logic [31:0] high_data;

    begin

        test_failed = 1'b0;

        $display("");
        $display("====================================================");
        $display("TEST 3 : BANK C END-TO-END");
        $display("====================================================");

        reset_dut();

        send_dma_beat(
            4'd2,
            32'h0000_0000,
            64'hDEAD_BEEF_CAFE_BABE
        );

        read_spad_word(
            2'd2,
            6'd0,
            low_data
        );

        read_spad_word(
            2'd2,
            6'd1,
            high_data
        );

        check_equal(
            32'hCAFE_BABE,
            low_data,
            "Bank C LOW Word"
        );

        check_equal(
            32'hDEAD_BEEF,
            high_data,
            "Bank C HIGH Word"
        );

        finish_test();

    end

    endtask

    //==========================================================
    // TEST 4 : NON-ZERO ADDRESS
    //==========================================================

    task automatic test_address_conversion;

        logic [31:0] low_data;
        logic [31:0] high_data;

    begin

        test_failed = 1'b0;

        $display("");
        $display("====================================================");
        $display("TEST 4 : NON-ZERO ADDRESS");
        $display("====================================================");

        reset_dut();

        //------------------------------------------------------
        // DMA byte address = 0x08
        //
        // 0x08 / 4 = SPAD word address 2
        //
        // Therefore:
        //
        // LOW  -> address 2
        // HIGH -> address 3
        //------------------------------------------------------

        send_dma_beat(
            4'd0,
            32'h0000_0008,
            64'hAABB_CCDD_1122_3344
        );

        read_spad_word(
            2'd0,
            6'd2,
            low_data
        );

        read_spad_word(
            2'd0,
            6'd3,
            high_data
        );

        check_equal(
            32'h1122_3344,
            low_data,
            "Address 2 LOW Word"
        );

        check_equal(
            32'hAABB_CCDD,
            high_data,
            "Address 3 HIGH Word"
        );

        finish_test();

    end

    endtask

    //==========================================================
    // TEST 5 : MULTIPLE DMA BEATS
    //==========================================================

    task automatic test_multiple_beats;

        logic [31:0] data0;
        logic [31:0] data1;
        logic [31:0] data2;
        logic [31:0] data3;

    begin

        test_failed = 1'b0;

        $display("");
        $display("====================================================");
        $display("TEST 5 : MULTIPLE DMA BEATS");
        $display("====================================================");

        reset_dut();

        //------------------------------------------------------
        // Beat 0
        //------------------------------------------------------

        send_dma_beat(
            4'd0,
            32'h0000_0000,
            64'h1111_2222_3333_4444
        );

        //------------------------------------------------------
        // Beat 1
        //------------------------------------------------------

        send_dma_beat(
            4'd0,
            32'h0000_0008,
            64'h5555_6666_7777_8888
        );

        //------------------------------------------------------
        // Read back all four words
        //------------------------------------------------------

        read_spad_word(2'd0, 6'd0, data0);
        read_spad_word(2'd0, 6'd1, data1);
        read_spad_word(2'd0, 6'd2, data2);
        read_spad_word(2'd0, 6'd3, data3);

        //------------------------------------------------------
        // Verify
        //------------------------------------------------------

        check_equal(
            32'h3333_4444,
            data0,
            "Word 0"
        );

        check_equal(
            32'h1111_2222,
            data1,
            "Word 1"
        );

        check_equal(
            32'h7777_8888,
            data2,
            "Word 2"
        );

        check_equal(
            32'h5555_6666,
            data3,
            "Word 3"
        );

        finish_test();

    end

    endtask

    //==========================================================
    // TEST 6 : BANK ISOLATION
    //==========================================================

    task automatic test_bank_isolation;

        logic [31:0] bank_a_data;
        logic [31:0] bank_b_data;

    begin

        test_failed = 1'b0;

        $display("");
        $display("====================================================");
        $display("TEST 6 : BANK ISOLATION");
        $display("====================================================");

        reset_dut();

        //------------------------------------------------------
        // Write Bank A
        //------------------------------------------------------

        send_dma_beat(
            4'd0,
            32'h0000_0000,
            64'hAAAA_BBBB_CCCC_DDDD
        );

        //------------------------------------------------------
        // Write Bank B
        //------------------------------------------------------

        send_dma_beat(
            4'd1,
            32'h0000_0000,
            64'h1111_2222_3333_4444
        );

        //------------------------------------------------------
        // Read Bank A
        //------------------------------------------------------

        read_spad_word(
            2'd0,
            6'd0,
            bank_a_data
        );

        //------------------------------------------------------
        // Read Bank B
        //------------------------------------------------------

        read_spad_word(
            2'd1,
            6'd0,
            bank_b_data
        );

        //------------------------------------------------------
        // Verify they retained independent values
        //------------------------------------------------------

        check_equal(
            32'hCCCC_DDDD,
            bank_a_data,
            "Bank A Isolation"
        );

        check_equal(
            32'h3333_4444,
            bank_b_data,
            "Bank B Isolation"
        );

        finish_test();

    end

    endtask

    //==========================================================
    // Main Regression
    //==========================================================

    initial begin

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        test_bank_a();

        test_bank_b();

        test_bank_c();

        test_address_conversion();

        test_multiple_beats();

        test_bank_isolation();

        $display("");
        $display("====================================================");
        $display("SCRATCHPAD CONTROLLER + SCRATCHPAD REGRESSION");
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