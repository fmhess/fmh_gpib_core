-- a cb7210 with digital filtering of the gpib control lines,
-- and dma translation suitable for an ARM PL330 DMA controller.
-- There is also a "gpib_disable" input which disconnects the
-- gpib chip from the gpib bus, and a dma transfer counter.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dma_translator_cb7210p2_to_pl330;
use work.gpib_control_debounce_filter;
use work.frontend_cb7210p2;
use work.dma_fifos;

entity gpib_top is
	port (
		clock : in std_logic;
		reset : in  std_logic;

		-- gpib chip registers, avalon mm io port
		avalon_chip_select_inverted : in std_logic;
		avalon_read_inverted : in std_logic;
		avalon_write_inverted : in  std_logic;
		avalon_address : in  std_logic_vector(6 downto 0);
		avalon_data_in : in  std_logic_vector(7 downto 0);
		avalon_data_out : out std_logic_vector(7 downto 0);

		avalon_irq : out std_logic;

		-- dma, avalon mm io port
		dma_fifos_chip_select : in std_logic;
		dma_fifos_address : in std_logic_vector(0 downto 0);
		dma_fifos_read : in std_logic;
		dma_fifos_write : in std_logic;
		dma_fifos_data_in : in  std_logic_vector(7 downto 0);
		dma_fifos_data_out : out std_logic_vector(7 downto 0);

		-- dma peripherial request
		dma_single : out std_logic;
		dma_req : out std_logic;
		dma_ack : in  std_logic;

		-- transfer counter, avalon mm io port
		dma_count_chip_select : in std_logic;
		dma_count_read : in  std_logic;
		dma_count_write : in  std_logic;
		dma_count_data_in : in  std_logic_vector(15 downto 0);
		dma_count_data_out : out std_logic_vector(15 downto 0);

		-- gpib bus
		gpib_data : inout std_logic_vector (7 downto 0);
		gpib_atn : inout std_logic;
		gpib_dav : inout std_logic;
		gpib_eoi : inout std_logic;
		gpib_ifc : inout std_logic;
		gpib_nrfd : inout std_logic;
		gpib_ndac : inout std_logic;
		gpib_srq : inout std_logic;
		gpib_ren : inout std_logic;

		-- gpib transceiver control
		gpib_pe : out std_logic;
		gpib_dc : out std_logic;
		gpib_te : out std_logic;

		-- gpib bus disconnect
		gpib_disable : in std_logic
	);
end gpib_top;

architecture structural of gpib_top is
	signal safe_reset : std_logic;
	
	signal cb7210p2_dma_bus_in_request : std_logic;
	signal cb7210p2_dma_bus_out_request : std_logic;
	signal cb7210p2_dma_read : std_logic;
	signal cb7210p2_dma_write : std_logic;
	signal cb7210p2_dma_ack : std_logic;
	signal cb7210p2_dma_read_inverted : std_logic;
	signal cb7210p2_dma_write_inverted : std_logic;
	signal cb7210p2_dma_ack_inverted : std_logic;
	signal cb7210p2_dma_data_in : std_logic_vector(7 downto 0);
	signal cb7210p2_dma_data_out : std_logic_vector(7 downto 0);
	
	signal fifo_host_to_gpib_dma_request : std_logic;
	signal fifo_gpib_to_host_dma_request : std_logic;
	
	signal dma_count: unsigned (10 downto 0); -- Count of bytes into 7210.
	signal dma_transfer_active : std_logic;
	
	signal filtered_ATN : std_logic;
	signal filtered_DAV : std_logic;
	signal filtered_EOI : std_logic;
	signal filtered_IFC : std_logic;
	signal filtered_NDAC : std_logic;
	signal filtered_NRFD : std_logic;
	signal filtered_REN : std_logic;
	signal filtered_SRQ : std_logic;

	-- gpib control line inputs gated by gpib_disable.  We don't need to disable input gpib data lines.
	signal gated_ATN : std_logic;
	signal gated_DAV : std_logic;
	signal gated_EOI : std_logic;
	signal gated_IFC : std_logic;
	signal gated_NDAC : std_logic;
	signal gated_NRFD : std_logic;
	signal gated_REN : std_logic;
	signal gated_SRQ : std_logic;
	
	-- raw gpib control lines and data coming from the gpib chip, before they have been gated by gpib_disable
	signal ungated_ATN_inverted_out : std_logic;
	signal ungated_DAV_inverted_out : std_logic;
	signal ungated_EOI_inverted_out : std_logic;
	signal ungated_IFC_inverted_out : std_logic;
	signal ungated_NDAC_inverted_out : std_logic;
	signal ungated_NRFD_inverted_out : std_logic;
	signal ungated_REN_inverted_out : std_logic;
	signal ungated_SRQ_inverted_out : std_logic;
	signal ungated_DIO_inverted_out : std_logic_vector(7 downto 0);
	
	-- raw transceiver controls
	signal ungated_talk_enable : std_logic;
	signal ungated_pullup_disable : std_logic;
	signal ungated_not_controller_in_charge : std_logic;
	
