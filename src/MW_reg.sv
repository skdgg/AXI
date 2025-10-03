module MW_reg(
    input clk,
    input rst,

    // Inputs from the MEM stage
    input [31:0] M_alu_out,
    input [4:0] M_rd,
    input [4:0] M_rd_f,
    input [2:0] M_funct3,
    input M_reg_write_enable,
    input M_reg_write_enable_f,
    input M_wb_data_sel,

    // Outputs to the WB stage
    output logic [31:0] W_alu_out,
    output logic [4:0] W_rd,
    output logic [4:0] W_rd_f,
    output logic [2:0] W_funct3,
    output logic W_reg_write_enable,
    output logic W_reg_write_enable_f,
    output logic W_wb_data_sel
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            W_alu_out <= 32'd0;
            W_rd <= 5'd0;
            W_rd_f <= 5'd0;
            W_funct3 <= 3'd0;
            W_reg_write_enable <= 1'b0;
            W_reg_write_enable_f <= 1'b0;
            W_wb_data_sel <= 1'b0;
        end else begin
            W_alu_out <= M_alu_out;
            W_rd <= M_rd;
            W_rd_f <= M_rd_f;
            W_funct3 <= M_funct3;
            W_reg_write_enable <= M_reg_write_enable;
            W_reg_write_enable_f <= M_reg_write_enable_f;
            W_wb_data_sel <= M_wb_data_sel;
        end
    end

endmodule
