-- testbench for ieee 488.1 extended listener interface function.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_states.all;

entity interface_function_LE_testbench is
end interface_function_LE_testbench;
     
architecture behav of interface_function_LE_testbench is
	signal clock : std_logic;
	signal acceptor_handshake_state : AH_state;
	signal controller_state_p1 : C_state_p1;
	signal talker_state_p2 : TE_state_p2;
	signal ATN : std_logic;
	signal IFC : std_logic;
	signal pon : std_logic;
	signal ltn : std_logic;
	signal lon : std_logic;
	signal lun : std_logic;
	signal UNL : std_logic;
	signal MLA : std_logic;
	signal MSA : std_logic;
	signal PCG : std_logic;
	signal MTA : std_logic;
	signal enable_secondary_addressing : std_logic;
	signal listener_state_p1 : LE_state_p1;
	signal listener_state_p2 : LE_state_p2;
	
	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	begin
	my_LE: entity work.interface_function_LE 
		port map (
			clock => clock,
			acceptor_handshake_state => acceptor_handshake_state,
			controller_state_p1 => controller_state_p1,
			talker_state_p2 => talker_state_p2,
			ATN => ATN,
			IFC => IFC,
			pon => pon,
			ltn => ltn,
			lon => lon,
			lun => lun,
			UNL => UNL,
			MLA => MLA,
			MSA => MSA,
			PCG => PCG,
			MTA => MTA,
			enable_secondary_addressing => enable_secondary_addressing,
			listener_state_p1 => listener_state_p1,
			listener_state_p2 => listener_state_p2
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
		controller_state_p1 <= CIDS;
		talker_state_p2 <= TPIS;
		ATN <= 'L';
		IFC <= 'L';
		pon <= '0';
		ltn <= '0';
		lon <= '0';
		lun <= '0';
		UNL <= '0';
		MLA <= '0';
		MSA <= '0';
		MTA <= '0';
		PCG <= '0';
		enable_secondary_addressing <= '0';
		
		wait until rising_edge(clock);
		pon <= '1';

		wait until rising_edge(clock);
		pon <= '0';
		
		wait until rising_edge(clock);
		
		assert listener_state_p1 = LIDS;
		assert listener_state_p2 = LPIS;

		-- listener L test
		
		lon <= '1';
		wait_for_ticks( 2 );
		assert listener_state_p1 = LADS;
		wait until rising_edge(clock);
		assert listener_state_p1 = LACS;
		
		ATN <= '1';
		wait_for_ticks( 3 );
		assert listener_state_p1 = LADS;

		ATN <= '1';
		wait_for_ticks( 3 );
		assert listener_state_p1 = LADS;

		UNL <= '1';
		lon <= '0';
		acceptor_handshake_state <= ACDS;
		wait_for_ticks( 3 );
		assert listener_state_p1 = LIDS;

		UNL <= '0';
		MLA <= '1';
		wait_for_ticks( 3 );
		assert listener_state_p1 = LADS;

		MLA <= '0';
		MTA <= '1';
		wait_for_ticks( 3 );
		assert listener_state_p1 = LIDS;

		controller_state_p1 <= CACS;
		ltn <= '1';
		MTA <= '0';
		acceptor_handshake_state <= AIDS;
		wait_for_ticks( 3 );
		assert listener_state_p1 = LADS;

		ltn <= '0';
		lun <= '1';
		wait_for_ticks( 3 );
		assert listener_state_p1 = LIDS;

		controller_state_p1 <= CIDS;
		ATN <= '0';
		lun <= '0';

		
		-- now test extended listener LE
		
		enable_secondary_addressing <= '1';
		ATN <= '1';
		acceptor_handshake_state <= ACDS;
		PCG <= '1';
		wait_for_ticks( 3 );
		assert listener_state_p1 = LIDS;
		assert listener_state_p2 = LPIS;
		
		MLA <= '1';
		wait_for_ticks( 3 );
		assert listener_state_p1 = LIDS;
		assert listener_state_p2 = LPAS;
		
		MSA <= '1';
		wait_for_ticks( 3 );
		assert listener_state_p1 = LADS;
		
		MLA <= '0';
		wait_for_ticks( 3 );
		assert listener_state_p2 = LPIS;

		talker_state_p2 <= TPAS;
		wait_for_ticks( 3 );
		assert listener_state_p1 = LIDS;
		
		-- test IFC transition

		talker_state_p2 <= TPIS;
		MSA <= '0';
		lon <= '1';
		wait_for_ticks( 3 );
		assert listener_state_p1 = LADS;

		IFC <= '1';
		wait_for_ticks( 3 );
		assert listener_state_p1 = LIDS;

		IFC <= '0';
		ATN <= '0';
		wait_for_ticks( 3 );
		assert listener_state_p1 = LACS;
		
		IFC <= '1';
		wait_for_ticks( 3 );
		assert listener_state_p1 = LIDS;

		wait until rising_edge(clock);
		assert false report "end of test" severity note;
		test_finished := true;
		wait;
	end process;
end behav;
