module relu_unit(
    input  wire [31:0] in_data,
    output wire [31:0] out_data
);

assign out_data =
    in_data[31] ? 32'd0 : in_data;

endmodule