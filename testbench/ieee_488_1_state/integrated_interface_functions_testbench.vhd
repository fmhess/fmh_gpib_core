-- testbench for integrated interface functions.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_states.all;
use work.integrated_interface_functions.all;

entity integrated_interface_functions_testbench is
end integrated_interface_functions_testbench;
     
architecture behav of integrated_interface_functions_testbench is
	signal clock : std_logic;
	signal bus_DIO : std_logic_vector(7 downto 0);
	signal bus_REN : std_logic;
	signal bus_IFC : std_logic;
	signal bus_SRQ : std_logic;
	signal bus_EOI : std_logic;
	signal bus_ATN : std_logic;
	signal bus_NDAC : std_logic;
	signal bus_NRFD : std_logic;
	signal bus_DAV : std_logic;

	signal configured_eos_character : std_logic_vector(7 downto 0);
	signal ignore_eos_bit_7 : std_logic;
	signal configured_primary_address : std_logic_vector(4 downto 0);
	signal configured_secondary_address :std_logic_vector(4 downto 0);
	signal local_parallel_poll_config : std_logic;
	signal local_parallel_poll_sense : std_logic;
	signal local_parallel_poll_response_line : std_logic_vector(2 downto 0);
	signal check_for_listeners : std_logic;
	signal no_listeners : std_logic;
	signal first_T1_terminal_count : std_logic_vector(15 downto 0);
	signal T1_terminal_count : std_logic_vector(15 downto 0);

	signal ist : std_logic;
	signal lon : std_logic;	
	signal lpe : std_logic;
	signal lun : std_logic;
	signal ltn : std_logic;
	signal pon : std_logic;
	signal rsv : std_logic;
	signal rtl : std_logic;
	signal ton : std_logic;
	signal tcs : std_logic;

	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	begin
	my_integrated_interface_functions: entity work.integrated_interface_functions 
		port map (
			clock => clock,
			bus_DIO_in => bus_DIO,
			bus_REN_in => bus_REN,
			bus_IFC_in => bus_IFC,
			bus_SRQ_in => bus_SRQ,
			bus_EOI_in => bus_EOI,
			bus_ATN_in => bus_ATN,
			bus_NDAC_in => bus_NDAC,
			bus_NRFD_in => bus_NRFD,
			bus_DAV_in => bus_DAV,
			bus_DIO_out => bus_DIO,
			bus_REN_out => bus_REN,
			bus_IFC_out => bus_IFC,
			bus_SRQ_out => bus_SRQ,
			bus_EOI_out => bus_EOI,
			bus_ATN_out => bus_ATN,
			bus_NDAC_out => bus_NDAC,
			bus_NRFD_out => bus_NRFD,
			bus_DAV_out => bus_DAV,
			ist => ist,
			lon => lon,
			lpe => lpe,
			lun => lun,
			ltn => ltn,
			pon => pon,
			rsv => rsv,
			rtl => rtl,
			tcs => tcs,
			ton => ton,
			configured_eos_character => configured_eos_character,
			ignore_eos_bit_7 => ignore_eos_bit_7,
			configured_primary_address => configured_primary_address,
			configured_secondary_address => configured_secondary_address,
			local_parallel_poll_config => local_parallel_poll_config,
			local_parallel_poll_sense => local_parallel_poll_sense,
			local_parallel_poll_response_line => local_parallel_poll_response_line,
			check_for_listeners => check_for_listeners,
			first_T1_terminal_count => first_T1_terminal_count,
			T1_terminal_count => T1_terminal_count,
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
		-- wait wait for a condition with a hard coded timeout to avoid infinite test loops on failure
		procedure wait_for_ticks (num_clock_cycles : in integer) is
			begin
				for i in 1 to num_clock_cycles loop
					wait until rising_edge(clock);
				end loop;
			end procedure wait_for_ticks;

	begin
		bus_DIO <= "LLLLLLLL";
		bus_REN <= 'L';
		bus_IFC <= 'L';
		bus_SRQ <= 'L';
		bus_EOI <= 'L';
		bus_ATN <= 'L';
		bus_NDAC <= 'L';
		bus_NRFD <= 'L';
		bus_DAV <= 'L';
		configured_eos_character <= X"00";
		ignore_eos_bit_7 <= '0';
		configured_primary_address <= to_stdlogicvector(NO_ADDRESS_CONFIGURED);
		configured_secondary_address <= to_stdlogicvector(NO_ADDRESS_CONFIGURED);
		local_parallel_poll_config <= '0';
		local_parallel_poll_sense <= '0';
		local_parallel_poll_response_line <= "000";
		check_for_listeners <= '1';
		first_T1_terminal_count <= X"0004";
		T1_terminal_count <= X"0002";
		ist <= '0';
		lon <= '0';
		lpe <= '0';
		lun <= '0';
		ltn <= '0';
		pon <= '0';
		rsv <= '0';
		rtl <= '0';
		ton <= '0';
		tcs <= '0';
				
		wait until rising_edge(clock);	
		pon <= '1';
		wait until rising_edge(clock);	
		pon <= '0';
		wait until rising_edge(clock);	
		
		wait until rising_edge(clock);	
		assert false report "end of test" severity note;
		test_finished := true;
		wait;
	end process;
end behav;
