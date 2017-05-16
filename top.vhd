library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity charlie is
  port (
    rst_in : in std_logic;
    clk    : in std_logic;

    -- SPI
    ss   : in  std_logic;
    sck  : in  std_logic;
    mosi : in  std_logic;
    miso : out std_logic;

    -- Matrix IO
    rows    : out unsigned(7 downto 0);
    cols    : out unsigned(7 downto 0);
    buttons : in  unsigned(7 downto 0);

    -- Display IO
    display_ss   : out std_logic;
    display_sck  : out std_logic;
    display_mosi : out std_logic;
    display_dc   : out std_logic;
    display_rst  : out std_logic
  );
end charlie;

architecture arch of charlie is
  constant DISPLAY_RAM_ADDR_WIDTH : natural := 12;
  constant DISPLAY_RAM_DATA_WIDTH : natural := 8;
  constant DISPLAY_ADDR_WIDTH     : natural := 11;
  constant DISPLAY_DATA_WIDTH     : natural := 8;
  constant DISPLAY_WIDTH          : natural := 132;
  constant DISPLAY_HEIGHT         : natural := 64;

  constant MATRIX_RAM_ADDR_WIDTH : natural := 7;
  constant MATRIX_RAM_DATA_WIDTH : natural := 8;
  constant MATRIX_ADDR_WIDTH     : natural := 6;
  constant MATRIX_DATA_WIDTH     : natural := 8;
  constant MATRIX_WIDTH          : natural := 8;
  constant MATRIX_HEIGHT         : natural := 8;

  constant SPI_DATA_WIDTH : natural := 8;

  constant READ_COMMAND      : integer := 0;
  constant WRITE_COMMAND     : integer := 1;
  constant FLIP_PAGE_COMMAND : integer := 2;

  type state_type is (RESET_STATE, CMD_STATE, CMD_WAIT_STATE, WRITE_STATE, READ_STATE, READ_INC_STATE, WRITE_INC_STATE);
  signal state, next_state : state_type;

  signal clk10, clk50, locked, rst : std_logic;

  signal matrix_ram_we, next_matrix_ram_we : std_logic;
  signal matrix_ram_addr_a : unsigned(MATRIX_RAM_ADDR_WIDTH-1 downto 0);
  signal matrix_ram_addr_b : unsigned(MATRIX_RAM_ADDR_WIDTH-1 downto 0);
  signal matrix_ram_din_a, next_matrix_ram_din_a, matrix_ram_dout_a, matrix_ram_dout_b : unsigned(MATRIX_RAM_DATA_WIDTH-1 downto 0);

  signal display_ram_we, next_display_ram_we : std_logic;
  signal display_ram_addr_a : unsigned(DISPLAY_RAM_ADDR_WIDTH-1 downto 0);
  signal display_ram_addr_b : unsigned(DISPLAY_RAM_ADDR_WIDTH-1 downto 0);
  signal display_ram_din_a, next_display_ram_din_a, display_ram_dout_a, display_ram_dout_b : unsigned(DISPLAY_RAM_DATA_WIDTH-1 downto 0);

  signal spi_rx_data, spi_tx_data, next_spi_tx_data : std_logic_vector(MATRIX_RAM_DATA_WIDTH-1 downto 0);
  signal spi_done, spi_req, spi_wren, next_spi_wren, spi_wr_ack : std_logic;

  signal write_en, next_write_en : std_logic;

  signal display_row_addr : unsigned(2 downto 0);

  -- The current page in memory being displayed.
  signal page, next_page : std_logic;

  signal paged_display_addr : unsigned(DISPLAY_ADDR_WIDTH-1 downto 0);
  signal paged_matrix_addr : unsigned(MATRIX_ADDR_WIDTH-1 downto 0);
  signal paged_matrix_ram_addr, next_paged_matrix_ram_addr : unsigned(MATRIX_ADDR_WIDTH-1 downto 0);
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

  display_ram : entity work.memory
    generic map (
      ADDR_WIDTH => DISPLAY_RAM_ADDR_WIDTH,
      DATA_WIDTH => DISPLAY_RAM_DATA_WIDTH
    )
    port map (
      clk    => clk50,
      we     => display_ram_we,
      addr_a => display_ram_addr_a,
      din_a  => display_ram_din_a,
      dout_a => display_ram_dout_a,
      addr_b => display_ram_addr_b,
      dout_b => display_ram_dout_b
    );

  matrix_ram : entity work.memory
    generic map (
      ADDR_WIDTH => MATRIX_RAM_ADDR_WIDTH,
      DATA_WIDTH => MATRIX_RAM_DATA_WIDTH
    )
    port map (
      clk    => clk50,
      we     => matrix_ram_we,
      addr_a => matrix_ram_addr_a,
      din_a  => matrix_ram_din_a,
      dout_a => matrix_ram_dout_a,
      addr_b => matrix_ram_addr_b,
      dout_b => matrix_ram_dout_b
    );

  display : entity work.display
    generic map (
      ADDR_WIDTH => DISPLAY_ADDR_WIDTH,
      DATA_WIDTH => DISPLAY_DATA_WIDTH,
      WIDTH      => DISPLAY_WIDTH,
      HEIGHT     => DISPLAY_HEIGHT
    )
    port map (
      clk          => clk50,
      rst          => rst,
      ram_addr     => paged_display_addr,
      ram_data     => display_ram_dout_b,
      display_ss   => display_ss,
      display_sck  => display_sck,
      display_mosi => display_mosi,
      display_dc   => display_dc,
      display_rst  => display_rst
    );

  matrix : entity work.matrix
    generic map (
      ADDR_WIDTH => MATRIX_ADDR_WIDTH,
      DATA_WIDTH => MATRIX_DATA_WIDTH,
      WIDTH      => MATRIX_WIDTH,
      HEIGHT     => MATRIX_HEIGHT
    )
    port map (
      clk         => clk50,
      rst         => rst,
      ram_addr    => paged_matrix_addr,
      ram_data    => matrix_ram_dout_b,
      matrix_rows => rows,
      matrix_cols => cols,
      row_addr    => display_row_addr
    );

  spi_slave : entity work.spi_slave
    generic map (
      N => SPI_DATA_WIDTH
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
      state_dbg_o => open
    );

  sync_proc : process(clk50)
  begin
    if rising_edge(clk50) then
      if rst = '1' or ss = '1' then
        state <= RESET_STATE;
      else
        state <= next_state;
        matrix_ram_we <= next_matrix_ram_we;
        paged_matrix_ram_addr <= next_paged_matrix_ram_addr;
        matrix_ram_din_a <= next_matrix_ram_din_a;
        spi_tx_data <= next_spi_tx_data;
        -- TODO: Debug SPI.
        -- spi_tx_data <= (others => '1');
        -- spi_wren <= next_spi_wren;
        spi_wren <= '1';
        write_en <= next_write_en;
        page <= next_page;
      end if;
    end if;
  end process sync_proc;

  comb_proc : process(state, spi_done, spi_req, write_en)
  begin
    -- Default register assignments.
    next_state                 <= state;
    next_matrix_ram_we         <= '0';
    next_paged_matrix_ram_addr <= paged_matrix_ram_addr;
    next_matrix_ram_din_a      <= matrix_ram_din_a;
    next_spi_tx_data           <= spi_tx_data;
    next_spi_wren              <= '0';
    next_write_en              <= write_en;
    next_page                  <= page;

    case state is
    -- Reset the state machine.
    when RESET_STATE =>
      next_state <= CMD_STATE;
      next_paged_matrix_ram_addr <= (others => '0');
      next_matrix_ram_din_a <= (others => '0');
      next_spi_tx_data <= (others => '0');
      next_write_en <= '0';

    -- Wait for a command.
    when CMD_STATE =>
      if spi_done = '1' then
        next_state <= CMD_WAIT_STATE;

        case to_integer(unsigned(spi_rx_data)) is
        when READ_COMMAND =>
          next_write_en <= '0';
        when WRITE_COMMAND =>
          next_write_en <= '1';
        when FLIP_PAGE_COMMAND =>
          next_page <= not page;
          next_state <= RESET_STATE;
        when others =>
          next_state <= RESET_STATE;
        end case;
      end if;

    when CMD_WAIT_STATE =>
      if spi_done = '0' then
        if write_en = '1' then
          next_state <= WRITE_STATE;
        else
          next_state <= READ_STATE;

          -- Why does this need to be set here? It must have started writing requesting the SPI data at this point.
          next_spi_tx_data <= std_logic_vector(matrix_ram_dout_a);
          next_paged_matrix_ram_addr <= paged_matrix_ram_addr + 1;
        end if;
      end if;

    when READ_STATE =>
      if spi_req = '1' then
        next_state <= READ_INC_STATE;
        next_spi_tx_data <= std_logic_vector(matrix_ram_dout_a);
      end if;

    when READ_INC_STATE =>
      if spi_req = '0' then
        next_state <= READ_STATE;

        -- Only allow reading the display buffer (0-40h).
        if to_integer(paged_matrix_ram_addr) < MATRIX_WIDTH*MATRIX_HEIGHT then
          next_spi_wren <= '1';
        end if;

        next_paged_matrix_ram_addr <= paged_matrix_ram_addr + 1;
      end if;

    when WRITE_STATE =>
      if spi_done = '1' then
        next_state <= WRITE_INC_STATE;

        -- Only allow writing the display buffer (0-40h).
        if to_integer(paged_matrix_ram_addr) < MATRIX_WIDTH*MATRIX_HEIGHT then
          next_matrix_ram_we <= '1';
        end if;

        next_matrix_ram_din_a <= unsigned(spi_rx_data);
      end if;

    when WRITE_INC_STATE =>
      if spi_done = '0' then
        next_state <= WRITE_STATE;
        next_paged_matrix_ram_addr <= paged_matrix_ram_addr + 1;
      end if;

    when others =>
      next_state <= RESET_STATE;
    end case;
  end process comb_proc;

  rst <= not locked;

  -- Data is read from/written to one page, while display data is read from the
  -- other page.
  display_ram_addr_b <= page & paged_display_addr;
  matrix_ram_addr_a <= page & paged_matrix_ram_addr;
  matrix_ram_addr_b <= (not page) & paged_matrix_addr;
end arch;
