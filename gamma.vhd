library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

-- This block applies gamma correction to the input value.
entity gamma is
  generic (
    -- The gamma value.
    gamma : real := 1.0;

    -- The width of the colour value.
    data_width : natural := 8
  );
  port (
    data_in  : in  std_logic_vector(data_width-1 downto 0);
    data_out : out std_logic_vector(data_width-1 downto 0)
  );
end gamma;

architecture arch of gamma is
  type lut_type is array(2**data_width-1 downto 0) of std_logic_vector(data_width-1 downto 0);

  function lut_init(c : integer; g : real) return lut_type is
    variable lut_var     : lut_type;
    variable lut_element : integer;
  begin
    for i in 0 to 2**c-1 loop
      lut_element := integer(real(2**c-1) * ((real(i)/(real(2**c-1)))**g));
      lut_var(i)  := conv_std_logic_vector(lut_element, c);
    end loop;
    return lut_var;
  end lut_init;

  constant gamma_lut : lut_type := lut_init(data_width, gamma);
begin
  data_out <= gamma_lut(conv_integer(data_in));
end arch;
