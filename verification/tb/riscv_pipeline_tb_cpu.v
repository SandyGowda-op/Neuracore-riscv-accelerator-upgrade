`timescale 1ns / 1ps

module riscv_pipeline_tb_cpu;

    reg clk;
    reg rst;

    // DUT signals (adjust names ONLY if your top differs)
    wire mmul_busy;
    wire mmul_done;

    // Instantiate DUT
    riscv_pipeline dut (
        .clk(clk),
        .rst(rst),
        .mmul_busy(mmul_busy),
        .mmul_done(mmul_done)
    );

    // =============================
    // CLOCK GENERATION
    // =============================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 100 MHz
    end

    // =============================
    // RESET
    // =============================
    initial begin
        rst = 1;
        #40;
        rst = 0;
    end

    // =============================
    // MAIN SIMULATION CONTROL
    // =============================
    initial begin
        $display("===============================");
        $display(" RISC-V + MMUL SIMULATION START ");
        $display("===============================");

        // Wait until reset is released
        wait(rst == 0);

        // -----------------------------
        // WAIT FOR MMUL TO START
        // -----------------------------
        wait(mmul_busy == 1'b1);
        $display(">>> MMUL START detected at time %0t <<<", $time);

        // -----------------------------
        // WAIT FOR MMUL TO FINISH
        // -----------------------------
        wait(mmul_done == 1'b1);
        $display(">>> MMUL DONE detected at time %0t <<<", $time);

        // Small delay for final writes
        #50;

        $display("===============================");
        $display(" SIMULATION END (SUCCESS) ");
        $display("===============================");

        $finish;
    end

    // =============================
    // SAFETY TIMEOUT (ANTI-HANG)
    // =============================
    initial begin
        #8000000;
        $display("❌ ERROR: Simulation timeout - MMUL did not finish");
        $finish;
    end

endmodule