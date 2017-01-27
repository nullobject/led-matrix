library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This block implements a dual-port synchronous BRAM. Port A is read/write
-- signals, port B is read-only.
--
-- Adapted from the VHDL Prototyping By Examples book (p251).
entity memory is
  generic (
    addr_width : natural := 8;
    data_width : natural := 8
  );
  port (
    clk : in std_logic;
    we  : in std_logic;

    -- Port A
    addr_a : in  std_logic_vector(addr_width-1 downto 0);
    din_a  : in  std_logic_vector(data_width-1 downto 0);
    dout_a : out std_logic_vector(data_width-1 downto 0);

    -- Port B
    addr_b : in  std_logic_vector(addr_width-1 downto 0);
    dout_b : out std_logic_vector(data_width-1 downto 0)
  );
end memory;

architecture arch of memory is
  type ram_type is array (0 to 2**addr_width-1) of std_logic_vector(data_width-1 downto 0);
  signal ram : ram_type;
  signal addr_a_reg, addr_b_reg : std_logic_vector(addr_width-1 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        ram(to_integer(unsigned(addr_a))) <= din_a;
      end if;

      addr_a_reg <= addr_a;
      addr_b_reg <= addr_b;
    end if;
  end process;

  dout_a <= ram(to_integer(unsigned(addr_a_reg)));
  dout_b <= ram(to_integer(unsigned(addr_b_reg)));
end arch;
