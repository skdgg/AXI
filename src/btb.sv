// btb.sv — Direct-mapped Branch Target Buffer
module btb (
  input  logic clk,
  input  logic rst,

  // ==== IF: query ====
  input  logic [31:0] pc_if,       // fetch PC this cycle
  output logic        hit_if,      // 1 = found a target for pc_if
  output logic [31:0] target_if,   // predicted target

  // ==== EX ====
  input  logic        update_en,   // assert when a taken branch/jal/jalr is resolved
  input  logic [31:0] pc_ex,       // PC of the branch being updated
  input  logic [31:0] target_ex  // its actual target address
);

  localparam int ENTRIES = 4;
  // ---------- Derived widths ----------
  localparam int IDX_W = $clog2(ENTRIES);
  // tag excludes index bits [IDX_W+1:2] and byte bits [1:0]
  localparam int TAG_W = 32 - (IDX_W + 2);
  //localparam int TAG_W = 12;
  // ---------- Entry definition ----------
  typedef struct packed {
    logic [TAG_W-1:0]     tag;
    logic [31:0]          target;
  } btb_line_t;

  btb_line_t btb_data [ENTRIES];
  logic [ENTRIES-1:0] btb_valid;
  
  // ---------- Index & Tag split ----------
  //logic [7:0]         d_if, d_ex;      
  logic [IDX_W-1:0]   idx_if, idx_ex;     
  logic [TAG_W-1:0]   tag_if, tag_ex;    

  /*always_comb begin
    d_if = pc_if[9:2] ^ pc_if[31:24];
    d_ex = pc_ex[9:2] ^ pc_ex[31:24];
  end
  assign idx_if[0] = d_if[0] ^ d_if[2] ^ d_if[4] ^ d_if[6];
  assign idx_if[1] = d_if[1] ^ d_if[3] ^ d_if[5] ^ d_if[7];

  assign idx_ex[0] = d_ex[0] ^ d_ex[2] ^ d_ex[4] ^ d_ex[6];
  assign idx_ex[1] = d_ex[1] ^ d_ex[3] ^ d_ex[5] ^ d_ex[7];
  
  assign tag_if = pc_if[31:IDX_W+2];
  assign tag_ex = pc_ex[31:IDX_W+2];*/
  always_comb begin
    idx_if = pc_if[IDX_W+1:2];
    tag_if = pc_if[31:IDX_W+2];

    idx_ex = pc_ex[IDX_W+1:2];
    tag_ex = pc_ex[31:IDX_W+2];
  end

  // ---------- IF: combinational read ----------
  always_comb begin
      hit_if    = btb_valid[idx_if] && (btb_data[idx_if].tag == tag_if);
      target_if = hit_if ? btb_data[idx_if].target : 32'b0;
  end

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      btb_valid <= 4'd0;     
    end else if (update_en) begin
      btb_valid[idx_ex] <= 1'b1;
    end
  end
  
  // ---------- EX: synchronous write ----------
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      for (int i = 0; i < ENTRIES; i++) begin
        btb_data[i].tag    <= 28'd0;
        btb_data[i].target <= 32'd0;
      end
    end else if (update_en) begin
      btb_data[idx_ex].tag    <= tag_ex;
      btb_data[idx_ex].target <= target_ex;
    end
  end


endmodule
