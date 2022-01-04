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

-- IEEE 488.1 device trigger interface function.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity interface_function_DT is
	port(
		acceptor_handshake_state : in AH_state;
		listener_state_p1 : in LE_state_p1;
		GET : in std_logic;
		
		device_trigger_state : out DT_state
	);
 
end interface_function_DT;
 
architecture interface_function_DT_arch of interface_function_DT is
begin

	device_trigger_state <= DTAS when to_bit(GET) = '1' and listener_state_p1 = LADS and 
			acceptor_handshake_state = ACDS else
		DTIS;

end interface_function_DT_arch;
