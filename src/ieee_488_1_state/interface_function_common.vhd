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

	constant NO_ADDRESS_CONFIGURED : bit_vector := "11111";

	function to_X0Z (mysig : std_logic) return std_logic;
	function to_X0Z (myvector : std_logic_vector) return std_logic_vector;

end interface_function_common;

package body interface_function_common is
	function to_X0Z (mysig : std_logic) return std_logic is
	begin
		case mysig is
			when '0' => return '0';
			when 'L' => return '0';
			when '1' => return 'Z';
			when 'H' => return 'Z';
			when 'Z' => return 'Z';
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
	
end package body interface_function_common;
