module EM_reg(
    input clk,
    input rst,

    // Inputs from the EX stage
    input [6:0] E_op,
    input [4:0] E_rd,
    input [4:0] E_rd_f,
    input [4:0] E_alu_ctrl,
    input [2:0] E_funct3,
    input E_reg_write_enable,
    input E_reg_write_enable_f,
    input E_wb_data_sel,
    input [31:0] E_dm_write_enable,
    input E_web,
    // Data inputs from the EX stage
    input [31:0] E_alu_out,
    input [31:0] E_dm_data,
    // Outputs to the MEM stage
    output logic [6:0] M_op,
    output logic [4:0] M_rd,
    output logic [4:0] M_rd_f,
    output logic [2:0] M_funct3,
    output logic M_reg_write_enable,
    output logic M_reg_write_enable_f,
    output logic M_wb_data_sel,
    output logic [31:0] M_dm_write_enable,
    output logic M_web,
    // Data outputs to the MEM stage
    output logic [31:0] M_alu_out,
    output logic [31:0] M_dm_data
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            M_op <= 7'd0;
            M_funct3 <= 3'd0;
            M_rd <= 5'd0;
            M_rd_f <= 5'd0;
            M_reg_write_enable <= 1'b0;
            M_reg_write_enable_f <= 1'b0;
            M_wb_data_sel <= 1'b0;
            M_dm_write_enable <= 32'd0;
            M_web <= 1'b0;
            M_alu_out <= 32'd0;
            M_dm_data <= 32'd0;
        end else begin
            M_op <= E_op;
            M_alu_out <= E_alu_out;
            M_dm_data <= E_dm_data;
            M_rd <= E_rd;
            M_rd_f <= E_rd_f;
            M_funct3 <= E_funct3;
            M_reg_write_enable <= E_reg_write_enable;
            M_reg_write_enable_f <= E_reg_write_enable_f;
            M_wb_data_sel <= E_wb_data_sel;
            M_dm_write_enable <= E_dm_write_enable;
            M_web <= E_web;
        end
    end

endmodule
