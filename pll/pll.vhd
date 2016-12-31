--
-- Xilinx PLL instianciation
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity pll is
  generic (
    DEVICE       : string;
    clkin_period : real    := 5.0;
    gmult        : integer := 5;
    gphase       : real    := 0.0;
    c0div        : integer := 8;
    c0phase      : real    := 0.0;
    c1div        : integer := 1;
    c1phase      : real    := 0.0;
    c2div        : integer := 1;
    c2phase      : real    := 0.0;
    c3div        : integer := 1;
    c3phase      : real    := 0.0;
    c4div        : integer := 1;
    c4phase      : real    := 0.0;
    c5div        : integer := 1;
    c5phase      : real    := 0.0
    );
  port (

    rst    : in  std_logic;
    clkin  : in  std_logic;
    locked : out std_logic;
    clk0   : out std_logic;
    clk1   : out std_logic;
    clk2   : out std_logic;
    clk3   : out std_logic;
    clk4   : out std_logic;
    clk5   : out std_logic;

    drp_clk      : in  std_logic                     := '0';
    drp_write    : in  std_logic                     := '0';
    drp_go       : in  std_logic                     := '0';
    drp_done     : out std_logic;
    drp_addr     : in  std_logic_vector(6 downto 0)  := (others => '0');
    drp_data_in  : in  std_logic_vector(15 downto 0) := (others => '0');
    drp_data_out : out std_logic_vector(15 downto 0)

    );
end pll;

architecture behave of pll is

  signal clkfb : std_logic;
  signal clki0 : std_logic;
  signal clki1 : std_logic;
  signal clki2 : std_logic;
  signal clki3 : std_logic;
  signal clki4 : std_logic;
  signal clki5 : std_logic;

  signal int_drp_go, drp_enable, drp_ready : std_logic;
  signal int_drp_data_out                  : std_logic_vector(15 downto 0);
  
