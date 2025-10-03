module mux2to1_PC(
    input [31:0] in0,
    input [31:0] in1,
    input [31:0] F_PC,
    input d_rst,
    input next_pc_sel,
    input stall,
    output logic [31:0] out
);

always_comb
    begin
        if(stall)            out = F_PC;
        else if(~d_rst)      out = 32'd0;
        else if(next_pc_sel) out = in1;
        else                 out = in0;
    end


endmodule
