library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.automata.all;

entity charlie is
  port (
    rst_in : in std_logic;
    clk : in std_logic;

    -- Matrix
    rows    : out std_logic_vector(MATRIX_HEIGHT-1 downto 0);
    leds    : out std_logic_vector(MATRIX_WIDTH-1 downto 0);
    buttons : in  std_logic_vector(3 downto 0);

    -- I2C
    scl : in    std_logic;
    sda : inout std_logic
  );
end charlie;

architecture arch of charlie is
  signal ram_we     : std_logic;
  signal ram_addr_a : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal ram_addr_b : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal ram_din_a  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal ram_dout_b : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal display_load     : std_logic;
  signal display_led      : std_logic;
  signal display_lat      : std_logic;
  signal display_oe       : std_logic;
  signal display_row_addr : std_logic_vector(MATRIX_HEIGHT_LOG2-1 downto 0);

  signal i2c_read_req         : std_logic;
  signal i2c_data_to_master   : std_logic_vector(7 downto 0);
  signal i2c_data_valid       : std_logic;
  signal i2c_data_from_master : std_logic_vector(7 downto 0);

  type state is (idle_state, page_state, pwm_state);
  signal state_reg : state;

  signal clk10, clk100, locked, rst : std_logic;
begin
  clock_generator : entity work.clock_generator
    port map (
  		clkin_in        => clk,
      rst_in          => rst_in,
  		clkfx_out       => clk10,
  		clkin_ibufg_out => open,
  		clk0_out        => clk100,
      locked_out      => locked
  	);

  memory : entity work.memory
    port map (
      rst    => rst,
      clk    => clk100,
      we     => ram_we,
      addr_a => ram_addr_a,
      addr_b => ram_addr_b,
      din_a  => ram_din_a,
      dout_b => ram_dout_b
    );

  display : entity work.display
    port map (
      rst      => rst,
      clk      => clk10,
      load     => display_load,
      led      => display_led,
      lat      => display_lat,
      oe       => display_oe,
      row_addr => display_row_addr,
      addr     => ram_addr_b,
      data     => ram_dout_b
    );

  matrix_driver : entity work.matrix_driver
    port map (
      rst      => rst,
      clk      => clk10,
      load     => display_load,
      led      => display_led,
      lat      => display_lat,
      oe       => display_oe,
      row_addr => display_row_addr,
      rows     => rows,
      leds     => leds
    );

  button_driver : entity work.button_driver
    port map (
      rst      => rst,
      clk      => clk100,
      row_addr => display_row_addr,
      addr     => ram_addr_a,
      data     => ram_din_a,
      we       => ram_we,
      buttons  => buttons
    );

  i2c : entity work.i2c_slave
    generic map (
      SLAVE_ADDR => "0000011"
    )
    port map (
      rst              => rst,
      clk              => clk100,
      scl              => scl,
      sda              => sda,
      read_req         => i2c_read_req,
      data_to_master   => i2c_data_to_master,
      data_valid       => i2c_data_valid,
      data_from_master => i2c_data_from_master
    );

  -- i2c_handler : process(rst, clk100)
  -- begin
  --   if rst = '1' then
  --     state_reg <= idle_state;
  --   elsif rising_edge(clk100) then
  --     if i2c_data_valid = '1' then
  --       ram_we <= '0';
  --
  --       case state_reg is
  --         when idle_state =>
  --           if i2c_data_from_master = x"40" then
  --             state_reg <= page_state;
  --           else
  --             state_reg <= pwm_state;
  --             ram_addr_a <= i2c_data_from_master(ADDR_WIDTH-1 downto 0);
  --           end if;
  --         when page_state =>
  --           -- TODO: Flip page.
  --         when pwm_state =>
  --           state_reg <= idle_state;
  --           ram_din_a <= i2c_data_from_master;
  --           ram_we <= '1';
  --       end case;
  --     end if;
  --
  --     if i2c_read_req = '1' then
  --       i2c_data_to_master <= x"12";
  --     end if;
  --   end if;
  -- end process;

  rst <= not locked;
end arch;
