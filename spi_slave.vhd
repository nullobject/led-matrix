library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_slave is
  Port (
    clk : in std_logic;
    rst : in std_logic;

    -- SPI
    sck  : in std_logic;
    ss   : in std_logic;
    mosi : in std_logic;
    miso : out std_logic;

    -- IO
    din      : in std_logic_vector(7 downto 0); -- input data for master
    din_vld  : in std_logic; -- when din_vld = 1, input data are valid and can be accept
    dout     : out std_logic_vector(7 downto 0); -- output data from master
    dout_vld : out std_logic -- when dout_vld = 1, output data are valid
  );
end spi_slave;

architecture rtl of spi_slave is
  signal sck_reg, old_sck_reg : std_logic;
  signal sck_redge, sck_fedge : std_logic;
  signal bit_ctr : unsigned(2 downto 0);
  signal data_reg : std_logic_vector(7 downto 0);
begin
  -- -------------------------------------------------------------------------
  -- SPI CLOCK REGISTER
  -- -------------------------------------------------------------------------

  sck_redge <= not old_sck_reg and sck_reg;
  sck_fedge <= old_sck_reg and not sck_reg;

  spi_clk_reg_p : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        sck_reg <= '0';
        old_sck_reg <= '0';
      else
        sck_reg <= sck;
        old_sck_reg <= sck_reg;
      end if;
    end if;
  end process;

  -- -------------------------------------------------------------------------
  -- BIT COUNTER
  -- -------------------------------------------------------------------------

  -- Increments the counter on a rising SCK edge.
  bit_cnt_p : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' or ss = '1' then
        bit_ctr <= (others => '0');
      elsif sck_redge = '1' then
        bit_ctr <= bit_ctr + 1;
      end if;
    end if;
  end process;

  -- -------------------------------------------------------------------------
  -- DATA SHIFT REGISTER
  -- -------------------------------------------------------------------------

  data_reg_p : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        data_reg <= (others => '0');
        dout_vld <= '0';
      elsif ss = '1' then
        data_reg <= din;
        dout_vld <= '0';
      elsif sck_redge = '1' then
        if bit_ctr = "111" then
          dout <= data_reg(6 downto 0) & mosi;
          data_reg <= din;
          dout_vld <= '1';
        else
          data_reg <= data_reg(6 downto 0) & mosi;
          dout_vld <= '0';
        end if;
      end if;
    end if;
  end process;

  -- -------------------------------------------------------------------------
  -- MISO REGISTER
  -- -------------------------------------------------------------------------

  miso_p : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        miso <= '1';
      elsif ss = '1' or sck_fedge = '1' then
        miso <= data_reg(7);
      end if;
    end if;
  end process;
end rtl;
