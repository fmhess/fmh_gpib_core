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
		DAC_holdoff : in std_logic;
		
		acceptor_handshake_state : out AH_state;
		RFD : out std_logic;
		DAC : out std_logic
	);
 
end interface_function_AH;
 
architecture interface_function_AH_arch of interface_function_AH is
 
	signal acceptor_handshake_state_buffer : AH_state;
	signal addressed : boolean;
begin
 
	acceptor_handshake_state <= acceptor_handshake_state_buffer;
	addressed <= listener_state_p1 = LACS or listener_state_p1 = LADS;
	
	process(pon, clock) 
		-- used to delay in ACDS for an extra clock cycle so there is time to see if we need to
		-- do a DAC holdoff due to DTAS or DCAS
		variable T3_delay_satisfied : boolean; 
		-- state of rdy on previous ACRS clock cycle.  Used to assert rdy is not transitioned false during ACRS
		variable old_ACRS_rdy : std_logic;
	begin
		if pon = '1' then
			acceptor_handshake_state_buffer <= AIDS;
			T3_delay_satisfied := false;
			old_ACRS_rdy := '0';
		elsif rising_edge(clock) then
			
			case acceptor_handshake_state_buffer is
				when AIDS =>
					if to_X01(ATN) = '1' or addressed  then
						acceptor_handshake_state_buffer <= ANRS;
					end if;
				when ANRS =>
					if ((to_X01(ATN) = '1' and to_X01(DAV) = '0') or to_X01(rdy) = '1') and to_X01(tcs) = '0' then
						acceptor_handshake_state_buffer <= ACRS;
					elsif to_X01(DAV) = '1' then
						acceptor_handshake_state_buffer <= AWNS;
					end if;
				when ACRS =>
					if to_X01(DAV) = '1' then
						acceptor_handshake_state_buffer <= ACDS;
						T3_delay_satisfied := false;
					elsif to_X01(ATN) = '0' and to_X01(rdy) = '0' then
						acceptor_handshake_state_buffer <= ANRS;
					end if;
					if to_X01(old_ACRS_rdy) = '1' and to_X01(rdy) = '0' then
						assert false report "rdy is not permitted to transition false during ACRS.";
					end if;
					old_ACRS_rdy := to_X01(rdy);
				when ACDS =>
					if (to_X01(rdy) = '0' and to_X01(ATN) = '0') or 
						(DAC_holdoff = '0' and T3_delay_satisfied and to_X01(ATN) = '1') then
						acceptor_handshake_state_buffer <= AWNS;
					elsif to_X01(DAV) = '0' then
						acceptor_handshake_state_buffer <= ACRS;
					end if;
					T3_delay_satisfied := true;
				when AWNS =>
					if to_X01(DAV) = '0' then
						acceptor_handshake_state_buffer <= ANRS;
					end if;
			end case;

			if to_X01(ATN) = '0' and not addressed then
				acceptor_handshake_state_buffer <= AIDS;
			end if;

			if acceptor_handshake_state_buffer /= ACRS then
				old_ACRS_rdy := '0';
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
