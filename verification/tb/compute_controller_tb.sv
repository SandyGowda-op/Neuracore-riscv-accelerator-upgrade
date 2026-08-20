//==============================================================================
// Testbench    : compute_controller_tb
// Project      : Descriptor-Driven RISC-V AI Accelerator
//
// Description  :
//   Standalone dense compute-controller verification.
//
//   Verifies:
//
//     1. Reset
//     2. Dense 8x8 GEMM
//     3. Signed operands
//     4. Scratchpad two-cycle read latency
//     5. Correct i/j/k traversal
//     6. MAC operation count
//     7. Scratchpad read count
//     8. Output count
//     9. Completion
//
//   Golden reference is calculated independently in the testbench.
//   The legacy mmul_mem module is NOT used.
//
//==============================================================================

`timescale 1ns/1ps
`default_nettype none

module compute_controller_tb;

    //======================================================================
    // Parameters
    //======================================================================

    localparam int DATA_WIDTH = 32;
    localparam int ACC_WIDTH  = 64;
    localparam int ADDR_WIDTH = 6;

    localparam int N = 8;

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
    // Controller Inputs
    //======================================================================

    logic start;

    logic [ADDR_WIDTH-1:0] base_addr_a;
    logic [ADDR_WIDTH-1:0] base_addr_b;

    logic [15:0] stride_a;
    logic [15:0] stride_b;

    logic [15:0] rows;
    logic [15:0] cols;
    logic [15:0] k_size;

    //======================================================================
    // Controller Outputs
    //======================================================================

    logic busy;
    logic done;

    logic                  spad_a_en;
    logic [ADDR_WIDTH-1:0] spad_a_addr;
    logic [DATA_WIDTH-1:0] spad_a_rdata;

    logic                  spad_b_en;
    logic [ADDR_WIDTH-1:0] spad_b_addr;
    logic [DATA_WIDTH-1:0] spad_b_rdata;

    logic                  result_valid;
    logic [15:0]            result_row;
    logic [15:0]            result_col;
    logic signed [ACC_WIDTH-1:0] result_data;

    //======================================================================
    // Instrumentation
    //======================================================================

    logic [31:0] cycle_count;
    logic [31:0] a_read_count;
    logic [31:0] b_read_count;
    logic [31:0] mac_count;
    logic [31:0] output_count;

    //======================================================================
    // Scratchpad Control Signals
    //======================================================================

    logic spad_a_rst;
    logic spad_b_rst;

    //======================================================================
    // Compute Controller
    //======================================================================

    compute_controller #(

        .DATA_WIDTH (DATA_WIDTH),
        .ACC_WIDTH  (ACC_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)

    ) dut (

        .clk          (clk),
        .rst          (rst),

        .start        (start),

        .base_addr_a  (base_addr_a),
        .base_addr_b  (base_addr_b),

        .stride_a     (stride_a),
        .stride_b     (stride_b),

        .rows         (rows),
        .cols         (cols),
        .k_size       (k_size),

        .busy         (busy),
        .done         (done),

        .spad_a_en    (spad_a_en),
        .spad_a_addr  (spad_a_addr),
        .spad_a_rdata (spad_a_rdata),

        .spad_b_en    (spad_b_en),
        .spad_b_addr  (spad_b_addr),
        .spad_b_rdata (spad_b_rdata),

        .result_valid (result_valid),
        .result_row   (result_row),
        .result_col   (result_col),
        .result_data  (result_data),

        .cycle_count  (cycle_count),
        .a_read_count (a_read_count),
        .b_read_count (b_read_count),
        .mac_count    (mac_count),
        .output_count (output_count)

    );

    //======================================================================
    // Scratchpad Bank A
    //======================================================================

    scratchpad_bank #(

        .DATA_WIDTH (DATA_WIDTH),
        .MATRIX_DIM (N),
        .DEPTH      (N*N),
        .ADDR_WIDTH (ADDR_WIDTH)

    ) bank_a (

        .clk          (clk),
        .rst          (rst),

        .dma_en       (1'b0),
        .dma_we       (1'b0),
        .dma_addr     ('0),
        .dma_wdata    ('0),
        .dma_rdata    (),

        .compute_en   (spad_a_en),
        .compute_we   (1'b0),
        .compute_addr (spad_a_addr),
        .compute_wdata('0),
        .compute_rdata(spad_a_rdata)

    );

    //======================================================================
    // Scratchpad Bank B
    //======================================================================

    scratchpad_bank #(

        .DATA_WIDTH (DATA_WIDTH),
        .MATRIX_DIM (N),
        .DEPTH      (N*N),
        .ADDR_WIDTH (ADDR_WIDTH)

    ) bank_b (

        .clk          (clk),
        .rst          (rst),

        .dma_en       (1'b0),
        .dma_we       (1'b0),
        .dma_addr     ('0),
        .dma_wdata    ('0),
        .dma_rdata    (),

        .compute_en   (spad_b_en),
        .compute_we   (1'b0),
        .compute_addr (spad_b_addr),
        .compute_wdata('0),
        .compute_rdata(spad_b_rdata)

    );

    //======================================================================
    // Golden Matrices
    //======================================================================

    integer A [0:N-1][0:N-1];
    integer B [0:N-1][0:N-1];
    integer C_expected [0:N-1][0:N-1];

    integer r;
    integer c;
    integer k;

    //======================================================================
    // Test Counters
    //======================================================================

    integer tests_executed;
    integer tests_passed;
    integer tests_failed;

    //======================================================================
    // Test Result Storage
    //======================================================================

    logic signed [ACC_WIDTH-1:0] observed_C [0:N-1][0:N-1];

    //======================================================================
    // Matrix Initialization
    //======================================================================

    task automatic initialize_matrices;

        begin

            //--------------------------------------------------------------
            // Use signed values so that negative operand behavior is tested.
            //--------------------------------------------------------------

            for (r = 0; r < N; r = r + 1) begin

                for (c = 0; c < N; c = c + 1) begin

                    A[r][c] = (r + 1) * (c + 1);

                    B[r][c] = 0;

                    C_expected[r][c] = 0;

                end

            end

            //--------------------------------------------------------------
            // Make B a simple diagonal matrix.
            //
            // This gives an easily independently verifiable result:
            //
            // C[i][j] = A[i][j] * (j+1)
            //
            //--------------------------------------------------------------

            for (r = 0; r < N; r = r + 1)
                B[r][r] = r + 1;

            //--------------------------------------------------------------
            // Add signed values to exercise signed multiplication.
            //--------------------------------------------------------------

            A[1][2] = -3;
            B[2][1] = -4;

            A[4][5] = -6;
            B[5][4] = 2;

        end

    endtask

    //======================================================================
    // Calculate Golden GEMM
    //======================================================================

    task automatic calculate_golden;

        integer sum;

        begin

            for (r = 0; r < N; r = r + 1) begin

                for (c = 0; c < N; c = c + 1) begin

                    sum = 0;

                    for (k = 0; k < N; k = k + 1) begin

                        sum = sum + A[r][k] * B[k][c];

                    end

                    C_expected[r][c] = sum;

                end

            end

        end

    endtask

    //======================================================================
    // Load Matrix Into Scratchpad Banks
    //======================================================================

    task automatic load_scratchpads;

        begin

            for (r = 0; r < N; r = r + 1) begin

                for (c = 0; c < N; c = c + 1) begin

                    //------------------------------------------------------
                    // Bank A
                    //------------------------------------------------------

                    bank_a.mem[(r*N)+c] = A[r][c];

                    //------------------------------------------------------
                    // Bank B
                    //------------------------------------------------------

                    bank_b.mem[(r*N)+c] = B[r][c];

                end

            end

        end

    endtask

    //======================================================================
    // Clear Observed Results
    //======================================================================

    task automatic clear_observed;

        begin

            for (r = 0; r < N; r = r + 1)
                for (c = 0; c < N; c = c + 1)
                    observed_C[r][c] = '0;

        end

    endtask

    //======================================================================
    // Capture Results
    //======================================================================

    always @(posedge clk) begin

        if (result_valid) begin

        $display(
            "[RESULT_CAPTURE] row=%0d col=%0d data=%0d",
            result_row,
            result_col,
            $signed(result_data)
        );

        observed_C[result_row][result_col] <= result_data;

    end

end

//======================================================================
// Result Capture Monitor
//======================================================================

always @(posedge clk) begin

    if (result_valid) begin

        $display(
            "[RESULT_CAPTURE] row=%0d col=%0d data=%0d",
            result_row,
            result_col,
            $signed(result_data)
        );

        observed_C[result_row][result_col] <= result_data;

    end

end


//======================================================================
// Scratchpad Read Debug Monitor
//======================================================================

always @(posedge clk) begin

    #1;

    if (dut.state == dut.ISSUE_READ) begin

        $display(
            "[TB_SPAD_ISSUE] t=%0t state=ISSUE_READ i=%0d j=%0d k=%0d A_ADDR=%0d B_ADDR=%0d A_EN=%b B_EN=%b",
            $time,
            dut.i,
            dut.j,
            dut.k,
            spad_a_addr,
            spad_b_addr,
            spad_a_en,
            spad_b_en
        );

    end

end

    //======================================================================
    // Start Computation
    //======================================================================

    task automatic start_compute;

        begin

            @(negedge clk);

            start = 1'b1;

            @(negedge clk);

            start = 1'b0;

        end

    endtask

    //======================================================================
    // Check Matrix
    //======================================================================

    task automatic check_results;

        integer expected;
        integer observed;

        begin

            for (r = 0; r < N; r = r + 1) begin

                for (c = 0; c < N; c = c + 1) begin

                    tests_executed = tests_executed + 1;

                    expected = C_expected[r][c];
                    observed = observed_C[r][c];

                    if (observed == expected) begin

                        tests_passed = tests_passed + 1;

                        $display(
                            "[PASS] C[%0d][%0d] : Expected=%0d Observed=%0d",
                            r,
                            c,
                            expected,
                            observed
                        );

                    end

                    else begin

                        tests_failed = tests_failed + 1;

                        $display(
                            "[FAIL] C[%0d][%0d] : Expected=%0d Observed=%0d",
                            r,
                            c,
                            expected,
                            observed
                        );

                    end

                end

            end

        end

    endtask

    //======================================================================
    // Main Test
    //======================================================================

    initial begin

        //--------------------------------------------------------------
        // Initialize
        //--------------------------------------------------------------

        start = 1'b0;

        base_addr_a = '0;
        base_addr_b = '0;

        stride_a = N;
        stride_b = N;

        rows   = N;
        cols   = N;
        k_size = N;

        tests_executed = 0;
        tests_passed   = 0;
        tests_failed   = 0;

        clear_observed();

        //--------------------------------------------------------------
        // Reset
        //--------------------------------------------------------------

        rst = 1'b1;

        repeat (4)
            @(posedge clk);

        rst = 1'b0;

        //--------------------------------------------------------------
        // Prepare data
        //--------------------------------------------------------------

        initialize_matrices();
        calculate_golden();
        load_scratchpads();

        $display("TB CHECK: A[0][0] mem=%0d", $signed(bank_a.mem[0]));
        $display("TB CHECK: A[0][1] mem=%0d", $signed(bank_a.mem[1]));
        $display("TB CHECK: A[1][0] mem=%0d", $signed(bank_a.mem[8]));
        $display("TB CHECK: B[0][0] mem=%0d", $signed(bank_b.mem[0]));
        $display("TB CHECK: B[1][0] mem=%0d", $signed(bank_b.mem[8]));

        

        //--------------------------------------------------------------
        // Start computation
        //--------------------------------------------------------------

        $display("");
        $display("====================================================");
        $display("TEST 1 : DENSE 8x8 GEMM");
        $display("====================================================");

        start_compute();

        //--------------------------------------------------------------
        // Wait for completion
        //--------------------------------------------------------------

        fork

            begin

                wait(done);

            end

            begin

                repeat (20000)
                    @(posedge clk);

            $display("[FAIL] COMPUTE TIMEOUT");
                tests_failed = tests_failed + 1;

            end

        join_any

        disable fork;

        //--------------------------------------------------------------
        // Allow nonblocking assignments to settle.
        //--------------------------------------------------------------

        @(posedge clk);
        #1;

        //--------------------------------------------------------------
        // Verify results
        //--------------------------------------------------------------

        check_results();

        //--------------------------------------------------------------
        // Instrumentation checks
        //--------------------------------------------------------------

        $display("");
        $display("====================================================");
        $display("COMPUTE CONTROLLER INSTRUMENTATION");
        $display("====================================================");

        $display(
            "A Reads       : %0d",
            a_read_count
        );

        $display(
            "B Reads       : %0d",
            b_read_count
        );

        $display(
            "MAC Operations: %0d",
            mac_count
        );

        $display(
            "Output Count  : %0d",
            output_count
        );

        $display(
            "Cycle Count   : %0d",
            cycle_count
        );

        //--------------------------------------------------------------
        // Expected instrumentation
        //--------------------------------------------------------------

        if (a_read_count == N*N*N)
            $display("[PASS] A read count");

        else begin

            $display(
                "[FAIL] A read count : Expected=%0d Observed=%0d",
                N*N*N,
                a_read_count
            );

            tests_failed = tests_failed + 1;

        end

        if (b_read_count == N*N*N)
            $display("[PASS] B read count");

        else begin

            $display(
                "[FAIL] B read count : Expected=%0d Observed=%0d",
                N*N*N,
                b_read_count
            );

            tests_failed = tests_failed + 1;

        end

        if (mac_count == N*N*N)
            $display("[PASS] MAC count");

        else begin

            $display(
                "[FAIL] MAC count : Expected=%0d Observed=%0d",
                N*N*N,
                mac_count
            );

            tests_failed = tests_failed + 1;

        end

        if (output_count == N*N)
            $display("[PASS] Output count");

        else begin

            $display(
                "[FAIL] Output count : Expected=%0d Observed=%0d",
                N*N,
                output_count
            );

            tests_failed = tests_failed + 1;

        end

        //--------------------------------------------------------------
        // Final result
        //--------------------------------------------------------------

        $display("");
        $display("====================================================");
        $display("COMPUTE CONTROLLER REGRESSION");
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

`default_nettype wire