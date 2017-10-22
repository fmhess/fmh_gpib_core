-- IEEE 488.1 source handshake interface function
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_states.all;

entity interface_function_SH is
	port(
		clock : in std_logic;
		talker_state_p1 : in T_state_p1;
		controller_state_p1 : in C_state_p1;
		ATN : in std_logic; -- negative logic
		NDAC : in std_logic; -- negative logic
		NRFD : in std_logic; -- negative logic
		nba : in std_logic;
		pon : in std_logic;
		first_T1_terminal_count : in std_logic_vector (15 downto 0); -- longer T1 used for first cycle only
		T1_terminal_count : in std_logic_vector (15 downto 0);
		check_for_listeners : in std_logic; -- do optional check in SDYS for listeners

		source_handshake_state : out SH_state;
		-- state from previous clock cycle, allows external code to trigger on arbitrary state transition
		old_source_handshake_state : out SH_state; 
		DAV : out std_logic; -- negative logic, asserted with '0' unasserted with 'Z'
		no_listeners : out std_logic -- pulses true during SDYS if no listeners are detected at end of T1 delay
	);
 
end interface_function_SH;
 
architecture interface_function_SH_arch of interface_function_SH is
 
	signal interrupt : boolean;
	signal active : boolean;
	signal T1_current_count : unsigned range 0 to T1_terminal_count'HIGH;
	signal T1_counter_done : boolean;
	signal first_cycle : boolean; -- we are on the first transfer since leaving SIDS
	-- used to insure we only report no listeners one time during SDYS
	signal no_listeners_reported : boolean;
	signal source_handshake_state_buffer : SH_state; -- work around inability to read outputs
 
begin
 
	interrupt <= (to_bit(ATN) = '0' and controller_state_p1 /= CACS and controller_state_p1 /= CTRS) or
		 (to_bit(ATN) = '1' and talker_state_p1 /= TACS and talker_state_p1 /= SPAS);
	active <= talker_state_p1 = TACS or talker_state_p1 = SPAS or controller_state_p1 = CACS;	
	source_handshake_state <= source_handshake_state_buffer;
		 
	process(pon, clock) begin
		if pon = '1' then
			source_handshake_state_buffer <= SIDS;
			old_source_handshake_state <= SIDS;
			DAV <= 'Z';
			no_listeners <= '0';
		elsif rising_edge(clock) then
			-- no_listeners only pulses high for 1 clock so clear it.  no_listeners may
			-- be set high (for a cycle) later in this process.
			no_listeners <= '0';
			old_source_handshake_state <= source_handshake_state_buffer;
			
			case source_handshake_state is
				when SIDS =>
					if active then
						source_handshake_state_buffer <= SGNS;
					end if;
					first_cycle <= true;
				when SGNS =>
					if nba = '1' then
						T1_current_count <= to_unsigned(0, T1_current_count'length);
						T1_counter_done <= false;
						no_listeners_reported <= false;
						source_handshake_state_buffer <= SDYS;
					elsif interrupt then
						source_handshake_state_buffer <= SIDS;
					end if;
				when SDYS =>
					-- check if T1 delay is done
					if (first_cycle and T1_current_count >= 
						unsigned(first_T1_terminal_count)) or
						(first_cycle = false and T1_current_count >= 
							unsigned(T1_terminal_count)) then
						T1_counter_done <= true;
					else
						T1_current_count <= T1_current_count + 1;
					end if;
					-- transitions
					if interrupt then
						source_handshake_state_buffer <= SIDS;
					elsif T1_counter_done and to_bit(NRFD) = '1' then
						if(check_for_listeners = '0' or to_bit(NDAC) = '0') then
							first_cycle <= false;
							DAV <= '0';
							source_handshake_state_buffer <= STRS;
						elsif (no_listeners_reported = false) then
							no_listeners <= '1';
							no_listeners_reported <= true;
						end if;
					end if;
				when STRS =>
					if interrupt then
						DAV <= 'Z';
						source_handshake_state_buffer <= SIWS;
					elsif to_bit(NDAC) = '1' then
						DAV <= 'Z';
						source_handshake_state_buffer <= SWNS;
					end if;
				when SWNS =>
					if nba = '0' then
						source_handshake_state_buffer <= SGNS;
					elsif interrupt then
						source_handshake_state_buffer <= SIWS;
					end if;
				when SIWS =>
					if nba = '0' then
						source_handshake_state_buffer <= SIDS;
					elsif active then
						source_handshake_state_buffer <= SWNS;
					end if;
					first_cycle <= true;
			end case;
		end if;
	end process;
end interface_function_SH_arch;
