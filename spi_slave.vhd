library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.automata.all;

entity spi_slave is
	port (
		reset        : in  std_logic;
		clk          : in  std_logic;
		spi_clk      : in std_logic;
		spi_ss       : in std_logic;
		spi_mosi     : in  std_logic;
		spi_miso     : out std_logic;
		spi_done     : out std_logic;
		DataToTx     : in std_logic_vector(7 downto 0);
		DataToTxLoad : in std_logic;
		DataRxd      : out std_logic_vector(7 downto 0)
  );
end spi_slave;

architecture Behavioral of spi_slave is
  signal TxData : std_logic_vector(7 downto 0);
  signal index: natural range 0 to 7;
  signal RxdData : std_logic_vector(7 downto 0);

  signal spi_clk_reg, spi_ss_reg : std_logic_vector(2 downto 0);
  signal spi_mosi_reg : std_logic_vector(1 downto 0);
  signal spi_clk_rising_edge, spi_clk_falling_edge, spi_ss_rising_edge, spi_ss_falling_edge : std_logic;
begin

 --
 -- Sync process
 --

process(clk, reset)
begin
  if reset = '1' then
    index <= 0;
    RxdData <= (others => '0');
    TxData <= (others => '0');
    spi_done <= '0';

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

    if DataToTxLoad = '1' then
      TxData <= DataToTx;
    end if;

    if spi_ss_falling_edge = '1' then
      index <= 0;
    end if;

    if spi_clk_rising_edge = '1' then
      -- if rising_edge(spi_clk) then
        index <= index + 1;
        RxdData <= RxdData(6 downto 0) & spi_mosi_reg(1);
      elsif spi_clk_falling_edge = '1' then
      -- elsif falling_edge(spi_clk) then
        if (index = 0) then
          spi_done <= '1';
        end if;
        TxData <= TxData(6 downto 0) & '1';
      end if;
    end if;
  end process;

	 --
	 -- Combinational assignments
	 --

	 spi_miso <= TxData(7);
	 DataRxd <= RxdData;

end Behavioral;
