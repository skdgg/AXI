module CSR_reg(
    input clk,
    input rst,
    input [31:0] pc,
    input [31:0] immex,
    output logic [31:0] csr_out
);

// 64-bit cycle counter
logic [63:0] csr_cycle;
// 64-bit retired instruction counter
logic [63:0] csr_instret;

localparam [11:0] CYCLE    = 12'hC00;
localparam [11:0] CYCLEH   = 12'hC80;
localparam [11:0] INSTRET  = 12'hC02;
localparam [11:0] INSTRETH = 12'hC82;

always_ff @(posedge clk or posedge rst) begin
    if (rst)
        csr_cycle <= 64'd0;
    else
        csr_cycle <= csr_cycle + 64'd1;
end

always_ff @(posedge clk or posedge rst) begin
    if (rst)
        csr_instret <= 64'd0;
    else if (pc != 32'd0)
        csr_instret <= csr_instret + 64'd1;
end

always_comb begin
    case (immex[11:0])
        INSTRETH: csr_out = csr_instret[63:32];
        INSTRET:  csr_out = csr_instret[31:0] + 32'd1; 
        CYCLEH:   csr_out = csr_cycle  [63:32];
        CYCLE:    csr_out = csr_cycle  [31:0];
        default:      csr_out = 32'hFFFF_FFFF;
    endcase
end

endmodule
