-- frontend with cb7210.2 style register layout
-- It has been extended with the addition or a isr0/imr0 register at page 1, offset 6.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;
use work.integrated_interface_functions.all;

entity frontend_cb7210p2 is
	generic(
		-- use 6 address lines for a flat register map.  Address lines 3 to 5 will specify page.
		num_address_lines : integer := 3;
		clock_frequency_KHz : integer := 20000);
	port(
		clock : in std_logic;
		chip_select_inverted : in std_logic;
		dma_ack_inverted : in std_logic;
		read_inverted : in std_logic;
		reset : in std_logic;
		address : in std_logic_vector(num_address_lines - 1 downto 0); 
		write_inverted : in std_logic;
		host_data_bus_in : in std_logic_vector(7 downto 0);
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

		dma_request : out std_logic;
		host_data_bus_out : out std_logic_vector(7 downto 0);
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
		talk_enable : out std_logic; -- transceiver TE
		trigger : out std_logic 
	);
end frontend_cb7210p2;
     
architecture frontend_cb7210p2_arch of frontend_cb7210p2 is
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
	signal acceptor_handshake_state : AH_state;
	signal controller_state_p1 : C_state_p1;
	signal controller_state_p2 : C_state_p2;
	signal device_clear_state : DC_state;
	signal device_trigger_state : DT_state;
	signal listener_state_p1 : LE_state_p1;
	signal parallel_poll_state_p1 : PP_state_p1;
	signal remote_local_state : RL_state;
	signal source_handshake_state : SH_state;
	signal talker_state_p1 : TE_state_p1;
	signal in_remote_state : std_logic;
	signal in_lockout_state : std_logic;
	signal TADS_or_TACS : std_logic;
	signal LADS_or_LACS : std_logic;
	
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
	signal local_STB : std_logic_vector(7 downto 0);
	
	signal safe_reset : std_logic;
	signal latched_host_data_byte_in : std_logic_vector(7 downto 0);
	signal host_write_selected : std_logic;
	signal host_read_selected : std_logic;
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
	signal enable_address_register_1 : std_logic;
	signal ultra_fast_T1_delay : std_logic;
	signal high_speed_T1_delay : std_logic;
	signal pon_pulse : std_logic;
	signal generate_END_interrupt_on_EOS : std_logic;
	
	signal talk_enable_buffer : std_logic;
	signal controller_in_charge_buffer : std_logic;
	signal pullup_disable_buffer : std_logic;
	signal EOI_output_enable_buffer : std_logic;
	signal trigger_buffer : std_logic;

	signal host_write_cycle_counter : integer range 0 to 2;
	signal host_read_cycle_counter : integer range 0 to 2;
	
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
	signal DET_interrupt_enable : std_logic;
	signal APT_interrupt_enable : std_logic;
	signal CPT_interrupt_enable : std_logic;
	
	-- interrupt mask register 2 interrupts
	signal ADSC_interrupt : std_logic;
	signal REMC_interrupt : std_logic;
	signal LOKC_interrupt : std_logic;
	signal CO_interrupt : std_logic;
	signal SRQ_interrupt : std_logic;
	signal ADSC_interrupt_enable : std_logic;
	signal REMC_interrupt_enable : std_logic;
	signal LOKC_interrupt_enable : std_logic;
	signal CO_interrupt_enable : std_logic;
	signal DMA_input_enable : std_logic;
	signal DMA_output_enable : std_logic;
	signal SRQ_interrupt_enable : std_logic;

	-- overhead parameter is fixed number of clock ticks of overhead even when using a timing delay of zero
	function to_clock_ticks (nanoseconds : in integer; overhead : in integer) return std_logic_vector is
		constant nanos_per_milli : integer := 1000000;
		variable ticks : integer;
	begin
		ticks := (nanoseconds * clock_frequency_KHz + nanos_per_milli - 1) / nanos_per_milli - overhead;
		if ticks < 0 then
			ticks := 0;
		end if;
		return std_logic_vector(to_unsigned(ticks, T1_terminal_count'LENGTH));
	end to_clock_ticks;
	constant T1_clock_ticks_2us : std_logic_vector(T1_terminal_count'RANGE) := to_clock_ticks(2000, 2);
	constant T1_clock_ticks_1100ns : std_logic_vector(T1_terminal_count'RANGE) := to_clock_ticks(1100, 2);
	constant T1_clock_ticks_500ns : std_logic_vector(T1_terminal_count'RANGE) := to_clock_ticks(500, 2);
	constant T1_clock_ticks_350ns : std_logic_vector(T1_terminal_count'RANGE) := to_clock_ticks(350, 2);
	
	function flat_address (page : in std_logic_vector(3 downto 0);
		raw_address : in std_logic_vector(num_address_lines - 1 downto 0)) 
		return integer is
		variable raw_address_integer : integer range 0 to 127;
		variable result : std_logic_vector(num_address_lines + page'LENGTH - 1 downto 0);
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
			host_to_gpib_data_byte_latched => host_to_gpib_data_byte_latched,
			acceptor_handshake_state => acceptor_handshake_state,
			controller_state_p1 => controller_state_p1,
			controller_state_p2 => controller_state_p2,
			device_clear_state => device_clear_state,
			device_trigger_state => device_trigger_state,
			listener_state_p1 => listener_state_p1,
			parallel_poll_state_p1 => parallel_poll_state_p1,
			remote_local_state => remote_local_state,
			source_handshake_state => source_handshake_state,
			talker_state_p1 => talker_state_p1,
			local_STB => local_STB
		);

	-- latch external gpib signals on falling clock edge
	process (clock)
	begin
		if falling_edge(clock) then
			bus_ATN_inverted_in <= gpib_ATN_inverted_in;
			bus_DAV_inverted_in <= gpib_DAV_inverted_in;
			bus_EOI_inverted_in <= gpib_EOI_inverted_in;
			bus_IFC_inverted_in <= gpib_IFC_inverted_in;
			bus_NDAC_inverted_in <= gpib_NDAC_inverted_in;
			bus_NRFD_inverted_in <= gpib_NRFD_inverted_in;
			bus_REN_inverted_in <= gpib_REN_inverted_in;
			bus_SRQ_inverted_in <= gpib_SRQ_inverted_in;
			bus_DIO_inverted_in <= gpib_DIO_inverted_in;
		end if;
	end process;
	
	-- generate reset which is asserted async but de-asserted synchronously on 
	-- falling clock edge, to avoid any potential metastability problems caused
	-- by pon deasserting near rising clock edge.
	process (reset, pon, clock)
	begin
		if to_bit(reset) = '1' or pon_pulse = '1' then
			pon <= '1';
			if to_bit(reset) = '1' then
				safe_reset <= '1';
			end if;
		elsif falling_edge(clock) then
			if to_bit(reset) = '0' then
				safe_reset <= '0';
				if pon_pulse = '0' then
					pon <= '0';
				end if;
			end if;
		end if;
	end process;
	
	host_write_selected <= not write_inverted and not chip_select_inverted;
	host_read_selected <= not read_inverted and not chip_select_inverted;
	host_data_bus_out <= host_data_bus_out_buffer when to_X01(host_read_selected) = '1' and
			host_read_cycle_counter > 1 else 
		(others => 'Z');
	
	-- accept reads from host
	process (safe_reset, pon, clock)
		variable do_pulse_gpib_to_host_byte_read : boolean;
		variable prev_acceptor_handshake_state : AH_state;
		variable prev_controller_state_p2 : C_state_p2;
		variable prev_source_handshake_state : SH_state;
		variable prev_in_remote_state : std_logic;
		variable prev_in_lockout_state : std_logic;
		variable prev_ATN_inverted : std_logic;
		variable prev_IFC_inverted : std_logic;
		variable prev_TADS_or_TACS : std_logic;
		variable prev_LADS_or_LACS : std_logic;
		variable prev_controller_in_charge : std_logic;
		
		-- process a read from the host
		procedure host_read_register (page : in std_logic_vector(3 downto 0);
			read_address : in std_logic_vector(num_address_lines - 1 downto 0)) is

		begin
			case flat_address(page, read_address) is
				when 0 => -- data in
					host_data_bus_out_buffer <= gpib_to_host_byte;
					do_pulse_gpib_to_host_byte_read := true;
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
				when 16#14# => -- interrupt status 0
					host_data_bus_out_buffer <= 
						(
							2 => ATN_interrupt,
							3 => IFC_interrupt,
							others => '0'
						);
					ATN_interrupt <= '0';
					IFC_interrupt <= '0';
				when others =>
			end case;
		end host_read_register;
	begin
		if pon = '1' then
			if safe_reset = '1' then
				host_read_cycle_counter <= 0;
				host_data_bus_out_buffer <= (others => 'Z');
			end if;
			do_pulse_gpib_to_host_byte_read := false;
			-- isr0 interrupts
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

			prev_acceptor_handshake_state := acceptor_handshake_state;
			prev_controller_state_p2 := controller_state_p2;
			prev_source_handshake_state := source_handshake_state;
			prev_in_remote_state := in_remote_state;
			prev_in_lockout_state := in_lockout_state;
			prev_ATN_inverted := bus_ATN_inverted_in;
			prev_IFC_inverted := bus_IFC_inverted_in;
			prev_TADS_or_TACS := TADS_or_TACS;
			prev_LADS_or_LACS := LADS_or_LACS;
			prev_controller_in_charge := controller_in_charge_buffer;
			
			check_for_listeners <= '1';
		elsif rising_edge(clock) then
			if host_read_selected = '1' then
				if host_read_cycle_counter < host_read_cycle_counter'HIGH then
					host_read_cycle_counter <= host_read_cycle_counter + 1;
				end if;
			else
				host_read_cycle_counter <= 0;
			end if;

			-- process read
			if host_read_cycle_counter = 1 then
				host_read_register(register_page, address);
			end if;

			-- handle pulses
			if do_pulse_gpib_to_host_byte_read then
				gpib_to_host_byte_read <= '1';
				do_pulse_gpib_to_host_byte_read := false;
			else
				gpib_to_host_byte_read <= '0';
			end if;

			-- set read-clearable interrupts
			
			if to_X01(host_to_gpib_data_byte_latched) = '0' then
				if prev_source_handshake_state /= SGNS and source_handshake_state = SGNS then
					if talker_state_p1 = TACS then
						DO_interrupt <= '1';
					elsif controller_state_p1 = CACS then
						--TODO
					end if;
				end if;
			else
				DO_interrupt <= '0';
			end if;

			if to_X01(rdy) = '0' then
				if prev_acceptor_handshake_state /= ACDS and acceptor_handshake_state = ACDS and listener_state_p1 = LACS then
					DI_interrupt <= '1';
				end if;
			else
				DI_interrupt <= '0';
			end if;

			if to_X01(gpib_to_host_byte_end or (generate_END_interrupt_on_EOS and gpib_to_host_byte_eos)) = '1' then
				if prev_acceptor_handshake_state /= ACDS and acceptor_handshake_state = ACDS and listener_state_p1 = LACS then
					END_interrupt <= '1';
				end if;
			else
				END_interrupt <= '0';
			end if;

			if device_clear_state = DCAS then
				DEC_interrupt <= '1';
			end if;
			
			if device_trigger_state = DTAS then
				DET_interrupt <= '1';
			end if;

			if false then
				APT_interrupt <= '1'; --TODO
			end if;
			
			if false then
				CPT_interrupt <= '1'; --TODO
			end if;

			if to_X01(no_listeners) = '1' then
				ERR_interrupt <= '1';
			end if;

			if prev_TADS_or_TACS /= TADS_or_TACS or prev_LADS_or_LACS /= LADS_or_LACS or
				prev_controller_in_charge /= controller_in_charge_buffer then
				ADSC_interrupt <= '1';
			end if;
				
			if prev_in_remote_state /= in_remote_state then
				REMC_interrupt <= '1';
			end if;
			
			if prev_in_lockout_state /= in_lockout_state then
				LOKC_interrupt <= '1';
			end if;

			if false then -- TODO
				CO_interrupt <= '1';
			end if;
			
			if controller_state_p2 = CSRS then
				if prev_controller_state_p2 /= CSRS then
					SRQ_interrupt <= '1';
				end if;
			else
				SRQ_interrupt <= '0';
			end if;
			
			if to_X01(bus_ATN_inverted_in) = '0' then
				if to_X01(prev_ATN_inverted) = '1' then
					ATN_interrupt <= '1';
				end if;
			else
				ATN_interrupt <= '0';
			end if;
			
			if to_X01(prev_IFC_inverted) = '1' and to_X01(bus_IFC_inverted_in) = '0' then
				IFC_interrupt <= '1';
			end if;

			prev_acceptor_handshake_state := acceptor_handshake_state;
			prev_controller_state_p2 := controller_state_p2;
			prev_source_handshake_state := source_handshake_state;
			prev_in_remote_state := in_remote_state;
			prev_in_lockout_state := in_lockout_state;
			prev_ATN_inverted := bus_ATN_inverted_in;
			prev_IFC_inverted := bus_IFC_inverted_in;
			prev_TADS_or_TACS := TADS_or_TACS;
			prev_LADS_or_LACS := LADS_or_LACS;
			prev_controller_in_charge := controller_in_charge_buffer;
		end if;
	end process;

	-- accept writes from host
	process (safe_reset, pon, clock)
		variable do_pulse_host_to_gpib_data_byte_write : boolean;
		variable send_eoi : std_logic;
		
		procedure execute_auxiliary_command(command : in std_logic_vector(4 downto 0)) is
		begin
			case command is
				when "00000" => -- immediate execute pon
					pon_pulse <= '1';
				when "00010" => -- chip reset
					-- TODO
				when "00011" => -- release RFD holdoff 
					-- TODO
				when "00100" => -- trigger
					-- TODO
				when "00101" | "01101" => -- rtl 
				when "00110" => -- send EOI on next byte 
					send_eoi := '1';
				when "00111" => -- non-valid pass through secondary address 
					-- TODO
				when "01111" => -- valid pass through secondary address 
					-- TODO
				when "00001" => -- clear parallel poll flag 
					-- TODO
				when "01001" => -- set parallel poll flag 
					-- TODO
				when "10000" => -- go to standby 
					-- TODO
				when "10001" => -- take control asynchronously
					-- TODO
				when "10010" => -- take control synchronously
					-- TODO
				when "11010" => -- take control synchronously on end
					-- TODO
				when "10011" => -- listen (pulse)
					-- TODO
				when "11000" => -- request rsv true
					rsv <= '1';
				when "11001" => -- request rsv false
					rsv <= '0';
				when "11011" => -- listen with continuous mode
					-- TODO
				when "11100" => -- local unlisten (pulse)
				when "11101" => -- execute parallel poll
					-- TODO
				when "10110" => -- clear IFC 
					-- TODO
				when "11110" => -- set IFC 
					-- TODO
				when "10111" => -- clear REN 
					-- TODO
				when "11111" => -- set REN
					-- TODO
				when "10100" => -- disable system control (wrong in cb7210 user manual)
					-- TODO
				when others =>
			end case;
		end execute_auxiliary_command;
		
		-- process a write from the host
		procedure host_write_register (page : in std_logic_vector(3 downto 0);
			write_address : in std_logic_vector(num_address_lines - 1 downto 0);
			write_data : in std_logic_vector(7 downto 0)) is

		begin
			case flat_address(page, write_address) is
				when 0 => -- byte out register
					host_to_gpib_data_byte <= write_data;
					host_to_gpib_data_byte_end <= send_eoi;
					send_eoi := '0';
					do_pulse_host_to_gpib_data_byte_write := true;
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
					local_STB <= write_data;
					rsv <= write_data(6);
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
							-- TODO
						when "100" => -- aux A register
							generate_END_interrupt_on_EOS <= write_data(2);
							-- TODO
						when "101" => -- aux B register
							high_speed_T1_delay <= write_data(2);
							invert_interrupt <= write_data(3);
							-- TODO
						when "110" => -- aux E register
							-- TODO
						when "010" => 
							if write_data(4) = '1' then
								register_page <= write_data(3 downto 0);
							else
								ultra_fast_T1_delay <= write_data(0);
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
				when 16#e# => -- interrupt mask register 0
					ATN_interrupt_enable <= write_data(2);
					IFC_interrupt_enable <= write_data(3);
				when others =>
			end case;
		end host_write_register;
		
	begin
		if pon = '1' then
			if safe_reset = '1' then
				host_write_cycle_counter <= 0;
				register_page <= (others => '0');
			end if;
			local_STB <= (others => '0');
			rsv <= '0';
			lon <= '0';
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
			host_to_gpib_data_byte_write <= '0';
			do_pulse_host_to_gpib_data_byte_write := false;
			send_eoi := '0';
			invert_interrupt <= '0';

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

			generate_END_interrupt_on_EOS <= '0';
			-- we have to clear the pon pulse in the "if pon" section
			-- otherwise we will get stuck in pon. We still want to
			-- wait for a clock though.
			if rising_edge(clock) then 
				pon_pulse <= '0';
			end if;
		elsif rising_edge(clock) then
			if host_write_selected = '1' then
				if host_write_cycle_counter < host_write_cycle_counter'HIGH then
					host_write_cycle_counter <= host_write_cycle_counter + 1;
				end if;
			else
				host_write_cycle_counter <= 0;
			end if;

			-- process write
			if host_write_cycle_counter = 1 then
				host_write_register(register_page, address, host_data_bus_in);
			end if;

			-- handle pulses
			if do_pulse_host_to_gpib_data_byte_write then
				host_to_gpib_data_byte_write <= '1';
				do_pulse_host_to_gpib_data_byte_write := false;
			else
				host_to_gpib_data_byte_write <= '0';
			end if;

			-- clear register page after read or write
			if host_write_cycle_counter = 1 or host_read_cycle_counter = 1 then
				register_page <= (others => '0');
			end if;
		end if;
	end process;	

	-- set timing counters
	first_T1_terminal_count <= T1_clock_ticks_1100ns when ultra_fast_T1_delay = '1' else
		T1_clock_ticks_2us;
	T1_terminal_count <= T1_clock_ticks_350ns when ultra_fast_T1_delay = '1' else
		T1_clock_ticks_500ns when high_speed_T1_delay = '1' else
		T1_clock_ticks_2us;
	
	-- figure out configured primary/secondary addresses based on settings written
	-- to chip registers
	process (pon, clock)
	begin
		if pon = '1' then
			configured_primary_address <= to_stdlogicvector(NO_ADDRESS_CONFIGURED);
			configured_secondary_address <= to_stdlogicvector(NO_ADDRESS_CONFIGURED);
		elsif rising_edge(clock) then
			case address_mode is
				when "00" =>
					configured_primary_address <= to_stdlogicvector(NO_ADDRESS_CONFIGURED);
					configured_secondary_address <= to_stdlogicvector(NO_ADDRESS_CONFIGURED);
				when "01" =>
					configured_primary_address <= gpib_address_0;
					configured_secondary_address <= to_stdlogicvector(NO_ADDRESS_CONFIGURED);
					-- TODO minor address
				when "10" =>
					configured_primary_address <= gpib_address_0;
					configured_secondary_address <= gpib_address_1;
				when "11" =>
					-- TODO addresses are major/minor primary addresses and secondaries are
					-- done via software using command pass through reg
				when others =>
			end case;
		end if;
	end process;

	talk_enable_buffer <= '1' when talker_state_p1 = TACS or talker_state_p1 = SPAS or 
			controller_state_p1 = CACS else
		'0';
	talk_enable <= talk_enable_buffer;
	
	controller_in_charge_buffer <= '0' when controller_state_p1 = CIDS or controller_state_p1 = CADS else '1';
	not_controller_in_charge <= not controller_in_charge_buffer;

	pullup_disable_buffer <= '1' when to_X01(not controller_in_charge_buffer) = '1' or 
		parallel_poll_state_p1 /= PPAS else '0';
	pullup_disable <= pullup_disable_buffer;
	
	EOI_output_enable_buffer <= '1' when
			talk_enable_buffer = '1' or 
			(controller_state_p1 /= CIDS and controller_state_p1 /= CADS and 
				controller_state_p1 /= CSBS and controller_state_p1 /= CSHS) else
		'0';
	EOI_output_enable <= EOI_output_enable_buffer;

	trigger_buffer <= '1' when device_trigger_state = DTAS else '0';
	trigger <= trigger_buffer;
	
	tr1 <= talk_enable_buffer;
	process (pon, clock)
	begin
		if pon = '1' then
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
	TADS_or_TACS <= '1' when talker_state_p1 = TADS or talker_state_p1 = TACS else '0';
	
end frontend_cb7210p2_arch;
