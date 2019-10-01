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
		max_length : positive
	);
	port(
		reset : in std_logic;
		-- inputs are latched on rising and falling edge of clock
		-- outputs are updated on rising edge of clock
		clock : in std_logic;
		length : in positive range 2 to max_length := max_length;
		-- if the number of historical values of an input differing from the current output meet the threshold, 
		-- the output changes to match.
		threshold : in positive range 1 to max_length;
		inputs : in std_logic_vector(num_inputs - 1 downto 0);
		outputs : out std_logic_vector(num_inputs - 1 downto 0)
	); 
end gpib_debounce_filter;
 
architecture arch of gpib_debounce_filter is
	-- we split inputs history into rising and falling because quartus has problems
	-- with signals getting written to on both rising and falling clock edges.
	constant max_rising_length : positive := max_length / 2;
	-- length of falling edge history is rounded up to deal with case of odd length
	constant max_falling_length : positive := (max_length + 1) / 2;
	
	signal rising_length : integer range 0 to max_rising_length := max_rising_length;
	signal falling_length : integer range 0 to max_falling_length := max_falling_length;
	signal length_latch : positive range 1 to max_length := max_length;
	signal threshold_latch : positive range 1 to max_length := max_length;
	signal configuration_change : std_logic;
	
	type history_type is array (natural range <>) of std_logic_vector(num_inputs - 1 downto 0);
	signal rising_inputs_history : history_type(max_rising_length - 1 downto 0);
	signal falling_inputs_history : history_type(max_falling_length - 1 downto 0);

	type rising_count_type is array (num_inputs - 1 downto 0) of integer range 0 to max_rising_length;
	signal rising_count : rising_count_type := (others => max_rising_length);

	type falling_count_type is array (num_inputs - 1 downto 0) of integer range 0 to max_falling_length;
	signal falling_count : falling_count_type := (others => max_falling_length);

	-- Inputs may be changing asynchronously so we latch them on both rising and
	-- falling edges.  We actually latch rising_inputs_latch on falling clock edges
	-- and vice-versa, in order to reduce latency by a half clock cycle.
	signal rising_inputs_latch : std_logic_vector(num_inputs - 1 downto 0);
	signal falling_inputs_latch : std_logic_vector(num_inputs - 1 downto 0);
	
	signal outputs_buffer : std_logic_vector(num_inputs - 1 downto 0);
	signal safe_reset : std_logic;

	procedure fill_history (signal history : out history_type; value : in std_logic) is
	begin
		for i in 0 to history'LENGTH - 1 loop
			history(i) <= (others => value);
		end loop;
	end fill_history;
	
	procedure fill_channel_history (signal history : out history_type; channel : in natural; value : in std_logic) is
	begin
		for i in 0 to history'LENGTH - 1 loop
			history(i)(channel) <= value;
		end loop;
	end fill_channel_history;

begin
	-- sync release of reset
	process (reset, clock)
	begin
		if to_X01(reset) = '1' then
			safe_reset <= '1';
		elsif rising_edge(clock) then
			safe_reset <= '0';
		end if;
	end process;
	
	-- rising edge stuff
	process (safe_reset, clock)
	begin
		if to_X01(safe_reset) = '1' then
			fill_history(rising_inputs_history, '1');
			rising_inputs_latch <= (others => '1');
			rising_count <= (others => max_rising_length);
			rising_length <= max_rising_length;

			falling_length <= max_falling_length;
			configuration_change <= '0';
			length_latch <= max_length;
			threshold_latch <= max_length;
		elsif rising_edge(clock) then
			-- Cycle through bitvector to make sure everything is a solid '0' or '1'
			-- The alternative to_01 is less than ideal since it sets everything
			-- to '0' if any element is invalid.
			rising_inputs_latch <= to_stdlogicvector(to_bitvector(inputs));
			
			-- handle dynamic changes to filter length and threshold
			assert threshold <= length report "the threshold may not be greater than the length";
			assert (threshold * 2) > length report "the threshold must be greater than half the length";
			if length /= length_latch or threshold /= threshold_latch then
