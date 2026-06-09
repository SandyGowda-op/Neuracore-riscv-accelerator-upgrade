module immediate_gen (
    input  wire [31:0] instr,
    output reg  [31:0] imm_out
);

    wire [6:0] opcode = instr[6:0];

    always @(*) begin
        case (opcode)

            // I-type (ADDI, LW)
            7'b0010011,
            7'b0000011: begin
                imm_out = {{20{instr[31]}}, instr[31:20]};
            end

            // S-type (SW)  <<< 🔥 THIS WAS BROKEN BEFORE
            7'b0100011: begin
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            // U-type (LUI)
            7'b0110111: begin
                imm_out = {instr[31:12], 12'b0};
            end

            // Default
            default: begin
                imm_out = 32'b0;
            end

        endcase
    end

endmodule