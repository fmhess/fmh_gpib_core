-- testbench for cb7210.2 frontend.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;
use work.test_common.all;
use work.fmh_gpib_top.all;

entity fmh_gpib_top_testbench is
end fmh_gpib_top_testbench;
     
architecture behav of fmh_gpib_top_testbench is
	signal clock : std_logic;
	signal bus_ATN_inverted : std_logic;
	signal bus_DAV_inverted : std_logic;
	signal bus_EOI_inverted : std_logic;
	signal bus_IFC_inverted : std_logic;
	signal bus_NDAC_inverted : std_logic;
	signal bus_NRFD_inverted : std_logic;
	signal bus_REN_inverted : std_logic;
	signal bus_SRQ_inverted : std_logic;
	signal bus_DIO_inverted : std_logic_vector(7 downto 0);
	signal avalon_chip_select_inverted : std_logic;
	signal dma_single : std_logic;
	signal dma_req : std_logic;
	signal dma_ack : std_logic;
	signal dma_fifos_data_in : std_logic_vector(15 downto 0);
	signal dma_fifos_data_out : std_logic_vector(15 downto 0);
	signal dma_fifos_address : std_logic_vector(1 downto 0);
	signal dma_fifos_read : std_logic;
	signal dma_fifos_write : std_logic;
	signal dma_fifos_chip_select : std_logic;
	signal avalon_read_inverted : std_logic;
	signal reset : std_logic;
	signal avalon_address : std_logic_vector(6 downto 0);
	signal avalon_write_inverted : std_logic;
	signal talk_enable : std_logic;
	signal controller_in_charge : std_logic;
	signal pullup_enable_inverted : std_logic;
	signal interrupt : std_logic;
	signal avalon_data_in : std_logic_vector(7 downto 0);
	signal avalon_data_out : std_logic_vector(7 downto 0);
	signal gpib_disable : std_logic;
	
	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	begin
	my_fmh_gpib_top: entity work.fmh_gpib_top
		generic map (
			clock_frequency_KHz => 10000
		)
		port map (
			clock => clock,
			avalon_chip_select_inverted => avalon_chip_select_inverted, 
			dma_fifos_read => dma_fifos_read,
			dma_fifos_write => dma_fifos_write,
			dma_fifos_chip_select => dma_fifos_chip_select,
			dma_fifos_data_in => dma_fifos_data_in,
			dma_fifos_data_out => dma_fifos_data_out,
			dma_fifos_address => dma_fifos_address,
			avalon_read_inverted => avalon_read_inverted,
			reset => reset,
			avalon_address => avalon_address,  
			avalon_write_inverted => avalon_write_inverted, 
			pullup_enable_inverted => pullup_enable_inverted,
			controller_in_charge => controller_in_charge,
			talk_enable => talk_enable,
			irq  => interrupt, 
			dma_single => dma_single,
			dma_req => dma_req,
			dma_ack => dma_ack,
			avalon_data_in => avalon_data_in, 
			gpib_ATN_inverted  => bus_ATN_inverted,
			gpib_DAV_inverted  => bus_DAV_inverted, 
			gpib_EOI_inverted  => bus_EOI_inverted, 
			gpib_IFC_inverted  => bus_IFC_inverted, 
			gpib_NDAC_inverted  => bus_NDAC_inverted,  
			gpib_NRFD_inverted  => bus_NRFD_inverted, 
			gpib_REN_inverted  => bus_REN_inverted,
			gpib_SRQ_inverted  => bus_SRQ_inverted, 
			gpib_DIO_inverted  => bus_DIO_inverted, 
			avalon_data_out  => avalon_data_out, 
			gpib_disable => gpib_disable
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

		procedure host_write (addr: in std_logic_vector(6 downto 0);
			byte : in std_logic_vector(7 downto 0)) is
		begin
			host_write (addr, byte,
				clock,
				avalon_chip_select_inverted,
				avalon_address,
				avalon_write_inverted,
				avalon_data_in
			);
		end procedure host_write;

		procedure host_read (addr: in std_logic_vector(6 downto 0);
			result: out std_logic_vector(7 downto 0)) is
		begin
			host_read (addr, result,
				clock,
				avalon_chip_select_inverted,
				avalon_address,
				avalon_read_inverted,
				avalon_data_out
			);
		end procedure host_read;

		procedure do_dma_ack is
		begin
			wait_for_ticks(1);
			dma_ack <= '1';
			if to_X01(dma_req) = '1' or to_X01(dma_single) = '1' then
				wait until to_X01(dma_req) = '0' and to_X01(dma_single) = '0';
			end if;
			wait_for_ticks(1);
			dma_ack <= '0';
			wait_for_ticks(1);
		end procedure do_dma_ack;
		
		procedure dma_write (addr: in std_logic_vector(1 downto 0);
			data : in std_logic_vector(15 downto 0)) is
		begin
			host_write (addr, data,
				clock,
				dma_fifos_chip_select,
				dma_fifos_address,
				dma_fifos_write,
				dma_fifos_data_in,
				'0'
			);
			do_dma_ack;
		end procedure dma_write;

		procedure dma_read (addr: in std_logic_vector(1 downto 0);
			result: out std_logic_vector(15 downto 0)) is
		begin
			host_read (addr, result,
				clock,
				dma_fifos_chip_select,
				dma_fifos_address,
				dma_fifos_read,
				dma_fifos_data_out,
				'0'
			);
			do_dma_ack;
		end procedure dma_read;

		variable gpib_read_result : std_logic_vector(7 downto 0);
		variable gpib_read_eoi : std_logic;
		variable gpib_write_byte : std_logic_vector(7 downto 0);
		variable host_read_result_8 : std_logic_vector(7 downto 0);
		variable host_write_8 : std_logic_vector(7 downto 0);
		variable host_read_result_16 : std_logic_vector(15 downto 0);
		variable host_write_16 : std_logic_vector(15 downto 0);
	
		variable primary_address : integer;
		variable secondary_address : integer;
		
		--address chip as listener
		procedure gpib_address_as_listener(listener_primary_address : integer;
			listener_secondary_address : integer) is
		begin
			gpib_setup_bus(true, true);

			assert listener_primary_address /= to_integer(unsigned(NO_ADDRESS_CONFIGURED));
			wait until rising_edge(clock);	
			gpib_write_byte(7 downto 5) := "001";
			gpib_write_byte(4 downto 0) := std_logic_vector(to_unsigned(listener_primary_address, 5));
			gpib_write(gpib_write_byte, false); -- MLA
			if listener_secondary_address /= to_integer(unsigned(NO_ADDRESS_CONFIGURED)) then
				gpib_write_byte(7 downto 5) := "011";
				gpib_write_byte(4 downto 0) := std_logic_vector(to_unsigned(listener_secondary_address, 5));
				gpib_write(gpib_write_byte, false); -- MSA
			end if;
			wait until rising_edge(clock);	
		end gpib_address_as_listener;

		procedure gpib_address_as_listener is
		begin
			gpib_address_as_listener(primary_address, secondary_address);
		end gpib_address_as_listener;
		
		--address chip as talker
		procedure gpib_address_as_talker(talker_primary_address : integer;
			talker_secondary_address : integer) is
		begin
			gpib_setup_bus(true, true);

			assert talker_primary_address /= to_integer(unsigned(NO_ADDRESS_CONFIGURED));
			wait until rising_edge(clock);	
			gpib_write_byte(7 downto 5) := "010";
			gpib_write_byte(4 downto 0) := std_logic_vector(to_unsigned(talker_primary_address, 5));
			gpib_write(gpib_write_byte, false); -- MTA
			if talker_secondary_address /= to_integer(unsigned(NO_ADDRESS_CONFIGURED)) then
				gpib_write_byte(7 downto 5) := "011";
				gpib_write_byte(4 downto 0) := std_logic_vector(to_unsigned(talker_secondary_address, 5));
				gpib_write(gpib_write_byte, false); -- MSA
			end if;
			wait until rising_edge(clock);	
		end gpib_address_as_talker;

		procedure gpib_address_as_talker is
		begin
			gpib_address_as_talker(primary_address, secondary_address);
		end gpib_address_as_talker;

		procedure test_addressing is
		begin

			-- set primary address
			primary_address := 5;
			secondary_address := to_integer(unsigned(NO_ADDRESS_CONFIGURED));
			host_write_8(7 downto 5) := "000";
			host_write_8(4 downto 0) := std_logic_vector(to_unsigned(primary_address, 5));
			host_write("0000110", host_write_8); --address register 0/1
			host_write("0000100", X"31"); -- address mode register, transmit/receive mode 0x3 address mode 1

			--address chip as talker
			gpib_address_as_talker;

			host_read("0000100", host_read_result_8); -- address status register
			assert host_read_result_8(1) = '1'; -- talker addressed
			assert host_read_result_8(2) = '0'; -- listener addressed

			-- make sure we don't pay attention to other addresses
			gpib_address_as_talker(17, to_integer(unsigned(NO_ADDRESS_CONFIGURED)));
			host_read("0000100", host_read_result_8); -- address status register
			assert host_read_result_8(1) = '0'; -- talker addressed
			assert host_read_result_8(2) = '0'; -- listener addressed
			
			-- turn on secondary addressing
			secondary_address := 10;
			host_write_8(7 downto 5) := "100";
			host_write_8(4 downto 0) := std_logic_vector(to_unsigned(secondary_address, 5));
			host_write("0000110", host_write_8); --address register 0/1
			host_write("0000100", X"32"); -- address mode register, transmit/receive mode 0x3 address mode 2

			gpib_address_as_listener;
			host_read("0000100", host_read_result_8); -- address status register
			assert host_read_result_8(1) = '0'; -- talker addressed
			assert host_read_result_8(2) = '1'; -- listener addressed

			-- make sure we don't pay attention to other addresses

			gpib_write("00111111", false); -- UNL
			
			gpib_address_as_listener(3, to_integer(unsigned(NO_ADDRESS_CONFIGURED)));
			host_read("0000100", host_read_result_8); -- address status register
			assert host_read_result_8(1) = '0'; -- talker addressed
			assert host_read_result_8(2) = '0'; -- listener addressed

			gpib_address_as_listener(primary_address, to_integer(unsigned(NO_ADDRESS_CONFIGURED)));
			host_read("0000100", host_read_result_8); -- address status register
			assert host_read_result_8(1) = '0'; -- talker addressed
			assert host_read_result_8(2) = '0'; -- listener addressed
			
			gpib_address_as_listener(primary_address, 18);
			host_read("0000100", host_read_result_8); -- address status register
			assert host_read_result_8(1) = '0'; -- talker addressed
			assert host_read_result_8(2) = '0'; -- listener addressed

			-- check secondary addressing works
			gpib_address_as_listener(primary_address, secondary_address);
			host_read("0000100", host_read_result_8); -- address status register
			assert host_read_result_8(1) = '0'; -- talker addressed
			assert host_read_result_8(2) = '1'; -- listener addressed
			
		end test_addressing;
		
		procedure test_device_clear is
		begin
			gpib_setup_bus(true, true);
			-- unlisten
			gpib_write_byte := "00111111";
			gpib_write(gpib_write_byte, false);
			
			-- enable DEC interrupts
			host_write("0000001", "00001000"); -- interrupt mask register 1
			host_read("0000001", host_read_result_8); -- read clear any pending interrupts
			assert interrupt = '0';

			-- send DCL
			gpib_write_byte := "00010100";
			gpib_write(gpib_write_byte, false);
			if interrupt /= '1' then
				wait until interrupt = '1';
			end if;
			host_read("0000001", host_read_result_8);
			assert host_read_result_8(3) = '1';
			
			
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
			host_read("0000001", host_read_result_8);
			assert host_read_result_8(3) = '1';

			host_write("0000001", "00000000"); -- interrupt mask register 1
		end test_device_clear;
		
		procedure test_device_trigger is
		begin
			gpib_setup_bus(true, true);
			-- unlisten
			gpib_write_byte := "00111111";
			gpib_write(gpib_write_byte, false);
			
			-- enable DET interrupts
			host_write("0000001", "00100000"); -- interrupt mask register 1
			host_read("0000001", host_read_result_8); -- read clear any pending interrupts
			assert interrupt = '0';

			-- send GET, this should produce no effect since chip is not listener
			gpib_write_byte := "00001000";
			gpib_write(gpib_write_byte, false);
			wait_for_ticks(3);
			assert interrupt = '0';

			-- address as listener then do GET, this should produce device trigger interrupt
			gpib_address_as_listener;
			
			gpib_write_byte := "00001000";
			gpib_write(gpib_write_byte, false);
			
			-- make sure we got a device trigger interrupt
			if interrupt /= '1' then
				wait until interrupt = '1';
			end if;
			host_read("0000001", host_read_result_8);
			assert host_read_result_8(5) = '1';

			host_write("0000001", "00000000"); -- interrupt mask register 1
		end test_device_trigger;

		procedure test_remote_local is
		begin
		
			-- unassert REN, should put us into LOCS
			bus_REN_inverted <= '1';
			wait_for_ticks(2);
			-- enable REMC and LOKC interrupts
			host_write("0000010", "00000110"); -- interrupt mask register 2
			host_read("0000010", host_read_result_8); -- interrupt status 2
			assert host_read_result_8(4) = '0'; -- REM bit
			assert host_read_result_8(5) = '0'; -- LOK bit

			bus_REN_inverted <= '0';
			gpib_address_as_listener;
			if interrupt /= '1' then
				wait until interrupt = '1';
			end if;
			host_read("0000010", host_read_result_8); -- interrupt status 2
			assert host_read_result_8(1) = '1'; -- REMC bit
			assert host_read_result_8(2) = '0'; -- LOKC bit
			assert host_read_result_8(4) = '1'; -- REM bit
			assert host_read_result_8(5) = '0'; -- LOK bit
			assert interrupt = '0';
			
			-- send local lockout
			gpib_write_byte := "00010001";
			gpib_write(gpib_write_byte, false);
			if interrupt /= '1' then
				wait until interrupt = '1';
			end if;
			host_read("0000010", host_read_result_8); -- interrupt status 2
			assert host_read_result_8(1) = '0'; -- REMC bit
			assert host_read_result_8(2) = '1'; -- LOKC bit
			assert host_read_result_8(4) = '1'; -- REM bit
			assert host_read_result_8(5) = '1'; -- LOK bit
			assert interrupt = '0';
			
			host_write("0000010", "00000000"); -- interrupt mask register 2
			bus_REN_inverted <= 'H';
		end test_remote_local;
		
		procedure test_address_status_change is
		begin
			gpib_setup_bus(true, true);
			-- unlisten
			gpib_write_byte := "00111111";
			gpib_write(gpib_write_byte, false);
		
			-- untalk
			gpib_write_byte := "01011111";
			gpib_write(gpib_write_byte, false);
			
			--enable ADSC interrupt
			host_write("0000010", "00000001"); -- interrupt mask register 2
			host_read("0000010", host_read_result_8); -- interrupt status 2
			assert interrupt = '0';
			
			gpib_address_as_talker;
			
			if interrupt /= '1' then
				wait until interrupt = '1';
			end if;
			host_read("0000010", host_read_result_8); -- interrupt status 2
			assert host_read_result_8(0) = '1'; -- ADSC bit
			host_read("0000100", host_read_result_8); -- address status register
			assert host_read_result_8(1) = '1'; -- talker addressed
			assert host_read_result_8(2) = '0'; -- listener addressed

			assert interrupt = '0';
			gpib_address_as_listener;
			if interrupt /= '1' then
				wait until interrupt = '1';
			end if;
			host_read("0000010", host_read_result_8); -- interrupt status 2
			assert host_read_result_8(0) = '1'; -- ADSC bit
			host_read("0000100", host_read_result_8); -- address status register
			assert host_read_result_8(1) = '0'; -- talker addressed
			assert host_read_result_8(2) = '1'; -- listener addressed
			
		end test_address_status_change;
		
		procedure test_interrupt_register_0 is
		begin
			bus_ATN_inverted <= 'H';
			bus_IFC_inverted <= 'H';
			
			host_write("0000101", "01010001"); -- select register page 1
			host_write("0000110", "00001100"); -- write to imr 0, enable ATN and IFC interrupts
			
			host_write("0000101", "01010001"); -- select register page 1
			host_read("0000110", host_read_result_8); -- read clear imr 0
			
			wait_for_ticks(3);
			assert interrupt = '0';
			
			bus_ATN_inverted <= '0';
			wait until interrupt = '1';
			host_write("0000101", "01010001"); -- select register page 1
			host_read("0000110", host_read_result_8); -- read imr 0
			assert host_read_result_8(2) = '1';
			host_write("0000101", "01010001"); -- select register page 1
			host_read("0000110", host_read_result_8); -- read imr 0
			assert host_read_result_8(2) = '0'; -- should have cleared due to previous read
		
			wait_for_ticks(3);
			assert interrupt = '0';

			bus_ATN_inverted <= 'H';
			bus_IFC_inverted <= '0';
			wait until interrupt = '1';
			host_write("0000101", "01010001"); -- select register page 1
			host_read("0000110", host_read_result_8); -- read imr 0
			assert host_read_result_8(3) = '1';
			host_write("0000101", "01010001"); -- select register page 1
			host_read("0000110", host_read_result_8); -- read imr 0
			assert host_read_result_8(3) = '0'; -- should have cleared due to previous read
			
			host_write("0000101", "01010001"); -- select register page 1
			host_write("0000110", "00000000"); -- write to imr 0, disable ATN and IFC interrupts
			bus_IFC_inverted <= 'H';
		end test_interrupt_register_0;
		
		procedure test_serial_poll is
		begin

			-- configure serial poll response
			host_write("0000011", "11010010");
			wait_for_ticks(5);
			assert to_X01(bus_SRQ_inverted) = '0';
			
			gpib_address_as_talker;
			gpib_write("00011000", false); -- SPE

			-- read serial poll byte
			gpib_setup_bus(false, false);
			gpib_read(gpib_read_result, gpib_read_eoi);
			assert gpib_read_result = "11010010";
			
			gpib_setup_bus(true, true);
			gpib_write("00011001", false); -- SPD

			gpib_setup_bus(false, true);
			
			host_read("0000011", host_read_result_8);
			assert host_read_result_8 = "10010010"; -- "pending" bit should have cleared after serial poll

			host_write("0000011", "10010010");
			wait_for_ticks(2);
			assert to_X01(bus_SRQ_inverted) = '1';

		end test_serial_poll;
		
		procedure test_parallel_poll is
		begin
			
			-- remote parallel poll mode
			host_write("0000101", "11100000"); -- aux reg I, remote mode 
			host_write("0000101", "10100000"); -- don't use SRQ as ist, use parallel poll flag (bit 4)
			host_write("0000101", "00001001"); -- set parallel poll flag to 1

			-- remotely configure parallel poll
			gpib_address_as_listener;
			gpib_write("00000101", false); -- PPC
			gpib_write("01101101", false); -- PPE, sense 1, line 5
			
			-- do parallel poll
			bus_ATN_inverted <= '0';
			bus_EOI_inverted <= '0';
			wait for 2us;
			assert not bus_DIO_inverted = "00100000";
			
			bus_ATN_inverted <= 'H';
			bus_EOI_inverted <= 'H';
			wait_for_ticks(1);
			
			-- remotely deconfigure parallel poll
			gpib_address_as_listener;
			gpib_write("00000101", false); -- PPC
			gpib_write("01110000", false); -- PPD

			-- do parallel poll
			bus_ATN_inverted <= '0';
			bus_EOI_inverted <= '0';
			wait for 2us;
			assert not bus_DIO_inverted = "00000000";

			bus_ATN_inverted <= 'H';
			bus_EOI_inverted <= 'H';
			wait_for_ticks(1);
			
			-- local parallel poll mode
			host_write("0000101", "01100111"); -- local mode enabled, sense 0, line 7 
			host_write("0000101", "11100100"); -- aux reg I, local mode 
			host_write("0000101", "10100000"); -- don't use SRQ as ist, use parallel poll flag (bit 4)
			host_write("0000101", "00000001"); -- set parallel poll flag to 0
			
			-- do parallel poll
			bus_ATN_inverted <= '0';
			bus_EOI_inverted <= '0';
			wait for 2us;
			assert not bus_DIO_inverted = "10000000";
			
			bus_ATN_inverted <= 'H';
			bus_EOI_inverted <= 'H';
			wait_for_ticks(1);

			-- disable parallel poll 
			host_write("0000101", "01110000"); -- local mode disabled
			host_write("0000101", "11100100"); -- aux reg I, local mode 
			host_write("0000101", "10100000"); -- don't use SRQ as ist, use parallel poll flag (bit 4)
			host_write("0000101", "00000001"); -- set parallel poll flag to 0
			
			-- do parallel poll
			bus_ATN_inverted <= '0';
			bus_EOI_inverted <= '0';
			wait for 2us;
			assert not bus_DIO_inverted = "00000000";
			
			bus_ATN_inverted <= 'H';
			bus_EOI_inverted <= 'H';
			wait_for_ticks(1);
	end test_parallel_poll;
		
	procedure test_rfd_holdoff is
	begin
		host_write("0000010", "00010000"); -- imr2 register, dma input enable
		dma_write("01",X"0300"); -- fifo control, clear and enable gpib-to-host fifo dma requests
		
		gpib_address_as_listener;
		gpib_setup_bus(false, true);
		
		host_write("0000101", "10000000");  -- Aux A register, normal handshake
				
		dma_write("10", X"0004"); -- transfer count
		gpib_write(X"01", false);
		
		if to_X01(dma_single) /= '1' then
			wait until to_X01(dma_single) = '1';
		end if;
		-- NRFD should clear since the dma fifos will automatically
		-- read the data byte out of the gpib chip and we are in normal
		-- handshake mode
		wait for 200ns;
		wait_for_ticks(2);
		assert to_X01(bus_NRFD_inverted) = '1';
		
		dma_read("00", host_read_result_16);
		assert host_read_result_16(7 downto 0) = X"01";
		assert to_X01(dma_single) = '0';
		
		host_write("0000101", "10000001");  -- Aux A register, holdoff on all
		
		gpib_write(X"02", false);
		
		if to_X01(dma_single) /= '1' then
			wait until to_X01(dma_single) = '1';
		end if;
		
		dma_read("00", host_read_result_16);
		assert host_read_result_16(7 downto 0) = X"02";
		wait_for_ticks(15);
		assert to_X01(bus_NRFD_inverted) = '0';
	
		host_write("0000101", "00000011"); -- release rfd holdoff
		wait_for_ticks(15);
		assert to_X01(bus_NRFD_inverted) = '1';

		
		host_write("0000101", "10000010");  -- Aux A register, holdoff on end

		gpib_write(X"03", false); -- byte without EOI asserted should not trigger holdoff
		
		if to_X01(dma_single) /= '1' then
			wait until to_X01(dma_single) = '1';
		end if;
		wait for 200ns;
		wait_for_ticks(2);
		assert to_X01(bus_NRFD_inverted) = '1';
		
		dma_read("00", host_read_result_16);
		assert host_read_result_16(7 downto 0) = X"03";
	
		gpib_write(X"04", true);  -- byte with EOI asserted should trigger holdoff
		
		if to_X01(dma_single) /= '1' then
			wait until to_X01(dma_single) = '1';
		end if;
		
		dma_read("00", host_read_result_16);
		assert host_read_result_16(7 downto 0) = X"04";
		wait_for_ticks(15);
		assert to_X01(bus_NRFD_inverted) = '0';

		host_write("0000101", "00000011"); -- release rfd holdoff
		wait_for_ticks(15);
		assert to_X01(bus_NRFD_inverted) = '1';

		
		host_write("0000101", "10000011");  -- Aux A register, continuous mode

		gpib_write(X"05", false); -- byte without EOI asserted should not trigger holdoff
		
		wait_for_ticks(15);
		assert to_X01(bus_NRFD_inverted) = '1';
	
		gpib_write(X"06", true);  -- byte with EOI asserted should trigger holdoff
		
		wait_for_ticks(15);
		assert to_X01(bus_NRFD_inverted) = '0';

		host_write("0000101", "00000011"); -- release rfd holdoff
		wait_for_ticks(15);
		assert to_X01(bus_NRFD_inverted) = '1';

		dma_write("01",X"0000"); -- fifo control, disable fifo requests
	end test_rfd_holdoff;
	
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
		avalon_chip_select_inverted <= '1';
		dma_ack <= '0';
		dma_fifos_data_in <= (others => 'Z');
		dma_fifos_data_out <= (others => 'Z');
		dma_fifos_address <= (others => 'Z');
		dma_fifos_read <= '0';
		dma_fifos_write <= '0';
		dma_fifos_chip_select <= '0';
		avalon_data_in <= (others => '0');
		avalon_data_out <= (others => 'Z');
		avalon_read_inverted <= '1';
		avalon_write_inverted <= '1';
		avalon_address <= ( others => '0' );
		gpib_disable <= '0';
		primary_address := 0;
		secondary_address := to_integer(unsigned(NO_ADDRESS_CONFIGURED));
		
		reset <= '1';
		wait until rising_edge(clock);	
		reset <= '0';
		wait until rising_edge(clock);	
		
		test_addressing;

		--address chip as talker
		gpib_address_as_talker;

		--send a data byte host to gpib

		gpib_setup_bus(false, false);
		-- enable DO interrupts
		host_write("0000001", "00000010"); -- interrupt mask register 1

		-- wait for DO interrupt
		if interrupt /= '1' then
			wait until interrupt = '1';
		end if;
		host_read("0000001", host_read_result_8);
		assert host_read_result_8(1) = '1';
		host_read("0000001", host_read_result_8);
		-- interrupt should clear on read
		assert host_read_result_8(1) = '0'; 
		assert interrupt = '0';
		
		host_write("0000000", X"01");
		wait until rising_edge(clock);	
		wait until rising_edge(clock);	
		gpib_read(gpib_read_result, gpib_read_eoi);
		wait until rising_edge(clock);	
		assert gpib_read_result = X"01";
		assert gpib_read_eoi = '0';
		
		--send a data byte host to gpib with EOI
		host_write("0000101", "00000110"); -- send eoi aux command
		host_write("0000000", X"02");
		wait until rising_edge(clock);	
		gpib_read(gpib_read_result, gpib_read_eoi);
		wait until rising_edge(clock);	
		assert gpib_read_result = X"02";
		assert gpib_read_eoi = '1';

		--send another data byte to make sure "send eoi" message clears
		host_write("0000000", X"03");
		wait until rising_edge(clock);	
		gpib_read(gpib_read_result, gpib_read_eoi);
		wait until rising_edge(clock);	
		assert gpib_read_result = X"03";
		assert gpib_read_eoi = '0';

		--address chip as listener
		gpib_address_as_listener;

		-- write some bytes from gpib to host
		gpib_setup_bus(false, true);

		-- enable DI and END interrupts
		host_write("0000001", "00010001"); -- interrupt mask register 1

		gpib_write_byte(7 downto 0) := X"10";
		gpib_write(gpib_write_byte, false);

		-- wait for DI interrupt
		if interrupt /= '1' then
			wait until interrupt = '1';
		end if;
		host_read("0000001", host_read_result_8);
		assert host_read_result_8(0) = '1';
		host_read("0000001", host_read_result_8);
		-- interrupt should clear on read
		assert host_read_result_8(0) = '0'; 
		assert interrupt = '0';
		-- read out data byte
		host_read("0000000", host_read_result_8);
		assert host_read_result_8 = X"10";
		
		--write a byte with EOI asserted
		gpib_write_byte(7 downto 0) := X"20";
		gpib_write(gpib_write_byte, true);
		-- check that we got END interrupt along with DI
		if interrupt /= '1' then
			wait until interrupt = '1';
		end if;
		host_read("0000001", host_read_result_8);
		assert host_read_result_8(0) = '1'; -- DI interrupt
		assert host_read_result_8(4) = '1'; -- END interrupt
		host_read("0000001", host_read_result_8);
		assert host_read_result_8(0) = '0'; -- DI interrupt
		assert host_read_result_8(4) = '0'; -- END interrupt
		-- read out data byte
		host_read("0000000", host_read_result_8);
		assert host_read_result_8 = X"20";

		-- write pon to aux command reg
		host_write("0000101", X"00");
		
		test_device_clear;
		
		test_device_trigger;

		test_remote_local;
		
		test_address_status_change;
		
		test_interrupt_register_0;
		
		test_serial_poll;
		
		test_parallel_poll;
		
		test_rfd_holdoff;
		
		wait until rising_edge(clock);	
		assert false report "end of test" severity note;
		test_finished := true;
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
