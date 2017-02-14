library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity charlie is
  port (
    rst_in : in std_logic;
    clk : in std_logic;

    -- Display IO
    rows    : out std_logic_vector(7 downto 0);
    cols    : out std_logic_vector(7 downto 0);
    buttons : in  std_logic_vector(7 downto 0);

    -- SPI IO
    ss   : in  std_logic;
    sck  : in  std_logic;
    mosi : in  std_logic;
    miso : out std_logic;

    debug : out std_logic_vector(3 downto 0)
  );
end charlie;

architecture arch of charlie is
  constant DATA_WIDTH : natural := 8;
  constant ADDR_WIDTH : natural := 6;

  constant DISPLAY_WIDTH  : natural := 8;
  constant DISPLAY_HEIGHT : natural := 8;

  signal ram_we, next_ram_we : std_logic;
  signal ram_addr_a, next_ram_addr_a, ram_addr_b : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal ram_din_a, next_ram_din_a, ram_dout_a, ram_dout_b : std_logic_vector(DATA_WIDTH-1 downto 0);

  type state_t is (addr_state, data_state, lol_state, inc_state);
  signal state, next_state : state_t;

  signal spi_rx_data, spi_tx_data, next_spi_tx_data : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal spi_done, spi_req, spi_wren, next_spi_wren, spi_wr_ack : std_logic;

  signal spi_done_reg, spi_req_reg : std_logic_vector(1 downto 0);
  signal spi_done_rising_edge, spi_req_rising_edge : std_logic;

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

  display : entity work.display
    generic map (
      ADDR_WIDTH     => ADDR_WIDTH,
      DATA_WIDTH     => DATA_WIDTH,
      DISPLAY_WIDTH  => DISPLAY_WIDTH,
      DISPLAY_HEIGHT => DISPLAY_HEIGHT
    )
    port map (
      rst          => rst,
      clk          => clk10,
      ram_addr     => ram_addr_b,
      ram_data     => ram_dout_b,
      display_rows => rows,
      display_cols => cols
    );

  spi_slave : entity work.spi_slave
    generic map (
      N => DATA_WIDTH
    )
    port map (
      clk_i => clk50,
      spi_ssel_i => ss,
      spi_sck_i  => sck,
      spi_mosi_i => mosi,
      spi_miso_o => miso,
      do_o => spi_rx_data,
      do_valid_o => spi_done,
      di_i => spi_tx_data,
      di_req_o => spi_req,
      wren_i => spi_wren,
      wr_ack_o => spi_wr_ack,
      state_dbg_o => debug
    );

  spi_fsm_proc : process(state, ss, spi_done_rising_edge, ram_addr_a, ram_din_a, spi_tx_data)
  begin
    next_state <= state;
    next_ram_addr_a <= ram_addr_a;
    next_ram_din_a <= ram_din_a;
    next_ram_we <= '0';
    next_spi_wren <= '0';
    next_spi_tx_data <= spi_tx_data;

    if ss = '1' then
      next_state <= addr_state;
      next_ram_we <= '0';
    else
      case state is
        when addr_state =>
          if spi_done_rising_edge = '1' then
            next_ram_addr_a <= spi_rx_data(ADDR_WIDTH-1 downto 0);
            next_state <= data_state;
          end if;

        when data_state =>
          if spi_req_rising_edge = '1' then
            next_spi_tx_data <= ram_dout_a;
            next_state <= lol_state;
          end if;

          if spi_done_rising_edge = '1' then
            if to_integer(unsigned(ram_addr_a)) < DISPLAY_WIDTH*DISPLAY_HEIGHT then
              -- Only allow writing to the display buffer (0-40h).
              next_ram_we <= '1';
            end if;
            next_ram_din_a <= spi_rx_data;
            next_state <= inc_state;
          end if;

        when lol_state =>
          next_spi_wren <= '1';
          next_state <= data_state;

        when inc_state =>
          next_ram_addr_a <= std_logic_vector(unsigned(ram_addr_a) + 1);
          next_ram_we <= '0';
          next_state <= data_state;
      end case;
    end if;
  end process;

  spi_handler : process(rst, clk50)
  begin
    if rst = '1' then
      state <= addr_state;
    elsif rising_edge(clk50) then
      state <= next_state;
      ram_we <= next_ram_we;
      ram_din_a <= next_ram_din_a;
      ram_addr_a <= next_ram_addr_a;
      spi_tx_data <= next_spi_tx_data;
      spi_wren <= next_spi_wren;

      spi_done_reg <= spi_done_reg(0) & spi_done;
      spi_done_rising_edge <= (not spi_done_reg(1)) and spi_done_reg(0);

      spi_req_reg <= spi_req_reg(0) & spi_req;
      spi_req_rising_edge <= (not spi_req_reg(1)) and spi_req_reg(0);
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
