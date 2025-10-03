`include "../include/AXI_define.svh"
`include "CPU.sv"

module CPU_wrapper (
  input                                 ACLK,
  input                                 ARESETn,

  // write address signals M1
  output logic [`AXI_ID_BITS-1:0]       AWID_M1,
  output logic [`AXI_ADDR_BITS-1:0]     AWADDR_M1,
  output logic [`AXI_LEN_BITS-1:0]      AWLEN_M1,
  output logic [`AXI_SIZE_BITS-1:0]     AWSIZE_M1,
  output logic [1:0]                    AWBURST_M1,
  output logic                          AWVALID_M1,
  input                                 AWREADY_M1,
        
  // write data signals M1
  output logic [`AXI_DATA_BITS-1:0]     WDATA_M1,
  output logic [`AXI_STRB_BITS-1:0]     WSTRB_M1,
  output logic                          WLAST_M1,
  output logic                          WVALID_M1,
  input                                 WREADY_M1,

  // write respond signals M1
  input [`AXI_ID_BITS-1:0]              BID_M1,
  input [1:0]                           BRESP_M1,
  input                                 BVALID_M1,
  output logic                          BREADY_M1,
  
  // read address signals M0
  output logic [`AXI_ID_BITS-1:0]       ARID_M0,
  output logic [`AXI_ADDR_BITS-1:0]     ARADDR_M0,
  output logic [`AXI_LEN_BITS-1:0]      ARLEN_M0,
  output logic [`AXI_SIZE_BITS-1:0]     ARSIZE_M0,
  output logic [1:0]                    ARBURST_M0,
  output logic                          ARVALID_M0,
  input                                 ARREADY_M0,

  // read data signals M0
  input [`AXI_ID_BITS-1:0]              RID_M0,
  input [`AXI_DATA_BITS-1:0]            RDATA_M0,
  input [1:0]                           RRESP_M0,
  input                                 RLAST_M0,
  input                                 RVALID_M0,
  output logic                          RREADY_M0,
        
  // read address signals M1
  output logic [`AXI_ID_BITS-1:0]       ARID_M1,
  output logic [`AXI_ADDR_BITS-1:0]     ARADDR_M1,
  output logic [`AXI_LEN_BITS-1:0]      ARLEN_M1,
  output logic [`AXI_SIZE_BITS-1:0]     ARSIZE_M1,
  output logic [1:0]                    ARBURST_M1,
  output logic                          ARVALID_M1,
  input                                 ARREADY_M1,
        
  // read data signals M1
  input [`AXI_ID_BITS-1:0]              RID_M1,
  input [`AXI_DATA_BITS-1:0]            RDATA_M1,
  input [1:0]                           RRESP_M1,
  input                                 RLAST_M1,
  input                                 RVALID_M1,
  output logic                          RREADY_M1
);



logic                      IM_STOP, DM_STOP;

// IM 
logic                      IM_CEB;              // high active
logic [14:0]               IM_addr;             // word addr
logic [`AXI_DATA_BITS-1:0] IM_DO;               // instruction to CPU

// DM from CPU
logic                      DM_CEB;              // low active
logic                      DM_WEB;              // 1=read, 0=write
logic [`AXI_ADDR_BITS-1:0] DM_BWEB;             // bit-level byte enable
logic [14:0]               DM_addr;             // word addr
logic [`AXI_DATA_BITS-1:0] DM_DI;               // CPU→AXI 
logic [`AXI_DATA_BITS-1:0] DM_DO;               // AXI→CPU 


assign ARID_M0    = `AXI_ID_BITS'(0);
assign ARLEN_M0   = `AXI_LEN_ONE;        // =0 → 1 beat
assign ARSIZE_M0  = `AXI_SIZE_WORD;
assign ARBURST_M0 = `AXI_BURST_INC;

assign ARID_M1    = `AXI_ID_BITS'(1);
assign ARLEN_M1   = `AXI_LEN_ONE;
assign ARSIZE_M1  = `AXI_SIZE_WORD;
assign ARBURST_M1 = `AXI_BURST_INC;

assign AWID_M1    = `AXI_ID_BITS'(1);
assign AWLEN_M1   = `AXI_LEN_ONE;
assign AWSIZE_M1  = `AXI_SIZE_WORD;
assign AWBURST_M1 = `AXI_BURST_INC;
assign WLAST_M1   = 1'b1;

// =====================================================================
// M0: IM READ (AR/R) — registered VALID
// =====================================================================
logic                         m0_inflight;
logic                         M0_ARVALID_q;
logic [`AXI_ADDR_BITS-1:0]    M0_ARADDR_q;
logic [`AXI_DATA_BITS-1:0]    m0_rdata_q;
logic                         m0_want_issue;    
// IM read request
assign m0_want_issue = IM_CEB && !m0_inflight;

// AR：VALID until READY 
always_ff @(posedge ACLK or negedge ARESETn) begin
  if (!ARESETn) begin
    M0_ARVALID_q <= 1'b0;
    M0_ARADDR_q  <= '0;
  end else if (!M0_ARVALID_q || ARREADY_M0) begin
    M0_ARVALID_q <= m0_want_issue;
    if (m0_want_issue) M0_ARADDR_q <= {15'd0, IM_addr, 2'd0};
  end
end

assign ARVALID_M0 = M0_ARVALID_q;
assign ARADDR_M0  = M0_ARADDR_q;

// inflight：AR 
always_ff @(posedge ACLK or negedge ARESETn) begin
  if (!ARESETn) m0_inflight <= 1'b0;
  else begin
    if (M0_ARVALID_q && ARREADY_M0) m0_inflight <= 1'b1;
    if (RVALID_M0 && RREADY_M0)     m0_inflight <= 1'b0;
  end
end

assign RREADY_M0 = m0_inflight;  

always_ff @(posedge ACLK or negedge ARESETn) begin
  if (!ARESETn) m0_rdata_q <= '0;
  else if (RVALID_M0 && RREADY_M0) m0_rdata_q <= RDATA_M0;
end

assign IM_DO   = m0_rdata_q;
assign IM_STOP = (RVALID_M0 && RREADY_M0) ? 1'b0 : 1'b1;

// =====================================================================
// M1: DM READ (AR/R) 
// =====================================================================
logic                         m1r_inflight;
logic                         M1_ARVALID_q;
logic [`AXI_ADDR_BITS-1:0]    M1_ARADDR_q;
logic [`AXI_DATA_BITS-1:0]    m1_rdata_q;

wire dm_read_req    = (!DM_CEB) && (DM_WEB==1'b1);   
wire m1r_want_issue = dm_read_req && !m1r_inflight;

always_ff @(posedge ACLK or negedge ARESETn) begin
  if (!ARESETn) begin
    M1_ARVALID_q <= 1'b0;
    M1_ARADDR_q  <= '0;
  end else if (!M1_ARVALID_q || ARREADY_M1) begin
    M1_ARVALID_q <= m1r_want_issue;
    if (m1r_want_issue) M1_ARADDR_q <= {15'd0, DM_addr, 2'd0};
  end
end

assign ARVALID_M1 = M1_ARVALID_q;
assign ARADDR_M1  = M1_ARADDR_q;

always_ff @(posedge ACLK or negedge ARESETn) begin
  if (!ARESETn) m1r_inflight <= 1'b0;
  else begin
    if (M1_ARVALID_q && ARREADY_M1) m1r_inflight <= 1'b1;
    if (RVALID_M1 && RREADY_M1)     m1r_inflight <= 1'b0;
  end
end

assign RREADY_M1 = m1r_inflight;

always_ff @(posedge ACLK or negedge ARESETn) begin
  if (!ARESETn) m1_rdata_q <= '0;
  else if (RVALID_M1 && RREADY_M1) m1_rdata_q <= RDATA_M1;
end

assign DM_DO = m1_rdata_q;

// =====================================================================
// M1: DM WRITE (AW/W/B) 
// =====================================================================
logic                         m1w_inflight;
logic                         M1_AWVALID_q, M1_WVALID_q;
logic [`AXI_ADDR_BITS-1:0]    M1_AWADDR_q;
logic [`AXI_DATA_BITS-1:0]    M1_WDATA_q;
logic [`AXI_STRB_BITS-1:0]    M1_WSTRB_q;

wire dm_write_req   = (!DM_CEB) && (DM_WEB==1'b0);

wire aw_slot_free   = (!M1_AWVALID_q) || AWREADY_M1;
wire w_slot_free    = (!M1_WVALID_q)  || WREADY_M1;
wire m1w_want_issue = dm_write_req && !m1w_inflight && aw_slot_free && w_slot_free;

always_ff @(posedge ACLK or negedge ARESETn) begin
  if (!ARESETn) begin
    M1_AWVALID_q <= 1'b0;
    M1_WVALID_q  <= 1'b0;
    M1_AWADDR_q  <= '0;
    M1_WDATA_q   <= '0;
    M1_WSTRB_q   <= '0;
  end else begin
    // AW
    if (aw_slot_free) begin
      M1_AWVALID_q <= m1w_want_issue;
      if (m1w_want_issue) M1_AWADDR_q <= {15'd0, DM_addr, 2'd0};
    end
    // W
    if (w_slot_free) begin
      M1_WVALID_q <= m1w_want_issue;
      if (m1w_want_issue) begin
        M1_WDATA_q <= DM_DI;
        M1_WSTRB_q <= { &DM_BWEB[31:24], &DM_BWEB[23:16], &DM_BWEB[15:8], &DM_BWEB[7:0] };
      end
    end
  end
end

assign AWVALID_M1 = M1_AWVALID_q;
assign AWADDR_M1  = M1_AWADDR_q;

assign WVALID_M1  = M1_WVALID_q;
assign WDATA_M1   = M1_WDATA_q;
assign WSTRB_M1   = M1_WSTRB_q;

always_ff @(posedge ACLK or negedge ARESETn) begin
  if (!ARESETn) m1w_inflight <= 1'b0;
  else begin
    if (m1w_want_issue && aw_slot_free && w_slot_free) m1w_inflight <= 1'b1;
    if (BVALID_M1 && BREADY_M1)                        m1w_inflight <= 1'b0;
  end
end

assign BREADY_M1 = m1w_inflight;

assign DM_STOP = (m1r_inflight | m1w_inflight);


CPU CPU(
  .clk(ACLK),
  .rst(~ARESETn),

  .IM_STOP(IM_STOP),
  .DM_STOP(DM_STOP),
  .im_instr(IM_DO),
  .dm_data_out(DM_DO),

  .IM_CEB(IM_CEB),
  .im_addr(IM_addr),

  .DM_CEB(DM_CEB),
  .dm_web(DM_WEB),
  .dm_addr(DM_addr),
  .dm_bweb(DM_BWEB),
  .dm_data_in(DM_DI)
);
