module PC (
    input               clk,
    input               rst,
    input               stall,
    input               d_rst,
    input        [31:0] pc_in,
    output logic [31:0] pc_out
);

    // This describes a 32-bit register with stall and flush capabilities.
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'd0; // On reset, the PC is set to address 0.
        end else if (~d_rst) begin
            pc_out <= 32'd0; // On stall, keep the current PC value.
        end else if (stall) begin
            pc_out <= pc_out; // On stall, keep the current PC value.
        end else begin
            pc_out <= pc_in; // On every clock edge, load the next PC value.
        end
    end

endmodule
