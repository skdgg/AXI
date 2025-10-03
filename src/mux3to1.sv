module mux3to1(
    input [4:0] E_rs,
    input [4:0] M_rd,
    input [4:0] W_rd,
    input M_RegWrite,
    input W_RegWrite,
    input [31:0] E_rs_data,
    input [31:0] M_rd_data,
    input [31:0] W_rd_data,

    output logic [31:0] newest_rs_data
);

always_comb
begin
    if(E_rs == M_rd && M_RegWrite && E_rs != 5'd0) newest_rs_data = M_rd_data;
    else if(E_rs == W_rd && W_RegWrite && E_rs != 5'd0) newest_rs_data = W_rd_data;
    else newest_rs_data = E_rs_data;
end

endmodule
