module hazard_detection_unit (

    input  wire [4:0] ifid_rs1,
    input  wire [4:0] ifid_rs2,

    input  wire [4:0] idex_rd,
    input  wire       idex_mem_read,

    input wire ifid_branch,

    output reg        pc_write,
    output reg        ifid_write,
    output reg        idex_flush

);
wire branch_load_hazard;

always @(*) begin

    // Default: normal execution
    pc_write   = 1'b1;
    ifid_write = 1'b1;
    idex_flush = 1'b0;
`ifndef SYNTHESIS
    $display(
"HZD: mem_read=%b idex_rd=%0d ifid_rs1=%0d ifid_rs2=%0d stall=%b",
idex_mem_read,
idex_rd,
ifid_rs1,
ifid_rs2,
(idex_mem_read &&
 (idex_rd != 0) &&
 ((idex_rd == ifid_rs1) ||
  (idex_rd == ifid_rs2)))
);
`endif 
    // Load-use hazard detection
    if (idex_mem_read &&
        (idex_rd != 0) &&
        ((idex_rd == ifid_rs1) ||
         (idex_rd == ifid_rs2))) begin

        pc_write   = 1'b0;
        ifid_write = 1'b0;
        idex_flush = 1'b1;
    end
end

endmodule