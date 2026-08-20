//==============================================================================
// Module      : dense_subsystem_wrapper
// Project     : Descriptor-Driven RISC-V AI Accelerator
//
// Milestone 1:
//   End-to-end dense scheduling + tile generation + DMA data movement.
//
//   Descriptor
//       |
//       v
//   Dense Scheduler
//       |
//       +--> Tile Walker
//       |
//       +--> Tile Generator
//       |
//       v
//   Transfer Engine
//       |
//       +--> Main Memory
//       |
//       +--> Scratchpad Controller
//                   |
//                   v
//              Scratchpad Banks
//
// IMPORTANT:
//   This wrapper does not modify any existing subsystem module.
//   Sparse datapath is intentionally excluded from this milestone.
//   The known scratchpad backpressure limitation remains unchanged.
//
//==============================================================================

`timescale 1ns/1ps
`default_nettype none

import descriptor_pkg::*;
import tile_pkg::*;

module dense_subsystem_wrapper #(

    parameter int DATA_WIDTH      = 32,
    parameter int SPAD_DEPTH      = 64,
    parameter int SPAD_ADDR_WIDTH = 6

)(
    //==========================================================================
    // Global
    //==========================================================================

    input logic clk,
    input logic rst,

    //==========================================================================
    // Descriptor Interface
    //==========================================================================

    input  logic       start,
    input descriptor_t descriptor,

    output logic       dense_done,

    //==========================================================================
    // Data-Movement Status
    //==========================================================================

    output logic       transfer_busy,
    output logic       transfer_done,

    //==========================================================================
    // Scratchpad Debug / Observation
    //==========================================================================

    output logic [3:0]  debug_spad_bank,
    output logic [31:0] debug_spad_address,
    output logic [63:0] debug_spad_write_data,
    output logic        debug_spad_write_enable

);

    //==========================================================================
    // Scheduler <-> Tile Walker
    //==========================================================================

    logic walker_start;
    logic walker_next;

    logic [15:0] max_tile_rows;
    logic [15:0] max_tile_cols;
    logic [15:0] max_tile_k;

    tile_context_t current_tile;

    logic first_tile;
    logic last_tile;
    logic walker_done;

    //==========================================================================
    // Tile Generator
    //==========================================================================

    tile_request_t generated_request;

    //==========================================================================
    // Scheduler <-> Transfer Engine
    //==========================================================================

    logic          transfer_valid;
    logic          transfer_ready;
    tile_request_t transfer_request;

    //==========================================================================
    // Main Memory Interface
    //==========================================================================

    logic        mem_req_valid;
    logic        mem_req_ready;

    logic [31:0] mem_req_addr;
    logic [31:0] mem_req_bytes;

    logic        mem_rvalid;
    logic [63:0] mem_rdata;
    logic        mem_rlast;
    logic        mem_rready;

    //==========================================================================
    // Transfer Engine -> Scratchpad Controller
    //==========================================================================

    logic        spad_write_enable;
    logic [3:0]  spad_bank;
    logic [31:0] spad_address;
    logic [63:0] spad_write_data;

    logic        spad_ready;

    //==========================================================================
    // Scratchpad Controller -> Scratchpad
    //==========================================================================

    logic [1:0]                  dma_bank_sel;
    logic                        dma_en;
    logic                        dma_we;
    logic [SPAD_ADDR_WIDTH-1:0]  dma_addr;
    logic [31:0]                 dma_wdata;

    //==========================================================================
    // Scratchpad Bank Read Data
    //==========================================================================

    logic [DATA_WIDTH-1:0] dma_rdata_a;
    logic [DATA_WIDTH-1:0] dma_rdata_b;
    logic [DATA_WIDTH-1:0] dma_rdata_c;

        //==========================================================================
    // Scheduler <-> Compute Controller
    //==========================================================================
    //
    // The scheduler launches computation for the tile that has completed
    // its transfer into the scratchpad.
    //
    // compute_request contains the accepted tile parameters.
    //
    //==========================================================================

    logic          compute_start;
    logic          compute_done;
    logic          compute_busy;

    tile_request_t compute_request;


    //==========================================================================
    // Compute Controller <-> Scratchpad
    //==========================================================================

    logic                         compute_spad_a_en;
    logic [SPAD_ADDR_WIDTH-1:0]   compute_spad_a_addr;
    logic [DATA_WIDTH-1:0]        compute_spad_a_rdata;

    logic                         compute_spad_b_en;
    logic [SPAD_ADDR_WIDTH-1:0]   compute_spad_b_addr;
    logic [DATA_WIDTH-1:0]        compute_spad_b_rdata;

    //==========================================================================
    // Dense Scheduler
    //==========================================================================

    dense_scheduler u_dense_scheduler (

        .clk               (clk),
        .rst_n             (~rst),

        .start             (start),
        .descriptor        (descriptor),

        .dense_done        (dense_done),

        .walker_start      (walker_start),
        .walker_next       (walker_next),

        .max_tile_rows     (max_tile_rows),
        .max_tile_cols     (max_tile_cols),
        .max_tile_k        (max_tile_k),

        .current_tile      (current_tile),

        .first_tile        (first_tile),
        .last_tile         (last_tile),
        .walker_done       (walker_done),

        .generated_request (generated_request),

        .transfer_ready    (transfer_ready),
        .transfer_done     (transfer_done),

        .transfer_valid    (transfer_valid),
        .transfer_request  (transfer_request),

        // Compute interface is intentionally unused in Milestone 1.
        .compute_start     (compute_start),
        .compute_done      (compute_done),
        .compute_request   (compute_request)
    );

    //==========================================================================
