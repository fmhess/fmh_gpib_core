-- fifo to accelerate dma transfers, sits between bus and gpib dma port.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.std_fifo;

entity dma_fifos is
	generic(
		fifo_depth : positive := 4
	);
	port(
		clock : in std_logic;
		reset : in std_logic;
		
		-- host bus port
		host_address : in std_logic_vector(0 downto 0);
		host_chip_select : in std_logic;
		host_read : in std_logic;
		host_write : in std_logic;
		host_data_in : in std_logic_vector(7 downto 0);
		host_data_out : out std_logic_vector(7 downto 0);

		host_to_gpib_dma_request : out std_logic;
		gpib_to_host_dma_request : out std_logic;
		request_xfer_to_device : in std_logic;
		request_xfer_from_device : in std_logic;
		
		device_chip_select : out std_logic;
		device_read : out std_logic;
		device_write : out std_logic;
		device_data_in : in std_logic_vector(7 downto 0);
		device_data_out : out std_logic_vector(7 downto 0)
	);
 
end dma_fifos;
 
architecture dma_fifos_arch of dma_fifos is
	constant num_address_lines : positive := 1;
	
	signal host_to_gpib_fifo_reset : std_logic;
	signal host_to_gpib_fifo_write_enable : std_logic;
	signal host_to_gpib_fifo_data_in : std_logic_vector(7 downto 0);
	signal host_to_gpib_fifo_data_out : std_logic_vector(7 downto 0);
	signal host_to_gpib_fifo_read_ack : std_logic;
	signal host_to_gpib_fifo_empty : std_logic;
	signal host_to_gpib_fifo_full : std_logic;
	
	signal gpib_to_host_fifo_reset : std_logic;
	signal gpib_to_host_fifo_write_enable : std_logic;
	signal gpib_to_host_fifo_read_ack : std_logic;
	signal gpib_to_host_fifo_empty : std_logic;
	signal gpib_to_host_fifo_full : std_logic;
	signal gpib_to_host_fifo_data_out : std_logic_vector(7 downto 0);

	signal host_write_pending : std_logic;
	signal host_read_pending : std_logic;
	signal xfer_to_device_pending : std_logic;
	type xfer_from_device_enum is (xfer_from_device_idle, xfer_from_device_active, xfer_from_device_waiting);
	signal xfer_from_device_state : xfer_from_device_enum;
	signal host_to_gpib_request_enable : std_logic;
	signal gpib_to_host_request_enable : std_logic;
