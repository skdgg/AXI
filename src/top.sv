//////////////////////////////////////////////////////////////////////
//          ██╗       ██████╗   ██╗  ██╗    ██████╗            		//
//          ██║       ██╔══█║   ██║  ██║    ██╔══█║            		//
//          ██║       ██████║   ███████║    ██████║            		//
//          ██║       ██╔═══╝   ██╔══██║    ██╔═══╝            		//
//          ███████╗  ██║  	    ██║  ██║    ██║  	           		//
//          ╚══════╝  ╚═╝  	    ╚═╝  ╚═╝    ╚═╝  	           		//
//                                                             		//
// 	2025 Advanced VLSI System Design, Advisor: Lih-Yih, Chiou		//
//                                                             		//
//////////////////////////////////////////////////////////////////////
//                                                             		//
// 	Author: 		                           				  	    //
//	Filename:		top.sv		                                    //
//	Description:	top module for AVSD HW1                     	//
// 	Date:			2025/XX/XX								   		//
// 	Version:		1.0	    								   		//
//////////////////////////////////////////////////////////////////////
`include "SRAM_wrapper.sv"
`include "CPU.sv"

module top(
input clk,
input rst
);


logic [13:0] im_addr;
logic [31:0] im_instr;

logic dm_web;
logic [31:0] dm_bweb;
logic [13:0] dm_addr;
logic [31:0] dm_data_in;
logic [31:0] dm_data_out;
// --------------------------//
//   Instance Your CPU Here  //
// --------------------------//
CPU cpu(
    .clk(clk),
    .rst(rst),
    .im_instr(im_instr),  
    .im_addr(im_addr),     

    .dm_data_out(dm_data_out), 
    .dm_addr(dm_addr),     
    .dm_data_in(dm_data_in),
    .dm_web(dm_web),      
    .dm_bweb(dm_bweb)  
);

SRAM_wrapper IM1(
.CLK(clk),
.RST(rst),
.CEB(1'b0),
.WEB(1'b1),
.BWEB(32'hFFFF_FFFF),
.A(im_addr),
.DI(32'd0),
.DO(im_instr)
);

SRAM_wrapper DM1(
.CLK(clk),
.RST(rst),
.CEB(1'b0),
.WEB(dm_web),
.BWEB(dm_bweb),
.A(dm_addr),
.DI(dm_data_in),
.DO(dm_data_out)
);

endmodule