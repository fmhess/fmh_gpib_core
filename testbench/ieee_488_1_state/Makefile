
.PHONY: test_SH
test_SH:
	nvc -a ../../src/ieee_488_1_state/interface_function_states.vhd ../../src/ieee_488_1_state/interface_function_SH.vhd interface_function_SH_testbench.vhd 
	nvc -e interface_function_SH_testbench
	nvc -r interface_function_SH_testbench --wave

.PHONY: clean
clean:
	rm work/*
	rmdir work/

