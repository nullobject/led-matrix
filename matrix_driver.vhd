library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.automata.all;

-- This entity implements a LED matrix driver. It converts display IO signals
-- into row and column signals to drive a LED matrix.
entity matrix_driver is
  port (
    rst : in std_logic;
    clk : in std_logic;

    -- Display IO
    load     : in std_logic;
    led      : in std_logic;
    lat      : in std_logic;
    oe       : in std_logic;
    row_addr : in std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0);

    -- Matrix IO
    rows : out std_logic_vector(MATRIX_HEIGHT-1 downto 0);
    leds : out std_logic_vector(MATRIX_WIDTH-1 downto 0)
  );
end matrix_driver;

architecture arch of matrix_driver is
  signal leds_in, leds_out : std_logic_vector(MATRIX_WIDTH-1 downto 0);
begin
  -- Data on the `led` input is loaded when the `load` signal is high on each rising edge of the `clk` signal.
  process(rst, clk)
  begin
    if rst = '1' then
      leds_in <= (others => '0');
    elsif rising_edge(clk) and load = '1' then
      leds_in <= leds_in(MATRIX_WIDTH-2 downto 0) & led;
    end if;
  end process;

  -- Latch the LEDs when the `lat` signal is high.
  process(clk)
  begin
    if rising_edge(clk) and lat = '1' then
      leds_out <= leds_in;
    end if;
  end process;

  -- Output the LEDs when the `oe` signal is low.
  process(clk)
  begin
    if rising_edge(clk) then
      if oe = '0' then
        leds <= leds_out;
      else
        leds <= (others => '0');
      end if;
    end if;
  end process;

  with row_addr select
    rows <= "10000000" when "111",
            "01000000" when "110",
            "00100000" when "101",
            "00010000" when "100",
            "00001000" when "011",
            "00000100" when "010",
            "00000010" when "001",
            "00000001" when others;
end arch;
