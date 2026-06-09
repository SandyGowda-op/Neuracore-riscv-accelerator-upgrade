`timescale 1ns/1ps
module mem_wb (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire [31:0] mem_data_in,
    input  wire [31:0] alu_result_in,
    input  wire [4:0]  rd_in,
    input  wire        mem_to_reg_in,
    input  wire        reg_write_in,
    output reg [31:0]  mem_data_out,
    output reg [31:0]  alu_result_out,
    output reg [4:0]   rd_out,
    output reg         mem_to_reg_out,
    output reg         reg_write_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_data_out <= 32'd0;
            alu_result_out <= 32'd0;
            rd_out <= 5'd0;
            mem_to_reg_out <= 1'b0;
            reg_write_out <= 1'b0;
        end else if (enable) begin
            mem_data_out <= mem_data_in;
            alu_result_out <= alu_result_in;
            rd_out <= rd_in;
            mem_to_reg_out <= mem_to_reg_in;
            reg_write_out <= reg_write_in;

            // DEBUG: print WB inputs each cycle when enable
            $display("mem_wb: time=%0t mem_data_in=%08h alu_result_in=%08h rd_in=%0d mem_to_reg=%0d reg_write=%0d",
                     $time, mem_data_in, alu_result_in, rd_in, mem_to_reg_in, reg_write_in);
        end
    end
endmodule