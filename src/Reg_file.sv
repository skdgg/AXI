/*
 *  Register file with two read ports and one write port.
 *  Includes forwarding logic to handle data hazards.
 */
module Reg_file(
    input clk,
    input rst,

    // Write port
    input write_enable,       // Enable writing to the register file
    input [4:0] write_address, // Address of the register to write to
    input [31:0] write_data,   // Data to write to the register file

    // Read port 1
    input [4:0] read_address1, // Address of the first register to read
    output logic [31:0] read_data1, // Data from the first register

    // Read port 2
    input [4:0] read_address2, // Address of the second register to read
    output logic [31:0] read_data2  // Data from the second register
);

    // 32 x 32-bit register file
    logic [31:0] registers[31:0];

    // Read port 1 logic with forwarding
    assign read_data1 = (read_address1 == 5'd0) ? 32'd0 : // x0 is always 0
                      (read_address1 == write_address && write_enable) ? write_data : // Forwarding
                      registers[read_address1];

    // Read port 2 logic with forwarding
    assign read_data2 = (read_address2 == 5'd0) ? 32'd0 : // x0 is always 0
                      (read_address2 == write_address && write_enable) ? write_data : // Forwarding
                      registers[read_address2];

    // Write port logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all registers to 0
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'd0;
            end
        end else if (write_enable) begin
            // Write to the register file, but not to x0
            if (write_address != 5'd0) begin
                registers[write_address] <= write_data;
            end
        end
    end

endmodule