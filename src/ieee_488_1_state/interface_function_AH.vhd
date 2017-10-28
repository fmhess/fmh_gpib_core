-- IEEE 488.1 acceptor handshake interface function.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity interface_function_AH is
	port(
		clock : in std_logic;
		listener_state_p1 : in LE_state_p1;
		ATN : in std_logic;
		DAV : in std_logic;
		pon : in std_logic;
		rdy : in std_logic;
		tcs : in std_logic;
		
		acceptor_handshake_state : out AH_state;
		RFD : out std_logic;
		DAC : out std_logic
	);
 
end interface_function_AH;
 
architecture interface_function_AH_arch of interface_function_AH is
 
	signal acceptor_handshake_state_buffer : AH_state;
	signal addressed : boolean;
	-- state of rdy on previous clock cycle.  rdy is not allowed to transition false during ACRS
	signal old_rdy : std_logic;
	-- we only need to stay in ACDS 1 cycle to successfully read a command byte, so we hard
	-- code T3 to always be satisfied.  Really, T3_rdy is only here to document that
	-- we haven't overlooked it from the standard.  If we implement command pass-through
	-- for unrecognized commands we will need to turn T3_rdy into an input.
	constant T3_rdy : std_logic := '1';
begin
 
	acceptor_handshake_state <= acceptor_handshake_state_buffer;
	addressed <= listener_state_p1 = LACS or listener_state_p1 = LADS;
	
	process(pon, clock) begin
		if pon = '1' then
			acceptor_handshake_state_buffer <= AIDS;
		elsif rising_edge(clock) then
			old_rdy <= rdy;
			
			case acceptor_handshake_state_buffer is
				when AIDS =>
					if to_bit(ATN) = '1' or addressed  then
						acceptor_handshake_state_buffer <= ANRS;
					end if;
				when ANRS =>
					if ((to_bit(ATN) = '1' and to_bit(DAV) = '0') or to_bit(rdy) = '1') and to_bit(tcs) = '0' then
						acceptor_handshake_state_buffer <= ACRS;
					elsif to_bit(DAV) = '1' then
						acceptor_handshake_state_buffer <= AWNS;
					end if;
				when ACRS =>
					if to_bit(DAV) = '1' then
						acceptor_handshake_state_buffer <= ACDS;
					elsif to_bit(ATN) = '0' and to_bit(rdy) = '0' then
						acceptor_handshake_state_buffer <= ANRS;
					end if;
					if to_bit(old_rdy) = '1' and to_bit(rdy) = '0' then
						assert false report "rdy is not permitted to transition false during ACRS.";
					end if;
				when ACDS =>
					if (to_bit(rdy) = '0' and to_bit(ATN) = '0') or (to_bit(T3_rdy) = '1' and to_bit(ATN) = '1') then
						acceptor_handshake_state_buffer <= AWNS;
					elsif to_bit(DAV) = '0' then
						acceptor_handshake_state_buffer <= ACRS;
					end if;
				when AWNS =>
					if to_bit(DAV) = '0' then
						acceptor_handshake_state_buffer <= ANRS;
					end if;
			end case;

			if to_bit(ATN) = '0' and not addressed then
				acceptor_handshake_state_buffer <= AIDS;
			end if;

		end if;
	end process;

	-- set local message outputs as soon as state changes for low latency
	process(acceptor_handshake_state_buffer) begin
		case acceptor_handshake_state_buffer is
			when AIDS =>
				RFD <= 'H';
				DAC <= 'H';
			when ANRS =>
				RFD <= '0';
				DAC <= '0';
			when ACRS =>
				RFD <= 'H';
				DAC <= '0';
			when ACDS =>
				RFD <= '0';
				DAC <= '0';
			when AWNS =>
				RFD <= '0';
				DAC <= 'H';
		end case;
	end process;
end interface_function_AH_arch;
