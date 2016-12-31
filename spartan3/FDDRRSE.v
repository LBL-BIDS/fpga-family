// pathetic model of Spartan3 DDR output cell
// ignores set and reset inputs
`timescale 1ns / 1ns
module FDDRRSE(input S, input R,
	input D0, input D1, input CE, input C0, input C1, output reg Q);

always @(posedge C0) if (CE) Q <= D0;
always @(posedge C1) if (CE) Q <= D1;

endmodule
