module F_Reg_file(
    input clk,
    input rst,
    input W_wb_en_f,
    input [4:0] rs1_index_f,
    input [4:0] rs2_index_f,
    input [4:0] W_rd_index_f,
    input [31:0] W_rd_data_f,

    output logic [31:0] rs1_data_f,
    output logic [31:0] rs2_data_f
);

int i;
logic [31:0] register[31:0]; // 1-D array 32 regs (32bits)

assign rs1_data_f = (rs1_index_f == W_rd_index_f && W_wb_en_f) ? W_rd_data_f : register[rs1_index_f];
assign rs2_data_f = (rs2_index_f == W_rd_index_f && W_wb_en_f) ? W_rd_data_f : register[rs2_index_f];

always_ff@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        for(i=0; i<32; i=i+1)begin
            register[i] <= 32'd0;
        end
    end
    else if(W_wb_en_f)
    begin
        register[W_rd_index_f] <= W_rd_data_f;
    end
    else
    begin
        register[W_rd_index_f] <= register[W_rd_index_f];
    end
end

endmodule
