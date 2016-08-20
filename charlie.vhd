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
  signal count : std_logic_vector(3 downto 0);
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
      case count is
        when "0001" => io <= "ZZ10"; -- 1
        when "0010" => io <= "Z1Z0"; -- 2
        when "0011" => io <= "1ZZ0"; -- 3
        when "0100" => io <= "ZZ01"; -- 4
        when "0101" => io <= "Z10Z"; -- 5
        when "0110" => io <= "1Z0Z"; -- 6
        when others => io <= "ZZZZ";
      end case;
      count <= count + 1;
      if count = "0111" then
        count <= "0000";
      end if;
    end if;
  end process;
end charlie_arch;
