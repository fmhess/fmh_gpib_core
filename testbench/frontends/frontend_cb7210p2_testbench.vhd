-- testbench for integrated interface functions.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;
use work.gpib_transceiver.all;
use work.test_common.all;
use work.frontend_cb7210p2.all;

entity frontend_cb7210p2_testbench is
end frontend_cb7210p2_testbench;
     
architecture behav of frontend_cb7210p2_testbench is
	signal clock : std_logic;
	signal device_ATN_inverted : std_logic;
	signal device_DAV_inverted : std_logic;
	signal device_EOI_inverted : std_logic;
	signal device_IFC_inverted : std_logic;
	signal device_NDAC_inverted : std_logic;
	signal device_NRFD_inverted : std_logic;
	signal device_REN_inverted : std_logic;
	signal device_SRQ_inverted : std_logic;
	signal device_DIO_inverted : std_logic_vector(7 downto 0);
	signal bus_ATN_inverted : std_logic;
	signal bus_DAV_inverted : std_logic;
	signal bus_EOI_inverted : std_logic;
	signal bus_IFC_inverted : std_logic;
	signal bus_NDAC_inverted : std_logic;
	signal bus_NRFD_inverted : std_logic;
	signal bus_REN_inverted : std_logic;
	signal bus_SRQ_inverted : std_logic;
	signal bus_DIO_inverted : std_logic_vector(7 downto 0);
	signal chip_select_inverted : std_logic;
	signal dma_bus_ack_inverted : std_logic;
	signal dma_bus_request : std_logic;
	signal dma_bus : std_logic_vector(7 downto 0);
	signal dma_read_inverted : std_logic;
	signal dma_write_inverted : std_logic;
	signal read_inverted : std_logic;
	signal reset : std_logic;
	signal address : std_logic_vector(2 downto 0);
	signal write_inverted : std_logic;
	signal tr1 : std_logic;
	signal tr2 : std_logic;
	signal tr3 : std_logic;
	signal interrupt : std_logic;
	signal host_data_bus : std_logic_vector(7 downto 0);
	signal pullup_disable : std_logic;
	signal talk_enable : std_logic;
	signal not_controller_in_charge : std_logic;
	signal system_controller : std_logic;
	
	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	begin
	my_frontend_cb7210p2: entity work.frontend_cb7210p2
		generic map (
			clock_frequency_KHz => 10000,
			num_counter_bits => 16
		)
		port map (
			clock => clock,
			chip_select_inverted => chip_select_inverted, 
			dma_bus_out_ack_inverted => dma_bus_ack_inverted,
			dma_bus_in_ack_inverted => dma_bus_ack_inverted,
			dma_read_inverted => dma_read_inverted,
			dma_write_inverted => dma_write_inverted,
			read_inverted => read_inverted,
			reset => reset,
			address => address,  
			write_inverted => write_inverted, 
			tr1  => tr1,
			tr2  => tr2, 
			tr3  => tr3,
			interrupt  => interrupt, 
			dma_bus_out_request  => dma_bus_request, 
			dma_bus_in_request  => dma_bus_request, 
			dma_bus_out  => dma_bus, 
			dma_bus_in  => dma_bus, 
			host_data_bus_in  => host_data_bus, 
			gpib_ATN_inverted_in  => device_ATN_inverted,
			gpib_DAV_inverted_in  => device_DAV_inverted, 
			gpib_EOI_inverted_in  => device_EOI_inverted, 
			gpib_IFC_inverted_in  => device_IFC_inverted, 
			gpib_NDAC_inverted_in  => device_NDAC_inverted,  
			gpib_NRFD_inverted_in  => device_NRFD_inverted, 
			gpib_REN_inverted_in  => device_REN_inverted,
			gpib_SRQ_inverted_in  => device_SRQ_inverted, 
			gpib_DIO_inverted_in  => device_DIO_inverted, 
			host_data_bus_out  => host_data_bus, 
			gpib_ATN_inverted_out  => device_ATN_inverted,
			gpib_DAV_inverted_out  => device_DAV_inverted, 
			gpib_EOI_inverted_out  => device_EOI_inverted, 
			gpib_IFC_inverted_out  => device_IFC_inverted, 
			gpib_NDAC_inverted_out  => device_NDAC_inverted,  
			gpib_NRFD_inverted_out  => device_NRFD_inverted, 
			gpib_REN_inverted_out  => device_REN_inverted,
			gpib_SRQ_inverted_out  => device_SRQ_inverted, 
			gpib_DIO_inverted_out  => device_DIO_inverted 
		);
	
	my_gpib_transceiver: entity work.gpib_transceiver
		port map(
			pullup_disable => 	pullup_disable,
			talk_enable => talk_enable,
			device_DIO => device_DIO_inverted,
			device_ATN => device_ATN_inverted,
			device_DAV => device_DAV_inverted,
			device_EOI => device_EOI_inverted,
			device_IFC => device_IFC_inverted,
			device_NDAC => device_NDAC_inverted,
			device_NRFD => device_NRFD_inverted,
			device_REN => device_REN_inverted,
			device_SRQ => device_SRQ_inverted,
			bus_DIO => bus_DIO_inverted,
			bus_ATN => bus_ATN_inverted,
			bus_DAV => bus_DAV_inverted,
			bus_EOI => bus_EOI_inverted,
			bus_IFC => bus_IFC_inverted,
			bus_NDAC => bus_NDAC_inverted,
			bus_NRFD => bus_NRFD_inverted,
			bus_REN => bus_REN_inverted,
			bus_SRQ => bus_SRQ_inverted,
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
		procedure wait_for_ticks (num_clock_cycles : in integer) is
		begin
			wait_for_ticks(num_clock_cycles, clock);
		end procedure wait_for_ticks;

		procedure gpib_setup_bus (assert_ATN : boolean; 
		talk_enable : in boolean) is
		begin
			gpib_setup_bus(assert_ATN, talk_enable,
				bus_DIO_inverted,
				bus_ATN_inverted,
				bus_DAV_inverted,
				bus_EOI_inverted,
				bus_NDAC_inverted,
				bus_NRFD_inverted,
				bus_SRQ_inverted);
		end gpib_setup_bus;

		procedure gpib_write (data_byte : in std_logic_vector(7 downto 0);
			assert_eoi : in boolean) is
		begin
			gpib_write (data_byte, assert_eoi,
				bus_DIO_inverted,
				bus_DAV_inverted,
				bus_EOI_inverted,
				bus_NDAC_inverted,
				bus_NRFD_inverted);
		end procedure gpib_write;

		procedure gpib_read (data_byte : out std_logic_vector(7 downto 0);
			eoi : out std_logic) is
		begin
			gpib_read(data_byte, eoi,
				bus_DIO_inverted,
				bus_DAV_inverted,
				bus_EOI_inverted,
				bus_NDAC_inverted,
				bus_NRFD_inverted);
		end procedure gpib_read;

		procedure host_write (addr: in std_logic_vector(2 downto 0);
			byte : in std_logic_vector(7 downto 0)) is
		begin
			host_write (addr, byte,
				clock,
				chip_select_inverted,
				address,
				write_inverted,
				host_data_bus
			);
		end procedure host_write;

		procedure host_read (addr: in std_logic_vector(2 downto 0);
			result: out std_logic_vector(7 downto 0)) is
		begin
			host_read (addr, result,
				clock,
				chip_select_inverted,
				address,
				read_inverted,
				host_data_bus
			);
		end procedure host_read;

		variable gpib_read_result : std_logic_vector(7 downto 0);
		variable gpib_read_eoi : std_logic;
		variable gpib_write_byte : std_logic_vector(7 downto 0);
		variable host_read_result : std_logic_vector(7 downto 0);
		variable host_write_byte : std_logic_vector(7 downto 0);
	
		variable primary_address : integer;
		variable secondary_address : integer;
		
		--address chip as listener
		procedure gpib_address_as_listener is
		begin
			assert primary_address /= to_integer(unsigned(NO_ADDRESS_CONFIGURED));
			wait until rising_edge(clock);	
			gpib_write_byte(7 downto 5) := "001";
			gpib_write_byte(4 downto 0) := std_logic_vector(to_unsigned(primary_address, 5));
			gpib_write(gpib_write_byte, false); -- MLA
			if secondary_address /= to_integer(unsigned(NO_ADDRESS_CONFIGURED)) then
				-- if secondary address is enabled, make sure we didn't prematurely become addressed
				host_read("100", host_read_result); -- address status reg
				assert host_read_result(2) = '0';

				gpib_write_byte(7 downto 5) := "011";
				gpib_write_byte(4 downto 0) := std_logic_vector(to_unsigned(secondary_address, 5));
				gpib_write(gpib_write_byte, false); -- MSA
			end if;
			wait until rising_edge(clock);	
		end gpib_address_as_listener;
		
		procedure test_device_clear is
		begin
			gpib_setup_bus(true, true);
			-- unlisten
			gpib_write_byte := "00111111";
			gpib_write(gpib_write_byte, false);
			
			-- enable DEC interrupts
			host_write("001", "00001000"); -- interrupt mask register 1
			host_read("001", host_read_result); -- read clear any pending interrupts
			assert interrupt = '0';

			-- send DCL
			gpib_write_byte := "00010100";
			gpib_write(gpib_write_byte, false);
			if interrupt /= '1' then
				wait until interrupt = '1';
			end if;
			host_read("001", host_read_result);
			assert host_read_result(3) = '1';
			
			
			-- send selected device clear, this should produce no effect since chip is not listener
			gpib_write_byte := "00000100";
			gpib_write(gpib_write_byte, false);
			wait_for_ticks(3);
			assert interrupt = '0';

			-- address as listener then do SDC, this should produce device clear interrupt
			gpib_address_as_listener;
			
			gpib_write_byte := "00000100";
			gpib_write(gpib_write_byte, false);
			
			-- make sure we got a device clear interrupt
			if interrupt /= '1' then
				wait until interrupt = '1';
			end if;
			host_read("001", host_read_result);
			assert host_read_result(3) = '1';

		end test_device_clear;
		
	begin
		bus_DIO_inverted <= "HHHHHHHH";
		bus_REN_inverted <= 'H';
		bus_IFC_inverted <= 'H';
		bus_SRQ_inverted <= 'H';
		bus_EOI_inverted <= 'H';
		bus_ATN_inverted <= 'H';
		bus_NDAC_inverted <= 'H';
		bus_NRFD_inverted <= 'H';
		bus_DAV_inverted <= 'H';
		reset <= '0';
		chip_select_inverted <= '1';
		dma_bus_ack_inverted <= '1';
		dma_bus_request <= '0';
		dma_bus <= (others => 'Z');
		host_data_bus <= (others => '0');
		read_inverted <= '1';
		write_inverted <= '1';
		dma_read_inverted <= '1';
		dma_write_inverted <= '1';
		address <= ( others => '0' );
		primary_address := 0;
		secondary_address := to_integer(unsigned(NO_ADDRESS_CONFIGURED));
		
		wait until rising_edge(clock);	
		reset <= '1';
		wait until rising_edge(clock);	
		reset <= '0';
		wait until rising_edge(clock);	
		
		-- initialize chip

		host_write("100", X"31"); -- address mode register, transmit/receive mode 0x3 address mode 1

		-- set primary address
		primary_address := 5;
		host_write_byte(7 downto 5) := "000";
		host_write_byte(4 downto 0) := std_logic_vector(to_unsigned(primary_address, 5));
		host_write("110", host_write_byte); --address register 0/1

		--address chip as talker
		gpib_setup_bus(true, true);
		gpib_write_byte(7 downto 5) := "010";
		gpib_write_byte(4 downto 0) := std_logic_vector(to_unsigned(primary_address, 5));
		gpib_write(gpib_write_byte, false); -- MTA

		--send a data byte host to gpib

		gpib_setup_bus(false, false);
		-- enable DO interrupts
		host_write("001", "00000010"); -- interrupt mask register 1

		-- wait for DO interrupt
		if interrupt /= '1' then
			wait until interrupt = '1';
		end if;
		host_read("001", host_read_result);
		assert host_read_result(1) = '1';
		host_read("001", host_read_result);
		-- interrupt should clear on read
		assert host_read_result(1) = '0'; 
		assert interrupt = '0';
		
		host_write("000", X"01");
		wait until rising_edge(clock);	
		wait until rising_edge(clock);	
		gpib_read(gpib_read_result, gpib_read_eoi);
		wait until rising_edge(clock);	
		assert gpib_read_result = X"01";
		assert gpib_read_eoi = '0';
		
		--send a data byte host to gpib with EOI
		host_write("101", "00000110"); -- send eoi aux command
		host_write("000", X"02");
		wait until rising_edge(clock);	
		gpib_read(gpib_read_result, gpib_read_eoi);
		wait until rising_edge(clock);	
		assert gpib_read_result = X"02";
		assert gpib_read_eoi = '1';

		--send another data byte to make sure "send eoi" message clears
		host_write("000", X"03");
		wait until rising_edge(clock);	
		gpib_read(gpib_read_result, gpib_read_eoi);
		wait until rising_edge(clock);	
		assert gpib_read_result = X"03";
		assert gpib_read_eoi = '0';

		-- turn on secondary addressing
		secondary_address := 10;
		host_write_byte(7 downto 5) := "100";
		host_write_byte(4 downto 0) := std_logic_vector(to_unsigned(secondary_address, 5));
		host_write("110", host_write_byte); --address register 0/1
		host_write("100", X"32"); -- address mode register, transmit/receive mode 0x3 address mode 2

		gpib_setup_bus(true, true);
		
		--address chip as listener
		gpib_address_as_listener;

		-- write some bytes from gpib to host
		gpib_setup_bus(false, true);

		-- enable DI and END interrupts
		host_write("001", "00010001"); -- interrupt mask register 1

		gpib_write_byte(7 downto 0) := X"10";
		gpib_write(gpib_write_byte, false);

		-- wait for DI interrupt
		if interrupt /= '1' then
			wait until interrupt = '1';
		end if;
		host_read("001", host_read_result);
		assert host_read_result(0) = '1';
		host_read("001", host_read_result);
		-- interrupt should clear on read
		assert host_read_result(0) = '0'; 
		assert interrupt = '0';
		-- read out data byte
		host_read("000", host_read_result);
		assert host_read_result = X"10";
		
		--write a byte with EOI asserted
		gpib_write_byte(7 downto 0) := X"20";
		gpib_write(gpib_write_byte, true);
		-- check that we got END interrupt along with DI
		if interrupt /= '1' then
			wait until interrupt = '1';
		end if;
		host_read("001", host_read_result);
		assert host_read_result(0) = '1'; -- DI interrupt
		assert host_read_result(4) = '1'; -- END interrupt
		host_read("001", host_read_result);
		assert host_read_result(0) = '0'; -- DI interrupt
		assert host_read_result(4) = '0'; -- END interrupt
		-- read out data byte
		host_read("000", host_read_result);
		assert host_read_result = X"20";

		-- write pon to aux command reg
		host_write("101", X"00");
		
		test_device_clear;
		
		wait until rising_edge(clock);	
		assert false report "end of test" severity note;
		test_finished := true;
		wait;
	end process;

	talk_enable <= tr1;
	not_controller_in_charge <= not tr2;
	system_controller <= '0';
	pullup_disable <= tr3;

	--pullup resistors
	bus_DIO_inverted <= "HHHHHHHH";
	bus_ATN_inverted <= 'H';
	bus_DAV_inverted <= 'H';
	bus_IFC_inverted <= 'H';
	bus_EOI_inverted <= 'H';
	bus_NDAC_inverted <= 'H';
	bus_NRFD_inverted <= 'H';
	bus_REN_inverted <= 'H';
	bus_SRQ_inverted <= 'H';
end behav;
