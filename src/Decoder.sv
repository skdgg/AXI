module Decoder(
    input [31:0] instruction, // The 32-bit instruction

    // Instruction fields
    output logic [6:0] opcode, // Opcode field
    output logic [2:0] funct3,   // Funct3 field
    output logic [4:0] rd,       // Destination register field
    output logic [4:0] rs1,      // Source register 1 field
    output logic [4:0] rs2,      // Source register 2 field
    //floating point register fields
    output logic [4:0] rd_f,
    output logic [4:0] rs1_f,
    output logic [4:0] rs2_f,

    // Control signals
    output logic [4:0] alu_control,    // Control signal for the ALU
    output logic reg_write_enable, // Enables writing to the register file
    output logic reg_write_enable_f, // Enables writing to the floating-point register file
    output logic jump,             // Jump signal
    output logic jump_register,    // Jump register signal
    output logic jb_op1_sel,
    output logic alu_op1_sel,   // ALU operand 1 selector
    output logic alu_op2_sel,   // ALU operand 2 selector
    output logic wb_data_sel,   // Write-back data selector
    output logic [31:0] dm_write_enable, // Memory write enable
    output logic web     // Memory write web
);

// Internal logic for funct7 field
logic [6:0] funct7;

// Extract instruction fields
always_comb begin
    opcode = instruction[6:0];
    funct3 = instruction[14:12];
    rd = instruction[11:7];
    rs1 = instruction[19:15];
    rs2 = instruction[24:20];
    rd_f   = instruction[11:7];
    rs1_f  = instruction[19:15];
    rs2_f  = instruction[24:20];
    funct7 = instruction[31:25];
end

