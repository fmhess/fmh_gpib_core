-- Copyright 2017 Frank Mori Hess fmh6jj@gmail.com

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--    http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
------------------------------------------------------------------------------

-- IEEE 488.1 device clear interface function.


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
