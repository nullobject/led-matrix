library ieee;

use ieee.std_logic_1164.all;
use ieee.math_real.log2;
use ieee.numeric_std.all;

-- This block implements a display controller. It continuously refreshes the
-- pixel data from RAM and converts it into display IO signals.
entity display is
  generic (
    addr_width     : natural := 6;
    data_width     : natural := 8;
    display_width  : natural := 8;
    display_height : natural := 8
  );
  port (
    rst : in std_logic;
    clk : in std_logic;

    -- Memory IO
    ram_addr : out std_logic_vector(addr_width-1 downto 0);
    ram_data : in  std_logic_vector(data_width-1 downto 0);

    -- Display IO
    display_rows : out std_logic_vector(display_height-1 downto 0);
    display_cols : out std_logic_vector(display_width-1 downto 0)
  );
end display;

architecture arch of display is
  constant DISPLAY_HEIGHT_LOG2 : natural := natural(log2(real(display_height)));
  constant DISPLAY_WIDTH_LOG2  : natural := natural(log2(real(display_width)));

  -- The current pixel value.
  signal pixel : std_logic_vector(7 downto 0);

  -- Essential state machine signals
  type state_type is (read_pixel_data, incr_ram_addr, incr_row_addr, latch);
  signal state, next_state : state_type;

  -- State machine signals
  signal bpp_count, next_bpp_count : unsigned(data_width-1 downto 0);
  signal row, next_row             : std_logic_vector(DISPLAY_HEIGHT_LOG2-1 downto 0);
  signal addr, next_addr           : std_logic_vector(addr_width-1 downto 0);
  signal led, next_led             : std_logic;
  signal oe, next_oe               : std_logic;
  signal inc_row, next_inc_row     : std_logic;
  signal load, lat                 : std_logic;

  signal leds_in, leds_out : std_logic_vector(display_width-1 downto 0);
begin
  gamma : entity work.gamma
    generic map (
      gamma      => 2.8,
      data_width => data_width
    )
    port map (
      data_in  => ram_data,
      data_out => pixel
    );

  ram_addr <= addr;

  -- State register
  process(rst, clk)
  begin
    if rst = '1' then
      state     <= read_pixel_data;
      bpp_count <= (others => '0');
      row       <= (others => '0');
      addr      <= (others => '0');
      led       <= '0';
      inc_row   <= '0';
      oe        <= '0';
    elsif rising_edge(clk) then
      state     <= next_state;
      bpp_count <= next_bpp_count;
      row       <= next_row;
      addr      <= next_addr;
      led       <= next_led;
      inc_row   <= next_inc_row;
      oe        <= next_oe;
    end if;
  end process;

  -- Next-state logic
  process(state, bpp_count, row, addr, led, oe, pixel, inc_row) is
  begin
    -- Default register next-state assignments
    next_bpp_count <= bpp_count;
    next_row       <= row;
    next_addr      <= addr;
    next_led       <= '0';
    next_oe        <= oe;
    next_inc_row   <= inc_row;

    -- Default signal assignments
    load <= '0';
    lat  <= '0';

    -- States
    case state is
      when read_pixel_data =>
        if unsigned(pixel) > bpp_count then
          next_led <= '1';
        end if;

        next_state <= incr_ram_addr;

      when incr_ram_addr =>
        -- Pulse the output clock.
        load <= '1';

        if addr(2 downto 0) = "111" then
          if inc_row = '1' then
            next_inc_row <= '0';
            next_oe <= '1';
            next_state <= incr_row_addr;
          elsif bpp_count = unsigned(to_signed(-1, data_width)) then
            next_addr <= std_logic_vector(unsigned(addr) + 1);
            next_inc_row <= '1';
            next_state <= latch;
          else
            next_state <= latch;
          end if;
          next_bpp_count <= bpp_count + 1;
        else
          next_addr <= std_logic_vector(unsigned(addr) + 1);
          next_state <= read_pixel_data;
        end if;

      when incr_row_addr =>
        -- Increment the row address.
        next_row <= std_logic_vector(unsigned(row) + 1);

        next_state <= latch;

      when latch =>
        -- Latch the row.
        lat <= '1';

        -- Enable the display.
        next_oe <= '0';

        next_addr <= addr(addr_width-1 downto 3) & "000";

        next_state <= read_pixel_data;
    end case;
  end process;

  -- Data on the `led` input is loaded when the `load` signal is high on each rising edge of the `clk` signal.
  process(rst, clk, load)
  begin
    if rst = '1' then
      leds_in <= (others => '0');
    elsif rising_edge(clk) and load = '1' then
      leds_in <= leds_in(display_width-2 downto 0) & led;
    end if;
  end process;

  -- Latch the LEDs when the `lat` signal is high.
  process(clk, lat)
  begin
    if rising_edge(clk) and lat = '1' then
      leds_out <= leds_in;
    end if;
  end process;

  -- Output the LEDs when the `oe` signal is low.
  process(clk)
  begin
    if rising_edge(clk) then
      if oe = '0' then
        display_cols <= leds_out;
      else
        display_cols <= (others => '0');
      end if;
    end if;
  end process;

  with row select
    display_rows <= "10000000" when "111",
                    "01000000" when "110",
                    "00100000" when "101",
                    "00010000" when "100",
                    "00001000" when "011",
                    "00000100" when "010",
                    "00000010" when "001",
                    "00000001" when others;
end arch;
