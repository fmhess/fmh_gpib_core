-- a cb7210 with digital filtering of the gpib control lines, and
-- dma translation suitable for "synopsys" style dma peripheral
-- requests (the ARM DMA-330 DMA controller on Altera's Cyclone V HPS).
-- It puts a small fifo between the cb7210 dma port and the bus to
-- prevent dma latency from becoming a bottleneck.
-- There is also a "gpib_disable" input which disconnects the
-- gpib chip from the gpib bus.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017,2019 Frank Mori Hess
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.gpib_debounce_filter;
use work.frontend_cb7210p2;
use work.dma_fifos;

entity integrated_cb7210p2 is
	generic (
		-- The clock frequency is really intended to have no default, but we 
		-- default it to the invalid value of zero to make the Quartus Component Editor
		-- able to "Analyze Synthesis files".
		clock_frequency_KHz : natural := 0; 
		fifo_depth : positive := 32; -- must be at least 2, the maximum dma burst length is half the fifo depth
		max_filter_length : positive := 63
	);
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

		interrupt : out std_logic;

		-- dma, avalon mm io port
		dma_fifos_chip_select : in std_logic;
		dma_fifos_address : in std_logic_vector(1 downto 0);
		dma_fifos_read : in std_logic;
		dma_fifos_write : in std_logic;
		dma_fifos_data_in : in  std_logic_vector(15 downto 0);
		dma_fifos_data_out : out std_logic_vector(15 downto 0);

		-- dma peripherial request
		dma_single : out std_logic;
		dma_req : out std_logic;
		dma_ack : in  std_logic;

		-- gpib bus input
		gpib_DIO_inverted_in : in std_logic_vector (7 downto 0);
		gpib_ATN_inverted_in : in std_logic;
		gpib_DAV_inverted_in : in std_logic;
		gpib_EOI_inverted_in : in std_logic;
		gpib_IFC_inverted_in : in std_logic;
		gpib_NRFD_inverted_in : in std_logic;
		gpib_NDAC_inverted_in : in std_logic;
		gpib_SRQ_inverted_in : in std_logic;
		gpib_REN_inverted_in : in std_logic;
		-- gpib bus output
		gpib_DIO_inverted_out : out std_logic_vector (7 downto 0);
		gpib_ATN_inverted_out : out std_logic;
		gpib_DAV_inverted_out : out std_logic;
		gpib_EOI_inverted_out : out std_logic;
		gpib_IFC_inverted_out : out std_logic;
		gpib_NRFD_inverted_out : out std_logic;
		gpib_NDAC_inverted_out : out std_logic;
		gpib_SRQ_inverted_out : out std_logic;
		gpib_REN_inverted_out : out std_logic;

		-- gpib transceiver control
		talk_enable : out std_logic; -- aka talk enable
		EOI_output_enable : out std_logic;
		not_controller_in_charge : out std_logic; -- transceiver DC
		pullup_enable_inverted : out std_logic; -- transceiver PE
		system_controller : out std_logic;

		trigger : out std_logic;

		-- gpib bus disconnect
		gpib_disable : in std_logic := '0'
	);
end integrated_cb7210p2;

