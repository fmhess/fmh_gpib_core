.PHONY: all
all: gpib_transceiver_testbench.fst

GPIB_TRANSCEIVER_TEST_SRC = \
	../../src/util/gpib_transceiver.vhd \
	gpib_transceiver_testbench.vhd
gpib_transceiver_testbench.fst: $(GPIB_TRANSCEIVER_TEST_SRC)
	nvc -a $(GPIB_TRANSCEIVER_TEST_SRC)
	nvc -e gpib_transceiver_testbench
	nvc -r gpib_transceiver_testbench --wave 

.PHONY: clean
clean:
	rm -f work/*
	-rmdir work/
	rm -f *.fst

