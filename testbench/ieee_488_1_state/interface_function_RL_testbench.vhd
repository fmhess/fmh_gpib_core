-- testbench for ieee 488.1 extended listener interface function.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_states.all;

entity interface_function_RL_testbench is
end interface_function_RL_testbench;
     
architecture behav of interface_function_RL_testbench is
	signal clock : std_logic;
	signal acceptor_handshake_state : AH_state;
	signal listener_state_p1 : LE_state_p1;
	signal listener_state_p2 : LE_state_p2;
	signal pon : std_logic;
	signal rtl : std_logic;
	signal REN : std_logic;
	signal LLO : std_logic;
	signal GTL : std_logic;
	signal MLA : std_logic;
	signal MSA : std_logic;
	signal enable_secondary_addressing : std_logic;
	signal remote_local_state : RL_state;
	
	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	begin
	my_RL: entity work.interface_function_RL 
		port map (
			clock => clock,
			acceptor_handshake_state => acceptor_handshake_state,
			listener_state_p1 => listener_state_p1,
			listener_state_p2 => listener_state_p2,
			pon => pon,
			rtl => rtl,
			REN => REN,
			LLO => LLO,
			GTL => GTL,
			MLA => MLA,
			MSA => MSA,
			enable_secondary_addressing => enable_secondary_addressing,
			remote_local_state => remote_local_state
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
		acceptor_handshake_state <= AIDS;
		listener_state_p1 <= LIDS;
		listener_state_p2 <= LPIS;
		pon <= '0';
		rtl <= '0';
		REN <= '0';
		LLO <= '0';
		GTL <= '0';
		MLA <= '0';
		MSA <= '0';
		enable_secondary_addressing <= '0';
		
		wait until rising_edge(clock);
		pon <= '1';

		wait until rising_edge(clock);
		pon <= '0';
		
		wait until rising_edge(clock);
		
		assert remote_local_state = LOCS;

		REN <= '1';
		MLA <= '1';
		acceptor_handshake_state <= ACDS;
		wait_for_ticks(3);
		assert remote_local_state = REMS;

		MLA <= '0';
		LLO <= '1';
		wait_for_ticks(3);
		assert remote_local_state = RWLS;

		LLO <= '0';
		GTL <= '1';
		listener_state_p1 <= LADS;
		wait_for_ticks(3);
		assert remote_local_state = LWLS;
		
		MLA <= '1';
		GTL <= '0';
		wait_for_ticks(3);
		assert remote_local_state = RWLS;
		
		REN <= '0';
		MLA <= '0';
		wait_for_ticks(3);
		assert remote_local_state = LOCS;

		enable_secondary_addressing <= '1';
		REN <= '1';
		MSA <= '1';
		listener_state_p2 <= LPAS;
		wait_for_ticks(3);
		assert remote_local_state = REMS;
		
		MSA <= '0';
		GTL <= '1';
		listener_state_p1 <= LADS;
		wait_for_ticks(3);
		assert remote_local_state = LOCS;
		
		GTL <= '0';
		LLO <= '1';
		wait_for_ticks(3);
		assert remote_local_state = LWLS;
		
		wait until rising_edge(clock);
		assert false report "end of test" severity note;
		test_finished := true;
		wait;
	end process;
end behav;
