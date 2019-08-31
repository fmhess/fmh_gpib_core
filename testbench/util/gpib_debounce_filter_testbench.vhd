-- testbench for gpib tranceiver.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.gpib_transceiver.all;
use work.test_common.all;

entity gpib_debounce_filter_testbench is
end gpib_debounce_filter_testbench;
     
architecture behav of gpib_debounce_filter_testbench is

	signal input : std_logic;
	signal output : std_logic;
	signal length : integer;
	signal threshold : integer;
	signal reset : std_logic;
	
	signal clock : std_logic;
	constant clock_half_period : time := 500 ns;

	shared variable test_finished : boolean := false;

	procedure wait_for_ticks(n : in integer) is
	begin
		wait_for_ticks(n, clock);
	end wait_for_ticks;
	
	procedure pulse_test (
		pulse_polarity : in std_logic;
		pulse_width : in integer;
		settle_ticks : in integer;
		expected_latency : in integer;
		expect_output_pulse : in boolean
	) is 
	begin
--		assert false report "pulse_test: polarity " & std_logic'image(pulse_polarity) &
--			" width " & integer'image(pulse_width) severity note;
		input <= not pulse_polarity;
		wait_for_ticks(settle_ticks);
		assert output = not pulse_polarity;
		input <= pulse_polarity;
		for i in 0 to pulse_width + expected_latency - 1 loop
			wait_for_ticks(1);

			if i < expected_latency then
				assert output = not pulse_polarity;
			elsif expect_output_pulse then
				assert output = pulse_polarity;
			else
				assert output = not pulse_polarity;
			end if;
			
			if i = pulse_width - 1 then
				input <= not pulse_polarity;
			end if;
		end loop;
		wait_for_ticks(1);
		assert output = not pulse_polarity;
	end pulse_test;
		
	begin
	my_filter: entity work.gpib_debounce_filter
		generic map (
			num_inputs => 1,
			max_length => 10
			)
		port map (
			clock => clock,
			reset => reset,
			length => length,
			threshold => threshold,
			inputs(0) => input,
			outputs(0) => output
		);
	
	process
	begin
		if(test_finished) then
			wait;
		end if;
		
		clock <= '0';
		wait for clock_half_period;
		clock <= '1';
		wait for clock_half_period;
	end process;
	
	process
	begin
		length <= 10;
		threshold <= 8;
		input <= '1';
		reset <= '1';
		wait until rising_edge(clock);
		reset <= '0';
		wait_for_ticks(1); 

		pulse_test ('0', 4, 6, 5, true);
		pulse_test ('0', 3, 6, 5, false);
		pulse_test ('1', 4, 6, 5, true);
		pulse_test ('1', 3, 6, 5, false);

		length <= 3;
		threshold <= 2;
		wait_for_ticks(2);
		
		pulse_test ('1', 1, 3, 2, true);
		pulse_test ('0', 1, 3, 2, true);

		length <= 4;
		threshold <= 4;
		wait_for_ticks(2);

		pulse_test ('0', 2, 4, 3, true);
		pulse_test ('0', 1, 4, 3, false);
		pulse_test ('1', 2, 4, 3, true);
		pulse_test ('1', 1, 4, 3, false);

		wait until rising_edge(clock);
		assert false report "end of test" severity note;
		test_finished := true;
		wait;
	end process;

end behav;