-- 				assert false report "length " & integer'image(length_latch) & " -> " & integer'image(length) severity note;
-- 				assert false report "threshold " & integer'image(threshold_latch) & " -> " & integer'image(threshold) severity note;
-- 				assert false report "rising length " & integer'image(rising_length) & "/" & integer'image(max_rising_length) severity note;
-- 				assert false report "falling length " & integer'image(falling_length) & "/" & integer'image(max_falling_length) severity note;
				configuration_change <= '1';
				length_latch <= length;
				threshold_latch <= threshold;
				rising_length <= length / 2;
				falling_length <= (length + 1) / 2;
			else
				configuration_change <= '0';
			end if;
			
			if configuration_change = '1' then
				-- reinitialize channel histories to whatever their current output is, to suppress
				-- spurious transitions when the length/threshold is changed
				for channel in 0 to num_inputs - 1 loop
					fill_channel_history (rising_inputs_history, channel, outputs_buffer (channel));
					if outputs_buffer (channel) = '1' then
						rising_count(channel) <= rising_length;
					else
						rising_count(channel) <= 0;
					end if;
				end loop;
			else -- normal update
				for i in max_rising_length - 1 downto 1 loop
					rising_inputs_history(i) <= rising_inputs_history(i - 1);
				end loop;
				rising_inputs_history(0) <= falling_inputs_latch;
				
				-- update count due to new bit coming in and old bit going out
				for j in 0 to num_inputs - 1 loop
					if falling_inputs_latch(j) = '1' and
						rising_inputs_history(rising_length - 1)(j) = '0'then
						rising_count(j) <= rising_count(j) + 1;
					elsif falling_inputs_latch(j) = '0' and
						rising_inputs_history(rising_length - 1)(j) = '1' then
						rising_count(j) <= rising_count(j) - 1;
					end if;
				end loop;
			end if;
		end if;
	end process;

	-- falling edge stuff
	process (safe_reset, clock)
	begin
		if to_X01(safe_reset) = '1' then
			fill_history(falling_inputs_history, '1');
			falling_inputs_latch <= (others => '1');
			falling_count <= (others => max_falling_length);
		elsif rising_edge(clock) then
		elsif falling_edge(clock) then
			-- Cycle through bitvector to make sure everything is a solid '0' or '1'
			-- The alternative to_01 is less than ideal since it sets everything
			-- to '0' if any element is invalid.
			falling_inputs_latch <= to_stdlogicvector(to_bitvector(inputs));

			-- handle dynamic changes to filter length and threshold
			if configuration_change = '1' then
				-- reinitialize channel histories to whatever their current output is, to suppress
				-- spurious transitions when the length/threshold is changed
				for channel in 0 to num_inputs - 1 loop
					fill_channel_history (falling_inputs_history, channel, outputs_buffer (channel));
					if outputs_buffer (channel) = '1' then
						falling_count(channel) <= falling_length;
					else
						falling_count(channel) <= 0;
					end if;
				end loop;
			else -- normal update
				for i in max_falling_length - 1 downto 1 loop
					falling_inputs_history(i) <= falling_inputs_history(i - 1);
				end loop;
				falling_inputs_history(0) <= rising_inputs_latch;

				-- update count due to new bit coming in and old bit going out
				for j in 0 to num_inputs - 1 loop
					if rising_inputs_latch(j) = '1' and
						falling_inputs_history(falling_length - 1)(j) = '0'then
						falling_count(j) <= falling_count(j) + 1;
					elsif rising_inputs_latch(j) = '0' and
						falling_inputs_history(falling_length - 1)(j) = '1' then
						falling_count(j) <= falling_count(j) - 1;
					end if;
				end loop;
			end if;
		end if;
	end process;

	-- combine rising and falling counts and update outputs
	process (safe_reset, clock)
		variable total_count : integer range 0 to max_length;
	begin
		if to_X01(safe_reset) = '1' then
			outputs_buffer <= (others => '1');
			total_count := 0;
		elsif rising_edge(clock) then
			-- suppress updating the outputs while we are changing length/threshold to avoid glitches
			if configuration_change = '0' then 
				for j in 0 to num_inputs - 1 loop
					total_count := rising_count(j) + falling_count(j);
					if total_count >= threshold_latch then
						outputs_buffer(j) <= '1';
					elsif total_count <= length_latch - threshold_latch then
						outputs_buffer(j) <= '0';
					end if;
				end loop;
			end if;
		end if;
	end process;

	outputs <= outputs_buffer;
end architecture arch;
