`timescale 100 ps / 10 ps
module virtex6_clocks(
    input rst,
    input sysclk_p,
    input sysclk_n,
    output clk_eth,
    output clk_1x_90,
    output clk_2x_0,
    output pll_lock
);
    parameter clkin_period = 5;
    parameter dcm_mult = 5;
    parameter dcm_div = 8;
    parameter plladv_mult = 5;
    parameter plladv_div0 = 16;
    parameter plladv_div1 = 8;

wire xclk125_buf, clk_int_buf, clk_int;
wire sysclk_buf;
wire pll_clkfb;
parameter FALSE=0;
`ifdef SIMULATE

assign clk_2x_0 = sysclk_p;
reg clk_r=0;
always @(negedge clk_2x_0) clk_r <= #1.25 ~clk_r;
assign clk_1x_90 = clk_r;
assign clk_eth = clk_r;

`else

IBUFGDS inibufgds (
    .O(clkin1),
    .I(sysclk_p),
    .IB(sysclk_n)
);
wire clkout0,clkout1,clkout2,clkfbout;
wire LOCKED;
//---------- 125 MHz TX clock ----------
MMCM_ADV #(
    .BANDWIDTH            ( "OPTIMIZED"),
    .CLKOUT4_CASCADE      ( FALSE),
    .CLOCK_HOLD           ( FALSE),
    .COMPENSATION         ( "ZHOLD"),
    .STARTUP_WAIT         ( FALSE),
    .DIVCLK_DIVIDE        ( 1),
    .CLKFBOUT_MULT_F      ( 5.000),
    .CLKFBOUT_PHASE       ( 0.000),
    .CLKFBOUT_USE_FINE_PS ( FALSE),
    .CLKOUT0_DIVIDE_F     ( 20.000),
    .CLKOUT0_PHASE        ( 0.000),
    .CLKOUT0_DUTY_CYCLE   ( 0.500),
    .CLKOUT0_USE_FINE_PS  ( FALSE),
    .CLKOUT1_DIVIDE       ( 8),
    .CLKOUT1_PHASE        ( 0.000),
    .CLKOUT1_DUTY_CYCLE   ( 0.500),
    .CLKOUT1_USE_FINE_PS  ( FALSE),
    .CLKOUT2_DIVIDE       ( 5),
    .CLKOUT2_PHASE        ( 0.000),
    .CLKOUT2_DUTY_CYCLE   ( 0.500),
    .CLKOUT2_USE_FINE_PS  ( FALSE),
    .CLKIN1_PERIOD        ( 5.0),
    .REF_JITTER1          ( 0.010)
) MMCM_ADV_clk125tx
(
	.CLKFBOUT            ( clkfbout),
    .CLKFBOUTB           ( ),//clkfboutb_unused),
    .CLKOUT0             ( clkout0),
    .CLKOUT0B            ( ),//clkout0b_unused),
    .CLKOUT1             ( clkout1),
    .CLKOUT1B            ( ),//clkout1b_unused),
    .CLKOUT2             ( clkout2),
    .CLKOUT2B            ( ),//clkout2b_unused),
    .CLKOUT3             ( ),//clkout3_unused),
    .CLKOUT3B            ( ),//clkout3b_unused),
    .CLKOUT4             ( ),//clkout4_unused),
    .CLKOUT5             ( ),//clkout5_unused),
    .CLKOUT6             ( ),//clkout6_unused),
    //-- Input clock control
    .CLKFBIN             ( clkfbout),
    .CLKIN1              ( clkin1),
    .CLKIN2              ( 0),
    //-- Tied to always select the primary input clock
    .CLKINSEL            ( 1'b1),
    //.-- Ports for dynamic reconfiguration
    .DADDR               ( 7'b0),
    .DCLK                ( 0),
    .DEN                 ( 0),
    .DI                  ( 16'b0),
    .DO                  ( ),//do_unused),
    .DRDY                ( ),//drdy_unused),
    .DWE                 ( 0),
    //.-- Ports for dynamic phase shift
    .PSCLK               ( 0),
    .PSEN                ( 0),
    .PSINCDEC            ( 0),
    .PSDONE              ( ),//psdone_unused),
    //.-- Other control and status signals
    .LOCKED              ( LOCKED),
    .CLKINSTOPPED        ( ),//clkinstopped_unused),
    .CLKFBSTOPPED        ( ),//clkfbstopped_unused),
    .PWRDWN              ( 0),
    .RST                 ( rst));

AUTOBUF clk_1x_bufg (.I(clkout0), .O(clk_1x_90));
AUTOBUF clk_2x_bufg (.I(clkout1), .O(clk_2x_0));
AUTOBUF clk_200_bufg (.I(clkout2), .O(clk_int));
assign clk_eth=clk_2x_0;
assign pll_lock=LOCKED;
`endif // `define SIMULATE
endmodule
