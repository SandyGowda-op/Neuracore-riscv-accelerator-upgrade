//==============================================================================
// Module      : compute_controller
// Project     : Descriptor-Driven RISC-V AI Accelerator
//
// Description :
//   Dense matrix-computation controller.
//
//   Controls the traversal of a dense matrix tile and coordinates:
//
//       Scratchpad A
//            |
//            v
//       Scratchpad B ---> Compute Controller ---> MAC
//                                      |
//                                      v
//                                Output Result
//
//   Matrix operation:
//
//       C[i][j] = SUM(A[i][k] * B[k][j])
//
//   Current Phase:
//     - Dense execution only
//     - Single MAC operation per cycle
//     - Two-cycle scratchpad read latency
//     - No sparse metadata handling
//     - No C scratchpad writeback
//
//   Research instrumentation:
//     - Cycle count
//     - A read count
//     - B read count
//     - MAC count
//     - Output count
//
//==============================================================================

`timescale 1ns/1ps
`default_nettype none

module compute_controller #(

    parameter int DATA_WIDTH = 32,
    parameter int ACC_WIDTH  = 64,
    parameter int ADDR_WIDTH = 6

)(

    input logic clk,
    input logic rst,

    //==========================================================
    // Compute Command
    //==========================================================

    input logic start,

    input logic [ADDR_WIDTH-1:0] base_addr_a,
    input logic [ADDR_WIDTH-1:0] base_addr_b,

    input logic [15:0] stride_a,
    input logic [15:0] stride_b,

    input logic [15:0] rows,
    input logic [15:0] cols,
    input logic [15:0] k_size,

    //==========================================================
    // Status
    //==========================================================

    output logic busy,
    output logic done,

    //==========================================================
    // Scratchpad A
    //==========================================================

    output logic                  spad_a_en,
    output logic [ADDR_WIDTH-1:0] spad_a_addr,
    input  logic [DATA_WIDTH-1:0] spad_a_rdata,

    //==========================================================
    // Scratchpad B
    //==========================================================

    output logic                  spad_b_en,
    output logic [ADDR_WIDTH-1:0] spad_b_addr,
    input  logic [DATA_WIDTH-1:0] spad_b_rdata,

    //==========================================================
    // Result Interface
    //==========================================================

    output logic                  result_valid,
    output logic [15:0]            result_row,
    output logic [15:0]            result_col,
    output logic signed [ACC_WIDTH-1:0] result_data,

    //==========================================================
    // Research Instrumentation
    //==========================================================

    output logic [31:0] cycle_count,
    output logic [31:0] a_read_count,
    output logic [31:0] b_read_count,
    output logic [31:0] mac_count,
    output logic [31:0] output_count

);

//==============================================================================
// Parameter Checking
//==============================================================================

initial begin

    if (DATA_WIDTH <= 0)
        $fatal("compute_controller: DATA_WIDTH must be > 0");

    if (ACC_WIDTH <= 0)
        $fatal("compute_controller: ACC_WIDTH must be > 0");

    if (ADDR_WIDTH <= 0)
        $fatal("compute_controller: ADDR_WIDTH must be > 0");

end

//==============================================================================
// FSM
//==============================================================================
//
// IDLE
//   Wait for start.
//
// CLEAR_ACC
//   Begin a new C[i][j] dot product.
//
// ISSUE_READ
//   Present A and B addresses to the scratchpad.
//
// WAIT_SPAD_1
//   First cycle of scratchpad read latency.
//
// WAIT_SPAD_2
//   Second cycle of scratchpad read latency.
//
// MAC
//   Execute one A*B accumulation.
//
// CAPTURE_RESULT
//   Capture the completed accumulator after the final MAC.
//
// NEXT_OUTPUT
//   Advance j/i and begin the next output element.
//
// COMPLETE
//   One-cycle completion state.
//
//==============================================================================

typedef enum logic [3:0]
{
    IDLE,

    CLEAR_ACC,

    ISSUE_READ,

    WAIT_SPAD_1,

    WAIT_SPAD_2,

    MAC,

    CAPTURE_RESULT,

    NEXT_OUTPUT,

    COMPLETE

} compute_state_t;

compute_state_t state;
compute_state_t next_state;

//==============================================================================
// Latched Command
//==============================================================================

logic [ADDR_WIDTH-1:0] base_addr_a_reg;
logic [ADDR_WIDTH-1:0] base_addr_b_reg;

logic [15:0] stride_a_reg;
logic [15:0] stride_b_reg;

logic [15:0] rows_reg;
logic [15:0] cols_reg;
logic [15:0] k_size_reg;

//==============================================================================
// Matrix Traversal Counters
//==============================================================================

logic [15:0] i;
logic [15:0] j;
logic [15:0] k;

//==============================================================================
// MAC Interface
//==============================================================================

logic mac_enable;
logic mac_clear;

logic signed [DATA_WIDTH-1:0] mac_operand_a;
logic signed [DATA_WIDTH-1:0] mac_operand_b;

