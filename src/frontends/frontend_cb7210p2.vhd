-- frontend with cb7210.2 style register layout.  It favors standards compliance
-- and sanity over bug-for-bug compatibility with the original chip.
--
-- It has been extended with:
-- * the addition or a isr0/imr0 register at page 1, offset 6.
-- * added "Aux reg I" with PPMODE2 bit which properly selects between the remote
--   or local parallel poll subsets of IEEE 488.1.
-- * status bits at offset 9 (register page 1, offset 1) which indicate clearly
--   whether a byte may currently be written into or read out of the chip
--   independently of interrupt clearing logic.
-- * a dedicated data byte out register at offset 8 (register page 1, offset 0) which
--   only accepts data bytes, not command bytes 
-- * a dedicated command byte out register at offset 0x10 (register page 2, offset 0) which
--   only accepts commmand bytes, not data bytes 
-- * a "RFD holdoff ASAP" auxilliary command, which causes an RFD holdoff to take effect
--   as soon as possible (IEEE 488.1 forbids rdy from becoming false while in ACRS).
-- * reqt/reqf setting similar to NI tnt4882 serial poll mode SP1
--
-- Features which could be implemented if anyone cares:
-- * Setting clock frequency by writing to the auxiliary mode register.  Clock frequency
--   is specified by a generic parameter instead.  We would want to implement this if someone actually
--   wanted to produce this as an ASIC rather than burning it into an FPGA.
--
-- Features we don't implement, because they are standards violating:
-- * bug-for-bug compatible source handshaking that violates 488.1 or 488.2.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;
use work.integrated_interface_functions;

entity frontend_cb7210p2 is
	generic(
		-- the number of address lines may be reduced to 3 if you don't care about having
		-- a flat register map.  Address lines 3 through 6 are equivalent to the register page
		-- selected by the page select auxilliary command.
		num_address_lines : positive := 7;
		clock_frequency_KHz : positive;
		-- you must have enough counter bits to generate a 2 microsecond delay given your clock speed.
		num_counter_bits : integer := 8);
	port(
		clock : in std_logic;
		chip_select_inverted : in std_logic;
		dma_bus_ack_inverted : in std_logic;
		dma_read_inverted : in std_logic;
		dma_write_inverted : in std_logic;
		read_inverted : in std_logic;
		reset : in std_logic;
		address : in std_logic_vector(num_address_lines - 1 downto 0); 
		write_inverted : in std_logic;
		host_data_bus_in : in std_logic_vector(7 downto 0);
		dma_bus_in : in std_logic_vector(7 downto 0);
		gpib_ATN_inverted_in : in std_logic; 
		gpib_DAV_inverted_in : in std_logic; 
		gpib_EOI_inverted_in : in std_logic; 
		gpib_IFC_inverted_in : in std_logic; 
		gpib_NDAC_inverted_in : in std_logic; 
		gpib_NRFD_inverted_in : in std_logic; 
		gpib_REN_inverted_in : in std_logic; 
		gpib_SRQ_inverted_in : in std_logic; 
		gpib_DIO_inverted_in : in std_logic_vector(7 downto 0);

		tr1 : out std_logic;
		tr2 : out std_logic;
		tr3 : out std_logic;
		interrupt : out std_logic;

		dma_bus_in_request : out std_logic;
		dma_bus_out_request : out std_logic;
		host_data_bus_out : out std_logic_vector(7 downto 0);
		dma_bus_out : out std_logic_vector(7 downto 0);
		gpib_ATN_inverted_out : out std_logic; 
		gpib_DAV_inverted_out : out std_logic; 
		gpib_EOI_inverted_out : out std_logic; 
		gpib_IFC_inverted_out : out std_logic; 
		gpib_NDAC_inverted_out : out std_logic; 
		gpib_NRFD_inverted_out : out std_logic; 
		gpib_REN_inverted_out : out std_logic; 
		gpib_SRQ_inverted_out : out std_logic; 
		gpib_DIO_inverted_out : out std_logic_vector(7 downto 0);

		--rather than relying on the driver to properly configure the modes
		-- of the tr2 and tr3 outputs, these outputs can be used instead
		EOI_output_enable : out std_logic;
		not_controller_in_charge : out std_logic; -- transceiver DC
		pullup_disable : out std_logic; -- transceiver PE
		trigger : out std_logic;
		system_controller : out std_logic
	);
end frontend_cb7210p2;
     
