library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_slave is
  port (
    rst      : in  std_logic;
    spi_clk  : in  std_logic;
    spi_ss   : in  std_logic;
    spi_mosi : in  std_logic;
    spi_miso : out std_logic := '0';
    spi_done : out std_logic;
    spi_ack  : in  std_logic;
    spi_rxd  : out std_logic_vector(7 downto 0)
  );
end spi_slave;

architecture arch of spi_slave is
  signal index: natural range 0 to 7;
  signal spi_rxd_reg : std_logic_vector(6 downto 0);
begin
  process(rst, spi_clk, spi_ss, spi_mosi, spi_ack)
  begin
    if rst = '1' then
      index <= 0;
      spi_rxd_reg <= (others => '0');
      spi_done <= '0';
    else
      if spi_ack = '1' then
        spi_done <= '0';

        if rising_edge(spi_clk) then
          if spi_ss = '0' then
            index <= index + 1;
            spi_rxd_reg <= spi_rxd_reg(5 downto 0) & spi_mosi;
          end if;
        end if;
      else
        if rising_edge(spi_clk) then
          if spi_ss = '0' then
            if index = 7 then
              spi_rxd <= spi_rxd_reg(6 downto 0) & spi_mosi;
              spi_done <= '1';
              index <= 0;
              spi_rxd_reg <= (others => '0');
            else
              index <= index + 1;
              spi_rxd_reg <= spi_rxd_reg(5 downto 0) & spi_mosi;
            end if;
          else
            index <= 0;
            spi_rxd_reg <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process;
end arch;
