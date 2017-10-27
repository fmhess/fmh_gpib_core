-- IEEE 488.1 device clear interface function.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_states.all;

entity interface_function_DC is
	port(
		clock : in std_logic;
		acceptor_handshake_state : in AH_state;
		listener_state_p1 : in LE_state_p1;
		DCL : in std_logic;
		SDC : in std_logic;
		
		device_clear_state : out DC_state
	);
 
end interface_function_DC;
 
architecture interface_function_DC_arch of interface_function_DC is

	signal device_clear_state_buffer : DC_state;
	signal device_clear_message : boolean;
	
begin

	device_clear_message <= (to_bit(DCL) = '1' or (to_bit(SDC) = '1' and listener_state_p1 = LADS)) and 
		acceptor_handshake_state = ACDS;

	device_clear_state <= device_clear_state_buffer;

	process(clock) begin
		if rising_edge(clock) then

			case device_clear_state_buffer is
				when DCIS =>
					if device_clear_message then
						device_clear_state_buffer <= DCAS;
					end if;
				when DCAS =>
					if not device_clear_message then
						device_clear_state_buffer <= DCIS;
					end if;
			end case;
		end if;
	end process;
end interface_function_DC_arch;