always_comb
begin
    case(opcode)
    7'b0110011:begin // R-type
        reg_write_enable = 1'b1;
        reg_write_enable_f = 1'b0;
        jump = 1'b0;
        jump_register = 1'b0;
        wb_data_sel = 1'b0;
        jb_op1_sel = 1'b0; // don't care
        alu_op1_sel = 1'b0;
        alu_op2_sel = 1'b0;
        dm_write_enable = 32'hFFFF_FFFF;
        web = 1'b1;
    end
    7'b0000011:begin // Load
        reg_write_enable = 1'b1;
        reg_write_enable_f = 1'b0;
        jump = 1'b0;
        jump_register = 1'b0;
        wb_data_sel = 1'b1;
        jb_op1_sel = 1'b0; // don't care
        alu_op1_sel = 1'b0;
        alu_op2_sel = 1'b1;
        dm_write_enable = 32'hFFFF_FFFF;
        web = 1'b1;
    end
    7'b0010011:begin // I-type
        reg_write_enable = 1'b1;
        reg_write_enable_f = 1'b0;
        jump = 1'b0;
        jump_register = 1'b0;
        wb_data_sel = 1'b0;
        jb_op1_sel = 1'b0; // don't care
        alu_op1_sel = 1'b0;
        alu_op2_sel = 1'b1;
        dm_write_enable = 32'hFFFF_FFFF;
        web = 1'b1;
    end
    7'b1100111:begin // JALR
        reg_write_enable = 1'b1;
        reg_write_enable_f = 1'b0;
        jump = 1'b0;
        jump_register = 1'b1;
        wb_data_sel = 1'b0;
        jb_op1_sel = 1'b0;
        alu_op1_sel = 1'b1;
        alu_op2_sel = 1'b0; // don't care
        dm_write_enable = 32'hFFFF_FFFF;
        web = 1'b1;
    end
    7'b0100011:begin // S-type
        reg_write_enable = 1'b0;
        reg_write_enable_f = 1'b0;
        jump = 1'b0;
        jump_register = 1'b0;
        wb_data_sel = 1'b0; // don't care
        jb_op1_sel = 1'b0; // don't care
        alu_op1_sel = 1'b0;
        alu_op2_sel = 1'b1;
        case(funct3)
        3'b000:  dm_write_enable = 32'hFFFF_FF00;
        3'b001:  dm_write_enable = 32'hFFFF_0000;
        3'b010:  dm_write_enable = 32'h0000_0000;
        default: dm_write_enable = 32'hFFFF_FFFF;
        endcase
        web = 1'b0;
    end
    7'b1100011:begin //B-type
        reg_write_enable = 1'b0;
        reg_write_enable_f = 1'b0;
        jump = 1'b0;
        jump_register = 1'b0;
        wb_data_sel = 1'b0; // don't care
        jb_op1_sel = 1'b1;
        alu_op1_sel = 1'b0;
        alu_op2_sel = 1'b0;
        dm_write_enable = 32'hFFFF_FFFF;
        web = 1'b1;
    end
    7'b0010111:begin // AUIPC
        reg_write_enable = 1'b1;
        reg_write_enable_f = 1'b0;
        jump = 1'b0;
        jump_register = 1'b0;
        wb_data_sel = 1'b0;
        jb_op1_sel = 1'b0; // don't care
        alu_op1_sel = 1'b1;
        alu_op2_sel = 1'b1;
        dm_write_enable = 32'hFFFF_FFFF;
        web = 1'b1;
    end
    7'b0110111:begin // LUI
        reg_write_enable = 1'b1;
        reg_write_enable_f = 1'b0;
        jump = 1'b0;
        jump_register = 1'b0;
        wb_data_sel = 1'b0;
        jb_op1_sel = 1'b0; // don't care
        alu_op1_sel = 1'b1; // don't care
        alu_op2_sel = 1'b1;
        dm_write_enable = 32'hFFFF_FFFF;
        web = 1'b1;
    end
    7'b1101111:begin // JAL
        reg_write_enable = 1'b1;
        reg_write_enable_f = 1'b0;
        jump = 1'b1;
        jump_register = 1'b0;
        wb_data_sel = 1'b0;
        jb_op1_sel = 1'b1;
        alu_op1_sel = 1'b1; 
        alu_op2_sel = 1'b1; // don't care
        dm_write_enable = 32'hFFFF_FFFF;
        web = 1'b1;
    end
    7'b1110011:begin //CSR
        reg_write_enable = 1'b1;
        reg_write_enable_f = 1'b0;
        jump = 1'b0;
        jump_register = 1'b0;
        wb_data_sel = 1'b0;
        jb_op1_sel = 1'b0; // don't care
        alu_op1_sel = 1'b0; // don't care 
        alu_op2_sel = 1'b0; // don't care
        dm_write_enable = 32'hFFFF_FFFF;
        web = 1'b1;
    end
    7'b0000111:begin // FLW
        reg_write_enable = 1'b0;
        reg_write_enable_f = 1'b1;
        jump = 1'b0;
        jump_register = 1'b0;
        wb_data_sel = 1'b1;
        jb_op1_sel = 1'b0; // don't care
        alu_op1_sel = 1'b0;
        alu_op2_sel = 1'b1;
        dm_write_enable = 32'hFFFF_FFFF;
        web = 1'b1;
    end
    7'b0100111:begin // FSW
        reg_write_enable = 1'b0;
        reg_write_enable_f = 1'b0;
        jump = 1'b0;
        jump_register = 1'b0;
        wb_data_sel = 1'b0; // don't care
        jb_op1_sel = 1'b0; // don't care
        alu_op1_sel = 1'b0;
        alu_op2_sel = 1'b1;
        dm_write_enable = 32'h0000_0000;
        web = 1'b0;
    end
    7'b1010011:begin // FADD.S FSUB.S
        reg_write_enable = 1'b0;
        reg_write_enable_f = 1'b1;
        jump = 1'b0;
        jump_register = 1'b0;
        wb_data_sel = 1'b0; // don't care
        jb_op1_sel = 1'b0; // don't care
        alu_op1_sel = 1'b0; // don't care
        alu_op2_sel = 1'b0; // don't care
        dm_write_enable = 32'hFFFF_FFFF;
        web = 1'b1;
    end
    default:begin
        reg_write_enable = 1'b0;
        reg_write_enable_f = 1'b0;
        jump = 1'b0;
        jump_register = 1'b0;
        wb_data_sel = 1'b0;
        jb_op1_sel = 1'b0;
        alu_op1_sel = 1'b0;
        alu_op2_sel = 1'b0;
        dm_write_enable = 32'hFFFF_FFFF;
        web = 1'b1;
    end
    endcase
