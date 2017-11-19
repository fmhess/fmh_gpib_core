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
		device_DIO : inout std_logic_vector(7 downto 0);
		device_ATN : inout std_logic;
		device_DAV : inout std_logic;
		device_EOI : inout std_logic;
		device_IFC : inout std_logic;
		device_NDAC : inout std_logic;
		device_NRFD : inout std_logic;
		device_REN : inout std_logic;
		device_SRQ : inout std_logic;
		bus_DIO : inout std_logic_vector(7 downto 0);
		bus_ATN : inout std_logic;
		bus_DAV : inout std_logic;
		bus_EOI : inout std_logic;
		bus_IFC : inout std_logic;
		bus_NDAC : inout std_logic;
		bus_NRFD : inout std_logic;
		bus_REN : inout std_logic;
		bus_SRQ : inout std_logic;
		not_controller_in_charge : in std_logic;
		system_controller : in std_logic
	);
 
end gpib_transceiver;
 
architecture gpib_transceiver_arch of gpib_transceiver is

	signal eoi_transmit : std_logic;
	
	signal device_is_asserting_DIO : std_logic_vector(7 downto 0);
	signal device_is_asserting_NDAC : std_logic;
	signal device_is_asserting_NRFD : std_logic;
	signal device_is_asserting_SRQ : std_logic;

	function open_collector_sync_to_bus(device_value : in std_logic) return std_logic is
	begin
		case device_value is
			when '0' => return '0';
			when '1' => return 'Z';
			when 'L' => return 'Z';
			when 'H' => return 'Z';
			when others => return 'Z';
		end case;
	end open_collector_sync_to_bus;

	function tristate_sync(source_value : in std_logic; 
		transmit : in std_logic) return std_logic is
	begin
		if to_X01(transmit) = '1' then
			case source_value is
				when '0' => return '0';
				when '1' => return '1';
				when 'L' => return '0';
				when 'H' => return '1';
				when others => return 'Z';
			end case;
		else
			return 'Z';
		end if;
	end tristate_sync;

	function open_collector_sync_to_device(bus_value : in std_logic) return std_logic is
	begin
		case bus_value is
			when '0' => return 'L';
			when '1' => return 'H';
			when 'L' => return 'L';
			when 'H' => return 'H';
			when others => return 'Z';
		end case;
	end open_collector_sync_to_device;

	function sync_dio_to_bus(source : in std_logic; transmit : in std_logic; 
		pullup_disable : in std_logic) return std_logic is
	begin
		if to_X01(pullup_disable) = '1' then
			return tristate_sync(source, transmit);
		else
			return open_collector_sync_to_bus(source);
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

	function sync_dio_to_device(source : in std_logic; transmit : in std_logic; 
		pullup_disable : in std_logic) return std_logic is
	begin
		if to_X01(pullup_disable) = '1' then
			return tristate_sync(source, transmit);
		else
			return open_collector_sync_to_device(source);
		end if;
	end sync_dio_to_device;

	function sync_dio_to_device(source : in std_logic_vector; transmit : in std_logic; 
		pullup_disable : in std_logic) return std_logic_vector is
		variable result : std_logic_vector(source'RANGE);
	begin
		for i in source'RANGE loop
			result(i) := 
				sync_dio_to_device(source(i), transmit, pullup_disable);
		end loop;
		return result;
	end sync_dio_to_device;
begin
	
	device_DIO <= sync_dio_to_device(bus_DIO, not talk_enable, pullup_disable);
	bus_DIO <= sync_dio_to_bus(device_DIO, talk_enable, pullup_disable);

	device_ATN <= tristate_sync(bus_ATN, not_controller_in_charge);
	bus_ATN <= tristate_sync(device_ATN, not not_controller_in_charge);

	device_SRQ <= open_collector_sync_to_device(bus_SRQ);
	bus_SRQ <= open_collector_sync_to_bus(device_SRQ);

	device_IFC <= tristate_sync(bus_IFC, not system_controller);
	device_REN <= tristate_sync(bus_REN, not system_controller);
	bus_IFC <= tristate_sync(device_IFC, system_controller);
	bus_REN <= tristate_sync(device_REN, system_controller);
	

	device_DAV <= tristate_sync(bus_DAV, not talk_enable);
	device_NDAC <= open_collector_sync_to_device(bus_NDAC);
	device_NRFD <= open_collector_sync_to_device(bus_NRFD);
	bus_DAV <= tristate_sync(device_DAV, talk_enable);
	bus_NDAC <= open_collector_sync_to_bus(device_NDAC);
	bus_NRFD <= open_collector_sync_to_bus(device_NRFD);
	

	eoi_transmit <= '1' when (to_bit(talk_enable) = '1' and to_bit(not_controller_in_charge) = '0') or
			(to_bit(talk_enable) = to_bit(not_controller_in_charge) and to_bit(talk_enable) = to_bit(bus_ATN)) else
		'0';
	device_EOI <= tristate_sync(bus_EOI, not eoi_transmit);
	bus_EOI <= tristate_sync(device_EOI, eoi_transmit);
	
end gpib_transceiver_arch;
