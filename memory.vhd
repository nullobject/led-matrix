library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.automata.all;

entity memory is
  port (
    rst : in std_logic;
    clk : in std_logic;

    -- Input
    we     : in std_logic;
    addr_a : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    din_a  : in std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Output
    addr_b : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    dout_b : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end memory;

architecture arch of memory is
  type ram is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal blocks : ram;
begin
  process(clk, we, addr_a, din_a)
  begin
    if rising_edge(clk) and we = '1' then
      blocks(to_integer(unsigned(addr_a))) <= din_a;
    end if;
  end process;

  dout_b <= blocks(to_integer(unsigned(addr_b)));
end arch;
