module PC_adder (
    input  [31:0] in_a,
    input  [31:0] in_b,
    output [31:0] sum_out
);

    // Generic 2-input adder
    assign sum_out = in_a + in_b;

endmodule
