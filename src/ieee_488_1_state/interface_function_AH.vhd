-- IEEE 488.1 extended acceptor handshake (AHE) interface function.
--
-- If you only need the simpler AH function, you may leave the defaulted
-- inputs unconnected.
--
-- You have 2 cycles after entering ACDS (or ANDS when noninterlocked) to latch the DIO lines.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017, 2019


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity interface_function_AH is
	generic( num_counter_bits : in integer := 8);
	port(
		clock : in std_logic;
		listener_state_p1 : in LE_state_p1;
		ATN : in std_logic;
		DAV : in std_logic;
		NIC : in std_logic := '0';
		lni : in std_logic := '1';
		pon : in std_logic;
		RFD_holdoff : in std_logic;
		rft : in std_logic := '0';
		tcs : in std_logic;
		DAC_holdoff : in std_logic;
		T16_terminal_count : in unsigned (num_counter_bits - 1 downto 0) := (others => '1');
		T17_terminal_count : in unsigned (num_counter_bits - 1 downto 0) := (others => '1');
		T18_terminal_count : in unsigned (num_counter_bits - 1 downto 0) := (others => '1');

		acceptor_handshake_state : out AH_state;
		acceptor_noninterlocked_state : out AH_noninterlocked_state;
		RFD : out std_logic;
		DAC : out std_logic
	);
 
end interface_function_AH;
 
architecture interface_function_AH_arch of interface_function_AH is
 
	signal acceptor_handshake_state_buffer : AH_state;
	signal acceptor_noninterlocked_state_buffer : AH_noninterlocked_state;
	signal addressed : boolean;
	-- timer counter local to AH_state state machine
	signal AH_count : unsigned(num_counter_bits - 1 downto 0);
	-- timer counter local to AH_noninterlocked_state state machine
	signal noninterlocked_count : unsigned(num_counter_bits - 1 downto 0);
	signal lni_or_tcs : boolean;
