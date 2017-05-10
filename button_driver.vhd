library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity button_driver is
  generic (
    DISPLAY_ADDR_WIDTH : natural := 6;
    RAM_DATA_WIDTH : natural := 8;
    DISPLAY_WIDTH  : natural := 8
  );
  port (
    clk : in std_logic;
    rst : in std_logic;

    -- Button IO
    buttons : in unsigned(DISPLAY_WIDTH-1 downto 0);

    -- Memory IO
    ram_addr : out unsigned(DISPLAY_ADDR_WIDTH-1 downto 0);
    ram_data : out unsigned(RAM_DATA_WIDTH-1 downto 0);
    ram_we   : out std_logic;

    -- Display IO
    row_addr : in unsigned(2 downto 0)
  );
end button_driver;

architecture arch of button_driver is
  signal counter : unsigned(2 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        counter <= (others => '0');
      else
        ram_we <= '1';
        ram_addr <= row_addr & counter;
        if buttons(to_integer(counter)) = '1' then
          ram_data <= x"ff";
        else
          ram_data <= (others => '0');
        end if;
        counter <= counter + 1;
      end if;
    end if;
  end process;
end arch;
