/******************************************************************************
 *
 * Module      : transfer_engine
 *
 * Description :
 *      Generic DMA Transfer Engine
 *
 *      Current implementation transfers one dense tile in two phases:
 *
 *          Phase A : Main Memory A -> Scratchpad bank_a
 *          Phase B : Main Memory B -> Scratchpad bank_b
 *
 *      The external scheduler transaction remains one tile_request_t.
 *
 ******************************************************************************/

`timescale 1ns/1ps

import tile_pkg::*;

module transfer_engine
#(
    parameter integer BURST_BYTES = 128,
    parameter integer DATA_WIDTH  = 64
)
(
    //----------------------------------------------------------
    // Global
    //----------------------------------------------------------

    input  logic clk,
    input  logic rst,

    //----------------------------------------------------------
    // Scheduler Interface
    //----------------------------------------------------------

    input  tile_request_t tile_request,
    input  logic          tile_request_valid,
    output logic          tile_request_ready,

    //----------------------------------------------------------
    // Main Memory Request Interface
    //----------------------------------------------------------

    output logic        mem_req_valid,
    input  logic        mem_req_ready,

    output logic [31:0] mem_req_addr,
    output logic [31:0] mem_req_bytes,

    output logic mem_rready,

    //----------------------------------------------------------
    // Main Memory Read Data Interface
    //----------------------------------------------------------

    input logic        mem_rvalid,
    input logic [63:0] mem_rdata,
    input logic        mem_rlast,

    //----------------------------------------------------------
    // Scratchpad Interface
    //----------------------------------------------------------

    output logic        spad_write_enable,
    output logic [3:0]  spad_bank,
    output logic [31:0] spad_address,
    output logic [63:0] spad_write_data,

    input logic         spad_ready,

    //----------------------------------------------------------
    // Status
    //----------------------------------------------------------

    output logic transfer_busy,
    output logic transfer_done
);

    localparam integer BYTES_PER_BEAT = DATA_WIDTH / 8;

    //----------------------------------------------------------
    // Transfer Phase
    //----------------------------------------------------------

    typedef enum logic
    {
        TRANSFER_A,
        TRANSFER_B
    }
    transfer_phase_t;

    transfer_phase_t transfer_phase;

    //----------------------------------------------------------
    // Transfer Engine FSM
    //----------------------------------------------------------

    typedef enum logic [2:0]
    {
        IDLE,
        REQUEST_BURST,
        WAIT_REQUEST_ACCEPT,
        WAIT_DATA,
        COMPLETE
    }
    transfer_state_t;

    transfer_state_t state;
    transfer_state_t next_state;

    //----------------------------------------------------------
    // Latched Tile Request
    //----------------------------------------------------------

    tile_request_t current_request;

    //----------------------------------------------------------
    // DMA Working Registers
    //----------------------------------------------------------

    logic [31:0] current_address;
    logic [31:0] bytes_remaining;

    // Scratchpad DMA address is a BYTE address.
// scratchpad_controller converts byte address -> 32-bit word address.
    logic [31:0] current_spad_write_addr;

    logic [31:0] current_burst_bytes;

    //----------------------------------------------------------
    // Burst Generator
    //----------------------------------------------------------

    logic [31:0] burst_bytes;

    always_comb
    begin

        if (bytes_remaining >= BURST_BYTES)
            burst_bytes = BURST_BYTES;
        else
            burst_bytes = bytes_remaining;

    end

    //----------------------------------------------------------
    // FSM Sequential Logic
    //----------------------------------------------------------

    always_ff @(posedge clk)
    begin

        if (rst)
        begin

            state <= IDLE;

            current_request <= '0;

            transfer_phase <= TRANSFER_A;

            current_address <= '0;
            bytes_remaining <= '0;

            current_spad_write_addr <= '0;

            current_burst_bytes <= '0;
        end

        else
        begin

            //------------------------------------------------------
            // State register
            //------------------------------------------------------

            state <= next_state;

            //------------------------------------------------------
            // Latch incoming tile request
            //------------------------------------------------------

            if (state == IDLE &&
                tile_request_valid &&
                tile_request_ready)
            begin

                current_request <= tile_request;

                //--------------------------------------------------
                // Begin with Matrix A
                //--------------------------------------------------

                transfer_phase <= TRANSFER_A;

                current_address <=
                    tile_request.addr_a;

                bytes_remaining <=
                    tile_request.transfer_bytes;

                current_spad_write_addr <=
                    '0;

            end

            //------------------------------------------------------
            // Latch burst size
            //------------------------------------------------------

            if (state == REQUEST_BURST)
            begin

                current_burst_bytes <=
                    burst_bytes;

            end

            //------------------------------------------------------
            // Consume memory beat
            //------------------------------------------------------

            if (state == WAIT_DATA &&
                mem_rvalid &&
                mem_rready)
            begin

                //--------------------------------------------------
                // Write current memory beat
                //--------------------------------------------------

                if (mem_rlast)
                begin

                    current_spad_write_addr <=
                        current_spad_write_addr +
                        current_burst_bytes;

                    //--------------------------------------------------
                    // A transfer completed
                    //--------------------------------------------------

                    if (transfer_phase == TRANSFER_A &&
                        bytes_remaining == current_burst_bytes)
                    begin

                        //--------------------------------------------------
                        // Start B phase
                        //--------------------------------------------------

                        transfer_phase <=
                            TRANSFER_B;

                        current_address <=
                            current_request.addr_b;

                        bytes_remaining <=
                            current_request.transfer_bytes_b;

                        current_spad_write_addr <=
                            '0;

                    end

                    //--------------------------------------------------
                    // B transfer completed
                    //--------------------------------------------------

                    else
                    begin

                        current_address <=
                            current_address +
                            current_burst_bytes;

                        bytes_remaining <=
                            bytes_remaining -
                            current_burst_bytes;
                    end

                end

                //--------------------------------------------------
                // Intermediate beat
                //--------------------------------------------------

                else
                begin

                    current_spad_write_addr <=
                        current_spad_write_addr +
                        BYTES_PER_BEAT;

                end

            end

        end

    end

    //----------------------------------------------------------
    // Next State Logic
    //----------------------------------------------------------

    always_comb
    begin

        next_state = state;

        case (state)

            //------------------------------------------------------
            // Wait for scheduler
            //------------------------------------------------------

            IDLE:
            begin

                if (tile_request_valid &&
                    tile_request_ready)
                begin

                    //--------------------------------------------------
                    // Protect against an empty A transfer.
                    //--------------------------------------------------

                    if (tile_request.transfer_bytes == 0)
                    begin

                        if (tile_request.transfer_bytes_b == 0)
                            next_state = COMPLETE;
                        else
                            next_state = REQUEST_BURST;

                    end
                    else
                    begin
                        next_state = REQUEST_BURST;
                    end

                end

            end

            //------------------------------------------------------
            // Issue memory request
            //------------------------------------------------------

            REQUEST_BURST:
            begin

                if (bytes_remaining == 0)
                begin

                    //--------------------------------------------------
                    // No data remains.
                    //
                    // This can occur when transitioning from A to B
                    // for a zero-length B tile.
                    //--------------------------------------------------

                    if (transfer_phase == TRANSFER_A &&
                        current_request.transfer_bytes_b != 0)
                    begin

                        next_state = REQUEST_BURST;
                    end
                    else
                    begin
                        next_state = COMPLETE;
                    end

                end
                else if (mem_req_ready)
                begin

                    next_state = WAIT_DATA;
                end
                else
                begin

                    next_state = WAIT_REQUEST_ACCEPT;
                end

            end

            //------------------------------------------------------
            // Hold memory request until accepted
            //------------------------------------------------------

            WAIT_REQUEST_ACCEPT:
            begin

                if (mem_req_ready)
                begin
                    next_state = WAIT_DATA;
                end

            end

            //------------------------------------------------------
            // Receive memory data
            //------------------------------------------------------

            WAIT_DATA:
            begin

                if (mem_rvalid && mem_rready)
                begin

                    if (mem_rlast)
                    begin

                        //--------------------------------------------------
                        // Final burst of current phase
                        //--------------------------------------------------

                        if (bytes_remaining == current_burst_bytes)
                        begin

                            if (transfer_phase == TRANSFER_A)
                            begin

                                //--------------------------------------------------
                                // A complete -> B starts
                                //--------------------------------------------------

                                if (current_request.transfer_bytes_b != 0)
                                    next_state = REQUEST_BURST;
                                else
                                    next_state = COMPLETE;

                            end
                            else
                            begin

                                //--------------------------------------------------
                                // B complete -> tile complete
                                //--------------------------------------------------

                                next_state = COMPLETE;

                            end

                        end
                        else
                        begin

                            //--------------------------------------------------
                            // More bursts remain in current phase
                            //--------------------------------------------------

                            next_state = REQUEST_BURST;

                        end

                    end
                    else
                    begin

                        next_state = WAIT_DATA;
                    end

                end

            end

            //------------------------------------------------------
            // DMA completion pulse
            //------------------------------------------------------

            COMPLETE:
            begin
                next_state = IDLE;
            end

            //------------------------------------------------------
            // Recovery
            //------------------------------------------------------

            default:
            begin
                next_state = IDLE;
            end

        endcase

    end

    //----------------------------------------------------------
    // Output Logic
    //----------------------------------------------------------

    always_comb
    begin

        //------------------------------------------------------
        // Defaults
        //------------------------------------------------------

        tile_request_ready = 1'b0;

        mem_req_valid = 1'b0;
        mem_req_addr  = '0;
        mem_req_bytes = '0;

        mem_rready         = 1'b0;

        spad_write_enable = 1'b0;
        spad_bank         = '0;
        spad_address      = '0;
        spad_write_data   = '0;

        transfer_busy = 1'b0;
        transfer_done = 1'b0;

        //------------------------------------------------------
        // State-dependent outputs
        //------------------------------------------------------

        case (state)

            //--------------------------------------------------
            // Idle
            //--------------------------------------------------

            IDLE:
            begin

                tile_request_ready = 1'b1;

            end

            //--------------------------------------------------
            // Memory request
            //--------------------------------------------------

            REQUEST_BURST:
            begin

                transfer_busy = 1'b1;

                if (bytes_remaining != 0)
                begin

                    mem_req_valid = 1'b1;

                    mem_req_addr =
                        current_address;

                    mem_req_bytes =
                        burst_bytes;

                end

            end

            //--------------------------------------------------
            // Memory request stalled
            //--------------------------------------------------

            WAIT_REQUEST_ACCEPT:
            begin

                transfer_busy = 1'b1;

                mem_req_valid = 1'b1;

                mem_req_addr =
                    current_address;

                mem_req_bytes =
                    burst_bytes;

            end

            //--------------------------------------------------
            // Memory data
            //--------------------------------------------------

            WAIT_DATA:
            begin

                transfer_busy = 1'b1;

                mem_rready = 1'b1;

                //--------------------------------------------------
                // Preserve existing scratchpad handshake behavior.
                //
                // NOTE:
                // Scratchpad backpressure remains a known limitation
                // and is intentionally NOT redesigned here.
                //--------------------------------------------------

                if (mem_rvalid && mem_rready)
                begin

                    spad_write_enable = 1'b1;

                    spad_write_data =
                        mem_rdata;

                    spad_address =
                        current_spad_write_addr;

                    if (transfer_phase == TRANSFER_A)
                        spad_bank = current_request.bank_a;
                    else
                        spad_bank = current_request.bank_b;

                end

            end

            //--------------------------------------------------
            // Completion
            //--------------------------------------------------

            COMPLETE:
            begin

                transfer_done = 1'b1;

            end

            default:
            begin
            end

        endcase

    end

endmodule