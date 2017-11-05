.PHONY: all
all: frontend_cb7210p2_testbench.fst

FRONTEND_CB7210P2_TEST_SRC = \
	../../src/ieee_488_1_state/interface_function_common.vhd \
	../../src/ieee_488_1_state/interface_function_AH.vhd \
	../../src/ieee_488_1_state/interface_function_C.vhd \
	../../src/ieee_488_1_state/interface_function_DC.vhd \
	../../src/ieee_488_1_state/interface_function_DT.vhd \
	../../src/ieee_488_1_state/interface_function_LE.vhd \
	../../src/ieee_488_1_state/interface_function_PP.vhd \
	../../src/ieee_488_1_state/interface_function_RL.vhd \
	../../src/ieee_488_1_state/interface_function_SH.vhd \
	../../src/ieee_488_1_state/interface_function_SR.vhd \
	../../src/ieee_488_1_state/interface_function_TE.vhd \
	../../src/ieee_488_1_state/remote_message_decoder.vhd \
	../../src/ieee_488_1_state/integrated_interface_functions.vhd \
	../../src/util/gpib_transceiver.vhd \
	../../src/frontends/frontend_cb7210p2.vhd \
	frontend_cb7210p2_testbench.vhd
frontend_cb7210p2_testbench.fst: $(FRONTEND_CB7210P2_TEST_SRC)
	nvc -a $(FRONTEND_CB7210P2_TEST_SRC)
	nvc -e frontend_cb7210p2_testbench
	nvc -r frontend_cb7210p2_testbench --wave 

.PHONY: clean
clean:
	rm -f work/*
	-rmdir work/
	rm -f *.fst

