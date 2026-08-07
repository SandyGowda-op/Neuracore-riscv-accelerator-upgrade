//==============================================================================
// Module      : scratchpad
// Project     : Descriptor-Driven RISC-V AI Accelerator
// Description :
//   Top-level scratchpad memory subsystem.
//   Instantiates three scratchpad memory banks and routes DMA and Compute
//   accesses based on bank select signals.
//==============================================================================

`timescale 1ns/1ps
`default_nettype none

module scratchpad #(

    parameter int DATA_WIDTH = 32,
    parameter int MATRIX_DIM = 8,
    parameter int DEPTH      = MATRIX_DIM * MATRIX_DIM,
    parameter int ADDR_WIDTH = $clog2(DEPTH)

)(
        input logic clk,
    input logic rst,

    //==============================================================
    // DMA Interface
    //==============================================================

    input  logic [1:0]              dma_bank_sel,
    input  logic                    dma_en,
    input  logic                    dma_we,
    input  logic [ADDR_WIDTH-1:0]   dma_addr,
    input  logic [DATA_WIDTH-1:0]   dma_wdata,
    output logic [DATA_WIDTH-1:0]   dma_rdata,

    //==============================================================
    // Compute Interface
    //==============================================================

    input  logic [1:0]              compute_bank_sel,
    input  logic                    compute_en,
    input  logic                    compute_we,
    input  logic [ADDR_WIDTH-1:0]   compute_addr,
    input  logic [DATA_WIDTH-1:0]   compute_wdata,
    output logic [DATA_WIDTH-1:0]   compute_rdata

);

//==============================================================================
// Internal Signals
//==============================================================================

//--------------------------------------------------------------
// DMA Read Data
//--------------------------------------------------------------

logic [DATA_WIDTH-1:0] dma_rdata_bank_a;
logic [DATA_WIDTH-1:0] dma_rdata_bank_b;
logic [DATA_WIDTH-1:0] dma_rdata_bank_c;

//--------------------------------------------------------------
// Compute Read Data
//--------------------------------------------------------------

logic [DATA_WIDTH-1:0] compute_rdata_bank_a;
logic [DATA_WIDTH-1:0] compute_rdata_bank_b;
logic [DATA_WIDTH-1:0] compute_rdata_bank_c;

//--------------------------------------------------------------
// DMA Enables
//--------------------------------------------------------------

logic dma_en_bank_a;
logic dma_en_bank_b;
logic dma_en_bank_c;

//--------------------------------------------------------------
// Compute Enables
//--------------------------------------------------------------

logic compute_en_bank_a;
logic compute_en_bank_b;
logic compute_en_bank_c;

//==============================================================================
// Bank Select Decode
//==============================================================================

always_comb begin

    //----------------------------------------------------------
    // Default
    //----------------------------------------------------------

    dma_en_bank_a = 1'b0;
    dma_en_bank_b = 1'b0;
    dma_en_bank_c = 1'b0;

    compute_en_bank_a = 1'b0;
    compute_en_bank_b = 1'b0;
    compute_en_bank_c = 1'b0;

    //----------------------------------------------------------
    // DMA Decode
    //----------------------------------------------------------

    if (dma_en) begin
        case (dma_bank_sel)

            2'b00: dma_en_bank_a = 1'b1;
            2'b01: dma_en_bank_b = 1'b1;
            2'b10: dma_en_bank_c = 1'b1;

            default: ;

        endcase
    end

    //----------------------------------------------------------
    // Compute Decode
    //----------------------------------------------------------

    if (compute_en) begin
        case (compute_bank_sel)

            2'b00: compute_en_bank_a = 1'b1;
            2'b01: compute_en_bank_b = 1'b1;
            2'b10: compute_en_bank_c = 1'b1;

            default: ;

        endcase
    end

end

//==============================================================================
// Scratchpad Bank A
//==============================================================================

scratchpad_bank #(
    .DATA_WIDTH (DATA_WIDTH),
    .MATRIX_DIM (MATRIX_DIM),
    .DEPTH      (DEPTH),
    .ADDR_WIDTH (ADDR_WIDTH)
) bank_a (

    .clk            (clk),
    .rst            (rst),

    // DMA Port
    .dma_en         (dma_en_bank_a),
    .dma_we         (dma_we),
    .dma_addr       (dma_addr),
    .dma_wdata      (dma_wdata),
    .dma_rdata      (dma_rdata_bank_a),

    // Compute Port
    .compute_en     (compute_en_bank_a),
    .compute_we     (compute_we),
    .compute_addr   (compute_addr),
    .compute_wdata  (compute_wdata),
    .compute_rdata  (compute_rdata_bank_a)

);

//==============================================================================
// Scratchpad Bank B
//==============================================================================

scratchpad_bank #(
    .DATA_WIDTH (DATA_WIDTH),
    .MATRIX_DIM (MATRIX_DIM),
    .DEPTH      (DEPTH),
    .ADDR_WIDTH (ADDR_WIDTH)
) bank_b (

    .clk            (clk),
    .rst            (rst),

    // DMA Port
    .dma_en         (dma_en_bank_b),
    .dma_we         (dma_we),
    .dma_addr       (dma_addr),
    .dma_wdata      (dma_wdata),
    .dma_rdata      (dma_rdata_bank_b),

    // Compute Port
    .compute_en     (compute_en_bank_b),
    .compute_we     (compute_we),
    .compute_addr   (compute_addr),
    .compute_wdata  (compute_wdata),
    .compute_rdata  (compute_rdata_bank_b)

);

//==============================================================================
// Scratchpad Bank C
//==============================================================================

scratchpad_bank #(
    .DATA_WIDTH (DATA_WIDTH),
    .MATRIX_DIM (MATRIX_DIM),
    .DEPTH      (DEPTH),
    .ADDR_WIDTH (ADDR_WIDTH)
) bank_c (

    .clk            (clk),
    .rst            (rst),

    // DMA Port
    .dma_en         (dma_en_bank_c),
    .dma_we         (dma_we),
    .dma_addr       (dma_addr),
    .dma_wdata      (dma_wdata),
    .dma_rdata      (dma_rdata_bank_c),

    // Compute Port
    .compute_en     (compute_en_bank_c),
    .compute_we     (compute_we),
    .compute_addr   (compute_addr),
    .compute_wdata  (compute_wdata),
    .compute_rdata  (compute_rdata_bank_c)

);

//==============================================================================
// DMA Read Data Multiplexer
//==============================================================================

always_comb begin

    case (dma_bank_sel)

        2'b00:  dma_rdata = dma_rdata_bank_a;
        2'b01:  dma_rdata = dma_rdata_bank_b;
        2'b10:  dma_rdata = dma_rdata_bank_c;

        default: dma_rdata = '0;

    endcase

end

//==============================================================================
// Compute Read Data Multiplexer
//==============================================================================

always_comb begin

    case (compute_bank_sel)

        2'b00:  compute_rdata = compute_rdata_bank_a;
        2'b01:  compute_rdata = compute_rdata_bank_b;
        2'b10:  compute_rdata = compute_rdata_bank_c;

        default: compute_rdata = '0;

    endcase

end

endmodule

`default_nettype wire