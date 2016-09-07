library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity clock_generator is
  port (
    clkin_in        : in  std_logic;
    rst_in          : in  std_logic;
    clkfx_out       : out std_logic;
    clkin_ibufg_out : out std_logic;
    clk0_out        : out std_logic;
    locked_out      : out std_logic
  );
end clock_generator;

architecture arch of clock_generator is
  signal clkfb_in    : std_logic;
  signal clkfx_buf   : std_logic;
  signal clkin_ibufg : std_logic;
  signal clk0_buf    : std_logic;
  signal gnd_bit     : std_logic;
begin
  gnd_bit <= '0';
  clkin_ibufg_out <= clkin_ibufg;
  clk0_out <= clkfb_in;

  clkfx_bufg_inst : bufg
    port map (
      i => clkfx_buf,
      o => clkfx_out
    );

  clkin_ibufg_inst : ibufg
    port map (
      i => clkin_in,
      o => clkin_ibufg
    );

  clk0_bufg_inst : bufg
    port map (
      i => clk0_buf,
      o => clkfb_in
    );

  dcm_sp_inst : dcm_sp
    generic map (
      clk_feedback          => "1X",
      clkdv_divide          => 2.0,
      clkfx_divide          => 10,
      clkfx_multiply        => 2,
      clkin_divide_by_2     => false,
      clkin_period          => 20.000,
      clkout_phase_shift    => "NONE",
      deskew_adjust         => "SYSTEM_SYNCHRONOUS",
      dfs_frequency_mode    => "LOW",
      dll_frequency_mode    => "LOW",
      duty_cycle_correction => true,
      factory_jf            => x"C080",
      phase_shift           => 0,
      startup_wait          => false
    )
    port map (
      clkfb    => clkfb_in,
      clkin    => clkin_ibufg,
      dssen    => gnd_bit,
      psclk    => gnd_bit,
      psen     => gnd_bit,
      psincdec => gnd_bit,
      rst      => rst_in,
      clkdv    => open,
      clkfx    => clkfx_buf,
      clkfx180 => open,
      clk0     => clk0_buf,
      clk2x    => open,
      clk2x180 => open,
      clk90    => open,
      clk180   => open,
      clk270   => open,
      locked   => locked_out,
      psdone   => open,
      status   => open
    );
end arch;
