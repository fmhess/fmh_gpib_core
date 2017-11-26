-- IEEE 488.1 device clear interface function.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity interface_function_DC is
	port(
		acceptor_handshake_state : in AH_state;
		listener_state_p1 : in LE_state_p1;
		DCL : in std_logic;
		SDC : in std_logic;
		
		device_clear_state : out DC_state
	);
 
end interface_function_DC;
 
architecture interface_function_DC_arch of interface_function_DC is
begin

	device_clear_state <= DCAS when (to_bit(DCL) = '1' or (to_bit(SDC) = '1' and listener_state_p1 = LADS)) and 
			acceptor_handshake_state = ACDS else
		DCIS;
end interface_function_DC_arch;
