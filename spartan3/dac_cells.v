`timescale 1ns / 1ns

// No sign handling here, and the DAC is offset binary.
// So the caller needs to provide offset binary inputs.
module dac_cells(
	clk,
	data0,
	data1,
	dac
);

parameter width=16;

input  clk;
input  [width-1:0] data0;
input  [width-1:0] data1;
output [width-1:0] dac;

wire [width-1:0] d0 = data0;

// move data stream to opposite clock phase in fabric
// before routing to output DDR cell
reg [width-1:0] d1=0;
always @(negedge clk) d1 <= data1;

// http://toolbox.xilinx.com/docsan/xilinx4/data/docs/sim/vtex8.html :
// "The dual data rate register primitives (the synchronous set/reset with clock
// enable FDDRRSE, and asynchronous set/reset with clock enable FDDRCPE) must be
// instantiated in order to utilize the dual data rate registers in the outputs."
// FDDRRSE is a primitive in Spartan-3, Virtex-II, Virtex-II Pro, Virtex-II Pro X

wire rst=0;
wire set=0;
wire ce=1;
genvar ix;
generate
	for (ix=0; ix<width; ix=ix+1) begin: out_cell
`ifndef SIMULATE
		FDDRRSE a(.S(set), .R(rst), .D0(d0[ix]), .D1(d1[ix]), .CE(ce), .C0(clk), .C1(~clk), .Q(dac[ix]));
`endif
	end
endgenerate

endmodule
