`timescale 1ns/1ps

module scratchpad (

    input  wire        clk,

    // CPU Port
    input  wire        cpu_we,
    input  wire [9:0]  cpu_addr,
    input  wire [31:0] cpu_wdata,
    output wire [31:0] cpu_rdata,

    // MMUL Port
    input  wire        mmul_we,
    input  wire [9:0]  mmul_addr,
    input  wire [31:0] mmul_wdata,
    output wire [31:0] mmul_rdata

);

    reg [31:0] mem [0:1023];

    integer i;

    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 32'd0;
    end
    `ifndef SYNTHESIS
    always @(posedge clk) begin

        if (cpu_we) begin
            mem[cpu_addr] <= cpu_wdata;
            $display("CPU WRITE  addr=%0d data=%h",
                     cpu_addr,
                     cpu_wdata);
        end

        if (mmul_we) begin
            mem[mmul_addr] <= mmul_wdata;
            $display("MMUL WRITE addr=%0d data=%h",
                     mmul_addr,
                     mmul_wdata);
        end

    end
    `endif
    assign cpu_rdata  = mem[cpu_addr];
    assign mmul_rdata = mem[mmul_addr];

endmodule