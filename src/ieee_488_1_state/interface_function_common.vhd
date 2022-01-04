-- Copyright 2017 Frank Mori Hess fmh6jj@gmail.com

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--    http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
------------------------------------------------------------------------------

-- common stuff used by different IEEE 488.1 interface functions

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package interface_function_common is

	-- 488.1 interface function states
	type AH_state is (AIDS, ANRS, ACRS, ACDS, AWNS, ANDS, ANES, ANTS);
	type AH_noninterlocked_state is (ANIS, ANYS, AWAS, AIAS, ANCS, ANAS, ALNS);
	type C_state_p1 is (CIDS, CADS, CACS, CTRS, CSBS, CSHS, CSWS, CAWS, CPWS, CPPS);
	type C_state_p2 is (CSNS, CSRS);
	type C_state_p3 is (SNAS, SACS);
	type C_state_p4 is (SRIS, SRAS, SRNS);
	type C_state_p5 is (SIIS, SIAS, SINS);
	type CF_state_p1 is (CNCS, CnnS);
	type CF_state_p2 is (NCIS, NCAS);
	type DC_state is (DCIS, DCAS);
	type DT_state is (DTIS, DTAS);
	type LE_state_p1 is (LIDS, LADS, LACS);
	type LE_state_p2 is (LPIS, LPAS);
	type PP_state_p1 is (PPIS, PPSS, PPAS);
	type PP_state_p2 is (PUCS, PACS);
	type RL_state is (LOCS, REMS, RWLS, LWLS);
	type SH_state is (SIDS, SGNS, SDYS, STRS, SWNS, SIWS, SWRS, SRDS, SNGS);
	type SH_noninterlocked_state is (SNDS, SNES);
	type SR_state is (NPRS, SRQS, APRS);
	type TE_state_p1 is (TIDS, TADS, TACS, SPAS);
	type TE_state_p2 is (TPIS, TPAS);
	type TE_state_p3 is (SPIS, SPMS);

	-- 488.2 states
	-- the 488.2 names for the set rsv states collide with unrelated 488.1 states (SRIS and SRAS) so we make up new names
	type set_rsv_enum is (set_rsv_idle, set_rsv_wait, set_rsv_active);
	
	type RFD_holdoff_enum is (holdoff_normal, holdoff_on_all, holdoff_on_end, continuous_mode);

	type time_selection_enum is (ts_350ns, ts_500ns, ts_750ns, ts_1000ns, ts_1100ns, ts_1500ns, ts_2000ns) ;
	
	constant NO_ADDRESS_CONFIGURED : std_logic_vector := "11111";

	function to_X0Z (mysig : std_logic) return std_logic;
	function to_X0Z (myvector : std_logic_vector) return std_logic_vector;
	function EOS_match (byte_A : std_logic_vector(7 downto 0); 
		byte_B : std_logic_vector(7 downto 0);
		ignore_eos_bit_7 : std_logic) return boolean;
	function is_unrecognized_primary_command (byte : std_logic_vector(7 downto 0)) return boolean;
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
	
	function is_unrecognized_primary_command (byte : std_logic_vector(7 downto 0)) return boolean is
		variable unsigned_stripped_byte : unsigned(7 downto 0);
	begin
		unsigned_stripped_byte(6 downto 0) := unsigned(to_X01(byte(6 downto 0)));
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
			(unsigned_stripped_byte >= X"1a" and unsigned_stripped_byte <= X"1e");
	end is_unrecognized_primary_command;

	function is_addressed_command (byte : std_logic_vector(7 downto 0)) return boolean is
	begin
		return byte(6 downto 4) = "000";
	end is_addressed_command;
end package body interface_function_common;
