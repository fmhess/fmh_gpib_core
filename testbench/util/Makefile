.PHONY: all
all: gpib_transceiver_testbench.fst \
	gpib_debounce_filter_testbench.fst \
	std_fifo_testbench.fst \
	dma_fifos_testbench.fst

GPIB_TRANSCEIVER_TEST_SRC = \
	../../src/util/gpib_transceiver.vhd \
	gpib_transceiver_testbench.vhd
gpib_transceiver_testbench.fst: $(GPIB_TRANSCEIVER_TEST_SRC)
	nvc -a $(GPIB_TRANSCEIVER_TEST_SRC)
	nvc -e gpib_transceiver_testbench
	nvc -r gpib_transceiver_testbench --wave

STD_FIFO_TEST_SRC = \
	../../src/util/std_fifo.vhd \
	std_fifo_testbench.vhd
std_fifo_testbench.fst: $(STD_FIFO_TEST_SRC)
	nvc -a $(STD_FIFO_TEST_SRC)
	nvc -e std_fifo_testbench
	nvc -r std_fifo_testbench --wave

DMA_FIFOS_TEST_SRC = \
	../../src/util/dma_fifos.vhd \
	../test_common.vhd \
	dma_fifos_testbench.vhd
dma_fifos_testbench.fst: $(DMA_FIFOS_TEST_SRC)
	nvc -a $(DMA_FIFOS_TEST_SRC)
	nvc -e dma_fifos_testbench
	nvc -r dma_fifos_testbench --wave

GPIB_DEBOUNCE_FILTER_TEST_SRC = \
	../test_common.vhd \
	../../src/util/gpib_control_debounce_filter.vhd \
	gpib_debounce_filter_testbench.vhd
gpib_debounce_filter_testbench.fst: $(GPIB_DEBOUNCE_FILTER_TEST_SRC)
	nvc -a $(GPIB_DEBOUNCE_FILTER_TEST_SRC)
	nvc -e gpib_debounce_filter_testbench
	nvc -r gpib_debounce_filter_testbench --wave
.PHONY: clean
clean:
	rm -f work/*
	-rmdir work/
	rm -f *.fst

