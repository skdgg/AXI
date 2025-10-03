module JB_unit(
    input [31:0] in_1,
    input [31:0] in_2,
    input JALR,

    output logic [31:0] jb_pc
);

logic [31:0] base;

always_comb
begin
    base = in_1 + in_2;
    if(JALR)
        jb_pc = {base[31:1],1'b0};
    else
        jb_pc = base;
end

endmodule
