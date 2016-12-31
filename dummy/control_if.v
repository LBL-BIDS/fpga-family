`timescale 1ns / 1ns

module control_if(
	input usbclk,
	input interrupt,   // not used in hardware, but useful in simulation
	output [39:0] control_bus,
	output control_strobe
);

assign control_bus=40'bx;
assign control_strobe=1'b0;

endmodule
