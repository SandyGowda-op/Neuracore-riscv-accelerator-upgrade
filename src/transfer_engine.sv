/******************************************************************************
 *
 * Module      : transfer_engine
 *
 * Description :
 *      Generic DMA Transfer Engine
 *
 * Responsibilities:
 *      - Accept tile requests from the scheduler
 *      - Generate burst requests to main memory
 *      - Receive burst data
 *      - Write received data into the scratchpad
 *      - Report DMA completion
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
// Burst Generator
//----------------------------------------------------------

logic [31:0] burst_bytes;

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

} transfer_state_t;

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

logic [31:0] current_spad_address;

logic [15:0] current_burst_bytes;

logic [31:0] current_spad_write_addr;

//----------------------------------------------------------
// FSM Register
//----------------------------------------------------------

always_ff @(posedge clk)
begin

    if (rst)
    begin

        state <= IDLE;

        current_request <= '0;

        current_address <= '0;

        bytes_remaining <= '0;

        current_spad_address <= '0;

        current_burst_bytes <= '0;

        current_spad_write_addr <= '0;

    end

    else
    begin

        //--------------------------------------------------
        // State Register
        //--------------------------------------------------

        state <= next_state;

        //--------------------------------------------------
        // Latch Tile Request
        //--------------------------------------------------

        if(state == IDLE &&
           tile_request_valid &&
           tile_request_ready)
        begin

            current_request <= tile_request;

            current_address <= tile_request.addr_a;

            bytes_remaining <= tile_request.transfer_bytes;

            current_spad_address <= '0;

            current_spad_write_addr <= '0;

            $display("[%0t] REQUEST LATCHED",$time);
            $display("transfer_bytes = %0d",
                     tile_request.transfer_bytes);
            $display("addr_a         = %08h",
                     tile_request.addr_a);

        end

        //--------------------------------------------------
        // Latch Burst Size
        //--------------------------------------------------

        if(state == REQUEST_BURST)
        begin

            current_burst_bytes <= burst_bytes;

        end

        //--------------------------------------------------
        // Consume Memory Beat
        //--------------------------------------------------

        if(state == WAIT_DATA &&
        mem_rvalid &&
        spad_ready)
        begin

            if(mem_rlast)
            begin

                current_address <= current_address + current_burst_bytes;

                bytes_remaining <= bytes_remaining - current_burst_bytes;

                current_spad_address <=
                    current_spad_address + current_burst_bytes;

                current_spad_write_addr <=
                    current_spad_address + current_burst_bytes;

            end
            else
            begin

                current_spad_write_addr <=
                    current_spad_write_addr + BYTES_PER_BEAT;

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

    case(state)

        //--------------------------------------------------
        // Wait for Scheduler
        //--------------------------------------------------

        IDLE:
        begin

            if(tile_request_valid &&
               tile_request_ready)
            begin

                next_state = REQUEST_BURST;

            end

        end

        //--------------------------------------------------
        // Issue exactly one memory request
        //--------------------------------------------------

        REQUEST_BURST:
        begin

            if(mem_req_ready)
            begin

                next_state = WAIT_DATA;

            end
            else
            begin

                next_state = WAIT_REQUEST_ACCEPT;

            end

        end

        //--------------------------------------------------
        // Wait until memory accepts request
        //--------------------------------------------------

        WAIT_REQUEST_ACCEPT:
        begin

            if(mem_req_ready)
            begin

                next_state = WAIT_DATA;

            end

        end

        //--------------------------------------------------
        // Wait for memory data
        //--------------------------------------------------

        WAIT_DATA:
        begin

            if(mem_rvalid && spad_ready)
            begin

                if(mem_rlast)
                begin

                    if(bytes_remaining == current_burst_bytes)
                        next_state = COMPLETE;
                    else
                        next_state = REQUEST_BURST;

                end
                else
                begin

                    next_state = WAIT_DATA;

                end

            end

        end

        //--------------------------------------------------
        // DMA Complete
        //--------------------------------------------------

        COMPLETE:
        begin

            next_state = IDLE;

        end

        //--------------------------------------------------

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

    spad_write_enable = 1'b0;
    spad_bank         = '0;
    spad_address      = '0;
    spad_write_data   = '0;

    transfer_busy = 1'b0;
    transfer_done = 1'b0;

    //------------------------------------------------------
    // State Outputs
    //------------------------------------------------------

    case(state)

        //--------------------------------------------------
        // Waiting for Scheduler
        //--------------------------------------------------

        IDLE:
        begin
            tile_request_ready = 1'b1;
        end

        //--------------------------------------------------
        // Issue Request
        //--------------------------------------------------

        REQUEST_BURST:
        begin

            transfer_busy = 1'b1;

            mem_req_valid = 1'b1;
            mem_req_addr  = current_address;
            mem_req_bytes = burst_bytes;

        end

        //--------------------------------------------------
        // Hold request until accepted
        //--------------------------------------------------

        WAIT_REQUEST_ACCEPT:
        begin

            transfer_busy = 1'b1;

            mem_req_valid = 1'b1;
            mem_req_addr  = current_address;
            mem_req_bytes = burst_bytes;

        end

        //--------------------------------------------------
        // Waiting for memory data
        //--------------------------------------------------

        WAIT_DATA:
        begin

            transfer_busy = 1'b1;

            if(mem_rvalid && spad_ready)
            begin

                spad_write_enable = 1'b1;

                spad_write_data = mem_rdata;

                spad_address = current_spad_write_addr;

                spad_bank = current_request.bank_a;

           end

        end

        //--------------------------------------------------
        // DMA Complete
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

//----------------------------------------------------------
// Burst Generator
//----------------------------------------------------------

always_comb
begin

    if (bytes_remaining >= BURST_BYTES)
    begin

        burst_bytes = BURST_BYTES;

    end
    else
    begin

        burst_bytes = bytes_remaining;

    end

end

endmodule