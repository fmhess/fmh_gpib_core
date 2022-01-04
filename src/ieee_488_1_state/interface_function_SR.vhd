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

-- IEEE 488.1 service request interface function.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity interface_function_SR is
	port(
		clock : in std_logic;
		talker_state_p1 : in TE_state_p1;
		pon : in std_logic;
		rsv : in std_logic;

		service_request_state : out SR_state;
		SRQ : out std_logic
	);
 
end interface_function_SR;
 
architecture interface_function_SR_arch of interface_function_SR is
 
	signal service_request_state_buffer : SR_state;
	
begin
 
	service_request_state <= service_request_state_buffer;
		
	process(pon, clock) begin
		if pon = '1' then
			service_request_state_buffer <= NPRS;
		elsif rising_edge(clock) then

			case service_request_state_buffer is
				when NPRS =>
					if to_bit(rsv) = '1' and talker_state_p1 /= SPAS then
						service_request_state_buffer <= SRQS;
					end if;
				when SRQS =>
					if to_bit(rsv) = '0' and talker_state_p1 /= SPAS then
						service_request_state_buffer <= NPRS;
					elsif talker_state_p1 = SPAS then
						service_request_state_buffer <= APRS;
					end if;
				when APRS =>
					if to_bit(rsv) = '0' and talker_state_p1 /= SPAS then
						service_request_state_buffer <= NPRS;
					end if;
			end case;
		end if;
	end process;

	-- set local message outputs as soon as state changes for low latency
	process(service_request_state_buffer) begin
		case service_request_state_buffer is
			when NPRS =>
				SRQ <= 'L';
			when SRQS =>
				SRQ <= '1';
			when APRS =>
				SRQ <= 'L';
		end case;
	end process;

end interface_function_SR_arch;
