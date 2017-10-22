-- testbench for ieee 488.1 source handshake interface function.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--
-- TODO: test while CACS

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_states.all;

entity interface_function_SH_testbench is
end interface_function_SH_testbench;
     
architecture behav of interface_function_SH_testbench is
	component interface_function_SH
		port(
			clock : in std_logic;
			talker_state_1 : in T_state_1;
			controller_state_1 : in C_state_1;
			ATN : in std_logic;
			NDAC : in std_logic;
			NRFD : in std_logic;
			nba : in std_logic;
			pon : in std_logic;
			first_T1_terminal_count : in std_logic_vector (15 downto 0);
			T1_terminal_count : in std_logic_vector (15 downto 0);
			check_for_listeners : in std_logic;

			source_handshake_state : out SH_state;
			old_source_handshake_state : out SH_state;
			DAV : out std_logic;
			no_listeners : out std_logic
		);
	end component;

	for my_SH: interface_function_SH use entity work.interface_function_SH;
	signal clock : std_logic;
	signal talker_state_1 : T_state_1;
	signal controller_state_1 : C_state_1;
	signal ATN : std_logic;
	signal NDAC : std_logic;
	signal NRFD : std_logic;
	signal nba : std_logic;
	signal pon : std_logic;
	signal first_T1_terminal_count : std_logic_vector (15 downto 0);
	signal T1_terminal_count : std_logic_vector (15 downto 0);
	signal check_for_listeners : std_logic;

	signal source_handshake_state : SH_state;
	signal DAV : std_logic;
	signal no_listeners : std_logic;
	
	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	begin
	my_SH: interface_function_SH 
		port map (
			clock => clock,
			talker_state_1 => talker_state_1,
			controller_state_1 => controller_state_1,
			ATN => ATN,
			NDAC => NDAC,
			NRFD => NRFD,
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
		ATN <= 'H';
		NDAC <= 'H';
		NRFD <= 'H';
		nba <= '0';
		
		
		first_T1_terminal_count <= X"0004";
		T1_terminal_count <= X"0002";
		check_for_listeners <= '1';
		talker_state_1 <= TIDS;
		controller_state_1 <= CIDS;
		
		wait until rising_edge(clock);
		pon <= '1';

		wait until rising_edge(clock);
		pon <= '0';
		
		wait until rising_edge(clock);
		
		wait until rising_edge(clock);
		talker_state_1 <= TACS;

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
		assert DAV = 'Z';
		NDAC <= '0';
		
		wait until rising_edge(clock);
		wait until rising_edge(clock);
		assert source_handshake_state = STRS;
		assert DAV = '0';
		NDAC <= 'H';
		
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
		ATN <= '0';
		talker_state_1 <= TADS;
		
		wait until rising_edge(clock);
		wait until rising_edge(clock);
		assert source_handshake_state = SIWS;
		nba <= '0';
		
		wait until rising_edge(clock);
		for i in 1 to 3 loop
			wait until rising_edge(clock);
			assert source_handshake_state = SIDS;
		end loop;
		
		talker_state_1 <= SPAS;
		ATN <= 'H';

		wait until rising_edge(clock);
		for i in 1 to 3 loop
			wait until rising_edge(clock);
			assert source_handshake_state = SGNS;
		end loop;

		-- interrupt back to SIDS
		talker_state_1 <= TADS;
		
		wait until rising_edge(clock);
		for i in 1 to 3 loop
			wait until rising_edge(clock);
			assert source_handshake_state = SIDS;
		end loop;
		
		talker_state_1 <= SPAS;
		
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
		ATN <= '0';
		talker_state_1 <= TADS;
		
		wait until rising_edge(clock);
		for i in 1 to 3 loop
			wait until rising_edge(clock);
			assert source_handshake_state = SIDS;
		end loop;

		ATN <= 'H';
		talker_state_1 <= SPAS;
		check_for_listeners <= '1';
		NDAC <= '0';
		
		for i in 1 to 3 loop
			wait until rising_edge(clock);
		end loop;
		assert source_handshake_state = SDYS;

		for i in 1 to 6 loop
			wait until rising_edge(clock);
		end loop;
		assert source_handshake_state = STRS;

		-- interrupt to SIWS
		ATN <= '0';
		talker_state_1 <= TADS;
		
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
