library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.automata.all;

entity charlie is
  port (
    rst_in : in std_logic;
    clk : in std_logic;

    -- Display IO
    rows    : out std_logic_vector(DISPLAY_HEIGHT-1 downto 0);
    cols    : out std_logic_vector(DISPLAY_WIDTH-1 downto 0);
    buttons : in  std_logic_vector(DISPLAY_WIDTH-1 downto 0);

    -- SPI IO
    ss   : in std_logic;
    sck  : in std_logic;
    mosi : in std_logic;
    miso : out std_logic
  );
end charlie;

architecture arch of charlie is
  signal ram_we     : std_logic;
  signal ram_addr_a, next_ram_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal ram_din_a  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal ram_addr_b : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal ram_dout_b : std_logic_vector(DATA_WIDTH-1 downto 0);

  type state_t is (addr_state, data_state, inc_state);
  signal state : state_t;

  signal spi_rx_data : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal spi_done : std_logic;

  signal clk10, clk50, locked, rst : std_logic;
begin
  clock_generator : entity work.clock_generator
    port map (
      clkin_in        => clk,
      rst_in          => rst_in,
      clkfx_out       => clk10,
      clkin_ibufg_out => open,
      clk0_out        => clk50,
      locked_out      => locked
    );

  memory : entity work.memory
    generic map (
      addr_width => ADDR_WIDTH,
      data_width => DATA_WIDTH
    )
    port map (
      rst    => rst,
      clk    => clk50,
      we     => ram_we,
      addr_a => ram_addr_a,
      din_a  => ram_din_a,
      addr_b => ram_addr_b,
      dout_b => ram_dout_b
    );

  display : entity work.display
    port map (
      rst          => rst,
      clk          => clk10,
      ram_addr     => ram_addr_b,
      ram_data     => ram_dout_b,
      display_rows => rows,
      display_cols => cols
    );

  spi_slave : entity work.spi_slave
    port map (
      rst      => rst,
      clk      => clk50,
      spi_ss   => ss,
      spi_clk  => sck,
      spi_mosi => mosi,
      spi_miso => miso,
      spi_rxd  => spi_rx_data,
      spi_done => spi_done
    );

  spi_handler : process(rst, clk50, spi_done)
  begin
    if rst = '1' then
      state <= addr_state;
    elsif rising_edge(clk50) then
      ram_we <= '0';

      if ss = '1' then
        state <= addr_state;
      else
        case state is
        when addr_state =>
          if spi_done = '1' then
            ram_addr_a <= spi_rx_data(ADDR_WIDTH-1 downto 0);
            state <= data_state;
          end if;

        when data_state =>
          if spi_done = '1' then
            ram_we <= '1';
            next_ram_addr <= ram_addr_a + 1;
            ram_din_a <= spi_rx_data;
            state <= inc_state;
          end if;

        when inc_state =>
          ram_addr_a <= next_ram_addr;
          state <= data_state;

        end case;
      end if;
    end if;
  end process;

  -- button_driver : entity work.button_driver
  --   port map (
  --     rst      => rst,
  --     clk      => clk50,
  --     row_addr => display_row_addr,
  --     addr     => ram_addr_a,
  --     data     => ram_din_a,
  --     we       => ram_we,
  --     buttons  => buttons
  --   );

  rst <= not locked;
end arch;
