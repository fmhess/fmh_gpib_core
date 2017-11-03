-- testbench for gpib tranceiver.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.gpib_transceiver.all;

entity gpib_transceiver_testbench is
end gpib_transceiver_testbench;
     
architecture behav of gpib_transceiver_testbench is

	signal pullup_disable : std_logic;
	signal talk_enable : std_logic;
	signal device_DIO : std_logic_vector(7 downto 0);
	signal device_ATN : std_logic;
	signal device_DAV : std_logic;
	signal device_EOI : std_logic;
	signal device_IFC : std_logic;
	signal device_NDAC : std_logic;
	signal device_NRFD : std_logic;
	signal device_REN : std_logic;
	signal device_SRQ : std_logic;
	signal bus_DIO : std_logic_vector(7 downto 0);
	signal bus_ATN : std_logic;
	signal bus_DAV : std_logic;
	signal bus_EOI : std_logic;
	signal bus_IFC : std_logic;
	signal bus_NDAC : std_logic;
	signal bus_NRFD : std_logic;
	signal bus_REN : std_logic;
	signal bus_SRQ : std_logic;
	signal not_controller_in_charge : std_logic;
	signal system_controller : std_logic;
	
	signal clock : std_logic;
	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	begin
	my_gpib_transceiver: entity work.gpib_transceiver 
		port map (
			pullup_disable => pullup_disable,
			talk_enable => talk_enable,
			device_DIO => device_DIO,
			device_ATN => device_ATN,
			device_DAV => device_DAV,
			device_EOI => device_EOI,
			device_IFC => device_IFC,
			device_NDAC => device_NDAC,
			device_NRFD => device_NRFD,
			device_REN => device_REN,
			device_SRQ => device_SRQ,
			bus_DIO => bus_DIO,
			bus_ATN => bus_ATN,
			bus_DAV => bus_DAV,
			bus_EOI => bus_EOI,
			bus_IFC => bus_IFC,
			bus_NDAC => bus_NDAC,
			bus_NRFD => bus_NRFD,
			bus_REN => bus_REN,
			bus_SRQ => bus_SRQ,
			not_controller_in_charge => not_controller_in_charge,
			system_controller => system_controller
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
		-- test DIO lines
		not_controller_in_charge <= '1';
		system_controller <= '0';
		talk_enable <= '0';
		pullup_disable <= '1';
		bus_DIO <= (others => 'H');
		wait until rising_edge(clock);

		bus_DIO <= X"55";
		device_DIO <= (others => 'Z');
		wait until rising_edge(clock);
		assert device_DIO = X"55";
		
		talk_enable <= '1';
		device_DIO <= X"aa";
		bus_DIO <= (others => 'Z');
		wait until rising_edge(clock);
		assert bus_DIO = X"aa";
		
		pullup_disable <= '0';
		bus_DIO <= (others => 'H');
		wait until rising_edge(clock);
		assert bus_DIO = "H0H0H0H0";
		
		-- test control lines
		
		bus_DIO <= (others => 'H');
		device_DIO <= (others => 'H');
		
		bus_ATN <= '1';
		bus_SRQ <= 'Z';
		device_ATN <= 'Z';
		device_SRQ <= '1';
		wait until rising_edge(clock);
		assert device_ATN = '1';
		assert bus_SRQ = 'H';
		
		not_controller_in_charge <= '0';
		device_ATN <= '0';
		device_SRQ <= 'Z';
		bus_ATN <= 'Z';
		bus_SRQ <= '0';
		wait until rising_edge(clock);
		assert bus_ATN = '0';
		assert device_SRQ = '0';

		bus_REN <= '0';
		bus_IFC <= '1';
		device_REN <= 'Z';
		device_IFC <= 'Z';
		wait until rising_edge(clock);
		assert device_REN = '0';
		assert device_IFC = '1';

		system_controller <= '1';
		device_REN <= '1';
		device_IFC <= '0';
		bus_REN <= 'Z';
		bus_IFC <= 'Z';
		wait until rising_edge(clock);
		assert bus_REN = '1';
		assert bus_IFC = '0';

		talk_enable <= '1';
		device_DAV <= '0'; 
		device_NDAC <= 'Z';
		device_NRFD <= 'Z';
		bus_DAV <= 'Z';
		bus_NDAC <= '0';
		bus_NRFD <= '1';
		wait until rising_edge(clock);
		assert bus_DAV = '0';
		assert device_NDAC = '0';
		assert device_NRFD = '1';

		talk_enable <= '0';
		device_DAV <= 'Z'; 
		device_NDAC <= '1';
		device_NRFD <= '0';
		bus_DAV <= '1';
		bus_NDAC <= 'Z';
		bus_NRFD <= 'Z';
		wait until rising_edge(clock);
		assert device_DAV = '1';
		assert bus_NDAC = '1';
		assert bus_NRFD = '0';

		-- test transmit EOI
		
		not_controller_in_charge <= '1';
		bus_ATN <= '1';
		device_ATN <= 'Z';
		talk_enable <= '1';
		device_NRFD <= 'Z';
		device_NDAC <= 'Z';
		wait until rising_edge(clock);
		
		device_EOI <= '1';
		bus_EOI <= 'Z';
		wait until rising_edge(clock);
		assert bus_EOI = '1';
		
		not_controller_in_charge <= '0';
		bus_ATN <= 'Z';
		wait until rising_edge(clock);
		talk_enable <= '0';
		wait until rising_edge(clock);
		device_ATN <= '0';
		device_EOI <= '0';
		bus_EOI <= 'Z';
		wait until rising_edge(clock);
		assert bus_EOI = '0';

		not_controller_in_charge <= '0';
		talk_enable <= '0';
		device_EOI <= '0';
		bus_EOI <= 'Z';
		wait until rising_edge(clock);
		assert bus_EOI = '0';

		-- test receive EOI

		not_controller_in_charge <= '1';
		talk_enable <= '1';
		bus_ATN <= '0';
		device_EOI <= 'Z';
		bus_EOI <= '0';
		wait until rising_edge(clock);
		assert device_EOI = '0';

		not_controller_in_charge <= '0';
		talk_enable <= '0';
		device_ATN <= '1';
		bus_ATN <= 'Z';
		device_EOI <= 'Z';
		bus_EOI <= '1';
		wait until rising_edge(clock);
		assert device_EOI = '1';

		not_controller_in_charge <= '1';
		talk_enable <= '0';
		device_EOI <= 'Z';
		bus_EOI <= '1';
		wait until rising_edge(clock);
		assert device_EOI = '1';

		wait until rising_edge(clock);
		assert false report "end of test" severity note;
		test_finished := true;
		wait;
	end process;

	-- simulate weak pullup resistors on bus
	bus_ATN <= 'H';
	bus_DAV <= 'H';
	bus_EOI <= 'H';
	bus_IFC <= 'H';
	bus_NDAC <= 'H';
	bus_NRFD <= 'H';
	bus_REN <= 'H';
	bus_SRQ <= 'H';
end behav;
