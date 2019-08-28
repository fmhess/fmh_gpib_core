-- IEEE 488.1 interface functions all wired together.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017, 2019


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.acceptor_fifo;
use work.interface_function_common.all;
use work.interface_function_AH;
use work.interface_function_C;
use work.interface_function_CF;
use work.interface_function_DC;
use work.interface_function_DT;
use work.interface_function_LE;
use work.interface_function_PP;
use work.interface_function_RL;
use work.interface_function_SHE;
use work.interface_function_SR;
use work.interface_function_TE;
use work.remote_message_decoder;

entity integrated_interface_functions is
	generic(
			num_counter_bits : in integer := 8
		);
	port(
		clock : in std_logic;
		
		bus_DIO_inverted_in : in std_logic_vector(7 downto 0);
		bus_REN_inverted_in : in std_logic;
		bus_IFC_inverted_in : in std_logic;
		bus_SRQ_inverted_in : in std_logic;
		bus_EOI_inverted_in : in std_logic;
		bus_ATN_inverted_in : in std_logic;
		bus_NDAC_inverted_in : in std_logic;
		bus_NRFD_inverted_in : in std_logic;
		bus_DAV_inverted_in : in std_logic;

		-- IEEE 488.1 local messages
		ist : in std_logic;
		gts : in std_logic;
		force_lni : in std_logic := '1';
		lon : in std_logic;
		lpe : in std_logic;
		lun : in std_logic;
		ltn : in std_logic;
		nie : in std_logic := '0';
		pon : in std_logic;
		rpp : in std_logic;
		rsc : in std_logic;
		rtl : in std_logic;
		sre : in std_logic;
		sic : in std_logic;
		tca : in std_logic;
		tcs : in std_logic;
		ton : in std_logic;
		set_reqt_pulse : in std_logic;
		set_reqf_pulse : in std_logic;

		configured_eos_character : in std_logic_vector(7 downto 0);
		ignore_eos_bit_7 : in std_logic;
		command_valid : in std_logic;
		command_invalid : in std_logic;
		enable_secondary_addressing : in std_logic;
		local_parallel_poll_config : in std_logic;
		local_parallel_poll_sense : in std_logic;
		local_parallel_poll_response_line : in std_logic_vector(2 downto 0);
		first_T1_terminal_count : in unsigned(num_counter_bits - 1 downto 0);
		T1_terminal_count : in unsigned(num_counter_bits - 1 downto 0);
		T6_terminal_count : in unsigned(num_counter_bits - 1 downto 0);
		T7_terminal_count : in unsigned(num_counter_bits - 1 downto 0);
		T8_count_per_us : in unsigned(num_counter_bits - 1 downto 0);
		T9_terminal_count : in unsigned(num_counter_bits - 1 downto 0);
		T10_terminal_count : in unsigned(num_counter_bits - 1 downto 0);
		check_for_listeners : in std_logic;
		-- host should set gpib_to_host_byte_read high for a clock when it reads gpib_to_host_byte
		gpib_to_host_byte_read : in std_logic;
		enable_gpib_to_host_EOS : in std_logic;
		host_to_gpib_byte : in std_logic_vector(7 downto 0);
		host_to_gpib_data_byte_end : in std_logic;
		host_to_gpib_auto_EOI_on_EOS : in std_logic;
		host_to_gpib_data_byte_write : in std_logic;
		host_to_gpib_command_byte_write : in std_logic;
		local_STB : in std_logic_vector(7 downto 0);
		RFD_holdoff_mode : in RFD_holdoff_enum;
		-- pulse to set rfd holdoff (does not cause rdy to go false until out of ACRS, to comply with IEEE 488.1)
		set_RFD_holdoff_pulse : in std_logic;
		-- pulse to release rfd holdoff
		release_RFD_holdoff_pulse : in std_logic;
		DAC_holdoff_on_DTAS : in std_logic;
		DAC_holdoff_on_DCAS : in std_logic;
		assert_END_in_SPAS : in std_logic;
		
		address_passthrough : out std_logic; 
		command_passthrough : out std_logic; 
		bus_DIO_inverted_out : out std_logic_vector(7 downto 0);
		bus_REN_inverted_out : out std_logic;
		bus_IFC_inverted_out : out std_logic;
		bus_SRQ_inverted_out : out std_logic;
		bus_EOI_inverted_out : out std_logic;
		bus_ATN_inverted_out : out std_logic;
		bus_NDAC_inverted_out : out std_logic;
		bus_NRFD_inverted_out : out std_logic;
		bus_DAV_inverted_out : out std_logic;
		acceptor_handshake_state : out AH_state;
		controller_state_p1 : out C_state_p1;
		controller_state_p2 : out C_state_p2;
		controller_state_p3 : out C_state_p3;
		controller_state_p4 : out C_state_p4;
		controller_state_p5 : out C_state_p5;
		device_clear_state : out DC_state;
		device_trigger_state : out DT_state;
		listener_state_p1 : out LE_state_p1;
		listener_state_p2 : out LE_state_p2;
		parallel_poll_state_p1 : out PP_state_p1;
		parallel_poll_state_p2 : out PP_state_p2;
		remote_local_state : out RL_state;
		service_request_state : out SR_state;
		source_handshake_state : out SH_state;
		talker_state_p1 : out TE_state_p1;
		talker_state_p2 : out TE_state_p2;
		talker_state_p3 : out TE_state_p3;
		configuration_state_p1 : out CF_state_p1;
		configuration_state_p1_num_meters : out unsigned(3 downto 0);
		configuration_state_p2 : out CF_state_p2;
		no_listeners : out std_logic;
		gpib_to_host_byte : out std_logic_vector(7 downto 0);
		gpib_to_host_byte_eos : out std_logic;
		gpib_to_host_byte_end : out std_logic;
		-- gpib_to_host_byte_latched true means a new gpib to host byte is available to be read by host
		gpib_to_host_byte_latched : out std_logic;
		-- host_to_gpib_data_byte_latched false means a new host to gpib byte can be written by host
		host_to_gpib_data_byte_latched : out std_logic;
		host_to_gpib_command_byte_latched : out std_logic;
		talk_enable : out std_logic;
		pullup_disable : out std_logic;
		EOI_output_enable : out std_logic;
		virtual_RFD_holdoff_status : out std_logic;
		pending_rsv : out std_logic
	);
 
