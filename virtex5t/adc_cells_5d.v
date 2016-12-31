`timescale 1ns / 1ns

// No sign handling here, and the DAC is offset binary.
// So the caller needs to provide offset binary inputs.
module adc_cells_5d(
	inp,
	inn,
	in
);

parameter pincount=16;
input [pincount-1:0] inp;
input [pincount-1:0] inn;
output [pincount-1:0] in;

genvar ix;
generate
	for (ix=0; ix<pincount; ix=ix+1) begin: in_cell
		IBUFDS #(.DIFF_TERM("TRUE")) c(.I(inp[ix]), .IB(inn[ix]), .O(in[ix]));
	end
endgenerate

endmodule
