module FD_reg (
    input               clk,
    input               rst,
    input               d_rst,
    input               stall,
    input               flush,

    // Data from IF stage
    input        [31:0] F_PC,
    input        [31:0] F_instruction,
    input               F_pred_taken,
    input        [4:0]  F_pht_idx,
    input               F_btb_hit,
    input        [31:0] F_btb_target,
    // Data to ID stage
    output logic [31:0] D_PC,
    output logic [31:0] D_instruction,
    output logic        D_pred_taken,
    output logic [4:0]  D_pht_idx,
    output logic        D_btb_hit,
    output logic [31:0] D_btb_target
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // On reset, clear the register's contents
            D_PC <= 32'd0;
            D_instruction <= 32'd0;
            D_pred_taken <= 1'b0;
            D_pht_idx <= 5'd0;
            D_btb_hit <= 1'b0;
            D_btb_target <= 32'd0;
        end else if (~d_rst) begin
            D_PC <= 32'd0;
            D_instruction <= 32'd0;
            D_pred_taken <= 1'b0;
            D_pht_idx <= 5'd0;
            D_btb_hit <= 1'b0;
            D_btb_target <= 32'd0;
        end else if (flush) begin
            // On flush, clear the register to nullify the instruction
            D_PC <= 32'd0;
            D_instruction <= 32'd0;
            D_pred_taken <= 1'b0;
            D_pht_idx <= 5'd0;
            D_btb_hit <= 1'b0;  
            D_btb_target <= 32'd0;
        end else if (!stall) begin
            // If not stalled or flushed, pass the data from IF to ID
            D_PC <= F_PC;
            D_instruction <= F_instruction;
            D_pred_taken <= F_pred_taken;
            D_pht_idx <= F_pht_idx;
            D_btb_hit <= F_btb_hit;
            D_btb_target <= F_btb_target;
        end else begin
            // If stalled, the register holds its current value
            D_PC <= D_PC;
            D_instruction <= D_instruction;
            D_pred_taken <= D_pred_taken;
            D_pht_idx <= D_pht_idx;
            D_btb_hit <= D_btb_hit;
            D_btb_target <= D_btb_target;
        end
    end

endmodule
