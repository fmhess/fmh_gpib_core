-- debounce filter
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpib_debounce_filter is
	generic( 
		num_inputs : integer;
		-- length is number of historical input values we remember for calculating outputs
		-- should be an even number since we save input values on rising and falling clock
		-- edges.
		length : positive;
		-- if the number of historical values of an input differing from the current output meet the threshold, 
		-- the output changes to match.
		threshold : positive
	);
	port(
		reset : in std_logic;
		-- inputs are latched on rising and falling edge of clock
		-- outputs are updated on rising edge of clock
		clock : in std_logic;
		inputs : in std_logic_vector(num_inputs - 1 downto 0);
		outputs : out std_logic_vector(num_inputs - 1 downto 0)
	); 
end gpib_debounce_filter;
 
architecture arch of gpib_debounce_filter is
	-- we split inputs history into rising and falling because quartus has problems
	-- with signals getting written to on both rising and falling clock edges.
	constant rising_length : integer := length / 2;
	-- length of falling edge history is rounded up to deal with case of odd length
	constant falling_length : integer := (length + 1) / 2;

	type rising_history_type is array (rising_length - 1 downto 0) of std_logic_vector(num_inputs - 1 downto 0);
	signal rising_inputs_history : rising_history_type;

	type falling_history_type is array (falling_length - 1 downto 0) of std_logic_vector(num_inputs - 1 downto 0);
	signal falling_inputs_history : falling_history_type;

	type rising_count_type is array (num_inputs - 1 downto 0) of integer range 0 to rising_length;
	signal rising_count : rising_count_type;

	type falling_count_type is array (num_inputs - 1 downto 0) of integer range 0 to falling_length;
	signal falling_count : falling_count_type;

	signal outputs_buffer : std_logic_vector(num_inputs - 1 downto 0);
	signal safe_reset : std_logic;
begin
	process (reset, clock)
	begin
		if to_X01(reset) = '1' then
			safe_reset <= '1';
		elsif rising_edge(clock) then
			safe_reset <= '0';
		end if;
	end process;
	
	process (safe_reset, clock)
	begin
		if to_X01(safe_reset) = '1' then
			for j in 0 to num_inputs - 1 loop
				for i in 0 to rising_length - 1 loop
					rising_inputs_history(i)(j) <= '1';
				end loop;
				rising_count(j) <= rising_length;
			end loop;

			for j in 0 to num_inputs - 1 loop
				for i in 0 to falling_length - 1 loop
					falling_inputs_history(i)(j) <= '1';
				end loop;
				falling_count(j) <= falling_length;
			end loop;
		elsif rising_edge(clock) then
			for i in rising_length - 1 downto 1 loop
				rising_inputs_history(i) <= rising_inputs_history(i - 1);
			end loop;
			rising_inputs_history(0) <= to_X01(inputs);
			
			-- update count due to new bit coming in and old bit going out
			for j in 0 to num_inputs - 1 loop
				if rising_inputs_history(0)(j) = '1' and
					rising_inputs_history(rising_length - 1)(j) = '0'then
					rising_count(j) <= rising_count(j) + 1;
				elsif rising_inputs_history(0)(j) = '0' and
					rising_inputs_history(rising_length - 1)(j) = '1' then
					rising_count(j) <= rising_count(j) - 1;
				end if;
			end loop;
		elsif falling_edge(clock) then
			for i in falling_length - 1 downto 1 loop
				falling_inputs_history(i) <= falling_inputs_history(i - 1);
			end loop;
			falling_inputs_history(0) <= to_X01(inputs);

			-- update count due to new bit coming in and old bit going out
			for j in 0 to num_inputs - 1 loop
				if to_X01(inputs(j)) = '1' and
					falling_inputs_history(falling_length - 1)(j) = '0'then
					falling_count(j) <= falling_count(j) + 1;
				elsif to_X01(inputs(j)) = '0' and
					falling_inputs_history(falling_length - 1)(j) = '1' then
					falling_count(j) <= falling_count(j) - 1;
				end if;
			end loop;
		end if;
	end process;
	
	process (safe_reset, clock)
		variable total_count : integer range 0 to length;
	begin
		if to_X01(safe_reset) = '1' then
			outputs_buffer <= (others => '1');
			total_count := 0;
			assert threshold <= length report "the threshold generic parameter may not be greater than length";
			assert (threshold * 2) > length report "the threshold generic parameter must be greater than half the length";
		elsif rising_edge(clock) then
			for j in 0 to num_inputs - 1 loop
				total_count := rising_count(j) + falling_count(j);
				if total_count >= threshold then
					outputs_buffer(j) <= '1';
				elsif total_count <= length - threshold then
					outputs_buffer(j) <= '0';
				end if;
			end loop;
		end if;
	end process;

	outputs <= outputs_buffer;
end architecture arch;