begin
	my_dma_translator : entity work.dma_translator_cb7210p2_to_pl330
		port map (
			clock => clock,
			reset => safe_reset,
			pl330_dma_ack => dma_ack,
			pl330_dma_single => dma_single,
			pl330_dma_req => dma_req,
			cb7210p2_dma_in_request => fifo_host_to_gpib_dma_request,
			cb7210p2_dma_out_request => fifo_gpib_to_host_dma_request
		);
	
	my_debounce_filter : entity work.gpib_control_debounce_filter
		generic map(
			length => 12,
			threshold => 10
		)
		port map(
			reset => safe_reset,
			input_clock => clock,
			output_clock => clock,
			inputs(0) => gpib_atn,
			inputs(1) => gpib_dav,
			inputs(2) => gpib_eoi,
			inputs(3) => gpib_ifc,
			inputs(4) => gpib_ndac,
			inputs(5) => gpib_nrfd,
			inputs(6) => gpib_ren,
			inputs(7) => gpib_srq,
			outputs(0) => filtered_ATN,
			outputs(1) => filtered_DAV,
			outputs(2) => filtered_EOI,
			outputs(3) => filtered_IFC,
			outputs(4) => filtered_NDAC,
			outputs(5) => filtered_NRFD,
			outputs(6) => filtered_REN,
			outputs(7) => filtered_SRQ
		);
	
	my_dma_fifos : entity work.dma_fifos
		generic map(fifo_depth => 4)
		port map(
			clock => clock,
			reset => safe_reset,
			host_address => dma_fifos_address,
			host_chip_select => dma_fifos_chip_select,
			host_read => dma_fifos_read,
			host_write => dma_fifos_write,
			host_data_in => dma_fifos_data_in,
			host_data_out => dma_fifos_data_out,
			host_to_gpib_dma_request => fifo_host_to_gpib_dma_request,
			gpib_to_host_dma_request => fifo_gpib_to_host_dma_request,
			request_xfer_to_device => cb7210p2_dma_bus_in_request,
			request_xfer_from_device => cb7210p2_dma_bus_out_request,
			device_chip_select => cb7210p2_dma_ack,
			device_read => cb7210p2_dma_read,
			device_write => cb7210p2_dma_write,
			device_data_in => cb7210p2_dma_data_out,
			device_data_out => cb7210p2_dma_data_in
		);
		
	my_cb7210p2 : entity work.frontend_cb7210p2
		generic map(
			num_address_lines => 7,
			clock_frequency_KHz => 60000)
		port map (
			clock => clock,
			reset => safe_reset,
			chip_select_inverted => avalon_chip_select_inverted,
			dma_bus_in_ack_inverted => cb7210p2_dma_ack_inverted,
			dma_bus_out_ack_inverted => cb7210p2_dma_ack_inverted,
			dma_read_inverted => cb7210p2_dma_read_inverted,
			dma_write_inverted => cb7210p2_dma_write_inverted,
			read_inverted => avalon_read_inverted,
			address => avalon_address,
			write_inverted => avalon_write_inverted,
			host_data_bus_in => avalon_data_in,
			dma_bus_in => cb7210p2_dma_data_in,
			gpib_ATN_inverted_in => gated_ATN,
			gpib_DAV_inverted_in => gated_DAV,
			gpib_EOI_inverted_in => gated_EOI,
			gpib_IFC_inverted_in => gated_IFC,
			gpib_NDAC_inverted_in => gated_NDAC,
			gpib_NRFD_inverted_in => gated_NRFD,
			gpib_REN_inverted_in => gated_REN,
			gpib_SRQ_inverted_in => gated_SRQ,
			gpib_DIO_inverted_in => gpib_data,
			tr1 => ungated_talk_enable,
			not_controller_in_charge => ungated_not_controller_in_charge,
			pullup_disable => ungated_pullup_disable,
			interrupt => avalon_irq,
			dma_bus_in_request => cb7210p2_dma_bus_in_request,
			dma_bus_out_request => cb7210p2_dma_bus_out_request,
			host_data_bus_out => avalon_data_out,
			dma_bus_out => cb7210p2_dma_data_out,
			gpib_ATN_inverted_out => ungated_ATN_inverted_out,
			gpib_DAV_inverted_out => ungated_DAV_inverted_out,
			gpib_EOI_inverted_out => ungated_EOI_inverted_out,
			gpib_IFC_inverted_out => ungated_IFC_inverted_out,
			gpib_NDAC_inverted_out => ungated_NDAC_inverted_out,
			gpib_NRFD_inverted_out => ungated_NRFD_inverted_out,
			gpib_REN_inverted_out => ungated_REN_inverted_out,
			gpib_SRQ_inverted_out => ungated_SRQ_inverted_out,
			gpib_DIO_inverted_out => ungated_DIO_inverted_out
		);

	dma_count_data_out(15 downto 11) <= (others => '0');
	dma_count_data_out(10 downto 0) <= std_logic_vector(dma_count);

	-- sync reset deassertion
	process (reset, clock)
	begin
		if to_X01(reset) = '1' then
			safe_reset <= '1';
		elsif rising_edge(clock) then
			safe_reset <= '0';
		end if;
	end process;
	
	-- dma transfer counter (at interfact between fifos and gpib chip)
	process(safe_reset, clock) is
		variable prev_cb7210p2_dma_ack_inverted : std_logic;
	begin
		if safe_reset = '1' then
			dma_count <= (others => '0');
			prev_cb7210p2_dma_ack_inverted := '1';
		elsif rising_edge(clock) then
			-- Reset counter when written to.
			if (dma_count_chip_select = '1') and (dma_count_write = '1') then
				dma_count <= (others => '0');
			-- count bytes on data transfer across dma bus port.
			elsif cb7210p2_dma_ack_inverted = '1' and prev_cb7210p2_dma_ack_inverted = '0' then
				dma_count <= dma_count + 1;
			end if;
			prev_cb7210p2_dma_ack_inverted := cb7210p2_dma_ack_inverted;
		end if;
	end process;

	-- handle gating by gpib_disable
	process (safe_reset, clock)
	begin
		if to_X01(safe_reset) = '1' then
			-- inputs
			gated_ATN <= '1';
			gated_DAV <= '1';
			gated_EOI <= '1';
			gated_IFC <= '1';
			gated_NDAC <= '1';
			gated_NRFD <= '1';
			gated_REN <= '1';
			gated_SRQ <= '1';

			-- transceiver control
			gpib_te <= '0';
			gpib_pe <= '0';
			gpib_dc <= '0';
		elsif rising_edge(clock) then
			if to_X01(gpib_disable) = '1' then
				-- inputs
				gated_ATN <= '1';
				gated_DAV <= '1';
				gated_EOI <= '1';
				gated_IFC <= '1';
				gated_NDAC <= '1';
				gated_NRFD <= '1';
				gated_REN <= '1';
				gated_SRQ <= '1';

				-- transceiver control
				gpib_te <= '0';
				gpib_pe <= '0';
				gpib_dc <= '0';
			else
				-- inputs
 				gated_ATN <= filtered_ATN;
 				gated_DAV <= filtered_DAV;
 				gated_EOI <= filtered_EOI;
 				gated_IFC <= filtered_IFC;
 				gated_NDAC <= filtered_NDAC;
 				gated_NRFD <= filtered_NRFD;
 				gated_REN <= filtered_REN;
 				gated_SRQ <= filtered_SRQ;

				-- transceiver control
				gpib_te <= ungated_talk_enable;
				gpib_pe <= ungated_pullup_disable;
				gpib_dc <= not ungated_not_controller_in_charge;
			end if;
		end if;
	end process;

	gpib_data <= (others => 'Z') when gpib_disable = '1' else ungated_DIO_inverted_out;
	gpib_atn <= 'Z' when gpib_disable = '1' else ungated_ATN_inverted_out;
	gpib_dav <= 'Z' when gpib_disable = '1' else ungated_DAV_inverted_out;
	gpib_eoi <= 'Z' when gpib_disable = '1' else ungated_EOI_inverted_out;
	gpib_ifc <= 'Z' when gpib_disable = '1' else ungated_IFC_inverted_out;
	gpib_ndac <= 'Z' when gpib_disable = '1' else ungated_NDAC_inverted_out;
	gpib_nrfd <= 'Z' when gpib_disable = '1' else ungated_NRFD_inverted_out;
	gpib_ren <= 'Z' when gpib_disable = '1' else ungated_REN_inverted_out;
	gpib_srq <= 'Z' when gpib_disable = '1' else ungated_SRQ_inverted_out;
	
	cb7210p2_dma_read_inverted <= not cb7210p2_dma_read;
	cb7210p2_dma_write_inverted <= not cb7210p2_dma_write;
	cb7210p2_dma_ack_inverted <= not cb7210p2_dma_ack;

end architecture structural;
