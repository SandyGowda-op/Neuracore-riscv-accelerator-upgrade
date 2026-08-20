//==============================================================================
// Testbench   : mac_unit_tb
// Project     : Descriptor-Driven RISC-V AI Accelerator
//
// Description :
//   Unit testbench for mac_unit.
//
// Tests:
//   1. Reset
//   2. Single MAC
//   3. Multiple MAC operations
//   4. Accumulator clear
//   5. Signed operands
//   6. Disabled MAC / skipped operation
//==============================================================================

`timescale 1ns/1ps
`default_nettype none

module mac_unit_tb;

    //==========================================================
    // Parameters
    //==========================================================

    localparam int OPERAND_WIDTH = 32;
    localparam int ACC_WIDTH     = 64;

    //==========================================================
    // Clock / Reset
    //==========================================================

    logic clk;
    logic rst;

    //==========================================================
    // DUT Interface
    //==========================================================

    logic enable;
    logic clear_acc;

    logic signed [OPERAND_WIDTH-1:0] operand_a;
    logic signed [OPERAND_WIDTH-1:0] operand_b;

    logic signed [ACC_WIDTH-1:0] accumulator;

    //==========================================================
    // Test Statistics
    //==========================================================

    integer tests_executed;
    integer tests_passed;
    integer tests_failed;

    //==========================================================
    // DUT
    //==========================================================

    mac_unit #(
        .OPERAND_WIDTH (OPERAND_WIDTH),
        .ACC_WIDTH     (ACC_WIDTH)
    ) dut (

        .clk          (clk),
        .rst          (rst),

        .enable       (enable),
        .clear_acc    (clear_acc),

        .operand_a    (operand_a),
        .operand_b    (operand_b),

        .accumulator  (accumulator)

    );

    //==========================================================
    // Clock
    //==========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end

    //==========================================================
    // Test Helpers
    //==========================================================

    task automatic check_result;

        input signed [ACC_WIDTH-1:0] expected;
        input [255:0] test_name;

        begin

            tests_executed = tests_executed + 1;

            if (accumulator === expected) begin

                tests_passed = tests_passed + 1;

                $display(
                    "[PASS] %s : Expected=%0d Observed=%0d",
                    test_name,
                    expected,
                    accumulator
                );

            end

            else begin

                tests_failed = tests_failed + 1;

                $display(
                    "[FAIL] %s : Expected=%0d Observed=%0d",
                    test_name,
                    expected,
                    accumulator
                );

            end

        end

    endtask

    //==========================================================
    // Apply One MAC
    //==========================================================

    task automatic do_mac;

        input signed [OPERAND_WIDTH-1:0] a;
        input signed [OPERAND_WIDTH-1:0] b;

        begin

            @(negedge clk);

            operand_a = a;
            operand_b = b;
            enable    = 1'b1;

            @(posedge clk);

            #1;

            enable = 1'b0;

        end

    endtask

    //==========================================================
    // Main Test Sequence
    //==========================================================

    initial begin

        //======================================================
        // Initialization
        //======================================================

        rst = 1'b1;

        enable    = 1'b0;
        clear_acc = 1'b0;

        operand_a = '0;
        operand_b = '0;

        tests_executed = 0;
        tests_passed   = 0;
        tests_failed   = 0;

        //======================================================
        // Reset
        //======================================================

        repeat (2)
            @(posedge clk);

        @(negedge clk);

        rst = 1'b0;

        @(posedge clk);

        #1;

        $display("");
        $display("====================================================");
        $display("TEST 1 : RESET");
        $display("====================================================");

        check_result(
            64'sd0,
            "Accumulator after reset"
        );

        //======================================================
        // TEST 2 : SINGLE MAC
        //======================================================

        $display("");
        $display("====================================================");
        $display("TEST 2 : SINGLE MAC");
        $display("====================================================");

        do_mac(32'sd2, 32'sd3);

        check_result(
            64'sd6,
            "2 x 3"
        );

        //======================================================
        // TEST 3 : MULTIPLE MAC OPERATIONS
        //======================================================

        $display("");
        $display("====================================================");
        $display("TEST 3 : MULTIPLE MAC OPERATIONS");
        $display("====================================================");

        // Current accumulator = 6
        //
        // Add:
        // 4 x 5 = 20
        // 6 x 7 = 42
        //
        // Expected = 6 + 20 + 42 = 68

        do_mac(32'sd4, 32'sd5);
        do_mac(32'sd6, 32'sd7);

        check_result(
            64'sd68,
            "2x3 + 4x5 + 6x7"
        );

        //======================================================
        // TEST 4 : CLEAR ACCUMULATOR
        //======================================================

        $display("");
        $display("====================================================");
        $display("TEST 4 : CLEAR ACCUMULATOR");
        $display("====================================================");

        @(negedge clk);

        clear_acc = 1'b1;

        @(posedge clk);

        #1;

        clear_acc = 1'b0;

        check_result(
            64'sd0,
            "Accumulator clear"
        );

        //======================================================
        // Verify New Dot Product After Clear
        //======================================================

        do_mac(32'sd10, 32'sd4);
        do_mac(32'sd2,  32'sd5);

        // 10x4 + 2x5 = 50

        check_result(
            64'sd50,
            "New dot product after clear"
        );

        //======================================================
        // TEST 5 : SIGNED OPERANDS
        //======================================================

        $display("");
        $display("====================================================");
        $display("TEST 5 : SIGNED OPERANDS");
        $display("====================================================");

        @(negedge clk);

        clear_acc = 1'b1;

        @(posedge clk);

        #1;

        clear_acc = 1'b0;

        // (-2) x 3 = -6

        do_mac(-32'sd2, 32'sd3);

        check_result(
            -64'sd6,
            "(-2) x 3"
        );

        // (-4) x (-5) = +20
        //
        // Expected = -6 + 20 = 14

        do_mac(-32'sd4, -32'sd5);

        check_result(
            64'sd14,
            "(-2)x3 + (-4)x(-5)"
        );

        //======================================================
        // TEST 6 : DISABLED MAC / SPARSE-STYLE SKIP
        //======================================================

        $display("");
        $display("====================================================");
        $display("TEST 6 : DISABLED MAC / SKIP");
        $display("====================================================");

        @(negedge clk);

        clear_acc = 1'b1;

        @(posedge clk);

        #1;

        clear_acc = 1'b0;

        // First useful operation
        do_mac(32'sd3, 32'sd4);

        // -----------------------------------------------------
        // Simulate a skipped sparse operation.
        //
        // enable = 0 means the accumulator must not change.
        // -----------------------------------------------------

        @(negedge clk);

        operand_a = 32'sd100;
        operand_b = 32'sd100;
        enable    = 1'b0;

        @(posedge clk);

        #1;

        check_result(
            64'sd12,
            "Accumulator unchanged during skip"
        );

        // Another useful operation
        do_mac(32'sd5, 32'sd6);

        // Expected = 12 + 30 = 42

        check_result(
            64'sd42,
            "MAC after skipped operation"
        );

        //======================================================
        // Final Result
        //======================================================

        $display("");
        $display("====================================================");
        $display("MAC UNIT REGRESSION");
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

            $display("OVERALL RESULT : PASS");

        end

        else begin

            $display("OVERALL RESULT : FAIL");

        end

        $display("====================================================");

        $finish;

    end

endmodule

`default_nettype wire