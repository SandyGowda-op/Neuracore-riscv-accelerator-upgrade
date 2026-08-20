/******************************************************************************
 *
 * Module      : tile_walker
 *
 * Description :
 *      Generic hardware tile iterator.
 *
 * Responsibilities:
 *      - Maintain current tile coordinates
 *      - Advance through a 3D tile space
 *      - Indicate first tile
 *      - Indicate last tile
 *      - Indicate completion
 *
 ******************************************************************************/

`timescale 1ns/1ps

import tile_pkg::*;

module tile_walker
(
    //----------------------------------------------------------
    // Global
    //----------------------------------------------------------

    input logic clk,
    input logic rst,

    //----------------------------------------------------------
    // Control
    //----------------------------------------------------------

    input logic start,
    input logic advance,

    //----------------------------------------------------------
    // Tile Limits
    //----------------------------------------------------------

    input logic [15:0] max_tile_rows,
    input logic [15:0] max_tile_cols,
    input logic [15:0] max_tile_k,

    //----------------------------------------------------------
    // Outputs
    //----------------------------------------------------------

    output tile_context_t current_tile,

    output logic first_tile,
    output logic last_tile,
    output logic done

);

//----------------------------------------------------------
// Tile Context Register
//----------------------------------------------------------

tile_context_t tile_reg;

//----------------------------------------------------------
// Completion Register
//----------------------------------------------------------

logic done_reg;

//----------------------------------------------------------
// Last Valid Tile Indices
//----------------------------------------------------------

logic [15:0] max_row_index;
logic [15:0] max_col_index;
logic [15:0] max_k_index;

//----------------------------------------------------------
// Output Assignments
//----------------------------------------------------------

assign current_tile = tile_reg;

assign done = done_reg;

assign max_row_index = max_tile_rows - 16'd1;
assign max_col_index = max_tile_cols - 16'd1;
assign max_k_index   = max_tile_k   - 16'd1;

assign first_tile =
    (tile_reg.tile_row == 16'd0) &&
    (tile_reg.tile_col == 16'd0) &&
    (tile_reg.tile_k   == 16'd0);

assign last_tile =
    (tile_reg.tile_row == max_row_index) &&
    (tile_reg.tile_col == max_col_index) &&
    (tile_reg.tile_k   == max_k_index);

//----------------------------------------------------------
// Tile Walker Registers
//----------------------------------------------------------

always_ff @(posedge clk)
begin

    if (rst)
    begin

        tile_reg.tile_row <= 16'd0;
        tile_reg.tile_col <= 16'd0;
        tile_reg.tile_k   <= 16'd0;

        done_reg <= 1'b0;

    end

    else
    begin

        //--------------------------------------------------
        // Start New Traversal
        //--------------------------------------------------

        if (start)
        begin

            tile_reg.tile_row <= 16'd0;
            tile_reg.tile_col <= 16'd0;
            tile_reg.tile_k   <= 16'd0;

            done_reg <= 1'b0;

        end

        //--------------------------------------------------
        // Advance Tile
        //--------------------------------------------------

        else if (advance && !done_reg)
        begin

            //--------------------------------------------------
            // Advance K Dimension
            //--------------------------------------------------

            if (tile_reg.tile_k < max_k_index)
            begin

                tile_reg.tile_k <= tile_reg.tile_k + 16'd1;

            end

            //--------------------------------------------------
            // K Dimension Complete
            // Advance Column
            //--------------------------------------------------

            else if (tile_reg.tile_col < max_col_index)
            begin

                tile_reg.tile_k   <= 16'd0;
                tile_reg.tile_col <= tile_reg.tile_col + 16'd1;

            end

            //--------------------------------------------------
            // K and Column Complete
            // Advance Row
            //--------------------------------------------------

            else if (tile_reg.tile_row < max_row_index)
            begin

                tile_reg.tile_k   <= 16'd0;
                tile_reg.tile_col <= 16'd0;
                tile_reg.tile_row <= tile_reg.tile_row + 16'd1;

            end

            //--------------------------------------------------
            // Already At Final Tile
            //--------------------------------------------------
            //
            // IMPORTANT:
            // Do not modify tile_reg here.
            //
            // The walker remains positioned on the final tile
            // while done is asserted.
            //--------------------------------------------------

            else
            begin

                done_reg <= 1'b1;

            end

        end

    end

end

endmodule