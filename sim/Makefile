TESTNAME ?= default_value_register
TB_NAME ?= testbench
SEED ?= 1
RUNARG ?=

IVERILOG ?= iverilog
VVP ?= vvp
BUILD_DIR ?= build
SIM_OUT ?= $(BUILD_DIR)/$(TB_NAME).out
LOG_DIR ?= log
RUN_LOG ?= $(LOG_DIR)/$(TESTNAME)_$(SEED).log
RTL_FILES := ../rtl/timer_register.v ../rtl/timer_clock_divisor.v ../rtl/timer_counter.v ../rtl/timer_interupt.v ../rtl/timer_top.v
TB_FILES := ../tb/dut_interface.sv ../tb/timer_pkg.sv ../testcase/test_pkg.sv ../tb/testbench.sv

.PHONY: all build run wave cov_gui cov_merge clean help

ifeq ($(strip $(SEED)),random)
  SEED_RAND = $(shell /bin/date +%s)
else
  SEED_RAND = $(SEED)
endif

all: build run

build:
	mkdir -p $(BUILD_DIR) $(LOG_DIR)
	$(IVERILOG) -g2012 -I../tb -I../testcase $(RTL_FILES) $(TB_FILES) -o $(SIM_OUT) 2>&1 | tee $(BUILD_DIR)/compile.log

run: build
	$(VVP) $(SIM_OUT) +TESTNAME=$(TESTNAME) +SEED=$(SEED_RAND) $(RUNARG) 2>&1 | tee $(RUN_LOG)
	ln -sf $(RUN_LOG) run.log

wave:
	@echo "Waveform support is not configured yet. Add dumpfile handling in the testbench if you want a VCD/GTKWave flow."

cov_gui:
	@echo "Coverage is not supported in this Makefile rewrite."

cov_merge:
	@echo "Coverage merge is not supported in this Makefile rewrite."

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(LOG_DIR)
	rm -f run.log
	rm -f *.vcd

help:
	@echo ""
	@echo "***************************************************"
	@echo "** make build: compile the design and testbench"
	@echo "** make run   : run simulation"
	@echo "** make all   : compile and run simulation"
	@echo "** make wave  : waveform hint"
	@echo "** make clean : clean generated files"
	@echo "***************************************************"
	@echo ""