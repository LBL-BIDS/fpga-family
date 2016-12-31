`timescale 1ns / 1ns

module mgt_gmii_link(
	//MGT
	input   refclk_p,
        input   refclk_n,
        input   rxn0,
        input   rxp0,
        output  txn0,
        output  txp0,
        input   rxn1,
        input   rxp1,
        output  txn1,
        output  txp1,

	// GMII interface
        // GMII Rx
        output GMII_RX_CLK,
        output [7:0] GMII_RXD,
        output GMII_RX_DV,
        output GMII_RX_ER,  // not used XXX that's a mistake
        // GMII Tx
        output GMII_GTX_CLK,
        input [7:0] GMII_TXD,
        input GMII_TX_EN,
        input GMII_TX_ER,
        output  GMII_TX_CLK  // not used
);

// The two clocks are sourced from gmii_link
wire rx_clk, tx_clk;

// Stupid resets
reg gtp_reset=1, gtp_reset1=1;
always @(posedge tx_clk) begin
        gtp_reset <= gtp_reset1;
        gtp_reset1 <= 0;
end

wire [9:0] txdata0, rxdata0;
wire [9:0] txdata1, rxdata1;
wire [6:0] rxstatus0, rxstatus1;  // XXX not hooked up?
wire txstatus0, txstatus1;
// Virtex-5 MGT wrapper on top of wrapper on ...
gtp_wrap2 gtp_wrap_i(
        .txdata0(txdata0), .txstatus0(txstatus0),
        .rxdata0(rxdata0), .rxstatus0(rxstatus0),
        .txdata1(txdata1), .txstatus1(txstatus1),
        .rxdata1(rxdata1), .rxstatus1(rxstatus1),
        .tx_clk(tx_clk), .rx_clk(rx_clk), .gtp_reset(gtp_reset),
        .refclk_p(refclk_p), .refclk_n(refclk_n),
        .rxn0(rxn0), .rxp0(rxp0),
        .txn0(txn0), .txp0(txp0),
        .rxn1(rxn1), .rxp1(rxp1),
        .txn1(txn1), .txp1(txp1)
);

wire [5:0] gmii_link_leds;
wire [15:0] lacr_rx;  // nominally in Rx clock domain, don't sweat it
wire [1:0] an_state_mon;
reg an_bypass=1;  // settable by software
gmii_link glink(
        .RX_CLK(rx_clk),
        .RXD(GMII_RXD),
        .RX_DV(GMII_RX_DV),
        .GTX_CLK(tx_clk),
        .TXD(GMII_TXD),
        .TX_EN(GMII_TX_EN),
        .TX_ER(GMII_TX_ER),
`ifndef CHANNEL1
        .txdata(txdata0),
        .rxdata(rxdata0),
        .rx_err_los(rxstatus0[4]),
`else
        .txdata(txdata1),
        .rxdata(rxdata1),
        .rx_err_los(rxstatus1[4]),
`endif
        .an_bypass(an_bypass),
        .lacr_rx(lacr_rx),
        .an_state_mon(an_state_mon),
        .leds(gmii_link_leds)
);

assign GMII_RX_CLK=rx_clk;
assign GMII_GTX_CLK=tx_clk;

endmodule
