`timescale 1ns / 1ps
module gtx( RXN,RXP,TXN,TXP,gtrefclk,gtrefclkbuf,sysclk,gt_txdata,gt_txusrrdy_in,gt_rxdata,gt_rxusrrdy_in,soft_reset,txusrclk,rxusrclk,txoutclk,rxoutclk,rxbyteisaligned);
parameter CHAN=1;
parameter DATA_WIDTH=20;
input [CHAN-1:0] RXN;
input  [CHAN-1:0]RXP;
output  [CHAN-1:0]TXN ;
output [CHAN-1:0] TXP;
input  [CHAN-1:0]gtrefclk;
input  [CHAN-1:0]gtrefclkbuf;
input sysclk;
input [CHAN*DATA_WIDTH-1:0] gt_txdata;
input [CHAN-1:0]gt_txusrrdy_in ;
output [CHAN*DATA_WIDTH-1:0] gt_rxdata ;
input [CHAN-1:0]gt_rxusrrdy_in;
input soft_reset;
input [CHAN-1:0]txusrclk ;
input [CHAN-1:0]rxusrclk;
output [CHAN-1:0]txoutclk ;
output [CHAN-1:0]rxoutclk;
output [CHAN-1:0]rxbyteisaligned;
//_________________________________________________________________________
//_________________________________________________________________________
//_________________________GTXE2_COMMON____________________________________
localparam QPLL_FBDIV_TOP = 16;
localparam QPLL_FBDIV_IN = (QPLL_FBDIV_TOP == 16) ? 10'b0000100000 : 
	(QPLL_FBDIV_TOP == 20) ? 10'b0000110000 :
	(QPLL_FBDIV_TOP == 32) ? 10'b0001100000 :
	(QPLL_FBDIV_TOP == 40) ? 10'b0010000000 :
	(QPLL_FBDIV_TOP == 64) ? 10'b0011100000 :
	(QPLL_FBDIV_TOP == 66) ? 10'b0101000000 :
	(QPLL_FBDIV_TOP == 80) ? 10'b0100100000 :
	(QPLL_FBDIV_TOP == 100) ? 10'b0101110000 : 10'b0000000000;
localparam QPLL_FBDIV_RATIO = (QPLL_FBDIV_TOP == 16) ? 1'b1 : 
	(QPLL_FBDIV_TOP == 20) ? 1'b1 :
	(QPLL_FBDIV_TOP == 32) ? 1'b1 :
	(QPLL_FBDIV_TOP == 40) ? 1'b1 :
	(QPLL_FBDIV_TOP == 64) ? 1'b1 :
	(QPLL_FBDIV_TOP == 66) ? 1'b0 :
	(QPLL_FBDIV_TOP == 80) ? 1'b1 :
	(QPLL_FBDIV_TOP == 100) ? 1'b1 : 1'b1;
wire qpllclk,qpllrefclk;
`ifndef SIMULATE
GTXE2_COMMON #(.SIM_RESET_SPEEDUP("FALSE")
,.SIM_QPLLREFCLK_SEL(3'b001)
,.SIM_VERSION("4.0")
//----------------COMMON BLOCK Attributes---------------
,.BIAS_CFG(64'h0000040000001000)
,.COMMON_CFG(32'h00000000)
,.QPLL_CFG(27'h06801C1)
,.QPLL_CLKOUT_CFG(4'b0000)
,.QPLL_COARSE_FREQ_OVRD(6'b010000)
,.QPLL_COARSE_FREQ_OVRD_EN(1'b0)
,.QPLL_CP(10'b0000011111)
,.QPLL_CP_MONITOR_EN(1'b0)
,.QPLL_DMONITOR_SEL(1'b0)
,.QPLL_FBDIV(QPLL_FBDIV_IN)
,.QPLL_FBDIV_MONITOR_EN(1'b0)
,.QPLL_FBDIV_RATIO(QPLL_FBDIV_RATIO)
,.QPLL_INIT_CFG(24'h000006)
,.QPLL_LOCK_CFG(16'h21E8)
,.QPLL_LPF(4'b1111)
,.QPLL_REFCLK_DIV(1)
)
gtxe2_common
(//----------- Common Block - Dynamic Reconfiguration Port(DRP) -----------
.DRPADDR(8'b0)
,.DRPCLK(1'b0)
,.DRPDI(16'b0)
,.DRPDO()
,.DRPEN(1'b0)
,.DRPRDY()
,.DRPWE(1'b0)
//-------------------- Common Block - Ref Clock Ports ---------------------
,.GTGREFCLK(1'b0)
,.GTNORTHREFCLK0(1'b0)
,.GTNORTHREFCLK1(1'b0)
,.GTREFCLK0(1'b0)
,.GTREFCLK1(1'b0)
,.GTSOUTHREFCLK0(1'b0)
,.GTSOUTHREFCLK1(1'b0)
//----------------------- Common Block - QPLL Ports -----------------------
,.QPLLDMONITOR()
//--------------------- Common Block - Clocking Ports ----------------------
,.QPLLOUTCLK(qpllclk)
,.QPLLOUTREFCLK(qpllrefclk)
,.REFCLKOUTMONITOR()
//----------------------- Common Block - QPLL Ports ------------------------
,.QPLLFBCLKLOST()
,.QPLLLOCK()//QPLLLOCK_OUT)
,.QPLLLOCKDETCLK(sysclk)
,.QPLLLOCKEN(1'b1)
,.QPLLOUTRESET(1'b0)
,.QPLLPD(1'b1)
,.QPLLREFCLKLOST()
,.QPLLREFCLKSEL(3'b1)
,.QPLLRESET(1'b1)
,.QPLLRSVD1(16'b0000000000000000)
,.QPLLRSVD2(5'b11111)
//------------------------------- QPLL Ports -------------------------------
,.BGBYPASSB(1'b1)
,.BGMONITORENB(1'b1)
,.BGPDB(1'b1)
,.BGRCALOVRD(5'b11111)
,.PMARSVD(8'b00000000)
,.RCALENB(1'b1)
);
`endif // `ifndef SIMULATE
genvar ichan;

generate for (ichan=0; ichan<CHAN; ichan=ichan+1) begin: gtx_channel
gtx_chan chan_i(.RXN(RXN[ichan])
	,.RXP(RXP[ichan])
	,.TXN(TXN[ichan])
	,.TXP(TXP[ichan])
	,.gtrefclk(gtrefclk[ichan])
	,.gtrefclkbuf(gtrefclkbuf[ichan])
	,.sysclk(sysclk)
	,.gt_txdata(gt_txdata[(ichan+1)*DATA_WIDTH-1:(ichan*DATA_WIDTH)])
	,.gt_txusrrdy_in(gt_txusrrdy_in[ichan])
	,.gt_rxdata(gt_rxdata[(ichan+1)*DATA_WIDTH-1:(ichan*DATA_WIDTH)])
	,.gt_rxusrrdy_in(gt_rxusrrdy_in[ichan])
	,.soft_reset(soft_reset)
	,.txoutclk(txoutclk[ichan])
	,.rxoutclk(rxoutclk[ichan])
	,.txusrclk(txusrclk[ichan])
	,.rxusrclk(rxusrclk[ichan])
	,.qpllclk(qpllclk)
	,.qpllrefclk(qpllrefclk)
	,.rxbyteisaligned(rxbyteisaligned[ichan])
	);
end
endgenerate
endmodule
