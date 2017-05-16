library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- This block implements a SH1106 display controller. It continuously refreshes
-- the display data from memory and converts it into SPI signals.
--
-- TODO: To write a page, first write out the contents of the ROM followed by
-- the pixel data. The pixel data will need to be mapped from a sequence of
-- pixels into page/column format.
entity display is
  generic (
    ADDR_WIDTH : natural := 11;
    DATA_WIDTH : natural := 8;
    WIDTH      : natural := 132;
    HEIGHT     : natural := 64
  );
  port (
    clk : in std_logic;
    rst : in std_logic;

    -- Memory IO
    ram_addr : out unsigned(ADDR_WIDTH-1 downto 0);
    ram_data : in  unsigned(DATA_WIDTH-1 downto 0);

    -- Display IO
    display_ss   : out  std_logic;
    display_sck  : out  std_logic;
    display_mosi : out  std_logic;
    display_dc   : out  std_logic;
    display_rst  : out  std_logic
  );
end display;

architecture arch of display is
  type rom_type is array (0 to 24) of unsigned(7 downto 0);

  -- This ROM contains the sequence of commands to initialise the display.
  constant ROM : rom_type := (
    X"ae",        -- display off, sleep mode
    X"d5", X"80", -- clock divide ratio (0x00=1) and oscillator frequency (0x8)
    X"a8", X"3f", -- multiplex ratio, duty = 1/32
    X"d3", X"00", -- set display offset
    X"40",        -- start line
    X"8d", X"14", -- [2] charge pump setting (p62): 0x014 enable, 0x010 disable
    X"20", X"00", -- 2012-05-27: page addressing mode
    X"a1",        -- segment remap a0/a1
    X"c8",        -- c0: scan dir normal, c8: reverse
    X"da", X"12", -- com pin HW config, sequential com pin config (bit 4), disable left/right remap (bit 5)
    X"81", X"cf", -- [2] set contrast control
    X"d9", X"f1", -- [2] pre-charge period 0x022/f1
    X"db", X"40", -- vcomh deselect level
    X"2e",        -- 2012-05-27: Deactivate scroll
    X"a4",        -- output ram to display
    X"a6"
  );

  type state_type is (RESET_STATE, INIT_STATE, COMMAND_STATE, DATA_STATE);
  signal state, next_state : state_type;

  -- Address counter
  signal address_ctr : unsigned(ADDR_WIDTH-1 downto 0);

  -- ROM data
  signal rom_data : unsigned(DATA_WIDTH-1 downto 0);

  signal output_data, next_output_data : unsigned(DATA_WIDTH-1 downto 0);
begin
  -- Updates the address counter according to the increment flags.
  addr_proc : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        address_ctr <= (others => '0');
      else
        address_ctr <= address_ctr + 1;
      end if;
    end if;
  end process addr_proc;

  main_proc : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state <= RESET_STATE;
      else
        -- Update the current state.
        state <= next_state;
      end if;
    end if;
  end process main_proc;

  comb_proc : process(state, address_ctr) is
  begin
    -- Default register assignments.
    next_state <= state;
    display_dc <= '0';
    next_output_data <= output_data;

    case state is
    -- Reset the state machine.
    when RESET_STATE =>
      next_state <= INIT_STATE;

    -- Initialise the display.
    when INIT_STATE =>
      next_state <= COMMAND_STATE;

      -- digitalWriteFast(OLED_RST, HIGH);
      -- delay(1);
      -- digitalWriteFast(OLED_RST, LOW);
      -- delay(10);
      -- digitalWriteFast(OLED_RST, HIGH);

      -- digitalWriteFast(OLED_CS, OLED_CS_INACTIVE);
      -- digitalWriteFast(OLED_DC, LOW);

      -- digitalWriteFast(OLED_RST, LOW);
      -- delay(20);
      -- digitalWriteFast(OLED_RST, HIGH);
      -- delay(20);

      -- digitalWriteFast(OLED_CS, OLED_CS_ACTIVE);

      -- SPI_send(SH1106_init_seq, sizeof(SH1106_init_seq));

      -- digitalWriteFast(OLED_CS, OLED_CS_INACTIVE);

    -- Prepare to send a page of data.
    when COMMAND_STATE =>
      -- digitalWriteFast(OLED_DC, LOW);
      display_dc <= '0';

      next_output_data <= rom_data;

      if address_ctr(2 downto 0) = "111" then -- end of ROM
        next_state <= DATA_STATE;
      end if;

      -- digitalWriteFast(OLED_CS, OLED_CS_ACTIVE);
      -- SPI_send(SH1106_data_start_seq, sizeof(SH1106_data_start_seq));

    -- Send a page of data.
    when DATA_STATE =>
      -- digitalWriteFast(OLED_DC, HIGH);
      display_dc <= '1';

      if address_ctr = 0 then -- end of page
        next_state <= COMMAND_STATE;
      end if;

      -- SPI_send(data, kPageSize);
      -- digitalWriteFast(OLED_CS, OLED_CS_INACTIVE);
    end case;
  end process comb_proc;

  -- Set the RAM address.
  ram_addr <= address_ctr;

  display_ss <= '0';
  display_sck <= '0';
  display_mosi <= '0';
  display_rst <= '0';
end arch;
