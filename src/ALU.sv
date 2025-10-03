module ALU(
    input  logic [4:0]  alu_control,
    input  logic [31:0] alu_in1,
    input  logic [31:0] alu_in2,
    output logic [31:0] alu_out,
    output logic        pc_flag
);

  logic sel_ADD, sel_SUB, sel_SLL, sel_SLT, sel_SLTU, sel_XOR, sel_SRL, sel_SRA;
  logic sel_OR,  sel_AND, sel_JLINK, sel_BEQ, sel_BNE, sel_BLT, sel_BGE, sel_BLTU, sel_BGEU;
  logic sel_MUL, sel_MULH, sel_MULHSU, sel_MULHU, sel_LUI;

  assign sel_ADD   = (alu_control == 5'b00000); 
  assign sel_SUB   = (alu_control == 5'b00001);
  assign sel_SLL   = (alu_control == 5'b00010);
  assign sel_SLT   = (alu_control == 5'b00011);
  assign sel_SLTU  = (alu_control == 5'b00100);
  assign sel_XOR   = (alu_control == 5'b00101);
  assign sel_SRL   = (alu_control == 5'b00110);
  assign sel_SRA   = (alu_control == 5'b00111);
  assign sel_OR    = (alu_control == 5'b01000);
  assign sel_AND   = (alu_control == 5'b01001);
  assign sel_JLINK = (alu_control == 5'b01010); 
  assign sel_BEQ   = (alu_control == 5'b01011);
  assign sel_BNE   = (alu_control == 5'b01100);
  assign sel_BLT   = (alu_control == 5'b01101);
  assign sel_BGE   = (alu_control == 5'b01110);
  assign sel_BLTU  = (alu_control == 5'b01111);
  assign sel_BGEU  = (alu_control == 5'b10000);
  assign sel_MUL   = (alu_control == 5'b10001);
  assign sel_MULH  = (alu_control == 5'b10010);
  assign sel_MULHSU= (alu_control == 5'b10011);
  assign sel_MULHU = (alu_control == 5'b10100);
  assign sel_LUI   = (alu_control == 5'b10101);

  logic [31:0] add_r, sub_r, sll_r, srl_r, sra_r, xor_r, or_r, and_r, slt_r, sltu_r, jlink_r, lui_r;
  assign add_r   = alu_in1 + alu_in2;
  assign sub_r   = $signed(alu_in1) - $signed(alu_in2);
  assign sll_r   = alu_in1 <<  alu_in2[4:0];
  assign srl_r   = alu_in1 >>  alu_in2[4:0];
  assign sra_r   = $signed(alu_in1) >>> alu_in2[4:0];
  assign xor_r   = alu_in1 ^  alu_in2;
  assign or_r    = alu_in1 |  alu_in2;
  assign and_r   = alu_in1 &  alu_in2;
  assign slt_r   = ($signed(alu_in1) <  $signed(alu_in2)) ? 32'd1 : 32'd0;
  assign sltu_r  = (alu_in1          <  alu_in2)          ? 32'd1 : 32'd0;
  assign jlink_r = alu_in1 + 32'd4;
  assign lui_r   = alu_in2;

/*  logic signed [63:0] a_s, b_s, mul_ss, mul_su;
  logic        [63:0] a_u, b_u, mul_uu;
  assign a_s = $signed({{32{alu_in1[31]}}, alu_in1});
  assign b_s = $signed({{32{alu_in2[31]}}, alu_in2});
  assign a_u = {32'd0, alu_in1};
  assign b_u = {32'd0, alu_in2};

  assign mul_ss = a_s * b_s;                    // signed * signed
  assign mul_su = a_s * $signed(b_u);           // signed * unsigned
  assign mul_uu = a_u * b_u;                    // unsigned * unsigned
*/
  logic        do_mul;
  logic [31:0] opA_mul, opB_mul, mul_lo, mulhu_hi, mulhsu_hi, mulh_hi;
  logic [63:0] U;                 // unsigned 32x32 -> 64 product
  logic        a_neg, b_neg;
  assign do_mul = sel_MUL | sel_MULH | sel_MULHSU | sel_MULHU;

  assign opA_mul = do_mul ? alu_in1 : 32'd0;
  assign opB_mul = do_mul ? alu_in2 : 32'd0;
  assign a_neg = alu_in1[31];
  assign b_neg = alu_in2[31];

  assign U     = opA_mul * opB_mul;
  assign mul_lo    = U[31:0];
  assign mulhu_hi  = U[63:32];
  assign mulhsu_hi = U[63:32] - (a_neg ? alu_in2 : 32'd0);
  assign mulh_hi   = U[63:32]
                   - (a_neg ? alu_in2 : 32'd0)
                   - (b_neg ? alu_in1 : 32'd0);


  logic eq, slt_b, ult_b;
  assign eq    = (alu_in1 == alu_in2);
  assign slt_b = ($signed(alu_in1) <  $signed(alu_in2));
  assign ult_b = (alu_in1          <  alu_in2);

  assign pc_flag =
      (sel_BEQ  &  eq)  |
      (sel_BNE  & ~eq)  |
      (sel_BLT  &  slt_b) |
      (sel_BGE  & ~slt_b) |
      (sel_BLTU &  ult_b) |
      (sel_BGEU & ~ult_b);

  // ---------------- AND/OR gating ----------------
  logic [31:0] g_add, g_sub, g_sll, g_slt, g_sltu, g_xor, g_srl, g_sra, g_or, g_and, g_jlink, g_lui;
  logic [31:0] g_mul, g_mulh, g_mulhsu, g_mulhu;

  assign g_add    = {32{sel_ADD   }} & add_r;
  assign g_sub    = {32{sel_SUB   }} & sub_r;
  assign g_sll    = {32{sel_SLL   }} & sll_r;
  assign g_slt    = {32{sel_SLT   }} & slt_r;
  assign g_sltu   = {32{sel_SLTU  }} & sltu_r;
  assign g_xor    = {32{sel_XOR   }} & xor_r;
  assign g_srl    = {32{sel_SRL   }} & srl_r;
  assign g_sra    = {32{sel_SRA   }} & sra_r;
  assign g_or     = {32{sel_OR    }} & or_r;
  assign g_and    = {32{sel_AND   }} & and_r;
  assign g_jlink  = {32{sel_JLINK }} & jlink_r;
  assign g_lui    = {32{sel_LUI   }} & lui_r;
/*
  assign g_mul    = {32{sel_MUL   }} & mul_uu[31:0];
  assign g_mulh   = {32{sel_MULH  }} & mul_ss[63:32];
  assign g_mulhsu = {32{sel_MULHSU}} & mul_su[63:32];
  assign g_mulhu  = {32{sel_MULHU }} & mul_uu[63:32];
*/
  assign g_mul    = {32{sel_MUL   }} & mul_lo;
  assign g_mulhu  = {32{sel_MULHU }} & mulhu_hi;
  assign g_mulhsu = {32{sel_MULHSU}} & mulhsu_hi;
  assign g_mulh   = {32{sel_MULH  }} & mulh_hi;

  assign alu_out = g_add | g_sub | g_sll | g_slt | g_sltu | g_xor |
                   g_srl | g_sra | g_or  | g_and | g_jlink | g_lui |
                   g_mul | g_mulh | g_mulhsu | g_mulhu;

endmodule
