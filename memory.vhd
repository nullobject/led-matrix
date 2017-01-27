library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This block implements a clocked dual-port asynchronous RAM. Port A is
-- read/write signals, port B is read-only.
entity memory is
  generic (
    addr_width : natural := 8;
    data_width : natural := 8
  );
  port (
    rst : in std_logic;
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
begin
  process(clk, we, addr_a, din_a)
  begin
    if rst = '1' then
      ram <= (others => (others => '0'));
    elsif rising_edge(clk) and we = '1' then
      ram(to_integer(unsigned(addr_a))) <= din_a;
    end if;
  end process;

  dout_a <= ram(to_integer(unsigned(addr_a)));
  dout_b <= ram(to_integer(unsigned(addr_b)));
end arch;
