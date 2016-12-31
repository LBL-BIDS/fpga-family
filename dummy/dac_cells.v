`timescale 1ns / 1ns

// XXX untested
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

reg [width-1:0] r0=0, r1=0, out=0;
always @(posedge clk) begin
	r0 <= data0;
	r1 <= data1;
end
always @(clk) out <= clk ? data1 : data0;
assign dac = out;

endmodule
