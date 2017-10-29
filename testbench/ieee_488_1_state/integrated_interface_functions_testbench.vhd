-- testbench for integrated interface functions.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;
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
	signal gpib_to_host_byte : std_logic_vector(7 downto 0);
	signal gpib_to_host_byte_read : std_logic;
	signal gpib_to_host_byte_end : std_logic;
	signal gpib_to_host_byte_eos : std_logic;
	signal host_to_gpib_data_byte : std_logic_vector(7 downto 0);
	signal host_to_gpib_data_byte_end : std_logic;
	signal host_to_gpib_data_byte_write : std_logic;
	signal host_to_gpib_data_byte_latched : std_logic;
	
	signal ist : std_logic;
	signal lon : std_logic;	
	signal lpe : std_logic;
	signal lun : std_logic;
	signal ltn : std_logic;
	signal pon : std_logic;
	signal rdy : std_logic;
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
			gpib_to_host_byte_read => gpib_to_host_byte_read,
			first_T1_terminal_count => first_T1_terminal_count,
			T1_terminal_count => T1_terminal_count,
			no_listeners => no_listeners,
			gpib_to_host_byte => gpib_to_host_byte,
			gpib_to_host_byte_end => gpib_to_host_byte_end,
			gpib_to_host_byte_eos => gpib_to_host_byte_eos,
			rdy => rdy,
			host_to_gpib_data_byte => host_to_gpib_data_byte,
			host_to_gpib_data_byte_end => host_to_gpib_data_byte_end,
			host_to_gpib_data_byte_write => host_to_gpib_data_byte_write,
			host_to_gpib_data_byte_latched => host_to_gpib_data_byte_latched
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
					if (to_bit(bus_NRFD) /= '0' or to_bit(bus_NDAC) /= '1') then
							wait until (to_bit(bus_NRFD) = '0' and to_bit(bus_NDAC) = '1');
					end if;
					wait for 99ns;
					bus_DIO <= data_byte;
					if assert_eoi then
							bus_EOI <= '1';
					else 
						bus_EOI <= 'L';
					end if;
					wait for 499ns;
					bus_DAV <='1';
					if (to_bit(bus_NRFD) /= '1' or to_bit(bus_NDAC) /= '0') then
							wait until (to_bit(bus_NRFD) = '1' and to_bit(bus_NDAC) = '0');
					end if;
					wait for 99ns;
					bus_DAV <='L';
					bus_EOI <= 'L';
					bus_DIO <= "LLLLLLLL";
					if (to_bit(bus_NDAC) /= '0') then
							wait until (to_bit(bus_NDAC) = '0');
					end if;
					wait for 99ns;
			end procedure gpib_write;

			procedure gpib_read (data_byte : out integer;
					eoi : out boolean) is
			begin
					bus_NDAC <= '1';
					wait for 99ns;
					bus_NRFD <= 'L';
					if (to_bit(bus_DAV) /= '1') then
							wait until (to_bit(bus_DAV) = '1');
					end if;
					wait for 99ns;
					bus_NRFD <= '1';
					data_byte := to_integer(unsigned(bus_DIO));
					eoi := to_bit(bus_EOI) = '1';
					wait for 99ns;
					bus_NDAC <= 'L';
					if (to_bit(bus_DAV) /= '0') then
							wait until (to_bit(bus_DAV) = '0');
					end if;
					wait for 99ns;
					bus_NDAC <= '0';
					wait for 99ns;
			end procedure gpib_read;

		variable gpib_read_result : integer;
		variable gpib_read_eoi : boolean;
	
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
		gpib_to_host_byte_read <= '0';
		host_to_gpib_data_byte <= X"00";
		host_to_gpib_data_byte_end <= '0';
		host_to_gpib_data_byte_write <= '0'; 
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
		
		-- address device as listener
		configured_primary_address <= "00001";
		bus_ATN <= '1';
		gpib_write("00100001", false);

		-- try sending some data bytes gpib to host
		
		bus_ATN <= 'L';
		gpib_write(X"01", false);

		wait until rising_edge(clock);	
		assert rdy = '0';
		assert gpib_to_host_byte = X"01";
		assert gpib_to_host_byte_end = '0';
		assert gpib_to_host_byte_eos = '0';
		gpib_to_host_byte_read <= '1';
		wait until rising_edge(clock);	
		gpib_to_host_byte_read <= '0';
		wait until rising_edge(clock);	
		assert rdy = '1';

		gpib_write(X"00", false);
		wait until rising_edge(clock);	
		assert gpib_to_host_byte = X"00";
		assert gpib_to_host_byte_end = '0';
		assert gpib_to_host_byte_eos = '1';
		gpib_to_host_byte_read <= '1';
		wait until rising_edge(clock);	
		gpib_to_host_byte_read <= '0';
		wait until rising_edge(clock);	
		
		gpib_write(X"a8", true);
		wait until rising_edge(clock);	
		assert gpib_to_host_byte = X"a8";
		assert gpib_to_host_byte_end = '1';
		assert gpib_to_host_byte_eos = '0';
		gpib_to_host_byte_read <= '1';
		wait until rising_edge(clock);	
		gpib_to_host_byte_read <= '0';
		wait until rising_edge(clock);	
		
		-- address device as talker
		bus_ATN <= '1';
		gpib_write("01000001", false);

		-- try sending some data bytes host to gpib

		bus_ATN <= '0';

		wait until rising_edge(clock);	
		host_to_gpib_data_byte <= X"b3";
		host_to_gpib_data_byte_end <= '0';
		host_to_gpib_data_byte_write <= '1';
		wait until rising_edge(clock);	
		host_to_gpib_data_byte_write <= '0';
		
		gpib_read(gpib_read_result, gpib_read_eoi);
		assert gpib_read_result = 16#b3#;
		assert gpib_read_eoi = false;
		
		-- no try a sending a byte with end asserted
		wait until rising_edge(clock);	
		host_to_gpib_data_byte <= X"c4";
		host_to_gpib_data_byte_end <= '1';
		host_to_gpib_data_byte_write <= '1';
		wait until rising_edge(clock);	
		host_to_gpib_data_byte_write <= '0';
		wait until rising_edge(clock);	
		assert host_to_gpib_data_byte_latched = '1';
		
		gpib_read(gpib_read_result, gpib_read_eoi);
		assert gpib_read_result = 16#c4#;
		assert gpib_read_eoi = true;
		assert host_to_gpib_data_byte_latched = '0';

		wait until rising_edge(clock);	
		assert false report "end of test" severity note;
		test_finished := true;
		wait;
	end process;
end behav;
