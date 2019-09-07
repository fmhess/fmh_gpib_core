.PHONY: all
all: frontend_cb7210p2_testbench.fst \
	dual_cb7210p2_testbench.fst \
	dual_integrated_cb7210p2_testbench.fst

FRONTEND_CB7210P2_TEST_SRC = \
	../../src/ieee_488_1_state/interface_function_common.vhd \
	../../src/ieee_488_1_state/interface_function_AH.vhd \
	../../src/util/std_fifo.vhd \
	../../src/ieee_488_1_state/acceptor_fifo.vhd \
	../../src/ieee_488_1_state/interface_function_C.vhd \
	../../src/ieee_488_1_state/interface_function_CF.vhd \
	../../src/ieee_488_1_state/interface_function_DC.vhd \
	../../src/ieee_488_1_state/interface_function_DT.vhd \
	../../src/ieee_488_1_state/interface_function_LE.vhd \
	../../src/ieee_488_1_state/interface_function_PP.vhd \
	../../src/ieee_488_1_state/interface_function_RL.vhd \
	../../src/ieee_488_1_state/interface_function_SH.vhd \
	../../src/ieee_488_1_state/interface_function_SR.vhd \
	../../src/ieee_488_1_state/set_rsv_488_2.vhd \
	../../src/ieee_488_1_state/interface_function_TE.vhd \
	../../src/ieee_488_1_state/remote_message_decoder.vhd \
	../../src/ieee_488_1_state/integrated_interface_functions.vhd \
	../../src/util/gpib_transceiver.vhd \
	../../src/frontends/frontend_cb7210p2.vhd \
	../test_common.vhd \
	frontend_cb7210p2_testbench.vhd
frontend_cb7210p2_testbench.fst: $(FRONTEND_CB7210P2_TEST_SRC)
	nvc -a $(FRONTEND_CB7210P2_TEST_SRC)
	nvc -e frontend_cb7210p2_testbench
	nvc -r frontend_cb7210p2_testbench --wave 

DUAL_CB7210P2_TEST_SRC = \
	../../src/util/std_fifo.vhd \
	../../src/ieee_488_1_state/acceptor_fifo.vhd \
	../../src/ieee_488_1_state/interface_function_common.vhd \
	../../src/ieee_488_1_state/interface_function_AH.vhd \
	../../src/ieee_488_1_state/interface_function_C.vhd \
	../../src/ieee_488_1_state/interface_function_CF.vhd \
	../../src/ieee_488_1_state/interface_function_DC.vhd \
	../../src/ieee_488_1_state/interface_function_DT.vhd \
	../../src/ieee_488_1_state/interface_function_LE.vhd \
	../../src/ieee_488_1_state/interface_function_PP.vhd \
	../../src/ieee_488_1_state/interface_function_RL.vhd \
	../../src/ieee_488_1_state/interface_function_SH.vhd \
	../../src/ieee_488_1_state/interface_function_SR.vhd \
	../../src/ieee_488_1_state/set_rsv_488_2.vhd \
	../../src/ieee_488_1_state/interface_function_TE.vhd \
	../../src/ieee_488_1_state/remote_message_decoder.vhd \
	../../src/ieee_488_1_state/integrated_interface_functions.vhd \
	../../src/util/gpib_transceiver.vhd \
	../../src/frontends/frontend_cb7210p2.vhd \
	../test_common.vhd \
	dual_cb7210p2_testbench.vhd
dual_cb7210p2_testbench.fst: $(DUAL_CB7210P2_TEST_SRC)
	nvc -a $(DUAL_CB7210P2_TEST_SRC)
	nvc -e dual_cb7210p2_testbench
	nvc -r dual_cb7210p2_testbench --wave 

DUAL_INTEGRATED_CB7210P2_TEST_SRC = \
	$(DUAL_CB7210P2_TEST_SRC) \
	../../src/util/gpib_control_debounce_filter.vhd \
	../../src/util/dma_fifos.vhd \
	../../src/util/gpib_transceiver.vhd \
	../../src/frontends/integrated_cb7210p2.vhd \
	dual_integrated_cb7210p2_testbench.vhd
dual_integrated_cb7210p2_testbench.fst: $(DUAL_INTEGRATED_CB7210P2_TEST_SRC)
	nvc -a $(DUAL_INTEGRATED_CB7210P2_TEST_SRC)
	nvc -e dual_integrated_cb7210p2_testbench
	nvc -r dual_integrated_cb7210p2_testbench --wave 

.PHONY: clean
clean:
	rm -f work/*
	-rmdir work/
	rm -f *.fst

