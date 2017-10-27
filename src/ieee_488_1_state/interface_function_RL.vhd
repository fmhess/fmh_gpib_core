-- IEEE 488.1 remote local interface function.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_states.all;

entity interface_function_RL is
	port(
		clock : in std_logic;
		acceptor_handshake_state : in AH_state;
		listener_state_p1 : in LE_state_p1;
		listener_state_p2 : in LE_state_p2;
		pon : in std_logic;
		rtl : in std_logic;
		REN : in std_logic;
		LLO : in std_logic;
		GTL : in std_logic;
		MLA : in std_logic;
		MSA : in std_logic;
		enable_secondary_addressing : in std_logic;
		
		remote_local_state : out RL_state
	);
 
end interface_function_RL;
 
architecture interface_function_RL_arch of interface_function_RL is
 
	signal remote_local_state_buffer : RL_state;
	signal listener_addressed : boolean;
	
begin
	listener_addressed <=  acceptor_handshake_state = ACDS and 
		((to_bit(enable_secondary_addressing) = '0' and to_bit(MLA) = '1') or
		(to_bit(enable_secondary_addressing) = '1' and to_bit(MSA) = '1' and listener_state_p2 = LPAS));

	remote_local_state <= remote_local_state_buffer;
		
	process(pon, clock) begin
		if pon = '1' then
			remote_local_state_buffer <= LOCS;
		elsif rising_edge(clock) then

			case remote_local_state_buffer is
				when LOCS =>
					if to_bit(REN) = '1' and to_bit(rtl) = '0' and listener_addressed then
						remote_local_state_buffer <= REMS;
					elsif to_bit(REN) = '1' and to_bit(LLO) = '1' and acceptor_handshake_state = ACDS then
						remote_local_state_buffer <= LWLS;
					end if;
				when REMS =>
					if to_bit(LLO) = '1' and acceptor_handshake_state = ACDS then
						remote_local_state_buffer <= RWLS;
					elsif (to_bit(GTL) = '1' and listener_state_p1 = LADS and acceptor_handshake_state = ACDS) or
						(to_bit(rtl) = '1' and (to_bit(LLO) = '0' or acceptor_handshake_state /= ACDS)) then
						remote_local_state_buffer <= LOCS;
					end if;
				when RWLS =>
					if to_bit(GTL) = '1' and listener_state_p1 = LADS and acceptor_handshake_state = ACDS then
						remote_local_state_buffer <= LWLS;
					end if;
				when LWLS =>
					if listener_addressed then
						remote_local_state_buffer <= RWLS;
					end if;
			end case;
			
			if to_bit(REN) = '0' then
				remote_local_state_buffer <= LOCS;
			end if;
		end if;
	end process;
end interface_function_RL_arch;
