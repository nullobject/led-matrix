library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

-- This block implements a debouncing circuit.
--
-- The input signal is sampled every clock tick. If the last `DEBOUNCE_LENGTH`
-- consecutive input values are the same, then an output signal is produced.
entity debounce is
  generic (
    DEBOUNCE_LENGTH : natural := 4
  );
  port (
    clk  : in std_logic;
    rst  : in std_logic;
    din  : in std_logic;
    dout : out std_logic
  );
end debounce;

architecture arch of debounce is
  signal pipeline : std_logic_vector(DEBOUNCE_LENGTH-1 downto 0) := (others => '0');
begin
  process(clk, rst) is
  begin
    if rst = '1' then
      pipeline <= (others => '0');
      dout <= '0';
    elsif rising_edge(clk) then
      pipeline <= pipeline(pipeline'length-2 downto 0) & din;

      if or_reduce(pipeline) = '0' then
        dout <= '0';
      elsif and_reduce(pipeline) = '1' then
        dout <= '1';
      end if;
    end if;
  end process;
end arch;
