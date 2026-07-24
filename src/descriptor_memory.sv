/******************************************************************************
 *
 * Module : descriptor_memory
 *
 * Description:
 *     Dual-port descriptor memory.
 *
 *     CPU Port  : Read / Write
 *     DFU Port  : Read Only
 *
 *     Descriptor Memory stores descriptors as consecutive 32-bit words.
 *
 ******************************************************************************/

`timescale 1ns/1ps

import descriptor_pkg::*;

module descriptor_memory
#(
    parameter string INIT_FILE    = "",
    parameter bit    USE_INIT_FILE = 1'b0
)
(

    input  logic clk,

    //==========================================================
    // CPU Interface
    //==========================================================

    input  logic                     cpu_re,
    input  logic                     cpu_we,

    input  logic [DESC_INDEX_WIDTH-1:0]
                 cpu_desc_idx,

    input  logic [WORD_COUNTER_WIDTH-1:0]
                 cpu_word_offset,

    input  descriptor_mem_word_t
                 cpu_wdata,

    output descriptor_mem_word_t
                 cpu_rdata,

    //==========================================================
    // Descriptor Fetch Unit Interface
    //==========================================================

    input  logic                     dfu_re,

    input  logic [DESC_INDEX_WIDTH-1:0]
                 dfu_desc_idx,

    input  logic [WORD_COUNTER_WIDTH-1:0]
                 dfu_word_offset,

    output descriptor_mem_word_t
                 dfu_rdata

);

    //==========================================================
    // Memory Array
    //==========================================================

    descriptor_mem_word_t mem [0:DESCRIPTOR_MEM_DEPTH-1];

    //==========================================================
    // Internal Addresses
    //==========================================================

    logic [MEM_ADDR_WIDTH-1:0] cpu_addr;

    logic [MEM_ADDR_WIDTH-1:0] dfu_addr;

    //----------------------------------------------------------
    // Address Generation
    //----------------------------------------------------------

    assign cpu_addr =
            cpu_desc_idx * WORDS_PER_DESCRIPTOR +
            cpu_word_offset;

    assign dfu_addr =
            dfu_desc_idx * WORDS_PER_DESCRIPTOR +
            dfu_word_offset;

    //==========================================================
    // Optional Memory Initialization
    //==========================================================

    initial begin

        if (USE_INIT_FILE)
            $readmemh(INIT_FILE, mem);

    end

    //==========================================================
    // CPU Port
    //==========================================================

    always_ff @(posedge clk)
begin

    if(cpu_we)
    begin
        `ifdef SIM_DEBUG
        $display("[%0t] WRITE", $time);
        $display("    addr = %0d", cpu_addr);
        $display("    data = %h", cpu_wdata);
        `endif  
        mem[cpu_addr] <= cpu_wdata;
    end

    if(cpu_re)
    begin
        cpu_rdata <= mem[cpu_addr];

        `ifdef SIM_DEBUG
        $display("[%0t] READ", $time);
        $display("    addr = %0d", cpu_addr);
        $display("    mem  = %h", mem[cpu_addr]);
        `endif
    end

end

    //==========================================================
    // DFU Port
    //==========================================================

    always_ff @(posedge clk)
    begin

        if(dfu_re)
            dfu_rdata <= mem[dfu_addr];

    end

endmodule
