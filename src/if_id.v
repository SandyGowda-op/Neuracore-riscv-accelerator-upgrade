`timescale 1ns/1ps
module if_id (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire        flush,
    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] instr_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'd0;
            instr_out <= 32'd0;
        end else if (flush) begin
            pc_out <= 32'd0;
            instr_out <= 32'd0;
            $display("IFID: flush asserted - cleared at time %0t", $time);
        end else if (enable) begin
            pc_out <= pc_in;
            instr_out <= instr_in;
            $display("IFID: captured pc_in=%08h instr_in=%08h at time %0t", pc_in, instr_in, $time);
        end
        // else hold previous values (stall)
    end
endmodule