logic signed [ACC_WIDTH-1:0] mac_accumulator;

//==============================================================================
// MAC Unit
//==============================================================================

mac_unit #(

    .OPERAND_WIDTH (DATA_WIDTH),
    .ACC_WIDTH     (ACC_WIDTH)

) mac_inst (

    .clk          (clk),
    .rst          (rst),

    .enable       (mac_enable),
    .clear_acc    (mac_clear),

    .operand_a    (mac_operand_a),
    .operand_b    (mac_operand_b),

    .accumulator  (mac_accumulator)

);

//==============================================================================
// Address Generation
//==============================================================================
//
// A[i][k] = base_A + i*stride_A + k
//
// B[k][j] = base_B + k*stride_B + j
//
// All addresses are scratchpad WORD addresses in this controller.
//
//==============================================================================

logic [ADDR_WIDTH-1:0] current_a_addr;
logic [ADDR_WIDTH-1:0] current_b_addr;

logic [31:0] calculated_a_addr;
logic [31:0] calculated_b_addr;

always_comb begin

    calculated_a_addr =
        base_addr_a_reg +
        (i * stride_a_reg) +
        k;

    calculated_b_addr =
        base_addr_b_reg +
        (k * stride_b_reg) +
        j;

    current_a_addr =
        calculated_a_addr[ADDR_WIDTH-1:0];

    current_b_addr =
        calculated_b_addr[ADDR_WIDTH-1:0];

end

//==============================================================================
// MAC Operands
//==============================================================================
//
// Scratchpad data is interpreted as signed DATA_WIDTH-bit values.
//
//==============================================================================

assign mac_operand_a =
    $signed(spad_a_rdata);

assign mac_operand_b =
    $signed(spad_b_rdata);

//==============================================================================
// State Register
//==============================================================================

always_ff @(posedge clk) begin

    if (rst) begin

        state <= IDLE;

        base_addr_a_reg <= '0;
        base_addr_b_reg <= '0;

        stride_a_reg <= '0;
        stride_b_reg <= '0;

        rows_reg <= '0;
        cols_reg <= '0;
        k_size_reg <= '0;

        i <= '0;
        j <= '0;
        k <= '0;

    end

    else begin

        state <= next_state;

        //------------------------------------------------------
        // Accept new computation
        //------------------------------------------------------

        if (state == IDLE && start) begin

            base_addr_a_reg <= base_addr_a;
            base_addr_b_reg <= base_addr_b;

            stride_a_reg <= stride_a;
            stride_b_reg <= stride_b;

            rows_reg <= rows;
            cols_reg <= cols;
            k_size_reg <= k_size;

            i <= 16'd0;
            j <= 16'd0;
            k <= 16'd0;

        end

        //------------------------------------------------------
        // Advance K
        //------------------------------------------------------

        else if (state == MAC) begin

            if (k < (k_size_reg - 1))
                k <= k + 1'b1;

        end

        //------------------------------------------------------
        // Advance output position
        //------------------------------------------------------

        else if (state == NEXT_OUTPUT) begin

            k <= 16'd0;

            if (j < (cols_reg - 1)) begin

                j <= j + 1'b1;

            end

            else begin

                j <= 16'd0;

                if (i < (rows_reg - 1))
                    i <= i + 1'b1;

            end

        end

    end

end

//==============================================================================
// Next-State Logic
//==============================================================================

