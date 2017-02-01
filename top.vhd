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

  signal ram_we : std_logic;
  signal ram_addr_a, next_ram_addr_a, ram_addr_b : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal ram_din_a, ram_dout_a, ram_dout_b : std_logic_vector(DATA_WIDTH-1 downto 0);

  type state_t is (addr_state, data_state, inc_state);
  signal state : state_t;

  signal spi_rx_data, spi_tx_data : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal spi_done : std_logic;
  signal spi_done_reg : std_logic_vector(1 downto 0);
  signal spi_done_rising_edge : std_logic;

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
      addr_width     => ADDR_WIDTH,
      data_width     => DATA_WIDTH,
      display_width  => DISPLAY_WIDTH,
      display_height => DISPLAY_HEIGHT
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
      di_req_o => open,
      di_i => spi_tx_data,
      wren_i => open,
      wr_ack_o => open,
      do_valid_o => spi_done,
      do_o => spi_rx_data,
      state_dbg_o => debug
    );

  spi_handler : process(rst, clk50)
  begin
    if rst = '1' then
      state <= addr_state;
    elsif rising_edge(clk50) then
      ram_we <= '0';
      spi_done_reg <= spi_done_reg(0) & spi_done;
      spi_done_rising_edge <= (not spi_done_reg(1)) and spi_done_reg(0);

      if ss = '1' then
        state <= addr_state;
      else
        case state is
        when addr_state =>
          if spi_done_rising_edge = '1' then
            ram_addr_a <= spi_rx_data(ADDR_WIDTH-1 downto 0);
            state <= data_state;
          end if;

        when data_state =>
          if spi_done_rising_edge = '1' then
            if to_integer(unsigned(ram_addr_a)) < DISPLAY_WIDTH*DISPLAY_HEIGHT then
              -- Only allow writing to the display buffer (0-40h).
              ram_we <= '1';
            end if;
            next_ram_addr_a <= std_logic_vector(unsigned(ram_addr_a) + 1);
            ram_din_a <= spi_rx_data;
            state <= inc_state;
          else
            spi_tx_data <= ram_dout_a;
          end if;

        when inc_state =>
          ram_addr_a <= next_ram_addr_a;
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
