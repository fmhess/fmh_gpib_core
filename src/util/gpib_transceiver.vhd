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

	signal eoi_transmit : boolean;
	
	function weak_value (mysignal : in std_logic) return std_logic is
	begin
		case mysignal is
			when '1' => return 'H';
			when '0' => return 'L';
			when 'H' => return 'H';
			when 'L' => return 'L';
			when others => return 'Z';
		end case;
	end weak_value;
	
	function weak_value_vector (myvector : in std_logic_vector(7 downto 0)) return std_logic_vector is
		variable result : std_logic_vector(7 downto 0);
	begin
		for i in 0 to 7 loop
			result(i) := weak_value(myvector(i));
		end loop;
		return result;
	end weak_value_vector;

	function strong_value (mysignal : in std_logic) return std_logic is
	begin
		case mysignal is
			when '1' => return '1';
			when '0' => return '0';
			when 'H' => return '1';
			when 'L' => return '0';
			when others => return 'Z';
		end case;
	end strong_value;

	function strong_value_vector (myvector : in std_logic_vector(7 downto 0)) return std_logic_vector is
		variable result : std_logic_vector(7 downto 0);
	begin
		for i in 0 to 7 loop
			result(i) := strong_value(myvector(i));
		end loop;
		return result;
	end strong_value_vector;

	function open_collector_device_to_bus_value (mysignal : in std_logic) return std_logic is
	begin
		case mysignal is
			when '1' => return 'Z';
			when '0' => return '0';
			-- we don't assert bus side if there is a weak value on the device side, since we might just be seeing a
			-- reflection of the current bus state
			when 'H' => return 'Z';
			when 'L' => return 'Z';
			when others => return 'Z';
		end case;
	end open_collector_device_to_bus_value;

	function open_collector_device_to_bus_value_vector (myvector : in std_logic_vector(7 downto 0)) return std_logic_vector is
		variable result : std_logic_vector(7 downto 0);
	begin
		for i in 0 to 7 loop
			result(i) := open_collector_device_to_bus_value(myvector(i));
		end loop;
		return result;
	end open_collector_device_to_bus_value_vector;

	function strong_device_to_bus_value (mysignal : in std_logic) return std_logic is
	begin
		case mysignal is
			when '1' => return '1';
			when '0' => return '0';
			-- we don't assert bus side if there is a weak value on the device side, since we might just be seeing a
			-- reflection of the current bus state
			when 'H' => return 'Z';
			when 'L' => return 'Z'; 
			when others => return 'Z';
		end case;
	end strong_device_to_bus_value;

	function strong_device_to_bus_value_vector (myvector : in std_logic_vector(7 downto 0)) return std_logic_vector is
		variable result : std_logic_vector(7 downto 0);
	begin
		for i in 0 to 7 loop
			result(i) := strong_device_to_bus_value(myvector(i));
		end loop;
		return result;
	end strong_device_to_bus_value_vector;
begin

	device_DIO <= strong_value_vector(bus_DIO) when to_bit(talk_enable) = '0' else
		weak_value_vector(device_DIO);
	bus_DIO <= strong_device_to_bus_value_vector(device_DIO) when to_bit(talk_enable and pullup_disable) = '1' else
		open_collector_device_to_bus_value_vector(device_DIO) when to_bit(talk_enable and not pullup_disable) = '1' else
		(others => 'Z');
	
	device_ATN <= strong_value(bus_ATN) when to_bit(not_controller_in_charge) = '1' else
		weak_value(bus_ATN);
	device_SRQ <= strong_value(bus_SRQ) when to_bit(not_controller_in_charge) = '0' else 
		weak_value(bus_SRQ);
	bus_ATN <= strong_device_to_bus_value(device_ATN) when to_bit(not_controller_in_charge) = '0' else 'Z';
	bus_SRQ <= open_collector_device_to_bus_value(device_SRQ) when to_bit(not_controller_in_charge) = '1' else 'Z';
	
	device_IFC <= strong_value(bus_IFC) when to_bit(system_controller) = '0' else
		weak_value(bus_IFC);
	device_REN <= strong_value(bus_REN) when to_bit(system_controller) = '0' else
		weak_value(bus_REN);
	bus_IFC <= strong_device_to_bus_value(device_IFC) when to_bit(system_controller) = '1' else
		'Z';
	bus_REN <= strong_device_to_bus_value(device_REN) when to_bit(system_controller) = '1' else
		'Z';

	device_DAV <= strong_value(bus_DAV) when to_bit(talk_enable) = '0' else
		weak_value(bus_DAV);
	device_NDAC <= strong_value(bus_NDAC) when to_bit(talk_enable) = '1' else
		weak_value(bus_NDAC);
	device_NRFD <= strong_value(bus_NRFD) when to_bit(talk_enable) = '1' else
		weak_value(bus_NRFD);
	bus_DAV <= strong_device_to_bus_value(device_DAV) when to_bit(talk_enable) = '1' else
		'Z';
	bus_NDAC <= strong_device_to_bus_value(device_NDAC) when to_bit(talk_enable) = '0' else
		'Z';
	bus_NRFD <= strong_device_to_bus_value(device_NRFD) when to_bit(talk_enable) = '0' else
		'Z';
	

	eoi_transmit <= (to_bit(talk_enable) = '1' and to_bit(not_controller_in_charge) = '0') or
			(to_bit(talk_enable) = to_bit(not_controller_in_charge) and to_bit(talk_enable) = to_bit(bus_ATN));
	device_EOI <= strong_value(bus_EOI) when not eoi_transmit else
		weak_value(bus_EOI);
	bus_EOI <= strong_device_to_bus_value(device_EOI) when eoi_transmit else
		'Z';

end gpib_transceiver_arch;
