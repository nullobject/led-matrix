library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.automata.all;

-- This entity implements a dual-port asynchronous RAM.
entity memory is
  port (
    rst : in std_logic;
    clk : in std_logic;
    we  : in std_logic;

    -- Input
    addr_a : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    din_a  : in std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Output
    addr_b : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    dout_b : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end memory;

architecture arch of memory is
  type ram_type is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
  -- FIXME: remove the initial values.
  signal ram : ram_type := (
    0 => x"0f",
    1 => x"1f",
    2 => x"2f",
    3 => x"3f",
    4 => x"4f",
    5 => x"5f",
    6 => x"6f",
    7 => x"7f",
    8 => x"8f",
    9 => x"9f",
    10 => x"af",
    11 => x"bf",
    12 => x"cf",
    13 => x"df",
    14 => x"ef",
    15 => x"ff",
    48 => x"0f",
    49 => x"1f",
    50 => x"2f",
    51 => x"3f",
    52 => x"4f",
    53 => x"5f",
    54 => x"6f",
    55 => x"7f",
    56 => x"8f",
    57 => x"9f",
    58 => x"af",
    59 => x"bf",
    60 => x"cf",
    61 => x"df",
    62 => x"ef",
    63 => x"ff",
    others => (others => '0')
  );
begin
  process(clk, we, addr_a, din_a)
  begin
    if rising_edge(clk) and we = '1' then
      ram(to_integer(unsigned(addr_a))) <= din_a;
    end if;
  end process;

  dout_b <= ram(to_integer(unsigned(addr_b)));
end arch;