end integrated_interface_functions;
 
architecture integrated_interface_functions_arch of integrated_interface_functions is
	signal lni : std_logic;
	signal rft : std_logic;
	signal rsv : std_logic;
	signal reqt : std_logic;
	signal reqf : std_logic;
	signal set_rsv_state : set_rsv_enum;
	signal internal_host_to_gpib_data_byte_latched : std_logic;
	signal internal_host_to_gpib_data_byte : std_logic_vector(7 downto 0);
	signal internal_host_to_gpib_data_byte_end : std_logic;
	signal internal_host_to_gpib_command_byte_latched : std_logic;
	signal internal_host_to_gpib_command_byte : std_logic_vector(7 downto 0);
	-- A fake RFD holdoff to hide the fact that RFD holdoffs don't happen
	-- immediately for noninterlaced acceptor handshake.  Needed to preserve
	-- the appearance of how nec 7210 holdoff modes (other than normal mode) work, since
	-- additional data bytes may be received before a RFD holdoff can actually stop the
	-- data flow.  The real RFD_holdoff is cleared only when both the virtual_RFD_holdoff is
	-- false and the acceptor_fifo is empty.
	signal virtual_RFD_holdoff : std_logic;
	signal RFD_holdoff : std_logic;
	signal combined_RFD_holdoff : std_logic; -- holdoff due to combination of a requested RFD_holdoff or an unread data byte
	signal DAC_holdoff : std_logic;
	signal unrecognized_primary_command : std_logic;
	signal address_passthrough_buffer : std_logic;
	signal command_passthrough_buffer : std_logic;
	
	signal ATN : std_logic;
	signal CFE : std_logic;
	signal CFGn : std_logic;
	signal CFGn_meters : unsigned(3 downto 0);
	signal DAC : std_logic;
	signal DAV : std_logic;
	signal DCL : std_logic;
	signal END_msg: std_logic;
	signal EOS: std_logic;
	signal GET : std_logic;
	signal GTL : std_logic;
	signal IDY : std_logic;
	signal IFC : std_logic;
	signal LAG : std_logic;
	signal LLO : std_logic;
	signal MLA : std_logic;
	signal MTA : std_logic;
	signal MSA : std_logic;
	signal NIC : std_logic;
	signal OSA : std_logic;
	signal OTA : std_logic;
	signal PCG : std_logic;
	signal PPC : std_logic;
	signal PPE : std_logic;
	signal PPE_sense : std_logic;
	signal PPE_response_line : std_logic_vector(2 downto 0);
	signal PPD : std_logic;
	signal PPU : std_logic;
	signal REN : std_logic;
	signal RFD : std_logic;
	signal SCG : std_logic;
	signal SDC : std_logic;
	signal SPD : std_logic;
	signal SPE : std_logic;
	signal SRQ : std_logic;
	signal TCT : std_logic;
	signal TAG : std_logic;
	signal UNL : std_logic;
	signal UNT : std_logic;
	signal local_PPR : std_logic_vector(7 downto 0);
	signal local_ATN : std_logic;
	signal local_DAC : std_logic;
	signal local_DAV : std_logic;
	signal local_END : std_logic;
	signal local_IFC : std_logic;
	signal local_NIC : std_logic;
	signal local_REN : std_logic;
	signal local_RFD : std_logic;
	signal local_RQS : std_logic;
	signal local_SRQ : std_logic;
	signal local_IDY : std_logic;
	signal local_TCT : std_logic;
	
	signal acceptor_handshake_state_buffer : AH_state;
	signal controller_state_p1_buffer : C_state_p1;
	signal controller_state_p2_buffer : C_state_p2;
	signal controller_state_p3_buffer : C_state_p3;
	signal controller_state_p4_buffer : C_state_p4;
	signal controller_state_p5_buffer : C_state_p5;
	signal device_clear_state_buffer : DC_state;
	signal device_trigger_state_buffer : DT_state;
	signal listener_state_p1_buffer : LE_state_p1;
	signal listener_state_p2_buffer : LE_state_p2;
	signal parallel_poll_state_p1_buffer : PP_state_p1;
	signal parallel_poll_state_p2_buffer : PP_state_p2;
	signal remote_local_state_buffer : RL_state;
	signal source_handshake_state_buffer : SH_state;
	signal service_request_state_buffer : SR_state;
	signal talker_state_p1_buffer : TE_state_p1;
	signal talker_state_p2_buffer : TE_state_p2;
	signal talker_state_p3_buffer : TE_state_p3;
	signal bus_dio_inverted_out_buffer : std_logic_vector(7 downto 0);
	signal bus_DIO_in : std_logic_vector(7 downto 0);
	
	signal talk_enable_buffer : std_logic;
	signal pullup_disable_buffer : std_logic;
	signal EOI_output_enable_buffer : std_logic;
	
	signal status_byte_buffer : std_logic_vector(7 downto 0);
	
	signal parallel_poll_sense : std_logic;
	signal parallel_poll_response_line : std_logic_vector(2 downto 0);
	
	signal acceptor_fifo_write : std_logic;
	signal acceptor_fifo_empty : std_logic;
	signal acceptor_fifo_end : std_logic;
	signal acceptor_fifo_eos : std_logic;
	signal acceptor_fifo_in_virtual_holdoff : std_logic;
	
	signal configuration_state_p1_buffer : CF_state_p1;
	
	begin
	my_decoder: entity work.remote_message_decoder 
		port map (
			bus_DIO_inverted => bus_DIO_inverted_in,
			bus_REN_inverted => bus_REN_inverted_in,
			bus_IFC_inverted => bus_IFC_inverted_in,
			bus_SRQ_inverted => bus_SRQ_inverted_in,
			bus_EOI_inverted => bus_EOI_inverted_in,
			bus_ATN_inverted => bus_ATN_inverted_in,
			bus_NDAC_inverted => bus_NDAC_inverted_in,
			bus_NRFD_inverted => bus_NRFD_inverted_in,
			bus_DAV_inverted => bus_DAV_inverted_in,
			configured_eos_character => configured_eos_character,
			ignore_eos_bit_7 => ignore_eos_bit_7,
			command_valid => command_valid,
			command_invalid => command_invalid,
			enable_EOS_detection => enable_gpib_to_host_EOS,
			ATN => ATN,
			CFE => CFE,
			CFGn => CFGn,
			CFGn_meters => CFGn_meters,
			DAC => DAC,
			DAV => DAV,
			DCL => DCL,
			END_msg => END_msg,
			EOS => EOS,
			GET => GET,
			GTL => GTL,
			IDY => IDY,
			IFC => IFC,
			LAG => LAG,
			LLO => LLO,
			MLA => MLA,
			MTA => MTA,
			MSA => MSA,
			NIC => NIC,
			OSA => OSA,
			OTA => OTA,
			PCG => PCG,
			PPC => PPC,
			PPE => PPE,
			PPE_sense => PPE_sense,
			PPE_response_line => PPE_response_line,
			PPD => PPD,
			PPU => PPU,
			REN => REN,
			RFD => RFD,
			SCG => SCG,
			SDC => SDC,
			SPD => SPD,
			SPE => SPE,
			SRQ => SRQ,
			TCT => TCT,
			TAG => TAG,
			UNL => UNL,
			UNT => UNT,
			unrecognized_primary_command => unrecognized_primary_command
		);

	my_AH: entity work.interface_function_AH 
		generic map (num_counter_bits => num_counter_bits)
		port map (
			clock => clock,
			listener_state_p1 => listener_state_p1_buffer,
			ATN => ATN,
			DAV => DAV,
			NIC => NIC,
			lni => lni,
			pon => pon,
			rft => rft,
			tcs => tcs,
			DAC_holdoff => DAC_holdoff,
			RFD_holdoff => combined_RFD_holdoff,
			acceptor_handshake_state => acceptor_handshake_state_buffer,
			RFD => local_RFD,
			DAC => local_DAC
		);

	my_DC: entity work.interface_function_DC 
		port map (
			acceptor_handshake_state => acceptor_handshake_state_buffer,
			listener_state_p1 => listener_state_p1_buffer,
			DCL => DCL,
			SDC => SDC,
			device_clear_state => device_clear_state_buffer
		);

	my_DT: entity work.interface_function_DT 
		port map (
			acceptor_handshake_state => acceptor_handshake_state_buffer,
			listener_state_p1 => listener_state_p1_buffer,
			GET => GET,
			device_trigger_state => device_trigger_state_buffer
		);

	my_LE: entity work.interface_function_LE 
		port map (
			clock => clock,
			acceptor_handshake_state => acceptor_handshake_state_buffer,
			controller_state_p1 => controller_state_p1_buffer,
			talker_state_p2 => talker_state_p2_buffer,
			ATN => ATN,
			IFC => IFC,
			pon => pon,
			ltn => ltn,
			lon => lon,
			lun => lun,
			UNL => UNL,
			MLA => MLA,
			MSA => MSA,
			PCG => PCG,
			MTA => MTA,
			enable_secondary_addressing => enable_secondary_addressing,
			listener_state_p1 => listener_state_p1_buffer,
			listener_state_p2 => listener_state_p2_buffer
		);

	my_PP: entity work.interface_function_PP 
		port map (
			clock => clock,
			acceptor_handshake_state => acceptor_handshake_state_buffer,
			listener_state_p1 => listener_state_p1_buffer,
			ATN => ATN,
			PPC => PPC,
			PPD => PPD,
			PPE => PPE,
			PPU => PPU,
			IDY => IDY,
			pon => pon,
			lpe => lpe,
			ist => ist,
			sense => parallel_poll_sense,
			PCG => PCG,
			local_configuration_mode => local_parallel_poll_config,
			PPR_line => parallel_poll_response_line,
			PPR => local_PPR,
			parallel_poll_state_p1 => parallel_poll_state_p1_buffer,
			parallel_poll_state_p2 => parallel_poll_state_p2_buffer
		);

	my_RL: entity work.interface_function_RL 
		port map (
			clock => clock,
			acceptor_handshake_state => acceptor_handshake_state_buffer,
			listener_state_p1 => listener_state_p1_buffer,
			listener_state_p2 => listener_state_p2_buffer,
			pon => pon,
			rtl => rtl,
			REN => REN,
			LLO => LLO,
			GTL => GTL,
			MLA => MLA,
			MSA => MSA,
			enable_secondary_addressing => enable_secondary_addressing,
			remote_local_state => remote_local_state_buffer
		);

	my_SH : entity work.interface_function_SHE
		generic map (num_counter_bits => num_counter_bits)
		port map (
			clock => clock,
			talker_state_p1 => talker_state_p1_buffer,
			controller_state_p1 => controller_state_p1_buffer,
			configuration_state_p1 => configuration_state_p1_buffer,
			ATN => ATN,
			DAC => DAC,
			IFC => IFC,
			RFD => RFD,
			command_byte_available => internal_host_to_gpib_command_byte_latched ,
			data_byte_available => internal_host_to_gpib_data_byte_latched ,
			nie => nie,
			pon => pon,
			first_T1_terminal_count => first_T1_terminal_count,
			T1_terminal_count => T1_terminal_count,
			check_for_listeners => check_for_listeners,
			
			source_handshake_state => source_handshake_state_buffer,
			DAV => local_DAV,
			NIC => local_NIC,
			no_listeners => no_listeners
		);

	my_SR: entity work.interface_function_SR 
		port map (
			clock => clock,
			talker_state_p1 => talker_state_p1_buffer,
			pon => pon,
			rsv => rsv,
			service_request_state => service_request_state_buffer,
			SRQ => local_SRQ
		);

	my_set_rsv: entity work.set_rsv_488_2
		port map (
			clock => clock,
			pon => pon,
			service_request_state => service_request_state_buffer,
			set_reqt_pulse => set_reqt_pulse,
			set_reqf_pulse => set_reqf_pulse,
			rsv => rsv,
			reqt => reqt,
			reqf => reqf,
			set_rsv_state => set_rsv_state
		);
		
	my_TE: entity work.interface_function_TE 
		port map (
			clock => clock,
			acceptor_handshake_state => acceptor_handshake_state_buffer,
			listener_state_p2 => listener_state_p2_buffer,
			service_request_state => service_request_state_buffer,
			source_handshake_state => source_handshake_state_buffer,
			ATN => ATN,
			IFC => IFC,
			pon => pon,
			ton => ton,
			MTA => MTA,
			MSA => MSA,
			OTA => OTA,
			OSA => OSA,
			MLA => MLA,
			SPE => SPE,
			SPD => SPD,
			PCG => PCG,
			enable_secondary_addressing => enable_secondary_addressing,
			host_to_gpib_data_byte_end => internal_host_to_gpib_data_byte_end,
			assert_END_in_SPAS => assert_END_in_SPAS,
			talker_state_p1 => talker_state_p1_buffer,
			talker_state_p2 => talker_state_p2_buffer,
			talker_state_p3 => talker_state_p3_buffer,
			END_msg => local_END,
			RQS => local_RQS
		);
		
	my_C: entity work.interface_function_C
		generic map (num_counter_bits => num_counter_bits)
		port map (
			clock => clock,
			pon => pon,
			gts => gts,
			rpp => rpp,
			rsc => rsc,
			sre => sre,
			sic => sic,
			tca => tca,
			tcs => tcs,
			ATN_in => ATN,
			IFC_in => IFC,
			SRQ_in => SRQ,
			TCT_in => TCT,
			ATN_out => local_ATN,
			IDY_out => local_IDY,
			IFC_out => local_IFC,
			REN_out => local_REN,
			TCT_out => local_TCT,
			T6_terminal_count => T6_terminal_count,
			T7_terminal_count => T7_terminal_count,
			T8_count_per_us => T8_count_per_us,
			T9_terminal_count => T9_terminal_count,
			T10_terminal_count => T10_terminal_count,
			acceptor_handshake_state => acceptor_handshake_state_buffer,
			source_handshake_state => source_handshake_state_buffer,
			talker_state_p1 => talker_state_p1_buffer,
			controller_state_p1 => controller_state_p1_buffer,
			controller_state_p2 => controller_state_p2_buffer,
			controller_state_p3 => controller_state_p3_buffer,
			controller_state_p4 => controller_state_p4_buffer,
			controller_state_p5 => controller_state_p5_buffer
		);

	my_CF : entity work.interface_function_CF
		port map (
			-- inputs
			clock => clock,
			acceptor_handshake_state => acceptor_handshake_state_buffer,
			CFE => CFE,
			CFGn => CFGn,
			CFGn_meters => CFGn_meters,
			PCG => PCG,
			pon => pon,
			-- outputs
			configuration_state => configuration_state_p1_buffer,
			num_meters => configuration_state_p1_num_meters,
			noninterlocked_configuration_state => configuration_state_p2
		);
		
	my_acceptor_fifo : entity work.acceptor_fifo 
		port map (
			clock => clock,
			reset => pon,
			write_enable => acceptor_fifo_write,
			data_byte_in => bus_DIO_in,
			END_in => END_msg,
			EOS_in => EOS,
			read_acknowledge => gpib_to_host_byte_read,
			data_byte_out => gpib_to_host_byte,
			END_out => acceptor_fifo_end,
			EOS_out => acceptor_fifo_eos,
			rft => rft,
			empty => acceptor_fifo_empty
		);
 
	acceptor_handshake_state <= acceptor_handshake_state_buffer;
	controller_state_p1 <= controller_state_p1_buffer;
	controller_state_p2 <= controller_state_p2_buffer;
	controller_state_p3 <= controller_state_p3_buffer;
	controller_state_p4 <= controller_state_p4_buffer;
	controller_state_p5 <= controller_state_p5_buffer;
	device_clear_state <= device_clear_state_buffer;
	device_trigger_state <= device_trigger_state_buffer;
	listener_state_p1 <= listener_state_p1_buffer;
	listener_state_p2 <= listener_state_p2_buffer;
	parallel_poll_state_p1 <= parallel_poll_state_p1_buffer;
	parallel_poll_state_p2 <= parallel_poll_state_p2_buffer;
	remote_local_state <= remote_local_state_buffer;
	service_request_state <= service_request_state_buffer;
	source_handshake_state <= source_handshake_state_buffer;
	talker_state_p1 <= talker_state_p1_buffer;
	talker_state_p2 <= talker_state_p2_buffer;
	talker_state_p3 <= talker_state_p3_buffer;
		
	host_to_gpib_data_byte_latched <= internal_host_to_gpib_data_byte_latched;
	host_to_gpib_command_byte_latched <= internal_host_to_gpib_command_byte_latched;
	
	status_byte_buffer(7) <= not local_STB(7); 
	status_byte_buffer(6) <= not local_RQS; 
	status_byte_buffer(5 downto 0) <= not local_STB(5 downto 0);

	bus_ATN_inverted_out <= not local_ATN when
		controller_state_p1_buffer /= CIDS and controller_state_p1_buffer /= CADS else 'Z';
	bus_DAV_inverted_out <= not local_DAV when talk_enable_buffer = '1' else 'Z';
	bus_EOI_inverted_out <= not (local_END) when
			talker_state_p1_buffer = TACS or talker_state_p1_buffer = SPAS else
		not local_IDY when 
			(
				controller_state_p1_buffer /= CIDS and 
				controller_state_p1_buffer /= CADS and 
				controller_state_p1_buffer /= CSBS and 
				controller_state_p1_buffer /= CSHS 
			) else 
		'Z';
	bus_IFC_inverted_out <= not local_IFC when
		controller_state_p5_buffer /= SIIS else 'Z';
	bus_NDAC_inverted_out <= to_X0Z(local_DAC);
	bus_NRFD_inverted_out <= to_X0Z(local_RFD and not local_NIC);
	-- REN is an output based on whether we are the system controller (based on SIIS, not SRIS)
	bus_REN_inverted_out <= not local_REN when
		controller_state_p5_buffer /= SIIS else 'Z';
	bus_SRQ_inverted_out <= to_X0Z(not local_SRQ);

	bus_DIO_in <= not bus_DIO_inverted_in;

	gpib_to_host_byte_latched <= not acceptor_fifo_empty and not acceptor_fifo_in_virtual_holdoff;
	gpib_to_host_byte_end <= acceptor_fifo_end;
	gpib_to_host_byte_eos <= acceptor_fifo_eos;
	
	lni <= force_lni or RFD_holdoff;
	
	process(pon, clock)
		variable prev_source_handshake_state  : SH_state;
	begin
		if pon = '1' then
			bus_DIO_inverted_out_buffer <= (others => 'Z');
			prev_source_handshake_state := SIDS;
		elsif rising_edge(clock) then
		
			if (source_handshake_state_buffer = SDYS) then
				-- we should only update the output lines when we first enter SDYS,
				-- since the purpose of SDYS is to give time for the lines to settle
				if (prev_source_handshake_state /= SDYS) then
					if talker_state_p1_buffer = TACS then
						bus_DIO_inverted_out_buffer <= not internal_host_to_gpib_data_byte;
					elsif controller_state_p1_buffer = CACS then
						bus_DIO_inverted_out_buffer <= not internal_host_to_gpib_command_byte;
					elsif talker_state_p1_buffer = SPAS then
						bus_DIO_inverted_out_buffer <= status_byte_buffer;
					end if;
				else
					bus_DIO_inverted_out_buffer <= bus_DIO_inverted_out_buffer;
				end if;
			elsif source_handshake_state_buffer = STRS then
				-- DIO lines should already be in correct state from SDYS, just keep it steady until we are out of STRS.
				-- This allows the next output byte to be accepted by the chip without disturbing the state of the DIO
				-- lines.
				bus_DIO_inverted_out_buffer <= bus_DIO_inverted_out_buffer;
			elsif to_X01(local_TCT) = '1' then
				bus_DIO_inverted_out_buffer <= not "00001001";
			elsif parallel_poll_state_p1_buffer = PPAS then
				bus_DIO_inverted_out_buffer <= to_X0Z(not local_PPR);
			elsif (talker_state_p1_buffer = TACS or talker_state_p1_buffer = SPAS or controller_state_p1_buffer = CACS) then
				bus_DIO_inverted_out_buffer <= (others => '1');
			else
				bus_DIO_inverted_out_buffer <= (others => 'Z');
			end if;
			
			prev_source_handshake_state := source_handshake_state_buffer;
		end if;
	end process;
	bus_DIO_inverted_out <= bus_DIO_inverted_out_buffer;

	talk_enable_buffer <= '1' when (talker_state_p1_buffer = TACS or talker_state_p1_buffer = SPAS or 
			controller_state_p1_buffer = CACS or controller_state_p1_buffer = CTRS) or
			(parallel_poll_state_p1_buffer = PPAS and (controller_state_p1_buffer = CIDS or controller_state_p1_buffer = CADS)) else
		'0';
	talk_enable <= talk_enable_buffer;
	
	pullup_disable_buffer <= '1' when parallel_poll_state_p1_buffer /= PPAS else '0';
	pullup_disable <= pullup_disable_buffer;

	EOI_output_enable_buffer <= '1' when
			(talker_state_p1_buffer = TACS or talker_state_p1_buffer = SPAS) or
			(controller_state_p1_buffer /= CIDS and controller_state_p1_buffer /= CADS and 
			controller_state_p1_buffer /= CSBS and controller_state_p1_buffer /= CSHS) else
		'0';
	EOI_output_enable <= EOI_output_enable_buffer;

	-- deal with byte read by host from gpib bus
	process(pon, clock) 
		variable prev_acceptor_handshake_state : AH_state;
	begin
		if to_bit(pon) = '1' then
			prev_acceptor_handshake_state := AIDS;
			acceptor_fifo_write <= '0';
		elsif rising_edge(clock) then
			-- clear pulses
			acceptor_fifo_write <= '0';
			
			-- first data byte cycle in ACDS/ANDS
			if to_bit(ATN) = '0' and
				((acceptor_handshake_state_buffer = ACDS and prev_acceptor_handshake_state /= ACDS) or 
				(acceptor_handshake_state_buffer = ANDS and prev_acceptor_handshake_state /= ANDS)) 
			then
				acceptor_fifo_write <= '1';
			end if;

			prev_acceptor_handshake_state := acceptor_handshake_state_buffer;
		end if;
	end process;
	
	-- set RFD holdoff
	process(pon, clock) 
		variable prev_acceptor_fifo_read : std_logic;
		variable prev_acceptor_fifo_empty : std_logic;
		
		-- virtual_RFD_holdoff and RFD_holdoff should always be set together
		-- (but not cleared together necessarily).  So we do it in a procedure.
		procedure set_virtual_RFD_holdoff is
		begin
			virtual_RFD_holdoff <= '1';
			RFD_holdoff <= '1';
		end set_virtual_RFD_holdoff;

		-- virtual_RFD_holdoff and acceptor_fifo_in_virtual_holdoff should always be
		-- cleared together (but not set together).  So we do it in a procedure.
		procedure clear_virtual_RFD_holdoff is
		begin
			virtual_RFD_holdoff <= '0';
			acceptor_fifo_in_virtual_holdoff <= '0';
		end clear_virtual_RFD_holdoff;
	begin
		if to_bit(pon) = '1' then
			prev_acceptor_fifo_read := '0';
			prev_acceptor_fifo_empty := '1';
			RFD_holdoff <= '0';
			virtual_RFD_holdoff <= '0';
			acceptor_fifo_in_virtual_holdoff <= '0';
		elsif rising_edge(clock) then
			-- if a new byte has appeared at the front of the fifo, either
			-- by writing to an empty fifo, or by reading from the fifo
			-- that still contains bytes after the read.
			if acceptor_fifo_empty = '0' and 
				(prev_acceptor_fifo_empty = '1' or prev_acceptor_fifo_read = '1')
			then
				case RFD_holdoff_mode is
					when holdoff_normal =>
					when holdoff_on_all =>
						set_virtual_RFD_holdoff;
					when holdoff_on_end =>
						if (acceptor_fifo_end or acceptor_fifo_eos) = '1' then
							set_virtual_RFD_holdoff;
						end if;
					when continuous_mode =>
						if (acceptor_fifo_end or acceptor_fifo_eos) = '1' then
							set_virtual_RFD_holdoff;
						end if;
				end case;
			end if;

			if to_X01(set_RFD_holdoff_pulse) = '1' then
				set_virtual_RFD_holdoff;
			end if;
			if to_X01(release_RFD_holdoff_pulse) = '1' then
				clear_virtual_RFD_holdoff;
			end if;
			
			if virtual_RFD_holdoff = '0' and
				acceptor_fifo_empty = '1'
			then
				RFD_holdoff <= '0';
			end if;
			
			if gpib_to_host_byte_read = '1' and virtual_RFD_holdoff = '1' then
				acceptor_fifo_in_virtual_holdoff <= '1';
			end if;
			
			prev_acceptor_fifo_read := gpib_to_host_byte_read;
			prev_acceptor_fifo_empty := acceptor_fifo_empty;
		end if;
	end process;

	combined_RFD_holdoff <= RFD_holdoff or not acceptor_fifo_empty;
	
	-- deal with byte written by host to gpib bus
	process(pon, clock)
		variable prev_source_handshake_state  : SH_state;
	begin
		if to_bit(pon) = '1' then
			internal_host_to_gpib_data_byte_latched <= '0';
			internal_host_to_gpib_data_byte <= (others => '0');
			internal_host_to_gpib_data_byte_end <= '0';
			internal_host_to_gpib_command_byte <= (others => '0');
			internal_host_to_gpib_command_byte_latched <= '0';
			prev_source_handshake_state := SIDS;
		elsif rising_edge(clock) then
			if prev_source_handshake_state /= STRS and 
				source_handshake_state_buffer = STRS then
				if ATN = '0' then
					internal_host_to_gpib_data_byte_latched <= '0';
				else
					internal_host_to_gpib_command_byte_latched <= '0';
				end if;
			end if;
			if device_clear_state_buffer = DCAS then
				internal_host_to_gpib_data_byte_latched <= '0';
			elsif host_to_gpib_data_byte_write = '1' then
				internal_host_to_gpib_data_byte <= host_to_gpib_byte;
				if host_to_gpib_data_byte_end = '1' or
					(host_to_gpib_auto_EOI_on_EOS = '1' and 
					EOS_match(internal_host_to_gpib_data_byte, configured_eos_character, ignore_eos_bit_7)) then
					internal_host_to_gpib_data_byte_end <= '1';
				else
					internal_host_to_gpib_data_byte_end <= '0';
				end if;
				internal_host_to_gpib_data_byte_latched <= '1';
			elsif host_to_gpib_command_byte_write = '1' then
				internal_host_to_gpib_command_byte <= host_to_gpib_byte;
				internal_host_to_gpib_command_byte_latched <= '1';
			end if;
			prev_source_handshake_state := source_handshake_state_buffer;
		end if;
	end process;

	-- update parallel poll sense and line
	process(pon, clock) 
	begin
		if to_X01(pon) = '1' then
			parallel_poll_sense <= '1';
			parallel_poll_response_line <= "000";
		elsif rising_edge(clock) then
			if to_X01(local_parallel_poll_config) = '1' then
				parallel_poll_sense <= local_parallel_poll_sense;
				parallel_poll_response_line <= local_parallel_poll_response_line;
			else
				if to_X01(PPE) = '1' then
					parallel_poll_sense <= PPE_sense;
					parallel_poll_response_line <= PPE_response_line;
				end if;
			end if;
		end if;
	end process;
	
	-- update DAC_holdoff
	process(pon, clock)
		variable last_primary_command_unrecognized : std_logic;
		variable prev_device_clear_state : DC_state;
		variable prev_device_trigger_state : DT_state;
	begin
		if to_X01(pon) = '1' then
			DAC_holdoff <= '0';
			address_passthrough_buffer <= '0';
			command_passthrough_buffer <= '0';
			last_primary_command_unrecognized := '0';
			prev_device_clear_state := DCIS;
			prev_device_trigger_state := DTIS;
		elsif rising_edge(clock) then
			if ATN = '1' then
				if acceptor_handshake_state_buffer = ACDS then
					if (command_valid or command_invalid) = '1' then
						DAC_holdoff <= '0';
					elsif device_clear_state_buffer = DCAS and prev_device_clear_state /= DCAS and DAC_holdoff_on_DCAS = '1' then
						DAC_holdoff <= '1';
					elsif device_trigger_state_buffer = DTAS and prev_device_trigger_state /= DTAS and DAC_holdoff_on_DTAS = '1' then
						DAC_holdoff <= '1';
					end if;
					if PCG = '1' then
						if unrecognized_primary_command = '1' then
							last_primary_command_unrecognized := '1';
						else
							last_primary_command_unrecognized := '0';
						end if;
					end if;
				elsif acceptor_handshake_state_buffer = ACRS then
					if ((LAG or TAG) and not UNT and not UNL) = '1' then
						address_passthrough_buffer <= '1';
						command_passthrough_buffer <= '0';
						DAC_holdoff <= '1';
					elsif SCG = '1' then
						if talker_state_p2_buffer = TPAS or listener_state_p2_buffer = LPAS then
							address_passthrough_buffer <= '1';
							command_passthrough_buffer <= '0';
							DAC_holdoff <= '1';
						elsif parallel_poll_state_p2_buffer /= PACS and last_primary_command_unrecognized = '1' then
							address_passthrough_buffer <= '0';
							command_passthrough_buffer <= '1';
							DAC_holdoff <= '1';
						end if;
					elsif unrecognized_primary_command = '1' then
						address_passthrough_buffer <= '0';
						if is_addressed_command(not bus_DIO_inverted_in) then
							if listener_state_p2_buffer = LPAS or talker_state_p2_buffer = TPAS then
								command_passthrough_buffer <= '1';
								DAC_holdoff <= '1';
							else
								command_passthrough_buffer <= '0';
								DAC_holdoff <= '0';
							end if;
						else
							command_passthrough_buffer <= '1';
							DAC_holdoff <= '1';
						end if;
					else
						address_passthrough_buffer <= '0';
						command_passthrough_buffer <= '0';
						DAC_holdoff <= '0';
					end if;
				end if;
			else
				address_passthrough_buffer <= '0';
				command_passthrough_buffer <= '0';
				DAC_holdoff <= '0';
			end if;
			prev_device_clear_state := device_clear_state_buffer;
			prev_device_trigger_state := device_trigger_state_buffer;
		end if;
	end process;

	address_passthrough <= address_passthrough_buffer when acceptor_handshake_state_buffer = ACDS else '0';
	command_passthrough <= command_passthrough_buffer when acceptor_handshake_state_buffer = ACDS else '0';
	
	virtual_RFD_holdoff_status <= virtual_RFD_holdoff;

	-- update pending_rsv
	process(pon, clock)
		variable serial_poll_in_progress : boolean;
		variable prev_serial_poll_in_progress : boolean;
	begin
		if to_X01(pon) = '1' then
			pending_rsv <= '0';
			serial_poll_in_progress := false;
			prev_serial_poll_in_progress := false;
		elsif rising_edge(clock) then
			serial_poll_in_progress := talker_state_p1_buffer = SPAS and service_request_state_buffer = APRS;
		
			-- Clear pending_rsv if the user explicitly cancels the service request.
			if (reqf = '1') then 
				pending_rsv <= '0';
			-- if any service requests are definitely known to be pending 
			elsif (reqt = '1' or set_rsv_state /= set_rsv_idle) then
				pending_rsv <= '1';
			-- otherwise clear pending_rsv when we are serial polled.
			elsif (serial_poll_in_progress = false and
					prev_serial_poll_in_progress = true) then
				pending_rsv <= '0';
			end if;
			
			prev_serial_poll_in_progress := serial_poll_in_progress;
		end if;
	end process;
end integrated_interface_functions_arch;
