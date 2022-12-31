-- Based on https://nandland.com/register-based-fifo/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity fifo_module is
	generic (
	g_WIDTH : integer := 8;
	g_DEPTH : integer := 10
	);
	port (
		i_clk : in std_logic;
		i_reset_fifo : in std_logic;

		-- FIFO write interface:
		i_write_enable : in std_logic;
		i_write_data : in std_logic_vector(g_WIDTH-1 downto 0);
		o_fifo_full : out std_logic;

		-- FIFO read interface:
		i_read_enable : in std_logic;
		o_read_data : out std_logic_vector(g_WIDTH-1 downto 0);
		o_fifo_empty : out std_logic
	);
end fifo_module;

architecture rtl of fifo_module is
	type t_FIFO_DATA is array (0 to g_DEPTH-1) of std_logic_vector(g_WIDTH-1 downto 0);
	signal r_FIFO_DATA : t_FIFO_DATA := (others => (others => '0'));
	signal r_WRITE_INDEX : integer range 0 to g_DEPTH-1 := 0;
	signal r_READ_INDEX : integer range 0 to g_DEPTH-1 := 0;

	-- Number of Elements in FIFO, has extra range to allow for assert conditions -- TODO: why is this done this way?
	signal r_FIFO_NUMBER_OF_ELEMENTS : integer range -1 to g_DEPTH + 1 := 0;
begin
	p_CONTROL : process (i_clk) is
	begin
		if rising_edge(i_clk) then
			if i_reset_fifo = '1' then
				r_WRITE_INDEX <= 0;
				r_READ_INDEX <= 0;
				r_FIFO_NUMBER_OF_ELEMENTS <= 0;
			else
				-- keep track of the number of elements in the FIFO:
				if i_write_enable = '1' and i_read_enable = '0' then
					r_FIFO_NUMBER_OF_ELEMENTS <= r_FIFO_NUMBER_OF_ELEMENTS + 1;
				elsif i_write_enable = '0' and i_read_enable = '1' then
					r_FIFO_NUMBER_OF_ELEMENTS <= r_FIFO_NUMBER_OF_ELEMENTS - 1;
				end if;

				if i_write_enable = '1' then
					-- Save the input data into the current FIFO element
					r_FIFO_DATA(r_WRITE_INDEX) <= i_write_data;
					-- increment the write index:
					if r_WRITE_INDEX < g_DEPTH - 1 then
						r_WRITE_INDEX <= r_WRITE_INDEX + 1;
					else
						r_WRITE_INDEX <= 0;
					end if;
				end if;

				-- increment ther read index:
				if i_read_enable = '1' then
					if r_READ_INDEX < g_DEPTH - 1 then
						r_READ_INDEX <= r_READ_INDEX + 1;
					else
						r_READ_INDEX <= 0;
					end if;
				end if;
			end if;


			-- always set o_read_data to the current read element
			o_read_data <= r_FIFO_DATA(r_READ_INDEX);

			-- set FIFO full flag
			if r_FIFO_NUMBER_OF_ELEMENTS = g_DEPTH then
				o_fifo_full <= '1';
			else
				o_fifo_full <= '0';
			end if;

			-- set FIFO empty flag
			if r_FIFO_NUMBER_OF_ELEMENTS = 0 then
				o_fifo_empty <= '1';
			else
				o_fifo_empty <= '0';
			end if;
		end if;
	end process p_CONTROL;


end rtl;