begin
 
	acceptor_handshake_state <= acceptor_handshake_state_buffer;
	acceptor_noninterlocked_state <= acceptor_noninterlocked_state_buffer;
	addressed <= listener_state_p1 = LACS or listener_state_p1 = LADS;
	lni_or_tcs <= to_X01(lni) = '1' or to_X01(tcs) = '1';
	
	process(pon, clock) 
		-- used to delay in some states for an extra clock cycle so to give time for
		-- the DAC holdoff input to update before we transition out of the state.
		variable T3_delay_satisfied : boolean; 
		variable AH_counter_done : boolean;
		variable noninterlocked_counter_done : boolean;
		variable prev_ATN : std_logic;
		variable rdy : boolean;
	begin
		if pon = '1' then
			acceptor_handshake_state_buffer <= AIDS;
			acceptor_noninterlocked_state_buffer <= ANIS;
			T3_delay_satisfied := false;
			AH_count <= to_unsigned(0, num_counter_bits);
			AH_counter_done := false;
			noninterlocked_count <= to_unsigned(0, num_counter_bits);
			noninterlocked_counter_done := false;
			prev_ATN := '0';
			rdy := false;
		elsif rising_edge(clock) then
			
			case acceptor_handshake_state_buffer is
				when AIDS =>
					if to_X01(ATN) = '1' or addressed  then
						acceptor_handshake_state_buffer <= ANRS;
					end if;
				when ANRS =>
					rdy := to_X01(RFD_holdoff) = '0';
					
					if ((to_X01(ATN) = '1' and to_X01(DAV) = '0') or rdy) and to_X01(tcs) = '0' then
						acceptor_handshake_state_buffer <= ACRS;
						rdy := false; -- see comment in ACRS case
					elsif to_X01(DAV) = '1' then
						acceptor_handshake_state_buffer <= AWNS;
					end if;
				when ACRS =>
					-- We proactively clear rdy before entering ACRS (see other states where they transition to ACRS), 
					-- since 488.1 prohibits rdy from transitioning false
					-- when we are already in ACRS.  This produces a transition back to ANRS if ATN is deasserted 
					-- in ACRS, allowing a RFD holdoff 
					-- to take effect, while still complying with the letter of IEEE 488.1.
					
					if to_X01(DAV) = '1' then
						if 
						(
								to_X01(ATN) = '1' or 
								acceptor_noninterlocked_state_buffer = AIAS or 
								acceptor_noninterlocked_state_buffer = ANCS
						) 
						then
							acceptor_handshake_state_buffer <= ACDS;
							T3_delay_satisfied := false;
						elsif acceptor_noninterlocked_state_buffer = ANAS then
							acceptor_handshake_state_buffer <= ANDS;
							AH_count <= to_unsigned(0, num_counter_bits);
						end if;
					-- transition to ANRS is only permitted on transitions of ATN from true to false, as per IEEE 488.1
					elsif prev_ATN = '1' and to_X01(ATN) = '0' and not rdy then
						acceptor_handshake_state_buffer <= ANRS;
					end if;
				when ACDS =>
					-- 488.1 only specifies a T3 delay for ATN true, but we want it for ATN false too
					-- in order to allow user 2 cycles of ACDS to latch data byte.
					rdy := not T3_delay_satisfied;
					if (not rdy and to_X01(ATN) = '0') or 
						(DAC_holdoff = '0' and T3_delay_satisfied and to_X01(ATN) = '1') then
						acceptor_handshake_state_buffer <= AWNS;
					elsif to_X01(DAV) = '0' then
						acceptor_handshake_state_buffer <= ACRS;
						rdy := false; -- see comment in ACRS case
					end if;
					T3_delay_satisfied := true;
				when AWNS =>
					if to_X01(DAV) = '0' then
						acceptor_handshake_state_buffer <= ANRS;
					end if;
				when ANDS =>
					AH_counter_done := (AH_count >= T18_terminal_count);
					if not AH_counter_done then
						AH_count <= AH_count + 1;
					end if;

					if to_X01(DAV) = '0' and AH_counter_done then
						acceptor_handshake_state_buffer <= ANES;
					elsif to_X01(DAV) = '1' and 
						(to_X01(ATN) = '1' or acceptor_noninterlocked_state_buffer = ANCS) 
					then
						acceptor_handshake_state_buffer <= ANTS;
						T3_delay_satisfied := false;
					end if;
				when ANES =>
					if to_X01(DAV) = '1' then
						acceptor_handshake_state_buffer <= ANDS;
						AH_count <= to_unsigned(0, num_counter_bits);
					elsif to_X01(ATN) = '1' or acceptor_noninterlocked_state_buffer = ANCS then
						acceptor_handshake_state_buffer <= ACRS;
						rdy := false; -- see comment in ACRS case
					end if;
				when ANTS =>
					-- we don't need to use rdy to delay in this state, there
					-- should have been plenty of time (at least 2 cycles) for
					-- the user to latch the byte from the DIO lines already,
					-- since they should have initiated that on entering ANDS.
					rdy := false;
					if (to_X01(ATN) = '0' and not rdy) or
						(DAC_holdoff = '0' and T3_delay_satisfied and to_X01(ATN) = '1') then
						acceptor_handshake_state_buffer <= AWNS;
					end if;
					T3_delay_satisfied := true;
			end case;

			if to_X01(ATN) = '0' and not addressed then
				acceptor_handshake_state_buffer <= AIDS;
			end if;

			case acceptor_noninterlocked_state_buffer is
				when ANIS =>
					if to_X01(ATN) = '0' then
						acceptor_noninterlocked_state_buffer <= ANYS;
						noninterlocked_count <= to_unsigned(0, num_counter_bits);
					end if;
				when ANYS =>
					-- T16 counter
					noninterlocked_counter_done := noninterlocked_count >= T16_terminal_count;
					if not noninterlocked_counter_done then
						noninterlocked_count <= noninterlocked_count + 1;
					end if;

					-- transitions
					if to_X01(DAV) = '1' then
						acceptor_noninterlocked_state_buffer <= AIAS;
					elsif acceptor_handshake_state_buffer = ACRS and 
						to_X01(NIC) = '0' and -- in 488.1 this appears as a transition on RFD, which is the same as checking not NIC
						noninterlocked_counter_done
					then
						acceptor_noninterlocked_state_buffer <= AWAS;
					end if;
				when AWAS =>
					if to_X01(DAV) = '1' then
						acceptor_noninterlocked_state_buffer <= AIAS;
					elsif to_X01(NIC) = '1' then
						acceptor_noninterlocked_state_buffer <= ANCS;
					end if;
				when AIAS =>
				when ANCS =>
					if not lni_or_tcs then
						acceptor_noninterlocked_state_buffer <= ANAS;
					end if;
				when ANAS =>
					if lni_or_tcs then
						acceptor_noninterlocked_state_buffer <= ALNS;
						noninterlocked_count <= to_unsigned(0, num_counter_bits);
					end if;
				when ALNS =>
					-- T17 counter
					noninterlocked_counter_done := noninterlocked_count >= T17_terminal_count;
					if not noninterlocked_counter_done then
						noninterlocked_count <= noninterlocked_count + 1;
					end if;
					
					-- transitions
					if noninterlocked_counter_done then
						acceptor_noninterlocked_state_buffer <= ANCS;
					end if;
			end case;
			
			if to_X01(ATN) = '1' then
				acceptor_noninterlocked_state_buffer <= ANIS;
			end if;

			prev_ATN := to_X01(ATN);
		end if;
	end process;

	-- set local message outputs as soon as state changes for low latency
	process(acceptor_handshake_state_buffer, acceptor_noninterlocked_state_buffer, rft) begin
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
			when ANDS =>
				RFD <= 'H';
				if acceptor_noninterlocked_state_buffer = ANAS and to_X01(rft) = '1' then
					DAC <= 'H';
				else
					DAC <= '0';
				end if;
			when ANES =>
				RFD <= 'H';
				if acceptor_noninterlocked_state_buffer = ANAS and to_X01(rft) = '1' then
					DAC <= 'H';
				else
					DAC <= '0';
				end if;
			when ANTS =>
				RFD <= '0';
				DAC <= '0';
		end case;
	end process;
end interface_function_AH_arch;
