`timescale 1ns/1ps

module riscv_pipeline (
    input wire clk,
    input  wire        rst,
    output wire mmul_busy,
    output wire mmul_done,
    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_instr,
    output wire [31:0] dbg_alu,
    output wire [31:0] dbg_dmem_load,
    output wire [31:0] dbg_r1,
    output wire [31:0] dbg_r2,
    output wire [31:0] dbg_r3,
    output wire        dbg_accel_busy
);

    // ============================================================
    // PC (STALL PATCH APPLIED)
    // ============================================================
    reg [31:0] pc_reg;
    wire cpu_stall = dbg_accel_busy;

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_reg <= 32'd0;
        else if (!cpu_stall)
            pc_reg <= pc_reg + 32'd4;
    end

    assign dbg_pc = pc_reg;

    // ============================================================
    // IF stage
    // ============================================================
    wire [31:0] instr_fetched;

    instr_mem instr_mem_inst (
        .addr (pc_reg),
        .instr(instr_fetched)
    );

    wire [31:0] ifid_pc_out;
    wire [31:0] ifid_instr_out;

    if_id if_id_inst (
        .clk(clk),
        .rst(rst),
        .enable(!cpu_stall),   // 🔒 STALL HERE
        .flush(1'b0),
        .pc_in(pc_reg),
        .instr_in(instr_fetched),
        .pc_out(ifid_pc_out),
        .instr_out(ifid_instr_out)
    );

    assign dbg_instr = ifid_instr_out;

    // ============================================================
    // ID stage
    // ============================================================
    wire [6:0] id_opcode = ifid_instr_out[6:0];
    wire [4:0] id_rs1    = ifid_instr_out[19:15];
    wire [4:0] id_rs2    = ifid_instr_out[24:20];
    wire [4:0] id_rd     = ifid_instr_out[11:7];

    wire [31:0] rf_rs1_data, rf_rs2_data;

    wire wb_we;
    wire [4:0] wb_rd;
    wire [31:0] wb_data;

    register_file rf (
        .clk(clk),
        .rst(rst),
        .we_en(wb_we),
        .we_addr(wb_rd),
        .we_data(wb_data),
        .rs1_addr(id_rs1),
        .rs2_addr(id_rs2),
        .rs1_data(rf_rs1_data),
        .rs2_data(rf_rs2_data),
        .dbg_r1(dbg_r1),
        .dbg_r2(dbg_r2),
        .dbg_r3(dbg_r3),
        .dbg_r4(),
        .dbg_r5()
    );

    // ============================================================
    // Immediate generator
    // ============================================================
    wire [31:0] id_imm;
    immediate_gen imm_gen (
        .instr(ifid_instr_out),
        .imm_out(id_imm)
    );

    // ============================================================
    // Control
    // ============================================================
    wire id_mem_read   = (id_opcode == 7'b0000011);
    wire id_mem_write  = (id_opcode == 7'b0100011);
    wire id_reg_write  = (id_opcode == 7'b0110011) |
                          (id_opcode == 7'b0010011) |
                          (id_opcode == 7'b0000011) |
                          (id_opcode == 7'b0110111);

    wire id_mem_to_reg = (id_opcode == 7'b0000011);
    wire id_alu_src    = (id_opcode != 7'b0110011);

    // ============================================================
    // ID / EX
    // ============================================================
    wire [31:0] idex_rs1, idex_rs2, idex_imm;
    wire [4:0]  idex_rd;
    wire [6:0]  idex_opcode;
    wire        idex_mem_read, idex_mem_write, idex_mem_to_reg, idex_reg_write, idex_alu_src;

    id_ex id_ex_inst (
        .clk(clk),
        .rst(rst),
        .flush(1'b0),

        .pc_in(ifid_pc_out),
        .rs1_data_in(rf_rs1_data),
        .rs2_data_in(rf_rs2_data),
        .imm_in(id_imm),
        .rs1_in(id_rs1),
        .rs2_in(id_rs2),
        .rd_in(id_rd),
        .opcode_in(id_opcode),

        .alu_src_in(id_alu_src),
        .mem_read_in(id_mem_read),
        .mem_write_in(id_mem_write),
        .mem_to_reg_in(id_mem_to_reg),
        .reg_write_in(id_reg_write),

        .pc_out(),
        .rs1_out(idex_rs1),
        .rs2_out(idex_rs2),
        .imm_out(idex_imm),
        .rs1_addr_out(),
        .rs2_addr_out(),
        .rd_out(idex_rd),
        .opcode_out(idex_opcode),

        .alu_src_out(idex_alu_src),
        .mem_read_out(idex_mem_read),
        .mem_write_out(idex_mem_write),
        .mem_to_reg_out(idex_mem_to_reg),
        .reg_write_out(idex_reg_write)
    );

    // ============================================================
    // EX stage (LUI FIX PRESERVED)
    // ============================================================
    wire [31:0] alu_b = idex_alu_src ? idex_imm : idex_rs2;

    wire [31:0] alu_result_ex =
        (idex_opcode == 7'b0110111) ? idex_imm :
                                      (idex_rs1 + alu_b);

    assign dbg_alu = alu_result_ex;

    // ============================================================
    // EX / MEM
    // ============================================================
    wire [31:0] exmem_alu;
    wire [31:0] exmem_rs2;
    wire [4:0]  exmem_rd;
    wire        exmem_mem_read, exmem_mem_write, exmem_mem_to_reg, exmem_reg_write;

    ex_mem ex_mem_inst (
        .clk(clk),
        .rst(rst),

        .alu_in(alu_result_ex),
        .rs2_data_in(idex_rs2),
        .rd_in(idex_rd),
        .mem_read_in(idex_mem_read),
        .mem_write_in(idex_mem_write),
        .mem_to_reg_in(idex_mem_to_reg),
        .reg_write_in(idex_reg_write),

        .alu_out(exmem_alu),
        .rs2_data_out(exmem_rs2),
        .rd_out(exmem_rd),
        .mem_read_out(exmem_mem_read),
        .mem_write_out(exmem_mem_write),
        .mem_to_reg_out(exmem_mem_to_reg),
        .reg_write_out(exmem_reg_write)
    );

    // ============================================================
    // MEM stage + MMUL
    // ============================================================
    localparam MMUL_BASE = 32'h00001000;

    wire mmul_sel = (exmem_alu >= MMUL_BASE) &&
                    (exmem_alu <  MMUL_BASE + 32'h100);

    wire [31:0] dmem_rdata;
    data_memory dmem (
        .clk(clk),
        .mem_read(exmem_mem_read & ~mmul_sel),
        .mem_write(exmem_mem_write & ~mmul_sel),
        .addr(exmem_alu),
        .write_data(exmem_rs2),
        .read_data(dmem_rdata)
    );


    mmul_mem mmul_inst (
        .clk(clk),
        .rst(rst),
        .addr(exmem_alu),
        .wdata(exmem_rs2),
        .we(exmem_mem_write & mmul_sel),
        .mmul_busy(mmul_busy),
        .mmul_done(mmul_done)
    );

    assign dbg_accel_busy = mmul_busy;

    wire [31:0] mem_rdata = dmem_rdata;
    assign dbg_dmem_load = mem_rdata;

    // ============================================================
    // MEM / WB
    // ============================================================
    wire [31:0] memwb_mem;
    wire [31:0] memwb_alu;
    wire [4:0]  memwb_rd;
    wire        memwb_mem_to_reg, memwb_reg_write;

    mem_wb mem_wb_inst (
        .clk(clk),
        .rst(rst),
        .enable(!cpu_stall),

        .mem_data_in(mem_rdata),
        .alu_result_in(exmem_alu),
        .rd_in(exmem_rd),
        .mem_to_reg_in(exmem_mem_to_reg),
        .reg_write_in(exmem_reg_write),

        .mem_data_out(memwb_mem),
        .alu_result_out(memwb_alu),
        .rd_out(memwb_rd),
        .mem_to_reg_out(memwb_mem_to_reg),
        .reg_write_out(memwb_reg_write)
    );

    assign wb_we   = memwb_reg_write;
    assign wb_rd   = memwb_rd;
    assign wb_data = memwb_mem_to_reg ? memwb_mem : memwb_alu;

endmodule