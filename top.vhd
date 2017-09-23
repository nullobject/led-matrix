library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity charlie is
  port (
    rst_in : in std_logic;
    clk    : in std_logic;

    -- Display IO
    rows    : out unsigned(7 downto 0);
    cols    : out unsigned(7 downto 0);
    buttons : in  unsigned(7 downto 0);

    -- SPI
    ss   : in  std_logic;
    sck  : in  std_logic;
    mosi : in  std_logic;
    miso : out std_logic;

    debug : out std_logic_vector(3 downto 0)
  );
end charlie;

architecture arch of charlie is
  constant RAM_ADDR_WIDTH : natural := 7;
  constant RAM_DATA_WIDTH : natural := 8;

  constant DISPLAY_ADDR_WIDTH : natural := 6;
  constant DISPLAY_DATA_WIDTH : natural := 8;

  constant SPI_DATA_WIDTH : natural := 8;

  constant DISPLAY_WIDTH  : natural := 8;
  constant DISPLAY_HEIGHT : natural := 8;

  constant READ_COMMAND      : integer := 0;
  constant WRITE_COMMAND     : integer := 1;
  constant FLIP_PAGE_COMMAND : integer := 2;

  type state_type is (RESET_STATE, CMD_STATE, CMD_WAIT_STATE, WRITE_STATE, READ_STATE, READ_INC_STATE, WRITE_INC_STATE);
  signal state, next_state : state_type;

  signal clk10, clk50, locked, rst : std_logic;

  signal ram_we, next_ram_we : std_logic;
  signal ram_addr_a : unsigned(RAM_ADDR_WIDTH-1 downto 0);
  signal ram_addr_b : unsigned(RAM_ADDR_WIDTH-1 downto 0);
  signal ram_din_a, next_ram_din_a, ram_dout_a, ram_dout_b : unsigned(RAM_DATA_WIDTH-1 downto 0);

  signal spi_dout, spi_din, next_spi_din : std_logic_vector(RAM_DATA_WIDTH-1 downto 0);
  signal spi_din_vld, next_spi_din_vld, spi_dout_vld : std_logic;

  signal write_en, next_write_en : std_logic;

  signal display_row_addr : unsigned(2 downto 0);

  -- The current page in memory being displayed.
  signal page, next_page : std_logic;

  signal paged_display_addr : unsigned(DISPLAY_ADDR_WIDTH-1 downto 0);
  signal paged_ram_addr, next_paged_ram_addr : unsigned(DISPLAY_ADDR_WIDTH-1 downto 0);
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

  ram : entity work.memory
    generic map (
      ADDR_WIDTH => RAM_ADDR_WIDTH,
      DATA_WIDTH => RAM_DATA_WIDTH
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
      ADDR_WIDTH     => DISPLAY_ADDR_WIDTH,
      DATA_WIDTH     => DISPLAY_DATA_WIDTH,
      DISPLAY_WIDTH  => DISPLAY_WIDTH,
      DISPLAY_HEIGHT => DISPLAY_HEIGHT
    )
    port map (
      rst          => rst,
      clk          => clk50,
      ram_addr     => paged_display_addr,
      ram_data     => ram_dout_b,
      matrix_rows  => rows,
      matrix_cols  => cols,
      row_addr     => display_row_addr
    );

  spi_slave : entity work.spi_slave
    port map (
      clk      => clk50,
      rst      => rst,
      ss       => ss,
      mosi     => mosi,
      miso     => miso,
      sck      => sck,
      din      => spi_din,
      din_vld  => spi_din_vld,
      dout     => spi_dout,
      dout_vld => spi_dout_vld
    );

  sync_proc : process(clk50)
  begin
    if rising_edge(clk50) then
      if rst = '1' or ss = '1' then
        state <= RESET_STATE;
      else
        state <= next_state;
        ram_we <= next_ram_we;
        paged_ram_addr <= next_paged_ram_addr;
        ram_din_a <= next_ram_din_a;
        spi_din <= next_spi_din;
        spi_din_vld <= next_spi_din_vld;
        write_en <= next_write_en;
        page <= next_page;
      end if;
    end if;
  end process sync_proc;

  comb_proc : process(state, write_en)
  begin
    -- Default register assignments.
    next_state          <= state;
    next_ram_we         <= '0';
    next_paged_ram_addr <= paged_ram_addr;
    next_ram_din_a      <= ram_din_a;
    next_spi_din        <= spi_din;
    next_spi_din_vld    <= '0';
    next_write_en       <= write_en;
    next_page           <= page;

    case state is
    -- Reset the state machine.
    when RESET_STATE =>
      next_state <= CMD_STATE;
      next_paged_ram_addr <= (others => '0');
      next_ram_din_a <= (others => '0');
      next_spi_din <= (others => '0');
      next_write_en <= '0';

    -- Wait for a command.
    when CMD_STATE =>
      if spi_dout_vld = '1' then
        next_state <= CMD_WAIT_STATE;

        case to_integer(unsigned(spi_dout)) is
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
      if spi_dout_vld = '0' then
        if write_en = '1' then
          next_state <= WRITE_STATE;
        else
          next_state <= READ_STATE;
          next_paged_ram_addr <= paged_ram_addr + 1;
        end if;
      end if;

    when READ_STATE =>
      if spi_dout_vld = '1' then
        next_state <= READ_INC_STATE;
        next_spi_din <= std_logic_vector(ram_dout_a);
      end if;

    when READ_INC_STATE =>
      if spi_dout_vld = '0' then
        next_state <= READ_STATE;

        -- Only allow reading the display buffer (0-40h).
        if to_integer(paged_ram_addr) < DISPLAY_WIDTH*DISPLAY_HEIGHT then
          next_spi_din_vld <= '1';
        end if;

        next_paged_ram_addr <= paged_ram_addr + 1;
      end if;

    when WRITE_STATE =>
      if spi_dout_vld = '1' then
        next_state <= WRITE_INC_STATE;

        -- Only allow writing the display buffer (0-40h).
        if to_integer(paged_ram_addr) < DISPLAY_WIDTH*DISPLAY_HEIGHT then
          next_ram_we <= '1';
        end if;

        next_ram_din_a <= unsigned(spi_dout);
      end if;

    when WRITE_INC_STATE =>
      if spi_dout_vld = '0' then
        next_state <= WRITE_STATE;
        next_paged_ram_addr <= paged_ram_addr + 1;
      end if;

    when others =>
      next_state <= RESET_STATE;
    end case;
  end process comb_proc;

  rst <= not locked;

  -- Data is read from/written to one page, while display data is read from the
  -- other page.
  ram_addr_a <= page & paged_ram_addr;
  ram_addr_b <= (not page) & paged_display_addr;
end arch;
