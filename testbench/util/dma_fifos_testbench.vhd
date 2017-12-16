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
	
	signal host_address : std_logic_vector(0 downto 0);
	signal host_chip_select : std_logic;
	signal host_read_sig : std_logic;
	signal host_write_sig : std_logic;
	signal host_data_in : std_logic_vector(7 downto 0);
	signal host_data_out : std_logic_vector(7 downto 0);

	signal dma_request : std_logic;
	signal request_xfer_to_device : std_logic;
	signal request_xfer_from_device : std_logic;
	
	signal device_chip_select : std_logic;
	signal device_read : std_logic;
	signal device_write : std_logic;
	signal device_data_in : std_logic_vector(7 downto 0);
	signal device_data_out : std_logic_vector(7 downto 0);

	constant num_address_lines : positive := 1;
	
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
			dma_request => dma_request,
			request_xfer_to_device => request_xfer_to_device,
			request_xfer_from_device => request_xfer_from_device,
			device_chip_select => device_chip_select,
			device_read => device_read,
			device_write => device_write,
			device_data_in => device_data_in,
			device_data_out => device_data_out
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
		variable host_read_result : std_logic_vector(7 downto 0);
		
		procedure host_write (addr: in std_logic_vector(num_address_lines - 1 downto 0);
			byte : in std_logic_vector(7 downto 0)) is
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
			result: out std_logic_vector(7 downto 0)) is
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
		
		-- enable host-to-gpib dma requests
		host_write("1", "00000001");
		
		-- write some data in response to dma requests
		for i in 0 to 9 loop
			if dma_request = '0' then
				wait until dma_request = '1';
			end if;
			host_write("0", std_logic_vector(to_unsigned(i, 8)));
		end loop;
		
		-- enable gpib-to-host dma requests
		host_write("1", "00010000");
		--read some data in response to dma requests
		for i in 16#10# to 16#19# loop
			if dma_request = '0' then
				wait until dma_request = '1';
			end if;
			wait_for_ticks(5); -- slow down response to let fifo gradually fill up
			host_read("0", host_read_result);
			assert host_read_result = std_logic_vector(to_unsigned(i, 8));
		end loop;

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
		
		wait until reset = '0';
		wait_for_ticks(1);
		
		-- make some dma requests for host to write data to us
		for i in 0 to 9 loop
			request_xfer_to_device <= '1';
			if device_chip_select = '0' or device_write = '0' then
				wait until device_chip_select = '1' and device_write = '1';
			end if;
			request_xfer_to_device <= '0';
			wait_for_ticks(6); -- slow down reads so host fills up fifo and has to wait
			assert device_data_out = std_logic_vector(to_unsigned(i, 8));
			if device_chip_select = '1' and device_write = '1' then
				wait until device_chip_select = '0' or device_write = '0';
			end if;
		end loop;

		-- make some dma requests for host to read data from us
		for i in 16#10# to 16#19# loop
			request_xfer_from_device <= '1';
			if device_chip_select = '0' or device_read = '0' then
				wait until device_chip_select = '1' and device_read = '1';
			end if;
			request_xfer_from_device <= '0';
			device_data_in <= std_logic_vector(to_unsigned(i, 8)); 
			if device_chip_select = '1' and device_read = '1' then
				wait until device_chip_select = '0' or device_read = '0';
			end if;
		end loop;

		assert false report "end of device process" severity note;
		device_process_finished := true;
		wait;
	end process;
end behav;

