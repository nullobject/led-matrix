library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

-- This block applies gamma correction to the input value on every rising clock
-- edge.
entity gamma is
  generic (
    -- The gamma value.
    GAMMA : real := 1.0;

    -- The width of the colour value.
    DATA_WIDTH : natural := 8
  );
  port (
    clk : in std_logic;

    -- Data IO
    data_in  : in  unsigned(DATA_WIDTH-1 downto 0);
    data_out : out unsigned(DATA_WIDTH-1 downto 0)
  );
end gamma;

architecture arch of gamma is
  type lut_type is array(2**DATA_WIDTH-1 downto 0) of unsigned(DATA_WIDTH-1 downto 0);

  function lut_init(c : integer; g : real) return lut_type is
    variable lut_var : lut_type;
    variable lut_element : integer;
  begin
    for i in 0 to 2**c-1 loop
      lut_element := integer(real(2**c-1) * ((real(i)/(real(2**c-1)))**g));
      lut_var(i)  := to_unsigned(lut_element, c);
    end loop;
    return lut_var;
  end lut_init;

  constant gamma_lut : lut_type := lut_init(DATA_WIDTH, GAMMA);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      data_out <= gamma_lut(to_integer(data_in));
    end if;
  end process;
end arch;
