-- testbench for ieee 488.1 extended listener interface function.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_states.all;

entity interface_function_PP_testbench is
end interface_function_PP_testbench;
     
architecture behav of interface_function_PP_testbench is
	signal clock : std_logic;
	signal acceptor_handshake_state : AH_state;
	signal listener_state_p1 : LE_state_p1;
	signal ATN : std_logic;
	signal PPC : std_logic;
	signal PPD : std_logic;
	signal PPE : std_logic;
	signal PPU : std_logic;
	signal IDY : std_logic;
	signal pon : std_logic;
	signal lpe : std_logic;
	signal ist : std_logic;
	signal sense : std_logic;
	signal PCG : std_logic;
	signal local_configuration_mode : std_logic;
	signal PPR_line : std_logic_vector(2 downto 0);
	signal parallel_poll_state_p1 : PP_state_p1;
	signal parallel_poll_state_p2 : PP_state_p2;
	signal PPR : std_logic_vector(7 downto 0);
	
	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	begin
	my_PP: entity work.interface_function_PP 
		port map (
			clock => clock,
			acceptor_handshake_state => acceptor_handshake_state,
			listener_state_p1 => listener_state_p1,
			ATN => ATN,
			PPC => PPC,
			PPD => PPD,
			PPE => PPE,
			PPU => PPU,
			IDY => IDY,
			pon => pon,
			lpe => lpe,
			ist => ist,
			sense => sense,
			PCG => PCG,
			local_configuration_mode => local_configuration_mode,
			PPR_line => PPR_line,
			PPR => PPR,
			parallel_poll_state_p1 => parallel_poll_state_p1,
			parallel_poll_state_p2 => parallel_poll_state_p2
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
		ATN <= 'L';
		PPC <= '0';
		PPD <= '0';
		PPE <= '0';
		PPU <= '0';
		IDY <= '0';
		pon <= '0';
		lpe <= '0';
		ist <= '0';
		sense <= '0';
		PCG <= '0';
		local_configuration_mode <= '0';
		PPR_line <= "000";
		
		wait until rising_edge(clock);
		pon <= '1';

		wait until rising_edge(clock);
		pon <= '0';
		
		wait until rising_edge(clock);
		
		assert parallel_poll_state_p1 = PPIS;
		assert parallel_poll_state_p2 = PUCS;

		PPC <= '1';
		listener_state_p1 <= LADS;
		acceptor_handshake_state <= ACDS;

		wait_for_ticks(3);
		assert parallel_poll_state_p2 = PACS;
		
		ATN <= '1';
		PPC <= '0';
		PPE <= '1';
		sense <= '1';
		ist <= '1';
		PPR_line <= "001";
		wait_for_ticks(3);
		assert parallel_poll_state_p1 = PPSS;
		
		PPE <= '0';
		IDY <= '1';
		wait_for_ticks(3);
		assert parallel_poll_state_p1 = PPAS;
		assert PPR = "LLLLLL1L";
		
		ATN <= 'L';
		IDY <= '0';
		wait_for_ticks(3);
		assert parallel_poll_state_p1 = PPSS;
		
		PPU <= '1';
		wait_for_ticks(3);
		assert parallel_poll_state_p1 = PPIS;
		
		PPU <= '0';
		ATN <= '1';
		PPE <= '1';
		wait_for_ticks(3);
		assert parallel_poll_state_p1 = PPSS;

		PPE <= '0';
		PPD <= '1';
		wait_for_ticks(3);
		assert parallel_poll_state_p1 = PPIS;

		PCG <= '1';
		wait_for_ticks(3);
		assert parallel_poll_state_p2 = PUCS;
		
		wait until rising_edge(clock);
		assert false report "end of test" severity note;
		test_finished := true;
		wait;
	end process;
end behav;
