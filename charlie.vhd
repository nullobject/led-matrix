library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity charlie is
  port (
    clock : in std_logic;
    leds  : out std_logic_vector(7 downto 0)
  );
end charlie;

architecture charlie_arch of charlie is
  signal count : std_logic_vector(7 downto 0) := "11111111";
begin
  led_charlie: process(clock)
  begin
    if clock'event and clock = '1' then
      leds <= count;
    end if;
  end process;
end charlie_arch;