begin

	host_to_gpib_fifo: entity work.std_fifo 
		generic map(
			FIFO_DEPTH => fifo_depth
		)
		port map (
			CLK => clock,
			RST => host_to_gpib_fifo_reset,
			WriteEn => host_to_gpib_fifo_write_enable,
			DataIn => host_to_gpib_fifo_data_in,
			ReadAck => host_to_gpib_fifo_read_ack,
			DataOut => host_to_gpib_fifo_data_out,
			Empty => host_to_gpib_fifo_empty,
			Full => host_to_gpib_fifo_full
		);

	gpib_to_host_fifo: entity work.std_fifo 
		generic map(
			FIFO_DEPTH => fifo_depth
		)
		port map (
			CLK => clock,
			RST => gpib_to_host_fifo_reset,
			WriteEn => gpib_to_host_fifo_write_enable,
			DataIn => device_data_in,
			ReadAck => gpib_to_host_fifo_read_ack,
			DataOut => gpib_to_host_fifo_data_out,
			Empty => gpib_to_host_fifo_empty,
			Full => gpib_to_host_fifo_full
		);
		
	-- process host reads and writes
	process(reset, clock)
		variable host_write_selected : std_logic;
		variable host_read_selected : std_logic;

		procedure handle_host_write(address : in std_logic_vector(num_address_lines - 1 downto 0); 
			data : in std_logic_vector(7 downto 0)) is
		begin
			case address is
				when "0" => -- push byte into host-to-gpib fifo
					host_to_gpib_fifo_data_in <= data;
					host_to_gpib_fifo_write_enable <= '1';
				when "1" => -- control register
					host_to_gpib_request_enable <= data(0);
					host_to_gpib_fifo_reset <= data(1);
					gpib_to_host_request_enable <= data(4);
					gpib_to_host_fifo_reset <= data(5);
				when others =>
			end case;
		end handle_host_write;

		procedure handle_host_read(address : in std_logic_vector(num_address_lines - 1 downto 0)) is
		begin
			case address is
				when "0" => -- pop byte from gpib-to-host fifo
					gpib_to_host_fifo_read_ack <= '1';
					host_data_out <= gpib_to_host_fifo_data_out;
				when "1" => -- host-to-gpib status register
					host_data_out <= (
						0 => host_to_gpib_fifo_empty,
						1 => host_to_gpib_fifo_full,
						4 => gpib_to_host_fifo_empty,
						5 => gpib_to_host_fifo_full,
						others => '0'
					);
				when others =>
			end case;
		end handle_host_read;
	begin
		if to_X01(reset) = '1' then
			host_to_gpib_fifo_reset <= '1';
			host_to_gpib_fifo_write_enable <= '0';
			host_to_gpib_request_enable <= '0';
			host_to_gpib_fifo_read_ack <= '0';
			host_to_gpib_fifo_data_in <= (others => '0');
			host_to_gpib_dma_request <= '0';
			host_data_out <= (others => '0');
			
			gpib_to_host_fifo_reset <= '1';
			gpib_to_host_fifo_read_ack <= '0';
			gpib_to_host_fifo_write_enable <= '0';
			gpib_to_host_request_enable <= '0';
			gpib_to_host_dma_request <= '0';
		
			device_chip_select <= '0';
			device_write <= '0';
			device_read <= '0';
			device_data_out <= (others => '0');
			
			host_write_pending <= '0';
			host_read_pending <= '0';
			xfer_to_device_pending <= '0';
			xfer_from_device_state <= xfer_from_device_idle;
		elsif rising_edge(clock) then

			-- host write state machine
			host_write_selected := host_chip_select and host_write ;
			if host_write_pending = '0' then
				if host_write_selected = '1' then
					host_write_pending <= '1';
					handle_host_write(host_address, host_data_in);
					host_to_gpib_dma_request <= '0';
				elsif host_to_gpib_request_enable = '1' and host_to_gpib_fifo_full = '0' then
					host_to_gpib_dma_request <= '1';
				end if;
			else -- host_write_pending = '1'
				if host_write_selected = '1' then
					host_write_pending <= '0';
				end if;
			end if;
			
			-- host read state machine
			host_read_selected := host_chip_select and host_read;
			if host_read_pending = '0' then
				if host_read_selected = '1' then
					host_read_pending <= '1';
					handle_host_read(host_address);
					gpib_to_host_dma_request <= '0';
				elsif (gpib_to_host_request_enable = '1' and gpib_to_host_fifo_empty = '0') then
					gpib_to_host_dma_request <= '1';
				end if;
			else -- host_read_pending = '1'
				if host_read_selected = '1' then
					host_read_pending <= '0';
				end if;
			end if;

			-- handle request for transfer to device
			if xfer_to_device_pending = '0' then
				if request_xfer_to_device = '1' and host_to_gpib_fifo_empty = '0' then
					xfer_to_device_pending <= '1';
					host_to_gpib_fifo_read_ack <= '1';
					device_data_out <= host_to_gpib_fifo_data_out;
					device_chip_select <= '1';
					device_write <= '1';
				end if;
			else -- xfer_to_device_pending = '1'
				host_to_gpib_fifo_read_ack <= '0';
				if request_xfer_to_device = '0' then
					device_chip_select <= '0';
					device_write <= '0';
					xfer_to_device_pending <= '0';
				end if;
			end if;
			
			-- handle request for transfer from device
			case xfer_from_device_state is
				when xfer_from_device_idle =>
					if request_xfer_from_device = '1' and gpib_to_host_fifo_full = '0' then
						xfer_from_device_state <= xfer_from_device_active;
						device_chip_select <= '1';
						device_read <= '1';
					end if;
				when xfer_from_device_active =>
					gpib_to_host_fifo_write_enable <= '1';
					xfer_from_device_state <= xfer_from_device_waiting;
				when xfer_from_device_waiting =>
					gpib_to_host_fifo_write_enable <= '0';
					device_chip_select <= '0';
					device_read <= '0';
					if request_xfer_from_device = '0' then
						xfer_from_device_state <= xfer_from_device_idle;
					end if;
			end case;

			-- clear fifo resets after they are set by hard or soft reset
			if host_to_gpib_fifo_reset = '1' then
				host_to_gpib_fifo_reset <= '0';
			end if;
			if gpib_to_host_fifo_reset = '1' then
				gpib_to_host_fifo_reset <= '0';
			end if;
			--clear various pulses
			if host_to_gpib_fifo_read_ack = '1' then
				host_to_gpib_fifo_read_ack <= '0';
			end if;
			if host_to_gpib_fifo_write_enable = '1' then
				host_to_gpib_fifo_write_enable <= '0';
			end if;
			if gpib_to_host_fifo_read_ack = '1' then
				gpib_to_host_fifo_read_ack <= '0';
			end if;
			if gpib_to_host_fifo_write_enable = '1' then
				gpib_to_host_fifo_write_enable <= '0';
			end if;
			
		end if;
	end process;
end dma_fifos_arch;
