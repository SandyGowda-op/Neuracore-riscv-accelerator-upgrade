`timescale 1ns/1ps

module riscv_pipeline_tb;

    reg clk;
    reg rst;

    wire mmul_busy;
    wire mmul_done;

    wire [31:0] dbg_pc;
    wire [31:0] dbg_instr;
    wire [31:0] dbg_alu;
    wire [31:0] dbg_dmem_load;
    wire [31:0] dbg_r1;
    wire [31:0] dbg_r2;
    wire [31:0] dbg_r3;
    wire dbg_accel_busy;

    // DUT
    riscv_pipeline uut (
        .clk(clk),
        .rst(rst),
        .mmul_busy(mmul_busy),
        .mmul_done(mmul_done),
        .dbg_pc(dbg_pc),
        .dbg_instr(dbg_instr),
        .dbg_alu(dbg_alu),
        .dbg_dmem_load(dbg_dmem_load),
        .dbg_r1(dbg_r1),
        .dbg_r2(dbg_r2),
        .dbg_r3(dbg_r3),
        .dbg_accel_busy(dbg_accel_busy)
    );

    // Clock: 10ns period (100 MHz)
    always #5 clk = ~clk;

    integer cycle;

    initial begin
        clk = 0;
        rst = 1;
        cycle = 0;

        $display("\n================ PIPELINE DEMO START ================\n");

        // Reset phase
        #20;
        rst = 0;

        // Run simulation
        repeat (50) begin
            @(posedge clk);
            cycle = cycle + 1;

            $display("CYCLE=%0d | PC=%h | INSTR=%h | ALU=%h | R1=%h | R2=%h | BUSY=%b",
                cycle,
                dbg_pc,
                dbg_instr,
                dbg_alu,
                dbg_r1,
                dbg_r2,
                dbg_accel_busy
            );
        end

        $display("\n================ SIMULATION END =====================\n");
        $finish;
    end

    // Optional continuous monitor (helps waveform correlation)
    initial begin
        $monitor("T=%0t | PC=%h | INSTR=%h | ALU=%h",
                 $time, dbg_pc, dbg_instr, dbg_alu);
    end

endmodule