library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity charlie is
  port (
    clock : in std_logic;
    io    : out std_logic_vector(3 downto 0)
  );
end charlie;

architecture charlie_arch of charlie is
  signal clock_enable : std_logic;
  signal clock_enable_counter : std_logic_vector(23 downto 0);
  signal count : std_logic_vector(3 downto 0) := "0000";
begin
  clock_divider: process(clock)
  begin
    if rising_edge(clock) then
      clock_enable_counter <= clock_enable_counter + 1;

      if clock_enable_counter = 0 then
        clock_enable <= '1';
      else
        clock_enable <= '0';
      end if;
    end if;
  end process;

  led_charlie: process(clock, clock_enable)
  begin
    if rising_edge(clock) and clock_enable = '1' then
      count <= count + 1;
      io <= count;
    end if;
  end process;
end charlie_arch;
