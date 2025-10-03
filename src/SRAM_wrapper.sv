`include "../include/AXI_define.svh"

module SRAM_wrapper (
  input                             ACLK,
  input                             ARESETn,

  // ---------------- Write address ----------------
  input  [`AXI_IDS_BITS-1:0]        AWID_S,
  input  [`AXI_ADDR_BITS-1:0]       AWADDR_S,
  input  [`AXI_LEN_BITS-1:0]        AWLEN_S,   // 0..3 => 1..4 beats
  input  [`AXI_SIZE_BITS-1:0]       AWSIZE_S,  // expect word
  input  [1:0]                      AWBURST_S, // expect INCR
  input                             AWVALID_S,
  output logic                      AWREADY_S,

  // ---------------- Write data -------------------
  input  [`AXI_DATA_BITS-1:0]       WDATA_S,
  input  [`AXI_STRB_BITS-1:0]       WSTRB_S,   // 4-bit byte enable (active-high)
  input                             WLAST_S,
  input                             WVALID_S,
  output logic                      WREADY_S,

  // ---------------- Write resp -------------------
  output logic [`AXI_IDS_BITS-1:0]  BID_S,
  output logic [1:0]                BRESP_S,
  output logic                      BVALID_S,
  input                             BREADY_S,

  // ---------------- Read address -----------------
  input  [`AXI_IDS_BITS-1:0]        ARID_S,
  input  [`AXI_ADDR_BITS-1:0]       ARADDR_S,
  input  [`AXI_LEN_BITS-1:0]        ARLEN_S,   // 0..3 => 1..4 beats
  input  [`AXI_SIZE_BITS-1:0]       ARSIZE_S,  // expect word
  input  [1:0]                      ARBURST_S, // expect INCR
  input                             ARVALID_S,
  output logic                      ARREADY_S,

  // ---------------- Read data --------------------
  output logic [`AXI_IDS_BITS-1:0]  RID_S,
  output logic [`AXI_DATA_BITS-1:0] RDATA_S,
  output logic [1:0]                RRESP_S,
  output logic                      RLAST_S,
  output logic                      RVALID_S,
  input                             RREADY_S
);

  // -----------------------------------------------
  // Local params
  // -----------------------------------------------
  localparam int ADDR_WIDTH = `AXI_ADDR_BITS;
  localparam int DATA_WIDTH = `AXI_DATA_BITS; // 32
  localparam int LSB        = 2;              // word aligned (4 bytes)

  localparam int SRAM_AW    = 14;

  logic                    CEB;          // low active
  logic                    WEB;          // low active (0=write, 1=read)
  logic [SRAM_AW-1:0]      A;            // word index
  logic [DATA_WIDTH-1:0]   DI;           // write data
  logic [DATA_WIDTH-1:0]   DO;           // read data
  logic [DATA_WIDTH-1:0]   BWEB;         // per-bit write enable, low active

  // =================================================
  //                 WRITE CHANNEL
  // =================================================
  logic                      axi_awready, axi_wready;
  logic                      axi_bvalid;
  logic [`AXI_IDS_BITS-1:0]  axi_bid;

  logic                      awready_buf;

  // AW latched
  logic [`AXI_IDS_BITS-1:0]  awid_buf;
  logic [ADDR_WIDTH-1:0]     awaddr_buf;
  logic [`AXI_LEN_BITS-1:0]  awlen_buf;
  logic [`AXI_SIZE_BITS-1:0] awsize_buf;
  logic [1:0]                awburst_buf;

  // write cursor
  logic [ADDR_WIDTH-1:0]     waddr, next_wr_addr;
  logic [1:0]                wburst;
  logic [`AXI_SIZE_BITS-1:0] wsize;
  logic [`AXI_LEN_BITS-1:0]  wlen;

  // B channel hold
  logic                      r_bvalid;
  logic [`AXI_IDS_BITS-1:0]  r_bid;

  logic [DATA_WIDTH-1:0]     bweb32;
  logic                      write_fire;
  logic [SRAM_AW-1:0]        windex;
  // ---- AW buffering ----
  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      awid_buf    <= '0;
      awaddr_buf  <= '0;
      awlen_buf   <= '0;
      awsize_buf  <= '0;
      awburst_buf <= '0;
    end else if (AWVALID_S && AWREADY_S) begin
      awid_buf    <= AWID_S;
      awaddr_buf  <= AWADDR_S;
      awlen_buf   <= AWLEN_S;
      awsize_buf  <= AWSIZE_S;
      awburst_buf <= AWBURST_S;
    end
  end

  // ---- handshake ----
  always_ff @(posedge ACLK or negedge ARESETn)
  if (!ARESETn) begin
    axi_awready <= 1'b1;
    axi_wready  <= 1'b0;
  end else if (AWVALID_S && AWREADY_S) begin
    axi_awready <= 1'b0;  
    axi_wready  <= 1'b1;
  end else if (WVALID_S && WREADY_S) begin
    axi_awready <= (WLAST_S) && (!BVALID_S || BREADY_S); 
    axi_wready  <= (!WLAST_S);                           
  end else if (!axi_awready) begin
    if (WREADY_S) begin
      axi_awready <= 1'b0;
    end else if (r_bvalid && !BREADY_S) begin
      axi_awready <= 1'b0;
    end else begin
      axi_awready <= 1'b1;
    end
  end

  // ---- write address ----
  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      waddr  <= '0; wburst <= `AXI_BURST_INC; wsize <= `AXI_SIZE_WORD; wlen <= '0;
    end else if (AWVALID_S && AWREADY_S) begin
      waddr  <= AWADDR_S;
      wburst <= AWBURST_S;
      wsize  <= AWSIZE_S;
      wlen   <= AWLEN_S;
    end else if (WVALID_S && WREADY_S) begin
      waddr <= next_wr_addr;
    end
  end

  // ---- INCR + word ----
  always_comb begin
    next_wr_addr = waddr;
    if (wburst == `AXI_BURST_INC)
      next_wr_addr = waddr + (1 << wsize); // +4
  end

  always_comb begin
    bweb32 = { {8{WSTRB_S[3]}}, {8{WSTRB_S[2]}}, {8{WSTRB_S[1]}}, {8{WSTRB_S[0]}} };
  end

  assign write_fire = (WVALID_S && WREADY_S);

  // SRAM word index
  assign windex = waddr[LSB +: SRAM_AW];

  assign DI   = WDATA_S;
  assign BWEB = write_fire ? bweb32 : {DATA_WIDTH{1'b1}}; 

  // =================================================
  //                 READ CHANNEL
  // =================================================
  logic                      axi_arready;
  logic [ADDR_WIDTH-1:0]     raddr, next_rd_addr;
  logic [1:0]                rburst;
  logic [`AXI_SIZE_BITS-1:0] rsize;
  logic [`AXI_LEN_BITS-1:0]  rlen;
  logic [`AXI_LEN_BITS-1:0]  axi_rlen;    
  logic [`AXI_IDS_BITS-1:0]  rid;

  // read pipeline
  logic                      o_rd;        
  wire  [SRAM_AW-1:0]        rindex_now;  
  assign rindex_now = (ARREADY_S ? ARADDR_S[LSB +: SRAM_AW] : raddr[LSB +: SRAM_AW]);

  logic                      rd_fire_d1;
  logic [`AXI_IDS_BITS-1:0]  rid_d1;
  logic                      rlast_d1;
  logic [DATA_WIDTH-1:0]     rdata_d1;

  // skid buffer 
  logic                      rskd_ready;

  // ---- ARREADY ----
  always_ff @(posedge ACLK or negedge ARESETn)
    if (!ARESETn)
      axi_arready <= 1'b1;
    else if (ARVALID_S && ARREADY_S)
      axi_arready <= (ARLEN_S == 0) && (o_rd);  
    else if (o_rd)
      axi_arready <= (axi_rlen <= 1);           


  always_ff @(posedge ACLK) begin
    if (!ARESETn)
      axi_rlen <= '0;
    else if (ARVALID_S && ARREADY_S)
      axi_rlen <= ARLEN_S + 1;     
    else if (o_rd)
      axi_rlen <= axi_rlen - 1;
  end

  always_ff @(posedge ACLK) begin
    if (!ARESETN)
      raddr <= '0;
    else if (o_rd)
      raddr <= next_rd_addr;
    else if (ARVALID_S && ARREADY_S)
      raddr <= ARADDR_S;
  end

  always_ff @(posedge ACLK) begin
    if (!ARESETN) begin
      rburst <= '0; rsize <= '0; rlen <= '0; rid <= '0;
    end else if (ARVALID_S && ARREADY_S) begin
      rburst <= ARBURST_S;
      rsize  <= ARSIZE_S;
      rlen   <= ARLEN_S;
      rid    <= ARID_S;
    end
  end


  always_comb begin
    logic [ADDR_WIDTH-1:0] base_a  = (ARREADY_S ? ARADDR_S : raddr);
    logic [1:0]            base_b  = (ARREADY_S ? ARBURST_S: rburst);
    logic [`AXI_SIZE_BITS-1:0] base_s = (ARREADY_S ? ARSIZE_S : rsize);

    next_rd_addr = base_a;
    if (base_b == `AXI_BURST_INC)
      next_rd_addr = base_a + (1 << base_s); // +4
  end

  always_comb begin
    o_rd = (ARVALID_S || !ARREADY_S);      
    if (RVALID_S && !RREADY_S)   o_rd = 1'b0; 
    if (!rskd_ready)             o_rd = 1'b0; 
  end


  assign CEB = ~((WVALID_S && WREADY_S) || o_rd); 
  assign WEB = (WVALID_S && WREADY_S) ? 1'b0 : 1'b1; 

  always_comb begin
    if (WVALID_S && WREADY_S)
      A = windex;
    else
      A = rindex_now;
  end


  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) rd_fire_d1 <= 1'b0;
    else          rd_fire_d1 <= o_rd;
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      rid_d1   <= '0;
      rlast_d1 <= 1'b0;
    end else if (o_rd) begin
      rid_d1   <= (ARVALID_S && ARREADY_S) ? ARID_S : rid;
      rlast_d1 <= (axi_rlen == 1); 
    end
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) rdata_d1 <= '0;
    else if (rd_fire_d1)   rdata_d1 <= DO;
  end

  skid_buffer #(.DWIDTH(32+8+1)) u_r_skid (
    .clk    (ACLK),
    .rstn   (ARESETn),
    .i_data ({rid_d1, rlast_d1, rdata_d1}),
    .i_valid(rd_fire_d1),
    .o_ready(rskd_ready),
    .o_data ({RID_S,   RLAST_S,   RDATA_S}),
    .o_valid(RVALID_S),
    .i_ready(RREADY_S)
  );

  assign RRESP_S   = 2'b00;      // OKAY
  assign ARREADY_S = axi_arready;

  // =================================================
  //                Write response (B)
  // =================================================
  always_ff @(posedge ACLK or negedge ARESETn)
  if (!ARESETn)
    r_bvalid <= 1'b0;
  else if (WVALID_S && WREADY_S && WLAST_S && (BVALID_S && !BREADY_S))
    r_bvalid <= 1'b1;
  else if (BREADY_S)
    r_bvalid <= 1'b0;

  always_ff @(posedge ACLK or negedge ARESETn)
  if (!ARESETn) begin
    r_bid   <= '0;
    axi_bid <= '0;
  end else if (AWVALID_S && AWREADY_S) begin
    r_bid <= AWID_S;
  end else if (!BVALID_S || BREADY_S) begin
    axi_bid <= r_bid;
  end

  always_ff @(posedge ACLK or negedge ARESETn)
  if (!ARESETn)
    axi_bvalid <= 1'b0;
  else if (WVALID_S && WREADY_S && WLAST_S)
    axi_bvalid <= 1'b1;
  else if (BREADY_S)
    axi_bvalid <= r_bvalid;

  always_comb begin
    awready_buf = axi_awready;
    if (WVALID_S && WREADY_S && WLAST_S && (!BVALID_S || BREADY_S))
      awready_buf = 1'b1;
  end

  assign AWREADY_S = awready_buf;
  assign WREADY_S  = axi_wready;
  assign BVALID_S  = axi_bvalid;
  assign BID_S     = axi_bid;
  assign BRESP_S   = 2'b00; // OKAY

  TS1N16ADFPCLLLVTA512X45M4SWSHOD i_SRAM (
    .SLP    (1'b0),
    .DSLP   (1'b0),
    .SD     (1'b0),
    .PUDELAY(),
    .CLK    (ACLK),
    .CEB    (CEB),            // low-active enable
    .WEB    (WEB),            // low-active write enable
    .A      (A),              // word address (SRAM_AW bits)
    .D      (DI),             // write data
    .BWEB   (BWEB),           // per-bit low-active mask
    .RTSEL  (2'b01),
    .WTSEL  (2'b01),
    .Q      (DO)              
  );

endmodule
