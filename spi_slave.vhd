library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This block implements an SPI slave controller. It was adapted from the
-- fpga4fun site (https://fpga4fun.com/SPI2.html).
entity spi_slave is
  port (
    rst : in std_logic;
    clk : in std_logic;

    -- SPI IO
    spi_clk  : in  std_logic;
    spi_ss   : in  std_logic;
    spi_mosi : in  std_logic;
    spi_miso : out std_logic;
    spi_done : out std_logic;
    spi_rxd  : out std_logic_vector(7 downto 0);
    spi_txd  : in  std_logic_vector(7 downto 0)
  );
end spi_slave;

architecture arch of spi_slave is
  signal count: natural range 0 to 7;
  signal din, dout : std_logic_vector(7 downto 0);

  signal spi_clk_reg, spi_ss_reg : std_logic_vector(2 downto 0);
  signal spi_mosi_reg : std_logic_vector(1 downto 0);
  signal spi_clk_rising_edge, spi_clk_falling_edge, spi_ss_rising_edge, spi_ss_falling_edge : std_logic;
begin
  process(clk, rst, spi_clk)
  begin
    if rst = '1' then
      count <= 0;
      din <= (others => '0');
      spi_done <= '0';
      spi_miso <= 'Z';

      spi_clk_reg <= (others => '0');
      spi_ss_reg  <= (others => '0');
      spi_mosi_reg <= (others => '0');
    elsif rising_edge(clk) then
      spi_clk_reg <= spi_clk_reg(1 downto 0) & spi_clk;
      spi_clk_rising_edge <= (not spi_clk_reg(2)) and spi_clk_reg(1);
      spi_clk_falling_edge <= spi_clk_reg(2) and (not spi_clk_reg(1));

      spi_ss_reg <= spi_ss_reg(1 downto 0) & spi_ss;
      spi_ss_rising_edge <= (not spi_ss_reg(2)) and spi_ss_reg(1);
      spi_ss_falling_edge <= spi_ss_reg(2) and (not spi_ss_reg(1));

      spi_mosi_reg <= spi_mosi_reg(0) & spi_mosi;

      spi_done <= '0';

      if spi_ss_falling_edge = '1' then
        -- The first output bit is written on the SS falling edge.
        dout <= spi_txd;
      elsif spi_ss_reg(1) = '0' then
        if spi_clk_rising_edge = '1' then
          -- The input is read on the clock rising edge.
          din <= din(6 downto 0) & spi_mosi_reg(1);
          count <= count + 1;
        elsif spi_clk_falling_edge = '1' then
          if count = 0 then
            spi_done <= '1';
            dout <= spi_txd;
          else
            dout <= dout(6 downto 0) & '0';
          end if;
        end if;
      else
        count <= 0;
      end if;
    end if;
  end process;

  spi_miso <= dout(7);
  spi_rxd <= din;
end arch;
