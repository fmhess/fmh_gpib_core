-- enum types for states of IEEE 488.1 interface functions
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017

package interface_function_states is

	type SH_state is (SIDS, SGNS, SDYS, STRS, SWNS, SIWS);
	type T_state_1 is (TIDS, TADS, TACS, SPAS);
	type T_state_2 is (SPIS, SPMS);
	type C_state_1 is (CIDS, CADS, CACS, CTRS, CSBS, CSHS, CSWS, CAWS, CPWS, CPPS);
	type C_state_2 is (CSNS, CSRS);
	type C_state_3 is (SNAS, SACS);
	type C_state_4 is (SRIS, SRAS, SRNS);
	type C_state_5 is (SIIS, SIAS, SINS);

end interface_function_states