architecture structural of integrated_cb7210p2 is

	-- calculate a reasonable value for the
	-- number of input samples the a filter stores (sampled on rising and falling clock edges)
	function suggest_filter_length (filter_frequency_Khz : natural; 
		filter_window_ns : natural;
		min_length : positive;
		max_length : positive) return natural is
		variable length : natural;
	begin
		length := (filter_window_ns * filter_frequency_Khz) / 1000000;
		if length < min_length then 
			length := min_length;
		elsif length > max_length then
			length := max_length;
		end if;
		return length;
	end suggest_filter_length;
	
	-- threshold is number of matching input samples required to change filter output 
	function suggest_filter_threshold (filter_length : positive) return natural is
		variable threshold : natural;
	begin
		threshold := (filter_length * 3) / 4;
		if (threshold * 2) <= filter_length then
			threshold := filter_length;
		end if;
		return threshold;
	end suggest_filter_threshold;
	

	-- IEEE 488.1 has a couple 200ns response time requirements for control lines, so that should be taken into account when
	-- setting the filter length/threshold given your clock frequency.
	constant filter_length_25ns : positive := suggest_filter_length (clock_frequency_KHz * 2, 25, 2, max_filter_length); 
	constant filter_threshold_25ns : positive := suggest_filter_threshold (filter_length_25ns);
	constant filter_length_40ns : positive := suggest_filter_length (clock_frequency_KHz * 2, 40, 2, max_filter_length); 
	constant filter_threshold_40ns : positive := suggest_filter_threshold (filter_length_40ns);
	constant filter_length_75ns : positive := suggest_filter_length (clock_frequency_KHz * 2, 75, 2, max_filter_length); 
	constant filter_threshold_75ns : positive := suggest_filter_threshold (filter_length_75ns);
	constant filter_length_80ns : positive := suggest_filter_length (clock_frequency_KHz * 2, 80, 2, max_filter_length); 
	constant filter_threshold_80ns : positive := suggest_filter_threshold (filter_length_80ns);
	constant filter_length_120ns : positive := suggest_filter_length (clock_frequency_KHz * 2, 120, 2, max_filter_length); 
	constant filter_threshold_120ns : positive := suggest_filter_threshold (filter_length_120ns);
	constant filter_length_151ns : positive := suggest_filter_length (clock_frequency_KHz * 2, 151, 2, max_filter_length); 
	constant filter_threshold_151ns : positive := suggest_filter_threshold (filter_length_151ns);
	constant filter_length_200ns : positive := suggest_filter_length (clock_frequency_KHz * 2, 200, 2, max_filter_length); 
	constant filter_threshold_200ns : positive := suggest_filter_threshold (filter_length_200ns);

	procedure set_DAV_filter_parameters (num_meters : in unsigned; 
		signal length : out positive;
		signal threshold : out positive) is
	begin
		-- filters based on T19 response requirements, or
		-- T2 of 200ns when interlocked 
		if num_meters = 0 then
			length <= filter_length_200ns;
			threshold <= filter_threshold_200ns;
		elsif num_meters <= 3 then
			length <= filter_length_25ns;
			threshold <= filter_threshold_25ns;
		elsif num_meters <= 7 then
			length <= filter_length_40ns;
			threshold <= filter_threshold_40ns;
		else
			length <= filter_length_75ns;
			threshold <= filter_threshold_75ns;
		end if;
	end set_DAV_filter_parameters;
	
	procedure set_DIO_filter_parameters (num_meters : unsigned;
		signal length : out positive;
		signal threshold : out positive) is
	begin
		-- filters based on T18 settle times, until we cap at 200ns 
		-- due to T2 response requirement of IEEE 488.1
		if num_meters = 0 then
			length <= filter_length_200ns;
			threshold <= filter_threshold_200ns;
		elsif num_meters <= 1 then
			length <= filter_length_80ns;
			threshold <= filter_threshold_80ns;
		elsif num_meters <= 2 then
			length <= filter_length_120ns;
			threshold <= filter_threshold_120ns;
		elsif num_meters <= 3 then
			length <= filter_length_151ns;
			threshold <= filter_threshold_151ns;
		else 
			length <= filter_length_200ns;
			threshold <= filter_threshold_200ns;
		end if;
	end set_DIO_filter_parameters;

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
	signal cb7210p2_dma_data_eoi_in : std_logic;
	signal cb7210p2_dma_data_out : std_logic_vector(7 downto 0);
	signal cb7210p2_dma_data_end_out : std_logic;
	
	signal fifo_host_to_gpib_dma_single_request : std_logic;
	signal fifo_host_to_gpib_dma_burst_request : std_logic;
	signal fifo_gpib_to_host_dma_single_request : std_logic;
	signal fifo_gpib_to_host_dma_burst_request : std_logic;
	
	signal dma_transfer_active : std_logic;
	
	signal filtered_ATN_inverted : std_logic;
	signal filtered_DAV_inverted : std_logic;
	signal filtered_EOI_inverted : std_logic;
	signal filtered_IFC_inverted : std_logic;
	signal filtered_NDAC_inverted : std_logic;
	signal filtered_NRFD_inverted : std_logic;
	signal filtered_REN_inverted : std_logic;
	signal filtered_SRQ_inverted : std_logic;
	signal filtered_DIO_inverted : std_logic_vector (7 downto 0);

	-- gpib control line inputs gated by gpib_disable.  We don't need to disable input gpib data lines.
	signal gated_ATN_inverted : std_logic;
	signal gated_DAV_inverted : std_logic;
	signal gated_EOI_inverted : std_logic;
	signal gated_IFC_inverted : std_logic;
	signal gated_NDAC_inverted : std_logic;
	signal gated_NRFD_inverted : std_logic;
	signal gated_REN_inverted : std_logic;
	signal gated_SRQ_inverted : std_logic;
	
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
	signal ungated_system_controller : std_logic;
	signal ungated_EOI_output_enable : std_logic;
	
	signal xfer_countdown : unsigned(11 downto 0);
	signal force_lni : std_logic;
	signal configuration_num_meters : unsigned(3 downto 0);

	signal DAV_filter_length : positive range 1 to filter_length_200ns;
	signal DAV_filter_threshold : positive range 1 to filter_length_200ns;
	signal DIO_filter_length : positive range 1 to filter_length_200ns;
	signal DIO_filter_threshold : positive range 1 to filter_length_200ns;
