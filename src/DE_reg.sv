/*
 *  Decode/Execute Pipeline Register
 */
module DE_reg(
    input clk,
    input rst,
    input stall,
    input flush,

    // Inputs from the ID stage
    input [31:0] D_PC,
    input [6:0] D_op,
    input [2:0] D_funct3,
    input [4:0] D_rd,
    input [4:0] D_rs1,
    input [4:0] D_rs2,
    input [4:0] D_rd_f,
    input [4:0] D_rs1_f,
    input [4:0] D_rs2_f,
    input [31:0] D_rs1_data,
    input [31:0] D_rs2_data,
    input [31:0] D_rs1_data_f,
    input [31:0] D_rs2_data_f,
    input [31:0] D_imm,
    input [4:0] D_alu_control,
    input D_reg_write_enable,
    input D_reg_write_enable_f,
    input D_JAL,
    input D_JALR,
    input D_jb_op1_sel,
    input D_alu_op1_sel,
    input D_alu_op2_sel,
    input D_wb_data_sel,
    input [31:0] D_dm_write_enable,
    input D_web,
    //branch prediction signals
    input               D_pred_taken,
    input        [4:0]  D_pht_idx,
    input               D_btb_hit,
    input        [31:0] D_btb_target,

    // Outputs to the EX stage
    output logic [31:0] E_PC,
    output logic [6:0] E_op,
    output logic [2:0] E_funct3,
    output logic [4:0] E_rd,
    output logic [4:0] E_rs1,
    output logic [4:0] E_rs2,
    output logic [4:0] E_rd_f,
    output logic [4:0] E_rs1_f,
    output logic [4:0] E_rs2_f,
    output logic [31:0] E_rs1_data,
    output logic [31:0] E_rs2_data,
    output logic [31:0] E_rs1_data_f,
    output logic [31:0] E_rs2_data_f,
    output logic [31:0] E_imm,
    output logic [4:0] E_alu_ctrl,
    output logic E_reg_write_enable,
    output logic E_reg_write_enable_f,
    output logic E_JAL,
    output logic E_JALR,
    output logic E_jb_op1_sel,
    output logic E_alu_op1_sel,
    output logic E_alu_op2_sel,
    output logic E_wb_data_sel,
    output logic [31:0] E_dm_write_enable,
    output logic E_web,
    //branch prediction signals
    output logic        E_pred_taken,
    output logic [4:0]  E_pht_idx,   
    output logic        E_btb_hit,   
    output logic [31:0] E_btb_target
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            E_PC <= 32'd0;
            E_op <= 7'd0;
            E_funct3 <= 3'd0;
            E_rd <= 5'd0;
            E_rs1 <= 5'd0;
            E_rs2 <= 5'd0;
            E_rs1_data <= 32'd0;
            E_rs2_data <= 32'd0;
            E_rs1_data_f <= 32'd0;
            E_rs2_data_f <= 32'd0;
            E_imm <= 32'd0;
            E_alu_ctrl <= 5'd0;
            E_reg_write_enable <= 1'b0;
            E_reg_write_enable_f <= 1'b0;
            E_JAL <= 1'b0;
            E_JALR <= 1'b0;
            E_jb_op1_sel <= 1'b0;  
            E_alu_op1_sel <= 1'b0;
            E_alu_op2_sel <= 1'b0;
            E_wb_data_sel <= 1'b0;
            E_dm_write_enable <= 32'd0;
            E_web <= 1'b0;
            E_rd_f <= 5'd0;
            E_rs1_f <= 5'd0;
            E_rs2_f <= 5'd0;
            E_pred_taken <= 1'b0;
            E_pht_idx <= 5'd0;
            E_btb_hit <= 1'b0;
            E_btb_target <= 32'd0;
        end else if (flush || stall) begin
            // On flush, or stall, insert a bubble (no-op)
            E_PC <= 32'd0;
            E_op <= 7'd0;
            E_funct3 <= 3'd0;
            E_rd <= 5'd0;
            E_rs1 <= 5'd0;
            E_rs2 <= 5'd0;
            E_rs1_data <= 32'd0;
            E_rs2_data <= 32'd0;
            E_rs1_data_f <= 32'd0;
            E_rs2_data_f <= 32'd0;
            E_imm <= 32'd0;
            E_alu_ctrl <= 5'd0;
            E_reg_write_enable <= 1'b0;
            E_reg_write_enable_f <= 1'b0;
            E_JAL <= 1'b0;
            E_JALR <= 1'b0;
            E_jb_op1_sel <= 1'b0;
            E_alu_op1_sel <= 1'b0;
            E_alu_op2_sel <= 1'b0;
            E_wb_data_sel <= 1'b0;
            E_dm_write_enable <= 32'hFFFF_FFFF;
            E_web <= 1'b1;
            E_rd_f <= 5'd0;
            E_rs1_f <= 5'd0;
            E_rs2_f <= 5'd0;
            E_pred_taken <= 1'b0;
            E_pht_idx <= 5'd0;
            E_btb_hit <= 1'b0;  
            E_btb_target <= 32'd0;
        end else begin
            // Pass data from ID to EX
            E_PC <= D_PC;
            E_op <= D_op;
            E_funct3 <= D_funct3;
            E_rd <= D_rd;
            E_rs1 <= D_rs1;
            E_rs2 <= D_rs2;
            E_rs1_data <= D_rs1_data;
            E_rs2_data <= D_rs2_data;
            E_rs1_data_f <= D_rs1_data_f;
            E_rs2_data_f <= D_rs2_data_f;
            E_imm <= D_imm;
            E_alu_ctrl <= D_alu_control;
            E_reg_write_enable <= D_reg_write_enable;
            E_reg_write_enable_f <= D_reg_write_enable_f;
            E_JAL <= D_JAL;
            E_JALR <= D_JALR;
            E_jb_op1_sel <= D_jb_op1_sel; 
            E_alu_op1_sel <= D_alu_op1_sel;
            E_alu_op2_sel <= D_alu_op2_sel;
            E_wb_data_sel <= D_wb_data_sel;
            E_dm_write_enable <= D_dm_write_enable;
            E_web <= D_web;
            E_rd_f <= D_rd_f;
            E_rs1_f <= D_rs1_f;
            E_rs2_f <= D_rs2_f;
            E_pred_taken <= D_pred_taken;
            E_pht_idx <= D_pht_idx;
            E_btb_hit <= D_btb_hit;
            E_btb_target <= D_btb_target;
        end
    end

endmodule
