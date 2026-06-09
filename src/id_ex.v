module id_ex (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,

    input  wire [31:0] pc_in,
    input  wire [31:0] rs1_data_in,
    input  wire [31:0] rs2_data_in,
    input  wire [31:0] imm_in,
    input  wire [4:0]  rs1_in,
    input  wire [4:0]  rs2_in,
    input  wire [4:0]  rd_in,
    input  wire [6:0]  opcode_in,   // 🔧 ADDED

    input  wire        alu_src_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
    input  wire        reg_write_in,

    output reg  [31:0] pc_out,
    output reg  [31:0] rs1_out,
    output reg  [31:0] rs2_out,
    output reg  [31:0] imm_out,
    output reg  [4:0]  rs1_addr_out,
    output reg  [4:0]  rs2_addr_out,
    output reg  [4:0]  rd_out,
    output reg  [6:0]  opcode_out,   // 🔧 ADDED

    output reg         alu_src_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg         mem_to_reg_out,
    output reg         reg_write_out
);

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc_out           <= 0;
            rs1_out          <= 0;
            rs2_out          <= 0;
            imm_out          <= 0;
            rs1_addr_out     <= 0;
            rs2_addr_out     <= 0;
            rd_out           <= 0;
            opcode_out       <= 0;
            alu_src_out      <= 0;
            mem_read_out     <= 0;
            mem_write_out    <= 0;
            mem_to_reg_out   <= 0;
            reg_write_out    <= 0;
        end else begin
            pc_out           <= pc_in;
            rs1_out          <= rs1_data_in;
            rs2_out          <= rs2_data_in;
            imm_out          <= imm_in;
            rs1_addr_out     <= rs1_in;
            rs2_addr_out     <= rs2_in;
            rd_out           <= rd_in;
            opcode_out       <= opcode_in;
            alu_src_out      <= alu_src_in;
            mem_read_out     <= mem_read_in;
            mem_write_out    <= mem_write_in;
            mem_to_reg_out   <= mem_to_reg_in;
            reg_write_out    <= reg_write_in;
        end
    end

endmodule