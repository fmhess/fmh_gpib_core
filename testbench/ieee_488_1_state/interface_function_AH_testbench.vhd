-- testbench for ieee 488.1 acceptor handshake interface function.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_states.all;

entity interface_function_AH_testbench is
end interface_function_AH_testbench;
     
architecture behav of interface_function_AH_testbench is
	signal clock : std_logic;
	signal listener_state_p1 : LE_state_p1;
	signal ATN : std_logic;
	signal DAV : std_logic;
	signal pon : std_logic;
	signal rdy : std_logic;
	signal tcs : std_logic;
	signal acceptor_handshake_state : AH_state;
	signal RFD : std_logic;
	signal DAC : std_logic;
	
	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	begin
	my_AH: entity work.interface_function_AH 
		port map (
			clock => clock,
			listener_state_p1 => listener_state_p1,
			ATN => ATN,
			DAV => DAV,
			pon => pon,
			rdy => rdy,
			tcs => tcs,
			acceptor_handshake_state => acceptor_handshake_state,
			RFD => RFD,
			DAC => DAC
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
		listener_state_p1 <= LIDS;
		ATN <= 'L';
		DAV <= 'L';
		pon <= '0';
		rdy <= '0';
		tcs <= '0';
		
		wait until rising_edge(clock);
		pon <= '1';

		wait until rising_edge(clock);
		pon <= '0';
		
		wait until rising_edge(clock);
		
		assert acceptor_handshake_state = AIDS;
		assert RFD = 'H';
		assert DAC = 'H';

		listener_state_p1 <= LACS;

		wait_for_ticks(3);
		assert acceptor_handshake_state = ANRS;
		
		-- accept a data byte
		
		rdy <= '1';
		wait_for_ticks(3);
		assert acceptor_handshake_state = ACRS;

		DAV <= '1';
		wait_for_ticks(3);
		assert acceptor_handshake_state = ACDS;
		
		rdy <= '0';
		wait_for_ticks(3);
		assert acceptor_handshake_state = AWNS;

		DAV <= 'L';
		wait_for_ticks(3);
		assert acceptor_handshake_state = ANRS;

		-- accept a command byte

		ATN <= '1';
		wait_for_ticks(3);
		assert acceptor_handshake_state = ACRS;
		
		DAV <= '1';
		wait_for_ticks(2);
		assert acceptor_handshake_state = ACDS;
		wait_for_ticks(1);
		assert acceptor_handshake_state = AWNS;

		DAV <= 'L';
		wait_for_ticks(2);
		assert acceptor_handshake_state = ANRS;
		wait_for_ticks(1);
		assert acceptor_handshake_state = ACRS;

		ATN <= 'L';
		rdy <= '0';
		wait_for_ticks(3);
		assert acceptor_handshake_state = ANRS;

		listener_state_p1 <= LIDS;
		wait_for_ticks(3);
		assert acceptor_handshake_state = AIDS;
		
		wait until rising_edge(clock);
		assert false report "end of test" severity note;
		test_finished := true;
		wait;
	end process;
end behav;
