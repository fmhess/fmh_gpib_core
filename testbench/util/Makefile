.PHONY: all
all: gpib_transceiver_testbench.fst std_fifo_testbench.fst

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

.PHONY: clean
clean:
	rm -f work/*
	-rmdir work/
	rm -f *.fst

