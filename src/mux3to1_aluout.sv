module mux3to1_aluout(
    input [6:0] E_op,
    input [4:0] E_alu_ctrl,
    input [31:0] E_alu_f,
    input [31:0] E_alu,
    input [31:0] E_csr,

    output logic [31:0] E_alu_out
);

    logic sel_alu_f, sel_csr, sel_alu;

    assign sel_alu_f = (E_alu_ctrl == 5'd22 || E_alu_ctrl == 5'd23);
    assign sel_csr  = ((sel_alu_f != 1'd1) && E_op == 7'b1110011);
    assign sel_alu  = ~(sel_alu_f | sel_csr); 


    always_comb begin
        E_alu_out = ({32{sel_alu_f}} & E_alu_f) | ({32{sel_csr}} & E_csr) | ({32{sel_alu}} & E_alu);
    end

endmodule
