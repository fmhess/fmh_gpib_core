-- common stuff used by different IEEE 488.1 interface functions
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package interface_function_common is

	-- 488.1 interface function states
	type AH_state is (AIDS, ANRS, ACRS, ACDS, AWNS);
	type C_state_p1 is (CIDS, CADS, CACS, CTRS, CSBS, CSHS, CSWS, CAWS, CPWS, CPPS);
	type C_state_p2 is (CSNS, CSRS);
	type C_state_p3 is (SNAS, SACS);
	type C_state_p4 is (SRIS, SRAS, SRNS);
	type C_state_p5 is (SIIS, SIAS, SINS);
	type DC_state is (DCIS, DCAS);
	type DT_state is (DTIS, DTAS);
	type LE_state_p1 is (LIDS, LADS, LACS);
	type LE_state_p2 is (LPIS, LPAS);
	type PP_state_p1 is (PPIS, PPSS, PPAS);
	type PP_state_p2 is (PUCS, PACS);
	type RL_state is (LOCS, REMS, RWLS, LWLS);
	type SH_state is (SIDS, SGNS, SDYS, STRS, SWNS, SIWS);
	type SR_state is (NPRS, SRQS, APRS);
	type TE_state_p1 is (TIDS, TADS, TACS, SPAS);
	type TE_state_p2 is (TPIS, TPAS);
	type TE_state_p3 is (SPIS, SPMS);
	
	type RFD_holdoff_enum is (holdoff_normal, holdoff_on_all, holdoff_on_end, continuous_mode);

	constant NO_ADDRESS_CONFIGURED : std_logic_vector := "11111";

	function to_X0Z (mysig : std_logic) return std_logic;
	function to_X0Z (myvector : std_logic_vector) return std_logic_vector;
	function EOS_match (byte_A : std_logic_vector(7 downto 0); 
		byte_B : std_logic_vector(7 downto 0);
		ignore_eos_bit_7 : std_logic) return boolean;
	function is_passthrough_primary_command (byte : std_logic_vector; listener_state : LE_state_p1) return boolean;
	function is_unrecognized_primary_command (byte : std_logic_vector) return boolean;
	function is_addressed_command (byte : std_logic_vector(7 downto 0)) return boolean;

end interface_function_common;

package body interface_function_common is
	function to_X0Z (mysig : std_logic) return std_logic is
		variable mysig_X01 : std_logic;
	begin
		mysig_X01 := to_X01(mysig);
		case mysig_X01 is
			when '0' => return '0';
			when '1' => return 'Z';
			when others => return 'X';
		end case;
	end to_X0Z;
	
	function to_X0Z (myvector : std_logic_vector) return std_logic_vector is
		variable result : std_logic_vector(myvector'RANGE);
	begin
		for i in myvector'LOW to myvector'HIGH loop
			result(i) := to_X0Z(myvector(i));
		end loop;
		return result;
	end to_X0Z;
	
	function EOS_match (byte_A : std_logic_vector(7 downto 0); 
		byte_B : std_logic_vector(7 downto 0);
		ignore_eos_bit_7 : std_logic) return boolean is
	begin
		return to_X01(byte_A(6 downto 0)) = to_X01(byte_B(6 downto 0)) and
		(ignore_eos_bit_7 = '1' or to_X01(byte_A(7)) = to_X01(byte_B(7)));
	end EOS_match;
	
	
	function is_passthrough_primary_command (byte : std_logic_vector(7 downto 0);
		listener_state : LE_state_p1) return boolean is
		variable unsigned_stripped_byte : unsigned(7 downto 0);
	begin
		unsigned_stripped_byte(6 downto 0) := to_01(unsigned(byte(6 downto 0)));
		unsigned_stripped_byte(7) := '0';
		if is_addressed_command(byte) and listener_state /= LIDS then
			-- these are addressed commands and should be ignored if they were
			-- not directed at us.
			return unsigned_stripped_byte = X"00" or
				unsigned_stripped_byte = X"02" or
				unsigned_stripped_byte = X"03" or
				unsigned_stripped_byte = X"06" or
				unsigned_stripped_byte = X"07" or
				(unsigned_stripped_byte >= X"0a" and unsigned_stripped_byte <= X"0f");
		else
			return 
				unsigned_stripped_byte = X"10" or
				unsigned_stripped_byte = X"12" or
				unsigned_stripped_byte = X"13" or
				unsigned_stripped_byte = X"16" or
				unsigned_stripped_byte = X"17" or
				(unsigned_stripped_byte >= X"1a" and unsigned_stripped_byte <= X"1f");
		end if;
	end is_passthrough_primary_command;
	
	function is_unrecognized_primary_command (byte : std_logic_vector(7 downto 0)) return boolean is
		variable unsigned_stripped_byte : unsigned(7 downto 0);
	begin
		unsigned_stripped_byte(6 downto 0) := to_01(unsigned(byte(6 downto 0)));
		unsigned_stripped_byte(7) := '0';
		return unsigned_stripped_byte = X"00" or
			unsigned_stripped_byte = X"02" or
			unsigned_stripped_byte = X"03" or
			unsigned_stripped_byte = X"06" or
			unsigned_stripped_byte = X"07" or
			(unsigned_stripped_byte >= X"0a" and unsigned_stripped_byte <= X"0f") or
			unsigned_stripped_byte = X"10" or
			unsigned_stripped_byte = X"12" or
			unsigned_stripped_byte = X"13" or
			unsigned_stripped_byte = X"16" or
			unsigned_stripped_byte = X"17" or
			(unsigned_stripped_byte >= X"1a" and unsigned_stripped_byte <= X"1f");
	end is_unrecognized_primary_command;

	function is_addressed_command (byte : std_logic_vector(7 downto 0)) return boolean is
	begin
		return byte(6 downto 4) = "000";
	end is_addressed_command;
end package body interface_function_common;
