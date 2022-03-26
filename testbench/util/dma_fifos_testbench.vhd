-- testbench for rx/tx fifo designed to sit between host bus and gpib chip's dma
-- port to accelerate dma transfers
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.test_common.all;
use work.dma_fifos;

entity dma_fifos_testbench is
end dma_fifos_testbench;
     
architecture behav of dma_fifos_testbench is
	signal clock : std_logic;
	signal reset : std_logic;
	
	signal host_address : std_logic_vector(1 downto 0);
	signal host_chip_select : std_logic;
	signal host_read_sig : std_logic;
	signal host_write_sig : std_logic;
	signal host_data_in : std_logic_vector(15 downto 0);
	signal host_data_out : std_logic_vector(15 downto 0);
	signal host_interrupt : std_logic;
	
	signal gpib_to_host_dma_single_request : std_logic;
	signal gpib_to_host_dma_burst_request : std_logic;
	signal host_to_gpib_dma_single_request : std_logic;
	signal host_to_gpib_dma_burst_request : std_logic;
	signal request_xfer_to_device : std_logic;
	signal request_xfer_from_device : std_logic;
	
	signal device_chip_select : std_logic;
	signal device_read : std_logic;
	signal device_write : std_logic;
	signal device_data_in : std_logic_vector(7 downto 0);
	signal device_data_end_in : std_logic;
	signal device_data_out : std_logic_vector(7 downto 0);
	signal device_data_eoi_out : std_logic;

	constant num_address_lines : positive := 2;
	
	constant clock_half_period : time := 10 ns;
	shared variable host_process_finished : boolean := false;
	shared variable device_process_finished : boolean := false;

	procedure wait_for_ticks (num_clock_cycles : in integer) is
	begin
		wait_for_ticks(num_clock_cycles, clock);
	end procedure wait_for_ticks;
