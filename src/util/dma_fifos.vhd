-- Copyright 2017 Frank Mori Hess fmh6jj@gmail.com

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--    http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
------------------------------------------------------------------------------

-- fifo to accelerate transfers between bus and gpib dma port.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.std_fifo;

entity dma_fifos is
	generic(
		fifo_depth : positive := 32
	);
	port(
		clock : in std_logic;
		reset : in std_logic;
		
		-- host bus port
		host_address : in std_logic_vector(1 downto 0);
		host_chip_select : in std_logic;
		host_read : in std_logic;
		host_write : in std_logic;
		host_data_in : in std_logic_vector(15 downto 0);
		host_data_out : out std_logic_vector(15 downto 0);
		-- optional byteenable allows safe 8 bit writes to address 0
		host_byteenable : in std_logic_vector(1 downto 0) := (others => '1');

		host_interrupt : out std_logic;
		
		host_to_gpib_dma_single_request : out std_logic;
		host_to_gpib_dma_burst_request : out std_logic;
		gpib_to_host_dma_single_request : out std_logic;
		gpib_to_host_dma_burst_request : out std_logic;
		request_xfer_to_device : in std_logic;
		request_xfer_from_device : in std_logic;
		
		device_chip_select : out std_logic;
		device_read : out std_logic;
		device_write : out std_logic;
		device_data_in : in std_logic_vector(7 downto 0);
		device_data_end_in : in std_logic;
		device_data_out : out std_logic_vector(7 downto 0);
		device_data_eoi_out : out std_logic;

		-- xfer_countdown outputs how many elements are left to transfer
		-- between the fifo and device.  It is used to generate a
		-- 488.1 lni message when a gpib-to-host transfer nears completion.
		xfer_countdown : out unsigned(11 downto 0)
	);
 
end dma_fifos;
 
