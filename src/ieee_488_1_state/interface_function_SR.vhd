-- IEEE 488.1 service request interface function.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_states.all;

entity interface_function_SR is
	port(
		clock : in std_logic;
		talker_state_p1 : in TE_state_p1;
		pon : in std_logic;
		rsv : in std_logic;

		service_request_state : out SR_state;
		SRQ : out std_logic;
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
