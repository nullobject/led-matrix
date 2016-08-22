library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity charlie is
  port (
    clock  : in std_logic;
    row    : out std_logic_vector(3 downto 0);
    column : out std_logic_vector(6 downto 0)
  );
end charlie;

architecture charlie_arch of charlie is
  type pwm_type is array (0 to 7) of integer range 0 to 255;
  signal clock_enable : std_logic;
  signal clock_enable_counter : std_logic_vector(15 downto 0) := (others => '0');
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

  row_scan: process(clock)
    variable row_counter : std_logic_vector(3 downto 0) := "0001";
  begin
    if rising_edge(clock) and clock_enable = '1' then
      row_counter := row_counter(2 downto 0) & row_counter(3);
      row <= row_counter;
    end if;
  end process;

  column_scan: process(clock)
    variable pwm_counter : integer range 0 to 255;
  begin
    if rising_edge(clock) then
      for i in 0 to 6 loop
        if pwm_counter < pwm(i) then
          column(i) <= '1';
        else
          column(i) <= '0';
        end if;
      end loop;

      pwm_counter := pwm_counter + 1;
    end if;
  end process;
end charlie_arch;
