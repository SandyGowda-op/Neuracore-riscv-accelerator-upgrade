`timescale 1ns/1ps

module scratchpad_tb;

    reg clk;

    reg         cpu_we;
    reg  [9:0]  cpu_addr;
    reg  [31:0] cpu_wdata;
    wire [31:0] cpu_rdata;

    reg         mmul_we;
    reg  [9:0]  mmul_addr;
    reg  [31:0] mmul_wdata;
    wire [31:0] mmul_rdata;

    scratchpad dut (

        .clk(clk),

        .cpu_we(cpu_we),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),

        .mmul_we(mmul_we),
        .mmul_addr(mmul_addr),
        .mmul_wdata(mmul_wdata),
        .mmul_rdata(mmul_rdata)
    );

    // ============================================
    // CLOCK
    // ============================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ============================================
    // TEST
    // ============================================

    initial begin

        cpu_we     = 0;
        cpu_addr   = 0;
        cpu_wdata  = 0;

        mmul_we    = 0;
        mmul_addr  = 0;
        mmul_wdata = 0;

        #20;

        $display("");
        $display("=================================");
        $display(" SCRATCHPAD TEST START ");
        $display("=================================");
        $display("");

        // ============================================
        // TEST 1
        // ============================================

        cpu_addr  = 10'd5;
        cpu_wdata = 32'h12345678;
        cpu_we    = 1;

        @(posedge clk);
        #1;
        cpu_we = 0;

        #1;

        @(posedge clk);

        cpu_addr = 10'd5;

        @(posedge clk);

        if (cpu_rdata == 32'h12345678)
            $display("PASS: CPU WRITE/READ");
        else begin
            $display("FAIL: CPU WRITE/READ");
            $display("Expected = 12345678");
            $display("Observed = %h", cpu_rdata);
        end

        // ============================================
        // TEST 2
        // ============================================

        mmul_addr  = 10'd10;
        mmul_wdata = 32'hDEADBEEF;
        mmul_we    = 1;

        @(posedge clk);
        #1;
        mmul_we = 0;

        #1;

        @(posedge clk);

        mmul_addr = 10'd10;

        @(posedge clk);

        if (mmul_rdata == 32'hDEADBEEF)
            $display("PASS: MMUL WRITE/READ");
        else begin
            $display("FAIL: MMUL WRITE/READ");
            $display("Observed = %h", mmul_rdata);
        end

        // ============================================
        // TEST 3
        // ============================================

        cpu_addr  = 10'd20;
        cpu_wdata = 32'hAAAAAAAA;
        cpu_we    = 1;

        mmul_addr  = 10'd50;
        mmul_wdata = 32'hBBBBBBBB;
        mmul_we    = 1;

      @(posedge clk);

    #1;

    cpu_we  = 0;
    mmul_we = 0;

    $display("AFTER WRITE:");
    $display("mem[20] = %h", dut.mem[20]);
    $display("mem[50] = %h", dut.mem[50]);

        @(posedge clk);
        #1;

        cpu_addr  = 10'd20;
        mmul_addr = 10'd50;

        @(posedge clk);

        if ((cpu_rdata == 32'hAAAAAAAA) &&
            (mmul_rdata == 32'hBBBBBBBB))
            $display("PASS: SIMULTANEOUS WRITE");
        else begin
            $display("FAIL: SIMULTANEOUS WRITE");
            $display("CPU  = %h", cpu_rdata);
            $display("MMUL = %h", mmul_rdata);
        end

        // ============================================
        // TEST 4
        // ============================================

        cpu_addr = 10'd100;

        mmul_addr  = 10'd200;
        mmul_wdata = 32'hCAFEBABE;
        mmul_we    = 1;

        @(posedge clk);

        mmul_we = 0;
        #1;

        @(posedge clk);
        #1;
        mmul_addr = 10'd200;

        @(posedge clk);

        if (mmul_rdata == 32'hCAFEBABE)
            $display("PASS: READ/WRITE CONCURRENT");
        else begin
            $display("FAIL: READ/WRITE CONCURRENT");
            $display("Observed = %h", mmul_rdata);
        end

        // ============================================
        // TEST 5
        // ============================================

        cpu_addr  = 10'd1023;
        cpu_wdata = 32'hFACECAFE;
        cpu_we    = 1;

        @(posedge clk);

        cpu_we = 0;
        #1;

        @(posedge clk);
        #1;

        cpu_addr = 10'd1023;

        @(posedge clk);

        if (cpu_rdata == 32'hFACECAFE)
            $display("PASS: BOUNDARY ADDRESS");
        else begin
            $display("FAIL: BOUNDARY ADDRESS");
            $display("Observed = %h", cpu_rdata);
        end

        $display("");
        $display("=================================");
        $display(" SCRATCHPAD TEST COMPLETE ");
        $display("=================================");
        $display("");

        $finish;

    end

endmodule