always_comb begin

    next_state = state;

    case (state)

        //======================================================
        // Wait for command
        //======================================================

        IDLE:
        begin

            if (start)
                next_state = CLEAR_ACC;

        end

        //======================================================
        // Clear accumulator for C[i][j]
        //======================================================

        CLEAR_ACC:
        begin

            next_state = ISSUE_READ;

        end

        //======================================================
        // Issue A/B scratchpad reads
        //======================================================

        ISSUE_READ:
        begin

            next_state = WAIT_SPAD_1;

        end

        //======================================================
        // First scratchpad latency cycle
        //======================================================

        WAIT_SPAD_1:
        begin

            next_state = WAIT_SPAD_2;

        end

        //======================================================
        // Second scratchpad latency cycle
        //======================================================

        WAIT_SPAD_2:
        begin

            next_state = MAC;

        end

        //======================================================
        // Perform one MAC
        //======================================================

        MAC:
        begin

            if (k_size_reg == 0)
                next_state = COMPLETE;

            else if (k == (k_size_reg - 1))
                next_state = CAPTURE_RESULT;

            else
                next_state = ISSUE_READ;

        end

        //======================================================
        // Capture completed dot product
        //======================================================

        CAPTURE_RESULT:
        begin

            next_state = NEXT_OUTPUT;

        end

        //======================================================
        // Advance output coordinates
        //======================================================

        NEXT_OUTPUT:
        begin

            if ((i == (rows_reg - 1)) &&
                (j == (cols_reg - 1)))
            begin

                next_state = COMPLETE;

            end

            else begin

                next_state = CLEAR_ACC;

            end

        end

        //======================================================
        // Complete
        //======================================================

        COMPLETE:
        begin

            next_state = IDLE;

        end

        //======================================================
        // Safety
        //======================================================

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

    //--------------------------------------------------------------------------
    // Defaults
    //--------------------------------------------------------------------------

    busy = 1'b0;
    done = 1'b0;

    spad_a_en   = 1'b0;
    spad_a_addr = '0;

    spad_b_en   = 1'b0;
    spad_b_addr = '0;

    mac_enable = 1'b0;
    mac_clear  = 1'b0;

    //--------------------------------------------------------------------------
    // Busy
    //--------------------------------------------------------------------------

    case (state)

        CLEAR_ACC,
        ISSUE_READ,
        WAIT_SPAD_1,
        WAIT_SPAD_2,
        MAC,
        CAPTURE_RESULT,
        NEXT_OUTPUT:
        begin
            busy = 1'b1;
        end

        default:
        begin
            busy = 1'b0;
        end

    endcase

    //--------------------------------------------------------------------------
    // State-specific control signals
    //--------------------------------------------------------------------------

    case (state)

        //==============================================================
        // Clear MAC accumulator
        //==============================================================

        CLEAR_ACC:
        begin

            mac_clear = 1'b1;

        end


        //==============================================================
        // Issue scratchpad reads
        //==============================================================

        ISSUE_READ:
        begin

            spad_a_en   = 1'b1;
            spad_a_addr = current_a_addr;

            spad_b_en   = 1'b1;
            spad_b_addr = current_b_addr;

        `ifndef SYNTHESIS

            $display(
                "[SPAD_ISSUE] t=%0t i=%0d j=%0d k=%0d A_ADDR=%0d B_ADDR=%0d",
                $time,
                i,
                j,
                k,
                current_a_addr,
                current_b_addr
            );

        `endif

        end


        //==============================================================
        // Perform MAC
        //==============================================================

        MAC:
        begin

            mac_enable = 1'b1;

        `ifndef SYNTHESIS

            $display(
                "[MAC_DEBUG] t=%0t i=%0d j=%0d k=%0d A=%0d B=%0d ACC_BEFORE=%0d",
                $time,
                i,
                j,
                k,
                $signed(spad_a_rdata),
                $signed(spad_b_rdata),
                $signed(mac_accumulator)
            );

        `endif

        end


        //==============================================================
        // Completion
        //==============================================================

        COMPLETE:
        begin

            done = 1'b1;

        end


        //==============================================================
        // Other states
        //==============================================================

        default:
        begin

        end

    endcase

end

//==============================================================================
// Result Registers
//==============================================================================

always_ff @(posedge clk) begin

    if (rst) begin

        result_valid <= 1'b0;
        result_row   <= '0;
        result_col   <= '0;
        result_data  <= '0;

    end

    else begin

        result_valid <= 1'b0;

        //------------------------------------------------------
        // MAC accumulator is updated at the end of MAC state.
        // CAPTURE_RESULT occurs on the following cycle, so
        // mac_accumulator already contains the complete dot
        // product.
        //------------------------------------------------------

        if (state == CAPTURE_RESULT) begin

            result_valid <= 1'b1;
            result_row   <= i;
            result_col   <= j;
            result_data  <= mac_accumulator;

        end

    end

end

//==============================================================================
// Temporary MAC Debug
//==============================================================================

`ifndef SYNTHESIS
always_ff @(posedge clk) begin

    if (!rst && state == MAC) begin

        $display(
            "[MAC_DEBUG] t=%0t i=%0d j=%0d k=%0d A=%0d B=%0d ACC=%0d",
            $time,
            i,
            j,
            k,
            $signed(spad_a_rdata),
            $signed(spad_b_rdata),
            $signed(mac_accumulator)
        );

    end

end
`endif

//==============================================================================
// Research Instrumentation
//==============================================================================

always_ff @(posedge clk) begin

    if (rst) begin

        cycle_count  <= 32'd0;
        a_read_count <= 32'd0;
        b_read_count <= 32'd0;
        mac_count    <= 32'd0;
        output_count <= 32'd0;

    end

    else begin

        //------------------------------------------------------
        // Count active computation cycles.
        //------------------------------------------------------

        if (state != IDLE)
            cycle_count <= cycle_count + 1'b1;

        //------------------------------------------------------
        // Count scratchpad reads.
        //------------------------------------------------------

        if (state == ISSUE_READ) begin

            a_read_count <= a_read_count + 1'b1;
            b_read_count <= b_read_count + 1'b1;

        end

        //------------------------------------------------------
        // Count actual MAC operations.
        //------------------------------------------------------

        if (state == MAC)
            mac_count <= mac_count + 1'b1;

        //------------------------------------------------------
        // Count completed output elements.
        //------------------------------------------------------

        if (state == CAPTURE_RESULT)
            output_count <= output_count + 1'b1;

    end

end

endmodule

`default_nettype wire