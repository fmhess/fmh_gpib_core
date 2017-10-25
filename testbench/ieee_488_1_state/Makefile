
.PHONY: test_AH
test_AH:
	nvc -a ../../src/ieee_488_1_state/interface_function_states.vhd ../../src/ieee_488_1_state/interface_function_AH.vhd interface_function_AH_testbench.vhd 
	nvc -e interface_function_AH_testbench
	nvc -r interface_function_AH_testbench --wave

.PHONY: test_TE
test_TE:
	nvc -a ../../src/ieee_488_1_state/interface_function_states.vhd ../../src/ieee_488_1_state/interface_function_TE.vhd interface_function_TE_testbench.vhd 
	nvc -e interface_function_TE_testbench
	nvc -r interface_function_TE_testbench --wave

.PHONY: test_SH
test_SH:
	nvc -a ../../src/ieee_488_1_state/interface_function_states.vhd ../../src/ieee_488_1_state/interface_function_SH.vhd interface_function_SH_testbench.vhd 
	nvc -e interface_function_SH_testbench
	nvc -r interface_function_SH_testbench --wave

.PHONY: clean
clean:
	rm -f work/*
	-rmdir work/
	rm -f *.fst

