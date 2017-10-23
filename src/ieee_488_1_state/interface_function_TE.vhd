-- IEEE 488.1 extended talker TE and talker T interface functions.  Implements TE5 and T5.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_states.all;

entity interface_function_TE is
	port(
		clock : in std_logic;
		acceptor_handshake_state : in AH_state;
		listener_state : in L_state;
		service_request_state : in SR_state;
		ATN : in std_logic;
		IFC : in std_logic;
		pon : in std_logic;
		ton : in std_logic;
		MTA : in std_logic;
		MSA : in std_logic;
		OTA : in std_logic;
		OSA : in std_logic;
		MLA : in std_logic;
		SPE : in std_logic;
		SPD : in std_logic;
		PCG : in std_logic;
		enable_secondary_addressing : in std_logic; -- true for extended talker, false for talker
		
		talker_state_p1 : out TE_state_p1;
		talker_state_p2 : out TE_state_p2;
		talker_state_p3 : out TE_state_p3;
		-- state from previous clock cycle, allows external code to trigger on arbitrary state transition
		old_talker_state_p1 : out TE_state_p1;
		old_talker_state_p2 : out TE_state_p2;
		old_talker_state_p3 : out TE_state_p3;
		END_msg : out std_logic;
		RQS : out std_logic;
		NUL : out std_logic;
	);
 
end interface_function_TE;
 
architecture interface_function_TE_arch of interface_function_TE is
 
	signal talker_state_p1_buffer : TE_state_p1;
	signal talker_state_p2_buffer : TE_state_p2;
	signal talker_state_p3_buffer : TE_state_p3;
	signal TE_addressed : std_logic;
	signal T_addressed : std_logic;
	signal addressed : std_logic;
	signal TE_unaddressed : std_logic;
	signal T_unaddressed : std_logic;
	signal unaddressed : std_logic;
	
begin
 
	talker_state_p1 <= talker_state_p1_buffer;
	talker_state_p2 <= talker_state_p2_buffer;
	talker_state_p3 <= talker_state_p3_buffer;
	
	T_addressed <= not IFC and MTA and acceptor_handshake_state = ACDS;		
	TE_addressed <= not IFC and MSA and talker_state_p2_buffer = TPAS and acceptor_handshake_state = ACDS;		
	addressed <= (not IFC and ton) or ((enable_secondary_addressing and TE_addressed) or
		(not enable_secondary_addressing and T_addressed));

	T_unaddressed <= OTA or MLA;
	TE_unaddressed <= OTA or (OSA and talker_state_p2 = TPAS) or (MSA and listener_state = LPAS);
	unaddressed <= acceptor_handshake_state = ACDS and ((enable_secondary_addressing and TE_unaddressed) or
		(not enable_secondary_addressing and T_unaddressed));

	
	process(pon, clock) begin
		if pon = '1' then
			talker_state_p1_buffer <= TIDS;
			old_talker_state_p1 <= TIDS;
			talker_state_p2_buffer <= TPIS;
			old_talker_state_p2 <= TPIS;
			talker_state_p3_buffer <= SPIS;
			old_talker_state_p3 <= SPIS;
			END_msg <= 'L';
			RQS <= 'L';
			NUL <= 'H';
		elsif rising_edge(clock) then
			old_talker_state_p1 <= talker_state_p1_buffer;
			old_talker_state_p2 <= talker_state_p2_buffer;
			old_talker_state_p3 <= talker_state_p3_buffer;
			
			-- part 1 state machine
			case talker_state_p1_buffer is
				when TIDS =>
					if addressed then
						talker_state_p1_buffer <= TADS;
					end if;
					
					END_msg <= 'L';
					RQS <= 'L';
					NUL <= 'H';
				when TADS =>
					if unaddressed then
						talker_state_p1_buffer <= TIDS;
					elsif not ATN then
						if talker_state_p3_buffer /= SPMS then
							talker_state_p1_buffer <= TACS;
						else
							talker_state_p1_buffer <= SPAS;
						end if;
					end if;
					
					END_msg <= 'L';
					RQS <= 'L';
					NUL <= 'H';
				when TACS =>
					if ATN then
						talker_state_p1_buffer <= TADS;
					end if;
					END_msg <= 'Z';
					RQS <= 'L';
					NUL <= 'Z';
				when SPAS =>
					if ATN then
						talker_state_p1_buffer <= TADS;
					end if;
					END_msg <= '0';
					RQS <= service_request_state = APRS;
					NUL <= 'Z';
			end case;

			-- part 2 state machine
			case talker_state_p2_buffer is
				when TPIS =>
					if MTA and acceptor_handshake_state = ACDS then
						talker_state_p2_buffer <= TPAS;
					end if;
				when TPAS =>
					if PCG and not MTA and acceptor_handshake_state = ACDS then
						talker_state_p2_buffer <= TPIS;
					end if;
			end case;

			-- part 3 state machine
			case talker_state_p3_buffer is
				when SPIS =>
					if not IFC and SPE and acceptor_handshake_state = ACDS then
						talker_state_p3_buffer <= SPMS;
					end if;
				when SPMS =>
					if SPD and acceptor_handshake_state = ACDS then
						talker_state_p3_buffer <= SPIS;
					end if;
			end case;

			if to_bit(IFC) = '1' then
				talker_state_p1 <= TIDS;
				talker_state_p3 <= SPIS;
			end if;

		end if;
	end process;
end interface_function_TE_arch;
