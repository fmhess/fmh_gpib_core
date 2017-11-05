-- testbench for integrated interface functions.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;
use work.gpib_transceiver.all;
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
	signal dma_ack_inverted : std_logic;
	signal read_inverted : std_logic;
	signal reset : std_logic;
	signal address : std_logic_vector(2 downto 0);
	signal write_inverted : std_logic;
	signal tr1 : std_logic;
	signal tr2 : std_logic;
	signal tr3 : std_logic;
	signal interrupt : std_logic;
	signal dma_request : std_logic;
	signal host_data_bus : std_logic_vector(7 downto 0);
	signal pullup_disable : std_logic;
	signal talk_enable : std_logic;
	signal not_controller_in_charge : std_logic;
	signal system_controller : std_logic;
	
	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	begin
	my_frontend_cb7210p2: entity work.frontend_cb7210p2 
		port map (
			clock => clock,
			chip_select_inverted => chip_select_inverted, 
			dma_ack_inverted => dma_ack_inverted,
			read_inverted => read_inverted,
			reset => reset,
			address => address,  
			write_inverted => write_inverted, 
			tr1  => tr1,
			tr2  => tr2, 
			tr3  => tr3,
			interrupt  => interrupt, 
			dma_request  => dma_request, 
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
		-- wait wait for a condition with a hard coded timeout to avoid infinite test loops on failure
		procedure wait_for_ticks (num_clock_cycles : in integer) is
			begin
				for i in 1 to num_clock_cycles loop
					wait until rising_edge(clock);
				end loop;
			end procedure wait_for_ticks;

		-- write a byte from gpib bus to device
		procedure gpib_write (data_byte : in std_logic_vector(7 downto 0);
			assert_eoi : in boolean) is
			begin
					bus_NRFD_inverted <= 'Z';
					bus_NDAC_inverted <= 'Z';
					if (to_bit(bus_NRFD_inverted) /= '1' or to_bit(bus_NDAC_inverted) /= '0') then
							wait until (to_bit(bus_NRFD_inverted) = '1' and to_bit(bus_NDAC_inverted) = '0');
					end if;
					wait for 99ns;
					bus_DIO_inverted <= not data_byte;
					if assert_eoi then
							bus_EOI_inverted <= '0';
					else 
						bus_EOI_inverted <= 'H';
					end if;
					wait for 499ns;
					bus_DAV_inverted <='0';
					if (to_bit(bus_NRFD_inverted) /= '0' or to_bit(bus_NDAC_inverted) /= '1') then
							wait until (to_bit(bus_NRFD_inverted) = '0' and to_bit(bus_NDAC_inverted) = '1');
					end if;
					wait for 99ns;
					bus_DAV_inverted <='H';
					bus_EOI_inverted <= 'H';
					bus_DIO_inverted <= "HHHHHHHH";
					if (to_bit(bus_NDAC_inverted) /= '1') then
							wait until (to_bit(bus_NDAC_inverted) = '1');
					end if;
					wait for 99ns;
			end procedure gpib_write;

			procedure gpib_read (data_byte : out integer;
					eoi : out boolean) is
			begin
					bus_DAV_inverted <= 'Z';
					bus_NDAC_inverted <= '0';
					wait for 99ns;
					bus_NRFD_inverted <= 'H';
					if (to_bit(bus_DAV_inverted) /= '0') then
							wait until (to_bit(bus_DAV_inverted) = '0');
					end if;
					wait for 99ns;
					bus_NRFD_inverted <= '0';
					data_byte := to_integer(unsigned(not bus_DIO_inverted));
					eoi := to_bit(bus_EOI_inverted) = '0';
					wait for 99ns;
					bus_NDAC_inverted <= 'H';
					if (to_bit(bus_DAV_inverted) /= '1') then
							wait until (to_bit(bus_DAV_inverted) = '1');
					end if;
					wait for 99ns;
					bus_NDAC_inverted <= 'H';
					wait for 99ns;
			end procedure gpib_read;

		-- write a byte from host to device register
		procedure host_write (addr: in std_logic_vector(2 downto 0);
			byte : in std_logic_vector(7 downto 0)) is
			begin
				wait until rising_edge(clock);
				write_inverted <= '0';
				chip_select_inverted <= '0';
				address <= addr;
				host_data_bus <= byte;
				wait until rising_edge(clock);
				write_inverted <= '1';
				chip_select_inverted <= '1';
				address <= (others => '0');
				host_data_bus <= (others => '0');
				wait until rising_edge(clock);
			end procedure host_write;

		variable gpib_read_result : integer;
		variable gpib_read_eoi : boolean;
		variable temp_byte : std_logic_vector(7 downto 0);
	
		variable primary_address : integer;
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
		dma_ack_inverted <= '1';
		host_data_bus <= (others => '0');
		read_inverted <= '1';
		address <= ( others => '0' );
		
		wait until rising_edge(clock);	
		reset <= '1';
		wait until rising_edge(clock);	
		reset <= '0';
		wait until rising_edge(clock);	
		
		-- initialize chip

		host_write("100", X"31"); -- address mode register, transmit/receive mode 0x3 address mode 1

		-- set primary address
		primary_address := 5;
		temp_byte(7 downto 5) := "000";
		temp_byte(4 downto 0) := std_logic_vector(to_unsigned(primary_address, 5));
		host_write("110", temp_byte); --address register 0/1
		wait until rising_edge(clock);	

		--address chip as talker
		bus_ATN_inverted <= '0';
		temp_byte(7 downto 5) := "010";
		temp_byte(4 downto 0) := std_logic_vector(to_unsigned(primary_address, 5));
		gpib_write(temp_byte, false); -- MTA

		--send a data byte
		host_write("000", X"01");
		wait until rising_edge(clock);	
		bus_ATN_inverted <= 'H';
		wait until rising_edge(clock);	
		gpib_read(gpib_read_result, gpib_read_eoi);
		wait until rising_edge(clock);	
		assert gpib_read_result = 16#1# report "read result is " & integer'IMAGE(gpib_read_result);
		assert gpib_read_eoi = false;
		
		-- write pon to aux command reg
		host_write("101", X"00");
		
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
