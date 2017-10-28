-- IEEE 488.1 interface functions all wired together.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;
use work.remote_message_decoder.all;
use work.interface_function_AH.all;
use work.interface_function_DC.all;
use work.interface_function_DT.all;
use work.interface_function_LE.all;
use work.interface_function_PP.all;
use work.interface_function_RL.all;
use work.interface_function_SH.all;
use work.interface_function_SR.all;
use work.interface_function_TE.all;

entity integrated_interface_functions is
	port(
		clock : in std_logic;
		
		bus_DIO_in : in std_logic_vector(7 downto 0);
		bus_REN_in : in std_logic;
		bus_IFC_in : in std_logic;
		bus_SRQ_in : in std_logic;
		bus_EOI_in : in std_logic;
		bus_ATN_in : in std_logic;
		bus_NDAC_in : in std_logic;
		bus_NRFD_in : in std_logic;
		bus_DAV_in : in std_logic;

		ist : in std_logic;
		lon : in std_logic;
		lpe : in std_logic;
		lun : in std_logic;
		ltn : in std_logic;
		pon : in std_logic;
		rsv : in std_logic;
		rtl : in std_logic;
		tcs : in std_logic;
		ton : in std_logic;

		configured_eos_character : in std_logic_vector(7 downto 0);
		ignore_eos_bit_7 : in std_logic;
		configured_primary_address : std_logic_vector(4 downto 0);
		configured_secondary_address : in std_logic_vector(4 downto 0);
		local_parallel_poll_config : in std_logic;
		local_parallel_poll_sense : in std_logic;
		local_parallel_poll_response_line : in std_logic_vector(2 downto 0);
		first_T1_terminal_count : in std_logic_vector(15 downto 0);
		T1_terminal_count : in std_logic_vector(15 downto 0);
		check_for_listeners : in std_logic;

		bus_DIO_out : out std_logic_vector(7 downto 0);
		bus_REN_out : out std_logic;
		bus_IFC_out : out std_logic;
		bus_SRQ_out : out std_logic;
		bus_EOI_out : out std_logic;
		bus_ATN_out : out std_logic;
		bus_NDAC_out : out std_logic;
		bus_NRFD_out : out std_logic;
		bus_DAV_out : out std_logic;
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
		source_handshake_state : out SH_state;
		service_request_state : out SR_state;
		talker_state_p1 : out TE_state_p1;
		talker_state_p2 : out TE_state_p2;
		talker_state_p3 : out TE_state_p3;
		no_listeners : out std_logic
	);
 
end integrated_interface_functions;
 
architecture integrated_interface_functions_arch of integrated_interface_functions is
	signal nba : std_logic;
	signal rdy : std_logic;

	signal ACG : std_logic;
	signal ATN : std_logic;
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
	signal OSA : std_logic;
	signal OTA : std_logic;
	signal PCG : std_logic;
	signal PPC : std_logic;
	signal PPE : std_logic;
	signal PPE_sense : std_logic;
	signal PPE_response_line : std_logic_vector(2 downto 0);
	signal PPR : std_logic_vector(7 downto 0);
	signal PPD : std_logic;
	signal PPU : std_logic;
	signal REN : std_logic;
	signal RFD : std_logic;
	signal RQS : std_logic;
	signal SCG : std_logic;
	signal SDC : std_logic;
	signal SPD : std_logic;
	signal SPE : std_logic;
	signal SRQ : std_logic;
	signal TCT : std_logic;
	signal TAG : std_logic;
	signal UCG : std_logic;
	signal UNL : std_logic;
	signal UNT : std_logic;
	signal NIC : std_logic;
	signal CFE : std_logic;
	signal NUL : std_logic;

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
	
	signal enable_secondary_addressing : std_logic;
	signal parallel_poll_sense : std_logic;
	signal parallel_poll_response_line : std_logic_vector(2 downto 0);
	
begin
	my_decoder: entity work.remote_message_decoder 
		port map (
			bus_DIO => bus_DIO_in,
			bus_REN => bus_REN_in,
			bus_IFC => bus_IFC_in,
			bus_SRQ => bus_SRQ_in,
			bus_EOI => bus_EOI_in,
			bus_ATN => bus_ATN_in,
			bus_NDAC => bus_NDAC_in,
			bus_NRFD => bus_NRFD_in,
			bus_DAV => bus_DAV_in,
			configured_eos_character => configured_eos_character,
			ignore_eos_bit_7 => ignore_eos_bit_7,
			configured_primary_address => configured_primary_address,
			configured_secondary_address => configured_secondary_address,
			ACG => ACG,
			ATN => ATN,
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
			RQS => RQS,
			SCG => SCG,
			SDC => SDC,
			SPD => SPD,
			SPE => SPE,
			SRQ => SRQ,
			TCT => TCT,
			TAG => TAG,
			UCG => UCG,
			UNL => UNL,
			UNT => UNT,
			NIC => NIC,
			CFE => CFE
		);

	my_AH: entity work.interface_function_AH 
		port map (
			clock => clock,
			listener_state_p1 => listener_state_p1_buffer,
			ATN => ATN,
			DAV => DAV,
			pon => pon,
			rdy => rdy,
			tcs => tcs,
			acceptor_handshake_state => acceptor_handshake_state_buffer,
			RFD => RFD,
			DAC => DAC
		);

	my_DC: entity work.interface_function_DC 
		port map (
			clock => clock,
			acceptor_handshake_state => acceptor_handshake_state_buffer,
			listener_state_p1 => listener_state_p1_buffer,
			DCL => DCL,
			SDC => SDC,
			device_clear_state => device_clear_state_buffer
		);

	my_DT: entity work.interface_function_DT 
		port map (
			clock => clock,
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
			PPR => PPR,
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

	my_SH : entity work.interface_function_SH
		port map (
			clock => clock,
			talker_state_p1 => talker_state_p1_buffer,
			controller_state_p1 => controller_state_p1_buffer,
			ATN => ATN,
			DAC => DAC,
			RFD => RFD,
			nba => nba,
			pon => pon,
			first_T1_terminal_count => first_T1_terminal_count,
			T1_terminal_count => T1_terminal_count,
			check_for_listeners => check_for_listeners,
			
			source_handshake_state => source_handshake_state_buffer,
			DAV => DAV,
			no_listeners => no_listeners
		);

	my_SR: entity work.interface_function_SR 
		port map (
			clock => clock,
			talker_state_p1 => talker_state_p1_buffer,
			pon => pon,
			rsv => rsv,
			service_request_state => service_request_state_buffer,
			SRQ => SRQ
		);

	my_TE: entity work.interface_function_TE 
		port map (
			clock => clock,
			acceptor_handshake_state => acceptor_handshake_state_buffer,
			listener_state_p2 => listener_state_p2_buffer,
			service_request_state => service_request_state_buffer,
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
			talker_state_p1 => talker_state_p1_buffer,
			talker_state_p2 => talker_state_p2_buffer,
			talker_state_p3 => talker_state_p3_buffer,
			END_msg => END_msg,
			RQS => RQS,
			NUL => NUL
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
	
	enable_secondary_addressing <= '1' when 
			to_bitvector(configured_secondary_address) /= NO_ADDRESS_CONFIGURED
		else
			'0';
	
	parallel_poll_sense <= local_parallel_poll_sense when
			to_bit(local_parallel_poll_config) = '1'
		else
			PPE_sense;
			
	parallel_poll_response_line <= local_parallel_poll_response_line when
			to_bit(local_parallel_poll_config) = '1'
		else
			PPE_response_line;

	process(clock) begin
	end process;
end integrated_interface_functions_arch;
