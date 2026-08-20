//==============================================================================
// Module      : mac_unit
// Project     : Descriptor-Driven RISC-V AI Accelerator
//
// Description :
//   Parameterizable multiply-accumulate datapath.
//
//   Performs:
//
//       accumulator = accumulator + (operand_a * operand_b)
//
//   This module is intentionally mode-independent.
//   Both dense and sparse execution will use the same MAC primitive.
//
// Responsibilities:
//   - Multiply two signed operands
//   - Accumulate the product
//   - Clear accumulator at the beginning of a new dot product
//   - Provide accumulated result
//
// Current Phase Limitations:
//   - Single MAC operation per cycle
//   - No pipelined multiplier
//   - No saturation/rounding
//   - No zero-skipping logic
//   - No sparse metadata awareness
//==============================================================================

`timescale 1ns/1ps
`default_nettype none

module mac_unit #(

    parameter int OPERAND_WIDTH = 32,
    parameter int ACC_WIDTH     = 64

)(

    input logic clk,
    input logic rst,

    //==========================================================
    // Control
    //==========================================================

    input logic enable,
    input logic clear_acc,

    //==========================================================
    // Operands
    //==========================================================

    input logic signed [OPERAND_WIDTH-1:0] operand_a,
    input logic signed [OPERAND_WIDTH-1:0] operand_b,

    //==========================================================
    // Accumulator Output
    //==========================================================

    output logic signed [ACC_WIDTH-1:0] accumulator

);

    //==========================================================
    // Product
    //==========================================================

    logic signed [(2*OPERAND_WIDTH)-1:0] product;

    assign product =
        operand_a * operand_b;

    //==========================================================
    // Accumulator
    //==========================================================

    always_ff @(posedge clk) begin

        if (rst) begin

            accumulator <= '0;

        end

        else if (clear_acc) begin

            accumulator <= '0;

        end

        else if (enable) begin

            accumulator <=
                accumulator + product;

        end

    end

endmodule

`default_nettype wire