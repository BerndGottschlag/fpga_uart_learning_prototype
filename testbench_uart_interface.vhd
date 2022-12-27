library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_interface_tb is
end uart_interface_tb;

architecture behave of uart_interface_tb is
	-- 100 MHz -> 10 ns period
	constant c_CLOCK_PERIOD : time := 10 ns;

	signal r_CLOCK : std_logic := '0';
	signal w_TX_BYTE: std_logic_vector(7 downto 0);
	signal w_DATA_AVAILABLE: std_logic := '0';
	signal w_UART_OUTPUT:std_logic;

	-- Component declaration for the Unit Under Test
	component uart_interface is
		port (
			i_clock: in std_logic;
			i_TX_Byte: in std_logic_vector(7 downto 0);
			i_data_available: in std_logic;
			o_uart_tx: out std_logic);
	end component uart_interface;
begin
	-- instantiate the Unit Under Test
	UUT : uart_interface
		port map (
		i_clock => r_CLOCK,
		i_TX_Byte => w_TX_BYTE,
		i_data_available => w_DATA_AVAILABLE,
		o_uart_tx => w_UART_OUTPUT
	);

	p_CLK_GEN : process is
	begin
		wait for c_CLOCK_PERIOD/2;
		r_CLOCK <= not r_CLOCK;
	end process p_CLK_GEN;

	process -- main testing
	begin
		w_TX_BYTE <= X"aa";
		w_DATA_AVAILABLE <= '1';
		wait for 0.00001 sec;
		w_DATA_AVAILABLE <= '0';

		wait for 0.001 sec;
		w_TX_BYTE <= X"55";
		w_DATA_AVAILABLE <= '1';
		wait for 0.00001 sec;
		w_DATA_AVAILABLE <= '0';

		wait for 0.2 sec;
	end process;

end behave;
