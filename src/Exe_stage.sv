/*
 *  Execute Stage
 *  This module executes the instruction, implements forwarding, and detects hazards.
 */

`include "../src/JB_unit.sv"
`include "../src/CSR_reg.sv"
`include "../src/mux3to1.sv"
`include "../src/mux3to1_aluout.sv"
`include "../src/ALU_F.sv"
`include "../src/ALU.sv"

module Exe_stage(
    input clk,
    input rst,

    // branch prediction signals 
    input               E_pred_taken,
    input        [4:0]  E_pht_idx,   
    input               E_btb_hit,   
    input        [31:0] E_btb_target,
    
    input [31:0] E_PC,
    input [31:0] E_imm,
    input [4:0] E_rs1,
    input [4:0] E_rs2,
    input [4:0] E_rs1_f,
    input [4:0] E_rs2_f,
    input [4:0] M_rd,
    input [4:0] W_rd,
    input [4:0] M_rd_f,
    input [4:0] W_rd_f,
    input M_reg_write_enable,
    input M_reg_write_enable_f,
    input W_reg_write_enable,
    input W_reg_write_enable_f,
    // Forwarded data inputs
    input [31:0] E_rs1_data,
    input [31:0] E_rs2_data,
    input [31:0] E_rs1_data_f,
    input [31:0] E_rs2_data_f,
    input [31:0] M_rd_data,
    input [31:0] W_rd_data,

    input E_JAL,
    input E_JALR,
    input E_alu_op1_sel,
    input E_alu_op2_sel,
    input E_jb_op1_sel,

    input [4:0] E_alu_ctrl,
    input [6:0] E_op,
    input [4:0] E_rd,
    input [4:0] E_rd_f,
    input [4:0] D_rs1,
    input [4:0] D_rs2,
    input [4:0] D_rs1_f,
    input [4:0] D_rs2_f,

    output logic flush,
    output logic stall,
    output logic next_pc_sel,
    output logic [31:0] E_alu_out,
    output logic [31:0] E_dm_data,
    output logic [31:0] jb_pc,
    //output for branch predictor update
    output logic redirect_valid,
    output logic [31:0] redirect_pc,
    output logic ex_update_en,
    output logic ex_actual_taken,
    output logic [31:0] ex_actual_target
);

    // Forwarding logic
    logic [31:0] forwarded_rs1_data;
    logic [31:0] forwarded_rs2_data;
    logic [31:0] forwarded_rs1_data_f;
    logic [31:0] forwarded_rs2_data_f;
    //ALU control signals
    logic [31:0] alu_in1;
    logic [31:0] alu_in2;
    logic pc_flag;
    logic [31:0] JB_src;
    logic is_branch;
    logic mis_dir;
    logic mis_tgt;
    logic mispredict;

    logic [31:0] E_alu;
    logic [31:0] E_alu_f;
    logic [31:0] E_csr;
    logic predT_actNT_nohit;
    logic dir_needs_flush;

    logic dm_sel;

    always_comb begin
        dm_sel = (E_op == 7'b0100111);
    end
    always_comb begin
        ex_actual_target = jb_pc;
        is_branch = (E_op == 7'b1100011);         // RISC-V B-type
        ex_actual_taken = (E_JAL | E_JALR) ? 1'b1
                        : (is_branch ? pc_flag : 1'b0);
        ex_update_en = (is_branch | E_JAL | E_JALR);
        mis_dir = (ex_actual_taken != E_pred_taken);
        predT_actNT_nohit = (~ex_actual_taken) & E_pred_taken & (~E_btb_hit);
        dir_needs_flush = mis_dir & ~predT_actNT_nohit;
        mis_tgt = (ex_actual_taken & E_pred_taken) &
                ( (!E_btb_hit) | (E_btb_target != ex_actual_target) );
        mispredict = dir_needs_flush | mis_tgt;
    end

    always_comb begin
        redirect_valid = mispredict;
        redirect_pc    = ex_actual_taken ? ex_actual_target
                                            : (E_PC + 32'd4);
    end

    always_comb begin
        //flush       = pc_flag || E_JAL || E_JALR;
        flush       =  mispredict;

        stall       = ((E_op == 7'b0000011) && 
                    ((E_rd   == D_rs1)   || (E_rd   == D_rs2)))
                || ((E_op == 7'b0000111) && 
                    ((E_rd_f == D_rs1_f) || (E_rd_f == D_rs2_f)));

        next_pc_sel = pc_flag || E_JAL || E_JALR;
    end
    // Forwarding multiplexers
    mux3to1 mux_forward_rs1(
        .E_rs(E_rs1),
        .M_rd(M_rd),
        .W_rd(W_rd),
        .M_RegWrite(M_reg_write_enable),
        .W_RegWrite(W_reg_write_enable),
        .E_rs_data(E_rs1_data),
        .M_rd_data(M_rd_data),
        .W_rd_data(W_rd_data),
        .newest_rs_data(forwarded_rs1_data)
    );

    mux3to1 mux_forward_rs2(
        .E_rs(E_rs2),
        .M_rd(M_rd),
        .W_rd(W_rd),
        .M_RegWrite(M_reg_write_enable),
        .W_RegWrite(W_reg_write_enable),
        .E_rs_data(E_rs2_data),
        .M_rd_data(M_rd_data),
        .W_rd_data(W_rd_data),
        .newest_rs_data(forwarded_rs2_data)
    );

    mux3to1 mux_forward_rs1_f(
        .E_rs(E_rs1_f),
        .M_rd(M_rd_f),
        .W_rd(W_rd_f),
        .M_RegWrite(M_reg_write_enable_f),
        .W_RegWrite(W_reg_write_enable_f),
        .E_rs_data(E_rs1_data_f),
        .M_rd_data(M_rd_data),
        .W_rd_data(W_rd_data),
        .newest_rs_data(forwarded_rs1_data_f)
    );

    mux3to1 mux_forward_rs2_f(
        .E_rs(E_rs2_f),
        .M_rd(M_rd_f),
        .W_rd(W_rd_f),
        .M_RegWrite(M_reg_write_enable_f),
        .W_RegWrite(W_reg_write_enable_f),
        .E_rs_data(E_rs2_data_f),
        .M_rd_data(M_rd_data),
        .W_rd_data(W_rd_data),
        .newest_rs_data(forwarded_rs2_data_f)
    );


    mux2to1 mux2to1_ALUsrc1(
        .in0(forwarded_rs1_data),
        .in1(E_PC),
        .sel(E_alu_op1_sel),
        .out(alu_in1)
    );

    mux2to1 mux2to1_ALUsrc2(
        .in0(forwarded_rs2_data),
        .in1(E_imm),
        .sel(E_alu_op2_sel),
        .out(alu_in2)
    );

    // Instantiate the ALU
    ALU alu (
        .alu_control(E_alu_ctrl),
        .alu_in1(alu_in1),
        .alu_in2(alu_in2),
        .alu_out(E_alu),
        .pc_flag(pc_flag)
    );

    // Instantiate the Floating-Point ALU
    ALU_F alu_f (
        .ALU_ctrl(E_alu_ctrl),
        .ALU_in1_f(forwarded_rs1_data_f),
        .ALU_in2_f(forwarded_rs2_data_f),
        .ALU_out_f(E_alu_f)
    );

    // Instantiate the CSR unit
    CSR_reg csr_unit (
        .clk(clk),
        .rst(rst),
        .pc(E_PC),
        .immex(E_imm),
        .csr_out(E_csr)
    );
    mux2to1 mux2to1_jbsrc(
        .in0(forwarded_rs1_data),
        .in1(E_PC),
        .sel(E_jb_op1_sel),
        .out(JB_src)
    );
    JB_unit JB_unit(
        .in_1(JB_src),
        .in_2(E_imm),
        .JALR(E_JALR),
        .jb_pc(jb_pc)
    );

    mux2to1 mux2to1_DM_sel(
        .in0(forwarded_rs2_data),
        .in1(forwarded_rs2_data_f),
        .sel(dm_sel),
        .out(E_dm_data)
    );

    mux3to1_aluout mux_aluout(
        .E_op(E_op),
        .E_alu_ctrl(E_alu_ctrl),
        .E_alu_f(E_alu_f),
        .E_alu(E_alu),
        .E_csr(E_csr),
        .E_alu_out(E_alu_out)
    );
endmodule
