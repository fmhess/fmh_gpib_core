-- Synchronization of setting rsv local message, as specified by
-- IEEE 488.2 11.3.3 
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2019


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity set_rsv_488_2 is
	port(
		clock : in std_logic;
		pon : in std_logic;
		service_request_state : in SR_state;
		set_reqt_pulse : in std_logic;
		set_reqf_pulse : in std_logic;
		
		
		set_rsv_state : out set_rsv_enum;
		rsv : out std_logic;
		reqt : out std_logic;
		reqf : out std_logic
	);
 
end set_rsv_488_2;
 
architecture set_rsv_488_2_arch of set_rsv_488_2 is
 
	signal current_state : set_rsv_enum;
	signal reqt_buffer : std_logic;
	signal reqf_buffer : std_logic;
	
begin
 
	process(pon, clock) begin
		if to_bit(pon) = '1' then
			current_state <= set_rsv_idle;
			reqt_buffer <= '0';
			reqf_buffer <= '0';
		elsif rising_edge(clock) then

			if to_bit(set_reqt_pulse) = '1' then
				reqt_buffer <= '1';
				reqf_buffer <= '0';
			end if;
			
			if to_bit(set_reqf_pulse) = '1' then
				reqf_buffer <= '1';
				reqt_buffer <= '0';
			end if;

			case current_state is
				when set_rsv_idle =>
					if to_bit(reqt_buffer) = '1' then
						current_state <= set_rsv_wait;
					end if;
					reqf_buffer <= '0';
				when set_rsv_wait =>
					if service_request_state /= APRS then
						current_state <= set_rsv_active;
					end if;
					reqt_buffer <= '0';
				when set_rsv_active =>
					if service_request_state = APRS then
						current_state <= set_rsv_idle;
					end if;
			end case;
			
			if to_bit(reqf_buffer) = '1' then
				current_state <= set_rsv_idle;
			end if;
		end if;
	end process;

	rsv <= '1' when current_state = set_rsv_active else '0';
	set_rsv_state <= current_state;
	reqt <= reqt_buffer;
	reqf <= reqf_buffer;
	
end set_rsv_488_2_arch;