begin
	my_control_debounce_filter : entity work.gpib_debounce_filter
		generic map(
			max_length => filter_length_200ns,
			num_inputs => 6
		)
		port map(
			reset => safe_reset,
			clock => clock,
			threshold => filter_threshold_200ns,
			inputs(0) => gpib_ATN_inverted_in,
			inputs(1) => gpib_IFC_inverted_in,
			inputs(2) => gpib_NDAC_inverted_in,
			inputs(3) => gpib_NRFD_inverted_in,
			inputs(4) => gpib_REN_inverted_in,
			inputs(5) => gpib_SRQ_inverted_in,
			outputs(0) => filtered_ATN_inverted,
			outputs(1) => filtered_IFC_inverted,
			outputs(2) => filtered_NDAC_inverted,
			outputs(3) => filtered_NRFD_inverted,
			outputs(4) => filtered_REN_inverted,
			outputs(5) => filtered_SRQ_inverted
		);

	my_DAV_debounce_filter : entity work.gpib_debounce_filter
		generic map(
			max_length => filter_length_200ns,
			num_inputs => 1
		)
		port map(
			reset => safe_reset,
			clock => clock,
			length => DAV_filter_length,
			threshold => DAV_filter_threshold,
			inputs(0) => gpib_DAV_inverted_in,
			outputs(0) => filtered_DAV_inverted
		);

	my_DIO_debounce_filter : entity work.gpib_debounce_filter
		generic map(
			max_length => filter_length_200ns,
			num_inputs => 9
		)
		port map(
			reset => safe_reset,
			clock => clock,
			length => DIO_filter_length,
			threshold => DIO_filter_threshold,
			inputs(7 downto 0) => gpib_DIO_inverted_in,
			inputs(8) => gpib_EOI_inverted_in,
			outputs(7 downto 0) => filtered_DIO_inverted,
			outputs(8) => filtered_EOI_inverted
		);
	
	my_dma_fifos : entity work.dma_fifos
		generic map(fifo_depth => fifo_depth)
		port map(
			clock => clock,
			reset => safe_reset,
			host_address => dma_fifos_address(1 downto 0),
			host_chip_select => dma_fifos_chip_select,
			host_read => dma_fifos_read,
			host_write => dma_fifos_write,
			host_data_in => dma_fifos_data_in,
			host_data_out => dma_fifos_data_out,
			host_to_gpib_dma_single_request => fifo_host_to_gpib_dma_single_request,
			host_to_gpib_dma_burst_request => fifo_host_to_gpib_dma_burst_request,
			gpib_to_host_dma_single_request => fifo_gpib_to_host_dma_single_request,
			gpib_to_host_dma_burst_request => fifo_gpib_to_host_dma_burst_request,
			request_xfer_to_device => cb7210p2_dma_bus_in_request,
			request_xfer_from_device => cb7210p2_dma_bus_out_request,
			device_chip_select => cb7210p2_dma_ack,
			device_read => cb7210p2_dma_read,
			device_write => cb7210p2_dma_write,
			device_data_in => cb7210p2_dma_data_out,
			device_data_end_in => cb7210p2_dma_data_end_out,
			device_data_out => cb7210p2_dma_data_in,
			device_data_eoi_out => cb7210p2_dma_data_eoi_in,
			xfer_countdown => xfer_countdown
		);
		
	my_cb7210p2 : entity work.frontend_cb7210p2
		generic map(
			num_address_lines => 7,
			clock_frequency_KHz => clock_frequency_KHz)
		port map (
			clock => clock,
			reset => safe_reset,
			chip_select_inverted => avalon_chip_select_inverted,
			dma_bus_ack_inverted => cb7210p2_dma_ack_inverted,
			dma_read_inverted => cb7210p2_dma_read_inverted,
			dma_write_inverted => cb7210p2_dma_write_inverted,
			read_inverted => avalon_read_inverted,
			address => avalon_address,
			write_inverted => avalon_write_inverted,
			host_data_bus_in => avalon_data_in,
			dma_bus_in => cb7210p2_dma_data_in,
			dma_bus_eoi_in => cb7210p2_dma_data_eoi_in,
			gpib_ATN_inverted_in => gated_ATN_inverted,
			gpib_DAV_inverted_in => gated_DAV_inverted,
			gpib_EOI_inverted_in => gated_EOI_inverted,
			gpib_IFC_inverted_in => gated_IFC_inverted,
			gpib_NDAC_inverted_in => gated_NDAC_inverted,
			gpib_NRFD_inverted_in => gated_NRFD_inverted,
			gpib_REN_inverted_in => gated_REN_inverted,
			gpib_SRQ_inverted_in => gated_SRQ_inverted,
			gpib_DIO_inverted_in => filtered_DIO_inverted,
			force_lni_true => force_lni,
			configuration_num_meters => configuration_num_meters,
			tr1 => ungated_talk_enable,
			EOI_output_enable => ungated_EOI_output_enable,
			not_controller_in_charge => ungated_not_controller_in_charge,
			pullup_enable_inverted => ungated_pullup_disable,
			system_controller => ungated_system_controller,
			trigger => trigger,
			interrupt => interrupt,
			dma_bus_in_request => cb7210p2_dma_bus_in_request,
			dma_bus_out_request => cb7210p2_dma_bus_out_request,
			host_data_bus_out => avalon_data_out,
			dma_bus_out => cb7210p2_dma_data_out,
			dma_bus_end_out => cb7210p2_dma_data_end_out,
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

	-- sync reset deassertion
	process (reset, clock)
	begin
		if to_X01(reset) = '1' then
			safe_reset <= '1';
		elsif rising_edge(clock) then
			safe_reset <= '0';
		end if;
	end process;

	-- handle gating by gpib_disable
	process (safe_reset, clock)
	begin
		if to_X01(safe_reset) = '1' then
			-- inputs
			gated_ATN_inverted <= '1';
			gated_DAV_inverted <= '1';
			gated_EOI_inverted <= '1';
			gated_IFC_inverted <= '1';
			gated_NDAC_inverted <= '1';
			gated_NRFD_inverted <= '1';
			gated_REN_inverted <= '1';
			gated_SRQ_inverted <= '1';

			--outputs
			gpib_DIO_inverted_out <= (others => 'Z');
			gpib_ATN_inverted_out <= 'Z';
			gpib_DAV_inverted_out <= 'Z';
			gpib_EOI_inverted_out <= 'Z';
			gpib_IFC_inverted_out <= 'Z';
			gpib_NDAC_inverted_out <= 'Z';
			gpib_NRFD_inverted_out <= 'Z';
			gpib_REN_inverted_out <= 'Z';
			gpib_SRQ_inverted_out <= 'Z';
			
			-- transceiver control
			talk_enable <= '0';
			pullup_enable_inverted <= '0';
			not_controller_in_charge <= '1';
			system_controller <= '0';
			EOI_output_enable <= '0';
		elsif rising_edge(clock) then
			if to_X01(gpib_disable) = '1' then
				-- inputs
				gated_ATN_inverted <= '1';
				gated_DAV_inverted <= '1';
				gated_EOI_inverted <= '1';
				gated_IFC_inverted <= '1';
				gated_NDAC_inverted <= '1';
				gated_NRFD_inverted <= '1';
				gated_REN_inverted <= '1';
				gated_SRQ_inverted <= '1';

				--outputs
				gpib_DIO_inverted_out <= (others => 'Z');
				gpib_ATN_inverted_out <= 'Z';
				gpib_DAV_inverted_out <= 'Z';
				gpib_EOI_inverted_out <= 'Z';
				gpib_IFC_inverted_out <= 'Z';
				gpib_NDAC_inverted_out <= 'Z';
				gpib_NRFD_inverted_out <= 'Z';
				gpib_REN_inverted_out <= 'Z';
				gpib_SRQ_inverted_out <= 'Z';

				-- transceiver control
				talk_enable <= '0';
				pullup_enable_inverted <= '0';
				not_controller_in_charge <= '1';
				system_controller <= '0';
				EOI_output_enable <= '0';
			else
				-- inputs
 				gated_ATN_inverted <= filtered_ATN_inverted;
 				gated_DAV_inverted <= filtered_DAV_inverted;
 				gated_EOI_inverted <= filtered_EOI_inverted;
 				gated_IFC_inverted <= filtered_IFC_inverted;
 				gated_NDAC_inverted <= filtered_NDAC_inverted;
 				gated_NRFD_inverted <= filtered_NRFD_inverted;
 				gated_REN_inverted <= filtered_REN_inverted;
 				gated_SRQ_inverted <= filtered_SRQ_inverted;

 				--outputs
				gpib_DIO_inverted_out <=  ungated_DIO_inverted_out;
				gpib_ATN_inverted_out <= ungated_ATN_inverted_out;
				gpib_DAV_inverted_out <= ungated_DAV_inverted_out;
				gpib_EOI_inverted_out <= ungated_EOI_inverted_out;
				gpib_IFC_inverted_out <= ungated_IFC_inverted_out;
				gpib_NDAC_inverted_out <= ungated_NDAC_inverted_out;
				gpib_NRFD_inverted_out <= ungated_NRFD_inverted_out;
				gpib_REN_inverted_out <= ungated_REN_inverted_out;
				gpib_SRQ_inverted_out <= ungated_SRQ_inverted_out;

				-- transceiver control
				talk_enable <= ungated_talk_enable;
				pullup_enable_inverted <= ungated_pullup_disable;
				not_controller_in_charge <= ungated_not_controller_in_charge;
				EOI_output_enable <= ungated_EOI_output_enable;
				system_controller <= ungated_system_controller;
			end if;
		end if;
	end process;

	-- dma requests
	process (safe_reset, clock)
	begin
		if to_X01(safe_reset) = '1' then
			dma_single <= '0';
			dma_req <= '0';
		elsif rising_edge(clock) then
			-- altera's dma fifo example code for their "synopsys style" dma protocol on the
			-- cyclone V HPS claims that dma requests should never be de-asserted
			-- unless a dma_ack is received.  They must be de-asserted on receiving a dma_ack in
			-- order to "ack the ack".
			if to_X01(dma_ack) = '1' then
				dma_single <= '0';
				dma_req <= '0';
			else
				if (fifo_host_to_gpib_dma_single_request or fifo_gpib_to_host_dma_single_request) = '1' then
					dma_single <= '1';
				end if;
				if (fifo_host_to_gpib_dma_burst_request or fifo_gpib_to_host_dma_burst_request) = '1' then
					dma_req <= '1';
				end if;
			end if;
		end if;
	end process;
	
	cb7210p2_dma_read_inverted <= not cb7210p2_dma_read;
	cb7210p2_dma_write_inverted <= not cb7210p2_dma_write;
	cb7210p2_dma_ack_inverted <= not cb7210p2_dma_ack;
	
	-- dynamic filter settings
	process (safe_reset, clock)
	begin
		if to_X01(safe_reset) = '1' then
			set_DAV_filter_parameters (X"0", DAV_filter_length, DAV_filter_threshold);
			set_DIO_filter_parameters (X"0", DIO_filter_length, DIO_filter_threshold);
		elsif rising_edge(clock) then
			set_DAV_filter_parameters (configuration_num_meters, DAV_filter_length, DAV_filter_threshold);
			set_DIO_filter_parameters (configuration_num_meters, DIO_filter_length, DIO_filter_threshold);
		end if;
	end process;

	-- assert lni when we are near the end of a gpib-to-host transfer
	process (safe_reset, clock)
	begin
		if to_X01(safe_reset) = '1' then
			force_lni <= '1';
		elsif rising_edge(clock) then
			if xfer_countdown <= 5 then
				force_lni <= '1';
			else
				force_lni <= '0';
			end if;
		end if;
	end process;

end architecture structural;
