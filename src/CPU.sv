/*
 *  CPU Top Level
 *  This module connects all the pipeline stages together.
 */

`include "../src/IF_stage.sv"
`include "../src/FD_reg.sv"
`include "../src/ID_stage.sv"
`include "../src/DE_reg.sv"
`include "../src/Exe_stage.sv"
`include "../src/EM_reg.sv"
`include "../src/MW_reg.sv"
`include "../src/WB_stage.sv"
`include "../src/Shifter.sv"

module CPU (
    input  logic        clk,
    input  logic        rst,
    input  logic        IM_STOP,
    input  logic        DM_STOP,
    // ------------------------------
    // Instruction Memory (read-only)
    // ------------------------------
    input  logic [31:0] im_instr,  
    output logic [14:0] im_addr,     

    // ------------------------------
    // Data Memory (read/write)
    // ------------------------------
    input  logic [31:0] dm_data_out, 
    output logic [14:0] dm_addr,     
    output logic [31:0] dm_data_in,  
    output logic        dm_web,      
    output logic [31:0] dm_bweb,
    output logic        IM_CEB,      
    output logic        DM_CEB       
);

    logic stall;
    logic flush;

    // IF Stage signals
    logic next_pc_sel;
    logic [31:0] jb_pc;
    logic [31:0] next_pc;
    logic [31:0] F_PC;

    // ID Stage signals
    logic [31:0] D_PC;
    logic [31:0] D_instruction;
    logic [6:0]  D_op;
    logic [2:0]  D_funct3;
    logic [4:0]  D_rd;
    logic [4:0]  D_rs1;
    logic [4:0]  D_rs2;
    logic [4:0]  D_rd_f;
    logic [4:0]  D_rs1_f;
    logic [4:0]  D_rs2_f;
    logic [31:0] D_rs1_data;
    logic [31:0] D_rs2_data;
    logic [31:0] D_rs1_data_f;
    logic [31:0] D_rs2_data_f;
    logic [31:0] D_imm;
    logic [4:0]  D_alu_control;
    logic        D_reg_write_enable;
    logic        D_reg_write_enable_f;
    logic        D_JAL;
    logic        D_JALR;
    logic        D_alu_op1_sel;
    logic        D_alu_op2_sel;
    logic        D_wb_data_sel;
    logic [31:0] D_dm_write_enable;
    logic        D_web;
    logic D_jb_op1_sel;
    // EX Stage signals   
    logic [4:0]  E_rs1;
    logic [2:0]  E_funct3;
    logic [4:0]  E_rs2;
    logic [4:0]  E_rs1_f;
    logic [4:0]  E_rs2_f;
    logic [31:0] E_rs1_data;
    logic [31:0] E_rs2_data;
    logic [31:0] E_rs1_data_f;
    logic [31:0] E_rs2_data_f;
    logic [4:0]  E_rd;
    logic [4:0]  E_rd_f;
    logic [4:0]  E_alu_ctrl;
    logic [31:0] E_PC;
    logic [31:0] E_imm;  
    logic [6:0]  E_op;
    logic [31:0] E_alu_out, E_dm_data;
    logic E_alu_op1_sel;
    logic E_alu_op2_sel;
    logic E_wb_data_sel;
    logic [31:0] E_dm_write_enable;  
    logic E_web;
    // MW Register signals
    logic [31:0] M_dm_data;
    logic [31:0] M_alu_out;
    logic [6:0]  M_op;
    logic [4:0]  M_rd, M_rd_f;
    logic [2:0]  M_funct3;
    logic        M_reg_write_enable, M_reg_write_enable_f;
    logic        M_wb_data_sel;
    logic [31:0] M_dm_write_enable;
    logic [31:0] M_rd_data; 

    // WB Stage signals
    logic        W_reg_write_enable;
    logic        W_reg_write_enable_f;
    logic [31:0] W_rd_data;
    logic [31:0] W_alu_out;
    logic [4:0]  W_rd, W_rd_f;
    logic [2:0]  W_funct3;
    logic        W_wb_data_select;
    logic [31:0] LD_data;

    // branch prediction signals
    logic               F_pred_taken;
    logic [4:0]         F_pht_idx;
    logic               F_btb_hit;
    logic [31:0]        F_btb_target;
    logic               D_pred_taken;
    logic [4:0]         D_pht_idx;
    logic               D_btb_hit;
    logic [31:0]        D_btb_target;
    logic               E_pred_taken;
    logic [4:0]         E_pht_idx;
    logic               E_btb_hit;
    logic [31:0]        E_btb_target;
    logic               ex_update_en;
    logic               ex_actual_taken;
    logic [31:0]        ex_actual_target;
    logic               redirect_valid;
    logic [31:0]        redirect_pc;

    Shifter shifter (
        .next_pc(next_pc),
        .M_alu_out(M_alu_out),
        .M_op(M_op),
        .M_funct3(M_funct3),
        .M_dm_data(M_dm_data),
        .M_dm_write_enable(M_dm_write_enable),
        .im_addr(im_addr),
        .dm_addr(dm_addr),
        .dm_data_in(dm_data_in),
        .dm_bweb(dm_bweb)
    );
    // Instantiate the pipeline stages
    IF_stage if_stage (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        //.next_pc_sel(next_pc_sel),
        //.jb_pc(jb_pc),
        .next_pc(next_pc),
        .F_PC(F_PC),
        .d_rst(d_rst),
        //from EX stage for branch prediction
        .redirect_valid(redirect_valid),
        .redirect_pc(redirect_pc),
        .ex_update_en(ex_update_en),
        .ex_actual_taken(ex_actual_taken),
        .ex_pc(E_PC),
        .ex_actual_target(ex_actual_target),
        .pht_idx_ex(E_pht_idx),
        .F_pred_taken(F_pred_taken),
        .F_pht_idx(F_pht_idx),
        .F_btb_hit(F_btb_hit),
        .F_btb_target(F_btb_target) 
    );

    FD_reg fd_reg (
        .clk(clk),
        .rst(rst),
        .d_rst(d_rst),
        .stall(stall),
        .flush(flush),
        .F_PC(F_PC),
        .F_instruction(im_instr),
        .F_pred_taken(F_pred_taken),
        .F_pht_idx(F_pht_idx),
        .F_btb_hit(F_btb_hit),
        .F_btb_target(F_btb_target),
        .D_PC(D_PC),
        .D_instruction(D_instruction),
        .D_pred_taken(D_pred_taken),
        .D_pht_idx(D_pht_idx),
        .D_btb_hit(D_btb_hit),
        .D_btb_target(D_btb_target)
    );

    ID_stage id_stage (
        .clk                 (clk),
        .rst                 (rst),

        // From IF stage
        .D_PC                (D_PC),
        .D_instruction       (D_instruction),

        // From WB stage
        .W_write_enable      (W_reg_write_enable),
        .W_write_enable_f    (W_reg_write_enable_f),
        .W_rd                (W_rd),
        .W_rd_data           (W_rd_data),

        // Decoded fields / control to next stage
        .D_op                (D_op),
        .D_funct3            (D_funct3),
        .D_rd                (D_rd),
        .D_rs1               (D_rs1),
        .D_rs2               (D_rs2),
        .D_rd_f              (D_rd_f),
        .D_rs1_f             (D_rs1_f),
        .D_rs2_f             (D_rs2_f),

        // Register file read data
        .D_rs1_data          (D_rs1_data),
        .D_rs2_data          (D_rs2_data),
        .D_rs1_data_f        (D_rs1_data_f),
        .D_rs2_data_f        (D_rs2_data_f),

        // Immediate & ALU control
        .D_imm               (D_imm),
        .D_alu_control       (D_alu_control),

        // Write-back / control signals
        .D_reg_write_enable  (D_reg_write_enable),
        .D_reg_write_enable_f(D_reg_write_enable_f),
        .D_JAL               (D_JAL),
        .D_JALR              (D_JALR),
        .D_alu_op1_sel       (D_alu_op1_sel),
        .D_alu_op2_sel       (D_alu_op2_sel),
        .D_wb_data_sel       (D_wb_data_sel),
        .D_jb_op1_sel        (D_jb_op1_sel),
        // Data memory write enables (active-low byte mask & WEB)
        .D_dm_write_enable   (D_dm_write_enable),
        .D_web               (D_web)
    );

    DE_reg de_reg (
        .clk                  (clk),
        .rst                  (rst),
        .stall                (stall),
        .flush                (flush),

        // Inputs from ID stage
        .D_PC                 (D_PC),
        .D_op                 (D_op),
        .D_funct3             (D_funct3),
        .D_rd                 (D_rd),
        .D_rs1                (D_rs1),
        .D_rs2                (D_rs2),
        .D_rd_f               (D_rd_f),
        .D_rs1_f              (D_rs1_f),
        .D_rs2_f              (D_rs2_f),
        .D_rs1_data           (D_rs1_data),
        .D_rs2_data           (D_rs2_data),
        .D_rs1_data_f         (D_rs1_data_f),
        .D_rs2_data_f         (D_rs2_data_f),
        .D_imm                (D_imm),
        .D_alu_control        (D_alu_control),
        .D_reg_write_enable   (D_reg_write_enable),
        .D_reg_write_enable_f (D_reg_write_enable_f),
        .D_JAL                (D_JAL),
        .D_JALR               (D_JALR),
        .D_jb_op1_sel         (D_jb_op1_sel),
        .D_alu_op1_sel        (D_alu_op1_sel),
        .D_alu_op2_sel        (D_alu_op2_sel),
        .D_wb_data_sel        (D_wb_data_sel),
        .D_dm_write_enable    (D_dm_write_enable),
        .D_web                (D_web),
        //branch prediction signals
        .D_pred_taken        (D_pred_taken),
        .D_pht_idx           (D_pht_idx),
        .D_btb_hit           (D_btb_hit),
        .D_btb_target        (D_btb_target),
        // Outputs to EX stage
        .E_PC                 (E_PC),
        .E_op                 (E_op),
        .E_funct3             (E_funct3),
        .E_rd                 (E_rd),
        .E_rs1                (E_rs1),
        .E_rs2                (E_rs2),
        .E_rd_f               (E_rd_f),
        .E_rs1_f              (E_rs1_f),
        .E_rs2_f              (E_rs2_f),
        .E_rs1_data           (E_rs1_data),
        .E_rs2_data           (E_rs2_data),
        .E_rs1_data_f         (E_rs1_data_f),
        .E_rs2_data_f         (E_rs2_data_f),
        .E_imm                (E_imm),
        .E_alu_ctrl           (E_alu_ctrl),
        .E_reg_write_enable   (E_reg_write_enable),
        .E_reg_write_enable_f (E_reg_write_enable_f),
        .E_JAL                (E_JAL),
        .E_JALR               (E_JALR),
        .E_jb_op1_sel         (E_jb_op1_sel),
        .E_alu_op1_sel        (E_alu_op1_sel),
        .E_alu_op2_sel        (E_alu_op2_sel),
        .E_wb_data_sel        (E_wb_data_sel),
        .E_dm_write_enable    (E_dm_write_enable),
        .E_web                (E_web),
        //branch prediction signals
        .E_pred_taken        (E_pred_taken),
        .E_pht_idx           (E_pht_idx),   
        .E_btb_hit           (E_btb_hit),   
        .E_btb_target        (E_btb_target)
    );


    // ======================
    // EXE stage instance
    // ======================
    Exe_stage exe_stage (
        .clk                    (clk),
        .rst                    (rst),
        .E_PC                   (E_PC),
        .E_imm                  (E_imm),
        .E_rs1                  (E_rs1),
        .E_rs2                  (E_rs2),
        .E_rs1_f                (E_rs1_f),
        .E_rs2_f                (E_rs2_f),
        .M_rd                   (M_rd),
        .W_rd                   (W_rd),
        .M_rd_f                 (M_rd_f),
        .W_rd_f                 (W_rd_f),
        .M_reg_write_enable     (M_reg_write_enable),
        .M_reg_write_enable_f   (M_reg_write_enable_f),
        .W_reg_write_enable     (W_reg_write_enable),
        .W_reg_write_enable_f   (W_reg_write_enable_f),

        //branch prediction signals
        .E_pred_taken           (E_pred_taken),
        .E_pht_idx              (E_pht_idx),    
        .E_btb_hit              (E_btb_hit),    
        .E_btb_target           (E_btb_target),
        .redirect_valid         (redirect_valid),
        .redirect_pc            (redirect_pc),
        .ex_update_en           (ex_update_en),
        .ex_actual_taken        (ex_actual_taken),
        .ex_actual_target       (ex_actual_target),
        // Forwarded data
        .E_rs1_data             (E_rs1_data),
        .E_rs2_data             (E_rs2_data),
        .E_rs1_data_f           (E_rs1_data_f),
        .E_rs2_data_f           (E_rs2_data_f),
        .M_rd_data              (M_alu_out),
        .W_rd_data              (W_rd_data),

        .E_JAL                  (E_JAL),
        .E_JALR                 (E_JALR),
        .E_alu_op1_sel          (E_alu_op1_sel),
        .E_alu_op2_sel          (E_alu_op2_sel),
        .E_jb_op1_sel           (E_jb_op1_sel),

        .E_alu_ctrl             (E_alu_ctrl),
        .E_op                   (E_op),
        .E_rd                   (E_rd),
        .E_rd_f                 (E_rd_f),
        .D_rs1                  (D_rs1),
        .D_rs2                  (D_rs2),
        .D_rs1_f                (D_rs1_f),
        .D_rs2_f                (D_rs2_f),

        .flush                  (flush),
        .stall                  (stall),
        .next_pc_sel            (next_pc_sel),
        .E_alu_out              (E_alu_out),
        .E_dm_data              (E_dm_data),
        .jb_pc                  (jb_pc)
    );

    EM_reg em_reg (
        .clk                    (clk),
        .rst                    (rst),

        // Control/ID from EX
        .E_op                   (E_op),
        .E_rd                   (E_rd),
        .E_rd_f                 (E_rd_f),
        .E_alu_ctrl             (E_alu_ctrl),
        .E_funct3               (E_funct3),
        .E_reg_write_enable     (E_reg_write_enable),
        .E_reg_write_enable_f   (E_reg_write_enable_f),
        .E_wb_data_sel          (E_wb_data_sel),
        .E_dm_write_enable      (E_dm_write_enable),
        .E_web                  (E_web),

        // Data from EX
        .E_alu_out              (E_alu_out),
        .E_dm_data              (E_dm_data),

        // To MEM
        .M_op                   (M_op),
        .M_rd                   (M_rd),
        .M_rd_f                 (M_rd_f),
        .M_funct3               (M_funct3),
        .M_reg_write_enable     (M_reg_write_enable),
        .M_reg_write_enable_f   (M_reg_write_enable_f),
        .M_wb_data_sel          (M_wb_data_sel),
        .M_dm_write_enable      (M_dm_write_enable),
        .M_web                  (dm_web),

        // Data to MEM
        .M_alu_out              (M_alu_out),
        .M_dm_data              (M_dm_data)
    );


    MW_reg u_mw_reg (
        .clk                   (clk),
        .rst                   (rst),

        // From MEM stage
        .M_alu_out             (M_alu_out),
        .M_rd                  (M_rd),
        .M_rd_f                (M_rd_f),
        .M_funct3              (M_funct3),
        .M_reg_write_enable    (M_reg_write_enable),
        .M_reg_write_enable_f  (M_reg_write_enable_f),
        .M_wb_data_sel         (M_wb_data_sel),

        // To WB stage
        .W_alu_out             (W_alu_out),
        .W_rd                  (W_rd),
        .W_rd_f                (W_rd_f),
        .W_funct3              (W_funct3),
        .W_reg_write_enable    (W_reg_write_enable),
        .W_reg_write_enable_f  (W_reg_write_enable_f),
        .W_wb_data_sel         (W_wb_data_sel)
    );
    WB_stage u_wb_stage (
        .W_wb_data_sel         (W_wb_data_sel),
        .W_funct3              (W_funct3),
        .LD_data               (dm_data_out),     
        .W_alu_out             (W_alu_out),

        // To register file
        .W_rd_data             (W_rd_data)
    );

endmodule
