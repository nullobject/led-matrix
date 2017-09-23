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
    din  : in std_logic_vector(7 downto 0); -- input data for master
    dout : out std_logic_vector(7 downto 0); -- output data from master
    done : out std_logic -- when done = 1, output data are valid
  );
end spi_slave;

architecture rtl of spi_slave is
  signal sck_reg, old_sck_reg : std_logic;
  signal sck_redge, sck_fedge : std_logic;
  signal bit_ctr : unsigned(2 downto 0);

  signal ss_reg, next_ss_reg : std_logic;
  signal mosi_reg, next_mosi_reg : std_logic;
  signal miso_reg, next_miso_reg : std_logic;
  signal data_reg, next_data_reg : std_logic_vector(7 downto 0);
  signal dout_reg, next_dout_reg : std_logic_vector(7 downto 0);
  signal done_reg, next_done_reg : std_logic;
begin
  -- Synchronises SCK to the local clock domain.
  clk_proc : process(clk)
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

  -- Increments the counter on a rising SCK edge.
  cnt_proc : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' or ss_reg = '1' then
        bit_ctr <= (others => '0');
      elsif sck_redge = '1' then
        bit_ctr <= bit_ctr + 1;
      end if;
    end if;
  end process;

  main_proc : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        miso_reg <= '1';
        dout_reg <= (others => '0');
        done_reg <= '0';
      else
        miso_reg <= next_miso_reg;
        dout_reg <= next_dout_reg;
        done_reg <= next_done_reg;
      end if;

      ss_reg   <= next_ss_reg;
      mosi_reg <= next_mosi_reg;
      data_reg <= next_data_reg;
    end if;
  end process;

  comb_proc : process(ss, ss_reg, sck_redge, sck_fedge, mosi, mosi_reg, miso_reg, data_reg, dout_reg, din, bit_ctr)
  begin
    next_ss_reg   <= ss;
    next_mosi_reg <= mosi;
    next_miso_reg <= miso_reg;
    next_data_reg <= data_reg;
    next_dout_reg <= dout_reg;
    next_done_reg <= '0';

    if ss_reg = '1' then
      next_data_reg <= din;
      next_miso_reg <= data_reg(7);
    else
      if sck_redge = '1' then
        next_data_reg <= data_reg(6 downto 0) & mosi_reg;

        if bit_ctr = "111" then
          next_dout_reg <= data_reg(6 downto 0) & mosi_reg;
          next_done_reg <= '1';
          next_data_reg <= din;
        end if;
      elsif sck_fedge = '1' then
        next_miso_reg <= data_reg(7);
      end if;
    end if;
  end process;

  sck_redge <= not old_sck_reg and sck_reg;
  sck_fedge <= old_sck_reg and not sck_reg;

  miso <= miso_reg;
  dout <= dout_reg;
  done <= done_reg;
end rtl;
