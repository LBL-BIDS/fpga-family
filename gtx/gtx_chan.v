`timescale 1ns / 1ps
module gtx_chan( RXN,RXP,TXN,TXP,gtrefclk,gtrefclkbuf,sysclk,gt_txdata,gt_txusrrdy_in,gt_rxdata,gt_rxusrrdy_in,soft_reset,txusrclk,rxusrclk,qpllclk,qpllrefclk,txoutclk,rxoutclk,rxbyteisaligned);
parameter DATA_WIDTH = 20;
parameter xout_div = 4;  // 4 for Ethernet, 2 for PRC-RFS
parameter x8b10ben = 1'b0;  // 1'b0 for Ethernet, 1'b1 for PRC-RFS
parameter txoutclksel = 3'b100;  // 3'b100 for Ethernet, 3'b011 for PRC-RFS
// 3'b100 means TXPLLREFCLK_DIV2 (62.5 MHz)
// 3'b011 means TXPLLREFCLK_DIV1 (125 MHz)

input RXN;
input RXP;
output TXN ;
output TXP;
input gtrefclk;
input gtrefclkbuf;
input sysclk;
input [DATA_WIDTH-1:0] gt_txdata;
input gt_txusrrdy_in ;
output [DATA_WIDTH-1:0] gt_rxdata ;
input gt_rxusrrdy_in;
input soft_reset;
output txoutclk ;
output rxoutclk;
input txusrclk ;
input rxusrclk;
input qpllclk;
input qpllrefclk;
output rxbyteisaligned;
parameter PMA_RSV_IN = 32'h00018480;
parameter PCS_RSVD_ATTR_IN = 48'h000000000000;
parameter RX_DFE_KL_CFG2_IN = 32'h301148AC;
(* equivalent_register_removal = "no" *) reg [95:0] cpllpd_wait = 96'hFFFFFFFFFFFFFFFFFFFFFFFF;
(* equivalent_register_removal = "no" *) reg [127:0] cpllreset_wait = 128'h000000000000000000000000000000FF;
//assign refclk_out = refclk;
always @(posedge gtrefclkbuf)
begin
	cpllpd_wait <= {cpllpd_wait[94:0],1'b0};
	cpllreset_wait <= {cpllreset_wait[126:0],1'b0};
end
wire cpll_pd = cpllpd_wait[95];
wire cpll_reset = cpllreset_wait[127];

wire [63:0] rxdata_i;
wire [7:0] rxcharisk_i;
wire [7:0] rxdisperr_i;
wire [DATA_WIDTH-1:0] rxdata_out_i;
assign gt_rxdata = rxdata_out_i;
assign rxdata_out_i = {rxdisperr_i[1],rxcharisk_i[1],rxdata_i[15:8],rxdisperr_i[0],rxcharisk_i[0],rxdata_i[7:0]};
wire [63:0] txdata_i;
wire [DATA_WIDTH-1:0] txdata_in_i;
assign txdata_in_i = gt_txdata;
wire [7:0] txchardispmode_i;
wire [7:0] txchardispval_i;
wire [7:0] txcharisk_i;
assign txchardispmode_i = {6'b0,txdata_in_i[19],txdata_in_i[9]};
assign txchardispval_i = x8b10ben ? 8'b0 : {6'b0,txdata_in_i[18],txdata_in_i[8]};
assign txcharisk_i = x8b10ben ? {6'b0,txdata_in_i[18],txdata_in_i[8]} : 8'b0;
assign txdata_i = {48'b0,txdata_in_i[17:10],txdata_in_i[7:0]};
wire [1:0] gt_txbufstatus;
wire cpllrefclklost, cplllock;
wire gt_cpllreset_t, gt_recclk_stable, gt_rxdfeagchold_i, gt_rxdfelfhold_i, rxlpmlfhold, rxlpmhfhold;
wire gt_txreset_t, gt_txusrrdy_t, gt_txfsm_resetdone_out, gt_txresetdone;
wire gt_rxreset_t, gt_rxusrrdy_t, gt_rxfsm_resetdone_out, gt_rxresetdone;
`ifndef SIMULATE
//------------------------- GT Instantiations --------------------------
GTXE2_CHANNEL #
(//_______________________ Simulation-Only Attributes __________________
.SIM_RECEIVER_DETECT_PASS("TRUE")
,.SIM_TX_EIDLE_DRIVE_LEVEL("X")
,.SIM_RESET_SPEEDUP("FALSE")
,.SIM_CPLLREFCLK_SEL(3'b001)
,.SIM_VERSION("4.0")
//----------------RX Byte and Word Alignment Attributes---------------
,.ALIGN_COMMA_DOUBLE("FALSE")
,.ALIGN_COMMA_ENABLE(10'b0001111111)
,.ALIGN_COMMA_WORD(2)
,.ALIGN_MCOMMA_DET("TRUE")
,.ALIGN_MCOMMA_VALUE(10'b1010000011)
,.ALIGN_PCOMMA_DET("TRUE")
,.ALIGN_PCOMMA_VALUE(10'b0101111100)
,.SHOW_REALIGN_COMMA("TRUE")
,.RXSLIDE_AUTO_WAIT(7)
,.RXSLIDE_MODE("OFF")
,.RX_SIG_VALID_DLY(10)
//----------------RX 8B/10B Decoder Attributes---------------
,.RX_DISPERR_SEQ_MATCH("FALSE")
,.DEC_MCOMMA_DETECT("TRUE")
,.DEC_PCOMMA_DETECT("TRUE")
,.DEC_VALID_COMMA_ONLY("FALSE")
//----------------------RX Clock Correction Attributes----------------------
,.CBCC_DATA_SOURCE_SEL("ENCODED")
,.CLK_COR_SEQ_2_USE("FALSE")
,.CLK_COR_KEEP_IDLE("FALSE")
,.CLK_COR_MAX_LAT(36)
,.CLK_COR_MIN_LAT(32)
,.CLK_COR_PRECEDENCE("TRUE")
,.CLK_COR_REPEAT_WAIT(0)
,.CLK_COR_SEQ_LEN(1)
,.CLK_COR_SEQ_1_ENABLE(4'b1111)
,.CLK_COR_SEQ_1_1(10'b0100000000)
,.CLK_COR_SEQ_1_2(10'b0000000000)
,.CLK_COR_SEQ_1_3(10'b0000000000)
,.CLK_COR_SEQ_1_4(10'b0000000000)
,.CLK_CORRECT_USE("FALSE")
,.CLK_COR_SEQ_2_ENABLE(4'b1111)
,.CLK_COR_SEQ_2_1(10'b0100000000)
,.CLK_COR_SEQ_2_2(10'b0000000000)
,.CLK_COR_SEQ_2_3(10'b0000000000)
,.CLK_COR_SEQ_2_4(10'b0000000000)
//----------------------RX Channel Bonding Attributes----------------------
,.CHAN_BOND_KEEP_ALIGN("FALSE")
,.CHAN_BOND_MAX_SKEW(1)
,.CHAN_BOND_SEQ_LEN(1)
,.CHAN_BOND_SEQ_1_1(10'b0000000000)
,.CHAN_BOND_SEQ_1_2(10'b0000000000)
,.CHAN_BOND_SEQ_1_3(10'b0000000000)
,.CHAN_BOND_SEQ_1_4(10'b0000000000)
,.CHAN_BOND_SEQ_1_ENABLE(4'b1111)
,.CHAN_BOND_SEQ_2_1(10'b0000000000)
,.CHAN_BOND_SEQ_2_2(10'b0000000000)
,.CHAN_BOND_SEQ_2_3(10'b0000000000)
,.CHAN_BOND_SEQ_2_4(10'b0000000000)
,.CHAN_BOND_SEQ_2_ENABLE(4'b1111)
,.CHAN_BOND_SEQ_2_USE("FALSE")
,.FTS_DESKEW_SEQ_ENABLE(4'b1111)
,.FTS_LANE_DESKEW_CFG(4'b1111)
,.FTS_LANE_DESKEW_EN("FALSE")
//-------------------------RX Margin Analysis Attributes----------------------------
,.ES_CONTROL(6'b000000)
,.ES_ERRDET_EN("FALSE")
,.ES_EYE_SCAN_EN("TRUE")
,.ES_HORZ_OFFSET(12'h000)
,.ES_PMA_CFG(10'b0000000000)
,.ES_PRESCALE(5'b00000)
,.ES_QUALIFIER(80'h00000000000000000000)
,.ES_QUAL_MASK(80'h00000000000000000000)
,.ES_SDATA_MASK(80'h00000000000000000000)
,.ES_VERT_OFFSET(9'b000000000)
//-----------------------FPGA RX Interface Attributes-------------------------
,.RX_DATA_WIDTH(DATA_WIDTH)
//-------------------------PMA Attributes----------------------------
,.OUTREFCLK_SEL_INV(2'b11)
,.PMA_RSV(PMA_RSV_IN)
,.PMA_RSV2(16'h2050)
,.PMA_RSV3(2'b00)
,.PMA_RSV4(32'h00000000)
,.RX_BIAS_CFG(12'b000000000100)
,.DMONITOR_CFG(24'h000A00)
,.RX_CM_SEL(2'b11)
,.RX_CM_TRIM(3'b010)
,.RX_DEBUG_CFG(12'b000000000000)
,.RX_OS_CFG(13'b0000010000000)
,.TERM_RCAL_CFG(5'b10000)
,.TERM_RCAL_OVRD(1'b0)
,.TST_RSV(32'h00000000)
,.RX_CLK25_DIV(5)
,.TX_CLK25_DIV(5)
,.UCODEER_CLR(1'b0)
//-------------------------PCI Express Attributes----------------------------
,.PCS_PCIE_EN("FALSE")
//-------------------------PCS Attributes----------------------------
,.PCS_RSVD_ATTR(PCS_RSVD_ATTR_IN)
//-----------RX Buffer Attributes------------
,.RXBUF_ADDR_MODE("FAST")
,.RXBUF_EIDLE_HI_CNT(4'b1000)
,.RXBUF_EIDLE_LO_CNT(4'b0000)
,.RXBUF_EN("TRUE")
,.RX_BUFFER_CFG(6'b000000)
,.RXBUF_RESET_ON_CB_CHANGE("TRUE")
,.RXBUF_RESET_ON_COMMAALIGN("FALSE")
,.RXBUF_RESET_ON_EIDLE("FALSE")
,.RXBUF_RESET_ON_RATE_CHANGE("TRUE")
,.RXBUFRESET_TIME(5'b00001)
,.RXBUF_THRESH_OVFLW(61)
,.RXBUF_THRESH_OVRD("FALSE")
,.RXBUF_THRESH_UNDFLW(8)
,.RXDLY_CFG(16'h001F)
,.RXDLY_LCFG(9'h030)
,.RXDLY_TAP_CFG(16'h0000)
,.RXPH_CFG(24'h000000)
,.RXPHDLY_CFG(24'h084020)
,.RXPH_MONITOR_SEL(5'b00000)
,.RX_XCLK_SEL("RXREC")
,.RX_DDI_SEL(6'b000000)
,.RX_DEFER_RESET_BUF_EN("TRUE")
//---------------------CDR Attributes-------------------------
//For Display Port HBR/RBR- set RXCDR_CFG = 72'h0380008bff40200008
//For Display Port HBR2 - set RXCDR_CFG = 72'h038c008bff20200010
//For SATA Gen1 GTX- set RXCDR_CFG = 72'h03_8000_8BFF_4010_0008
//For SATA Gen2 GTX- set RXCDR_CFG = 72'h03_8800_8BFF_4020_0008
//For SATA Gen3 GTX- set RXCDR_CFG = 72'h03_8000_8BFF_1020_0010
//For SATA Gen3 GTP- set RXCDR_CFG = 83'h0_0000_87FE_2060_2444_1010
//For SATA Gen2 GTP- set RXCDR_CFG = 83'h0_0000_47FE_2060_2448_1010
//For SATA Gen1 GTP- set RXCDR_CFG = 83'h0_0000_47FE_1060_2448_1010
,.RXCDR_CFG(72'h03000023ff40100020)
,.RXCDR_FR_RESET_ON_EIDLE(1'b0)
,.RXCDR_HOLD_DURING_EIDLE(1'b0)
,.RXCDR_PH_RESET_ON_EIDLE(1'b0)
,.RXCDR_LOCK_CFG(6'b010101)
//-----------------RX Initialization and Reset Attributes-------------------
,.RXCDRFREQRESET_TIME(5'b00001)
,.RXCDRPHRESET_TIME(5'b00001)
,.RXISCANRESET_TIME(5'b00001)
,.RXPCSRESET_TIME(5'b00001)
,.RXPMARESET_TIME(5'b00011)
//-----------------RX OOB Signaling Attributes-------------------
,.RXOOB_CFG(7'b0000110)
//-----------------------RX Gearbox Attributes---------------------------
,.RXGEARBOX_EN("FALSE")
,.GEARBOX_MODE(3'b000)
//-----------------------PRBS Detection Attribute-----------------------
,.RXPRBS_ERR_LOOPBACK(1'b0)
//-----------Power-Down Attributes----------
,.PD_TRANS_TIME_FROM_P2(12'h03c)
,.PD_TRANS_TIME_NONE_P2(8'h19)
,.PD_TRANS_TIME_TO_P2(8'h64)
//-----------RX OOB Signaling Attributes----------
,.SAS_MAX_COM(64)
,.SAS_MIN_COM(36)
,.SATA_BURST_SEQ_LEN(4'b0101)
,.SATA_BURST_VAL(3'b100)
,.SATA_EIDLE_VAL(3'b100)
,.SATA_MAX_BURST(8)
,.SATA_MAX_INIT(21)
,.SATA_MAX_WAKE(7)
,.SATA_MIN_BURST(4)
,.SATA_MIN_INIT(12)
,.SATA_MIN_WAKE(4)
//-----------RX Fabric Clock Output Control Attributes----------
,.TRANS_TIME_RATE(8'h0E)
//------------TX Buffer Attributes----------------
,.TXBUF_EN("TRUE")
,.TXBUF_RESET_ON_RATE_CHANGE("TRUE")
,.TXDLY_CFG(16'h001F)
,.TXDLY_LCFG(9'h030)
,.TXDLY_TAP_CFG(16'h0000)
,.TXPH_CFG(16'h0780)
,.TXPHDLY_CFG(24'h084020)
,.TXPH_MONITOR_SEL(5'b00000)
,.TX_XCLK_SEL("TXOUT")
//-----------------------FPGA TX Interface Attributes-------------------------
,.TX_DATA_WIDTH(DATA_WIDTH)
//-----------------------TX Configurable Driver Attributes-------------------------
,.TX_DEEMPH0(5'b00000)
,.TX_DEEMPH1(5'b00000)
,.TX_EIDLE_ASSERT_DELAY(3'b110)
,.TX_EIDLE_DEASSERT_DELAY(3'b100)
,.TX_LOOPBACK_DRIVE_HIZ("FALSE")
,.TX_MAINCURSOR_SEL(1'b0)
,.TX_DRIVE_MODE("DIRECT")
,.TX_MARGIN_FULL_0(7'b1001110)
,.TX_MARGIN_FULL_1(7'b1001001)
,.TX_MARGIN_FULL_2(7'b1000101)
,.TX_MARGIN_FULL_3(7'b1000010)
,.TX_MARGIN_FULL_4(7'b1000000)
,.TX_MARGIN_LOW_0(7'b1000110)
,.TX_MARGIN_LOW_1(7'b1000100)
,.TX_MARGIN_LOW_2(7'b1000010)
,.TX_MARGIN_LOW_3(7'b1000000)
,.TX_MARGIN_LOW_4(7'b1000000)
//-----------------------TX Gearbox Attributes--------------------------
,.TXGEARBOX_EN("FALSE")
//-----------------------TX Initialization and Reset Attributes--------------------------
,.TXPCSRESET_TIME(5'b00001)
,.TXPMARESET_TIME(5'b00001)
//-----------------------TX Receiver Detection Attributes--------------------------
,.TX_RXDETECT_CFG(14'h1832)
,.TX_RXDETECT_REF(3'b100)
//--------------------------CPLL Attributes----------------------------
,.CPLL_CFG(24'hBC07DC)
,.CPLL_FBDIV(4)
,.CPLL_FBDIV_45(5)
,.CPLL_INIT_CFG(24'h00001E)
,.CPLL_LOCK_CFG(16'h01E8)
,.CPLL_REFCLK_DIV(1)
,.RXOUT_DIV(xout_div)
,.TXOUT_DIV(xout_div)
,.SATA_CPLL_CFG("VCO_3000MHZ")
//------------RX Initialization and Reset Attributes-------------
,.RXDFELPMRESET_TIME(7'b0001111)
//------------RX Equalizer Attributes-------------
,.RXLPM_HF_CFG(14'b00000011110000)
,.RXLPM_LF_CFG(14'b00000011110000)
,.RX_DFE_GAIN_CFG(23'h020FEA)
,.RX_DFE_H2_CFG(12'b000000000000)
,.RX_DFE_H3_CFG(12'b000001000000)
,.RX_DFE_H4_CFG(11'b00011110000)
,.RX_DFE_H5_CFG(11'b00011100000)
,.RX_DFE_KL_CFG(13'b0000011111110)
,.RX_DFE_LPM_CFG(16'h0904)
,.RX_DFE_LPM_HOLD_DURING_EIDLE(1'b0)
,.RX_DFE_UT_CFG(17'b10001111000000000)
,.RX_DFE_VP_CFG(17'b00011111100000011)
//-----------------------Power-Down Attributes-------------------------
,.RX_CLKMUX_PD(1'b1)
,.TX_CLKMUX_PD(1'b1)
//-----------------------FPGA RX Interface Attribute-------------------------
,.RX_INT_DATAWIDTH(0)
//-----------------------FPGA TX Interface Attribute-------------------------
,.TX_INT_DATAWIDTH(0)
//----------------TX Configurable Driver Attributes---------------
,.TX_QPI_STATUS_EN(1'b0)
//-----------------------RX Equalizer Attributes--------------------------
,.RX_DFE_KL_CFG2(RX_DFE_KL_CFG2_IN)
,.RX_DFE_XYD_CFG(13'b0000000000000)
//-----------------------TX Configurable Driver Attributes--------------------------
,.TX_PREDRIVER_MODE(1'b0)
) 
gtxe2_channel 
(//------------------------------- CPLL Ports -------------------------------
.CPLLFBCLKLOST(cpllfbclklost_out)
,.CPLLLOCK(cplllock)
,.CPLLLOCKDETCLK(sysclk)
,.CPLLLOCKEN(1'b1)
,.CPLLPD(cpll_pd)
,.CPLLREFCLKLOST(cpllrefclklost)
,.CPLLREFCLKSEL(3'b010)
,.CPLLRESET(gt_cpllreset_t)//||cpll_reset)
,.GTRSVD(16'b0000000000000000)
,.PCSRSVDIN(16'b0000000000000000)
,.PCSRSVDIN2(5'b00000)
,.PMARSVDIN(5'b00000)
,.PMARSVDIN2(5'b00000)
,.TSTIN(20'b11111111111111111111)
,.TSTOUT()
//-------------------------------- Channel ---------------------------------
,.CLKRSVD(4'b0)
//------------------------ Channel - Clocking Ports ------------------------
,.GTGREFCLK(1'b0)
,.GTNORTHREFCLK0(1'b0)
,.GTNORTHREFCLK1(1'b0)
,.GTREFCLK0(1'b0)
,.GTREFCLK1(gtrefclk)
,.GTSOUTHREFCLK0(1'b0)
,.GTSOUTHREFCLK1(1'b0)
//-------------------------- Channel - DRP Ports --------------------------
,.DRPADDR(9'b0)
,.DRPCLK(sysclk)
,.DRPDI(16'b0)
,.DRPDO()
,.DRPEN(1'b0)
,.DRPRDY()
,.DRPWE(1'b0)
//----------------------------- Clocking Ports -----------------------------
,.GTREFCLKMONITOR()
,.QPLLCLK(qpllclk)
,.QPLLREFCLK(qpllrefclk)
,.RXSYSCLKSEL(2'b00)
,.TXSYSCLKSEL(2'b00)
//------------------------- Digital Monitor Ports --------------------------
,.DMONITOROUT()
//--------------- FPGA TX Interface Datapath Configuration ----------------
,.TX8B10BEN(x8b10ben)
//----------------------------- Loopback Ports -----------------------------
,.LOOPBACK(3'b0)
//--------------------------- PCI Express Ports ----------------------------
,.PHYSTATUS()
,.RXRATE(3'b0)
,.RXVALID()
//---------------------------- Power-Down Ports ----------------------------
,.RXPD(2'b00)
,.TXPD(2'b00)
//------------------------ RX 8B/10B Decoder Ports -------------------------
,.SETERRSTATUS(1'b0)
//------------------- RX Initialization and Reset Ports --------------------
,.EYESCANRESET(1'b0)
,.RXUSERRDY(gt_rxusrrdy_in||gt_rxusrrdy_t)
//------------------------ RX Margin Analysis Ports ------------------------
,.EYESCANDATAERROR()
,.EYESCANMODE(1'b0)
,.EYESCANTRIGGER(1'b0)
//----------------------- Receive Ports - CDR Ports ------------------------
,.RXCDRFREQRESET(1'b0)
,.RXCDRHOLD(1'b0)
,.RXCDRLOCK()
,.RXCDROVRDEN(1'b0)
,.RXCDRRESET(1'b0)
,.RXCDRRESETRSV(1'b0)
//----------------- Receive Ports - Clock Correction Ports -----------------
,.RXCLKCORCNT()
//-------- Receive Ports - FPGA RX Interface Datapath Configuration --------
,.RX8B10BEN(x8b10ben)
//---------------- Receive Ports - FPGA RX Interface Ports -----------------
,.RXUSRCLK(rxusrclk)
,.RXUSRCLK2(rxusrclk)
//---------------- Receive Ports - FPGA RX interface Ports -----------------
,.RXDATA(rxdata_i)
//----------------- Receive Ports - Pattern Checker Ports ------------------
,.RXPRBSERR()
,.RXPRBSSEL(3'b0)
//----------------- Receive Ports - Pattern Checker ports ------------------
,.RXPRBSCNTRESET(1'b0)
//------------------ Receive Ports - RX Equalizer Ports -------------------
,.RXDFEXYDEN(1'b1)
,.RXDFEXYDHOLD(1'b0)
,.RXDFEXYDOVRDEN(1'b0)
//---------------- Receive Ports - RX 8B/10B Decoder Ports -----------------
,.RXDISPERR(rxdisperr_i)
,.RXNOTINTABLE()
//------------------------- Receive Ports - RX AFE -------------------------
,.GTXRXP(RXP)
//---------------------- Receive Ports - RX AFE Ports ----------------------
,.GTXRXN(RXN)
//----------------- Receive Ports - RX Buffer Bypass Ports -----------------
,.RXBUFRESET(1'b0)
,.RXBUFSTATUS()
,.RXDDIEN(1'b0)
,.RXDLYBYPASS(1'b1)
,.RXDLYEN(1'b0)
,.RXDLYOVRDEN(1'b0)
,.RXDLYSRESET(1'b0)
,.RXDLYSRESETDONE()
,.RXPHALIGN(1'b0)
,.RXPHALIGNDONE()
,.RXPHALIGNEN(1'b0)
,.RXPHDLYPD(1'b0)
,.RXPHDLYRESET(1'b0)
,.RXPHMONITOR()
,.RXPHOVRDEN(1'b0)
,.RXPHSLIPMONITOR()
,.RXSTATUS()
//------------ Receive Ports - RX Byte and Word Alignment Ports ------------
,.RXBYTEISALIGNED(rxbyteisaligned)
,.RXBYTEREALIGN()
,.RXCOMMADET()
,.RXCOMMADETEN(1'b1)
,.RXMCOMMAALIGNEN(1'b1)
,.RXPCOMMAALIGNEN(1'b1)
//---------------- Receive Ports - RX Channel Bonding Ports ----------------
,.RXCHANBONDSEQ()
,.RXCHBONDEN(1'b0)
,.RXCHBONDLEVEL(3'b0)
,.RXCHBONDMASTER(1'b0)
,.RXCHBONDO()
,.RXCHBONDSLAVE(1'b0)
//--------------- Receive Ports - RX Channel Bonding Ports ----------------
,.RXCHANISALIGNED()
,.RXCHANREALIGN()
//------------------ Receive Ports - RX Equailizer Ports -------------------
,.RXLPMHFHOLD(rxlpmhfhold)
,.RXLPMHFOVRDEN(1'b0)
,.RXLPMLFHOLD(rxlpmlfhold)
//------------------- Receive Ports - RX Equalizer Ports -------------------
,.RXDFEAGCHOLD(1'b0)
,.RXDFEAGCOVRDEN(1'b0)
,.RXDFECM1EN(1'b0)
,.RXDFELFHOLD(1'b0)
,.RXDFELFOVRDEN(1'b0)
,.RXDFELPMRESET(1'b0)
,.RXDFETAP2HOLD(1'b0)
,.RXDFETAP2OVRDEN(1'b0)
,.RXDFETAP3HOLD(1'b0)
,.RXDFETAP3OVRDEN(1'b0)
,.RXDFETAP4HOLD(1'b0)
,.RXDFETAP4OVRDEN(1'b0)
,.RXDFETAP5HOLD(1'b0)
,.RXDFETAP5OVRDEN(1'b0)
,.RXDFEUTHOLD(1'b0)
,.RXDFEUTOVRDEN(1'b0)
,.RXDFEVPHOLD(1'b0)
,.RXDFEVPOVRDEN(1'b0)
,.RXDFEVSEN(1'b0)
,.RXLPMLFKLOVRDEN(1'b0)
,.RXMONITOROUT()
,.RXMONITORSEL(2'b0)
,.RXOSHOLD(1'b0)
,.RXOSOVRDEN(1'b0)
//---------- Receive Ports - RX Fabric ClocK Output Control Ports ----------
,.RXRATEDONE()
//------------- Receive Ports - RX Fabric Output Control Ports -------------
,.RXOUTCLK(rxoutclk)
,.RXOUTCLKFABRIC()
,.RXOUTCLKPCS()
,.RXOUTCLKSEL(3'b010)
//-------------------- Receive Ports - RX Gearbox Ports --------------------
,.RXDATAVALID()
,.RXHEADER()
,.RXHEADERVALID()
,.RXSTARTOFSEQ()
//------------------- Receive Ports - RX Gearbox Ports --------------------
,.RXGEARBOXSLIP(1'b0)
//----------- Receive Ports - RX Initialization and Reset Ports ------------
,.GTRXRESET(gt_rxreset_t)
,.RXOOBRESET(1'b0)
,.RXPCSRESET(1'b0)
,.RXPMARESET(gt_rxreset_t)
//---------------- Receive Ports - RX Margin Analysis ports ----------------
,.RXLPMEN(1'b1)
//----------------- Receive Ports - RX OOB Signaling ports -----------------
,.RXCOMSASDET()
,.RXCOMWAKEDET()
//---------------- Receive Ports - RX OOB Signaling ports -----------------
,.RXCOMINITDET()
//---------------- Receive Ports - RX OOB signalling Ports -----------------
,.RXELECIDLE()
,.RXELECIDLEMODE(2'b11)
//--------------- Receive Ports - RX Polarity Control Ports ----------------
,.RXPOLARITY(1'b0)
//-------------------- Receive Ports - RX gearbox ports --------------------
,.RXSLIDE(1'b0)
//----------------- Receive Ports - RX8B/10B Decoder Ports -----------------
,.RXCHARISCOMMA()
,.RXCHARISK(rxcharisk_i)
//---------------- Receive Ports - Rx Channel Bonding Ports ----------------
,.RXCHBONDI(5'b00000)
//------------ Receive Ports -RX Initialization and Reset Ports ------------
,.RXRESETDONE(gt_rxresetdone)
//------------------------------ Rx AFE Ports ------------------------------
,.RXQPIEN(1'b0)
,.RXQPISENN()
,.RXQPISENP()
//------------------------- TX Buffer Bypass Ports -------------------------
,.TXPHDLYTSTCLK(1'b0)
//---------------------- TX Configurable Driver Ports ----------------------
,.TXPOSTCURSOR(5'b00000)
,.TXPOSTCURSORINV(1'b0)
,.TXPRECURSOR(5'b0)
,.TXPRECURSORINV(1'b0)
,.TXQPIBIASEN(1'b0)
,.TXQPISTRONGPDOWN(1'b0)
,.TXQPIWEAKPUP(1'b0)
//------------------- TX Initialization and Reset Ports --------------------
,.CFGRESET(1'b0)
,.GTTXRESET(gt_txreset_t)
,.PCSRSVDOUT()
,.TXUSERRDY(gt_txusrrdy_in||gt_txusrrdy_t)
//-------------------- Transceiver Reset Mode Operation --------------------
,.GTRESETSEL(1'b0)
,.RESETOVRD(1'b0)
//-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
,.TXCHARDISPMODE(txchardispmode_i)
,.TXCHARDISPVAL(txchardispval_i)
//---------------- Transmit Ports - FPGA TX Interface Ports ----------------
,.TXUSRCLK(txusrclk)
,.TXUSRCLK2(txusrclk)
//------------------- Transmit Ports - PCI Express Ports -------------------
,.TXELECIDLE(1'b0)
,.TXMARGIN(3'b0)
,.TXRATE(3'b0)
,.TXSWING(1'b0)
//---------------- Transmit Ports - Pattern Generator Ports ----------------
,.TXPRBSFORCEERR(1'b0)
//---------------- Transmit Ports - TX Buffer Bypass Ports -----------------
,.TXDLYBYPASS(1'b1)
,.TXDLYEN(1'b0)
,.TXDLYHOLD(1'b0)
,.TXDLYOVRDEN(1'b0)
,.TXDLYSRESET(1'b0)
,.TXDLYSRESETDONE()
,.TXDLYUPDOWN(1'b0)
,.TXPHALIGN(1'b0)
,.TXPHALIGNDONE()
,.TXPHALIGNEN(1'b0)
,.TXPHDLYPD(1'b0)
,.TXPHDLYRESET(1'b0)
,.TXPHINIT(1'b0)
,.TXPHINITDONE()
,.TXPHOVRDEN(1'b0)
//-------------------- Transmit Ports - TX Buffer Ports --------------------
,.TXBUFSTATUS(gt_txbufstatus)
//------------- Transmit Ports - TX Configurable Driver Ports --------------
,.TXBUFDIFFCTRL(3'b100)
,.TXDEEMPH(1'b0)
,.TXDIFFCTRL(4'b1010)
,.TXDIFFPD(1'b0)
,.TXINHIBIT(1'b0)
,.TXMAINCURSOR(7'b0000000)
,.TXPISOPD(1'b0)
//---------------- Transmit Ports - TX Data Path interface -----------------
,.TXDATA(txdata_i)
//-------------- Transmit Ports - TX Driver and OOB signaling --------------
,.GTXTXN(TXN)
,.GTXTXP(TXP)
//--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
,.TXOUTCLK(txoutclk)
,.TXOUTCLKFABRIC()
,.TXOUTCLKPCS()
,.TXOUTCLKSEL(txoutclksel)
,.TXRATEDONE()
//------------------- Transmit Ports - TX Gearbox Ports --------------------
,.TXCHARISK(txcharisk_i)
,.TXGEARBOXREADY()
,.TXHEADER(3'b0)
,.TXSEQUENCE(7'b0)
,.TXSTARTSEQ(1'b0)
//----------- Transmit Ports - TX Initialization and Reset Ports -----------
,.TXPCSRESET(1'b0)
,.TXPMARESET(1'b0)
,.TXRESETDONE(gt_txresetdone)
//---------------- Transmit Ports - TX OOB signalling Ports ----------------
,.TXCOMFINISH()
,.TXCOMINIT(1'b0)
,.TXCOMSAS(1'b0)
,.TXCOMWAKE(1'b0)
,.TXPDELECIDLEMODE(1'b0)
//--------------- Transmit Ports - TX Polarity Control Ports ---------------
,.TXPOLARITY(1'b0)
//------------- Transmit Ports - TX Receiver Detection Ports --------------
,.TXDETECTRX(1'b0)
//---------------- Transmit Ports - TX8b/10b Encoder Ports -----------------
,.TX8B10BBYPASS(8'b0)
//---------------- Transmit Ports - pattern Generator Ports ----------------
,.TXPRBSSEL(3'b0)
//--------------------- Tx Configurable Driver Ports ----------------------
,.TXQPISENN()
,.TXQPISENP()
);
`endif  // `ifndef SIMULATE
parameter EXAMPLE_SIM_GTRESET_SPEEDUP = "TRUE"; // Simulation setting for GT SecureIP model
parameter EXAMPLE_SIMULATION = 0; // Set to 1 for simulation
parameter STABLE_CLOCK_PERIOD = 10; //Period of the stable clock driving this state-machine; unit is [ns]
parameter EXAMPLE_USE_CHIPSCOPE = 0; // Set to 1 to use Chipscope to drive resets
gtwizard_TX_STARTUP_FSM #
(.EXAMPLE_SIMULATION(EXAMPLE_SIMULATION)
,.STABLE_CLOCK_PERIOD(STABLE_CLOCK_PERIOD)// Period of the stable clock driving this state-machine,unit is [ns]
,.RETRY_COUNTER_BITWIDTH(8)
,.TX_QPLL_USED("FALSE")// the TX and RX Reset FSMs must
,.RX_QPLL_USED("FALSE")// share these two generic values
,.PHASE_ALIGNMENT_MANUAL("FALSE")
) 
gt0_txresetfsm_i(.STABLE_CLOCK(sysclk)
,.TXUSERCLK(txusrclk)
,.SOFT_RESET(soft_reset)
,.QPLLREFCLKLOST(1'b0)
,.CPLLREFCLKLOST(cpllrefclklost)
,.QPLLLOCK(1'b1)
,.CPLLLOCK(cplllock)
,.TXRESETDONE(gt_txresetdone)
,.MMCM_LOCK(1'b1)
,.GTTXRESET(gt_txreset_t)
,.MMCM_RESET()
,.QPLL_RESET()
,.CPLL_RESET(gt_cpllreset_t)
,.TX_FSM_RESET_DONE(gt_txfsm_resetdone_out)
,.TXUSERRDY(gt_txusrrdy_t)
,.RUN_PHALIGNMENT()
,.RESET_PHALIGNMENT()
,.PHALIGNMENT_DONE(1'b1)
,.RETRY_COUNTER()
);
wire gt_data_valid_in = 1'b1;
wire dont_reset_on_data_error_in = 1'b0;
gtwizard_RX_STARTUP_FSM #(.EXAMPLE_SIMULATION(EXAMPLE_SIMULATION)
,.EQ_MODE("LPM")
,.STABLE_CLOCK_PERIOD(STABLE_CLOCK_PERIOD)
,.RETRY_COUNTER_BITWIDTH(8)
,.TX_QPLL_USED("FALSE")
,.RX_QPLL_USED("FALSE")
,.PHASE_ALIGNMENT_MANUAL("FALSE") 
) 
gt0_rxresetfsm_i(.STABLE_CLOCK(sysclk)
,.RXUSERCLK(rxusrclk)
,.SOFT_RESET(soft_reset)
,.DONT_RESET_ON_DATA_ERROR(dont_reset_on_data_error_in)
,.QPLLREFCLKLOST(1'b0)
,.CPLLREFCLKLOST(cpllrefclklost)
,.QPLLLOCK(1'b1)
,.CPLLLOCK(cplllock)
,.RXRESETDONE(gt_rxresetdone)
,.MMCM_LOCK(1'b1)
,.RECCLK_STABLE(gt_recclk_stable)
,.RECCLK_MONITOR_RESTART(1'b0)
,.DATA_VALID(gt_data_valid_in)
,.TXUSERRDY(1'b1)
,.GTRXRESET(gt_rxreset_t)
,.MMCM_RESET()
,.QPLL_RESET()
,.CPLL_RESET()
,.RX_FSM_RESET_DONE(gt_rxfsm_resetdone_out)
,.RXUSERRDY(gt_rxusrrdy_t)
,.RUN_PHALIGNMENT()
,.RESET_PHALIGNMENT()
,.PHALIGNMENT_DONE(1'b1)
,.RXDFEAGCHOLD(gt_rxdfeagchold_i)
,.RXDFELFHOLD(gt_rxdfelfhold_i)
,.RXLPMLFHOLD(rxlpmlfhold)
,.RXLPMHFHOLD(rxlpmhfhold)
,.RETRY_COUNTER()
);
reg gt_rx_cdrlocked;
integer gt_rx_cdrlock_counter = 0;
localparam RX_CDRLOCK_TIME = (EXAMPLE_SIMULATION == 1) ? 1000 : 100000/1.25;
//localparam integer WAIT_TIME_CDRLOCK = RX_CDRLOCK_TIME / STABLE_CLOCK_PERIOD; 
integer WAIT_TIME_CDRLOCK = RX_CDRLOCK_TIME / STABLE_CLOCK_PERIOD; 
`define DLY #1
always @(posedge sysclk)
begin
if(gt_rxreset_t)
begin
	gt_rx_cdrlocked <= `DLY 1'b0;
	gt_rx_cdrlock_counter <= `DLY 0; 
end 
else if(gt_rx_cdrlock_counter == WAIT_TIME_CDRLOCK) 
begin
	gt_rx_cdrlocked <= `DLY 1'b1;
	gt_rx_cdrlock_counter <= `DLY gt_rx_cdrlock_counter;
end
else
	gt_rx_cdrlock_counter <= `DLY gt_rx_cdrlock_counter + 1;
end 
assign gt_recclk_stable = gt_rx_cdrlocked;
endmodule