// Compute Controller
//==========================================================================
//
// Consumes the tile accepted by the scheduler.
//
// The compute controller addresses the scratchpad using WORD addresses.
// For the current 8x8 dense milestone:
//
//     base A = 0
//     base B = 0
//     stride A = 8 words
//     stride B = 8 words
//
// A and B reside in separate scratchpad banks.
//
//==========================================================================

compute_controller #(
    .DATA_WIDTH (DATA_WIDTH),
    .ACC_WIDTH  (64),
    .ADDR_WIDTH (SPAD_ADDR_WIDTH)
) u_compute_controller (

    .clk (clk),
    .rst (rst),

    //------------------------------------------------------
    // Compute command
    //------------------------------------------------------

    .start        (compute_start),

    .base_addr_a  ('0),
    .base_addr_b  ('0),

    .stride_a     (16'd8),
    .stride_b     (16'd8),

    .rows         (compute_request.rows),
    .cols         (compute_request.cols),
    .k_size       (compute_request.k_size),

    //------------------------------------------------------
    // Status
    //------------------------------------------------------

    .busy         (compute_busy),
    .done         (compute_done),

    //------------------------------------------------------
    // Scratchpad A
    //------------------------------------------------------

    .spad_a_en    (compute_spad_a_en),
    .spad_a_addr  (compute_spad_a_addr),
    .spad_a_rdata (compute_spad_a_rdata),

    //------------------------------------------------------
    // Scratchpad B
    //------------------------------------------------------

    .spad_b_en    (compute_spad_b_en),
    .spad_b_addr  (compute_spad_b_addr),
    .spad_b_rdata (compute_spad_b_rdata),

    //------------------------------------------------------
    // Result
    //------------------------------------------------------

    .result_valid (),
    .result_row   (),
    .result_col   (),
    .result_data  (),

    //------------------------------------------------------
    // Instrumentation
    //------------------------------------------------------

    .cycle_count  (),
    .a_read_count (),
    .b_read_count (),
    .mac_count    (),
    .output_count ()
);

    //==========================================================================
    // Tile Walker
    //==========================================================================

    tile_walker u_tile_walker (

        .clk           (clk),
        .rst           (rst),

        .start         (walker_start),
        .advance       (walker_next),

        .max_tile_rows (max_tile_rows),
        .max_tile_cols (max_tile_cols),
        .max_tile_k    (max_tile_k),

        .current_tile  (current_tile),

        .first_tile    (first_tile),
        .last_tile     (last_tile),
        .done          (walker_done)
    );

    //==========================================================================
    // Tile Generator
    //==========================================================================

    tile_generator u_tile_generator (

        .descriptor    (descriptor),
        .current_tile  (current_tile),
        .last_tile     (last_tile),

        .tile_request  (generated_request)
    );

        //==========================================================================
    // Transfer Engine
    //==========================================================================

    transfer_engine u_transfer_engine (

        .clk                (clk),
        .rst                (rst),

        // Scheduler interface
        .tile_request       (transfer_request),
        .tile_request_valid (transfer_valid),
        .tile_request_ready (transfer_ready),

        // Main memory request interface
        .mem_req_valid      (mem_req_valid),
        .mem_req_ready      (mem_req_ready),
        .mem_req_addr       (mem_req_addr),
        .mem_req_bytes      (mem_req_bytes),

        // Main memory read-data interface
        .mem_rvalid         (mem_rvalid),
        .mem_rdata          (mem_rdata),
        .mem_rlast          (mem_rlast),
        .mem_rready(mem_rready),

        // Scratchpad interface
        .spad_write_enable  (spad_write_enable),
        .spad_bank          (spad_bank),
        .spad_address       (spad_address),
        .spad_write_data    (spad_write_data),
        .spad_ready         (spad_ready),

        // Status
        .transfer_busy      (transfer_busy),
        .transfer_done      (transfer_done)
    );

    //==========================================================================
    // Main Memory Model
    //==========================================================================

    main_memory_model #(
        .DATA_WIDTH     (64),
        .MEMORY_SIZE    (65536),
        .MEMORY_LATENCY (3)
    ) u_main_memory (

        .clk            (clk),
        .rst            (rst),

        // DMA request channel
        .mem_req_valid  (mem_req_valid),
        .mem_req_ready  (mem_req_ready),

        .mem_req_addr   (mem_req_addr),
        .mem_req_bytes  (mem_req_bytes),

        // Current DMA path is read-only.
        .mem_req_write  (1'b0),

        // Read data channel
        .mem_rvalid     (mem_rvalid),
        .mem_rdata      (mem_rdata),
        .mem_rlast      (mem_rlast),
        .mem_rready(mem_rready)
    );

    //==========================================================================
    // Scratchpad Controller
    //==========================================================================
    //
    // Converts the Transfer Engine's 64-bit DMA writes into the
    // two 32-bit writes expected by the scratchpad banks.
    //
    //==========================================================================

    scratchpad_controller #(
        .DMA_DATA_WIDTH  (64),
        .SPAD_DATA_WIDTH (32),
        .SPAD_ADDR_WIDTH (SPAD_ADDR_WIDTH)
    ) u_scratchpad_controller (

        .clk              (clk),
        .rst              (rst),

        // Transfer Engine interface
        .dma_write_enable (spad_write_enable),
        .dma_bank         (spad_bank),
        .dma_address      (spad_address),
        .dma_write_data   (spad_write_data),

        .dma_ready        (spad_ready),

        // Scratchpad interface
        .spad_bank_sel    (dma_bank_sel),
        .spad_en          (dma_en),
        .spad_we          (dma_we),
        .spad_addr        (dma_addr),
        .spad_wdata       (dma_wdata)
    );

    //==========================================================================
    // Scratchpad Bank A
    //==========================================================================

    scratchpad_bank #(
        .DATA_WIDTH (DATA_WIDTH),
        .MATRIX_DIM (8),
        .DEPTH      (SPAD_DEPTH),
        .ADDR_WIDTH (SPAD_ADDR_WIDTH)
    ) u_scratchpad_bank_a (

        .clk          (clk),
        .rst          (rst),

        // DMA port
        .dma_en       (dma_en && (dma_bank_sel == 2'b00)),
        .dma_we       (dma_we),
        .dma_addr     (dma_addr),
        .dma_wdata    (dma_wdata),
        .dma_rdata    (dma_rdata_a),

        // Compute port unused in Milestone 1
        // Compute port

        .compute_en    (compute_spad_a_en),
        .compute_we    (1'b0),
        .compute_addr  (compute_spad_a_addr),
        .compute_wdata ('0),
        .compute_rdata (compute_spad_a_rdata)
    );

    //==========================================================================
    // Scratchpad Bank B
    //==========================================================================

    scratchpad_bank #(
        .DATA_WIDTH (DATA_WIDTH),
        .MATRIX_DIM (8),
        .DEPTH      (SPAD_DEPTH),
        .ADDR_WIDTH (SPAD_ADDR_WIDTH)
    ) u_scratchpad_bank_b (

        .clk          (clk),
        .rst          (rst),

        // DMA port
        .dma_en       (dma_en && (dma_bank_sel == 2'b01)),
        .dma_we       (dma_we),
        .dma_addr     (dma_addr),
        .dma_wdata    (dma_wdata),
        .dma_rdata    (dma_rdata_b),

        // Compute port unused in Milestone 1
        // Compute port

        .compute_en    (compute_spad_b_en),
        .compute_we    (1'b0),
        .compute_addr  (compute_spad_b_addr),
        .compute_wdata ('0),
        .compute_rdata (compute_spad_b_rdata)
    );

    //==========================================================================
    // Scratchpad Bank C
    //==========================================================================
    //
    // Reserved for destination/output data.
    // No compute access is used in Milestone 1.
    //
    //==========================================================================

    scratchpad_bank #(
        .DATA_WIDTH (DATA_WIDTH),
        .MATRIX_DIM (8),
        .DEPTH      (SPAD_DEPTH),
        .ADDR_WIDTH (SPAD_ADDR_WIDTH)
    ) u_scratchpad_bank_c (

        .clk          (clk),
        .rst          (rst),

        // DMA port
        .dma_en       (dma_en && (dma_bank_sel == 2'b10)),
        .dma_we       (dma_we),
        .dma_addr     (dma_addr),
        .dma_wdata    (dma_wdata),
        .dma_rdata    (dma_rdata_c),

        // Compute port unused in Milestone 1
        .compute_en   (1'b0),
        .compute_we   (1'b0),
        .compute_addr ('0),
        .compute_wdata('0),
        .compute_rdata()
    );

    //==========================================================================
    // Debug Outputs
    //==========================================================================
    //
    // These are observation-only signals.
    // They do not modify the datapath.
    //
    //==========================================================================

    always_comb begin

        debug_spad_bank         = spad_bank;
        debug_spad_address      = spad_address;
        debug_spad_write_data   = spad_write_data;
        debug_spad_write_enable = spad_write_enable;

    end

    //==========================================================================
    // End of Wrapper
    //==========================================================================

endmodule

`default_nettype wire