module Imm_ext(
    input [31:0] D_instruction, // The 32-bit instruction
    output logic [31:0] immex // The 32-bit sign-extended immex value
);

logic [6:0] opcode;

assign opcode = D_instruction[6:0];

always_comb begin
    case(opcode)
        7'b0000011: immex = {{20{D_instruction[31]}},D_instruction[31:20]}; // LW,LB,LH,LBU,LHU
        7'b0010011: immex = {{20{D_instruction[31]}},D_instruction[31:20]}; // I-type
        7'b1100111: immex = {{20{D_instruction[31]}},D_instruction[31:20]}; // JALR
        7'b0100011: immex = {{20{D_instruction[31]}},D_instruction[31:25],D_instruction[11:7]}; // S-type
        7'b1100011: immex = {{20{D_instruction[31]}},D_instruction[7],D_instruction[30:25],D_instruction[11:8],1'b0}; // B-type
        7'b0010111: immex = {D_instruction[31:12],{12{1'b0}}}; // AUIPC
        7'b0110111: immex = {D_instruction[31:12],{12{1'b0}}}; // LUI
        7'b1101111: immex = {{12{D_instruction[31]}},D_instruction[19:12],D_instruction[20],D_instruction[30:21],1'b0}; // J-type
        7'b1110011: immex = {{20{D_instruction[31]}},D_instruction[31:20]}; // CSR
        7'b0000111: immex = {{20{D_instruction[31]}},D_instruction[31:20]}; // FLW
        7'b0100111: immex = {{20{D_instruction[31]}},D_instruction[31:25],D_instruction[11:7]}; // FSW
        default:    immex = 32'hFFFF_FFFF;
    endcase
end

endmodule
