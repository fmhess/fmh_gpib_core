.PHONY: all
all: gpib_transceiver_testbench.fst dma_translator_cb7210p2_to_pl330.fst

GPIB_TRANSCEIVER_TEST_SRC = \
	../../src/util/gpib_transceiver.vhd \
	gpib_transceiver_testbench.vhd
gpib_transceiver_testbench.fst: $(GPIB_TRANSCEIVER_TEST_SRC)
	nvc -a $(GPIB_TRANSCEIVER_TEST_SRC)
	nvc -e gpib_transceiver_testbench
	nvc -r gpib_transceiver_testbench --wave

DMA_TRANSLATOR_TEST_SRC = \
	../../src/util/dma_translator_cb7210p2_to_pl330.vhd \
	dma_translator_cb7210p2_to_pl330_testbench.vhd
dma_translator_cb7210p2_to_pl330.fst: $(DMA_TRANSLATOR_TEST_SRC)
	nvc -a $(DMA_TRANSLATOR_TEST_SRC)
	nvc -e dma_translator_cb7210p2_to_pl330_testbench
	nvc -r dma_translator_cb7210p2_to_pl330_testbench --wave 

.PHONY: clean
clean:
	rm -f work/*
	-rmdir work/
	rm -f *.fst

