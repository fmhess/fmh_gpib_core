.PHONY: all
all: fmh_gpib_top_testbench.fst

FMH_GPIB_TOP_TEST_SRC = \
	../../src/util/std_fifo.vhd \
	../../src/ieee_488_1_state/acceptor_fifo.vhd \
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
	../../src/ieee_488_1_state/set_rsv_488_2.vhd \
	../../src/ieee_488_1_state/interface_function_TE.vhd \
	../../src/ieee_488_1_state/remote_message_decoder.vhd \
	../../src/ieee_488_1_state/integrated_interface_functions.vhd \
	../../src/util/gpib_control_debounce_filter.vhd \
	../../src/util/dma_fifos.vhd \
	../../src/frontends/frontend_cb7210p2.vhd \
	../../src/example/fmh_gpib_top.vhd \
	../test_common.vhd \
	fmh_gpib_top_testbench.vhd
fmh_gpib_top_testbench.fst: $(FMH_GPIB_TOP_TEST_SRC)
	nvc -a $(FMH_GPIB_TOP_TEST_SRC)
	nvc -e fmh_gpib_top_testbench
	nvc -r fmh_gpib_top_testbench --wave 

.PHONY: clean
clean:
	rm -f work/*
	-rmdir work/
	rm -f *.fst