begin
	my_dma_fifos : entity work.dma_fifos
		generic map(
			fifo_depth => 4
		)
		port map(
			clock => clock,
			reset => reset,
			host_address => host_address,
			host_chip_select => host_chip_select,
			host_read => host_read_sig,
			host_write => host_write_sig,
			host_data_in => host_data_in,
			host_data_out => host_data_out,
			host_interrupt => host_interrupt,
			host_to_gpib_dma_single_request => host_to_gpib_dma_single_request,
			host_to_gpib_dma_burst_request => host_to_gpib_dma_burst_request,
			gpib_to_host_dma_single_request => gpib_to_host_dma_single_request,
			gpib_to_host_dma_burst_request => gpib_to_host_dma_burst_request,
			request_xfer_to_device => request_xfer_to_device,
			request_xfer_from_device => request_xfer_from_device,
			device_chip_select => device_chip_select,
			device_read => device_read,
			device_write => device_write,
			device_data_in => device_data_in,
			device_data_end_in => device_data_end_in,
			device_data_out => device_data_out,
			device_data_eoi_out => device_data_eoi_out
		);

	-- clock
	process
	begin
		if(host_process_finished and device_process_finished) then
			wait;
		end if;
		
		clock <= '0';
		wait for clock_half_period;
		clock <= '1';
		wait for clock_half_period;
	end process;

	-- reset
	process
	begin
		reset <= '1';
		wait_for_ticks(1);
		reset <= '0';
		wait;
	end process;

	-- host
	process
		variable host_read_result : std_logic_vector(15 downto 0);
		
		procedure host_write (addr: in std_logic_vector(num_address_lines - 1 downto 0);
			byte : in std_logic_vector(15 downto 0)) is
		begin
			host_write (addr, byte,
				clock,
				host_chip_select,
				host_address,
				host_write_sig,
				host_data_in,
				'0'
			);
		end procedure host_write;

		procedure host_read (addr: in std_logic_vector(num_address_lines - 1 downto 0);
			result: out std_logic_vector(15 downto 0)) is
		begin
			host_read (addr, result,
				clock,
				host_chip_select,
				host_address,
				host_read_sig,
				host_data_out,
				'0'
			);
		end procedure host_read;
	begin
		host_address <= (others => '0');
		host_chip_select <= '0';
		host_read_sig <= '0';
		host_write_sig <= '0';
		host_data_in <= (others => '0');

		wait until reset = '0';
		wait_for_ticks(1);
		
		-- enable host-to-gpib dma requests and fifo half empty interrupt
		host_write("01", "0000000000001001");
		-- init xfer count
		host_write("10", std_logic_vector(to_unsigned(16#21#, 16)));
		
		-- host-to-gpib fast write slow reads tests fifo full behavior
		for i in 16#0# to 16#f# loop
			if host_to_gpib_dma_single_request = '0' then
				wait until host_to_gpib_dma_single_request = '1';
			end if;
			wait_for_ticks(1);
			host_write("00", std_logic_vector(to_unsigned(i, 16)));
		end loop;
		
		-- host-to-gpib slow write fast reads tests fifo empty behavior
		for i in 16#10# to 16#1f# loop
			if host_to_gpib_dma_single_request = '0' then
				wait until host_to_gpib_dma_single_request = '1';
			end if;
			wait_for_ticks(5);
			host_write("00", std_logic_vector(to_unsigned(i, 16)));
		end loop;

		-- host_to_gpib test eoi
		if host_to_gpib_dma_single_request = '0' then
			wait until host_to_gpib_dma_single_request = '1';
		end if;
		wait_for_ticks(1);
		host_write("00", std_logic_vector(to_unsigned(16#140#, 16)));


		-- enable gpib-to-host dma requests and fifo half full interrupt
		host_write("01", "0000100100000000");
		-- init xfer count
		host_write("10", std_logic_vector(to_unsigned(16#21#, 16)));

		-- gpib-to-host fast write slow read tests fifo full behavior
		for i in 16#20# to 16#2f# loop
			if gpib_to_host_dma_single_request = '0' then
				wait until gpib_to_host_dma_single_request = '1';
			end if;
			wait_for_ticks(5); -- slow down response to let fifo gradually fill up
			host_read("00", host_read_result);
			assert host_read_result = std_logic_vector(to_unsigned(i, 16));
		end loop;

		-- gpib-to-host slow write fast read tests fifo empty behavior
		for i in 16#30# to 16#3f# loop
			if gpib_to_host_dma_single_request = '0' then
				wait until gpib_to_host_dma_single_request = '1';
			end if;
			wait_for_ticks(1);
			host_read("00", host_read_result);
			assert host_read_result = std_logic_vector(to_unsigned(i, 16));
		end loop;

		-- gpib-to-host test end
		host_write("10", std_logic_vector(to_unsigned(16#1#, 16)));
		if gpib_to_host_dma_single_request = '0' then
			wait until gpib_to_host_dma_single_request = '1';
		end if;
		wait_for_ticks(1);
		host_read("00", host_read_result);
		assert host_read_result = std_logic_vector(to_unsigned(16#141#, 16));

		wait_for_ticks(1);
		assert false report "end of host process" severity note;
		host_process_finished := true;
		wait;
	end process;

	-- device
	process
	begin
		request_xfer_to_device <= '0';
		request_xfer_from_device <= '0';
		device_data_in <= (others => '0');
		device_data_end_in <= '0';
		
		wait until reset = '0';
		wait_for_ticks(1);
		
		-- host-to-gpib fast write slow reads to test fifo full behavior
		for i in 16#0# to 16#f# loop
			request_xfer_to_device <= '1';
			if device_chip_select = '0' or device_write = '0' then
				wait until device_chip_select = '1' and device_write = '1';
			end if;
			wait_for_ticks(1);
			request_xfer_to_device <= '0';
			wait_for_ticks(6); -- slow down reads so host fills up fifo and has to wait
			assert device_data_out = std_logic_vector(to_unsigned(i, 8));
			assert device_data_eoi_out = '0';
			if device_chip_select = '1' and device_write = '1' then
				wait until device_chip_select = '0' or device_write = '0';
			end if;
			wait_for_ticks(1);
		end loop;

		-- host-to-gpib slow write fast reads to test fifo empty behavior
		for i in 16#10# to 16#1f# loop
			request_xfer_to_device <= '1';
			if device_chip_select = '0' or device_write = '0' then
				wait until device_chip_select = '1' and device_write = '1';
			end if;
			wait_for_ticks(1);
			request_xfer_to_device <= '0';
			assert device_data_out = std_logic_vector(to_unsigned(i, 8));
			assert device_data_eoi_out = '0';
			if device_chip_select = '1' and device_write = '1' then
				wait until device_chip_select = '0' or device_write = '0';
			end if;
			wait_for_ticks(1);
		end loop;

		-- host_to_gpib test eoi
		request_xfer_to_device <= '1';
		if device_chip_select = '0' or device_write = '0' then
			wait until device_chip_select = '1' and device_write = '1';
		end if;
		wait_for_ticks(1);
		request_xfer_to_device <= '0';
		assert device_data_out = std_logic_vector(to_unsigned(16#40#, 8));
		assert device_data_eoi_out = '1';
		if device_chip_select = '1' and device_write = '1' then
			wait until device_chip_select = '0' or device_write = '0';
		end if;
		wait_for_ticks(1);

		-- gpib-to-host fast write slow reads to test fifo full behavior
		for i in 16#20# to 16#2f# loop
			request_xfer_from_device <= '1';
			if device_chip_select = '0' or device_read = '0' then
				wait until device_chip_select = '1' and device_read = '1';
			end if;
			wait_for_ticks(1);
			request_xfer_from_device <= '0';
			device_data_in <= std_logic_vector(to_unsigned(i, 8));
			device_data_end_in <= '0';
			if device_chip_select = '1' and device_read = '1' then
				wait until device_chip_select = '0' or device_read = '0';
			end if;
			wait_for_ticks(1);
		end loop;

		-- gpib-to-host slow write fast reads to test fifo full behavior
		for i in 16#30# to 16#3f# loop
			request_xfer_from_device <= '1';
			if device_chip_select = '0' or device_read = '0' then
				wait until device_chip_select = '1' and device_read = '1';
			end if;
			wait_for_ticks(1);
			request_xfer_from_device <= '0';
			device_data_in <= std_logic_vector(to_unsigned(i, 8)); 
			device_data_end_in <= '0';
			if device_chip_select = '1' and device_read = '1' then
				wait until device_chip_select = '0' or device_read = '0';
			end if;
			wait_for_ticks(1);
		end loop;

		-- gpib-to-host test end
		request_xfer_from_device <= '1';
		if device_chip_select = '0' or device_read = '0' then
			wait until device_chip_select = '1' and device_read = '1';
		end if;
		wait_for_ticks(1);
		request_xfer_from_device <= '0';
		device_data_in <= std_logic_vector(to_unsigned(16#41#, 8)); 
		device_data_end_in <= '1';
		if device_chip_select = '1' and device_read = '1' then
			wait until device_chip_select = '0' or device_read = '0';
		end if;
		wait_for_ticks(1);
		
		assert false report "end of device process" severity note;
		device_process_finished := true;
		wait;
	end process;
end behav;