end


// Generate control signals based on opcode
always_comb begin
    case (opcode)
        // R-type instructions
        7'b0110011: begin
            if(funct7 == 7'b0000001) begin // M-extension
                case(funct3)
                    3'b000: alu_control = 5'b10001; // MUL
                    3'b001: alu_control = 5'b10010; // MULH
                    3'b010: alu_control = 5'b10011; // MULHSU
                    3'b011: alu_control = 5'b10100; // MULHU
                    default: alu_control = 5'b0; // Default to ADD
                endcase
            end else begin
                case(funct3)
                    3'b000: begin // ADD/SUB
                        if (funct7 == 7'b0100000) alu_control = 5'b00001; // SUB
                        else alu_control = 5'b00000; // ADD
                    end
                    3'b001: alu_control = 5'b00010; // SLL
                    3'b010: alu_control = 5'b00011; // SLT
                    3'b011: alu_control = 5'b00100; // SLTU
                    3'b100: alu_control = 5'b00101; // XOR
                    3'b101: begin // SRL/SRA
                        if (funct7 == 7'b0100000) alu_control = 5'b00111; // SRA
                        else alu_control = 5'b00110; // SRL
                    end
                    3'b110: alu_control = 5'b01000; // OR
                    3'b111: alu_control = 5'b01001; // AND
                endcase
            end
        end

        // I-type instructions (e.g., ADDI, LW)
        7'b0010011: begin
            case(funct3)
                3'b000: alu_control = 5'b00000; // ADDI
                3'b010: alu_control = 5'b00011; // SLTI
                3'b011: alu_control = 5'b00100; // SLTIU
                3'b100: alu_control = 5'b00101; // XORI
                3'b110: alu_control = 5'b01000; // ORI
                3'b111: alu_control = 5'b01001; // ANDI
                3'b001: alu_control = 5'b00010; // SLLI
                3'b101: begin // SRLI/SRAI
                    if (funct7 == 7'b0100000) alu_control = 5'b00111; // SRAI
                    else alu_control = 5'b00110; // SRLI
                end
            endcase
        end

        // I-type instructions (LW)
        7'b0000011: begin
            alu_control = 5'b00000; // ADD for address calculation
        end

        // S-type instructions (e.g., SW)
        7'b0100011: begin
            alu_control = 5'b00000; // ADD for address calculation
        end

        // B-type instructions (e.g., BEQ)
        7'b1100011: begin
            case(funct3)
                3'b000: alu_control = 5'b01011; // BEQ
                3'b001: alu_control = 5'b01100; // BNE
                3'b100: alu_control = 5'b01101; // BLT
                3'b101: alu_control = 5'b01110; // BGE
                3'b110: alu_control = 5'b01111; // BLTU
                3'b111: alu_control = 5'b10000; // BGEU
                default:alu_control = 5'b11111; // default
            endcase
        end

        // J-type instructions (JAL)
        7'b1101111: begin
            alu_control = 5'b01010; // JAL
        end

        // LUI instruction
        7'b0110111: begin
            alu_control = 5'b10101; // LUI
        end

        // AUIPC instruction
        7'b0010111: begin
            alu_control = 5'b00000; // ADD
        end

        // JALR instruction
        7'b1100111: begin
            alu_control = 5'b01010; // JALR
        end

        // Floating-point Load
        7'b0000111: begin // FLW
            alu_control = 5'b00000; // ADD for address calculation
        end

        // Floating-point Store
        7'b0100111: begin // FSW
            alu_control = 5'b00000; // ADD for address calculation
        end

        // Floating-point R-type
        7'b1010011: begin // FADD.S, FSUB.S
            if (funct7 == 7'b0000000) alu_control = 5'b10110; // FADD.S
            else alu_control = 5'b10111; // FSUB.S
        end

        default: begin
            alu_control = 5'b11111;
        end
    endcase
end

endmodule