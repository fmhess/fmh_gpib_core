-- GPIB tranceiver, based on SN75160B and SN75162B.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpib_transceiver is
	port(
		pullup_disable : in std_logic;
		talk_enable : in std_logic;
		device_DIO : in std_logic_vector(7 downto 0);
		device_ATN : in std_logic;
		device_DAV : in std_logic;
		device_EOI : in std_logic;
		device_IFC : in std_logic;
		device_NDAC : in std_logic;
		device_NRFD : in std_logic;
		device_REN : in std_logic;
		device_SRQ : in std_logic;
		bus_DIO : out std_logic_vector(7 downto 0);
		bus_ATN_in : in std_logic;
		bus_ATN_out : out std_logic;
		bus_DAV : out std_logic;
		bus_EOI : out std_logic;
		bus_IFC : out std_logic;
		bus_NDAC : out std_logic;
		bus_NRFD : out std_logic;
		bus_REN : out std_logic;
		bus_SRQ : out std_logic;
		not_controller_in_charge : in std_logic;
		system_controller : in std_logic
	);
 
end gpib_transceiver;
 
architecture gpib_transceiver_arch of gpib_transceiver is

	signal eoi_transmit : std_logic;
	signal device_DIO_buffer : std_logic_vector(7 downto 0);
	signal device_NDAC_buffer : std_logic;
	signal device_NRFD_buffer : std_logic;
	signal device_SRQ_buffer : std_logic;
	signal device_DIO_resolved : std_logic_vector(7 downto 0);
	signal device_NDAC_resolved : std_logic;
	signal device_NRFD_resolved : std_logic;
	signal device_SRQ_resolved : std_logic;
	
	function to_X0Z (mysig : std_logic) return std_logic is
		variable mysig_X01 : std_logic;
	begin
		mysig_X01 := to_X01(mysig);
		case mysig_X01 is
			when '0' => return '0';
			when '1' => return 'Z';
			when others => return 'X';
		end case;
	end to_X0Z;
	
	function open_collector_sync(source_value : in std_logic;
		transmit : in std_logic) return std_logic is
	begin
		if to_X01(transmit) = '1' then
			return to_X0Z(source_value);
		else
			return 'Z';
		end if;
	end open_collector_sync;

	function tristate_sync(source_value : in std_logic; 
		transmit : in std_logic) return std_logic is
	begin
		if to_X01(transmit) = '1' then
			return to_X01(source_value);
		else
			return 'Z';
		end if;
	end tristate_sync;

	function sync_dio_to_bus(source : in std_logic; transmit : in std_logic; 
		pullup_disable : in std_logic) return std_logic is
	begin
		if to_X01(pullup_disable) = '1' then
			return tristate_sync(source, transmit);
		else
			return open_collector_sync(source, transmit);
		end if;
	end sync_dio_to_bus;

	function sync_dio_to_bus(source : in std_logic_vector; transmit : in std_logic; 
		pullup_disable : in std_logic) return std_logic_vector is
		variable result : std_logic_vector(source'RANGE);
	begin
		for i in source'RANGE loop
			result(i) := 
				sync_dio_to_bus(source(i), transmit, pullup_disable);
		end loop;
		return result;
	end sync_dio_to_bus;

begin
	device_DIO_buffer <= device_DIO;
	device_DIO_resolved <= device_DIO_buffer;
	device_DIO_resolved <= (others => 'H');
	
	device_NRFD_buffer <= device_NRFD;
	device_NRFD_resolved <= device_NRFD_buffer;
	device_NRFD_resolved <= 'H';

	device_NDAC_buffer <= device_NDAC;
	device_NDAC_resolved <= device_NDAC_buffer;
	device_NDAC_resolved <= 'H';

	device_SRQ_buffer <= device_SRQ;
	device_SRQ_resolved <= device_SRQ_buffer;
	device_SRQ_resolved <= 'H';

	bus_DIO <= sync_dio_to_bus(device_DIO_resolved, talk_enable, pullup_disable);

	bus_ATN_out <= tristate_sync(device_ATN, not not_controller_in_charge);

	bus_SRQ <= open_collector_sync(device_SRQ_resolved, not_controller_in_charge);

	bus_IFC <= tristate_sync(device_IFC, system_controller);
	bus_REN <= tristate_sync(device_REN, system_controller);
	

	bus_DAV <= tristate_sync(device_DAV, talk_enable);
	bus_NDAC <= open_collector_sync(device_NDAC_resolved, not talk_enable);
	bus_NRFD <= open_collector_sync(device_NRFD_resolved, not talk_enable);
	

	eoi_transmit <= '1' when (to_bit(talk_enable) = '1' and to_bit(not_controller_in_charge) = '0') or
			(to_bit(talk_enable) = to_bit(not_controller_in_charge) and to_bit(talk_enable) = to_bit(bus_ATN_in)) else
		'0';
	bus_EOI <= tristate_sync(device_EOI, eoi_transmit);
	
end gpib_transceiver_arch;
