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
  type state_type is (read_pixel_data, incr_ram_addr, incr_row_addr, latch, latch_row);
  signal state, next_state : state_type := read_pixel_data;

  -- State machine signals
  signal bpp_count, next_bpp_count  : unsigned(MATRIX_BPP-1 downto 0) := (others => '0');
  signal s_row_addr, next_row_addr  : std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0) := (others => '0');
  signal s_ram_addr, next_ram_addr  : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal s_led, next_led            : std_logic := '0';
  signal s_clk_out, s_lat, s_oe     : std_logic;
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
      state      <= read_pixel_data;
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
    s_oe      <= '0';

    -- States
    case state is
      when read_pixel_data =>
        if unsigned(data) > bpp_count then
          next_led <= '1';
        end if;

        next_state <= incr_ram_addr;

      when incr_ram_addr =>
        -- Pulse the output clock.
        s_clk_out <= '1';

        if s_ram_addr(2 downto 0) = "111" then
          if bpp_count = unsigned(to_signed(-1, MATRIX_BPP)) then
            next_bpp_count <= (others => '0');
            next_ram_addr <= std_logic_vector(unsigned(s_ram_addr) + 1);
            next_state <= incr_row_addr;
          else
            next_bpp_count <= bpp_count + 1;
            next_ram_addr <= s_ram_addr(ADDR_WIDTH-1 downto 3) & "000";
            next_state <= latch;
          end if;
        else
          next_ram_addr <= std_logic_vector(unsigned(s_ram_addr) + 1);
          next_state <= read_pixel_data;
        end if;

      when incr_row_addr =>
        -- Disable the display.
        s_oe <= '1';

        -- Increment the row address.
        next_row_addr <= std_logic_vector(unsigned(s_row_addr) + 1);

        next_state <= latch_row;

      when latch =>
        -- Latch the row.
        s_lat <= '1';

        next_state <= read_pixel_data;

      when latch_row =>
        -- Disable the display.
        s_oe <= '1';

        -- Latch the row.
        s_lat <= '1';

        next_state <= read_pixel_data;
    end case;
  end process;
end arch;
