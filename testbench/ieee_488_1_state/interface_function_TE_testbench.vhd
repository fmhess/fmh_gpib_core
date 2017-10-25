-- testbench for ieee 488.1 extended talker interface function.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_states.all;

entity interface_function_TE_testbench is
end interface_function_TE_testbench;
     
architecture behav of interface_function_TE_testbench is
	signal clock : std_logic;
	signal acceptor_handshake_state : AH_state;
	signal listener_state_p2 : LE_state_p2;
	signal service_request_state : SR_state;
	signal ATN : std_logic;
	signal IFC : std_logic;
	signal pon : std_logic;
	signal ton : std_logic;
	signal MTA : std_logic;
	signal MSA : std_logic;
	signal OTA : std_logic;
	signal OSA : std_logic;
	signal MLA : std_logic;
	signal SPE : std_logic;
	signal SPD : std_logic;
	signal PCG : std_logic;
	signal enable_secondary_addressing : std_logic;
	signal talker_state_p1 : TE_state_p1;
	signal talker_state_p2 : TE_state_p2;
	signal talker_state_p3 : TE_state_p3;
	signal END_msg : std_logic;
	signal RQS : std_logic;
	signal NUL : std_logic;
	
	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	begin
	my_TE: entity work.interface_function_TE 
		port map (
			clock => clock,
			acceptor_handshake_state => acceptor_handshake_state,
			listener_state_p2 => listener_state_p2,
			service_request_state => service_request_state,
			ATN => ATN,
			IFC => IFC,
			pon => pon,
			ton => ton,
			MTA => MTA,
			MSA => MSA,
			OTA => OTA,
			OSA => OSA,
			MLA => MLA,
			SPE => SPE,
			SPD => SPD,
			PCG => PCG,
			enable_secondary_addressing => enable_secondary_addressing,
			talker_state_p1 => talker_state_p1,
			talker_state_p2 => talker_state_p2,
			talker_state_p3 => talker_state_p3,
			END_msg => END_msg,
			RQS => RQS,
			NUL => NUL
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
		listener_state_p2 <= LPIS;
		service_request_state <= NPRS;
		ATN <= 'L';
		IFC <= 'L';
		pon <= '0';
		ton <= '0';
		MTA <= '0';
		MSA <= '0';
		OTA <= '0';
		OSA <= '0';
		MLA <= '0';
		SPE <= '0';
		SPD <= '0';
		PCG <= '0';
		enable_secondary_addressing <= '0';
		
		wait until rising_edge(clock);
		pon <= '1';

		wait until rising_edge(clock);
		pon <= '0';
		
		wait until rising_edge(clock);
		
		assert talker_state_p1 = TIDS;
		assert talker_state_p3 = SPIS;

		ton <= '1';
		wait_for_ticks( 2 );
		assert talker_state_p1 = TADS;
		wait until rising_edge(clock);
		assert talker_state_p1 = TACS;
		
		ATN <= '1';
		wait_for_ticks( 3 );
		assert talker_state_p1 = TADS;

		SPE <= '1';
		acceptor_handshake_state <= ACDS;
		wait_for_ticks( 3 );
		assert talker_state_p3 = SPMS;

		ATN <= 'L';
		
		wait_for_ticks( 3 );
		assert talker_state_p1 = SPAS;

		ATN <= '1';
		wait_for_ticks( 3 );
		assert talker_state_p1 = TADS;

		SPD <= '1';
		SPE <= '0';
		ton <= '0';
		wait_for_ticks( 3 );
		assert talker_state_p3 = SPIS;
		
		SPD <= '0';
		OTA <= '1';
		wait_for_ticks( 3 );
		assert talker_state_p1 = TIDS;
		
		OTA <= '0';
		MTA <= '1';
		wait_for_ticks( 3 );
		assert talker_state_p1 = TADS;

		MTA <= '0';
		MLA <= '1';
		wait_for_ticks( 3 );
		assert talker_state_p1 = TIDS;
		
		-- now test extended talker
		
		MLA <= '0';
		enable_secondary_addressing <= '1';
		PCG <= '1';
		wait_for_ticks( 3 );
		assert talker_state_p2 = TPIS;
		
		MTA <= '1';
		wait_for_ticks( 3 );
		assert talker_state_p2 = TPAS;

		MTA <= '0';
		PCG <= '0';
		MSA <= '1';
		wait_for_ticks( 4 );
		assert talker_state_p1 = TADS;
		assert talker_state_p2 = TPAS;
		
		MSA <= '0';
		OTA <= '1';
		wait_for_ticks( 3 );
		assert talker_state_p1 = TIDS;
		
		OTA <= '0';
		MTA <= '1';
		wait_for_ticks( 3 );
		assert talker_state_p2 = TPAS;

		MTA <= '0';
		MSA <= '1';
		wait_for_ticks( 3 );
		assert talker_state_p1 = TADS;
		
		MSA <= '0';
		OSA <= '1';
		wait_for_ticks( 3 );
		assert talker_state_p1 = TIDS;

		OSA <= '0';
		ton <= '1';
		wait_for_ticks( 3 );
		assert talker_state_p1 = TADS;

		ton <= '0';
		MSA <= '1';
		PCG <= '1';
		listener_state_p2 <= LPAS;
		wait_for_ticks( 3 );
		assert talker_state_p1 = TIDS;
		
		listener_state_p2 <= LPIS;
		MSA <= '0';
		
		wait until rising_edge(clock);
		assert false report "end of test" severity note;
		test_finished := true;
		wait;
	end process;
end behav;
