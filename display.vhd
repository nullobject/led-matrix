library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.automata.all;

entity display is
  port (
    rst     : in std_logic;
    clk_in  : in std_logic;
    clk_out : out std_logic;

    -- Display IO
    row_addr : out std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0);
    led      : out std_logic;
    lat      : out std_logic;
    oe       : out std_logic;

    -- Memory IO
    addr : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    data : in  std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end display;

architecture arch of display is
  signal clk : std_logic := '0';

  -- Essential state machine signals
  type STATE_TYPE is (INIT, READ_PIXEL_DATA, INCR_RAM_ADDR, LATCH, INCR_ROW_ADDR);
  signal state : STATE_TYPE := INIT;
  signal next_state : STATE_TYPE;

  -- State machine signals
  signal bpp_count, next_bpp_count  : unsigned(MATRIX_BPP-1 downto 0) := (others => '0');
  signal s_row_addr,  next_row_addr : std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0) := (others => '0');
  signal s_ram_addr, next_ram_addr  : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal s_led, next_led            : std_logic := '0';
  signal s_oe, s_lat, s_clk_out     : std_logic;
begin
  clock_divider : entity work.clock_divider
    generic map (
      clk_in_freq  => 50000000, -- 50MHz input clock
      clk_out_freq => 10000000  -- 10MHz output clock
    )
    port map (
      rst     => rst,
      clk_in  => clk_in,
      clk_out => clk
    );

  row_addr <= s_row_addr;
  addr     <= s_ram_addr;
  led      <= s_led;
  oe       <= s_oe;
  lat      <= s_lat;
  clk_out  <= s_clk_out;

  -- State register
  process(rst, clk)
  begin
    if rst = '1' then
      state      <= INIT;
      bpp_count  <= (others => '0');
      s_row_addr <= (others => '0');
      s_ram_addr <= (others => '0');
      s_led      <= '0';
    elsif rising_edge(clk) then
      state      <= next_state;
      bpp_count  <= next_bpp_count;
      s_row_addr <= next_row_addr;
      s_ram_addr <= next_ram_addr;
      s_led      <= next_led;
    end if;
  end process;

  -- Next-state logic
  process(state, bpp_count, s_row_addr, s_ram_addr, s_led, data) is
  begin
    -- Default register next-state assignments
    next_bpp_count <= bpp_count;
    next_row_addr  <= s_row_addr;
    next_ram_addr  <= s_ram_addr;
    next_led       <= '0';

    -- Default signal assignments
    s_clk_out <= '0';
    s_lat     <= '0';
    s_oe      <= '1';

    -- States
    case state is
      when INIT =>
        next_state <= READ_PIXEL_DATA;

      when READ_PIXEL_DATA =>
        -- Enable the display.
        s_oe <= '0';

        if unsigned(data) > bpp_count then
          next_led <= '1';
        end if;

        next_state <= INCR_RAM_ADDR;

      when INCR_RAM_ADDR =>
        -- Enable the display.
        s_oe <= '0';

        -- Pulse the output clock.
        s_clk_out <= '1';

        -- Increment the RAM address.
        if s_ram_addr(2 downto 0) /= "111" then
          next_ram_addr <= std_logic_vector(unsigned(s_ram_addr) + 1);
          next_state <= READ_PIXEL_DATA;
        else
          next_state <= LATCH;
        end if;

      when LATCH =>
        -- Latch the row.
        s_lat <= '1';

        if bpp_count = unsigned(to_signed(-1, MATRIX_BPP)) then
          next_bpp_count <= (others => '0');
          next_state <= INCR_ROW_ADDR;
        else
          next_bpp_count <= bpp_count + 1;
          next_ram_addr <= s_ram_addr(ADDR_WIDTH-1 downto 3) & "000";
          next_state <= READ_PIXEL_DATA;
        end if;

      when INCR_ROW_ADDR =>
        next_ram_addr <= std_logic_vector(unsigned(s_ram_addr) + 1);
        next_row_addr <= std_logic_vector(unsigned(s_row_addr) + 1);
        next_state <= INIT;

      when others => null;
    end case;
  end process;
end arch;
