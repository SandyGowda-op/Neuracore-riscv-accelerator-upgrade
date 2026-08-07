`timescale 1ns/1ps
`default_nettype none

module scratchpad_tb;

    localparam DATA_WIDTH = 32;
    localparam MATRIX_DIM = 8;
    localparam DEPTH      = 64;
    localparam ADDR_WIDTH = $clog2(DEPTH);

    logic clk;
    logic rst;

    // DMA Interface
    logic [1:0] dma_bank_sel;
    logic dma_en;
    logic dma_we;
    logic [ADDR_WIDTH-1:0] dma_addr;
    logic [DATA_WIDTH-1:0] dma_wdata;
    logic [DATA_WIDTH-1:0] dma_rdata;

    // Compute Interface
    logic [1:0] compute_bank_sel;
    logic compute_en;
    logic compute_we;
    logic [ADDR_WIDTH-1:0] compute_addr;
    logic [DATA_WIDTH-1:0] compute_wdata;
    logic [DATA_WIDTH-1:0] compute_rdata;
    logic [DATA_WIDTH-1:0] read_data;


scratchpad #(
    .DATA_WIDTH(DATA_WIDTH),
    .MATRIX_DIM(MATRIX_DIM),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) dut (
    .clk(clk),
    .rst(rst),

    .dma_bank_sel(dma_bank_sel),
    .dma_en(dma_en),
    .dma_we(dma_we),
    .dma_addr(dma_addr),
    .dma_wdata(dma_wdata),
    .dma_rdata(dma_rdata),

    .compute_bank_sel(compute_bank_sel),
    .compute_en(compute_en),
    .compute_we(compute_we),
    .compute_addr(compute_addr),
    .compute_wdata(compute_wdata),
    .compute_rdata(compute_rdata)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

initial begin
    rst = 1'b0;

    dma_bank_sel = 2'b00;
    dma_en       = 1'b0;
    dma_we       = 1'b0;
    dma_addr     = '0;
    dma_wdata    = '0;

    compute_bank_sel = 2'b00;
    compute_en       = 1'b0;
    compute_we       = 1'b0;
    compute_addr     = '0;
    compute_wdata    = '0;
end

//==============================================================================
// Clock Generation
//==============================================================================

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end


//==============================================================================
// Reset Task
//==============================================================================

task automatic reset_dut;

begin

    rst = 1'b1;

    repeat (5) @(posedge clk);

    rst = 1'b0;

    repeat (2) @(posedge clk);

end

endtask


//==============================================================================
// DMA Write Transaction
//==============================================================================

task automatic dma_write(

    input logic [1:0] bank,
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] data

);

begin

    @(posedge clk);

    dma_bank_sel <= bank;
    dma_addr     <= addr;
    dma_wdata    <= data;

    dma_we <= 1'b1;
    dma_en <= 1'b1;

    @(posedge clk);

    dma_en <= 1'b0;
    dma_we <= 1'b0;

end

endtask

//==============================================================================
// DMA Read Transaction
//==============================================================================

task automatic dma_read(

    input  logic [1:0] bank,
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data

);

begin

    @(posedge clk);

    dma_bank_sel <= bank;
    dma_addr     <= addr;

    dma_we <= 1'b0;
    dma_en <= 1'b1;

    @(posedge clk);

    dma_en <= 1'b0;

    // scratchpad_bank has a 2-cycle read latency
    repeat (2)
        @(posedge clk);

    data = dma_rdata;

end

endtask

task automatic compute_write(

    input logic [1:0] bank,
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] data

);

begin

    @(posedge clk);

    compute_bank_sel <= bank;
    compute_addr     <= addr;
    compute_wdata    <= data;

    compute_we <= 1'b1;
    compute_en <= 1'b1;

    @(posedge clk);

    compute_en <= 1'b0;
    compute_we <= 1'b0;

end

endtask

task automatic compute_read(

    input  logic [1:0] bank,
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data

);

begin

    @(posedge clk);

    compute_bank_sel <= bank;
    compute_addr     <= addr;

    compute_we <= 1'b0;
    compute_en <= 1'b1;

    @(posedge clk);

    compute_en <= 1'b0;

    repeat (2)
        @(posedge clk);

    data = compute_rdata;

end

endtask

//==============================================================================
// PASS Message
//==============================================================================

task automatic test_pass(

    input string test_name

);

