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
		T8_count_per_us : in unsigned(num_counter_bits - 1 downto 0);
		T9_terminal_count : in unsigned(num_counter_bits - 1 downto 0);
		T10_terminal_count : in unsigned(num_counter_bits - 1 downto 0);
		
		ATN_out : out std_logic;
		IDY_out : out std_logic;
		IFC_out : out std_logic;
		REN_out : out std_logic;
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
			counter_done := false;
			current_count := (others => '0');
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
	
	-- controller state part 2
	controller_state_p2_buffer <= CSRS when SRQ_in = '1' else CSNS;

	-- controller state part 3
	controller_state_p3_buffer <= SACS when rsc = '1' else SNAS;
	
	-- controller state part 4
	process(pon, clock)
		variable T8_counter_done : boolean;
		variable T8_current_count : unsigned(num_counter_bits - 1 downto 0);
		variable microseconds : unsigned(6 downto 0);

		procedure increment_T8_count is
		begin
			if T8_counter_done = false then
				if T8_current_count < T8_count_per_us then
					T8_current_count := T8_current_count + 1;
				else
					microseconds := microseconds + 1;
					T8_current_count := (others => '0');
				end if;
				if microseconds >= to_unsigned(100, microseconds'LENGTH) then
					T8_counter_done := true;
				end if;
			end if;
		end increment_T8_count;

		procedure init_T8_count is
		begin
			T8_counter_done := false;
			T8_current_count := (others => '0');
			microseconds := (others => '0');
		end init_T8_count;
	begin
		if to_X01(pon) = '1' then
			init_T8_count;
			controller_state_p4_buffer <= SRIS;
		elsif rising_edge(clock) then
			case controller_state_p4_buffer is
				when SRIS =>
					increment_T8_count;
					--transitions
					if controller_state_p3_buffer = SACS then
						if sre = '0' then
							controller_state_p4_buffer <= SRNS;
							init_T8_count;
						elsif T8_counter_done then
							controller_state_p4_buffer <= SRAS;
						end if;
					end if;
				when SRAS =>
					if sre = '0' then
						controller_state_p4_buffer <= SRNS;
						init_T8_count;
					end if;
				when SRNS =>
					if sre = '1' then
						increment_t8_count;
						if T8_counter_done then
							controller_state_p4_buffer <= SRAS;
						end if;
					else
						init_T8_count;
					end if;
			end case;
			if controller_state_p3_buffer /= SACS then
				controller_state_p4_buffer <= SRIS;
				init_T8_count;
			end if;
		end if;
	end process;

	-- controller state part 5
	process(pon, clock)
		variable T8_counter_done : boolean;
		variable T8_current_count : unsigned(num_counter_bits - 1 downto 0);
		variable microseconds : unsigned(6 downto 0);

		procedure increment_T8_count is
		begin
			if T8_counter_done = false then
				if T8_current_count < T8_count_per_us then
					T8_current_count := T8_current_count + 1;
				else
					microseconds := microseconds + 1;
					T8_current_count := (others => '0');
				end if;
				if microseconds >= to_unsigned(100, microseconds'LENGTH) then
					T8_counter_done := true;
				end if;
			end if;
		end increment_T8_count;

		procedure init_T8_count is
		begin
			T8_counter_done := false;
			T8_current_count := (others => '0');
			microseconds := (others => '0');
		end init_T8_count;
	begin
		if to_X01(pon) = '1' then
			init_T8_count;
			controller_state_p5_buffer <= SIIS;
		elsif rising_edge(clock) then
			case controller_state_p5_buffer is
				when SIIS =>
					if controller_state_p3_buffer = SACS then
						if sic = '1' then
							controller_state_p5_buffer <= SIAS;
							init_T8_count;
						else
							controller_state_p5_buffer <= SINS;
						end if;
					end if;
				when SIAS =>
					increment_T8_count;
					if sic = '0' and T8_counter_done then
						controller_state_p5_buffer <= SINS;
					end if;
				when SINS =>
					if sic = '1' then
						controller_state_p5_buffer <= SIAS;
						init_T8_count;
					end if;
			end case;
			if controller_state_p3_buffer /= SACS then
				controller_state_p5_buffer <= SIIS;
			end if;
		end if;
	end process;

	-- set outputs
	process (controller_state_p1_buffer)
	begin
		TCT_out <= 'L';
		case controller_state_p1_buffer is
			when CIDS =>
				ATN_out <= 'L';
				IDY_out <= 'L';
			when CADS =>
				ATN_out <= 'L';
				IDY_out <= 'L';
			when CACS =>
				ATN_out <= '1';
				IDY_out <= '0';
			when CPWS =>
				ATN_out <= '1';
				IDY_out <= '1';
			when CPPS =>
				ATN_out <= '1';
				IDY_out <= '1';
			when CSBS =>
				ATN_out <= '0';
				IDY_out <= 'L';
			when CSHS =>
				ATN_out <= '0';
				IDY_out <= 'L';
			when CSWS =>
				ATN_out <= '1';
				IDY_out <= '0';
			when CAWS =>
				ATN_out <= '1';
				IDY_out <= '0';
			when CTRS =>
				ATN_out <= '1';
				IDY_out <= '0';
				TCT_out <= '1';
		end case;
	end process;

	process (controller_state_p4_buffer)
	begin
		case controller_state_p4_buffer is
			when SRIS =>
				REN_out <= 'L';
			when SRNS =>
				REN_out <= '0';
			when SRAS =>
				REN_out <= '1';
		end case;
	end process;

	process (controller_state_p5_buffer)
	begin
		case controller_state_p5_buffer is
			when SIIS =>
				IFC_out <= 'L';
			when SINS =>
				IFC_out <= '0';
			when SIAS =>
				IFC_out <= '1';
		end case;
	end process;
	
	controller_state_p1 <= controller_state_p1_buffer;
	controller_state_p2 <= controller_state_p2_buffer;
	controller_state_p3 <= controller_state_p3_buffer;
	controller_state_p4 <= controller_state_p4_buffer;
	controller_state_p5 <= controller_state_p5_buffer;
	
end interface_function_C_arch;
