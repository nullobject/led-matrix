library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_tb is
end entity;

architecture arch of display_tb is
  component display is
    port (
      rst: in std_logic;
      clk: in std_logic;

      ram_addr: out unsigned(5 downto 0);
      ram_data: in unsigned(7 downto 0);

      matrix_rows: out unsigned(7 downto 0);
      matrix_cols: out unsigned(7 downto 0)
    );
  end component;

  constant CLK_PERIOD: time := 20 ns; -- for a 50MHz clock

  signal rst, clk: std_logic;

  signal ram_addr: unsigned(5 downto 0);
  signal ram_data: unsigned(7 downto 0);

  signal matrix_rows: unsigned(7 downto 0) := (others => '0');
  signal matrix_cols: unsigned(7 downto 0) := (others => '0');
begin
  uut: display port map (
    rst         => rst,
    clk         => clk,
    ram_addr    => ram_addr,
    ram_data    => ram_data,
    matrix_rows => matrix_rows,
    matrix_cols => matrix_cols
  );

  process
  begin
    rst <= '1';
    wait for CLK_PERIOD;
    rst <= '0';
    wait;
  end process;

  process
  begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
  end process;

  -- Simulate the data in memory.
  process(clk)
  begin
    if rising_edge(clk) then
      case ram_addr is
      when "000001" =>
        ram_data <= X"09";
      when "000010" =>
        ram_data <= X"0a";
      when "000011" =>
        ram_data <= X"0b";
      when "000100" =>
        ram_data <= X"0c";
      when "000101" =>
        ram_data <= X"0d";
      when "000110" =>
        ram_data <= X"0e";
      when "000111" =>
        ram_data <= X"0f";
      when others =>
        ram_data <= X"00";
      end case;
    end if;
  end process;
end architecture;
