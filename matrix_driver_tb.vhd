library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.automata.all;

entity matrix_driver_tb is
end entity;

architecture arch of matrix_driver_tb is
  component matrix_driver is
    port (
      rst      : in std_logic;
      clk      : in std_logic;
      row_addr : in std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0);
      led      : in std_logic;
      lat      : in std_logic;
      oe       : in std_logic;
      rows     : out std_logic_vector(MATRIX_HEIGHT-1 downto 0);
      leds     : out std_logic_vector(MATRIX_WIDTH-1 downto 0)
    );
  end component;

  signal rst          : std_logic := '0';
  signal clk          : std_logic := '0';
  signal row_addr     : std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0) := (others => '0');
  signal led, lat, oe : std_logic := '0';
  signal rows         : std_logic_vector(MATRIX_HEIGHT-1 downto 0) := (others => '0');
  signal leds         : std_logic_vector(MATRIX_WIDTH-1 downto 0) := (others => '0');

  constant clk_period : time := 100 ns;
begin
  uut : matrix_driver port map (
    rst      => rst,
    clk      => clk,
    row_addr => row_addr,
    led      => led,
    lat      => lat,
    oe       => oe,
    rows     => rows,
    leds     => leds
  );

  process
  begin
    led <= '1';

    for i in 0 to 7 loop
      clk <= '0';
      wait for clk_period/2;
      clk <= '1';
      wait for clk_period/2;
    end loop;
    lat <= '1';
    wait for clk_period;
    lat <= '0';
    wait for clk_period;

    led <= '0';

    for i in 0 to 7 loop
      clk <= '0';
      wait for clk_period/2;
      clk <= '1';
      wait for clk_period/2;
    end loop;
    lat <= '1';
    wait for clk_period;
    lat <= '0';
    wait for clk_period;
  end process;
end architecture;
