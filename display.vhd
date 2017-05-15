library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- This block implements a SH1106 display controller. It continuously refreshes
-- the display data from memory and converts it into SPI signals.
--
-- TODO: To write a page, first write out the contents of the ROM followed by
-- the pixel data. The pixel data will need to be mapped from a sequence of
-- pixels into page/column format.
entity display is
  generic (
    ADDR_WIDTH : natural := 11;
    DATA_WIDTH : natural := 8;
    WIDTH      : natural := 132;
    HEIGHT     : natural := 64
  );
  port (
    clk : in std_logic;
    rst : in std_logic;

    -- Memory IO
    ram_addr : out unsigned(ADDR_WIDTH-1 downto 0);
    ram_data : in  unsigned(DATA_WIDTH-1 downto 0);

    -- Display IO
    ss   : out  std_logic;
    sck  : out  std_logic;
    mosi : out  std_logic;
    dc   : out  std_logic
  );
end display;

architecture arch of display is
  signal rom_addr : unsigned(1 downto 0);
  signal rom_data : unsigned(DATA_WIDTH-1 downto 0);
begin
  display_rom : entity work.rom
    generic map (
      ADDR_WIDTH => 2,
      DATA_WIDTH => DATA_WIDTH
    )
    port map (
      clk  => clk,
      addr => rom_addr,
      data => rom_data
    );

  ram_addr <= (others => '0');
  ss <= '0';
  sck <= '0';
  mosi <= '0';
  ss <= '0';
end arch;
