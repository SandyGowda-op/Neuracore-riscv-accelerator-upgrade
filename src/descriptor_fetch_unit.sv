/******************************************************************************
 *
 * Module      : descriptor_fetch_unit
 *
 * Version     : 2.0
 *
 * Description :
 *      Fetches one descriptor from Descriptor Memory and reconstructs it
 *      into a descriptor_t structure for the DMA Controller.
 *
 * Operation
 * ---------
 *
 *      start (1-cycle pulse)
 *              │
 *              ▼
 *      Fetch Descriptor Memory
 *              │
 *              ▼
 *      Assemble descriptor_t
 *              │
 *              ▼
 *      descriptor_out + done
 *
 ******************************************************************************/

`timescale 1ns/1ps

import descriptor_pkg::*;

module descriptor_fetch_unit
(

    //==========================================================
    // Clock / Reset
    //==========================================================

    input  logic clk,
    input  logic rst,

    //==========================================================
    // Control Interface
    //==========================================================

    input  logic start,

    input  logic [DESC_INDEX_WIDTH-1:0]
                 descriptor_index,

    //==========================================================
    // Descriptor Memory Interface
    //==========================================================

    output logic dfu_re,

    output logic [DESC_INDEX_WIDTH-1:0]
                 dfu_desc_idx,

    output logic [WORD_COUNTER_WIDTH-1:0]
                 dfu_word_offset,

    input  descriptor_mem_word_t
                 dfu_rdata,

    //==========================================================
    // DMA Interface
    //==========================================================

    output logic busy,

    output logic done,

    output descriptor_t
                 descriptor_out

);

    //==========================================================
    // FSM Registers
    //==========================================================

    dfu_state_t current_state;
    dfu_state_t next_state;

    //==========================================================
    // Datapath Control Signals
    //==========================================================

    logic load_descriptor_index;

    logic clear_word_counter;

    logic increment_word_counter;

    logic capture_descriptor_word;

    logic commit_descriptor;

    logic pulse_done;

    //==========================================================
    // Datapath Registers
    //==========================================================

    logic [DESC_INDEX_WIDTH-1:0]
          descriptor_index_reg;

    logic [WORD_COUNTER_WIDTH-1:0]
          word_counter;

    descriptor_t working_desc;

    descriptor_t descriptor_out_reg;

    logic done_reg;

    //==========================================================
    // Helper Signals
    //==========================================================

    logic last_word;

    //==========================================================
    // FSM State Register
    //==========================================================

    always_ff @(posedge clk or posedge rst)
    begin

        if (rst)
            current_state <= DFU_IDLE;
        else
            current_state <= next_state;

    end

//==========================================================
// Datapath Register Updates
//==========================================================

always_ff @(posedge clk or posedge rst)
begin

    if (rst)
    begin

        //--------------------------------------------------
        // Registers
        //--------------------------------------------------

        descriptor_index_reg <= '0;

        word_counter <= '0;

        working_desc <= '0;

        descriptor_out_reg <= '0;

        done_reg <= 1'b0;

    end

    else
    begin

        //--------------------------------------------------
        // Default
        //--------------------------------------------------

        done_reg <= 1'b0;

        //--------------------------------------------------
        // Load Descriptor Index
        //--------------------------------------------------

        if (load_descriptor_index)
        begin

            descriptor_index_reg <= descriptor_index;

            //--------------------------------------------------
            // Begin constructing a new descriptor
            //--------------------------------------------------

            working_desc <= '0;

        end

        //--------------------------------------------------
        // Word Counter
        //--------------------------------------------------

        if (clear_word_counter)
            word_counter <= '0;

        else if (increment_word_counter)
            word_counter <= word_counter + 1'b1;

        //--------------------------------------------------
        // Capture Descriptor Word
        //--------------------------------------------------

        if (capture_descriptor_word)
        begin

            case (word_counter)

                //--------------------------------------------------
                // Word 0
                //--------------------------------------------------

                DESC_WORD_SRCA:
                    working_desc.srcA_addr <= dfu_rdata;

                //--------------------------------------------------
                // Word 1
                //--------------------------------------------------

                DESC_WORD_SRCB:
                    working_desc.srcB_addr <= dfu_rdata;

                //--------------------------------------------------
                // Word 2
                //--------------------------------------------------

                DESC_WORD_DST:
                    working_desc.dst_addr <= dfu_rdata;

                //--------------------------------------------------
                // Word 3
                //--------------------------------------------------

                DESC_WORD_ROWS_COLS:
                begin
                    working_desc.rows <= dfu_rdata[31:16];
                    working_desc.cols <= dfu_rdata[15:0];
                end

                //--------------------------------------------------
                // Word 4
                //--------------------------------------------------

                DESC_WORD_K_STRIDEA:
                begin
                    working_desc.k       <= dfu_rdata[31:16];
                    working_desc.strideA <= dfu_rdata[15:0];
                end

                //--------------------------------------------------
                // Word 5
                //--------------------------------------------------

                DESC_WORD_STRIDEB_C:
                begin
                    working_desc.strideB <= dfu_rdata[31:16];
                    working_desc.strideC <= dfu_rdata[15:0];
                end

                //--------------------------------------------------
                // Word 6
                //--------------------------------------------------

                DESC_WORD_DATATYPE:
                begin

                    working_desc.datatype <=
                        datatype_t'(dfu_rdata[1:0]);

                    working_desc.reserved0 <=
                        dfu_rdata[31:2];

                end

                //--------------------------------------------------
                // Word 7
                //--------------------------------------------------

                DESC_WORD_FLAGS:
                    working_desc.flags <= dfu_rdata;

                //--------------------------------------------------
                // Word 8
                //--------------------------------------------------

                DESC_WORD_STATUS:
                    working_desc.status <= dfu_rdata;

                //--------------------------------------------------
                // Word 9
                //--------------------------------------------------

                DESC_WORD_RESERVED:
                    working_desc.reserved1 <= dfu_rdata;

                default:
                begin
                end

            endcase

        end

//--------------------------------------------------
// Commit Descriptor
//--------------------------------------------------

if(commit_descriptor)
begin

    descriptor_out_reg <= working_desc;

end

//--------------------------------------------------
// Done Pulse
//--------------------------------------------------

if(pulse_done)
begin

    done_reg <= 1'b1;

end
    end

end

//==========================================================
// Next State Logic
//==========================================================

always_comb
begin

    //------------------------------------------------------
    // Default
    //------------------------------------------------------

    next_state = current_state;

    //------------------------------------------------------

    case (current_state)

        //--------------------------------------------------
        // IDLE
        //--------------------------------------------------

        DFU_IDLE:
        begin

            if (start)
                next_state = DFU_ISSUE_READ;

        end

        //--------------------------------------------------
        // ISSUE READ
        //--------------------------------------------------

        DFU_ISSUE_READ:
        begin

            next_state = DFU_CAPTURE;

        end

        //--------------------------------------------------
        // CAPTURE
        //--------------------------------------------------

        DFU_CAPTURE:
        begin

            if (last_word)
                next_state = DFU_COMPLETE;
            else
                next_state = DFU_ISSUE_READ;

        end

        //--------------------------------------------------
        // COMPLETE
        //--------------------------------------------------

        DFU_COMPLETE:
        begin

            next_state = DFU_IDLE;

        end

        //--------------------------------------------------

        default:
        begin

            next_state = DFU_IDLE;

        end

    endcase

end

    //==========================================================
    // Control Generation
    //==========================================================

    always_comb
    begin

        //------------------------------------------------------
        // Defaults
        //------------------------------------------------------

        load_descriptor_index   = 1'b0;

        clear_word_counter      = 1'b0;

        increment_word_counter  = 1'b0;

        capture_descriptor_word = 1'b0;

        commit_descriptor       = 1'b0;

        pulse_done              = 1'b0;

        //------------------------------------------------------

        case(current_state)

            //--------------------------------------------------
            // IDLE
            //--------------------------------------------------

            DFU_IDLE:
            begin

                if(start)
                begin

                    load_descriptor_index = 1'b1;

                    clear_word_counter = 1'b1;

                end

            end

            //--------------------------------------------------
            // ISSUE READ
            //--------------------------------------------------

            DFU_ISSUE_READ:
            begin

                // Memory interface only
                // No datapath control required.
                // Descriptor memory interface is driven
                // by the dedicated Memory Interface block.
            end

            //--------------------------------------------------
            // CAPTURE
            //--------------------------------------------------

            DFU_CAPTURE:
            begin

                capture_descriptor_word = 1'b1;

                if(!last_word)
                    increment_word_counter = 1'b1;

            end

            //--------------------------------------------------
            // COMPLETE
            //--------------------------------------------------

            DFU_COMPLETE:
            begin

                commit_descriptor = 1'b1;

                pulse_done = 1'b1;

            end

        endcase

    end

    //==========================================================
    // Descriptor Memory Interface
    //==========================================================

always_comb
begin

    //------------------------------------------------------
    // Defaults
    //------------------------------------------------------

    dfu_re = 1'b0;

    dfu_desc_idx = descriptor_index_reg;

    dfu_word_offset = word_counter;

    last_word =
        (word_counter == WORDS_PER_DESCRIPTOR-1);

    //------------------------------------------------------

    if(current_state == DFU_ISSUE_READ)
    begin

        dfu_re = 1'b1;

    end

end

    //==========================================================
    // Output Assignments
    //==========================================================

    assign busy =
        (current_state != DFU_IDLE);

    assign done =
        done_reg;

    assign descriptor_out =
        descriptor_out_reg;

endmodule
