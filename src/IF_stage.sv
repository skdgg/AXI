`include "../src/branch_gshare.sv"
`include "../src/btb.sv"
`include "../src/PC.sv"
`include "../src/PC_adder.sv"
`include "../src/mux2to1_PC.sv"

module IF_stage (
    input               clk,
    input               rst,
    input               stall,
    input               flush,
    //input               next_pc_sel,
    //input        [31:0] jb_pc,
	output logic d_rst,
    output logic [31:0] F_PC,
    output logic [31:0] next_pc,

    //from EX stage for branch prediction 
    input               redirect_valid,      
    input        [31:0] redirect_pc,         

    input               ex_update_en,      
    input               ex_actual_taken,    
    input        [31:0] ex_pc,               
    input        [31:0] ex_actual_target,    
    input        [4:0]  pht_idx_ex,

    output logic        F_pred_taken,
    output logic [4:0]  F_pht_idx,
    output logic        F_btb_hit,
    output logic [31:0] F_btb_target

);
    logic [31:0] pc_plus_4_out;

    localparam int N = $clog2(32);//SIZE of PHT
    logic        pred_taken_if;
    logic [N-1:0]pht_idx_if;

    logic        btb_hit_if;
    logic [31:0] btb_target_if;

    logic        use_pred;
    logic [31:0] jb_pc_int;
    logic        next_pc_sel_int;
    logic        pc_stall;
    //for bp accuracy
    /*logic if_fire;
    logic btb_need;

    logic [63:0] bp_total, bp_hits, bp_misses;

    always_comb begin
        if_fire      = ~flush & ~pc_stall;  
        btb_need     = pred_taken_if;
    end

    always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        bp_total <= '0; 
        bp_hits <= '0; 
        bp_misses <= '0;
    end else begin
        if (if_fire && btb_need || redirect_valid) begin
            bp_total <= bp_total + 1;
            if (btb_hit_if)  bp_hits <= bp_hits + 1;
        end
    end
    end
*/
    //
    always_ff @(posedge clk or posedge rst) 
    begin
        if(rst) d_rst <= 1'b0;
        else    d_rst <= ~rst;
    end

    always_comb begin
        use_pred = pred_taken_if && btb_hit_if;  
        jb_pc_int = redirect_valid ? redirect_pc : btb_target_if;
        next_pc_sel_int = redirect_valid | use_pred;
        pc_stall = stall & ~redirect_valid;
    end
    
    always_comb begin
        F_pred_taken  = pred_taken_if;
        F_pht_idx     = pht_idx_if;
        F_btb_hit     = btb_hit_if;
        F_btb_target  = btb_target_if;
    end

    PC pc_reg (
        .clk(clk),
        .rst(rst),
        .d_rst(d_rst),
        .stall(pc_stall),
        .pc_in(next_pc),
        .pc_out(F_PC)
    );

    // PC+4
    PC_adder pc_adder (
        .in_a(F_PC),
        .in_b(32'd4),
        .sum_out(pc_plus_4_out)
    );
    branch_gshare bp (
      .clk(clk), 
      .rst(rst),

      .pc_if        (F_PC),
      .pred_taken_if(pred_taken_if),
      .pht_idx_if   (pht_idx_if),

      .ex_update_en   (ex_update_en),
      .ex_actual_taken(ex_actual_taken),
      .pht_idx_ex     (pht_idx_ex)
    );

    btb btb (
      .clk(clk), 
      .rst(rst),

      .pc_if    (F_PC),
      .hit_if   (btb_hit_if),
      .target_if(btb_target_if),

      .update_en(ex_update_en && ex_actual_taken),
      .pc_ex    (ex_pc),
      .target_ex(ex_actual_target)
    );


    mux2to1_PC mux2to1_PC(
        .in0(pc_plus_4_out),
        .in1(jb_pc_int),
        .F_PC(F_PC),
        .stall(stall),
        .d_rst(d_rst),
        .next_pc_sel(next_pc_sel_int),
        .out(next_pc)
    );

endmodule
