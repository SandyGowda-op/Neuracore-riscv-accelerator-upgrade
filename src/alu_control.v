`timescale 1ns/1ps
module alu_control (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg  [3:0] alu_ctrl
);
    always @(*) begin
        // simple mapping for demo (expand as needed)
        if (opcode == 7'b0110011) begin // R-type (based on funct3/funct7)
            if (funct3 == 3'b000 && funct7 == 7'b0000000) alu_ctrl = 4'b0000; // ADD
            else if (funct3 == 3'b000 && funct7 == 7'b0100000) alu_ctrl = 4'b0001; // SUB
            else alu_ctrl = 4'b0000;
        end else if (opcode == 7'b0010011) begin // ADDI
            alu_ctrl = 4'b0000;
        end else begin
            alu_ctrl = 4'b0000;
        end
    end
endmodule
