`timescale 1ns / 1ns

module control_if(
	input usbclk,
	input interrupt,   // not used in hardware, but useful in simulation
	output reg [39:0] control_bus,
	output reg control_strobe
);

wire capture, drck1, drck2, jtag_reset, sel1, sel2, shift, tdi, update;
wire tdo1=0;
wire tdo2=0;
`ifndef SIMULATE
BSCAN_SPARTAN3 host(
	.CAPTURE(capture),
	.DRCK1(drck1),
	.DRCK2(drck2),
	.RESET(jtag_reset),
	.SEL1(sel1),
	.SEL2(sel2),
	.SHIFT(shift),
	.TDI(tdi),
	.UPDATE(update),
	.TDO1(tdo1),
	.TDO2(tdo2)
);
`endif

// Crib from http://www.mediatronix.com/code/ROM_blank_JTAG.vhd
reg tck1, tck2, write1, write2, shiftenable;
always @(posedge usbclk) begin
	tck1 <= drck1;
	tck2 <= tck1;
	write1 <= update;
	write2 <= write1;
	control_strobe <= sel1 & write1 & ~write2;
	shiftenable <= sel1 & shift & tck1 & ~tck2;
	if (shiftenable) control_bus <= {control_bus[38:0], tdi};
end

endmodule
