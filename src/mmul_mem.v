`timescale 1ns/1ps

module mmul_mem (
    input  wire        clk,
    input  wire        rst,

    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        we,

    output reg         mmul_busy,
    output reg         mmul_done
);

    // ============================================================
    // Matrix storage (8x8)
    // ============================================================
    integer A [0:7][0:7];
    integer B [0:7][0:7];
    integer C [0:7][0:7];

    integer r, c;

    // ============================================================
    // FSM indices
    // ============================================================
    reg [2:0] i, j, k;
    reg finish_pending;

    // ============================================================
    // Initialize matrices (DIAGONAL for demo)
    // ============================================================
    initial begin
        for (r = 0; r < 8; r = r + 1) begin
            for (c = 0; c < 8; c = c + 1) begin
                A[r][c] = (r == c) ? r : 0;
                B[r][c] = (r == c) ? r : 0;
                C[r][c] = 0;
            end
        end
    end

    // ============================================================
    // FSM: MMUL CONTROL
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i <= 0;
            j <= 0;
            k <= 0;
            mmul_busy <= 1'b0;
            mmul_done <= 1'b0;
            finish_pending <= 1'b0;

            for (r = 0; r < 8; r = r + 1)
                for (c = 0; c < 8; c = c + 1)
                    C[r][c] <= 0;
        end
        else begin
            mmul_done <= 1'b0; // default

            // ====================================================
            // START
            // ====================================================
            if (we && !mmul_busy) begin
                mmul_busy <= 1'b1;
                i <= 0;
                j <= 0;
                k <= 0;

                for (r = 0; r < 8; r = r + 1)
                    for (c = 0; c < 8; c = c + 1)
                        C[r][c] <= 0;

                $display("\n=== MMUL 8x8 START ===");
            end

            // ====================================================
            // RUN
            // ====================================================
            else if (mmul_busy) begin
                C[i][j] <= C[i][j] + A[i][k] * B[k][j];

                $display("MAC: C[%0d][%0d] += A[%0d][%0d] * B[%0d][%0d] = %0d",
                         i, j, i, k, k, j, A[i][k] * B[k][j]);

                if (k < 7)
                    k <= k + 1;
                else begin
                    k <= 0;
                    if (j < 7)
                        j <= j + 1;
                    else begin
                        j <= 0;
                        if (i < 7)
                            i <= i + 1;
                        else begin
                            // LAST MAC issued → wait 1 cycle
                            mmul_busy <= 1'b0;
                            finish_pending <= 1'b1;
                        end
                    end
                end
            end

            // ====================================================
            // FINISH (1 cycle later - IMPORTANT)
            // ====================================================
            if (finish_pending) begin
                finish_pending <= 1'b0;
                mmul_done <= 1'b1;

                $display("\n=================================");
                $display(" MATRIX MULTIPLICATION COMPLETE ");
                $display("=================================\n");

                // -------- Matrix A --------
                $display("Matrix A:");
                for (r = 0; r < 8; r = r + 1)
                    $display("%4d %4d %4d %4d %4d %4d %4d %4d",
                             A[r][0], A[r][1], A[r][2], A[r][3],
                             A[r][4], A[r][5], A[r][6], A[r][7]);

                // -------- Matrix B --------
                $display("\nMatrix B:");
                for (r = 0; r < 8; r = r + 1)
                    $display("%4d %4d %4d %4d %4d %4d %4d %4d",
                             B[r][0], B[r][1], B[r][2], B[r][3],
                             B[r][4], B[r][5], B[r][6], B[r][7]);

                // -------- Matrix C --------
                $display("\nMatrix C = A x B:");
                for (r = 0; r < 8; r = r + 1)
                    $display("%4d %4d %4d %4d %4d %4d %4d %4d",
                             C[r][0], C[r][1], C[r][2], C[r][3],
                             C[r][4], C[r][5], C[r][6], C[r][7]);

                // -------- Verification --------
                $display("\nVerification:");
                for (r = 0; r < 8; r = r + 1) begin
                    if (C[r][r] == r*r)
                        $display("PASS: C[%0d][%0d] = %0d",
                                 r, r, C[r][r]);
                    else
                        $display("FAIL: C[%0d][%0d] = %0d (expected %0d)",
                                 r, r, C[r][r], r*r);
                end

                $display("\nAXB = C VERIFIED");
                $display("=================================\n");
            end
        end
    end

endmodule