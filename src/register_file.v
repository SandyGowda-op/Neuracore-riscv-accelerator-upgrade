`timescale 1ns/1ps
module register_file (
    input  wire        clk,
    input  wire        rst,
    input  wire        we_en,
    input  wire [4:0]  we_addr,
    input  wire [31:0] we_data,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,
    output wire [31:0] dbg_r1,
    output wire [31:0] dbg_r2,
    output wire [31:0] dbg_r3,
    output wire [31:0] dbg_r4,
    output wire [31:0] dbg_r5
);
    reg [31:0] regs [0:31];
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) regs[i] <= 32'd0;
        end else begin
            if (we_en && (we_addr != 5'd0)) begin
                regs[we_addr] <= we_data;
                // DEBUG: announce register writes
                $display("REGFILE WRITE: time=%0t we_en=%0d we_addr=%0d we_data=%08h", $time, we_en, we_addr, we_data);
            end
        end
    end
    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : regs[rs2_addr];
    assign dbg_r1 = regs[1];
    assign dbg_r2 = regs[2];
    assign dbg_r3 = regs[3];
    assign dbg_r4 = regs[4];
    assign dbg_r5 = regs[5];
endmodule