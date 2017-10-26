.PHONY: all
all: interface_function_LE_testbench.fst \
	interface_function_TE_testbench.fst \
	interface_function_AH_testbench.fst \
	interface_function_SH_testbench.fst

LE_TEST_SRC = ../../src/ieee_488_1_state/interface_function_states.vhd \
	../../src/ieee_488_1_state/interface_function_LE.vhd \
	interface_function_LE_testbench.vhd
interface_function_LE_testbench.fst: $(LE_TEST_SRC)
	nvc -a $(LE_TEST_SRC)
	nvc -e interface_function_LE_testbench
	nvc -r interface_function_LE_testbench --wave

TE_TEST_SRC = ../../src/ieee_488_1_state/interface_function_states.vhd \
	../../src/ieee_488_1_state/interface_function_TE.vhd \
	interface_function_TE_testbench.vhd
interface_function_TE_testbench.fst: $(TE_TEST_SRC)
	nvc -a $(TE_TEST_SRC)
	nvc -e interface_function_TE_testbench
	nvc -r interface_function_TE_testbench --wave

AH_TEST_SRC = ../../src/ieee_488_1_state/interface_function_states.vhd \
	../../src/ieee_488_1_state/interface_function_AH.vhd \
	interface_function_AH_testbench.vhd
interface_function_AH_testbench.fst: $(AH_TEST_SRC)
	nvc -a $(AH_TEST_SRC)
	nvc -e interface_function_AH_testbench
	nvc -r interface_function_AH_testbench --wave

SH_TEST_SRC = ../../src/ieee_488_1_state/interface_function_states.vhd \
	../../src/ieee_488_1_state/interface_function_SH.vhd \
	interface_function_SH_testbench.vhd
interface_function_SH_testbench.fst: $(SH_TEST_SRC)
	nvc -a $(SH_TEST_SRC)
	nvc -e interface_function_SH_testbench
	nvc -r interface_function_SH_testbench --wave

.PHONY: clean
clean:
	rm -f work/*
	-rmdir work/
	rm -f *.fst

