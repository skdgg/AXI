module ALU_F(
    input  logic [4:0]  ALU_ctrl,   
    input  logic [31:0] ALU_in1_f,  // IEEE754 single, operand A
    input  logic [31:0] ALU_in2_f,  // IEEE754 single, operand B
    output logic [31:0] ALU_out_f   // IEEE754 single, result
);


    logic        a_s, b_s, b_s_eff;     
    logic [7:0]  a_e, b_e;
    logic [22:0] a_f23, b_f23;
    logic [24:0] a_f25, b_f25;          

    logic        fa_s, fb_s;
    logic [7:0]  fa_e, fb_e;
    logic [24:0] fa_f25, fb_f25;


    logic  [7:0]  exp_diff;
    logic [48:0]  fa_frac49, fb_frac49_shifted;
    logic [48:0]  frac_sum;    
    logic [48:0]  frac_norm;         
    logic  [5:0]  msb_index_base, msb_pos, lshift_amt;
    logic  [7:0]  res_exp_pre, res_exp_adj;
    logic         res_sign;
    logic [22:0]  res_frac23;


    logic [15:0]  scan16;
    logic  [7:0]  scan8;
    logic  [3:0]  scan4;
    logic  [1:0]  scan2;


    always_comb begin
        a_s   = ALU_in1_f[31];
        a_e   = ALU_in1_f[30:23];
        a_f23 = ALU_in1_f[22:0];
        a_f25 = {2'b01, a_f23};        

        b_s       = ALU_in2_f[31];
        b_e       = ALU_in2_f[30:23];
        b_f23     = ALU_in2_f[22:0];
        b_s_eff   = b_s ^ ALU_ctrl[0];     
        b_f25     = {2'b01, b_f23};
    end


    always_comb begin
        if (a_e > b_e) begin
            fa_s = a_s;     fa_e = a_e;     fa_f25 = a_f25;
            fb_s = b_s_eff; fb_e = b_e;     fb_f25 = b_f25;
        end
        else if (a_e < b_e) begin
            fa_s = b_s_eff; fa_e = b_e;     fa_f25 = b_f25;
            fb_s = a_s;     fb_e = a_e;     fb_f25 = a_f25;
        end
        else begin
            if (a_f23 >= b_f23) begin
                fa_s = a_s;     fa_e = a_e;     fa_f25 = a_f25;
                fb_s = b_s_eff; fb_e = b_e;     fb_f25 = b_f25;
            end else begin
                fa_s = b_s_eff; fa_e = b_e;     fa_f25 = b_f25;
                fb_s = a_s;     fb_e = a_e;     fb_f25 = a_f25;
            end
        end
    end

    always_comb begin
        exp_diff          = fa_e - fb_e;
        fa_frac49         = {fa_f25, 24'd0};         
        fb_frac49_shifted = ({fb_f25, 24'd0} >> exp_diff);
        frac_sum          = (fa_s == fb_s) ? (fa_frac49 + fb_frac49_shifted)
                                           : (fa_frac49 - fb_frac49_shifted);
        res_sign          = fa_s;                    
    end


    always_comb begin
        msb_index_base = 6'd0;

        scan16         = (|frac_sum[48:33]) ? frac_sum[48:33] : frac_sum[32:17];
        msb_index_base[4] = (|frac_sum[48:33]);

        scan8          = (|scan16[15:8]) ? scan16[15:8] : scan16[7:0];
        msb_index_base[3] = (|scan16[15:8]);

        scan4          = (|scan8[7:4]) ? scan8[7:4] : scan8[3:0];
        msb_index_base[2] = (|scan8[7:4]);

        scan2          = (|scan4[3:2]) ? scan4[3:2] : scan4[1:0];
        msb_index_base[1] = (|scan4[3:2]);

        msb_index_base[0] = scan2[1];

        msb_pos    = msb_index_base + 6'd17; 
        lshift_amt = 6'd48 - msb_pos;       
    end


    always_comb begin
        res_exp_pre = fa_e + 8'd1;
        res_exp_adj = 8'd0;
        res_frac23  = 23'd0;
        frac_norm   = 49'd0;

        if (msb_pos == 6'd48) begin
          frac_norm  = frac_sum;                 
          res_exp_adj = res_exp_pre;
        end else begin
          frac_norm  = frac_sum << lshift_amt;  
          res_exp_adj = res_exp_pre - lshift_amt;
        end
    
        if      (frac_norm[24]    == 1'b0)           res_frac23 = frac_norm[47:25];
        else if (frac_norm[24:22] >  3'b101)         res_frac23 = frac_norm[47:25] + 23'd1;
        else if (frac_norm[25])                      res_frac23 = frac_norm[47:25] + 23'd1;
        else                                         res_frac23 = frac_norm[47:25];
    end

    always_comb begin
        ALU_out_f[31]    = res_sign;
        ALU_out_f[30:23] = res_exp_adj;
        ALU_out_f[22:0]  = res_frac23;
    end

endmodule
