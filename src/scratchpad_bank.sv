//==============================================================================
// Module      : scratchpad_bank
// Project     : Descriptor-Driven RISC-V AI Accelerator
// Description :
//   Parameterizable true dual-port synchronous scratchpad memory bank.
//==============================================================================

`timescale 1ns/1ps
`default_nettype none

module scratchpad_bank #(

    parameter int DATA_WIDTH = 32,
    parameter int MATRIX_DIM = 8,
    parameter int DEPTH      = MATRIX_DIM * MATRIX_DIM,
    parameter int ADDR_WIDTH = $clog2(DEPTH)

)(
    input  logic clk,
    input  logic rst,

    //==========================
    // DMA Port
    //==========================
    input  logic                    dma_en,
    input  logic                    dma_we,
    input  logic [ADDR_WIDTH-1:0]   dma_addr,
    input  logic [DATA_WIDTH-1:0]   dma_wdata,
    output logic [DATA_WIDTH-1:0]   dma_rdata,

    //==========================
    // Compute Port
    //==========================
    input  logic                    compute_en,
    input  logic                    compute_we,
    input  logic [ADDR_WIDTH-1:0]   compute_addr,
    input  logic [DATA_WIDTH-1:0]   compute_wdata,
    output logic [DATA_WIDTH-1:0]   compute_rdata

);

    //==========================================================================
    // Parameter Checking
    //==========================================================================

    initial begin
        if (DATA_WIDTH <= 0)
            $fatal("scratchpad_bank: DATA_WIDTH must be > 0");

        if (MATRIX_DIM <= 0)
            $fatal("scratchpad_bank: MATRIX_DIM must be > 0");

        if (DEPTH <= 0)
            $fatal("scratchpad_bank: DEPTH must be > 0");
    end

    //==========================================================================
    // Memory Array
    //==========================================================================

    (* ram_style = "block" *)
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    //==========================================================================
    // Output Pipeline Registers
    //==========================================================================

    logic [DATA_WIDTH-1:0] dma_rdata_stage1;
    logic [DATA_WIDTH-1:0] dma_rdata_stage2;

    logic [DATA_WIDTH-1:0] compute_rdata_stage1;
    logic [DATA_WIDTH-1:0] compute_rdata_stage2;


    //==============================================================================
// DMA Port
//==============================================================================

always_ff @(posedge clk) begin

    if (rst) begin

        dma_rdata_stage1 <= '0;
        dma_rdata_stage2 <= '0;

    end
    else begin

        //--------------------------------------------------------------
        // Advance output pipeline
        //--------------------------------------------------------------

        dma_rdata_stage2 <= dma_rdata_stage1;

        //--------------------------------------------------------------
        // DMA Access
        //--------------------------------------------------------------

        if (dma_en) begin

            // READ_FIRST behavior
            dma_rdata_stage1 <= mem[dma_addr];

            if (dma_we)
                mem[dma_addr] <= dma_wdata;

        end

    end

end

//==============================================================================
// Compute Port
//==============================================================================

always_ff @(posedge clk) begin

    if (rst) begin

        compute_rdata_stage1 <= '0;
        compute_rdata_stage2 <= '0;

    end
    else begin

        //--------------------------------------------------------------
        // Advance output pipeline
        //--------------------------------------------------------------

        compute_rdata_stage2 <= compute_rdata_stage1;

        //--------------------------------------------------------------
        // Compute Access
        //--------------------------------------------------------------

        if (compute_en) begin

            // READ_FIRST behavior
            compute_rdata_stage1 <= mem[compute_addr];

            if (compute_we)
                mem[compute_addr] <= compute_wdata;

        end

    end

end

//==============================================================================
// Output Assignments
//==============================================================================

assign dma_rdata     = dma_rdata_stage2;
assign compute_rdata = compute_rdata_stage2;

endmodule

`default_nettype wire