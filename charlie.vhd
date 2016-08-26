library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity charlie is
  port (
    clock  : in std_logic;
    row    : out std_logic_vector(3 downto 0);
    column : out std_logic_vector(7 downto 0);
    scl    : inout std_logic;
    sda    : inout std_logic
  );
end charlie;

architecture charlie_arch of charlie is
  signal clock_enable : std_logic;

  type state_type is (idle_state, pwm_state);
  signal state_reg : state_type := idle_state;

  type pwm_type is array (0 to 7) of unsigned(7 downto 0);
  signal pwm : pwm_type := (x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00");

  signal i2c_read_req             : std_logic                    := '0';
  signal i2c_data_to_master       : std_logic_vector(7 downto 0) := (others => '0');
  signal i2c_data_valid           : std_logic                    := '0';
  signal i2c_data_from_master     : std_logic_vector(7 downto 0) := (others => '0');

  signal address_reg : unsigned(7 downto 0) := (others => '0');
begin
  i2c : entity work.i2c_slave(arch)
    generic map (
      SLAVE_ADDR => "0000011"
    )
    port map (
      clk              => clock,
      scl              => scl,
      sda              => sda,
      rst              => '0',
      read_req         => i2c_read_req,
      data_to_master   => i2c_data_to_master,
      data_valid       => i2c_data_valid,
      data_from_master => i2c_data_from_master
    );

  i2c_handler : process(clock, state_reg, address_reg, i2c_data_valid, i2c_read_req, i2c_data_from_master)
  begin
    if rising_edge(clock) then
      if i2c_data_valid = '1' then
        case state_reg is
          when idle_state =>
            address_reg <= unsigned(i2c_data_from_master);
            state_reg <= pwm_state;
          when pwm_state =>
            pwm(to_integer(address_reg)) <= unsigned(i2c_data_from_master);
            state_reg <= idle_state;
        end case;
      end if;

      if i2c_read_req = '1' then
        i2c_data_to_master <= x"12";
      end if;
    end if;
  end process;

  clock_divider : process(clock)
    variable counter : unsigned(15 downto 0) := (others => '0');
  begin
    if rising_edge(clock) then
      counter := counter + 1;

      if counter = 0 then
        clock_enable <= '1';
      else
        clock_enable <= '0';
      end if;
    end if;
  end process;

  row_scan : process(clock, clock_enable)
    variable row_counter : unsigned(3 downto 0) := "0001";
  begin
    if rising_edge(clock) and clock_enable = '1' then
      row_counter := row_counter rol 1;
      row <= std_logic_vector(row_counter);
    end if;
  end process;

  column_pwm : process(clock)
    variable counter : unsigned(7 downto 0) := (others => '0');
  begin
    if rising_edge(clock) then
      counter := counter + 1;

      for i in 0 to 6 loop
        if counter < pwm(i) then
          column(i) <= '1';
        else
          column(i) <= '0';
        end if;
      end loop;
    end if;
  end process;
end charlie_arch;
