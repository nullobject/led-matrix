library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.automata.all;

entity display_tb is
end entity;

architecture arch of display_tb is
  component display is
    port (
      rst      : in std_logic;
      clk_in   : in std_logic;
      clk_out  : out std_logic;
      row_addr : out std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0);
      led      : out std_logic;
      lat      : out std_logic;
      oe       : out std_logic;
      addr     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      data     : in std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  signal rst : std_logic;
  signal clk_in, clk_out : std_logic;
  signal row_addr : std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0);
  signal led, lat, oe : std_logic;
  signal addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal data : std_logic_vector(DATA_WIDTH-1 downto 0);

  constant clk_period : time := 20 ns; -- for a 50MHz clock
  constant num_cycles : positive := 10; -- change this to your liking
begin
  uut : display port map (
    rst  => rst,
    clk_in  => clk_in,
    clk_out  => clk_out,
    row_addr => row_addr,
    led => led,
    lat => lat,
    oe => oe,
    addr => addr,
    data => data
  );

  process
  begin
    clk_in <= '0';
    wait for clk_period/2;
    clk_in <= '1';
    wait for clk_period/2;
  end process;

  process
  begin
    if addr = "000000" then
      data <= (others => '1');
    else
      data <= (others => '0');
    end if;
    wait for clk_period;
  end process;
end architecture;
