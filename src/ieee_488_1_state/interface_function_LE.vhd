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

-- IEEE 488.1 extended listener LE and listener T interface functions.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity interface_function_LE is
	port(
		clock : in std_logic;
		acceptor_handshake_state : in AH_state;
		controller_state_p1 : in C_state_p1;
		talker_state_p2 : in TE_state_p2;
		ATN : in std_logic;
		IFC : in std_logic;
		pon : in std_logic;
		ltn : in std_logic;
		lon : in std_logic;
		lun : in std_logic;
		UNL : in std_logic;
		MLA : in std_logic;
		MSA : in std_logic;
		PCG : in std_logic;
		MTA : in std_logic;
		enable_secondary_addressing : in std_logic; -- true for extended listener LE, false for listener L
		
		listener_state_p1 : out LE_state_p1;
		listener_state_p2 : out LE_state_p2
	);
 
end interface_function_LE;
 
architecture interface_function_LE_arch of interface_function_LE is
 
	signal listener_state_p1_buffer : LE_state_p1;
	signal listener_state_p2_buffer : LE_state_p2;
	signal LE_addressed : boolean;
	signal L_addressed : boolean;
	signal addressed : boolean;
	signal LE_unaddressed : boolean;
	signal L_unaddressed : boolean;
	signal unaddressed : boolean;
	
begin
 
	listener_state_p1 <= listener_state_p1_buffer;
	listener_state_p2 <= listener_state_p2_buffer;
	
	L_addressed <= (to_bit(MLA) = '1' and acceptor_handshake_state = ACDS);	
	LE_addressed <= (to_bit(MSA) = '1' and listener_state_p2_buffer = LPAS and acceptor_handshake_state = ACDS);
	addressed <= to_bit(IFC) = '0' and (to_bit(lon) = '1' or
		(to_bit(ltn) = '1' and controller_state_p1 = CACS) or
		(to_bit(enable_secondary_addressing) = '1' and LE_addressed) or
		(to_bit(enable_secondary_addressing) = '0' and L_addressed));

	L_unaddressed <= to_bit(MTA) = '1' and acceptor_handshake_state = ACDS;
	LE_unaddressed <= to_bit(MSA) = '1' and acceptor_handshake_state = ACDS and talker_state_p2 = TPAS;
	unaddressed <= (to_bit(UNL) = '1' and acceptor_handshake_state = ACDS) or
		(to_bit(lun) = '1' and controller_state_p1 = CACS) or
		((to_bit(enable_secondary_addressing) = '1' and LE_unaddressed) or
		(to_bit(enable_secondary_addressing) = '0' and L_unaddressed));

	
	process(pon, clock) begin
		if pon = '1' then
			listener_state_p1_buffer <= LIDS;
			listener_state_p2_buffer <= LPIS;
		elsif rising_edge(clock) then

			-- part 1 state machine
			case listener_state_p1_buffer is
				when LIDS =>
					if addressed then
						listener_state_p1_buffer <= LADS;
					end if;
				when LADS =>
					if unaddressed then
						listener_state_p1_buffer <= LIDS;
					elsif to_bit(ATN) = '0' then
						listener_state_p1_buffer <= LACS;
					end if;
				when LACS =>
					if to_bit(ATN) = '1' then
						listener_state_p1_buffer <= LADS;
					end if;
			end case;

			-- part 2 state machine
			case listener_state_p2_buffer is
				when LPIS =>
					if to_bit(MLA) = '1' and acceptor_handshake_state = ACDS then
						listener_state_p2_buffer <= LPAS;
					end if;
				when LPAS =>
					if to_bit(PCG) = '1' and to_bit(MLA) = '0' and acceptor_handshake_state = ACDS then
						listener_state_p2_buffer <= LPIS;
					end if;
			end case;

			if to_bit(IFC) = '1' then
				listener_state_p1_buffer <= LIDS;
			end if;

		end if;
	end process;
end interface_function_LE_arch;
