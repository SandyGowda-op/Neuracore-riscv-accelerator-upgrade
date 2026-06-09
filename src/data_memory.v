`timescale 1ns/1ps
module data_memory (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);
    reg [31:0] mem [0:1023]; // 4KB
    integer i;
    initial begin
        if ($fopen("data_memory.mem") != 0) begin
            $display("data_memory: attempting to load init file 'data_memory.mem' ...");
            $readmemh("data_memory.mem", mem);
            $display("data_memory: init complete (depth=1024 words).");
        end
    end
    always @(posedge clk) begin
        if (mem_write) mem[addr[11:2]] <= write_data;
    end
    always @(*) begin
        if (mem_read) read_data = mem[addr[11:2]];
        else read_data = 32'd0;
    end
endmodule
