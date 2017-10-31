-- frontend with cb7210.2 style register layout
-- It has been extended with the addition or a isr0/imr0 register.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;
use work.integrated_interface_functions.all;

entity frontend_cb7210p2 is
	port(
		clock : in std_logic;
		chip_select_inverted : in std_logic;
		dma_ack_inverted : in std_logic;
		read_inverted : in std_logic;
		reset : in std_logic;
		address : in std_logic_vector(2 downto 0); 
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
		gpib_DIO_inverted_out : out std_logic_vector(7 downto 0)
	);
end frontend_cb7210p2;
     
architecture frontend_cb7210p2_arch of frontend_cb7210p2 is
	signal bus_ATN_in : std_logic; 
	signal bus_DAV_in :  std_logic; 
	signal bus_EOI_in :  std_logic; 
	signal bus_IFC_in :  std_logic; 
	signal bus_NDAC_in :  std_logic; 
	signal bus_NRFD_in :  std_logic; 
	signal bus_REN_in :  std_logic; 
	signal bus_SRQ_in :  std_logic; 
	signal bus_DIO_in :  std_logic_vector(7 downto 0);

	signal bus_ATN_out : std_logic; 
	signal bus_DAV_out :  std_logic; 
	signal bus_EOI_out :  std_logic; 
	signal bus_IFC_out :  std_logic; 
	signal bus_NDAC_out :  std_logic; 
	signal bus_NRFD_out :  std_logic; 
	signal bus_REN_out :  std_logic; 
	signal bus_SRQ_out :  std_logic; 
	signal bus_DIO_out :  std_logic_vector(7 downto 0);

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
	
	signal device_clear_state : DC_state;
	signal device_trigger_state : DT_state;

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
	
	begin
	my_integrated_interface_functions: entity work.integrated_interface_functions 
		port map (
			clock => clock,
			bus_DIO_in => bus_DIO_in,
			bus_REN_in => bus_REN_in,
			bus_IFC_in => bus_IFC_in,
			bus_SRQ_in => bus_SRQ_in,
			bus_EOI_in => bus_EOI_in,
			bus_ATN_in => bus_ATN_in,
			bus_NDAC_in => bus_NDAC_in,
			bus_NRFD_in => bus_NRFD_in,
			bus_DAV_in => bus_DAV_in,
			bus_DIO_out => bus_DIO_out,
			bus_REN_out => bus_REN_out,
			bus_IFC_out => bus_IFC_out,
			bus_SRQ_out => bus_SRQ_out,
			bus_EOI_out => bus_EOI_out,
			bus_ATN_out => bus_ATN_out,
			bus_NDAC_out => bus_NDAC_out,
			bus_NRFD_out => bus_NRFD_out,
			bus_DAV_out => bus_DAV_out,
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
			device_clear_state => device_clear_state
		);

	gpib_ATN_inverted_out <= not bus_ATN_out;
	gpib_DAV_inverted_out <= not bus_DAV_out;
	gpib_EOI_inverted_out <= not bus_EOI_out;
	gpib_IFC_inverted_out <= not bus_IFC_out;
	gpib_NDAC_inverted_out <= not bus_NDAC_out;
	gpib_NRFD_inverted_out <= not bus_NRFD_out;
	gpib_REN_inverted_out <= not bus_REN_out;
	gpib_SRQ_inverted_out <= not bus_SRQ_out;
	gpib_DIO_inverted_out <= not bus_DIO_out;
	
	-- latch external gpib signals on falling clock edge
	process (clock)
	begin
		if falling_edge(clock) then
			bus_ATN_in <= not gpib_ATN_inverted_in;
			bus_DAV_in <= not gpib_DAV_inverted_in;
			bus_EOI_in <= not gpib_EOI_inverted_in;
			bus_IFC_in <= not gpib_IFC_inverted_in;
			bus_NDAC_in <= not gpib_NDAC_inverted_in;
			bus_NRFD_in <= not gpib_NRFD_inverted_in;
			bus_REN_in <= not gpib_REN_inverted_in;
			bus_SRQ_in <= not gpib_SRQ_inverted_in;
			bus_DIO_in <= not gpib_DIO_inverted_in;
		end if;
	end process;
	
	-- generate pon which is asserted async but de-asserted synchronously on 
	-- falling clock edge, to avoid any potential metastability problems caused
	-- by pon deasserting near rising clock edge.
	process (reset, clock)
	begin
		if to_bit(reset) = '1' then
			pon <= '1';
		end if;
		if falling_edge(clock) then
			if to_bit(reset) = '0' then
				pon <= '0';
			end if;
		end if;
	end process;
end frontend_cb7210p2_arch;
