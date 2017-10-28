-- testbench for ieee 488.1 service request interface function.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity interface_function_SR_testbench is
end interface_function_SR_testbench;
     
architecture behav of interface_function_SR_testbench is
	signal clock : std_logic;
	signal talker_state_p1 : TE_state_p1;
	signal pon : std_logic;
	signal rsv : std_logic;
	signal service_request_state : SR_state;
	signal SRQ : std_logic;
	
	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	begin
	my_SR: entity work.interface_function_SR 
		port map (
			clock => clock,
			talker_state_p1 => talker_state_p1,
			pon => pon,
			rsv => rsv,
			service_request_state => service_request_state,
			SRQ => SRQ
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
		-- wait wait for a condition with a hard coded timeout to avoid infinite test loops on failure
		procedure wait_for_ticks (num_clock_cycles : in integer) is
			begin
				for i in 1 to num_clock_cycles loop
					wait until rising_edge(clock);
				end loop;
			end procedure wait_for_ticks;
		
	begin
		talker_state_p1 <= TIDS;
		pon <= '0';
		rsv <= '0';
		
		wait until rising_edge(clock);
		pon <= '1';

		wait until rising_edge(clock);
		pon <= '0';
		
		wait until rising_edge(clock);
		
		assert service_request_state = NPRS;

		rsv <= '1';
		wait_for_ticks(3);
		assert service_request_state = SRQS;
		
		rsv <= '0';
		wait_for_ticks(3);
		assert service_request_state = NPRS;
		
		rsv <= '1';
		wait_for_ticks(3);
		assert service_request_state = SRQS;
		assert SRQ = '1';

		talker_state_p1 <= SPAS;
		wait_for_ticks(3);
		assert service_request_state = APRS;
		assert SRQ = 'L';

		talker_state_p1 <= TADS;
		rsv <= '0';
		wait_for_ticks(3);
		assert service_request_state = NPRS;
		assert SRQ = 'L';
		
		wait until rising_edge(clock);
		assert false report "end of test" severity note;
		test_finished := true;
		wait;
	end process;
end behav;
