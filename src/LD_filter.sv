module LD_filter(
    input [31:0] LD_data,
    input [2:0] f3,

    output logic [31:0] wb_data
);

always_comb
begin
    case(f3)
    3'b010: wb_data = LD_data;                                  // LW 
    3'b000: wb_data = { {24{LD_data[7]}}, {LD_data[7:0]} };     // LB
    3'b001: wb_data = { {16{LD_data[15]}}, {LD_data[15:0]} };   // LH
    3'b100: wb_data = { {24{1'b0}}, {LD_data[7:0]} };           // LBU
    3'b101: wb_data = { {16{1'b0}}, {LD_data[15:0]} };          // LHU
    default: wb_data = LD_data;
    endcase
end

endmodule
