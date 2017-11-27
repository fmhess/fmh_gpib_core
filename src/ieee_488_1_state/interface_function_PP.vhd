-- IEEE 488.1 parallel poll interface function
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity interface_function_PP is
	port(
		clock : in std_logic;
		acceptor_handshake_state : in AH_state;
		listener_state_p1 : in LE_state_p1;
		ATN : in std_logic;
		PPE : in std_logic;
		PPC : in std_logic;
		PPD : in std_logic;
		PPU : in std_logic;
		IDY : in std_logic;
		PCG : in std_logic;
		pon : in std_logic;
		lpe : in std_logic;
		ist : in std_logic;
		sense : in std_logic;
		-- P1, P2, P3 which together specifiy which DIO line to use for parallel poll response
		PPR_line : in std_logic_vector(2 downto 0);
		local_configuration_mode : in std_logic;
		
		parallel_poll_state_p1 : out PP_state_p1;
		parallel_poll_state_p2 : out PP_state_p2;
		PPR : out std_logic_vector(7 downto 0)
	);
 
end interface_function_PP;
 
architecture interface_function_PP_arch of interface_function_PP is
 
	signal parallel_poll_state_p1_buffer : PP_state_p1;
	signal parallel_poll_state_p2_buffer : PP_state_p2;
 
begin
 
	parallel_poll_state_p1 <= parallel_poll_state_p1_buffer;
	parallel_poll_state_p2 <= parallel_poll_state_p2_buffer;
		 
	process(pon, clock) begin
		if pon = '1' then
			parallel_poll_state_p1_buffer <= PPIS;
			parallel_poll_state_p2_buffer <= PUCS;
		elsif rising_edge(clock) then
		
			-- state machine part 1
			case parallel_poll_state_p1_buffer is
				when PPIS =>
					if to_bit(local_configuration_mode) = '1' then
						if to_bit(lpe) = '1' then
							parallel_poll_state_p1_buffer <= PPSS;
						end if;
					else
						if to_bit(PPE) = '1' and parallel_poll_state_p2_buffer = PACS and
							acceptor_handshake_state = ACDS then
							parallel_poll_state_p1_buffer <= PPSS;
						end if;
					end if;
				when PPSS =>
					if to_bit(local_configuration_mode) = '1' then
						if to_bit(lpe) = '0' then
							parallel_poll_state_p1_buffer <= PPIS;
						end if;
					else
						if ((to_bit(PPD) = '1' and parallel_poll_state_p2_buffer = PACS) or to_bit(PPU) = '1') and
							acceptor_handshake_state = ACDS then
							parallel_poll_state_p1_buffer <= PPIS;
						end if;
					end if;
					if to_bit(IDY) = '1' and to_bit(ATN) = '1' then
						parallel_poll_state_p1_buffer <= PPAS;
					end if;
				when PPAS =>
					-- 488.1 PP diagram has an error (though the textual description is correct)
					-- We should leave PPAS when either ATN or IDY is no longer true.
					if to_bit(ATN) = '0' or to_bit(IDY) = '0' then
						parallel_poll_state_p1_buffer <= PPSS;
					end if;
			end case;

			-- state machine part 2
			case parallel_poll_state_p2_buffer is
				when PUCS =>
					if to_bit(PPC) = '1' and listener_state_p1 = LADS and
							acceptor_handshake_state = ACDS then
							parallel_poll_state_p2_buffer <= PACS;
					end if;
				when PACS =>
					if to_bit(PCG) = '1' and to_bit(PPC) = '0' and
							acceptor_handshake_state = ACDS then
							parallel_poll_state_p2_buffer <= PUCS;
					end if;
			end case;
		end if;
	end process;

	-- set local message outputs as soon as state changes for low latency
	process(parallel_poll_state_p1_buffer, sense, ist, PPR_line) begin
		case parallel_poll_state_p1_buffer is
			when PPAS =>
				PPR <= "00000000";
				if to_bit(sense) = to_bit(ist) then
					PPR(to_integer(unsigned(PPR_line))) <= '1';
				end if;
			when others =>
				PPR <= "00000000";
		end case;
	end process;
	
end interface_function_PP_arch;
