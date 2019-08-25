-- testbench for ieee 488.1 source handshake interface function.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--
-- TODO: test while CACS

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity interface_function_SH_testbench is
end interface_function_SH_testbench;
     
architecture behav of interface_function_SH_testbench is
	signal clock : std_logic;
	signal talker_state_p1 : TE_state_p1;
	signal controller_state_p1 : C_state_p1;
	signal ATN : std_logic;
	signal DAC : std_logic;
	signal IFC : std_logic;
	signal RFD : std_logic;
	signal nba : std_logic;
	signal pon : std_logic;
	signal first_T1_terminal_count : unsigned (7 downto 0);
	signal T1_terminal_count : unsigned (7 downto 0);
	signal check_for_listeners : std_logic;

	signal source_handshake_state : SH_state;
	signal DAV : std_logic;
	signal no_listeners : std_logic;
	
	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	begin
	my_SH : entity work.interface_function_SHE
		port map (
			clock => clock,
			talker_state_p1 => talker_state_p1,
			controller_state_p1 => controller_state_p1,
			ATN => ATN,
			IFC => IFC,
			DAC => DAC,
			RFD => RFD,
			nba => nba,
			pon => pon,
			first_T1_terminal_count => first_T1_terminal_count,
			T1_terminal_count => T1_terminal_count,
			check_for_listeners => check_for_listeners,
			
			source_handshake_state => source_handshake_state,
			DAV => DAV,
			no_listeners => no_listeners
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
		pon <= '0';
		ATN <= 'L';
		DAC <= 'H';
		RFD <= 'H';
		IFC <= 'H';
		nba <= '0';
		
		
		first_T1_terminal_count <= X"05";
		T1_terminal_count <= X"03";
		check_for_listeners <= '1';
		talker_state_p1 <= TIDS;
		controller_state_p1 <= CIDS;
		
		wait until rising_edge(clock);
		pon <= '1';

		wait until rising_edge(clock);
		pon <= '0';
		
		wait until rising_edge(clock);
		
		wait until rising_edge(clock);
		talker_state_p1 <= TACS;

		wait until rising_edge(clock);
		wait until rising_edge(clock);
		assert source_handshake_state = SGNS;

		wait until rising_edge(clock);
		wait until rising_edge(clock);
		assert source_handshake_state = SGNS;
		nba <= '1';

		wait until rising_edge(clock);
		wait until rising_edge(clock);
		assert source_handshake_state = SDYS;

		for i in 1 to 5 loop
			wait until rising_edge(clock);
		end loop;
		assert no_listeners = '0';

		wait until rising_edge(clock);
		assert no_listeners = '1';
		
		wait until rising_edge(clock);
		assert no_listeners = '0';
		assert DAV = '0';

		-- make sure RFD holdoff works
		DAC <= '0';
		RFD <= '0';
		for i in 1 to 3 loop
			wait until rising_edge(clock);
		end loop;
		assert source_handshake_state = SDYS;

		RFD <= 'H';
		for i in 1 to 3 loop
			wait until rising_edge(clock);
		end loop;
		assert source_handshake_state = STRS;
		assert DAV = '1';
		DAC <= 'H';
		
		wait until rising_edge(clock);
		for i in 1 to 3 loop
			wait until rising_edge(clock);
			assert source_handshake_state = SWNS;
		end loop;

		nba <= '0';
		
		wait until rising_edge(clock);
		wait until rising_edge(clock);
		assert source_handshake_state = SGNS;
		nba <= '1';
		check_for_listeners <= '0';

		wait until rising_edge(clock);
		wait until rising_edge(clock);
		assert source_handshake_state = SDYS;

		-- This is the second cycle so T1 should be shorter this time.
		for i in 1 to 3 loop
			wait until rising_edge(clock);
		end loop;
		assert source_handshake_state = SDYS;

		-- There is no listener and we turned off check so we go to STRS
		wait until rising_edge(clock);
		assert source_handshake_state = STRS;

		wait until rising_edge(clock);
		assert source_handshake_state = SWNS;

		-- interrupt to SIWS
		ATN <= '1';
		talker_state_p1 <= TADS;
		
		wait until rising_edge(clock);
		wait until rising_edge(clock);
		assert source_handshake_state = SIWS;
		nba <= '0';
		
		wait until rising_edge(clock);
		for i in 1 to 3 loop
			wait until rising_edge(clock);
			assert source_handshake_state = SIDS;
		end loop;
		
		talker_state_p1 <= SPAS;
		ATN <= 'L';

		wait until rising_edge(clock);
		for i in 1 to 3 loop
			wait until rising_edge(clock);
			assert source_handshake_state = SGNS;
		end loop;

		-- interrupt back to SIDS
		talker_state_p1 <= TADS;
		
		wait until rising_edge(clock);
		for i in 1 to 3 loop
			wait until rising_edge(clock);
			assert source_handshake_state = SIDS;
		end loop;
		
		talker_state_p1 <= SPAS;
		
		wait until rising_edge(clock);
		for i in 1 to 3 loop
			wait until rising_edge(clock);
			assert source_handshake_state = SGNS;
		end loop;

		nba <= '1';
		
		wait until rising_edge(clock);
		for i in 1 to 3 loop
			wait until rising_edge(clock);
			assert source_handshake_state = SDYS;
		end loop;

		-- interrupt back to SIDS
		ATN <= '1';
		talker_state_p1 <= TADS;
		
		wait until rising_edge(clock);
		for i in 1 to 3 loop
			wait until rising_edge(clock);
			assert source_handshake_state = SIDS;
		end loop;

		ATN <= 'L';
		talker_state_p1 <= SPAS;
		check_for_listeners <= '1';
		DAC <= '0';
		
		for i in 1 to 3 loop
			wait until rising_edge(clock);
		end loop;
		assert source_handshake_state = SDYS;

		for i in 1 to 6 loop
			wait until rising_edge(clock);
		end loop;
		assert source_handshake_state = STRS;

		-- interrupt to SIWS
		ATN <= '1';
		talker_state_p1 <= TADS;
		
		for i in 1 to 3 loop
			wait until rising_edge(clock);
		end loop;
		assert source_handshake_state = SIWS;

		wait until rising_edge(clock);
		assert false report "end of test" severity note;
		test_finished := true;
		wait;
	end process;
end behav;
