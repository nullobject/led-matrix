library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.automata.all;

entity button_driver is
  port (
    rst : in std_logic;
    clk : in std_logic;

    -- Display IO
    row_addr : in std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0);

    -- Memory IO
    addr : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    data : out  std_logic_vector(DATA_WIDTH-1 downto 0);
    we   : out  std_logic;

    -- Matrix IO
    buttons : in std_logic_vector(3 downto 0)
  );
end button_driver;

architecture arch of button_driver is
begin
  process(rst, clk)
  begin
    if rst = '1' then
    elsif rising_edge(clk) then
      we <= '1';
      addr <= "000000";
      if buttons(0) = '1' then
        data <= x"ff";
      else
        data <= x"00";
      end if;
    end if;
  end process;
end arch;