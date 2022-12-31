library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity uart_interface is
	port (
		i_clock: in std_logic; -- assumes 100 MHz
		o_uart_tx: out std_logic;

		-- Tx FIFO interface
		i_tx_fifo_reset: in std_logic;
		i_tx_fifo_write_enable: in std_logic;
		i_tx_fifo_write_data: in std_logic_vector(8-1 downto 0);
		o_tx_fifo_full: in std_logic
	);
end uart_interface;

architecture rtl of uart_interface is
	constant c_UART_TX_CLOCK_COUNTER_MAX_VALUE: natural := 434; -- clk * duty_cycle/target_frequency = 100 MHz * 0.5/(115200 baud) = 434
	constant c_NUMBER_OF_DATA_BITS: natural := 8;

	type t_PACKET_PHASE is (IDLE, START_BIT, DATA_PHASE, STOP_BIT);

	-- Tx process
	signal r_TX_UART_CLOCK_COUNTER: natural range 0 to c_UART_TX_CLOCK_COUNTER_MAX_VALUE;
	signal r_TX_DATA_BITS_COUNTER: natural range 0 to c_NUMBER_OF_DATA_BITS;
	signal r_TX_STOP_BITS_COUNTER: natural range 0 to c_NUMBER_OF_DATA_BITS;

	signal r_TX_PACKET_PHASE : t_PACKET_PHASE := IDLE;

	signal r_TX_BYTE: std_logic_vector(c_NUMBER_OF_DATA_BITS-1 downto 0);

	signal r_TX_FIFO_READ_ENABLE: std_logic := '0';
	signal r_TX_FIFO_READ_DATA: std_logic_vector(c_NUMBER_OF_DATA_BITS-1 downto 0);
	signal r_TX_FIFO_EMPTY: std_logic := '0';
	signal r_TX_FIFO_FULL: std_logic := '0';


	component fifo_module is
		port (
			i_clk : in std_logic;
			i_reset_fifo : in std_logic;

			-- FIFO write interface:
			i_write_enable : in std_logic;
			i_write_data : in std_logic_vector(c_NUMBER_OF_DATA_BITS-1 downto 0);
			o_fifo_full : out std_logic;

			-- FIFO read interface:
			i_read_enable : in std_logic;
			o_read_data : out std_logic_vector(c_NUMBER_OF_DATA_BITS-1 downto 0);
			o_fifo_empty : out std_logic
		);
	end component fifo_module;
begin
	-- instantiate the Tx FIFO
	TX_FIFO : fifo_module
		port map (
		i_clk => i_clock,
		i_reset_fifo => i_tx_fifo_reset,

		-- FIFO write interface:
		i_write_enable => i_tx_fifo_write_enable,
		i_write_data => i_tx_fifo_write_data,
		o_fifo_full => r_TX_FIFO_FULL,

		-- FIFO read interface:
		i_read_enable => r_TX_FIFO_READ_ENABLE,
		o_read_data => r_TX_FIFO_READ_DATA,
		o_fifo_empty => r_TX_FIFO_EMPTY
	);


	p_Send_Data: process (i_clock) is
	begin
		if (rising_edge(i_clock)) then
			if (r_TX_UART_CLOCK_COUNTER < c_UART_TX_CLOCK_COUNTER_MAX_VALUE) then
				r_TX_UART_CLOCK_COUNTER <= r_TX_UART_CLOCK_COUNTER + 1;

				r_TX_FIFO_READ_ENABLE <= '0';
			else
				r_TX_UART_CLOCK_COUNTER <= 0;

				if (r_TX_PACKET_PHASE = IDLE) then
					if (r_TX_FIFO_EMPTY = '0') then
						r_TX_FIFO_READ_ENABLE <= '1';
						r_TX_BYTE <= r_TX_FIFO_READ_DATA;

						r_TX_PACKET_PHASE <= START_BIT;
					end if;
				elsif (r_TX_PACKET_PHASE = START_BIT) then

					r_TX_FIFO_READ_ENABLE <= '0'; -- disable FIFO write to avoid popping further elements from the FIFO
					-- send one start bit (tx line low)
					o_uart_tx <= '0';

					r_TX_PACKET_PHASE <= DATA_PHASE;
					r_TX_DATA_BITS_COUNTER <= 0;
				elsif (r_TX_PACKET_PHASE = DATA_PHASE) then
					-- clock out data bits
					if (r_TX_DATA_BITS_COUNTER < c_NUMBER_OF_DATA_BITS - 1) then
						o_uart_tx <= r_TX_BYTE(r_TX_DATA_BITS_COUNTER);
						r_TX_DATA_BITS_COUNTER <= r_TX_DATA_BITS_COUNTER + 1;
					else
						o_uart_tx <= r_TX_BYTE(r_TX_DATA_BITS_COUNTER);

						r_TX_DATA_BITS_COUNTER <= 0;
						r_TX_PACKET_PHASE <= STOP_BIT;
					end if;
				elsif (r_TX_PACKET_PHASE = STOP_BIT) then
					o_uart_tx <= '1';
					r_TX_PACKET_PHASE <= IDLE;
				else
					r_TX_PACKET_PHASE <= IDLE;
				end if;
			end if;
		end if;
	end process p_Send_Data;

	p_Receive_Data: process (i_clock) is
	begin
		if (rising_edge(i_clock)) then
		end if;
	end process p_Receive_Data;
end rtl;
