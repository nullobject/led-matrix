library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.automata.all;

entity matrix_driver is
  port (
    rst : in std_logic;
    clk : in std_logic;

    -- Display IO
    row_addr : in std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0);
    led      : in std_logic;
    lat      : in std_logic;
    oe       : in std_logic;

    -- Matrix IO
    rows : out std_logic_vector(MATRIX_HEIGHT-1 downto 0);
    leds : out std_logic_vector(MATRIX_WIDTH-1 downto 0)
  );
end matrix_driver;

architecture arch of matrix_driver is
  signal leds_reg, leds_out : std_logic_vector(MATRIX_WIDTH-1 downto 0) := (others => '0');
begin
  leds <= leds_out when oe = '0' else (others => '0');

  -- Data on the `led` input is loaded on each rising edge of the `clk` signal.
  process(rst, clk, led)
  begin
    if rst = '1' then
      leds_reg <= (others => '0');
    elsif rising_edge(clk) then
      leds_reg <= leds_reg(MATRIX_WIDTH-2 downto 0) & led;
    end if;
  end process;

  -- Latch the LEDs on the rising edge of the `lat` input.
  process(lat, leds_reg)
  begin
    if rising_edge(lat) then
      leds_out <= leds_reg;
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
