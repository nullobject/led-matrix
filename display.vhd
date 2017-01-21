library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.automata.all;

-- This entity implements a display controller. It continuously refreshes the
-- pixel data from RAM and converts it into display IO signals.
entity display is
  port (
    rst : in std_logic;
    clk : in std_logic;

    -- Display IO
    load     : out std_logic;
    led      : out std_logic;
    lat      : out std_logic;
    oe       : out std_logic;
    row_addr : out std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0);

    -- Memory IO
    addr : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    data : in  std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end display;

architecture arch of display is
  -- Essential state machine signals
  type state_type is (read_pixel_data, incr_ram_addr, incr_row_addr, latch);
  signal state, next_state : state_type;

  -- State machine signals
  signal bpp_count, next_bpp_count : unsigned(MATRIX_BPP-1 downto 0);
  signal s_row_addr, next_row_addr : std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0);
  signal s_ram_addr, next_ram_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal s_led, next_led           : std_logic;
  signal s_oe, next_oe             : std_logic;
  signal inc_row, next_inc_row     : std_logic;
  signal s_load, s_lat             : std_logic;
begin
  load     <= s_load;
  led      <= s_led;
  lat      <= s_lat;
  oe       <= s_oe;
  row_addr <= s_row_addr;
  addr     <= s_ram_addr;

  -- State register
  process(rst, clk)
  begin
    if rst = '1' then
      state      <= read_pixel_data;
      bpp_count  <= (others => '0');
      s_row_addr <= (others => '0');
      s_ram_addr <= (others => '0');
      s_led      <= '0';
      inc_row    <= '0';
      s_oe       <= '0';
    elsif rising_edge(clk) then
      state      <= next_state;
      bpp_count  <= next_bpp_count;
      s_row_addr <= next_row_addr;
      s_ram_addr <= next_ram_addr;
      s_led      <= next_led;
      inc_row    <= next_inc_row;
      s_oe       <= next_oe;
    end if;
  end process;

  -- Next-state logic
  process(state, bpp_count, s_row_addr, s_ram_addr, s_led, s_oe, data) is
  begin
    -- Default register next-state assignments
    next_bpp_count <= bpp_count;
    next_row_addr  <= s_row_addr;
    next_ram_addr  <= s_ram_addr;
    next_led       <= '0';
    next_oe        <= s_oe;
    next_inc_row   <= inc_row;

    -- Default signal assignments
    s_load <= '0';
    s_lat  <= '0';

    -- States
    case state is
      when read_pixel_data =>
        if unsigned(data) > bpp_count then
          next_led <= '1';
        end if;

        next_state <= incr_ram_addr;

      when incr_ram_addr =>
        -- Pulse the output clock.
        s_load <= '1';

        if s_ram_addr(2 downto 0) = "111" then
          if inc_row = '1' then
            next_inc_row <= '0';
            next_oe <= '1';
            next_state <= incr_row_addr;
          elsif bpp_count = unsigned(to_signed(-1, MATRIX_BPP)) then
            next_ram_addr <= std_logic_vector(unsigned(s_ram_addr) + 1);
            next_inc_row <= '1';
            next_state <= latch;
          else
            next_state <= latch;
          end if;
          next_bpp_count <= bpp_count + 1;
        else
          next_ram_addr <= std_logic_vector(unsigned(s_ram_addr) + 1);
          next_state <= read_pixel_data;
        end if;

      when incr_row_addr =>
        -- Increment the row address.
        next_row_addr <= std_logic_vector(unsigned(s_row_addr) + 1);

        next_state <= latch;

      when latch =>
        -- Latch the row.
        s_lat <= '1';

        -- Enable the display.
        next_oe <= '0';

        next_ram_addr <= s_ram_addr(ADDR_WIDTH-1 downto 3) & "000";

        next_state <= read_pixel_data;
    end case;
  end process;
end arch;
