`timescale 1ns/1ps
`default_nettype none

module scratchpad_controller_tb;

    //==========================================================
    // Parameters
    //==========================================================

    localparam int DMA_DATA_WIDTH  = 64;
    localparam int SPAD_DATA_WIDTH = 32;
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
    // DMA Interface
    //==========================================================

    logic                       dma_write_enable;
    logic [3:0]                 dma_bank;
    logic [31:0]                dma_address;
    logic [DMA_DATA_WIDTH-1:0]  dma_write_data;

    logic                       dma_ready;

    //==========================================================
    // Scratchpad Interface
    //==========================================================

    logic [1:0]                 spad_bank_sel;
    logic                       spad_en;
    logic                       spad_we;
    logic [SPAD_ADDR_WIDTH-1:0] spad_addr;
    logic [SPAD_DATA_WIDTH-1:0] spad_wdata;

    //==========================================================
    // DUT
    //==========================================================

    scratchpad_controller #(
        .DMA_DATA_WIDTH  (DMA_DATA_WIDTH),
        .SPAD_DATA_WIDTH (SPAD_DATA_WIDTH),
        .SPAD_ADDR_WIDTH (SPAD_ADDR_WIDTH)
    )
    DUT (
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
    // Test Statistics
    //==========================================================

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    //==========================================================
    // Write Monitor
    //==========================================================

    integer write_count;

    logic [1:0]                  captured_bank [0:1];
    logic [SPAD_ADDR_WIDTH-1:0]  captured_addr [0:1];
    logic [SPAD_DATA_WIDTH-1:0] captured_data [0:1];

    always_ff @(posedge clk) begin

        if (!rst) begin

            if (spad_en && spad_we) begin

                if (write_count < 2) begin

                    captured_bank[write_count] = spad_bank_sel;
                    captured_addr[write_count] = spad_addr;
                    captured_data[write_count] = spad_wdata;

                end

                write_count = write_count + 1;

            end

        end

    end

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

        write_count = 0;

        repeat (4)
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

        @(posedge clk);

        while (!dma_ready)
            @(posedge clk);

        dma_bank         = bank;
        dma_address      = address;
        dma_write_data   = data;
        dma_write_enable = 1'b1;

        @(posedge clk);

        dma_write_enable = 1'b0;

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

        end

    end

    endtask

    //==========================================================
    // TEST 1 : Single 64-bit DMA Beat
    //==========================================================

    task automatic test_single_beat;

    begin

        total_tests = total_tests + 1;

        $display("");
        $display("====================================================");
        $display("TEST 1 : SINGLE 64-BIT DMA BEAT");
        $display("====================================================");

        reset_dut();

        send_dma_beat(
            4'd0,
            32'h0000_0000,
            64'h1122_3344_5566_7788
        );

        repeat (3)
            @(posedge clk);

        check_equal(
            2,
            write_count,
            "Scratchpad Write Count"
        );

        check_equal(
            0,
            captured_bank[0],
            "LOW Word Bank"
        );

        check_equal(
            0,
            captured_addr[0],
            "LOW Word Address"
        );

        check_equal(
            32'h5566_7788,
            captured_data[0],
            "LOW Word Data"
        );

        check_equal(
            0,
            captured_bank[1],
            "HIGH Word Bank"
        );

        check_equal(
            1,
            captured_addr[1],
            "HIGH Word Address"
        );

        check_equal(
            32'h1122_3344,
            captured_data[1],
            "HIGH Word Data"
        );

        passed_tests = passed_tests + 1;

        $display("[RESULT] TEST 1 PASS");

    end

    endtask

    //==========================================================
    // TEST 2 : DMA Address Conversion
    //==========================================================

    task automatic test_address_conversion;

    begin

        total_tests = total_tests + 1;

        $display("");
        $display("====================================================");
        $display("TEST 2 : DMA ADDRESS CONVERSION");
        $display("====================================================");

        reset_dut();

        send_dma_beat(
            4'd0,
            32'h0000_0008,
            64'hAABB_CCDD_1122_3344
        );

        repeat (3)
            @(posedge clk);

        check_equal(
            2,
            write_count,
            "Scratchpad Write Count"
        );

        check_equal(
            2,
            captured_addr[0],
            "LOW Word Address"
        );

        check_equal(
            3,
            captured_addr[1],
            "HIGH Word Address"
        );

        check_equal(
            32'h1122_3344,
            captured_data[0],
            "LOW Word Data"
        );

        check_equal(
            32'hAABB_CCDD,
            captured_data[1],
            "HIGH Word Data"
        );

        passed_tests = passed_tests + 1;

        $display("[RESULT] TEST 2 PASS");

    end

    endtask

    //==========================================================
    // TEST 3 : Bank Selection
    //==========================================================

    task automatic test_bank_selection;

        integer bank;

    begin

        total_tests = total_tests + 1;

        $display("");
        $display("====================================================");
        $display("TEST 3 : BANK SELECTION");
        $display("====================================================");

        reset_dut();

        for (bank = 0; bank < 3; bank = bank + 1) begin

            reset_dut();

            send_dma_beat(
                bank[3:0],
                32'h0000_0000,
                64'hDEAD_BEEF_CAFE_BABE
            );

            repeat (3)
                @(posedge clk);

            check_equal(
                bank,
                captured_bank[0],
                "LOW Word Bank"
            );

            check_equal(
                bank,
                captured_bank[1],
                "HIGH Word Bank"
            );

        end

        passed_tests = passed_tests + 1;

        $display("[RESULT] TEST 3 PASS");

    end

    endtask

    //==========================================================
    // TEST 4 : Controller Back-to-Back Protection
    //==========================================================

    task automatic test_ready_behavior;

    begin

        total_tests = total_tests + 1;

        $display("");
        $display("====================================================");
        $display("TEST 4 : READY / BUSY BEHAVIOR");
        $display("====================================================");

        reset_dut();

        if (!dma_ready) begin

            $display("[FAIL] Controller not ready in IDLE");

            failed_tests = failed_tests + 1;

        end
        else begin

            $display("[PASS] Controller ready in IDLE");

        end

        send_dma_beat(
            4'd0,
            32'h0000_0000,
            64'h1234_5678_9ABC_DEF0
        );

        //------------------------------------------------------
        // Controller should be busy during the two writes
        //------------------------------------------------------

        @(posedge clk);

        if (!dma_ready) begin

            $display("[PASS] Controller correctly busy");

        end
        else begin

            $display("[FAIL] Controller incorrectly ready");

        end

        repeat (3)
            @(posedge clk);

        //------------------------------------------------------
        // Controller should return to ready
        //------------------------------------------------------

        if (dma_ready) begin

            $display("[PASS] Controller returned to READY");

        end
        else begin

            $display("[FAIL] Controller did not return to READY");

        end

        passed_tests = passed_tests + 1;

        $display("[RESULT] TEST 4 PASS");

    end

    endtask

    //==========================================================
    // Regression
    //==========================================================

    initial begin

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        test_single_beat();

        test_address_conversion();

        test_bank_selection();

        test_ready_behavior();

        $display("");
        $display("====================================================");
        $display("SCRATCHPAD CONTROLLER REGRESSION");
        $display("====================================================");
        $display("Tests Executed : %0d", total_tests);
        $display("Tests Passed   : %0d", passed_tests);
        $display("Tests Failed   : %0d", failed_tests);
        $display("====================================================");

        $finish;

    end

endmodule

`default_nettype wire