begin

    $display("[PASS] %s", test_name);

end

endtask


//==============================================================================
// FAIL Message
//==============================================================================

task automatic test_fail(

    input string test_name,
    input logic [DATA_WIDTH-1:0] expected,
    input logic [DATA_WIDTH-1:0] received

);

begin

    $display("[FAIL] %s", test_name);
    $display(" Expected : %h", expected);
    $display(" Received : %h", received);

    $fatal;

end

endtask

//==============================================================================
// T1 : DMA Write/Read - Bank A
//==============================================================================

task automatic run_test_t1;

    logic [DATA_WIDTH-1:0] expected;

begin

    $display("\n----------------------------------------");
    $display("Running T1 : DMA Write/Read - Bank A");
    $display("----------------------------------------");

    expected = 32'h12345678;

    dma_write(
        2'b00,
        6'd5,
        expected
    );

    dma_read(
        2'b00,
        6'd5,
        read_data
    );

    if (read_data == expected)

        test_pass("T1 : DMA Write/Read Bank A");

    else

        test_fail(
            "T1 : DMA Write/Read Bank A",
            expected,
            read_data
        );

end

endtask

//==============================================================================
// T2 : DMA Write/Read - Bank B
//==============================================================================

task automatic run_test_t2;

    logic [DATA_WIDTH-1:0] expected;

begin

    $display("\n----------------------------------------");
    $display("Running T2 : DMA Write/Read - Bank B");
    $display("----------------------------------------");

    expected = 32'hCAFEBABE;

    dma_write(
        2'b01,
        6'd12,
        expected
    );

    dma_read(
        2'b01,
        6'd12,
        read_data
    );

    if (read_data == expected)

        test_pass("T2 : DMA Write/Read Bank B");

    else

        test_fail(
            "T2 : DMA Write/Read Bank B",
            expected,
            read_data
        );

end

endtask

//==============================================================================
// T3 : DMA Write/Read - Bank C
//==============================================================================

task automatic run_test_t3;

    logic [DATA_WIDTH-1:0] expected;

begin

    $display("\n----------------------------------------");
    $display("Running T3 : DMA Write/Read - Bank C");
    $display("----------------------------------------");

    expected = 32'hDEADBEEF;

    dma_write(
        2'b10,
        6'd25,
        expected
    );

    dma_read(
        2'b10,
        6'd25,
        read_data
    );

    if (read_data == expected)

        test_pass("T3 : DMA Write/Read Bank C");

    else

        test_fail(
            "T3 : DMA Write/Read Bank C",
            expected,
            read_data
        );

end

endtask

//==============================================================================
// T4 : Compute Write/Read - Bank A
//==============================================================================

task automatic run_test_t4;

    logic [DATA_WIDTH-1:0] expected;

begin

    $display("\n----------------------------------------");
    $display("Running T4 : Compute Write/Read - Bank A");
    $display("----------------------------------------");

    expected = 32'hABCDEF12;

    compute_write(
        2'b00,
        6'd8,
        expected
    );

    compute_read(
        2'b00,
        6'd8,
        read_data
    );

    if (read_data == expected)

        test_pass("T4 : Compute Write/Read Bank A");

    else

        test_fail(
            "T4 : Compute Write/Read Bank A",
            expected,
            read_data
        );

end

endtask

//==============================================================================
// T5 : Compute Write/Read - Bank B
//==============================================================================

task automatic run_test_t5;

    logic [DATA_WIDTH-1:0] expected;

begin

    $display("\n----------------------------------------");
    $display("Running T5 : Compute Write/Read - Bank B");
    $display("----------------------------------------");

    expected = 32'h87654321;

    compute_write(
        2'b01,
        6'd15,
        expected
    );

    compute_read(
        2'b01,
        6'd15,
        read_data
    );

    if (read_data == expected)

        test_pass("T5 : Compute Write/Read Bank B");

    else

        test_fail(
            "T5 : Compute Write/Read Bank B",
            expected,
            read_data
        );

end

endtask

//==============================================================================
// T6 : Compute Write/Read - Bank C
//==============================================================================

task automatic run_test_t6;

    logic [DATA_WIDTH-1:0] expected;

