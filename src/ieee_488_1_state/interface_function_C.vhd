-- IEEE 488.1 controller interface function.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity interface_function_C is
	generic( num_counter_bits : in integer := 8);
	port(
		clock : in std_logic;
		pon : in std_logic;
		gts : in std_logic;
		rpp : in std_logic;
		rsc : in std_logic;
		sre : in std_logic;
		sic : in std_logic;
		tcs : in std_logic;
		tca : in std_logic;
		ATN_in : in std_logic;
		IFC_in : in std_logic;
		SRQ_in : in std_logic;
		TCT_in : in std_logic;
		acceptor_handshake_state : in AH_state;
		source_handshake_state : in SH_state;
		talker_state_p1 : in TE_state_p1;
		T6_terminal_count : in unsigned(num_counter_bits - 1 downto 0);
		T7_terminal_count : in unsigned(num_counter_bits - 1 downto 0);
		T8_terminal_count : in unsigned(num_counter_bits - 1 downto 0);
		T9_terminal_count : in unsigned(num_counter_bits - 1 downto 0);
		T10_terminal_count : in unsigned(num_counter_bits - 1 downto 0);
		
		ATN_out : out std_logic;
		IDY_out : out std_logic;
		IFC_out : out std_logic;
		REN_out : out std_logic;
		NUL_out : out std_logic;
		TCT_out : out std_logic;
		
		controller_state_p1 : out C_state_p1;
		controller_state_p2 : out C_state_p2;
		controller_state_p3 : out C_state_p3;
		controller_state_p4 : out C_state_p4;
		controller_state_p5 : out C_state_p5
	);
 
end interface_function_C;
 
architecture interface_function_C_arch of interface_function_C is
	signal controller_state_p1_buffer : C_state_p1;
	signal controller_state_p2_buffer : C_state_p2;
	signal controller_state_p3_buffer : C_state_p3;
	signal controller_state_p4_buffer : C_state_p4;
	signal controller_state_p5_buffer : C_state_p5;
begin

	-- controller state part 1
	process(pon, clock) 
		variable counter_done : boolean;
		variable current_count : unsigned(num_counter_bits - 1 downto 0);
	begin
		if to_X01(pon) = '1' then
			controller_state_p1_buffer <= CIDS;
		elsif rising_edge(clock) then
			case controller_state_p1_buffer is
				when CIDS =>
					if (IFC_in = '0' and acceptor_handshake_state = ACDS and TCT_in = '1' and talker_state_p1 = TADS) or
						controller_state_p5_buffer = SIAS then
						controller_state_p1_buffer <= CADS;
					end if;
				when CADS =>
					if ATN_in = '0' then
						controller_state_p1_buffer <= CACS;
					end if;
				when CACS =>
					if TCT_in = '1' and acceptor_handshake_state = ACDS and talker_state_p1 /= TADS then
						controller_state_p1_buffer <= CTRS;
					end if;
					if source_handshake_state /= STRS and source_handshake_state /= SDYS then
						if gts = '1' then
							controller_state_p1_buffer <= CSBS;
						end if;
						if rpp = '1' then
							controller_state_p1_buffer <= CPWS;
						end if;
					end if;
				when CTRS =>
					if source_handshake_state /= STRS then
						controller_state_p1_buffer <= CIDS;
					end if;
				when CSBS =>
					if tcs = '1' and acceptor_handshake_state = ANRS then
						controller_state_p1_buffer <= CSHS;
						counter_done := false;
						current_count := (others => '0');
					end if;
					if tca = '1' then
						controller_state_p1_buffer <= CSWS;
					end if;
				when CSHS =>
					--T10 counter
					if counter_done = false then
						if current_count < T10_terminal_count then
							current_count := current_count + 1;
						else
							counter_done := true;
						end if;
					end if;
					--transitions
					if tcs = '0' then
						controller_state_p1_buffer <= CSBS;
					end if;
					if counter_done then
						controller_state_p1_buffer <= CSWS;
						counter_done := false;
						current_count := (others => '0');
					end if;
				when CSWS =>
					--T7 counter
					if counter_done = false then
						if current_count < T7_terminal_count then
							current_count := current_count + 1;
						else
							counter_done := true;
						end if;
					end if;
					--transitions
					if talker_state_p1 = TADS or counter_done then
						controller_state_p1_buffer <= CAWS;
						counter_done := false;
						current_count := (others => '0');
					end if;
				when CAWS =>
					--T9 counter
					if counter_done = false then
						if current_count < T9_terminal_count then
							current_count := current_count + 1;
						else
							counter_done := true;
						end if;
					end if;
					--transitions
					if counter_done and rpp = '0' then
						controller_state_p1_buffer <= CACS;
					end if;
					if rpp = '1' then
						controller_state_p1_buffer <= CPWS;
						counter_done := false;
						current_count := (others => '0');
					end if;
				when CPWS =>
					--T6 counter
					if counter_done = false then
						if current_count < T6_terminal_count then
							current_count := current_count + 1;
						else
							counter_done := true;
						end if;
					end if;
					--transitions
					if counter_done then
						controller_state_p1_buffer <= CPPS;
					end if;
					if rpp = '0' then
						controller_state_p1_buffer <= CAWS;
					end if;
				when CPPS =>
					if rpp = '0' then
						controller_state_p1_buffer <= CAWS;
					end if;
			end case;
		end if;
		
		if IFC_in = '1' and controller_state_p3_buffer /= SACS then
			controller_state_p1_buffer <= CIDS;
		end if;
	end process;
	
	-- controller state part 1 outputs
	
	-- constroller state part 2
	process(pon, clock)
	begin
		if to_X01(pon) = '1' then
			controller_state_p2_buffer <= CSNS;
		elsif rising_edge(clock) then
		end if;
	end process;

	-- constroller state part 3
	process(pon, clock)
	begin
		if to_X01(pon) = '1' then
			controller_state_p3_buffer <= SNAS;
		elsif rising_edge(clock) then
		end if;
	end process;
	
	-- constroller state part 4
	process(pon, clock)
	begin
		if to_X01(pon) = '1' then
			controller_state_p4_buffer <= SRIS;
		elsif rising_edge(clock) then
		end if;
	end process;

	-- constroller state part 5
	process(pon, clock)
	begin
		if to_X01(pon) = '1' then
			controller_state_p5_buffer <= SIIS;
		elsif rising_edge(clock) then
		end if;
	end process;

	controller_state_p1 <= controller_state_p1_buffer;
	controller_state_p2 <= controller_state_p2_buffer;
	controller_state_p3 <= controller_state_p3_buffer;
	controller_state_p4 <= controller_state_p4_buffer;
	controller_state_p5 <= controller_state_p5_buffer;
	
	ATN_out <= 'L';
	IDY_out <= 'L';
	NUL_out <= 'H';
	REN_out <= 'L';
	TCT_out <= 'L';
end interface_function_C_arch;