architecture frontend_cb7210p2_arch of frontend_cb7210p2 is
	type host_io_enum is (host_io_idle, host_io_waiting_for_idle);
	signal host_read_from_bus_state : host_io_enum;
	signal host_write_to_bus_state : host_io_enum;

	type dma_enum is (dma_idle, dma_waiting_for_idle);
	signal host_to_gpib_dma_state : dma_enum;
	signal gpib_to_host_dma_state : dma_enum;

	signal bus_ATN_inverted_in : std_logic; 
	signal bus_DAV_inverted_in :  std_logic; 
	signal bus_EOI_inverted_in :  std_logic; 
	signal bus_IFC_inverted_in :  std_logic; 
	signal bus_NDAC_inverted_in :  std_logic; 
	signal bus_NRFD_inverted_in :  std_logic; 
	signal bus_REN_inverted_in :  std_logic; 
	signal bus_SRQ_inverted_in :  std_logic; 
	signal bus_DIO_inverted_in :  std_logic_vector(7 downto 0);

	signal configured_eos_character : std_logic_vector(7 downto 0);
	signal ignore_eos_bit_7 : std_logic;
	signal local_parallel_poll_config : std_logic;
	signal local_parallel_poll_sense : std_logic;
	signal local_parallel_poll_response_line : std_logic_vector(2 downto 0);
	signal local_parallel_poll_disable : std_logic;
	signal no_listeners : std_logic;
	signal first_T1_terminal_count : unsigned(num_counter_bits - 1 downto 0);
	signal T1_terminal_count : unsigned(num_counter_bits - 1 downto 0);
	signal gpib_to_host_byte : std_logic_vector(7 downto 0);
	signal gpib_to_host_byte_read : std_logic;
	signal gpib_to_host_byte_end : std_logic;
	signal gpib_to_host_byte_eos : std_logic;
	signal host_to_gpib_byte : std_logic_vector(7 downto 0);
	signal host_to_gpib_data_byte_end : std_logic;
	signal host_to_gpib_data_byte_write : std_logic;
	signal host_to_gpib_data_byte_latched : std_logic;
	signal host_to_gpib_command_byte_write : std_logic;
	signal host_to_gpib_command_byte_latched : std_logic;
	signal acceptor_handshake_state : AH_state;
	signal controller_state_p1 : C_state_p1;
	signal controller_state_p2 : C_state_p2;
	signal controller_state_p3 : C_state_p3;
	signal controller_state_p4 : C_state_p4;
	signal controller_state_p5 : C_state_p5;
	signal device_clear_state : DC_state;
	signal device_trigger_state : DT_state;
	signal listener_state_p1 : LE_state_p1;
	signal listener_state_p2 : LE_state_p2;
	signal parallel_poll_state_p1 : PP_state_p1;
	signal parallel_poll_state_p2 : PP_state_p2;
	signal remote_local_state : RL_state;
	signal service_request_state : SR_state;
	signal source_handshake_state : SH_state;
	signal talker_state_p1 : TE_state_p1;
	signal talker_state_p2 : TE_state_p2;
	signal talker_state_p3 : TE_state_p3;
	signal in_remote_state : std_logic;
	signal in_lockout_state : std_logic;
	signal in_TIDS : std_logic;
	signal LADS_or_LACS : std_logic;
	signal pending_rsv : std_logic;
	signal entered_DTAS : std_logic;
	signal entered_DCAS : std_logic;
	
	signal gts : std_logic;
	signal ist : std_logic;
	signal lon : std_logic;	
	signal lpe : std_logic;
	signal lun : std_logic;
	signal ltn : std_logic;
	signal pon : std_logic;
	signal gpib_to_host_byte_latched : std_logic;
	signal rpp : std_logic;
	signal rsc : std_logic;
	signal rtl : std_logic;
	signal sre : std_logic;
	signal sic : std_logic;
	signal ton : std_logic;
	signal tca : std_logic;
	signal tcs : std_logic;
	signal reqt_pending : std_logic;
	signal reqf_pending : std_logic;
	signal set_reqt_pulse : std_logic;
	signal set_reqf_pulse : std_logic;
	signal local_STB : std_logic_vector(7 downto 0);
	
	signal hard_reset : std_logic;
	signal soft_reset : std_logic;
	signal soft_reset_pulse : std_logic;
	signal pon_pulse : std_logic;
	
	signal host_write_selected : std_logic;
	signal host_read_selected : std_logic;
	signal dma_write_selected : std_logic;
	signal dma_read_selected : std_logic;
	signal register_page : std_logic_vector(3 downto 0);
	signal host_data_bus_out_buffer : std_logic_vector(7 downto 0);
	
	signal transmit_receive_mode : std_logic_vector(1 downto 0);
	signal address_mode : std_logic_vector(1 downto 0);
	signal gpib_address_0 : std_logic_vector(4 downto 0);
	signal enable_talker_gpib_address_0 : std_logic;
	signal enable_listener_gpib_address_0 : std_logic;
	signal gpib_address_1 : std_logic_vector(4 downto 0);
	signal enable_talker_gpib_address_1 : std_logic;
	signal enable_listener_gpib_address_1 : std_logic;
	signal ultra_fast_T1_delay : std_logic;
	signal high_speed_T1_delay : std_logic;
	signal enable_gpib_to_host_EOS : std_logic;
	signal configured_RFD_holdoff_mode : RFD_holdoff_enum;
	signal RFD_holdoff_mode : RFD_holdoff_enum;
	signal set_RFD_holdoff_pulse : std_logic;
	signal release_RFD_holdoff_pulse : std_logic;
	signal parallel_poll_flag : std_logic;
	signal use_SRQS_as_ist : std_logic;
	signal host_to_gpib_auto_EOI_on_EOS : std_logic;
	signal command_valid : std_logic;
	signal command_invalid : std_logic;
	signal APT_needs_host_response : std_logic;
	signal CPT_needs_host_response : std_logic;
	signal CPT_enabled : std_logic;
	signal enable_secondary_addressing : std_logic;
	signal address_passthrough_active : std_logic;
	signal command_passthrough_active : std_logic;
	signal listen_with_continuous_mode : std_logic;
	signal assert_END_in_SPAS : std_logic;
	signal DAC_holdoff_on_DCAS : std_logic;
	signal DAC_holdoff_on_DTAS : std_logic;
	signal parallel_poll_result : std_logic_vector(7 downto 0);
	signal parallel_poll_result_latched : std_logic;
	
	signal talk_enable_buffer : std_logic;
	signal controller_in_charge_buffer : std_logic;
	signal pullup_disable_buffer : std_logic;
	signal EOI_output_enable_buffer : std_logic;
	signal trigger_buffer : std_logic;
	signal trigger_aux_command_pulse : std_logic;
	
	signal any_interrupt_active : std_logic;
	signal invert_interrupt : std_logic;

	-- interrupt mask register 0 interrupts
	signal ATN_interrupt : std_logic;
	signal IFC_interrupt : std_logic;
	signal ATN_interrupt_enable : std_logic;
	signal IFC_interrupt_enable : std_logic;

	-- interrupt mask register 1 interrupts
	signal DI_interrupt : std_logic;
	signal DO_interrupt : std_logic;
	signal DO_interrupt_condition : std_logic;
	signal ERR_interrupt : std_logic;
	signal DEC_interrupt : std_logic;
	signal END_interrupt : std_logic;
	signal DET_interrupt : std_logic;
	signal APT_interrupt : std_logic;
	signal CPT_interrupt : std_logic;
	signal DI_interrupt_enable : std_logic;
	signal DO_interrupt_enable : std_logic;
	signal ERR_interrupt_enable : std_logic;
	signal DEC_interrupt_enable : std_logic;
	signal END_interrupt_enable : std_logic;
	signal end_interrupt_condition : std_logic;
	signal DET_interrupt_enable : std_logic;
	signal APT_interrupt_enable : std_logic;
	signal CPT_interrupt_enable : std_logic;
	
	-- interrupt mask register 2 interrupts
	signal ADSC_interrupt : std_logic;
	signal REMC_interrupt : std_logic;
	signal LOKC_interrupt : std_logic;
	signal CO_interrupt : std_logic;
	signal CO_interrupt_condition : std_logic;
	signal SRQ_interrupt : std_logic;
	signal ADSC_interrupt_enable : std_logic;
	signal REMC_interrupt_enable : std_logic;
	signal LOKC_interrupt_enable : std_logic;
	signal CO_interrupt_enable : std_logic;
	signal DMA_input_enable : std_logic;
	signal DMA_output_enable : std_logic;
	signal SRQ_interrupt_enable : std_logic;
	
	signal minor_addressed : std_logic;
	signal minor_primary_addressed : std_logic;
	signal RFD_holdoff_status : std_logic;
	
	-- overhead parameter is fixed number of clock ticks of overhead even when using a timing delay of zero
	function to_clock_ticks (nanoseconds : in integer; overhead : in integer) return unsigned is
		constant nanos_per_milli : integer := 1000000;
		variable ticks : integer;
	begin
		ticks := (nanoseconds * clock_frequency_KHz + nanos_per_milli - 1) / nanos_per_milli - overhead;
		if ticks < 0 then
			ticks := 0;
		end if;
		return to_unsigned(ticks, num_counter_bits);
	end to_clock_ticks;
	constant T1_clock_ticks_2us : unsigned(T1_terminal_count'RANGE) := to_clock_ticks(2000, 2);
	constant T1_clock_ticks_1100ns : unsigned(T1_terminal_count'RANGE) := to_clock_ticks(1100, 2);
	constant T1_clock_ticks_500ns : unsigned(T1_terminal_count'RANGE) := to_clock_ticks(500, 2);
	constant T1_clock_ticks_350ns : unsigned(T1_terminal_count'RANGE) := to_clock_ticks(350, 2);
	constant T6_clock_ticks_2us : unsigned(num_counter_bits - 1 downto 0) := to_clock_ticks(2000, 1);
	constant T7_clock_ticks_500ns : unsigned(num_counter_bits - 1 downto 0) := to_clock_ticks(500, 1);
	constant T8_clock_ticks_per_us : unsigned(num_counter_bits - 1 downto 0) := to_clock_ticks(1000, 1);
	constant T9_clock_ticks_1500ns : unsigned(num_counter_bits - 1 downto 0) := to_clock_ticks(1500, 1);
	constant T10_clock_ticks_1500ns : unsigned(num_counter_bits - 1 downto 0) := to_clock_ticks(1500, 1);
	
	function flat_address (page : in std_logic_vector(3 downto 0);
		raw_address : in std_logic_vector(num_address_lines - 1 downto 0)) 
		return integer is
		variable raw_address_integer : integer range 0 to 127;
		variable result : std_logic_vector(page'LENGTH + 2 downto 0);
	begin
		raw_address_integer := to_integer(unsigned(raw_address));
		if raw_address_integer < 8 then
			result(2 downto 0) := raw_address(2 downto 0);
			result(page'LENGTH + 2 downto 3) := page;
			return to_integer(unsigned(result));
		else
			return raw_address_integer;
		end if;
	end flat_address;

begin
	my_integrated_interface_functions: entity work.integrated_interface_functions 
	generic map (
			num_counter_bits => num_counter_bits
		)
	port map (
			clock => clock,
			bus_DIO_inverted_in => bus_DIO_inverted_in,
			bus_REN_inverted_in => bus_REN_inverted_in,
			bus_IFC_inverted_in => bus_IFC_inverted_in,
			bus_SRQ_inverted_in => bus_SRQ_inverted_in,
			bus_EOI_inverted_in => bus_EOI_inverted_in,
			bus_ATN_inverted_in => bus_ATN_inverted_in,
			bus_NDAC_inverted_in => bus_NDAC_inverted_in,
			bus_NRFD_inverted_in => bus_NRFD_inverted_in,
			bus_DAV_inverted_in => bus_DAV_inverted_in,
			bus_DIO_inverted_out => gpib_DIO_inverted_out,
			bus_REN_inverted_out => gpib_REN_inverted_out,
			bus_IFC_inverted_out => gpib_IFC_inverted_out,
			bus_SRQ_inverted_out => gpib_SRQ_inverted_out,
			bus_EOI_inverted_out => gpib_EOI_inverted_out,
			bus_ATN_inverted_out => gpib_ATN_inverted_out,
			bus_NDAC_inverted_out => gpib_NDAC_inverted_out,
			bus_NRFD_inverted_out => gpib_NRFD_inverted_out,
			bus_DAV_inverted_out => gpib_DAV_inverted_out,
			gts => gts,
			ist => ist,
			lon => lon,
			lpe => lpe,
			lun => lun,
			ltn => ltn,
			pon => pon,
			rpp => rpp,
			rsc => rsc,
			rtl => rtl,
			sre => sre,
			sic => sic,
			tca => tca,
			tcs => tcs,
			ton => ton,
			set_reqt_pulse => set_reqt_pulse,
			set_reqf_pulse => set_reqf_pulse,
			configured_eos_character => configured_eos_character,
			ignore_eos_bit_7 => ignore_eos_bit_7,
			command_valid => command_valid,
			command_invalid => command_invalid,
			enable_secondary_addressing => enable_secondary_addressing,
			local_parallel_poll_config => local_parallel_poll_config,
			local_parallel_poll_sense => local_parallel_poll_sense,
			local_parallel_poll_response_line => local_parallel_poll_response_line,
			check_for_listeners => '1',
			gpib_to_host_byte_read => gpib_to_host_byte_read,
			first_T1_terminal_count => first_T1_terminal_count,
			T1_terminal_count => T1_terminal_count,
			T6_terminal_count => T6_clock_ticks_2us,
			T7_terminal_count => T7_clock_ticks_500ns,
			T8_count_per_us => T8_clock_ticks_per_us,
			T9_terminal_count => T9_clock_ticks_1500ns,
			T10_terminal_count => T10_clock_ticks_1500ns,
			no_listeners => no_listeners,
			gpib_to_host_byte => gpib_to_host_byte,
			gpib_to_host_byte_end => gpib_to_host_byte_end,
			gpib_to_host_byte_eos => gpib_to_host_byte_eos,
			gpib_to_host_byte_latched => gpib_to_host_byte_latched,
			enable_gpib_to_host_EOS => enable_gpib_to_host_EOS,
			host_to_gpib_byte => host_to_gpib_byte,
			host_to_gpib_data_byte_end => host_to_gpib_data_byte_end,
			host_to_gpib_auto_EOI_on_EOS => host_to_gpib_auto_EOI_on_EOS,
			host_to_gpib_data_byte_write => host_to_gpib_data_byte_write,
			host_to_gpib_data_byte_latched => host_to_gpib_data_byte_latched,
			host_to_gpib_command_byte_write => host_to_gpib_command_byte_write,
			host_to_gpib_command_byte_latched => host_to_gpib_command_byte_latched,
			acceptor_handshake_state => acceptor_handshake_state,
			controller_state_p1 => controller_state_p1,
			controller_state_p2 => controller_state_p2,
			controller_state_p3 => controller_state_p3,
			controller_state_p4 => controller_state_p4,
			controller_state_p5 => controller_state_p5,
			device_clear_state => device_clear_state,
			device_trigger_state => device_trigger_state,
			listener_state_p1 => listener_state_p1,
			listener_state_p2 => listener_state_p2,
			parallel_poll_state_p1 => parallel_poll_state_p1,
			parallel_poll_state_p2 => parallel_poll_state_p2,
			remote_local_state => remote_local_state,
			service_request_state => service_request_state,
			source_handshake_state => source_handshake_state,
			talker_state_p1 => talker_state_p1,
			talker_state_p2 => talker_state_p2,
			talker_state_p3 => talker_state_p3,
			local_STB => local_STB,
			RFD_holdoff_mode => RFD_holdoff_mode,
			set_RFD_holdoff_pulse => set_RFD_holdoff_pulse,
			release_RFD_holdoff_pulse => release_RFD_holdoff_pulse,
			address_passthrough => address_passthrough_active,
			command_passthrough => command_passthrough_active,
			assert_END_in_SPAS => assert_END_in_SPAS,
			DAC_holdoff_on_DCAS => DAC_holdoff_on_DCAS,
			DAC_holdoff_on_DTAS => DAC_holdoff_on_DTAS,
			talk_enable => talk_enable_buffer,
			pullup_disable => pullup_disable_buffer,
			EOI_output_enable => EOI_output_enable_buffer,
			RFD_holdoff_status => RFD_holdoff_status,
			pending_rsv => pending_rsv
		);

	-- latch external gpib signals on clock edge
	process (clock)
	begin
		if rising_edge(clock) then
			bus_ATN_inverted_in <= to_X01(gpib_ATN_inverted_in);
			bus_DAV_inverted_in <= to_X01(gpib_DAV_inverted_in);
			bus_EOI_inverted_in <= to_X01(gpib_EOI_inverted_in);
			bus_IFC_inverted_in <= to_X01(gpib_IFC_inverted_in);
			bus_NDAC_inverted_in <= to_X01(gpib_NDAC_inverted_in);
			bus_NRFD_inverted_in <= to_X01(gpib_NRFD_inverted_in);
			bus_REN_inverted_in <= to_X01(gpib_REN_inverted_in);
			bus_SRQ_inverted_in <= to_X01(gpib_SRQ_inverted_in);
			bus_DIO_inverted_in <= to_X01(gpib_DIO_inverted_in);
		end if;
	end process;
	
	-- generate reset which is asserted async but de-asserted synchronously on 
	-- falling clock edge, to avoid any potential metastability problems caused
	-- by resets deasserting near rising clock edge.  Also deal with various types
	-- of resets hard_reset -> soft_reset -> pon.
	process (reset, clock)
	begin
		if to_X01(reset) = '1' then
			hard_reset <= '1';
			soft_reset <= '1';
			pon <= '1';
		elsif rising_edge(clock) then
			hard_reset <= '0';
			if soft_reset_pulse = '1' then
				soft_reset <= '1';
				pon <= '1';
			elsif pon_pulse = '1' then
				soft_reset <= '0';
				pon <= '1';
			else
				soft_reset <= '0';
				pon <= '0';
			end if;
		end if;
	end process;
	
	host_write_selected <= not write_inverted and not chip_select_inverted;
	host_read_selected <= not read_inverted and not chip_select_inverted;
	dma_write_selected <= not dma_write_inverted and not dma_bus_ack_inverted;
	dma_read_selected <= not dma_read_inverted and not dma_bus_ack_inverted;
	host_data_bus_out <= host_data_bus_out_buffer;
	
	-- accept reads from host
	process (soft_reset, clock)
		variable prev_controller_state_p2 : C_state_p2;
		variable prev_source_handshake_state : SH_state;
		variable prev_in_remote_state : std_logic;
		variable prev_in_lockout_state : std_logic;
		variable prev_ATN_inverted : std_logic;
		variable prev_IFC_inverted : std_logic;
		variable prev_in_TIDS : std_logic;
		variable prev_LADS_or_LACS : std_logic;
		variable prev_minor_addressed : std_logic;
		variable prev_controller_in_charge : std_logic;
		variable prev_gpib_to_host_byte_latched : std_logic;
		variable prev_end_interrupt_condition : std_logic;
		variable prev_APT_needs_host_response : std_logic;
		variable prev_CPT_needs_host_response : std_logic;
		variable prev_DI_interrupt_enable : std_logic;
		
		-- process a read from the host
		procedure host_read_register (page : in std_logic_vector(3 downto 0);
			read_address : in std_logic_vector(num_address_lines - 1 downto 0)) is

		begin
			case flat_address(page, read_address) is
				when 0 => -- data in
					host_data_bus_out_buffer <= gpib_to_host_byte;
					gpib_to_host_byte_read <= '1';
				when 1 => -- interrupt status 1
					host_data_bus_out_buffer(0) <= DI_interrupt;
					host_data_bus_out_buffer(1) <= DO_interrupt;
					host_data_bus_out_buffer(2) <= ERR_interrupt;
					host_data_bus_out_buffer(3) <= DEC_interrupt;
					host_data_bus_out_buffer(4) <= END_interrupt;
					host_data_bus_out_buffer(5) <= DET_interrupt;
					host_data_bus_out_buffer(6) <= APT_interrupt;
					host_data_bus_out_buffer(7) <= CPT_interrupt;
					DI_interrupt <= '0';
					DO_interrupt <= '0';
					ERR_interrupt <= '0';
					DEC_interrupt <= '0';
					END_interrupt <= '0';
					DET_interrupt <= '0';
					APT_interrupt <= '0';
					CPT_interrupt <= '0';
				when 2 => -- interrupt status 2
					host_data_bus_out_buffer(0) <= ADSC_interrupt;
					host_data_bus_out_buffer(1) <= REMC_interrupt;
					host_data_bus_out_buffer(2) <= LOKC_interrupt;
					host_data_bus_out_buffer(3) <= CO_interrupt;
					host_data_bus_out_buffer(4) <= in_remote_state;
					host_data_bus_out_buffer(5) <= in_lockout_state;
					host_data_bus_out_buffer(6) <= SRQ_interrupt;
					host_data_bus_out_buffer(7) <= any_interrupt_active;
					ADSC_interrupt <= '0';
					REMC_interrupt <= '0';
					LOKC_interrupt <= '0';
					CO_interrupt <= '0';
					SRQ_interrupt <= '0';
				when 3 => -- serial poll status
					host_data_bus_out_buffer <= local_STB;
					host_data_bus_out_buffer(6) <= pending_rsv;
				when 4 => -- address status
					host_data_bus_out_buffer(0) <= minor_addressed;
					host_data_bus_out_buffer(1) <= not in_TIDS; --cb7210.2 user's guide is wrong
					host_data_bus_out_buffer(2) <= LADS_or_LACS; --cb7210.2 user's guide is wrong
					if talker_state_p2 = TPAS then
						host_data_bus_out_buffer(3) <= '1';
					else
						host_data_bus_out_buffer(3) <= '0';
					end if;
					if listener_state_p2 = LPAS then
						host_data_bus_out_buffer(4) <= '1';
					else
						host_data_bus_out_buffer(4) <= '0';
					end if;
					if talker_state_p3 = SPMS then
						host_data_bus_out_buffer(5) <= '1';
					else
						host_data_bus_out_buffer(5) <= '0';
					end if;
					host_data_bus_out_buffer(6) <= bus_ATN_inverted_in;
					host_data_bus_out_buffer(7) <= controller_in_charge_buffer;
				when 5 => -- command pass through
					if parallel_poll_result_latched = '0' then
						host_data_bus_out_buffer <= not bus_DIO_inverted_in;
					else
						host_data_bus_out_buffer <= parallel_poll_result;
					end if;
				when 6 => -- address register 0
					host_data_bus_out_buffer(4 downto 0) <= gpib_address_0;
					host_data_bus_out_buffer(5) <= not enable_listener_gpib_address_0;
					host_data_bus_out_buffer(6) <= not enable_talker_gpib_address_0;
					host_data_bus_out_buffer(7) <= gpib_to_host_byte_latched; -- provided for compatibility with old fluke gpib extension
				when 7 => -- address register 1
					host_data_bus_out_buffer(4 downto 0) <= gpib_address_1;
					host_data_bus_out_buffer(5) <= not enable_listener_gpib_address_1;
					host_data_bus_out_buffer(6) <= not enable_talker_gpib_address_1;
					host_data_bus_out_buffer(7) <= gpib_to_host_byte_end;
				when 16#9# => -- state of interrupt status register related states free from interrupt clearing logic
					host_data_bus_out_buffer(0) <= gpib_to_host_byte_latched;
					host_data_bus_out_buffer(1) <= DO_interrupt_condition;
					host_data_bus_out_buffer(2) <= CO_interrupt_condition;
					host_data_bus_out_buffer(3) <= RFD_holdoff_status;
					host_data_bus_out_buffer(4) <= end_interrupt_condition;
					host_data_bus_out_buffer (7 downto 5) <= (others => '0');
				when 16#b# => -- revision register
					host_data_bus_out_buffer <= X"ff";
				when 16#c# => -- state 1 register
					case source_handshake_state is
						when SIDS =>
							host_data_bus_out_buffer(2 downto 0) <= "000";
						when SGNS =>
							host_data_bus_out_buffer(2 downto 0) <= "001";
						when SDYS =>
							host_data_bus_out_buffer(2 downto 0) <= "010";
						when STRS =>
							host_data_bus_out_buffer(2 downto 0) <= "101";
						when SIWS =>
							host_data_bus_out_buffer(2 downto 0) <= "011";
						when SWNS =>
							host_data_bus_out_buffer(2 downto 0) <= "100";
					end case;
					case acceptor_handshake_state is
						when AIDS =>
							host_data_bus_out_buffer(5 downto 3) <= "000";
						when ANRS =>
							host_data_bus_out_buffer(5 downto 3) <= "001";
						when ACRS =>
							host_data_bus_out_buffer(5 downto 3) <= "010";
						when ACDS =>
							host_data_bus_out_buffer(5 downto 3) <= "100";
						when AWNS =>
							host_data_bus_out_buffer(5 downto 3) <= "011";
					end case;
					case talker_state_p1 is
						when TIDS =>
							host_data_bus_out_buffer(7 downto 6) <= "00";
						when TADS =>
							host_data_bus_out_buffer(7 downto 6) <= "01";
						when TACS =>
							host_data_bus_out_buffer(7 downto 6) <= "11";
						when SPAS =>
							host_data_bus_out_buffer(7 downto 6) <= "10";
					end case;
				when 16#e# => -- interrupt status 0
					host_data_bus_out_buffer <= 
						(
							2 => ATN_interrupt,
							3 => IFC_interrupt,
							others => '0'
						);
					ATN_interrupt <= '0';
					IFC_interrupt <= '0';
				when 16#f# => -- bus status register
					host_data_bus_out_buffer(0) <= bus_ATN_inverted_in;
					host_data_bus_out_buffer(1) <= bus_EOI_inverted_in;
					host_data_bus_out_buffer(2) <= bus_SRQ_inverted_in;
					host_data_bus_out_buffer(3) <= bus_IFC_inverted_in;
					host_data_bus_out_buffer(4) <= bus_REN_inverted_in;
					host_data_bus_out_buffer(5) <= bus_DAV_inverted_in;
					host_data_bus_out_buffer(6) <= bus_NRFD_inverted_in;
					host_data_bus_out_buffer(7) <= bus_NDAC_inverted_in;
				when 16#14# => -- state 2 register
					case talker_state_p2 is
						when TPIS =>
							host_data_bus_out_buffer(0) <= '0';
						when TPAS =>
							host_data_bus_out_buffer(0) <= '1';
					end case;
					case talker_state_p3 is
						when SPIS =>
							host_data_bus_out_buffer(1) <= '0';
						when SPMS =>
							host_data_bus_out_buffer(1) <= '1';
					end case;
					case listener_state_p1 is
						when LIDS =>
							host_data_bus_out_buffer(3 downto 2) <= "00";
						when LADS =>
							host_data_bus_out_buffer(3 downto 2) <= "01";
						when LACS =>
							host_data_bus_out_buffer(3 downto 2) <= "10";
					end case;
					case listener_state_p2 is
						when LPIS =>
							host_data_bus_out_buffer(4) <= '0';
						when LPAS =>
							host_data_bus_out_buffer(4) <= '1';
					end case;
					case service_request_state is
						when NPRS =>
							host_data_bus_out_buffer(6 downto 5) <= "00";
						when SRQS =>
							host_data_bus_out_buffer(6 downto 5) <= "01";
						when APRS =>
							host_data_bus_out_buffer(6 downto 5) <= "10";
					end case;
					case device_clear_state is
						when DCIS =>
							host_data_bus_out_buffer(7) <= '0';
						when DCAS =>
							host_data_bus_out_buffer(7) <= '1';
					end case;
				when 16#1c# => -- state 3 register
					case remote_local_state is
						when LOCS =>
							host_data_bus_out_buffer(1 downto 0) <= "00";
						when REMS =>
							host_data_bus_out_buffer(1 downto 0) <= "01";
						when RWLS =>
							host_data_bus_out_buffer(1 downto 0) <= "11";
						when LWLS =>
							host_data_bus_out_buffer(1 downto 0) <= "10";
					end case;
					case parallel_poll_state_p1 is
						when PPIS =>
							host_data_bus_out_buffer(3 downto 2) <= "00";
						when PPSS =>
							host_data_bus_out_buffer(3 downto 2) <= "01";
						when PPAS =>
							host_data_bus_out_buffer(3 downto 2) <= "10";
					end case;
					case parallel_poll_state_p2 is
						when PUCS =>
							host_data_bus_out_buffer(4) <= '0';
						when PACS =>
							host_data_bus_out_buffer(4) <= '1';
					end case;
					case device_trigger_state is
						when DTIS =>
							host_data_bus_out_buffer(5) <= '0';
						when DTAS =>
							host_data_bus_out_buffer(5) <= '1';
					end case;
					case controller_state_p5 is
						when SIIS =>
							host_data_bus_out_buffer(7 downto 6) <= "00";
						when SIAS =>
							host_data_bus_out_buffer(7 downto 6) <= "01";
						when SINS =>
							host_data_bus_out_buffer(7 downto 6) <= "10";
					end case;
				when 16#24# => -- state 4 register
					case controller_state_p1 is
						when CIDS =>
							host_data_bus_out_buffer(3 downto 0) <= "0000";
						when CADS =>
							host_data_bus_out_buffer(3 downto 0) <= "0010";
						when CACS =>
							host_data_bus_out_buffer(3 downto 0) <= "0011";
						when CTRS =>
							host_data_bus_out_buffer(3 downto 0) <= "0001";
						when CSBS =>
							host_data_bus_out_buffer(3 downto 0) <= "0100";
						when CSHS =>
							host_data_bus_out_buffer(3 downto 0) <= "0101";
						when CSWS =>
							host_data_bus_out_buffer(3 downto 0) <= "1000";
						when CAWS =>
							host_data_bus_out_buffer(3 downto 0) <= "0111";
						when CPWS =>
							host_data_bus_out_buffer(3 downto 0) <= "0110";
						when CPPS =>
							host_data_bus_out_buffer(3 downto 0) <= "1001";
					end case;
					case controller_state_p2 is
						when CSNS =>
							host_data_bus_out_buffer(4) <= '0';
						when CSRS =>
							host_data_bus_out_buffer(4) <= '1';
					end case;
					case controller_state_p3 is
						when SNAS =>
							host_data_bus_out_buffer(5) <= '0';
						when SACS =>
							host_data_bus_out_buffer(5) <= '1';
					end case;
					case controller_state_p4 is
						when SRIS =>
							host_data_bus_out_buffer(7 downto 6) <= "00";
						when SRAS =>
							host_data_bus_out_buffer(7 downto 6) <= "01";
						when SRNS =>
							host_data_bus_out_buffer(7 downto 6) <= "10";
					end case;
				when others =>
					host_data_bus_out_buffer <= (others => '0');
			end case;
		end host_read_register;
	
	begin
		if soft_reset = '1' then
			host_read_from_bus_state <= host_io_idle;
			host_data_bus_out_buffer <= (others => '0');
			gpib_to_host_dma_state <= dma_idle;
			gpib_to_host_byte_read <= '0';
			dma_bus_out_request <= '0';
			dma_bus_out <= (others => '0');
			prev_controller_state_p2 := CSNS;
			prev_source_handshake_state := SIDS;
			prev_in_remote_state := '0';
			prev_in_lockout_state := '0';
			prev_ATN_inverted := '0';
			prev_IFC_inverted := '0';
			prev_in_TIDS := '1';
			prev_LADS_or_LACS := '0';
			prev_controller_in_charge := '0';
			prev_gpib_to_host_byte_latched := '0';
			prev_end_interrupt_condition := '0';
			prev_APT_needs_host_response := '0';
			prev_CPT_needs_host_response := '0';
			
			ATN_interrupt <= '0';
			IFC_interrupt <= '0';
			-- isr1 interrupts
			DI_interrupt <= '0';
			DO_interrupt <= '0';
			ERR_interrupt <= '0';
			DEC_interrupt <= '0';
			END_interrupt <= '0';
			DET_interrupt <= '0';
			APT_interrupt <= '0';
			CPT_interrupt <= '0';
			-- isr2 interrupts
			ADSC_interrupt <= '0';
			REMC_interrupt <= '0';
			LOKC_interrupt <= '0';
			CO_interrupt <= '0';
			SRQ_interrupt <= '0';
		elsif rising_edge(clock) then
			-- host read from bus state machine
			case host_read_from_bus_state is
				when host_io_idle =>
					if host_read_selected = '1' then
						host_read_register(register_page, address);
						host_read_from_bus_state <= host_io_waiting_for_idle;
					else
						host_data_bus_out_buffer <= (others => '0');
					end if;
				when host_io_waiting_for_idle =>
					if host_read_selected = '0' then
						host_read_from_bus_state <= host_io_idle;
					end if;
			end case;

			-- gpib to host dma state machine
			case gpib_to_host_dma_state is
				when dma_idle =>
					dma_bus_out <= (others => '0');
					if DMA_input_enable = '1' and gpib_to_host_byte_latched = '1' then
						dma_bus_out_request <= '1';
					else
						dma_bus_out_request <= '0';
					end if;
					if dma_read_selected = '1' then
						dma_bus_out <= gpib_to_host_byte;
						gpib_to_host_byte_read <= '1';
						gpib_to_host_dma_state <= dma_waiting_for_idle;
						dma_bus_out_request <= '0';
					end if;
				when dma_waiting_for_idle =>
					if dma_read_selected = '0' then
						gpib_to_host_dma_state <= dma_idle;
					end if;
			end case;

			-- handle pulses
			if gpib_to_host_byte_read = '1' then
				gpib_to_host_byte_read <= '0';
			end if;

			-- set read-clearable interrupts
			
			if host_to_gpib_data_byte_latched = '0' then
				if prev_source_handshake_state /= SGNS and source_handshake_state = SGNS then
					if DO_interrupt_condition = '1' then
						DO_interrupt <= '1';
					end if;
				end if;
			else
				DO_interrupt <= '0';
			end if;

			if host_to_gpib_command_byte_latched = '0' then
				if prev_source_handshake_state /= SGNS and source_handshake_state = SGNS then
					if CO_interrupt_condition = '1'then
						CO_interrupt <= '1';
					end if;
				end if;
			else
				CO_interrupt <= '0';
			end if;

			if gpib_to_host_byte_latched = '1' then
				if prev_gpib_to_host_byte_latched = '0' or 
					(DI_interrupt_enable = '1' and prev_DI_interrupt_enable = '0') then
					DI_interrupt <= '1';
				end if;
			else
				DI_interrupt <= '0';
			end if;

			if end_interrupt_condition = '1' then
				if prev_end_interrupt_condition = '0' then
					END_interrupt <= '1';
				end if;
			else
				END_interrupt <= '0';
			end if;

			if entered_DCAS = '1' and DEC_interrupt_enable = '1' then
				DEC_interrupt <= '1';
			end if;
			
			if entered_DTAS = '1' and DET_interrupt_enable = '1' then
				DET_interrupt <= '1';
			end if;

			if APT_needs_host_response = '1' then
				if prev_APT_needs_host_response = '0' then
					APT_interrupt <= '1';
				end if;
			else
				APT_interrupt <= '0';
			end if;
			
			if CPT_needs_host_response = '1' then
				if prev_CPT_needs_host_response = '0' then
					CPT_interrupt <= '1';
				end if;
			else
				CPT_interrupt <= '0';
			end if;

			if to_X01(no_listeners) = '1' and ERR_interrupt_enable = '1' then
				ERR_interrupt <= '1';
			end if;

			if (prev_in_TIDS /= in_TIDS or prev_LADS_or_LACS /= LADS_or_LACS or
				prev_controller_in_charge /= controller_in_charge_buffer or
				prev_minor_addressed /= minor_addressed) and 
				ADSC_interrupt_enable = '1' then
				ADSC_interrupt <= '1';
			end if;
				
			if prev_in_remote_state /= in_remote_state and REMC_interrupt_enable = '1' then
				REMC_interrupt <= '1';
			end if;
			
			if prev_in_lockout_state /= in_lockout_state and LOKC_interrupt_enable = '1' then
				LOKC_interrupt <= '1';
			end if;

			if controller_state_p2 = CSRS then
				if prev_controller_state_p2 /= CSRS then
					SRQ_interrupt <= '1';
				end if;
			else
				SRQ_interrupt <= '0';
			end if;
			
			if bus_ATN_inverted_in = '0' then
				if prev_ATN_inverted = '1' then
					ATN_interrupt <= '1';
				end if;
			else
				ATN_interrupt <= '0';
			end if;
			
			if to_X01(prev_IFC_inverted) = '1' and to_X01(bus_IFC_inverted_in) = '0' and IFC_interrupt_enable = '1' then
				IFC_interrupt <= '1';
			end if;

			prev_controller_state_p2 := controller_state_p2;
			prev_source_handshake_state := source_handshake_state;
			prev_in_remote_state := in_remote_state;
			prev_in_lockout_state := in_lockout_state;
			prev_ATN_inverted := bus_ATN_inverted_in;
			prev_IFC_inverted := bus_IFC_inverted_in;
			prev_in_TIDS := in_TIDS;
			prev_LADS_or_LACS := LADS_or_LACS;
			prev_minor_addressed := minor_addressed;
			prev_controller_in_charge := controller_in_charge_buffer;
			prev_gpib_to_host_byte_latched := gpib_to_host_byte_latched;
			prev_end_interrupt_condition := end_interrupt_condition;
			prev_APT_needs_host_response := APT_needs_host_response;
			prev_CPT_needs_host_response := CPT_needs_host_response;
			prev_DI_interrupt_enable := DI_interrupt_enable;
		end if;
	end process;
		
	DO_interrupt_condition <= '1' when talker_state_p1 = TACS and host_to_gpib_data_byte_latched = '0' else '0';
	CO_interrupt_condition <= '1' when controller_state_p1 = CACS and host_to_gpib_command_byte_latched = '0' else '0';
	end_interrupt_condition <= gpib_to_host_byte_end or gpib_to_host_byte_eos;
	
	-- accept writes from host
	process (hard_reset, clock)
		variable send_eoi : std_logic;
		variable clear_rtl : boolean;
		variable take_control_synchronously_on_end : std_logic;
		variable prev_host_read_from_bus_state : host_io_enum;
		
		procedure execute_auxiliary_command(command : in std_logic_vector(4 downto 0)) is
		begin
			case command is
				when "00000" => -- immediate execute pon
					pon_pulse <= '1';
				when "00010" => -- chip reset
					soft_reset_pulse <= '1';
				when "00011" => -- release RFD holdoff 
					release_RFD_holdoff_pulse <= '1';
				when "00100" => -- trigger
					trigger_aux_command_pulse <= '1';
				when "00101" => -- pulse and clear rtl
					rtl <= '1';
					clear_rtl := true;
				when "01101" => -- set rtl 
					rtl <= '1';
				when "00110" => -- send EOI on next byte 
					send_eoi := '1';
				when "00111" => -- non-valid pass through secondary address 
					command_invalid <= '1';
				when "01111" => -- valid pass through secondary address 
					command_valid <= '1';
					if address_mode = "11" and APT_needs_host_response = '1' then
						minor_addressed <= minor_primary_addressed;
					end if;
				when "00001" => -- clear parallel poll flag 
					parallel_poll_flag <= '0';
				when "01001" => -- set parallel poll flag 
					parallel_poll_flag <= '1';
				when "10000" => -- go to standby
					gts <= '1';
				when "10001" => -- take control asynchronously
					tca <= '1';
				when "10010" => -- take control synchronously
					if controller_state_p1 = CSBS then -- 488.1 only allows tcs to become true during CSBS
						tcs <= '1';
					end if;
				when "11010" => -- take control synchronously on end
					take_control_synchronously_on_end := '1';
				when "10011" => -- listen (pulse)
					ltn <= '1';
					listen_with_continuous_mode <= '0';
				when "11000" => -- request rsv true, takes effect at next write to SPMR
					reqt_pending <= '1';
					reqf_pending <= '0';
				when "11001" => -- request rsv false, takes effect at next write to SPMR
					reqf_pending <= '1';
					reqt_pending <= '0';
				when "11011" => -- listen with continuous mode
					ltn <= '1';
					listen_with_continuous_mode <= '1';
				when "11100" => -- local unlisten (pulse)
					lun <= '1';
				when "10101" => -- request RFD holdoff ASAP (extension, does not take effect until out of ACRS to comply with IEEE 488.1)
					set_RFD_holdoff_pulse <= '1';
				when "11101" => -- execute parallel poll
					rpp <= '1';
				when "10110" => -- clear IFC 
					sic <= '0';
				when "11110" => -- set IFC 
					rsc <= '1';
					sic <= '1';
				when "10111" => -- clear REN 
					sre <= '0';
				when "11111" => -- set REN
					rsc <= '1';
					sre <= '1';
				when "10100" => -- disable system control (wrong in cb7210 user manual)
					rsc <= '0';
				when others =>
			end case;
		end execute_auxiliary_command;
		
		procedure write_host_to_gpib_data_byte (write_data : in std_logic_vector(7 downto 0)) is
		begin
			host_to_gpib_byte <= write_data;
			host_to_gpib_data_byte_write <= '1';
			host_to_gpib_data_byte_end <= send_eoi;
			send_eoi := '0';
		end write_host_to_gpib_data_byte;

		procedure write_host_to_gpib_command_byte (write_data : in std_logic_vector(7 downto 0)) is
		begin
			host_to_gpib_byte <= write_data;
			host_to_gpib_command_byte_write <= '1';
		end write_host_to_gpib_command_byte;

		procedure write_host_to_gpib_byte (write_data : in std_logic_vector(7 downto 0)) is
		begin
			if controller_state_p1 = CACS or controller_state_p1 = CAWS or controller_state_p1 = CSWS then
				write_host_to_gpib_command_byte(write_data);
			else
				write_host_to_gpib_data_byte(write_data);
			end if;
		end write_host_to_gpib_byte;
		
		-- process a write from the host
		procedure host_write_register (page : in std_logic_vector(3 downto 0);
			write_address : in std_logic_vector(num_address_lines - 1 downto 0);
			write_data : in std_logic_vector(7 downto 0)) is

		begin
			case flat_address(page, write_address) is
				when 0 => -- byte out register
					write_host_to_gpib_byte(write_data);
				when 1 => -- interrupt mask register 1
					DI_interrupt_enable <= write_data(0);
					DO_interrupt_enable <= write_data(1);
					ERR_interrupt_enable <= write_data(2);
					DEC_interrupt_enable <= write_data(3);
					END_interrupt_enable <= write_data(4);
					DET_interrupt_enable <= write_data(5);
					APT_interrupt_enable <= write_data(6);
					CPT_interrupt_enable <= write_data(7);
				when 2 => -- interrupt mask register 2
					ADSC_interrupt_enable <= write_data(0);
					REMC_interrupt_enable <= write_data(1);
					LOKC_interrupt_enable <= write_data(2);
					CO_interrupt_enable <= write_data(3);
					DMA_input_enable <= write_data(4);
					DMA_output_enable <= write_data(5);
					SRQ_interrupt_enable <= write_data(6);
				when 3 => -- serial poll mode
					if write_data(6) = '1' then
						set_reqt_pulse <= '1';
					else
						-- if bit 6 is transitioning from 1 to 0, then we want to issue reqf,
						-- to behave like NI tnt4882 serial poll mode SP3 (although we are
						-- still using reqt/reqf rather than setting rsv directly).
						-- if bit 6 is just sitting at 0, then we want to behave like
						-- NI tnt4882 serial poll mode SP1
						if (local_STB(6) = '1' or reqf_pending = '1') then
							set_reqf_pulse <= '1';
						elsif reqt_pending = '1' then
							set_reqt_pulse <= '1';
						end if;
					end if;
					local_STB <= write_data;
					reqt_pending <= '0';
					reqf_pending <= '0';
				when 4 => -- address mode
					address_mode <= write_data(1 downto 0);
					transmit_receive_mode <= write_data(5 downto 4);
					lon <= write_data(6);
					ton <= write_data(7);
				when 5 => -- auxiliary mode register
					case write_data(7 downto 5) is
						when "000" => -- auxiliary command
							execute_auxiliary_command(write_data(4 downto 0));
						when "001" => -- reference clock frequency
							-- TODO
						when "011" => -- parallel poll register
							local_parallel_poll_disable <= write_data(4) ;
							local_parallel_poll_sense <= write_data(3);
							local_parallel_poll_response_line <= write_data(2 downto 0);
						when "100" => -- aux A register
							case write_data(1 downto 0) is
								when "00" =>
									configured_RFD_holdoff_mode <= holdoff_normal;
								when "01" =>
									configured_RFD_holdoff_mode <= holdoff_on_all;
								when "10" =>
									configured_RFD_holdoff_mode <= holdoff_on_end;
								when "11" =>
									configured_RFD_holdoff_mode <= continuous_mode;
								when others =>
							end case;
							enable_gpib_to_host_EOS <= write_data(2);
							host_to_gpib_auto_EOI_on_EOS <= write_data(3);
							ignore_eos_bit_7 <= not write_data(4);
						when "101" => -- aux B register
							CPT_enabled <= write_data(0);
							assert_END_in_SPAS <= write_data(1);
							high_speed_T1_delay <= write_data(2);
							invert_interrupt <= write_data(3);
							use_SRQS_as_ist <= write_data(4);
						when "110" => -- aux E register
							DAC_holdoff_on_DCAS <=  write_data(0);
							DAC_holdoff_on_DTAS <= write_data(1);
						when "010" => 
							if write_data(4) = '1' then
								register_page <= write_data(3 downto 0);
							else
								ultra_fast_T1_delay <= write_data(0);
							end if;
						when "111" =>
							if write_data(4) = '1' then
							else -- aux reg I
								local_parallel_poll_config <= write_data(2);
							end if;
						when others =>
					end case;
				when 6 => -- address 0/1
					if to_bit(write_data(7)) = '1' then
						gpib_address_1 <= write_data(4 downto 0);
						enable_listener_gpib_address_1 <= not write_data(5);
						enable_talker_gpib_address_1 <= not write_data(6);
					else
						gpib_address_0 <= write_data(4 downto 0);
						enable_listener_gpib_address_0 <= not write_data(5);
						enable_talker_gpib_address_0 <= not write_data(6);
					end if;
				when 7 => -- end of string
					configured_eos_character <= write_data;
				when 8 => -- dedicated data byte out register
					write_host_to_gpib_data_byte(write_data);
				when 16#e# => -- interrupt mask register 0
					ATN_interrupt_enable <= write_data(2);
					IFC_interrupt_enable <= write_data(3);
				when 16#10# => -- dedicated command byte out register
					write_host_to_gpib_command_byte(write_data);
				when others =>
			end case;
		end host_write_register;
		
		procedure handle_command_pass_through is
			variable bus_DIO : std_logic_vector(7 downto 0);
		begin
			bus_DIO := not bus_DIO_inverted_in;
			if acceptor_handshake_state = ACDS then
				if command_passthrough_active = '1' then
					if CPT_enabled = '1' then
						CPT_needs_host_response <= '1';
					else
						command_invalid <= '1';
					end if;
				end if;
				
				if address_passthrough_active = '1' then
					case bus_DIO(6 downto 5) is
						when "10" => -- primary talk address
							case address_mode is
								when "00" =>
									command_invalid <= '1';
								when "01" =>
									if (enable_talker_gpib_address_0 = '1' and gpib_address_0 = not bus_DIO_inverted_in(4 downto 0)) then
										command_valid <= '1';
										minor_addressed <= '0';
									elsif (enable_talker_gpib_address_1 = '1' and gpib_address_1 = not bus_DIO_inverted_in(4 downto 0)) then
										command_valid <= '1';
										minor_addressed <= '1';
									else
										command_invalid <= '1';
									end if;
								when "10" =>
									if enable_talker_gpib_address_0 = '1' and gpib_address_0 = not bus_DIO_inverted_in(4 downto 0) then
										command_valid <= '1';
									else
										command_invalid <= '1';
									end if;
								when "11" =>
									if (enable_talker_gpib_address_0 = '1' and gpib_address_0 = not bus_DIO_inverted_in(4 downto 0)) or
										(enable_talker_gpib_address_1 = '1' and gpib_address_1 = not bus_DIO_inverted_in(4 downto 0)) then
										command_valid <= '1';
										minor_primary_addressed <= '1';
									else
										command_invalid <= '1';
									end if;
								when others =>
							end case;
						when "01" => -- primary listen address
							case address_mode is
								when "00" =>
									command_invalid <= '1';
								when "01" =>
									if (enable_listener_gpib_address_0 = '1' and gpib_address_0 = not bus_DIO_inverted_in(4 downto 0)) then
										command_valid <= '1';
										minor_addressed <= '0';
									elsif (enable_listener_gpib_address_1 = '1' and gpib_address_1 = not bus_DIO_inverted_in(4 downto 0)) then
										command_valid <= '1';
										minor_addressed <= '1';
									else
										command_invalid <= '1';
									end if;
								when "10" =>
									if enable_listener_gpib_address_0 = '1' and gpib_address_0 = not bus_DIO_inverted_in(4 downto 0) then
										command_valid <= '1';
									else
										command_invalid <= '1';
									end if;
								when "11" =>
									if (enable_listener_gpib_address_0 = '1' and gpib_address_0 = not bus_DIO_inverted_in(4 downto 0)) or
										(enable_listener_gpib_address_1 = '1' and gpib_address_1 = not bus_DIO_inverted_in(4 downto 0)) then
										command_valid <= '1';
										minor_primary_addressed <= '1';
									else
										command_invalid <= '1';
									end if;
								when others =>
							end case;
						when "11" => -- secondary address
							case address_mode is
								when "00" =>
									command_invalid <= '1';
								when "01" =>
									command_invalid <= '1';
								when "10" =>
									if gpib_address_1 = not bus_DIO_inverted_in(4 downto 0) and
										gpib_address_1 /= NO_ADDRESS_CONFIGURED then
										command_valid <= '1';
										minor_addressed <= '0';
									else
										command_invalid <= '1';
									end if;
								when "11" =>
									APT_needs_host_response <= '1';
								when others =>
							end case;
						when others =>
					end case;
				end if;
			else -- not ACDS
				command_valid <= '0';
				command_invalid <= '0';
				APT_needs_host_response <= '0';
				CPT_needs_host_response <= '0';
			end if;
			
		end handle_command_pass_through;
		
		procedure handle_soft_reset( do_reset : std_logic )is
		begin
			if do_reset = '1' then
				
				local_STB <= (others => '0');
				gts <= '0';
				rsc <= '0';
				reqt_pending <= '0';
				reqf_pending <= '0';
				set_reqt_pulse <= '0';
				set_reqf_pulse <= '0';
				lon <= '0';
				local_parallel_poll_disable <= '1';
				ltn <= '0';
				lun <= '0';
				rpp <= '0';
				rtl <= '0';
				sre <= '0';
				sic <= '0';
				tca <= '0';
				tcs <= '0';
				take_control_synchronously_on_end := '0';
				ton <= '0';
				transmit_receive_mode <= "00";
				address_mode <= "00";
				ultra_fast_T1_delay <= '0';
				high_speed_T1_delay <= '0';
				gpib_address_0 <= (others => '0');
				enable_talker_gpib_address_0 <= '0';
				enable_listener_gpib_address_0 <= '0';
				gpib_address_1 <= (others => '0');
				enable_talker_gpib_address_1 <= '0';
				enable_listener_gpib_address_1 <= '0';
				host_to_gpib_byte <= (others => '0');
				host_to_gpib_data_byte_end <= '0';
				host_to_gpib_data_byte_write <= '0';
				host_to_gpib_command_byte_write <= '0';
				send_eoi := '0';
				invert_interrupt <= '0';
				ignore_eos_bit_7 <= '0';
				parallel_poll_flag <= '0';
				use_SRQS_as_ist <= '0';
				host_to_gpib_auto_EOI_on_EOS <= '0';
				configured_eos_character <= (others => '0');
				local_parallel_poll_config <= '0';
				local_parallel_poll_sense <= '0';
				local_parallel_poll_response_line <= (others => '0');
				command_valid <= '0';
				command_invalid <= '0';
				APT_needs_host_response <= '0';
				CPT_needs_host_response <= '0';
				CPT_enabled <= '0';
				minor_addressed <= '0';
				minor_primary_addressed <= '0';
				listen_with_continuous_mode <= '0';
				assert_END_in_SPAS <= '0';
				DAC_holdoff_on_DCAS <= '0';
				DAC_holdoff_on_DTAS <= '0';
				
				-- imr0 enables
				ATN_interrupt_enable <= '0';
				IFC_interrupt_enable <= '0';
				--imr1 enables
				DI_interrupt_enable <= '0';
				DO_interrupt_enable <= '0';
				ERR_interrupt_enable <= '0';
				DEC_interrupt_enable <= '0';
				END_interrupt_enable <= '0';
				DET_interrupt_enable <= '0';
				APT_interrupt_enable <= '0';
				CPT_interrupt_enable <= '0';
				--imr2 enables
				ADSC_interrupt_enable <= '0';
				REMC_interrupt_enable <= '0';
				LOKC_interrupt_enable <= '0';
				CO_interrupt_enable <= '0';
				DMA_input_enable <= '0';
				DMA_output_enable <= '0';
				SRQ_interrupt_enable <= '0';

				enable_gpib_to_host_EOS <= '0';
				configured_RFD_holdoff_mode <= holdoff_normal;
			end if;
		end handle_soft_reset;
	begin

		if hard_reset = '1' then
			host_write_to_bus_state <= host_io_idle;
			prev_host_read_from_bus_state := host_io_idle;
			host_to_gpib_dma_state <= dma_idle;
			register_page <= (others => '0');
			pon_pulse <= '0';
			soft_reset_pulse <= '0';
			dma_bus_in_request <= '0';
			release_RFD_holdoff_pulse <= '0';
			set_RFD_holdoff_pulse <= '0';
			trigger_aux_command_pulse <= '0';
			clear_rtl := false;
			handle_soft_reset('1');
		elsif rising_edge(clock) then
			-- host write_to bus state machine
			case host_write_to_bus_state is
				when host_io_idle =>
					if host_write_selected = '1' then
						-- clear register page after writes.  Do it on the line before
						-- calling host_write_register since we want to allow a write to
						-- the page select to set a new register page
						register_page <= (others => '0'); 
						host_write_register(register_page, address, to_X01(host_data_bus_in));
						host_write_to_bus_state <= host_io_waiting_for_idle;
					end if;
				when host_io_waiting_for_idle =>
					if host_write_selected = '0' then
						host_write_to_bus_state <= host_io_idle;
					end if;
			end case;

			-- host to gpib dma state machine
			case host_to_gpib_dma_state is
				when dma_idle =>
					if DMA_output_enable = '1' and host_to_gpib_data_byte_latched = '0' then
						dma_bus_in_request <= '1';
					else
						dma_bus_in_request <= '0';
					end if;
					if dma_write_selected = '1' then
						write_host_to_gpib_data_byte(dma_bus_in);
						host_to_gpib_dma_state <= dma_waiting_for_idle;
						dma_bus_in_request <= '0';
					end if;
				when dma_waiting_for_idle =>
					if dma_write_selected = '0' then
						host_to_gpib_dma_state <= dma_idle;
					end if;
			end case;

			handle_command_pass_through;
			
			if take_control_synchronously_on_end = '1' and acceptor_handshake_state = ACDS and 
				(gpib_to_host_byte_end or gpib_to_host_byte_eos) = '1' then
				if controller_state_p1 = CSBS then -- 488.1 only allows tcs to become true during CSBS
					take_control_synchronously_on_end := '0';
					tcs <= '1';
				end if;
			end if;
			
			-- handle pulses
			if host_to_gpib_data_byte_write = '1' then
				host_to_gpib_data_byte_write <= '0';
			end if;
			if host_to_gpib_command_byte_write = '1' then
				host_to_gpib_command_byte_write <= '0';
			end if;
			if soft_reset_pulse /= '0' then 
				soft_reset_pulse <= '0';
			end if;
			if pon_pulse /= '0' then 
				pon_pulse <= '0';
			end if;
			if release_RFD_holdoff_pulse /= '0' then
				release_RFD_holdoff_pulse <= '0';
			end if;
			if set_RFD_holdoff_pulse /= '0' then
				set_RFD_holdoff_pulse <= '0';
			end if;
			if trigger_aux_command_pulse /= '0' then
				trigger_aux_command_pulse <= '0';
			end if;
			if ltn /= '0' then
				ltn <= '0';
			end if;
			if lun /= '0' then
				lun <= '0';
			end if;
			if set_reqt_pulse = '1' then
				set_reqt_pulse <= '0';
			end if;
			if set_reqf_pulse = '1' then
				set_reqf_pulse <= '0';
			end if;
			if rtl /= '0' and clear_rtl then
				rtl <= '0';
				clear_rtl := false;
			end if;
			
			if controller_state_p1 /= CACS then
				gts <= '0';
			end if;
			if controller_state_p1 = CAWS then -- 488.1 only allows tcs to go false during CAWS
				tcs <= '0';
				tca <= '0';
			end if;
			if controller_state_p1 = CPPS or controller_state_p1 = CIDS then 
				rpp <= '0';
			end if;
			
			if listen_with_continuous_mode = '1' and ltn = '0' and listener_state_p1 = LIDS then
				listen_with_continuous_mode <= '0';
			end if;
			
			-- clear register page after read (we clear it after writes above)
			if host_read_from_bus_state = host_io_waiting_for_idle and 
				prev_host_read_from_bus_state /=  host_io_waiting_for_idle then
				register_page <= (others => '0');
			end if;
			prev_host_read_from_bus_state := host_read_from_bus_state;
			
			handle_soft_reset(soft_reset);
		end if;
	end process;	

	RFD_holdoff_mode <= continuous_mode when listen_with_continuous_mode = '1' else
		configured_RFD_holdoff_mode;
	
	-- set timing counters
	first_T1_terminal_count <= T1_clock_ticks_1100ns when ultra_fast_T1_delay = '1' and controller_state_p1 /= CACS else
		T1_clock_ticks_2us;
	T1_terminal_count <= T1_clock_ticks_2us when controller_state_p1 = CACS else
		T1_clock_ticks_350ns when ultra_fast_T1_delay = '1' else
		T1_clock_ticks_500ns when high_speed_T1_delay = '1' else
		T1_clock_ticks_2us;
	
	-- enable_secondary_addressing as appropriate
	process (soft_reset, clock)
	begin
		if soft_reset = '1' then
			enable_secondary_addressing <= '0';
		elsif rising_edge(clock) then
			case address_mode is
				when "00" =>
					enable_secondary_addressing <= '0';
				when "01" =>
					enable_secondary_addressing <= '0';
				when "10" =>
					enable_secondary_addressing <= '1';
				when "11" =>
					enable_secondary_addressing <= '1';
				when others =>
			end case;
		end if;
	end process;

	lpe <= local_parallel_poll_config and not local_parallel_poll_disable;
	
	controller_in_charge_buffer <= '0' when controller_state_p1 = CIDS or controller_state_p1 = CADS else '1';
	not_controller_in_charge <= not controller_in_charge_buffer;

	pullup_disable <= pullup_disable_buffer;
	
	EOI_output_enable <= EOI_output_enable_buffer;

	system_controller <= '1' when controller_state_p3 = SACS else '0';
	
	trigger_buffer <= '1' when entered_DTAS = '1' or
		trigger_aux_command_pulse = '1' else '0';
	trigger <= trigger_buffer;
	
	tr1 <= talk_enable_buffer;
	process (soft_reset, clock)
	begin
		if soft_reset = '1' then
			tr2 <= '0';
			tr3 <= '0';
		elsif rising_edge(clock) then
			case transmit_receive_mode is
				when "00" =>
					tr2 <= EOI_output_enable_buffer;
					tr3 <= trigger_buffer;
				when "01" =>
					tr2 <= controller_in_charge_buffer;
					tr3 <= trigger_buffer;
				when "10" =>
					tr2 <= controller_in_charge_buffer;
					tr3 <= EOI_output_enable_buffer;
				when "11" =>
					tr2 <= controller_in_charge_buffer;
					tr3 <= pullup_disable_buffer;
				when others =>
					tr2 <= 'X';
					tr3 <= 'X';
			end case;
		end if;
	end process;
		
	interrupt <= any_interrupt_active xor invert_interrupt;
	
	any_interrupt_active <= 
		(DI_interrupt and DI_interrupt_enable) or
		(DO_interrupt and DO_interrupt_enable) or
		(ERR_interrupt and ERR_interrupt_enable) or
		(DEC_interrupt and DEC_interrupt_enable) or
		(END_interrupt and END_interrupt_enable) or
		(DET_interrupt and DET_interrupt_enable) or
		(APT_interrupt and APT_interrupt_enable) or
		(CPT_interrupt and CPT_interrupt_enable) or
		(ADSC_interrupt and ADSC_interrupt_enable) or
		(REMC_interrupt and REMC_interrupt_enable) or
		(LOKC_interrupt and LOKC_interrupt_enable) or
		(CO_interrupt and CO_interrupt_enable) or
		(SRQ_interrupt and SRQ_interrupt_enable) or
		(ATN_interrupt and ATN_interrupt_enable) or
		(IFC_interrupt and IFC_interrupt_enable);
	
	in_remote_state <= '1' when remote_local_state = REMS or remote_local_state = RWLS else '0';
	in_lockout_state <= '1' when remote_local_state = RWLS or remote_local_state = LWLS else '0';
	LADS_or_LACS <= '1' when listener_state_p1 = LADS or listener_state_p1 = LACS else '0';
	in_TIDS <= '1' when talker_state_p1 = TIDS else '0';
	
	ist <= parallel_poll_flag when use_SRQS_as_ist = '0' else
		'1' when service_request_state = SRQS else
		'0';

	process (soft_reset, clock)
		variable prev_device_trigger_state : DT_state;
	begin
		if soft_reset = '1' then
			entered_DTAS <= '0';
			prev_device_trigger_state := DTIS;
		elsif rising_edge(clock) then
			if prev_device_trigger_state /= DTAS and device_trigger_state = DTAS then
				entered_DTAS <= '1';
			else
				entered_DTAS <= '0';
			end if;
			prev_device_trigger_state := device_trigger_state;
		end if;
	end process;

	process (soft_reset, clock)
		variable prev_device_clear_state : DC_state;
	begin
		if soft_reset = '1' then
			entered_DCAS <= '0';
			prev_device_clear_state := DCIS;
		elsif rising_edge(clock) then
			if prev_device_clear_state /= DCAS and device_clear_state = DCAS then
				entered_DCAS <= '1';
			else
				entered_DCAS <= '0';
			end if;
			prev_device_clear_state := device_clear_state;
		end if;
	end process;
	
	process (soft_reset, clock)
	begin
		if soft_reset = '1' then
			parallel_poll_result <= (others => '0');
			parallel_poll_result_latched <= '0';
		elsif rising_edge(clock) then
			if controller_state_p1 = CPPS then
				parallel_poll_result <= not bus_DIO_inverted_in;
				parallel_poll_result_latched <= '1';
			-- once the next byte is accepted, we need to stop returning the
			-- parallel poll result in the command pass through register, since
			-- we might be receiving a pass through command.  We've given the
			-- host plenty of time to read the parallel poll result at this point.
			-- really the nec7210 should have been designed to just make the rpp
			-- message set/clear instead of a pulse to keep the controller in
			-- CPPS as long as it needed, but oh well.
			elsif acceptor_handshake_state = ACDS then
				parallel_poll_result_latched <= '0';
			end if;
		end if;
	end process;
end frontend_cb7210p2_arch;