begin

    $display("\n----------------------------------------");
    $display("Running T6 : Compute Write/Read - Bank C");
    $display("----------------------------------------");

    expected = 32'h13579BDF;

    compute_write(
        2'b10,
        6'd31,
        expected
    );

    compute_read(
        2'b10,
        6'd31,
        read_data
    );

    if (read_data == expected)

        test_pass("T6 : Compute Write/Read Bank C");

    else

        test_fail(
            "T6 : Compute Write/Read Bank C",
            expected,
            read_data
        );

end

endtask

//==============================================================================
// T7 : Bank Isolation
//==============================================================================

task automatic run_test_t7;

begin

    logic [DATA_WIDTH-1:0] expected;

    $display("\n----------------------------------------");
    $display("Running T7 : Bank Isolation");
    $display("----------------------------------------");

    //--------------------------------------------------
    // Write three different values
    //--------------------------------------------------

    dma_write(2'b00, 6'd10, 32'hAAAAAAAA);

    dma_write(2'b01, 6'd10, 32'hBBBBBBBB);

    dma_write(2'b10, 6'd10, 32'hCCCCCCCC);

    //--------------------------------------------------
    // Read Bank A
    //--------------------------------------------------

    expected = 32'hAAAAAAAA;

    dma_read(2'b00, 6'd10, read_data);

    if (read_data != expected)

        test_fail("T7 : Bank A Isolation",
                  expected,
                  read_data);

    //--------------------------------------------------
    // Read Bank B
    //--------------------------------------------------

    expected = 32'hBBBBBBBB;

    dma_read(2'b01, 6'd10, read_data);

    if (read_data != expected)

        test_fail("T7 : Bank B Isolation",
                  expected,
                  read_data);

    //--------------------------------------------------
    // Read Bank C
    //--------------------------------------------------

    expected = 32'hCCCCCCCC;

    dma_read(2'b10, 6'd10, read_data);

    if (read_data != expected)

        test_fail("T7 : Bank C Isolation",
                  expected,
                  read_data);

    test_pass("T7 : Bank Isolation");

end

endtask

//==============================================================================
// T8 : Cross-Port Verification
//==============================================================================

task automatic run_test_t8;

    logic [DATA_WIDTH-1:0] expected;

begin

    $display("\n----------------------------------------");
    $display("Running T8 : DMA Write -> Compute Read");
    $display("----------------------------------------");

    expected = 32'hFACECAFE;

    //--------------------------------------------------
    // DMA writes
    //--------------------------------------------------

    dma_write(
        2'b00,
        6'd20,
        expected
    );

    //--------------------------------------------------
    // Compute reads same location
    //--------------------------------------------------

    compute_read(
        2'b00,
        6'd20,
        read_data
    );

    if (read_data == expected)

        test_pass("T8 : DMA -> Compute");

    else

        test_fail(
            "T8 : DMA -> Compute",
            expected,
            read_data
        );

end

endtask

//==============================================================================
// T8B : Compute Write -> DMA Read
//==============================================================================

task automatic run_test_t8b;

    logic [DATA_WIDTH-1:0] expected;

begin

    $display("\n----------------------------------------");
    $display("Running T8B : Compute Write -> DMA Read");
    $display("----------------------------------------");

    expected = 32'h0BADF00D;

    //--------------------------------------------------
    // Compute writes
    //--------------------------------------------------

    compute_write(
        2'b01,
        6'd18,
        expected
    );

    //--------------------------------------------------
    // DMA reads
    //--------------------------------------------------

    dma_read(
        2'b01,
        6'd18,
        read_data
    );

    if (read_data == expected)

        test_pass("T8B : Compute -> DMA");

    else

        test_fail(
            "T8B : Compute -> DMA",
            expected,
            read_data
        );

end

endtask

//==============================================================================
// T9 : Simultaneous Dual-Port Access
//==============================================================================

task automatic run_test_t9;

begin

    logic [DATA_WIDTH-1:0] expected_dma;
    logic [DATA_WIDTH-1:0] expected_compute;

    $display("\n----------------------------------------");
    $display("Running T9 : Simultaneous Dual-Port Access");
    $display("----------------------------------------");

    expected_dma     = 32'hAAAABBBB;
    expected_compute = 32'hCCCC1111;

    //--------------------------------------------------
    // Simultaneous writes
    //--------------------------------------------------

    dma_bank_sel      <= 2'b00;
    dma_addr          <= 6'd5;
    dma_wdata         <= expected_dma;
    dma_we            <= 1'b1;
    dma_en            <= 1'b1;

    compute_bank_sel  <= 2'b01;
    compute_addr      <= 6'd15;
    compute_wdata     <= expected_compute;
    compute_we        <= 1'b1;
    compute_en        <= 1'b1;

    @(posedge clk);

    dma_we       <= 1'b0;
    dma_en       <= 1'b0;

    compute_we   <= 1'b0;
    compute_en   <= 1'b0;

    //--------------------------------------------------
    // Verify DMA write
    //--------------------------------------------------

    dma_read(
        2'b00,
        6'd5,
        read_data
    );

    if (read_data != expected_dma)

        test_fail(
            "T9 : DMA Concurrent Write",
            expected_dma,
            read_data
        );

    //--------------------------------------------------
    // Verify Compute write
    //--------------------------------------------------

    compute_read(
        2'b01,
        6'd15,
        read_data
    );

    if (read_data != expected_compute)

        test_fail(
            "T9 : Compute Concurrent Write",
            expected_compute,
            read_data
        );

    test_pass("T9 : Simultaneous Dual-Port Access");

end

endtask

//==============================================================================
// T10 : Address Boundary Test
//==============================================================================

task automatic run_test_t10;

    logic [DATA_WIDTH-1:0] expected;

begin

    $display("\n----------------------------------------");
    $display("Running T10 : Address Boundary Test");
    $display("----------------------------------------");

    //--------------------------------------------------
    // Lowest Address
    //--------------------------------------------------

    expected = 32'h11111111;

    dma_write(
        2'b00,
        6'd0,
        expected
    );

    dma_read(
        2'b00,
        6'd0,
        read_data
    );

    if (read_data != expected)

        test_fail(
            "T10 : Address 0",
            expected,
            read_data
        );

    //--------------------------------------------------
    // Highest Address
    //--------------------------------------------------

    expected = 32'hFFFFFFFF;

    dma_write(
        2'b00,
        6'd63,
        expected
    );

    dma_read(
        2'b00,
        6'd63,
        read_data
    );

    if (read_data != expected)

        test_fail(
            "T10 : Address 63",
            expected,
            read_data
        );

    test_pass("T10 : Address Boundary");

end

endtask

//==============================================================================
// T11 : Interface Disable Test
//==============================================================================

task automatic run_test_t11;

    logic [DATA_WIDTH-1:0] expected;

begin

    $display("\n----------------------------------------");
    $display("Running T11 : Interface Disable Test");
    $display("----------------------------------------");

    //--------------------------------------------------
    // Write initial value
    //--------------------------------------------------

    expected = 32'h12345678;

    dma_write(
        2'b00,
        6'd10,
        expected
    );

    //--------------------------------------------------
    // Attempt write while disabled
    //--------------------------------------------------

    dma_bank_sel <= 2'b00;
    dma_addr     <= 6'd10;
    dma_wdata    <= 32'hDEADBEEF;

    dma_we       <= 1'b1;
    dma_en       <= 1'b0;

    @(posedge clk);

    dma_we <= 1'b0;

    //--------------------------------------------------
    // Read back
    //--------------------------------------------------

    dma_read(
        2'b00,
        6'd10,
        read_data
    );

    if (read_data != expected)

        test_fail(
            "T11 : Interface Disable",
            expected,
            read_data
        );

    test_pass("T11 : Interface Disable");

end

endtask

//==============================================================================
// T12 : Invalid Bank Select Test
//==============================================================================

task automatic run_test_t12;

begin

    logic [DATA_WIDTH-1:0] exp_a;
    logic [DATA_WIDTH-1:0] exp_b;
    logic [DATA_WIDTH-1:0] exp_c;

    $display("\n----------------------------------------");
    $display("Running T12 : Invalid Bank Select");
    $display("----------------------------------------");

    exp_a = 32'hAAAAAAAA;
    exp_b = 32'hBBBBBBBB;
    exp_c = 32'hCCCCCCCC;

    //--------------------------------------------------
    // Initialize all banks
    //--------------------------------------------------

    dma_write(2'b00, 6'd7, exp_a);
    dma_write(2'b01, 6'd7, exp_b);
    dma_write(2'b10, 6'd7, exp_c);

    //--------------------------------------------------
    // Invalid bank write
    //--------------------------------------------------

    dma_bank_sel <= 2'b11;
    dma_addr     <= 6'd7;
    dma_wdata    <= 32'hDEADBEEF;
    dma_we       <= 1'b1;
    dma_en       <= 1'b1;

    @(posedge clk);

    dma_we <= 1'b0;
    dma_en <= 1'b0;

    //--------------------------------------------------
    // Verify Bank A
    //--------------------------------------------------

    dma_read(2'b00, 6'd7, read_data);

    if (read_data != exp_a)
        test_fail("T12 : Bank A", exp_a, read_data);

    //--------------------------------------------------
    // Verify Bank B
    //--------------------------------------------------

    dma_read(2'b01, 6'd7, read_data);

    if (read_data != exp_b)
        test_fail("T12 : Bank B", exp_b, read_data);

    //--------------------------------------------------
    // Verify Bank C
    //--------------------------------------------------

    dma_read(2'b10, 6'd7, read_data);

    if (read_data != exp_c)
        test_fail("T12 : Bank C", exp_c, read_data);

    test_pass("T12 : Invalid Bank Select");

end

endtask

//==============================================================================
// T13 : Back-to-Back Transactions
//==============================================================================

task automatic run_test_t13;

begin

    logic [DATA_WIDTH-1:0] expected [0:3];

    $display("\n----------------------------------------");
    $display("Running T13 : Back-to-Back Transactions");
    $display("----------------------------------------");

    expected[0] = 32'h11111111;
    expected[1] = 32'h22222222;
    expected[2] = 32'h33333333;
    expected[3] = 32'h44444444;

    //--------------------------------------------------
    // Four consecutive writes
    //--------------------------------------------------

    dma_write(2'b00, 6'd0, expected[0]);
    dma_write(2'b00, 6'd1, expected[1]);
    dma_write(2'b00, 6'd2, expected[2]);
    dma_write(2'b00, 6'd3, expected[3]);

    //--------------------------------------------------
    // Verify them
    //--------------------------------------------------

    dma_read(2'b00, 6'd0, read_data);
    if(read_data != expected[0])
        test_fail("T13 Addr0", expected[0], read_data);

    dma_read(2'b00, 6'd1, read_data);
    if(read_data != expected[1])
        test_fail("T13 Addr1", expected[1], read_data);

    dma_read(2'b00, 6'd2, read_data);
    if(read_data != expected[2])
        test_fail("T13 Addr2", expected[2], read_data);

    dma_read(2'b00, 6'd3, read_data);
    if(read_data != expected[3])
        test_fail("T13 Addr3", expected[3], read_data);

    test_pass("T13 : Back-to-Back Transactions");

end

endtask

//==============================================================================
// T14 : Read-After-Write Timing
//==============================================================================

task automatic run_test_t14;

    logic [DATA_WIDTH-1:0] expected;

begin

    $display("\n----------------------------------------");
    $display("Running T14 : Read-After-Write Timing");
    $display("----------------------------------------");

    //--------------------------------------------------
    // First write/read
    //--------------------------------------------------

    expected = 32'hABCDEF01;

    dma_write(
        2'b00,
        6'd30,
        expected
    );

    dma_read(
        2'b00,
        6'd30,
        read_data
    );

    if (read_data != expected)

        test_fail(
            "T14 : First Read",
            expected,
            read_data
        );

    //--------------------------------------------------
    // Overwrite same address
    //--------------------------------------------------

    expected = 32'h1234FEDC;

    dma_write(
        2'b00,
        6'd30,
        expected
    );

    dma_read(
        2'b00,
        6'd30,
        read_data
    );

    if (read_data != expected)

        test_fail(
            "T14 : Overwrite Read",
            expected,
            read_data
        );

    test_pass("T14 : Read-After-Write Timing");

end

endtask

initial begin

    $display("\n========================================");
    $display(" Scratchpad Verification Started");
    $display("========================================\n");

    reset_dut();

    run_test_t1();
    run_test_t2();
    run_test_t3();
    run_test_t4();
    run_test_t5();
    run_test_t6();
    run_test_t7();
    run_test_t8();
    run_test_t8b();
    run_test_t9();
    run_test_t10();
    run_test_t11();
    run_test_t12();
    run_test_t13();
    run_test_t14();

    $display("\nAll Executed Tests PASSED.\n");

    #20;

    $finish;

end


//==============================================================================
// Waveform Dump
//==============================================================================

initial begin

    $dumpfile("scratchpad_tb.vcd");
    $dumpvars(0, scratchpad_tb);

end


endmodule

`default_nettype wire