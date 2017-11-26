-- testbench consisting of two cb7210.2 instances, one
-- controller and one device.  They talk to each other
-- from behind transceivers, and use different clocks.
--
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

entity dual_cb7210p2_testbench is
end dual_cb7210p2_testbench;
     
architecture behav of dual_cb7210p2_testbench is
	signal device_clock : std_logic;
	signal controller_clock : std_logic;
	signal device_ATN_inverted : std_logic;
	signal device_DAV_inverted : std_logic;
	signal device_EOI_inverted : std_logic;
	signal device_IFC_inverted : std_logic;
	signal device_NDAC_inverted : std_logic;
	signal device_NRFD_inverted : std_logic;
	signal device_REN_inverted : std_logic;
	signal device_SRQ_inverted : std_logic;
	signal device_DIO_inverted : std_logic_vector(7 downto 0);
	signal controller_ATN_inverted : std_logic;
	signal controller_DAV_inverted : std_logic;
	signal controller_EOI_inverted : std_logic;
	signal controller_IFC_inverted : std_logic;
	signal controller_NDAC_inverted : std_logic;
	signal controller_NRFD_inverted : std_logic;
	signal controller_REN_inverted : std_logic;
	signal controller_SRQ_inverted : std_logic;
	signal controller_DIO_inverted : std_logic_vector(7 downto 0);
	signal bus_ATN_inverted : std_logic;
	signal bus_DAV_inverted : std_logic;
	signal bus_EOI_inverted : std_logic;
	signal bus_IFC_inverted : std_logic;
	signal bus_NDAC_inverted : std_logic;
	signal bus_NRFD_inverted : std_logic;
	signal bus_REN_inverted : std_logic;
	signal bus_SRQ_inverted : std_logic;
	signal bus_DIO_inverted : std_logic_vector(7 downto 0);

	signal device_chip_select_inverted : std_logic;
	signal device_dma_bus_ack_inverted : std_logic;
	signal device_dma_bus_request : std_logic;
	signal device_dma_bus : std_logic_vector(7 downto 0);
	signal device_dma_read_inverted : std_logic;
	signal device_dma_write_inverted : std_logic;
	signal device_read_inverted : std_logic;
	signal device_reset : std_logic;
	signal device_address : std_logic_vector(5 downto 0);
	signal device_write_inverted : std_logic;

	signal controller_chip_select_inverted : std_logic;
	signal controller_dma_bus_ack_inverted : std_logic;
	signal controller_dma_bus_request : std_logic;
	signal controller_dma_bus : std_logic_vector(7 downto 0);
	signal controller_dma_read_inverted : std_logic;
	signal controller_dma_write_inverted : std_logic;
	signal controller_read_inverted : std_logic;
	signal controller_reset : std_logic;
	signal controller_address : std_logic_vector(5 downto 0);
	signal controller_write_inverted : std_logic;

	signal device_interrupt : std_logic;
	signal device_host_data_bus : std_logic_vector(7 downto 0);
	signal device_pullup_disable : std_logic;
	signal device_talk_enable : std_logic;
	signal device_not_controller_in_charge : std_logic;
	signal device_system_controller : std_logic;
	
	signal controller_interrupt : std_logic;
	signal controller_host_data_bus : std_logic_vector(7 downto 0);
	signal controller_pullup_disable : std_logic;
	signal controller_talk_enable : std_logic;
	signal controller_not_controller_in_charge : std_logic;
	signal controller_system_controller : std_logic;

	constant device_clock_half_period : time := 7.5 ns;
	constant controller_clock_half_period : time := 10 ns;
	constant loop_timeout : integer := 100;
	
	signal device_sync : integer := 0;
	signal controller_sync : integer := 0;
	shared variable device_process_finished : boolean := false;
	shared variable controller_process_finished : boolean := false;

	shared variable device_primary_address : integer;
	shared variable device_secondary_address : integer;
	shared variable controller_primary_address : integer;
	shared variable controller_secondary_address : integer;
		

	begin
	device_frontend_cb7210p2: entity work.frontend_cb7210p2
		generic map (
			clock_frequency_KHz => 66667,
			num_counter_bits => 16,
			num_address_lines => 6
		)
		port map (
			clock => device_clock,
			chip_select_inverted => device_chip_select_inverted, 
			dma_bus_out_ack_inverted => device_dma_bus_ack_inverted,
			dma_bus_in_ack_inverted => device_dma_bus_ack_inverted,
			dma_read_inverted => device_dma_read_inverted,
			dma_write_inverted => device_dma_write_inverted,
			read_inverted => device_read_inverted,
			reset => device_reset,
			address => device_address,  
			write_inverted => device_write_inverted,
			pullup_disable => device_pullup_disable,
			tr1 => device_talk_enable,
			not_controller_in_charge => device_not_controller_in_charge,
			system_controller => device_system_controller,
			interrupt  => device_interrupt, 
			dma_bus_out_request  => device_dma_bus_request, 
			dma_bus_in_request  => device_dma_bus_request, 
			dma_bus_out  => device_dma_bus, 
			dma_bus_in  => device_dma_bus, 
			host_data_bus_in  => device_host_data_bus, 
			gpib_ATN_inverted_in  => device_ATN_inverted,
			gpib_DAV_inverted_in  => device_DAV_inverted, 
			gpib_EOI_inverted_in  => device_EOI_inverted, 
			gpib_IFC_inverted_in  => device_IFC_inverted, 
			gpib_NDAC_inverted_in  => device_NDAC_inverted,  
			gpib_NRFD_inverted_in  => device_NRFD_inverted, 
			gpib_REN_inverted_in  => device_REN_inverted,
			gpib_SRQ_inverted_in  => device_SRQ_inverted, 
			gpib_DIO_inverted_in  => device_DIO_inverted, 
			host_data_bus_out  => device_host_data_bus, 
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
	
	device_gpib_transceiver: entity work.gpib_transceiver
		port map(
			pullup_disable => device_pullup_disable,
			talk_enable => device_talk_enable,
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
			not_controller_in_charge => device_not_controller_in_charge,
			system_controller => device_system_controller
		);

	controller_frontend_cb7210p2: entity work.frontend_cb7210p2
		generic map (
			clock_frequency_KHz => 50000,
			num_address_lines => 6
		)
		port map (
			clock => controller_clock,
			chip_select_inverted => controller_chip_select_inverted, 
			dma_bus_out_ack_inverted => controller_dma_bus_ack_inverted,
			dma_bus_in_ack_inverted => controller_dma_bus_ack_inverted,
			dma_read_inverted => controller_dma_read_inverted,
			dma_write_inverted => controller_dma_write_inverted,
			read_inverted => controller_read_inverted,
			reset => controller_reset,
			address => controller_address,  
			write_inverted => controller_write_inverted,
			pullup_disable => controller_pullup_disable,
			tr1 => controller_talk_enable,
			not_controller_in_charge => controller_not_controller_in_charge,
			system_controller => controller_system_controller,
			interrupt  => controller_interrupt, 
			dma_bus_out_request  => controller_dma_bus_request, 
			dma_bus_in_request  => controller_dma_bus_request, 
			dma_bus_out  => controller_dma_bus, 
			dma_bus_in  => controller_dma_bus, 
			host_data_bus_in  => controller_host_data_bus, 
			gpib_ATN_inverted_in  => controller_ATN_inverted,
			gpib_DAV_inverted_in  => controller_DAV_inverted, 
			gpib_EOI_inverted_in  => controller_EOI_inverted, 
			gpib_IFC_inverted_in  => controller_IFC_inverted, 
			gpib_NDAC_inverted_in  => controller_NDAC_inverted,  
			gpib_NRFD_inverted_in  => controller_NRFD_inverted, 
			gpib_REN_inverted_in  => controller_REN_inverted,
			gpib_SRQ_inverted_in  => controller_SRQ_inverted, 
			gpib_DIO_inverted_in  => controller_DIO_inverted, 
			host_data_bus_out  => controller_host_data_bus, 
			gpib_ATN_inverted_out  => controller_ATN_inverted,
			gpib_DAV_inverted_out  => controller_DAV_inverted, 
			gpib_EOI_inverted_out  => controller_EOI_inverted, 
			gpib_IFC_inverted_out  => controller_IFC_inverted, 
			gpib_NDAC_inverted_out  => controller_NDAC_inverted,  
			gpib_NRFD_inverted_out  => controller_NRFD_inverted, 
			gpib_REN_inverted_out  => controller_REN_inverted,
			gpib_SRQ_inverted_out  => controller_SRQ_inverted, 
			gpib_DIO_inverted_out  => controller_DIO_inverted 
		);
	
	controller_gpib_transceiver: entity work.gpib_transceiver
		port map(
			pullup_disable => controller_pullup_disable,
			talk_enable => controller_talk_enable,
			device_DIO => controller_DIO_inverted,
			device_ATN => controller_ATN_inverted,
			device_DAV => controller_DAV_inverted,
			device_EOI => controller_EOI_inverted,
			device_IFC => controller_IFC_inverted,
			device_NDAC => controller_NDAC_inverted,
			device_NRFD => controller_NRFD_inverted,
			device_REN => controller_REN_inverted,
			device_SRQ => controller_SRQ_inverted,
			bus_DIO => bus_DIO_inverted,
			bus_ATN => bus_ATN_inverted,
			bus_DAV => bus_DAV_inverted,
			bus_EOI => bus_EOI_inverted,
			bus_IFC => bus_IFC_inverted,
			bus_NDAC => bus_NDAC_inverted,
			bus_NRFD => bus_NRFD_inverted,
			bus_REN => bus_REN_inverted,
			bus_SRQ => bus_SRQ_inverted,
			not_controller_in_charge => controller_not_controller_in_charge,
			system_controller => controller_system_controller
		);

	-- device clock
	process
	begin
		if(device_process_finished) then
			wait;
		end if;
		
		device_clock <= '0';
		wait for device_clock_half_period;
		device_clock <= '1';
		wait for device_clock_half_period;
	end process;

	-- controller clock
	process
	begin
		if(controller_process_finished) then
			wait;
		end if;
		
		controller_clock <= '0';
		wait for controller_clock_half_period;
		controller_clock <= '1';
		wait for controller_clock_half_period;
	end process;

	-- device process
	process
		procedure sync_with_controller(sync_point : integer) is
		begin
			device_sync <= sync_point;
			if controller_sync /= sync_point then
				wait until controller_sync = sync_point;
			end if;
			wait until rising_edge(device_clock);
		end sync_with_controller;
		
		procedure wait_for_ticks (num_clock_cycles : in integer) is
		begin
			wait_for_ticks(num_clock_cycles, device_clock);
		end procedure wait_for_ticks;

		procedure host_write (addr: in std_logic_vector(5 downto 0);
			byte : in std_logic_vector(7 downto 0)) is
		begin
			host_write (addr, byte,
				device_clock,
				device_chip_select_inverted,
				device_address,
				device_write_inverted,
				device_host_data_bus
			);
		end procedure host_write;

		procedure host_read (addr: in std_logic_vector(5 downto 0);
			result: out std_logic_vector(7 downto 0)) is
		begin
			host_read (addr, result,
				device_clock,
				device_chip_select_inverted,
				device_address,
				device_read_inverted,
				device_host_data_bus
			);
		end procedure host_read;

		variable host_read_result : std_logic_vector(7 downto 0);
		variable host_write_byte : std_logic_vector(7 downto 0);
	
		procedure wait_for_interrupt(isr0_wait_mask : std_logic_vector;
			isr1_wait_mask : std_logic_vector; isr2_wait_mask : std_logic_vector) is
			variable wait_satisfied : boolean;
		begin
			wait_satisfied := false;
			for i in 0 to loop_timeout loop
				if device_interrupt /= '1' then
					wait until device_interrupt = '1';
				end if;
				-- read clear interrupts
				host_read("001110", host_read_result); -- isr0
				if (host_read_result and isr0_wait_mask) /= X"00" then
					wait_satisfied := true;
				end if;
				host_read("000001", host_read_result); -- isr1
				if (host_read_result and isr1_wait_mask) /= X"00" then
					wait_satisfied := true;
				end if;
				host_read("000010", host_read_result); -- isr2
				if (host_read_result and isr2_wait_mask) /= X"00" then
					wait_satisfied := true;
				end if;
				
				if wait_satisfied then
					exit;
				end if;
				assert i < loop_timeout;
			end loop;
		end wait_for_interrupt;

		procedure setup_basic_io_test is
		begin

			-- set primary address
			host_write_byte(7 downto 5) := "000";
			host_write_byte(4 downto 0) := std_logic_vector(to_unsigned(device_primary_address, 5));
			host_write("000110", host_write_byte); -- address register 0/1

			-- turn on secondary addressing
			host_write_byte(7 downto 5) := "100";
			host_write_byte(4 downto 0) := std_logic_vector(to_unsigned(device_secondary_address, 5));
			host_write("000110", host_write_byte); --address register 0/1
			host_write("000100", X"32"); -- address mode register, transmit/receive mode 0x3 address mode 2
			
			host_write("001110", "00000000"); -- interrupt mask register 0
			host_write("000001", "00101011"); -- interrupt mask register 1, DI, DO, DEC, DETC interrupt enables
			host_write("000010", "00000001"); -- interrupt mask register 2, ADSC interrupt enable
		end setup_basic_io_test;
		
		procedure basic_io_test is
		begin
			host_read("000100", host_read_result); -- address status register
			if host_read_result(2) /= '1' then -- if not already addressed as listener
				-- wait to be addressed as listener
				for i in 0 to loop_timeout loop
					wait_for_interrupt(X"00", X"00", X"01"); -- wait for address status change interrupt
					
					host_read("000100", host_read_result); -- address status register
					if host_read_result(2) = '1' then -- addressed as listener
						exit;
					end if;
					assert i < loop_timeout;
				end loop;
			end if;
			
			-- receive n data bytes
			for n in 0 to 9 loop
				wait_for_interrupt(X"00", X"01", X"00"); -- wait for DI interrupt
				
				host_read("000000", host_read_result);
				assert host_read_result = std_logic_vector(to_unsigned(n, 8));
			end loop;
		end basic_io_test;
		
	begin
		device_chip_select_inverted <= '1';
		device_dma_bus_ack_inverted <= '1';
		device_dma_bus <= (others => 'Z');
		device_host_data_bus <= (others => '0');
		device_read_inverted <= '1';
		device_write_inverted <= '1';
		device_dma_read_inverted <= '1';
		device_dma_write_inverted <= '1';
		device_address <= ( others => '0' );
		device_primary_address := 4;
		device_secondary_address := 17;
		
		device_reset <= '1';
		wait until rising_edge(device_clock);	
		device_reset <= '0';
		wait until rising_edge(device_clock);	
		
		setup_basic_io_test;

		sync_with_controller(1);
		
		basic_io_test;
		
		sync_with_controller(2);

		wait until rising_edge(device_clock);	
		assert false report "end of device process" severity note;
		device_process_finished := true;
		wait;
	end process;

	-- controller process
	process
		procedure sync_with_device(sync_point : integer) is
		begin
			controller_sync <= sync_point;
			if controller_sync /= sync_point then
				wait until controller_sync = device_sync;
			end if;
			wait until rising_edge(controller_clock);
		end sync_with_device;
		
		procedure wait_for_ticks (num_clock_cycles : in integer) is
		begin
			wait_for_ticks(num_clock_cycles, controller_clock);
		end procedure wait_for_ticks;

		procedure host_write (addr: in std_logic_vector(5 downto 0);
			byte : in std_logic_vector(7 downto 0)) is
		begin
			host_write (addr, byte,
				controller_clock,
				controller_chip_select_inverted,
				controller_address,
				controller_write_inverted,
				controller_host_data_bus
			);
		end procedure host_write;

		procedure host_read (addr: in std_logic_vector(5 downto 0);
			result: out std_logic_vector(7 downto 0)) is
		begin
			host_read (addr, result,
				controller_clock,
				controller_chip_select_inverted,
				controller_address,
				controller_read_inverted,
				controller_host_data_bus
			);
		end procedure host_read;

		variable host_read_result : std_logic_vector(7 downto 0);
		variable host_write_byte : std_logic_vector(7 downto 0);
	
		procedure wait_for_interrupt(isr0_wait_mask : std_logic_vector;
			isr1_wait_mask : std_logic_vector; isr2_wait_mask : std_logic_vector) is
			variable wait_satisfied : boolean;
		begin
			wait_satisfied := false;
			for i in 0 to loop_timeout loop
				if controller_interrupt /= '1' then
					wait until controller_interrupt = '1';
				end if;
				-- read clear interrupts
				host_read("001110", host_read_result); -- isr0
				if (host_read_result and isr0_wait_mask) /= X"00" then
					wait_satisfied := true;
				end if;
				host_read("000001", host_read_result); -- isr1
				if (host_read_result and isr1_wait_mask) /= X"00" then
					wait_satisfied := true;
				end if;
				host_read("000010", host_read_result); -- isr2
				if (host_read_result and isr2_wait_mask) /= X"00" then
					wait_satisfied := true;
				end if;
				
				if wait_satisfied then
					exit;
				end if;
				assert i < loop_timeout;
			end loop;
		end wait_for_interrupt;
		
		--address chip as listener
		procedure send_setup is
		begin
			host_write("000101", "00010010"); -- tcs			
			wait_for_ticks(3);
			assert to_X01(bus_ATN_inverted) = '0';

			wait_for_interrupt(X"00", X"00", X"08"); -- wait for CO interrupt

			host_write_byte(7 downto 5) := "010";
			host_write_byte(4 downto 0) := std_logic_vector(to_unsigned(controller_primary_address, 5));
			host_write("000000", host_write_byte); -- controller MTA

			if controller_secondary_address /= to_integer(unsigned(NO_ADDRESS_CONFIGURED)) then
				wait_for_interrupt(X"00", X"00", X"08"); -- wait for CO interrupt
			
				host_write_byte(7 downto 5) := "011";
				host_write_byte(4 downto 0) := std_logic_vector(to_unsigned(controller_secondary_address, 5));
				host_write("000000", host_write_byte); -- controller MSA
			end if;

			wait_for_interrupt(X"00", X"00", X"08"); -- wait for CO interrupt

			host_write("000000", "00111111"); -- UNL

			wait_for_interrupt(X"00", X"00", X"08"); -- wait for CO interrupt
			
			host_write_byte(7 downto 5) := "001";
			host_write_byte(4 downto 0) := std_logic_vector(to_unsigned(device_primary_address, 5));
			host_write("000000", host_write_byte); -- device MLA

			if device_secondary_address /= to_integer(unsigned(NO_ADDRESS_CONFIGURED)) then
				wait_for_interrupt(X"00", X"00", X"08"); -- wait for CO interrupt
			
				host_write_byte(7 downto 5) := "011";
				host_write_byte(4 downto 0) := std_logic_vector(to_unsigned(device_secondary_address, 5));
				host_write("000000", host_write_byte); -- device MSA
			end if;

			wait_for_interrupt(X"00", X"00", X"08"); -- wait for CO interrupt
		end send_setup;

		procedure setup_basic_io_test is
		begin

			-- set primary address
			host_write_byte(7 downto 5) := "000";
			host_write_byte(4 downto 0) := std_logic_vector(to_unsigned(controller_primary_address, 5));
			host_write("000110", host_write_byte); -- address register 0/1
			host_write("000100", X"31"); -- address mode register, transmit/receive mode 0x3 address mode 1

			host_write("001110", "00000000"); -- interrupt mask register 0
			host_write("000001", "00000011"); -- interrupt mask register 1, DI, DO interrupt enables
			host_write("000010", "00001000"); -- interrupt mask register 2, CO interrupt enables

			host_write("000101", "00011110"); -- set IFC
			wait for 100 us;
			host_write("000101", "00010110"); -- release IFC
			wait_for_ticks(3);
			assert to_X01(bus_IFC_inverted) = '1';
		end setup_basic_io_test;
		
		procedure basic_io_test is
		begin
			send_setup;
			
			-- send n data bytes
			host_write("000101", "00010000"); -- gts			
			wait_for_ticks(5);
			assert to_X01(bus_ATN_inverted) = '1';

			for n in 0 to 9 loop
				wait_for_interrupt(X"00", X"02", X"00"); -- wait for DO interrupt
				host_write_byte := std_logic_vector(to_unsigned(n, 8));
				host_write("000000", host_write_byte);
			end loop;
			wait_for_interrupt(X"00", X"02", X"00"); -- wait for DO interrupt
		end basic_io_test;
		
	begin
		controller_chip_select_inverted <= '1';
		controller_dma_bus_ack_inverted <= '1';
		controller_dma_bus <= (others => 'Z');
		controller_host_data_bus <= (others => '0');
		controller_read_inverted <= '1';
		controller_write_inverted <= '1';
		controller_dma_read_inverted <= '1';
		controller_dma_write_inverted <= '1';
		controller_address <= ( others => '0' );
		controller_primary_address := 8;
		controller_secondary_address := to_integer(unsigned(NO_ADDRESS_CONFIGURED));
		
		controller_reset <= '1';
		wait until rising_edge(controller_clock);	
		controller_reset <= '0';
		wait until rising_edge(controller_clock);	
		
		setup_basic_io_test;
		
		sync_with_device(1);
		
		basic_io_test;
		
		sync_with_device(2);
		
		wait until rising_edge(controller_clock);	
		assert false report "end of controller process" severity note;
		controller_process_finished := true;
		wait;
	end process;

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
