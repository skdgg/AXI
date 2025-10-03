module Shifter (
    input  logic [31:0] next_pc,

    input  logic [31:0] M_alu_out,
    input  logic [6:0]  M_op,
    input  logic [2:0]  M_funct3,
    input  logic [31:0] M_dm_data,
    input  logic [31:0] M_dm_write_enable,
    output logic [13:0] im_addr,
    output logic [13:0] dm_addr,
    output logic [31:0] dm_data_in,
    output logic [31:0] dm_bweb  // byte write enable (active-low

);
    //  Word-addressed SRAM
    always_comb begin
        im_addr = next_pc   [15:2];   
        dm_addr = M_alu_out [15:2];   
    end


    // Store data aligner + byte write mask (active-low BWEB)
    always_comb begin
        if (M_op == 7'b0100011) begin  // S-type (store)
            unique case (M_funct3)
            // -------- SW (store word, 32-bit) --------
            3'b010: begin
                dm_data_in = M_dm_data;
                dm_bweb    = M_dm_write_enable;
            end

            // -------- SB (store byte, 8-bit) --------
            3'b000: begin
                unique case (M_alu_out[1:0])
                2'b11: begin
                    dm_data_in = { M_dm_data[7:0], 24'd0 };
                    dm_bweb    = { M_dm_write_enable[7:0], 24'hFF_FFFF };
                end
                2'b10: begin
                    dm_data_in = { M_dm_data[15:0], 16'd0 };
                    dm_bweb    = { M_dm_write_enable[15:0], 16'hFFFF };
                end
                2'b01: begin
                    dm_data_in = { M_dm_data[23:0], 8'd0 };
                    dm_bweb    = { M_dm_write_enable[23:0], 8'hFF };
                end
                default: begin
                    dm_data_in = M_dm_data;
                    dm_bweb    = M_dm_write_enable;
                end
                endcase
            end

            // -------- SH (store halfword, 16-bit) --------
            3'b001: begin
                unique case (M_alu_out[1:0])
                2'b10: begin
                    dm_data_in = { M_dm_data[15:0], 16'd0 };
                    dm_bweb    = { M_dm_write_enable[15:0], 16'hFFFF };
                end
                default: begin
                    dm_data_in = M_dm_data;
                    dm_bweb    = M_dm_write_enable;
                end
                endcase
            end

            default: begin
                dm_data_in = 32'd0;
                dm_bweb    = 32'hFFFF_FFFF; 
            end
            endcase
        end else begin
            dm_data_in = M_dm_data;
            dm_bweb    = M_dm_write_enable;
        end
    end

endmodule