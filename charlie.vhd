library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity charlie is
  port (
    clock : in std_logic;
    io    : out std_logic_vector(3 downto 0)
  );
end charlie;

architecture charlie_arch of charlie is
  type pwm_type is array (0 to 7) of integer range 0 to 255;
  signal clock_enable : std_logic;
  signal clock_enable_counter : std_logic_vector(8 downto 0) := (others => '0');
  signal pwm : pwm_type := (7, 15, 31, 63, 127, 255, 255, 255);
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
    variable pwm_counter : integer range 0 to 255;
    variable led : integer range 0 to 7;
    variable value : std_logic_vector(3 downto 0);
  begin
    if rising_edge(clock) and clock_enable = '1' then
      pwm_counter := pwm_counter + 1;

      if pwm_counter = 0 then
        led := led + 1;
      end if;

      case led is
        when 0 => value := "ZZ10";
        when 1 => value := "Z1Z0";
        when 2 => value := "1ZZ0";
        when 3 => value := "ZZ01";
        when 4 => value := "Z10Z";
        when 5 => value := "1Z0Z";
        when others => value := "0000";
      end case;

      if pwm_counter < pwm(led) then
        io <= value;
      else
        io <= "ZZZZ";
      end if;
    end if;
  end process;
end charlie_arch;
