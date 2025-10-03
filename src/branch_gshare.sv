// branch_gshare.sv (parameterized XOR-hash / GShare)
module branch_gshare #(
  parameter int PHT_ENTRIES = 32,                   
  parameter int PHT_BITS    = 5,   
  parameter int GHR_BITS    = PHT_BITS             
) (
  input  logic clk,
  input  logic rst,

  // IF: predict
  input  logic [31:0] pc_if,
  output logic        pred_taken_if,
  output logic [PHT_BITS-1:0] pht_idx_if,  // carry to EX

  // EX: update
  input  logic             ex_update_en,
  input  logic             ex_actual_taken,
  input  logic [PHT_BITS-1:0] pht_idx_ex
);

  // ---- state ----
  logic [1:0] pht [0:PHT_ENTRIES-1];   // 2-bit saturating counters
  logic [GHR_BITS-1:0] ghr;            // global history
  logic [PHT_BITS-1:0] pc_idx;
  // ---- IF: XOR hash = (pc[9:2] ^ pc[31:24]) -> fold to 5b -> xor GHR ----
 /* always_comb begin
    pc_idx = pc_if[9:2] ^ pc_if[31:24];  // 8-bit base hash
  
    // 5-bit¡G(0^5, 1^6, 2^7, 3, 4)
    idx5_if[0] = pc_idx[0] ^ pc_idx[5];
    idx5_if[1] = pc_idx[1] ^ pc_idx[6];
    idx5_if[2] = pc_idx[2] ^ pc_idx[7];
    idx5_if[3] = pc_idx[3];
    idx5_if[4] = pc_idx[4];
  
    pht_idx_if    = idx5_if ^ ghr[4:0];
    pred_taken_if = pht[pht_idx_if][1];   // MSB = prediction
  end
  */
  // ---- IF: XOR hash = PC_low_N ^ GHR ----
  always_comb begin
    pc_idx        = pc_if[PHT_BITS+1:2] ^ pc_if[31 -: PHT_BITS];
    pht_idx_if    = pc_idx ^ ghr;
    pred_taken_if = pht[pht_idx_if][1];   // MSB = prediction
  end


  // ---- EX: train PHT & update GHR ----
  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < PHT_ENTRIES; i++) pht[i] <= 2'b01; // weak-not-taken
    end else if (ex_update_en) begin
      unique case (ex_actual_taken)
        1'b1: if (pht[pht_idx_ex] != 2'b11)
                 pht[pht_idx_ex] <= pht[pht_idx_ex] + 2'b01;
        1'b0: if (pht[pht_idx_ex] != 2'b00)
                 pht[pht_idx_ex] <= pht[pht_idx_ex] - 2'b01;
      endcase
    end
  end
  
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      ghr <= 5'd0;  
    end else if (ex_update_en) begin
      ghr <= { ghr[GHR_BITS-2:0], ex_actual_taken };
    end
  end
endmodule
