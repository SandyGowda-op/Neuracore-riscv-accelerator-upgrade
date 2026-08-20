//==============================================================================
// Module      : scratchpad_controller
// Project     : Descriptor-Driven RISC-V AI Accelerator
//
// Description :
//   DMA-side controller for the banked scratchpad.
//
//   Responsibilities:
//     - Accept 64-bit DMA write transactions
//     - Decode the destination scratchpad bank
//     - Convert byte address to scratchpad word address
//     - Split one 64-bit DMA beat into two 32-bit writes
//     - Generate a ready signal for the Transfer Engine
//
//   Current Phase Limitations:
//     - DMA write path only
//     - No compute arbitration
//     - No simultaneous DMA/compute access handling
//     - No FIFO
//     - No advanced backpressure policy
//==============================================================================

`timescale 1ns/1ps
`default_nettype none

module scratchpad_controller #(

    parameter int DMA_DATA_WIDTH  = 64,
    parameter int SPAD_DATA_WIDTH = 32,
    parameter int SPAD_ADDR_WIDTH = 6

)(

    input logic clk,
    input logic rst,

    //==========================================================
    // Transfer Engine Interface
    //==========================================================

    input  logic                      dma_write_enable,
    input  logic [3:0]                dma_bank,
    input  logic [31:0]               dma_address,
    input  logic [DMA_DATA_WIDTH-1:0] dma_write_data,

    output logic                      dma_ready,

    //==========================================================
    // Scratchpad Interface
    //==========================================================

    output logic [1:0]                spad_bank_sel,
    output logic                      spad_en,
    output logic                      spad_we,
    output logic [SPAD_ADDR_WIDTH-1:0] spad_addr,
    output logic [SPAD_DATA_WIDTH-1:0] spad_wdata

);

//==============================================================================
// Parameter Checking
//==============================================================================

initial begin

    if (DMA_DATA_WIDTH != 64)
        $fatal("scratchpad_controller: DMA_DATA_WIDTH must currently be 64");

    if (SPAD_DATA_WIDTH != 32)
        $fatal("scratchpad_controller: SPAD_DATA_WIDTH must currently be 32");

    if (DMA_DATA_WIDTH != (2 * SPAD_DATA_WIDTH))
        $fatal("scratchpad_controller: DMA/SPAD width relationship invalid");

end

//==============================================================================
// Internal State
//==============================================================================

typedef enum logic [1:0]
{
    IDLE,

    WRITE_LOW,

    WRITE_HIGH

} controller_state_t;

controller_state_t state;
controller_state_t next_state;

//==============================================================================
// Latched DMA Transaction
//==============================================================================

logic [3:0]                 dma_bank_reg;
logic [31:0]                dma_address_reg;
logic [DMA_DATA_WIDTH-1:0]  dma_write_data_reg;

//==============================================================================
// Address Conversion
//
// DMA address is a BYTE address.
//
// Scratchpad address is a 32-bit WORD address.
//
// Therefore:
//
//     word_address = byte_address / 4
//
// The lower two address bits are byte offsets and are discarded.
//
//==============================================================================

logic [SPAD_ADDR_WIDTH-1:0] base_spad_address;

assign base_spad_address =
    dma_address_reg[SPAD_ADDR_WIDTH+1:2];

//==============================================================================
// State Register
//==============================================================================

always_ff @(posedge clk) begin

    if (rst) begin

        state <= IDLE;

        dma_bank_reg      <= '0;
        dma_address_reg   <= '0;
        dma_write_data_reg <= '0;

    end

    else begin

        state <= next_state;

        //------------------------------------------------------
        // Accept new DMA transaction
        //------------------------------------------------------

        if (state == IDLE &&
            dma_write_enable &&
            dma_ready)
        begin

            dma_bank_reg       <= dma_bank;
            dma_address_reg   <= dma_address;
            dma_write_data_reg <= dma_write_data;

        end

    end

end

//==============================================================================
// Next-State Logic
//==============================================================================

always_comb begin

    next_state = state;

    case (state)

        //------------------------------------------------------
        // Waiting for DMA transaction
        //------------------------------------------------------

        IDLE:
        begin

            if (dma_write_enable &&
                dma_ready)
            begin

                next_state = WRITE_LOW;

            end

        end

        //------------------------------------------------------
        // Write lower 32 bits
        //------------------------------------------------------

        WRITE_LOW:
        begin

            `ifndef SYNTHESIS
$display(
    "[SPAD_WRITE] t=%0t bank=%0d addr=%0d data=%0d phase=LOW",
    $time,
    dma_bank_reg[1:0],
    base_spad_address,
    $signed(dma_write_data_reg[31:0])
);
`endif

            next_state = WRITE_HIGH;

        end

        //------------------------------------------------------
        // Write upper 32 bits
        //------------------------------------------------------

        WRITE_HIGH:
        begin

            `ifndef SYNTHESIS
$display(
    "[SPAD_WRITE] t=%0t bank=%0d addr=%0d data=%0d phase=HIGH",
    $time,
    dma_bank_reg[1:0],
    base_spad_address + 1'b1,
    $signed(dma_write_data_reg[63:32])
);
`endif

            next_state = IDLE;

        end

        //------------------------------------------------------
        // Safety
        //------------------------------------------------------

        default:
        begin

            next_state = IDLE;

        end

    endcase

end

//==============================================================================
// Output Logic
//==============================================================================

always_comb begin

    //----------------------------------------------------------
    // Defaults
    //----------------------------------------------------------

    dma_ready = 1'b0;

    spad_bank_sel = 2'b00;
    spad_en       = 1'b0;
    spad_we       = 1'b0;
    spad_addr     = '0;
    spad_wdata    = '0;

    case (state)

        //------------------------------------------------------
        // Controller can accept a new DMA transaction
        //------------------------------------------------------

        IDLE:
        begin

            dma_ready = 1'b1;

        end

        //------------------------------------------------------
        // Write lower 32 bits
        //------------------------------------------------------

        WRITE_LOW:
        begin

            spad_en       = 1'b1;
            spad_we       = 1'b1;

            spad_bank_sel =
                dma_bank_reg[1:0];

            spad_addr =
                base_spad_address;

            spad_wdata =
                dma_write_data_reg[31:0];

        end

        //------------------------------------------------------
        // Write upper 32 bits
        //------------------------------------------------------

        WRITE_HIGH:
        begin

            spad_en       = 1'b1;
            spad_we       = 1'b1;

            spad_bank_sel =
                dma_bank_reg[1:0];

            spad_addr =
                base_spad_address + 1'b1;

            spad_wdata =
                dma_write_data_reg[63:32];

        end

        //------------------------------------------------------
        // Safety
        //------------------------------------------------------

        default:
        begin

        end

    endcase

end

endmodule

`default_nettype wire