architecture dma_fifos_arch of dma_fifos is
	constant num_address_lines : positive := 2;
	constant half_fifo_depth : positive := fifo_depth / 2;
	constant fifo_data_width : positive := 9;
	
	signal host_to_gpib_fifo_reset : std_logic;
	signal host_to_gpib_fifo_write_enable : std_logic;
	signal host_to_gpib_fifo_data_in : std_logic_vector(fifo_data_width - 1 downto 0);
	signal host_to_gpib_fifo_data_out : std_logic_vector(fifo_data_width - 1 downto 0);
	signal host_to_gpib_fifo_read_ack : std_logic;
	signal host_to_gpib_fifo_empty : std_logic;
	signal host_to_gpib_fifo_half_empty : std_logic;
	signal host_to_gpib_fifo_half_empty_interrupt_enable : std_logic;
	signal host_to_gpib_fifo_full : std_logic;
	signal host_to_gpib_fifo_contents : natural range 0 to fifo_depth;
	
	signal gpib_to_host_fifo_reset : std_logic;
	signal gpib_to_host_fifo_write_enable : std_logic;
	signal gpib_to_host_fifo_read_ack : std_logic;
	signal gpib_to_host_fifo_empty : std_logic;
	signal gpib_to_host_fifo_half_full : std_logic;
	signal gpib_to_host_fifo_half_full_interrupt_enable : std_logic;
	signal gpib_to_host_fifo_full : std_logic;
	signal gpib_to_host_fifo_contents : natural range 0 to fifo_depth;
	signal gpib_to_host_fifo_data_in : std_logic_vector(fifo_data_width - 1 downto 0);
	signal gpib_to_host_fifo_data_out : std_logic_vector(fifo_data_width - 1 downto 0);

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
			DATA_WIDTH => fifo_data_width,
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
			Full => host_to_gpib_fifo_full,
			Contents => host_to_gpib_fifo_contents
		);

	gpib_to_host_fifo: entity work.std_fifo 
		generic map(
			DATA_WIDTH => fifo_data_width,
			FIFO_DEPTH => fifo_depth
		)
		port map (
			CLK => clock,
			RST => gpib_to_host_fifo_reset,
			WriteEn => gpib_to_host_fifo_write_enable,
			DataIn => gpib_to_host_fifo_data_in,
			ReadAck => gpib_to_host_fifo_read_ack,
			DataOut => gpib_to_host_fifo_data_out,
			Empty => gpib_to_host_fifo_empty,
			Full => gpib_to_host_fifo_full,
			Contents => gpib_to_host_fifo_contents
		);
		
	gpib_to_host_fifo_data_in(7 downto 0) <= device_data_in;
	gpib_to_host_fifo_data_in(8) <= device_data_end_in;

	
	gpib_to_host_dma_burst_request <= gpib_to_host_fifo_half_full and gpib_to_host_request_enable;

	host_to_gpib_dma_burst_request <= host_to_gpib_fifo_half_empty and host_to_gpib_request_enable;
	
	host_interrupt <= (gpib_to_host_fifo_half_full_interrupt_enable and gpib_to_host_fifo_half_full) or
		(host_to_gpib_fifo_half_empty_interrupt_enable and host_to_gpib_fifo_half_empty);
		
	-- process host reads and writes
	process(reset, clock)
		variable host_write_selected : std_logic;
		variable host_read_selected : std_logic;
		variable xfer_count_var: unsigned (11 downto 0); -- Count of bytes in/out on the device side

		procedure handle_host_write(address : in std_logic_vector(num_address_lines - 1 downto 0); 
			data : in std_logic_vector(15 downto 0); byteenable : in std_logic_vector(1 downto 0)) is
		begin
			case address is
				when "00" => -- push byte into host-to-gpib fifo
					if to_X01(byteenable(0)) = '1' then
						host_to_gpib_fifo_data_in(7 downto 0) <= data(7 downto 0);
					else
						host_to_gpib_fifo_data_in(7 downto 0) <= (others => '0');
					end if;

					if to_X01(byteenable(1)) = '1' then
						host_to_gpib_fifo_data_in(fifo_data_width - 1 downto 8) <= data(fifo_data_width - 1 downto 8);
					else
						host_to_gpib_fifo_data_in(fifo_data_width - 1 downto 8) <= (others => '0');
					end if;
					
					host_to_gpib_fifo_write_enable <= '1';

					-- immediately clear dma requests taking into account a byte is currently being pushed into the fifo
					if host_to_gpib_fifo_contents >= fifo_depth - 1 then
						host_to_gpib_dma_single_request <= '0';
					end if;
					if host_to_gpib_fifo_contents >= half_fifo_depth then
						host_to_gpib_fifo_half_empty <= '0';
					end if;
				when "01" => -- control register
					if to_X01(byteenable(0)) = '1' then
						host_to_gpib_request_enable <= data(0);
						host_to_gpib_fifo_reset <= data(1);
						host_to_gpib_fifo_half_empty_interrupt_enable <= data(2);
					end if;
					if to_X01(byteenable(1)) = '1' then
						gpib_to_host_request_enable <= data(8);
						gpib_to_host_fifo_reset <= data(9);
						gpib_to_host_fifo_half_full_interrupt_enable <= data(10);
					end if;
				when "10" =>
					xfer_count_var := unsigned(data(11 downto 0));
				when others =>
			end case;
		end handle_host_write;

		procedure handle_host_read(address : in std_logic_vector(num_address_lines - 1 downto 0)) is
		begin
			case address is
				when "00" => -- pop byte from gpib-to-host fifo
					host_data_out(15 downto fifo_data_width) <= (others => '0');
					host_data_out(fifo_data_width - 1 downto 0) <= gpib_to_host_fifo_data_out;
					gpib_to_host_fifo_read_ack <= '1';
					
					-- immediately clear dma requests taking into account a byte is currently being popped out of the fifo
					if gpib_to_host_fifo_contents <= 1 then
						gpib_to_host_dma_single_request <= '0';
					end if;
					if gpib_to_host_fifo_contents <= half_fifo_depth then
						gpib_to_host_fifo_half_full <= '0';
					end if;
				when "01" => -- host-to-gpib status register
					host_data_out <= (
						0 => host_to_gpib_fifo_empty,
						1 => host_to_gpib_fifo_full,
						2 => host_to_gpib_fifo_half_empty,
						8 => gpib_to_host_fifo_empty,
						9 => gpib_to_host_fifo_full,
						10 => gpib_to_host_fifo_half_full,
						others => '0'
					);
				when "10" =>
					host_data_out(15 downto 12) <= (others => '0');
					host_data_out(11 downto 0) <= std_logic_vector(xfer_count_var);
				when "11" =>
					host_data_out(15 downto 8) <= (others => '0');
					host_data_out(7 downto 0) <= std_logic_vector(to_unsigned(half_fifo_depth, 8));
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
			host_to_gpib_dma_single_request <= '0';
			host_to_gpib_fifo_half_empty <= '0';
			host_to_gpib_fifo_half_empty_interrupt_enable <= '0';
			host_data_out <= (others => '0');
			
			gpib_to_host_fifo_reset <= '1';
			gpib_to_host_fifo_read_ack <= '0';
			gpib_to_host_fifo_write_enable <= '0';
			gpib_to_host_request_enable <= '0';
			gpib_to_host_dma_single_request <= '0';
			gpib_to_host_fifo_half_full <= '0';
			gpib_to_host_fifo_half_full_interrupt_enable <= '0';
		
			device_chip_select <= '0';
			device_write <= '0';
			device_read <= '0';
			device_data_out <= (others => '0');
			device_data_eoi_out <= '0';
			
			host_write_pending <= '0';
			host_read_pending <= '0';
			xfer_to_device_pending <= '0';
			xfer_from_device_state <= xfer_from_device_idle;
			xfer_count_var := (others => '0');
			xfer_countdown <= (others => '0');
		elsif rising_edge(clock) then
			-- host write state machine
			host_write_selected := host_chip_select and host_write ;
			if host_write_pending = '0' then
				if host_write_selected = '1' then
					host_write_pending <= '1';
					handle_host_write(host_address, host_data_in, host_byteenable);
				else
					host_to_gpib_dma_single_request <= host_to_gpib_request_enable and not host_to_gpib_fifo_full;
					if host_to_gpib_fifo_contents <= half_fifo_depth then
						host_to_gpib_fifo_half_empty <= '1';
					else 
						host_to_gpib_fifo_half_empty <= '0';
					end if;
				end if;
			else -- host_write_pending = '1'
				if host_write_selected = '0' then
					host_write_pending <= '0';
				end if;
			end if;
			
			-- host read state machine
			host_read_selected := host_chip_select and host_read;
			if host_read_pending = '0' then
				if host_read_selected = '1' then
					host_read_pending <= '1';
					handle_host_read(host_address);
				else
					gpib_to_host_dma_single_request <= gpib_to_host_request_enable and not gpib_to_host_fifo_empty;
					if gpib_to_host_fifo_contents >= half_fifo_depth then
						gpib_to_host_fifo_half_full <= '1';
					else
						gpib_to_host_fifo_half_full <= '0';
					end if;
				end if;
			else -- host_read_pending = '1'
				if host_read_selected = '0' then
					host_read_pending <= '0';
				end if;
			end if;

			-- handle request for transfer to device
			if xfer_to_device_pending = '0' then
				if to_X01(request_xfer_to_device) = '1' and host_to_gpib_fifo_empty = '0' and
					xfer_count_var > 0 then
					xfer_to_device_pending <= '1';
					host_to_gpib_fifo_read_ack <= '1';
					device_data_out <= host_to_gpib_fifo_data_out(7 downto 0);
					device_data_eoi_out <= host_to_gpib_fifo_data_out(8);
					device_chip_select <= '1';
					device_write <= '1';
					xfer_count_var := xfer_count_var - 1;
				end if;
			else -- xfer_to_device_pending = '1'
				if to_X01(request_xfer_to_device) = '0' then
					device_chip_select <= '0';
					device_write <= '0';
					xfer_to_device_pending <= '0';
				end if;
			end if;
			
			-- handle request for transfer from device
			case xfer_from_device_state is
				when xfer_from_device_idle =>
					if to_X01(request_xfer_from_device) = '1' and gpib_to_host_fifo_full = '0' and
						xfer_count_var > 0 then
						xfer_from_device_state <= xfer_from_device_waiting;
						device_chip_select <= '1';
						device_read <= '1';
						xfer_count_var := xfer_count_var - 1;
					end if;
				when xfer_from_device_waiting =>
					if to_X01(request_xfer_from_device) = '0' then
						xfer_from_device_state <= xfer_from_device_active;
						gpib_to_host_fifo_write_enable <= '1';
					end if;
				when xfer_from_device_active =>
					device_chip_select <= '0';
					device_read <= '0';
					xfer_from_device_state <= xfer_from_device_idle;
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
			
			xfer_countdown <= xfer_count_var;
		end if;
	end process;
end dma_fifos_arch;
