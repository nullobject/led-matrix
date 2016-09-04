library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_divider is
  generic (
    clk_in_freq  : natural;
    clk_out_freq : natural
  );
  port (
    rst     : in std_logic;
    clk_in  : in std_logic;
    clk_out : out std_logic
  );
end clock_divider;

architecture arch of clock_divider is
  constant OUT_PERIOD : integer := (clk_in_freq / clk_out_freq) - 1;
begin
  process(clk_in, rst)
    variable count : integer range 0 to OUT_PERIOD;
  begin
    if rst = '1' then
      count := 0;
      clk_out <= '0';
    elsif rising_edge(clk_in) then
      if count = OUT_PERIOD then
        count := 0;
      else
        count := count + 1;
      end if;

      if count > OUT_PERIOD / 2 then
        clk_out <= '1';
      else
        clk_out <= '0';
      end if;
    end if;
  end process;
end arch;
