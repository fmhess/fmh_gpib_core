-- debounce filter used on incoming GPIB control lines
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpib_control_debounce_filter is
	generic( 
		num_inputs : integer := 8;
		-- length is number of historical input values we remember for calculating outputs
		-- should be an even number since we save input values on rising and falling clock
		-- edges.
		length : integer := 12;
		-- if the number of historical values of an input differing from the current output meet the threshold, 
		-- the output changes to match.
		threshold : integer := 10
	);
	port(
		reset : in std_logic;
		-- inputs are latched on rising and falling edge of input_clock
		input_clock : in std_logic;
		-- outputs are updated on rising edge of output_clock
		output_clock : in std_logic;
		inputs : in std_logic_vector(num_inputs - 1 downto 0);
		outputs : out std_logic_vector(num_inputs - 1 downto 0)
	); 
end gpib_control_debounce_filter;
 
architecture arch of gpib_control_debounce_filter is
	constant half_length : integer := length / 2;
	type inputs_history_type is array (half_length - 1 downto 0) of std_logic_vector(num_inputs - 1 downto 0);
	-- we split inputs history into rising and falling because quartus has problems
	-- with signals getting written to on both rising and falling clock edges.
	signal rising_inputs_history : inputs_history_type;
	signal falling_inputs_history : inputs_history_type;
	signal outputs_buffer : std_logic_vector(num_inputs - 1 downto 0);
	signal safe_output_reset : std_logic;
	signal safe_input_reset : std_logic;
begin
	process (reset, input_clock)
	begin
		if to_X01(reset) = '1' then
			safe_input_reset <= '1';
		elsif rising_edge(input_clock) then
			safe_input_reset <= '0';
		end if;
	end process;
	
	process (reset, output_clock)
	begin
		if to_X01(reset) = '1' then
			safe_output_reset <= '1';
		elsif rising_edge(output_clock) then
			safe_output_reset <= '0';
		end if;
	end process;

	process (safe_input_reset, input_clock)
	begin
		if to_X01(safe_input_reset) = '1' then
			for i in 0 to half_length - 1 loop
				for j in 0 to num_inputs - 1 loop
					rising_inputs_history(i)(j) <= '1';
					falling_inputs_history(i)(j) <= '1';
				end loop;
			end loop;
		elsif rising_edge(input_clock) then
			for i in half_length - 1 downto 1 loop
				rising_inputs_history(i) <= rising_inputs_history(i - 1);
			end loop;
			rising_inputs_history(0) <= to_X01(inputs);
		elsif falling_edge(input_clock) then
			for i in half_length - 1 downto 1 loop
				falling_inputs_history(i) <= falling_inputs_history(i - 1);
			end loop;
			falling_inputs_history(0) <= to_X01(inputs);
		end if;
	end process;
	
	process (safe_output_reset, output_clock)
	variable input_sum : integer;
	begin
		if to_X01(safe_output_reset) = '1' then
			outputs_buffer <= (others => '1');
		elsif rising_edge(output_clock) then
			for j in 0 to num_inputs - 1 loop
				input_sum := 0;
				for i in 0 to half_length - 1 loop
					if rising_inputs_history(i)(j) = '1' then
						input_sum := input_sum + 1;
					end if;
					if falling_inputs_history(i)(j) = '1' then
						input_sum := input_sum + 1;
					end if;
				end loop;
				if input_sum >= threshold then
					outputs_buffer(j) <= '1';
				elsif input_sum <= length - threshold then
					outputs_buffer(j) <= '0';
				end if;
			end loop;
		end if;
	end process;

	outputs <= outputs_buffer;
end architecture arch;
