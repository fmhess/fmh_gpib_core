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

	function sync_output(source : in std_logic; 
		transmit : in std_logic) return std_logic is
	begin
		if to_X01(transmit) = '1' then
			return source;
		else
			return 'Z';
		end if;
	end sync_output;

	function sync_dio_output(source : in std_logic; transmit : in std_logic; 
		pullup_disable : in std_logic; source_is_asserting : in std_logic) return std_logic is
	begin
		return sync_output(source, (pullup_disable and transmit) or (not pullup_disable and source_is_asserting));
	end sync_dio_output;

	function sync_dio_output(source : in std_logic_vector; transmit : in std_logic; 
		pullup_disable : in std_logic; source_is_asserting : in std_logic_vector) return std_logic_vector is
		variable result : std_logic_vector(source'RANGE);
	begin
		for i in source'LOW to source'HIGH loop
			result(i) := 
				sync_dio_output(source(i), transmit, pullup_disable, 
				source_is_asserting(source_is_asserting'LOW + i));
		end loop;
		return result;
	end sync_dio_output;

	function device_is_asserting(
		device_value : in std_logic; bus_value : in std_logic;
		old_result : in std_logic) return std_logic is
	begin
		if to_X01(device_value) = '0' and to_X01(bus_value) = '1' then
			return '1';
		elsif to_X01(device_value) = '1' and to_X01(bus_value) = '0' then
			return '0';
		else
			return old_result;
		end if;
	end device_is_asserting;

	function device_is_asserting(
		device_value : in std_logic_vector; bus_value : in std_logic_vector;
		old_result : in std_logic_vector) return std_logic_vector is
		variable result : std_logic_vector(device_value'RANGE);
	begin
		for i in device_value'LOW to device_value'HIGH loop
			result(i) := device_is_asserting(device_value(i), bus_value(i), old_result(i));
		end loop;
		return result;
	end device_is_asserting;
begin
	device_is_asserting_DIO <= device_is_asserting(device_DIO, bus_DIO, device_is_asserting_DIO);
	device_is_asserting_SRQ <= device_is_asserting(device_SRQ, bus_SRQ, device_is_asserting_SRQ);
	device_is_asserting_NDAC <= device_is_asserting(device_NDAC, bus_NDAC, device_is_asserting_NDAC);
	device_is_asserting_NRFD <= device_is_asserting(device_NRFD, bus_NRFD, device_is_asserting_NRFD);
	
	device_DIO <= sync_dio_output(bus_DIO, not talk_enable, pullup_disable, not device_is_asserting_DIO);
	bus_DIO <= sync_dio_output(device_DIO, talk_enable, pullup_disable, device_is_asserting_DIO);

	device_ATN <= sync_output(bus_ATN, not_controller_in_charge);
	bus_ATN <= sync_output(device_ATN, not not_controller_in_charge);

	device_SRQ <= sync_output(bus_SRQ, not device_is_asserting_SRQ);
	bus_SRQ <= sync_output(device_SRQ, device_is_asserting_SRQ);

	device_IFC <= sync_output(bus_IFC, not system_controller);
	device_REN <= sync_output(bus_REN, not system_controller);
	bus_IFC <= sync_output(device_IFC, system_controller);
	bus_REN <= sync_output(device_REN, system_controller);
	

	device_DAV <= sync_output(bus_DAV, not talk_enable);
	device_NDAC <= sync_output(bus_NDAC, not device_is_asserting_NDAC);
	device_NRFD <= sync_output(bus_NRFD, not device_is_asserting_NRFD);
	bus_DAV <= sync_output(device_DAV, talk_enable);
	bus_NDAC <= sync_output(device_NDAC, device_is_asserting_NDAC);
	bus_NRFD <= sync_output(device_NRFD, device_is_asserting_NRFD);
	

	eoi_transmit <= '1' when (to_bit(talk_enable) = '1' and to_bit(not_controller_in_charge) = '0') or
			(to_bit(talk_enable) = to_bit(not_controller_in_charge) and to_bit(talk_enable) = to_bit(bus_ATN)) else
		'0';
	device_EOI <= sync_output(bus_EOI, not eoi_transmit);
	bus_EOI <= sync_output(device_EOI, eoi_transmit);
	
	-- pullup resistors
	bus_DIO <= "HHHHHHHH";
	bus_SRQ <= 'H';
	bus_NDAC <= 'H';
	bus_NRFD <= 'H';
	device_DIO <= "HHHHHHHH";
	device_SRQ <= 'H';
	device_NDAC <= 'H';
	device_NRFD <= 'H';
end gpib_transceiver_arch;
