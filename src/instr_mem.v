module instr_mem (
    input  wire [31:0] addr,
    output wire [31:0] instr
);

    reg [31:0] mem [0:1023];

    initial begin
        $display("instr_mem: attempting to load instruction_memory.mem...");
        $readmemh("instruction_memory.mem", mem);
        $display("instr_mem: load complete.");
    end

    // ✅ CRITICAL FIX
    assign instr = mem[addr[31:2]];

endmodule