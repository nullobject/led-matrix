library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity charlie_tb is
end entity;

architecture arch of charlie_tb is
  component display is
    port (
      rst      : in std_logic;
      clk      : in std_logic;
      load     : out std_logic;
      led      : out std_logic;
      lat      : out std_logic;
      oe       : out std_logic;
      row_addr : out std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0);
      addr     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      data     : in std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  component matrix is
    port (
      rst      : in std_logic;
      clk      : in std_logic;
      load     : in std_logic;
      led      : in std_logic;
      lat      : in std_logic;
      oe       : in std_logic;
      row_addr : in std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0);
      rows     : out std_logic_vector(MATRIX_HEIGHT-1 downto 0);
      leds     : out std_logic_vector(MATRIX_WIDTH-1 downto 0)
    );
  end component;

  signal rst, clk     : std_logic;
  signal load         : std_logic;
  signal led, lat, oe : std_logic;
  signal addr         : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal data         : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal row_addr     : std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0);
  signal rows         : std_logic_vector(MATRIX_HEIGHT-1 downto 0) := (others => '0');
  signal leds         : std_logic_vector(MATRIX_WIDTH-1 downto 0) := (others => '0');

  constant clk_period : time := 20 ns; -- for a 50MHz clock
  constant num_cycles : positive := 10; -- change this to your liking
begin
  display_uut : display port map (
    rst      => rst,
    clk      => clk,
    load     => load,
    led      => led,
    lat      => lat,
    oe       => oe,
    row_addr => row_addr,
    addr     => addr,
    data     => data
  );

  matrix_uut : matrix port map (
    rst      => rst,
    clk      => clk,
    load     => load,
    led      => led,
    lat      => lat,
    oe       => oe,
    row_addr => row_addr,
    rows     => rows,
    leds     => leds
  );

  process
  begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
  end process;

  with addr select
    data <= x"FF" when "000000",
            x"FF" when "001000",
            x"00" when others;
end architecture;
