module forwarding_unit (
    input  logic [4:0] idex_rs1,
    input  logic [4:0] idex_rs2,

    input  logic [4:0] exmem_rd,
    input  logic       exmem_reg_write,

    input  logic [4:0] memwb_rd,
    input  logic       memwb_reg_write,

    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);

always_comb begin

    forward_a = 2'b00;
    forward_b = 2'b00;

    // EX/MEM forwarding has priority
    if (exmem_reg_write &&
        (exmem_rd != 5'd0) &&
        (exmem_rd == idex_rs1))
        forward_a = 2'b10;

    if (exmem_reg_write &&
        (exmem_rd != 5'd0) &&
        (exmem_rd == idex_rs2))
        forward_b = 2'b10;

    // MEM/WB forwarding
    if (memwb_reg_write &&
        (memwb_rd != 5'd0) &&
        !(exmem_reg_write &&
          (exmem_rd != 5'd0) &&
          (exmem_rd == idex_rs1)) &&
        (memwb_rd == idex_rs1))
        forward_a = 2'b01;

    if (memwb_reg_write &&
        (memwb_rd != 5'd0) &&
        !(exmem_reg_write &&
          (exmem_rd != 5'd0) &&
          (exmem_rd == idex_rs2)) &&
        (memwb_rd == idex_rs2))
        forward_b = 2'b01;

end

endmodule