library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity uart_interface is
	port (
		i_clock: in std_logic; -- assumes 100 MHz
		i_tx_byte: in std_logic_vector(7 downto 0);
		i_data_available: in std_logic;
		o_uart_tx: out std_logic
	);
end uart_interface;

architecture rtl of uart_interface is
	constant c_UART_TX_CLOCK_COUNTER_MAX_VALUE: natural := 434; -- clk * duty_cycle/target_frequency = 100 MHz * 0.5/(115200 baud) = 434
	constant c_NUMBER_OF_DATA_BITS: natural := 8;

	signal r_UART_CLOCK_COUNTER: natural range 0 to c_UART_TX_CLOCK_COUNTER_MAX_VALUE;
	signal r_DATA_BITS_COUNTER: natural range 0 to c_NUMBER_OF_DATA_BITS;
	signal r_STOP_BITS_COUNTER: natural range 0 to c_NUMBER_OF_DATA_BITS;

	type t_PACKET_PHASE is (IDLE, START_BIT, DATA_PHASE, STOP_BIT);
	signal r_PACKET_PHASE : t_PACKET_PHASE := IDLE;


	signal r_TEMP_TEST_DATA: std_logic := '0';
begin
	p_Send_Data: process (i_clock) is
	begin
		if (rising_edge(i_clock)) then
			if (r_UART_CLOCK_COUNTER < c_UART_TX_CLOCK_COUNTER_MAX_VALUE) then
				r_UART_CLOCK_COUNTER <= r_UART_CLOCK_COUNTER + 1;
			else
				r_UART_CLOCK_COUNTER <= 0;

				if (r_PACKET_PHASE = IDLE) then -- TODO: no idle phase needed between packets needed

					if (i_data_available = '1') then
						o_uart_tx <= '1';

						r_PACKET_PHASE <= START_BIT;
					end if;
				elsif (r_PACKET_PHASE = START_BIT) then
					-- send one start bit (tx line low)
					o_uart_tx <= '0';

					r_PACKET_PHASE <= DATA_PHASE;
					r_DATA_BITS_COUNTER <= 0;
				elsif (r_PACKET_PHASE = DATA_PHASE) then
					-- clock out data bits
					if (r_DATA_BITS_COUNTER < c_NUMBER_OF_DATA_BITS - 1) then
						o_uart_tx <= i_tx_byte(r_DATA_BITS_COUNTER);
						r_TEMP_TEST_DATA <= not r_TEMP_TEST_DATA;
						r_DATA_BITS_COUNTER <= r_DATA_BITS_COUNTER + 1;
					else
						o_uart_tx <= i_tx_byte(r_DATA_BITS_COUNTER);
						r_TEMP_TEST_DATA <= not r_TEMP_TEST_DATA;

						r_DATA_BITS_COUNTER <= 0;
						r_PACKET_PHASE <= STOP_BIT;
					end if;
				elsif (r_PACKET_PHASE = STOP_BIT) then
					o_uart_tx <= '1';
					r_PACKET_PHASE <= IDLE;
				else
					r_PACKET_PHASE <= IDLE;
				end if;
			end if;
		end if;
	end process p_Send_Data;
end rtl;
