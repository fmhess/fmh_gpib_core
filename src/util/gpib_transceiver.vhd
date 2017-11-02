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
 	
begin
	process (bus_DIO, device_DIO, talk_enable, pullup_disable)
	begin
		for i in 0 to 7 loop
			if to_bit(talk_enable) = '1' then
				if to_bit(device_DIO(i)) = '1' then
					if to_bit(pullup_disable) = '1' then
						bus_DIO(i) <= '1'; 
					else
						bus_DIO(i) <= 'Z';
					end if;
				else
					bus_DIO(i) <= '0';
				end if;
				device_DIO(i) <= 'Z';
			else -- device is receiving DIO
				bus_DIO(i) <= 'Z';
				device_DIO(i) <= to_stdulogic(to_bit(bus_DIO(i)));
			end if;
		end loop;
	end process;
	
	process (not_controller_in_charge, bus_ATN, bus_SRQ, device_ATN, device_SRQ)
	begin
		if to_bit(not_controller_in_charge) = '1' then
			device_ATN <= to_stdulogic(to_bit(bus_ATN));
			device_SRQ <= 'Z';

			bus_ATN <= 'Z';
			bus_SRQ <= to_stdulogic(to_bit(device_SRQ));
		else
			device_ATN <= 'Z';
			device_SRQ <= to_stdulogic(to_bit(bus_SRQ));

			bus_ATN <= to_stdulogic(to_bit(device_ATN));
			bus_SRQ <= 'Z';
		end if;
	end process;

	process (system_controller, bus_IFC, bus_REN, device_IFC, device_REN)
	begin
		if to_bit(system_controller) = '1' then
			device_IFC <= 'Z';
			device_REN <= 'Z';

			bus_IFC <= to_stdulogic(to_bit(device_IFC));
			bus_REN <= to_stdulogic(to_bit(device_REN));
		else
			device_IFC <= to_stdulogic(to_bit(bus_IFC));
			device_REN <= to_stdulogic(to_bit(bus_REN));

			bus_IFC <= 'Z';
			bus_REN <= 'Z';
		end if;
	end process;

	process (talk_enable, bus_DAV, bus_NDAC, bus_NRFD, device_DAV, device_NDAC, device_NRFD)
	begin
		if to_bit(talk_enable) = '1' then
			device_DAV <= 'Z';
			device_NDAC <= to_stdulogic(to_bit(bus_NDAC));
			device_NRFD <= to_stdulogic(to_bit(bus_NRFD));

			bus_DAV <= to_stdulogic(to_bit(device_DAV));
			bus_NDAC <= 'Z';
			bus_NRFD <= 'Z';
		else
			device_DAV <= to_stdulogic(to_bit(bus_DAV));
			device_NDAC <= 'Z';
			device_NRFD <= 'Z';

			bus_DAV <= 'Z';
			bus_NDAC <= to_stdulogic(to_bit(device_NDAC));
			bus_NRFD <= to_stdulogic(to_bit(device_NRFD));
		end if;
	end process;
	
	process (talk_enable, not_controller_in_charge, bus_ATN, bus_EOI, device_EOI)
	begin
		if (to_bit(talk_enable) = '1' and to_bit(not_controller_in_charge) = '0') or
			(to_bit(talk_enable) = to_bit(not_controller_in_charge) and to_bit(talk_enable) = to_bit(bus_ATN)) then
			device_EOI <= 'Z';
			bus_EOI <= to_stdulogic(to_bit(device_EOI));
		elsif (to_bit(talk_enable) = '0' and to_bit(not_controller_in_charge) = '1') or
			(to_bit(talk_enable) = to_bit(not_controller_in_charge) and to_bit(talk_enable) /= to_bit(bus_ATN)) then
			device_EOI <= to_stdulogic(to_bit(bus_EOI));
			bus_EOI <= 'Z';
		end if;
	end process;
	
end gpib_transceiver_arch;
