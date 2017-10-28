-- common stuff used by different IEEE 488.1 interface functions
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017

package interface_function_common is

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

	constant NO_ADDRESS_CONFIGURED : bit_vector := "11111";

end interface_function_common;
