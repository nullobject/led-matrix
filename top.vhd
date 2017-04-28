library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity charlie is
  port (
    rst_in: in std_logic;
    clk:    in std_logic;

    -- Display IO
    rows:    out unsigned(7 downto 0);
    cols:    out unsigned(7 downto 0);
    buttons: in  unsigned(7 downto 0);

    -- SPI
    ss:   in  std_logic;
    sck:  in  std_logic;
    mosi: in  std_logic;
    miso: out std_logic;

    debug: out std_logic_vector(3 downto 0)
  );
end charlie;

architecture arch of charlie is
  constant DATA_WIDTH: natural := 8;
  constant ADDR_WIDTH: natural := 6;

  constant DISPLAY_WIDTH:  natural := 8;
  constant DISPLAY_HEIGHT: natural := 8;

  type state_type is (RESET_STATE, ADDR_STATE, WAIT_STATE, DATA_STATE, INC_STATE);
  signal state, next_state: state_type;

  signal ram_we, next_ram_we: std_logic;
  signal ram_addr_a, next_ram_addr_a, ram_addr_b: unsigned(ADDR_WIDTH-1 downto 0);
  signal ram_din_a, next_ram_din_a, ram_dout_a, ram_dout_b: unsigned(DATA_WIDTH-1 downto 0);

  signal spi_rx_data, spi_tx_data, next_spi_tx_data: std_logic_vector(DATA_WIDTH-1 downto 0);
  signal spi_done, spi_req, spi_wren, next_spi_wren, spi_wr_ack: std_logic;

  signal clk10, clk50, locked, rst: std_logic;
begin
  clock_generator: entity work.clock_generator
    port map (
      clkin_in        => clk,
      rst_in          => rst_in,
      clkfx_out       => clk10,
      clkin_ibufg_out => open,
      clk0_out        => clk50,
      locked_out      => locked
    );

  memory: entity work.memory
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      DATA_WIDTH => DATA_WIDTH
    )
    port map (
      clk    => clk50,
      we     => ram_we,
      addr_a => ram_addr_a,
      din_a  => ram_din_a,
      dout_a => ram_dout_a,
      addr_b => ram_addr_b,
      dout_b => ram_dout_b
    );

  display: entity work.display
    generic map (
      ADDR_WIDTH     => ADDR_WIDTH,
      DATA_WIDTH     => DATA_WIDTH,
      DISPLAY_WIDTH  => DISPLAY_WIDTH,
      DISPLAY_HEIGHT => DISPLAY_HEIGHT
    )
    port map (
      rst          => rst,
      clk          => clk50,
      ram_addr     => ram_addr_b,
      ram_data     => ram_dout_b,
      matrix_rows  => rows,
      matrix_cols  => cols
    );

  spi_slave: entity work.spi_slave
    generic map (
      N => DATA_WIDTH
    )
    port map (
      clk_i       => clk50,
      spi_ssel_i  => ss,
      spi_sck_i   => sck,
      spi_mosi_i  => mosi,
      spi_miso_o  => miso,
      do_o        => spi_rx_data,
      do_valid_o  => spi_done,
      di_i        => spi_tx_data,
      di_req_o    => spi_req,
      wren_i      => spi_wren,
      wr_ack_o    => spi_wr_ack,
      state_dbg_o => debug
    );

  sync_proc: process(rst, clk50, ss)
  begin
    if rst = '1' or ss = '1' then
      state <= RESET_STATE;
    elsif rising_edge(clk50) then
      state <= next_state;
      ram_we <= next_ram_we;
      ram_addr_a <= next_ram_addr_a;
      ram_din_a <= next_ram_din_a;
      spi_wren <= next_spi_wren;
    end if;
  end process sync_proc;

  comb_proc: process(state, spi_rx_data, spi_done, ram_addr_a)
  begin
    -- Default register assignments.
    next_state      <= state;
    next_ram_addr_a <= ram_addr_a;
    next_ram_din_a  <= ram_din_a;
    next_ram_we     <= '0';

    case state is
    -- Reset the state machine.
    when RESET_STATE =>
      next_state <= ADDR_STATE;

    -- Wait for data to be received.
    when ADDR_STATE =>
      if spi_done = '1' then
        next_ram_addr_a <= unsigned(spi_rx_data(ADDR_WIDTH-1 downto 0));
        next_state <= WAIT_STATE;
      end if;

    when WAIT_STATE =>
      if spi_done = '0' then
        next_state <= DATA_STATE;
      end if;

    -- Read the next byte.
    when DATA_STATE =>
      if spi_done = '1' then
        -- Only allow writing to the display buffer (0-40h).
        if to_integer(ram_addr_a) < DISPLAY_WIDTH*DISPLAY_HEIGHT then
          next_ram_we <= '1';
        end if;
        next_ram_din_a <= unsigned(spi_rx_data);
        next_state <= INC_STATE;
      end if;

    when INC_STATE =>
      if spi_done = '0' then
        next_ram_addr_a <= ram_addr_a + 1;
        next_state <= DATA_STATE;
      end if;
    end case;
  end process comb_proc;

  -- button_driver: entity work.button_driver
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
