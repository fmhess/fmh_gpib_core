.PHONY: all
all: interface_function_LE_testbench.fst \
	interface_function_TE_testbench.fst \
	interface_function_AH_testbench.fst \
	interface_function_SH_testbench.fst \
	interface_function_PP_testbench.fst \
	interface_function_RL_testbench.fst \
	interface_function_SR_testbench.fst \

SR_TEST_SRC = ../../src/ieee_488_1_state/interface_function_states.vhd \
	../../src/ieee_488_1_state/interface_function_SR.vhd \
	interface_function_SR_testbench.vhd
interface_function_SR_testbench.fst: $(SR_TEST_SRC)
	nvc -a $(SR_TEST_SRC)
	nvc -e interface_function_SR_testbench
	nvc -r interface_function_SR_testbench --wave

RL_TEST_SRC = ../../src/ieee_488_1_state/interface_function_states.vhd \
	../../src/ieee_488_1_state/interface_function_RL.vhd \
	interface_function_RL_testbench.vhd
interface_function_RL_testbench.fst: $(RL_TEST_SRC)
	nvc -a $(RL_TEST_SRC)
	nvc -e interface_function_RL_testbench
	nvc -r interface_function_RL_testbench --wave

PP_TEST_SRC = ../../src/ieee_488_1_state/interface_function_states.vhd \
	../../src/ieee_488_1_state/interface_function_PP.vhd \
	interface_function_PP_testbench.vhd
interface_function_PP_testbench.fst: $(PP_TEST_SRC)
	nvc -a $(PP_TEST_SRC)
	nvc -e interface_function_PP_testbench
	nvc -r interface_function_PP_testbench --wave

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

