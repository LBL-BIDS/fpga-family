`timescale 1ns / 1ns

// No sign handling here, and the DAC is offset binary.
// So the caller needs to provide offset binary inputs.
module dac_cells_5d(
	input clk,
	input [13:0] data0,
	input [13:0] data1,
	output [13:0] dacp,
	output [13:0] dacn
);

wire rst=0;
wire set=0;
wire ce=1;
wire [13:0] dac_se;
genvar ix;
generate
	for (ix=0; ix<14; ix=ix+1) begin: out_cell
		// Use the SAME_EDGE feature of Virtex-5 ODDR cell to avoid
		// weird timing constraints; moving data to the domain of the
		// opposite clock edge is now cast in silicon.
		ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b0), .SRTYPE("SYNC"))
			 a(.S(set), .R(rst), .D1(data0[ix]), .D2(data1[ix]), .CE(ce), .C(clk), .Q(dac_se[ix]));
		OBUFDS c(.O(dacp[ix]), .OB(dacn[ix]), .I(dac_se[ix]));
	end
endgenerate

endmodule
