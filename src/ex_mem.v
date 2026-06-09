`timescale 1ns/1ps
module ex_mem (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] alu_in,
    input  wire [31:0] rs2_data_in,
    input  wire [4:0]  rd_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
    input  wire        reg_write_in,
    output reg [31:0] alu_out,
    output reg [31:0] rs2_data_out,
    output reg [4:0]  rd_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        mem_to_reg_out,
    output reg        reg_write_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_out <= 32'd0;
            rs2_data_out <= 32'd0;
            rd_out <= 5'd0;
            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
            reg_write_out <= 1'b0;
        end else begin
            alu_out <= alu_in;
            rs2_data_out <= rs2_data_in;
            rd_out <= rd_in;
            mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            reg_write_out <= reg_write_in;
        end
    end
endmodule
