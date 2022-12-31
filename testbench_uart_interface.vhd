library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_interface_tb is
end uart_interface_tb;

architecture behave of uart_interface_tb is
	-- 100 MHz -> 10 ns period
	constant c_CLOCK_PERIOD : time := 10 ns;

	signal r_CLOCK : std_logic := '0';
	signal w_UART_OUTPUT: std_logic;

	signal w_UART_TX_FIFO_RESET: std_logic := '0';
	signal w_UART_TX_FIFO_WRITE_ENABLE: std_logic := '0';
	signal w_UART_TX_FIFO_WRITE_DATA: std_logic_vector(7 downto 0);
	signal w_UART_TX_FIFO_FULL: std_logic := '0';

	-- Component declaration for the Unit Under Test
	component uart_interface is
		port (
			i_clock: in std_logic;
			o_uart_tx: out std_logic;
			-- Tx FIFO interface
			i_tx_fifo_reset: in std_logic;
			i_tx_fifo_write_enable: in std_logic;
			i_tx_fifo_write_data: in std_logic_vector(8-1 downto 0);
			o_tx_fifo_full: in std_logic);
	end component uart_interface;
begin
	-- instantiate the Unit Under Test
	UUT : uart_interface
		port map (
		i_clock => r_CLOCK,
		o_uart_tx => w_UART_OUTPUT,

		-- Tx FIFO
		i_tx_fifo_reset => w_UART_TX_FIFO_RESET,
		i_tx_fifo_write_enable => w_UART_TX_FIFO_WRITE_ENABLE,
		i_tx_fifo_write_data => w_UART_TX_FIFO_WRITE_DATA,
		o_tx_fifo_full => w_UART_TX_FIFO_FULL
	);

	p_CLK_GEN : process is
	begin
		wait for c_CLOCK_PERIOD/2;
		r_CLOCK <= not r_CLOCK;
	end process p_CLK_GEN;

	process -- main testing
	begin
		w_UART_TX_FIFO_WRITE_ENABLE <= '1';
		w_UART_TX_FIFO_WRITE_DATA <= X"aa";
		wait for c_CLOCK_PERIOD;

		w_UART_TX_FIFO_WRITE_ENABLE <= '1';
		w_UART_TX_FIFO_WRITE_DATA <= X"55";
		wait for c_CLOCK_PERIOD;
		w_UART_TX_FIFO_WRITE_ENABLE <= '0';

		wait for 30 us;

		w_UART_TX_FIFO_WRITE_ENABLE <= '1';
		w_UART_TX_FIFO_WRITE_DATA <= X"F0";
		wait for c_CLOCK_PERIOD;
		w_UART_TX_FIFO_WRITE_ENABLE <= '0';

		wait for 0.2 sec;
	end process;

end behave;
