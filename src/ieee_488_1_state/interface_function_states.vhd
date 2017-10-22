-- enum types for states of IEEE 488.1 interface functions
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017

package interface_function_states is

	type SH_state is (SIDS, SGNS, SDYS, STRS, SWNS, SIWS);
	type TE_state_p1 is (TIDS, TADS, TACS, SPAS);
	type TE_state_p2 is (TPIS, TPAS);
	type TE_state_p3 is (SPIS, SPMS);
	type C_state_p1 is (CIDS, CADS, CACS, CTRS, CSBS, CSHS, CSWS, CAWS, CPWS, CPPS);
	type C_state_p2 is (CSNS, CSRS);
	type C_state_p3 is (SNAS, SACS);
	type C_state_p4 is (SRIS, SRAS, SRNS);
	type C_state_p5 is (SIIS, SIAS, SINS);
	type AH_state is (AIDS, ANRS, ACRS, ACDS, AWNC);
	type L_state is (LIDS, LADS, LACS);

end interface_function_states;
