library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.automata.all;

entity charlie is
  port (
    rst     : in std_logic;
    clk     : in std_logic;

    -- Matrix
    rows    : out std_logic_vector(MATRIX_HEIGHT-1 downto 0);
    leds    : out std_logic_vector(MATRIX_WIDTH-1 downto 0);
    buttons : in  std_logic_vector(3 downto 0);

    -- I2C
    scl     : in    std_logic;
    sda     : inout std_logic
  );
end charlie;

architecture arch of charlie is
  signal ram_we     : std_logic := '0';
  signal ram_addr_a : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal ram_addr_b : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal ram_din_a  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal ram_dout_b : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

  signal display_clk      : std_logic := '0';
  signal display_row_addr : std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0) := (others => '0');
  signal display_led      : std_logic := '0';
  signal display_lat      : std_logic := '0';
  signal display_oe       : std_logic := '0';

  signal i2c_read_req         : std_logic := '0';
  signal i2c_data_to_master   : std_logic_vector(7 downto 0) := (others => '0');
  signal i2c_data_valid       : std_logic := '0';
  signal i2c_data_from_master : std_logic_vector(7 downto 0) := (others => '0');

  type state is (idle_state, page_state, pwm_state);
  signal state_reg : state := idle_state;
begin
  memory : entity work.memory
    port map (
      rst    => rst,
      clk    => clk,
      we     => ram_we,
      addr_a => ram_addr_a,
      addr_b => ram_addr_b,
      din_a  => ram_din_a,
      dout_b => ram_dout_b
    );

  display : entity work.display
    port map (
      rst      => rst,
      clk_in   => clk,
      clk_out  => display_clk,
      row_addr => display_row_addr,
      led      => display_led,
      lat      => display_lat,
      oe       => display_oe,
      addr     => ram_addr_b,
      data     => ram_dout_b
    );

  matrix_driver : entity work.matrix_driver
    port map (
      rst      => rst,
      clk      => display_clk,
      row_addr => display_row_addr,
      led      => display_led,
      lat      => display_lat,
      oe       => display_oe,
      rows     => rows,
      leds     => leds
    );

  i2c : entity work.i2c_slave
    generic map (
      SLAVE_ADDR => "0000011"
    )
    port map (
      rst              => rst,
      clk              => clk,
      scl              => scl,
      sda              => sda,
      read_req         => i2c_read_req,
      data_to_master   => i2c_data_to_master,
      data_valid       => i2c_data_valid,
      data_from_master => i2c_data_from_master
    );

  i2c_handler : process(clk, state_reg, ram_addr_a, i2c_data_valid, i2c_read_req, i2c_data_from_master)
  begin
    if rising_edge(clk) then
      if i2c_data_valid = '1' then
        ram_we <= '0';

        case state_reg is
          when idle_state =>
            if i2c_data_from_master = x"40" then
              state_reg <= page_state;
            else
              state_reg <= pwm_state;
              ram_addr_a <= i2c_data_from_master(ADDR_WIDTH-1 downto 0);
            end if;
          when page_state =>
            -- TODO: Flip page.
          when pwm_state =>
            state_reg <= idle_state;
            ram_din_a <= i2c_data_from_master;
            ram_we <= '1';
        end case;
      end if;

      if i2c_read_req = '1' then
        i2c_data_to_master <= x"12";
      end if;
    end if;
  end process;
end arch;
