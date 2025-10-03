`include "../src/LD_filter.sv"
`include "../src/mux2to1.sv"


module WB_stage(
    // Inputs from the MW stage
    input W_wb_data_sel,
    input [2:0] W_funct3,
    input [31:0] LD_data,
    input [31:0] W_alu_out,
    // Outputs to the register file
    output logic [31:0] W_rd_data
);

    logic [31:0] filter_data;

    LD_filter ld_filter (
        .LD_data(LD_data),
        .f3(W_funct3),
        .wb_data(filter_data)
    );

    mux2to1 #(.WIDTH(32)) mux2to1(
        .in0(W_alu_out),
        .in1(filter_data),
        .sel(W_wb_data_sel),
        .out(W_rd_data)
    );


endmodule
