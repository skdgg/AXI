`include "../src/Reg_file.sv"
`include "../src/Decoder.sv"
`include "../src/F_Reg_file.sv"
`include "../src/Imm_ext.sv"

module ID_stage(
    input clk,
    input rst,
    input [31:0] D_PC,         // PC from the IF stage
    input [31:0] D_instruction, // Instruction from the IF stage

    // Write-back inputs from the WB stage
    input W_write_enable,    // Write enable from the WB stage
    input W_write_enable_f,    // Write enable from the WB stage
    input [4:0] W_rd, // Write address from the WB stage
    input [31:0] W_rd_data,   // Write data from the WB stage

    output logic [6:0] D_op, 
    output logic [2:0] D_funct3,   
    output logic [4:0] D_rd,       
    output logic [4:0] D_rs1,      
    output logic [4:0] D_rs2,    
    output logic [4:0] D_rd_f,       
    output logic [4:0] D_rs1_f,      
    output logic [4:0] D_rs2_f,
    output logic [31:0] D_rs1_data, 
    output logic [31:0] D_rs2_data, 
    output logic [31:0] D_rs1_data_f, 
    output logic [31:0] D_rs2_data_f, 
    output logic [31:0] D_imm, 
    output logic [4:0] D_alu_control,    
    output logic D_reg_write_enable, 
    output logic D_reg_write_enable_f, 
    output logic D_JAL,             
    output logic D_JALR,    
    output logic D_jb_op1_sel,
    output logic D_alu_op1_sel,   
    output logic D_alu_op2_sel, 
    output logic D_wb_data_sel,   
    output logic [31:0] D_dm_write_enable, 
    output logic D_web   
);

    // Instantiate the Decoder
    Decoder decoder (
        .instruction(D_instruction),
        .opcode(D_op),
        .funct3(D_funct3),
        .rd(D_rd),
        .rs1(D_rs1),
        .rs2(D_rs2),
        .rd_f(D_rd_f),
        .rs1_f(D_rs1_f),
        .rs2_f(D_rs2_f),
        .alu_control(D_alu_control),
        .reg_write_enable(D_reg_write_enable),
        .reg_write_enable_f(D_reg_write_enable_f),
        .jump(D_JAL),
        .jump_register(D_JALR),
        .jb_op1_sel(D_jb_op1_sel),
        .alu_op1_sel(D_alu_op1_sel),
        .alu_op2_sel(D_alu_op2_sel),
        .wb_data_sel(D_wb_data_sel),
        .dm_write_enable(D_dm_write_enable),
        .web(D_web)
    );

    // Instantiate the Register File
    Reg_file reg_file (
        .clk(clk),
        .rst(rst),
        .write_enable(W_write_enable),
        .write_address(W_rd),
        .write_data(W_rd_data),
        .read_address1(D_rs1),
        .read_data1(D_rs1_data),
        .read_address2(D_rs2),
        .read_data2(D_rs2_data)
    );

    // Instantiate the Floating-Point Register File
    F_Reg_file f_reg_file (
        .clk(clk),
        .rst(rst),
        .W_wb_en_f(W_write_enable_f),
        .rs1_index_f(D_rs1_f),
        .rs2_index_f(D_rs2_f),
        .W_rd_index_f(W_rd),
        .W_rd_data_f(W_rd_data),
        .rs1_data_f(D_rs1_data_f),
        .rs2_data_f(D_rs2_data_f)
    );

    // Instantiate the Immediate Extender
    Imm_ext imm_ext (
        .D_instruction(D_instruction),
        .immex(D_imm)
    );

endmodule
