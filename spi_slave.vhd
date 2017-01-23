library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.automata.all;

entity spi_slave is
	port (
		reset    : in  std_logic;
		clk      : in  std_logic;
		spi_clk     : in std_logic;
		spi_ss      : in std_logic;
		spi_mosi    : in  std_logic;
		spi_miso    : out std_logic;
		spi_done    : out std_logic;
		DataToTx    : in std_logic_vector(7 downto 0);
		DataToTxLoad: in std_logic;
		DataRxd     : out std_logic_vector(7 downto 0)
		);
end spi_slave;

architecture Behavioral of spi_slave is

		signal SCLK_latched, SCLK_old : std_logic;
		signal SS_latched, SS_old : std_logic;
		signal MOSI_latched: std_logic;
		signal TxData : std_logic_vector(7 downto 0);
		signal index: natural range 0 to 7;
		signal RxdData : std_logic_vector(7 downto 0);

begin

 --
 -- Sync process
 --

process(clk, reset)
begin
  if (reset = '1') then
    RxdData <= (others => '0');
    index <= 7;
    TxData <= (others => '0');
    SCLK_old <= '0';
    SCLK_latched <= '0';
    SS_old <= '0';
    SS_latched <= '0';
    spi_done <= '0';
    MOSI_latched <= '0';

  elsif( rising_edge(clk) ) then

    SCLK_latched <= spi_clk;
    SCLK_old <= SCLK_latched;
    SS_latched <= spi_ss;
    SS_old <= SS_latched;
    spi_done <= '0';
    MOSI_latched <= spi_mosi;

    if(DataToTxLoad = '1') then
      TxData <= DataToTx;
    end if;

    if (SS_old = '1' and SS_latched = '0') then
      index <= 7;
    end if;

    if( SS_latched = '0' ) then
       if(SCLK_old = '0' and SCLK_latched = '1') then
       -- if(rising_edge(spi_clk)) then
         RxdData <= RxdData(6 downto 0) & MOSI_latched;
         if(index = 0) then -- cycle ended
           index <= 7;
         else
           index <= index-1;
         end if;
       elsif(SCLK_old = '1' and SCLK_latched = '0') then
       -- elsif(falling_edge(spi_clk)) then
         if( index = 7 ) then
           spi_done <= '1';
         end if;
         TxData <= TxData(6 downto 0) & '1';
       end if;
     end if;
   end if;
  end process;

	 --
	 -- Combinational assignments
	 --

	 spi_miso <= TxData(7);
	 DataRxd <= RxdData;

end Behavioral;