begin

  g_spartan_6 : if DEVICE = "SPARTAN 6" generate
    
    pll_base_inst : pll_base
      generic map (
        bandwidth          => "OPTIMIZED",   -- "high", "low" or "optimized"
        clkfbout_mult      => gmult,  -- multiplication factor for all output clocks
        clkfbout_phase     => gphase,  -- phase shift (degrees) of all output clocks
        clkin_period       => clkin_period,  -- clock period (ns) of input clock on clkin_period
        clkout0_divide     => c0div,  -- division factor for clkout0 (1 to 128)
        clkout0_duty_cycle => 0.5,    -- duty cycle for clkout0 (0.01 to 0.99)
        clkout0_phase      => c0phase,  -- phase shift (degrees) for clkout0 (0.0 to 360.01)
        clkout1_divide     => c1div,  -- division factor for clkout1 (1 to 128)
        clkout1_duty_cycle => 0.5,    -- duty cycle for clkout1 (0.01 to 0.99)
        clkout1_phase      => c1phase,  -- phase shift (degrees) for clkout1 (0.0 to 360.01)
        clkout2_divide     => c2div,  -- division factor for clkout2 (1 to 128)
        clkout2_duty_cycle => 0.5,    -- duty cycle for clkout2 (0.01 to 0.99)
        clkout2_phase      => c2phase,  -- phase shift (degrees) for clkout2 (0.0 to 360.01)
        clkout3_divide     => c3div,  -- division factor for clkout3 (1 to 128)
        clkout3_duty_cycle => 0.5,    -- duty cycle for clkout3 (0.01 to 0.99)
        clkout3_phase      => c3phase,  -- phase shift (degrees) for clkout3 (0.0 to 360.01)
        clkout4_divide     => c4div,  -- division factor for clkout4 (1 to 128)
        clkout4_duty_cycle => 0.5,    -- duty cycle for clkout4 (0.01 to 0.99)
        clkout4_phase      => c4phase,  -- phase shift (degrees) for clkout4 (0.0 to 360.01)
        clkout5_divide     => c5div,  -- division factor for clkout5 (1 to 128)
        clkout5_duty_cycle => 0.5,    -- duty cycle for clkout5 (0.01 to 0.99)
        clkout5_phase      => c5phase,  -- phase shift (degrees) for clkout5 (0.0 to 360.01)
        compensation       => "SYSTEM_SYNCHRONOUS",  -- "system_synchrnous",
        -- "source_synchrnous", "internal",
        -- "external", "dcm2pll", "pll2dcm"
        divclk_divide      => 1,  -- division factor for all clocks (1 to 52)
        ref_jitter         => 0.100)  -- input reference jitter (0.000 to 0.999 ui%)
      port map (
        clkfbout => clkfb,              -- general output feedback signal
        clkout0  => clki0,        -- one of six general clock output signals
        clkout1  => clki1,        -- one of six general clock output signals
        clkout2  => clki2,        -- one of six general clock output signals
        clkout3  => clki3,        -- one of six general clock output signals
        clkout4  => clki4,        -- one of six general clock output signals
        clkout5  => clki5,        -- one of six general clock output signals
        locked   => locked,             -- active high pll lock signal
        clkfbin  => clkfb,              -- clock feedback input
        clkin    => clkin,              -- clock input
        rst      => rst
        );               -- asynchronous pll reset

  end generate g_spartan_6;

  g_kintex_7 : if DEVICE = "KINTEX 7" generate
    
    pll_inst : plle2_adv
      generic map (
        bandwidth          => "OPTIMIZED",   -- "high", "low" or "optimized"
        clkfbout_mult      => gmult,  -- multiplication factor for all output clocks
        clkfbout_phase     => gphase,  -- phase shift (degrees) of all output clocks
        clkin1_period      => clkin_period,  -- clock period (ns) of input clock on clkin_period
        clkout0_divide     => c0div,  -- division factor for clkout0 (1 to 128)
        clkout0_duty_cycle => 0.5,    -- duty cycle for clkout0 (0.01 to 0.99)
        clkout0_phase      => c0phase,  -- phase shift (degrees) for clkout0 (0.0 to 360.01)
        clkout1_divide     => c1div,  -- division factor for clkout1 (1 to 128)
        clkout1_duty_cycle => 0.5,    -- duty cycle for clkout1 (0.01 to 0.99)
        clkout1_phase      => c1phase,  -- phase shift (degrees) for clkout1 (0.0 to 360.01)
        clkout2_divide     => c2div,  -- division factor for clkout2 (1 to 128)
        clkout2_duty_cycle => 0.5,    -- duty cycle for clkout2 (0.01 to 0.99)
        clkout2_phase      => c2phase,  -- phase shift (degrees) for clkout2 (0.0 to 360.01)
        clkout3_divide     => c3div,  -- division factor for clkout3 (1 to 128)
        clkout3_duty_cycle => 0.5,    -- duty cycle for clkout3 (0.01 to 0.99)
        clkout3_phase      => c3phase,  -- phase shift (degrees) for clkout3 (0.0 to 360.01)
        clkout4_divide     => c4div,  -- division factor for clkout4 (1 to 128)
        clkout4_duty_cycle => 0.5,    -- duty cycle for clkout4 (0.01 to 0.99)
        clkout4_phase      => c4phase,  -- phase shift (degrees) for clkout4 (0.0 to 360.01)
        clkout5_divide     => c5div,  -- division factor for clkout5 (1 to 128)
        clkout5_duty_cycle => 0.5,    -- duty cycle for clkout5 (0.01 to 0.99)
        clkout5_phase      => c5phase,  -- phase shift (degrees) for clkout5 (0.0 to 360.01)
        compensation       => "ZHOLD",  -- "system_synchrnous",
        -- "source_synchrnous", "internal",
        -- "external", "dcm2pll", "pll2dcm"
        divclk_divide      => 1,  -- division factor for all clocks (1 to 52)
        ref_jitter1        => 0.100
        )  -- input reference jitter (0.000 to 0.999 ui%)
      port map (
        clkinsel => '1',                -- clkin1
        clkfbout => clkfb,              -- general output feedback signal
        clkout0  => clki0,        -- one of six general clock output signals
        clkout1  => clki1,        -- one of six general clock output signals
        clkout2  => clki2,        -- one of six general clock output signals
        clkout3  => clki3,        -- one of six general clock output signals
        clkout4  => clki4,        -- one of six general clock output signals
        clkout5  => clki5,        -- one of six general clock output signals
        locked   => locked,             -- active high pll lock signal
        clkfbin  => clkfb,              -- clock feedback input
        clkin1   => clkin,              -- clock input
        clkin2   => '0',                -- unused
        pwrdwn   => '0',
        rst      => rst,                -- asynchronous pll reset
        daddr    => drp_addr,
        dclk     => drp_clk,
        den      => drp_enable,
        drdy     => drp_ready,
        di       => drp_data_in,
        do       => int_drp_data_out,
        dwe      => drp_write
        );

  end generate g_kintex_7;

  clk0 <= clki0;
  clk1 <= clki1;
  clk2 <= clki2;
  clk3 <= clki3;
  clk4 <= clki4;
  clk5 <= clki5;

  -- DRP interface - pulse signals and latch result

  -- DRP enable pulse
  int_drp_go <= drp_go                       when rising_edge(drp_clk);
  drp_enable <= (not(int_drp_go) and drp_go) when rising_edge(drp_clk);

  -- DRP done latch
  drp_done_latch : process(drp_clk)
  begin
    if (rising_edge(drp_clk)) then
      if (drp_ready = '1') then
        drp_done <= '1';
      elsif (drp_enable = '1') then
        drp_done <= '0';
      end if;
    end if;
  end process drp_done_latch;

  -- DRP data latch
  drp_data_out_latch : process(drp_clk)
  begin
    if (rising_edge(drp_clk)) then
      if (drp_ready = '1') then
        drp_data_out <= int_drp_data_out;
      end if;
    end if;
  end process drp_data_out_latch;
  
end behave;
