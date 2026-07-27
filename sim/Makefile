##################################################################################################
#This file created by Huy Nguyen
#Updated date: 6/30/2024
##################################################################################################

# default_value_register_test, rw_register_test

#Define variables
TESTNAME 	?= default_value_register_test
TB_NAME 	?= testbench
RADIX			?= hexadecimal
SEED      ?= 1
COV       ?= OFF
RUNARG    ?=

# QuestaSim is installed on Windows and invoked from WSL through /mnt/c.
# Override on the command line if Questa is installed elsewhere, for example:
#   make all QUESTA_PATH=/mnt/d/Siemens/Questa/win64
QUESTA_PATH ?= /mnt/c/questasim64_10.2c/win64
VLIB        ?= $(QUESTA_PATH)/vlib.exe
VMAP        ?= $(QUESTA_PATH)/vmap.exe
VLOG        ?= $(QUESTA_PATH)/vlog.exe
VSIM        ?= $(QUESTA_PATH)/vsim.exe
VCOVER      ?= $(QUESTA_PATH)/vcover.exe
#==============================
ifeq ($(COV),ON)
  CMP_COV_OPT   = -coveropt 3 +cover=bcestf 
  SIM1_COV_OPT  = -coverage -coveranalysis  
  SIM2_COV_OPT  = coverage save -codeAll -cvg -onexit $(TESTNAME).ucdb;
endif

ifeq ($(strip $(SEED)),random)
  SEED_RAND = $(shell /bin/date +%s)
else
  SEED_RAND = $(SEED)
endif

#==============================
.PHONY: all build run wave cov_gui cov_merge clean help

all: build run

build:
	mkdir -p log
	$(VLIB) work
	$(VMAP) work work
	$(VLOG) ${CMP_COV_OPT} -sv -f compile.f | tee compile.log
run:
	$(VSIM) -sv_seed $(SEED_RAND) ${SIM1_COV_OPT} -debugDB -l $(TESTNAME)_$(SEED_RAND).log -voptargs=+acc -assertdebug -c $(TB_NAME) -do "${SIM2_COV_OPT} log -r /*;run -all;" +TESTNAME=$(TESTNAME) $(RUNARG)
	mv $(TESTNAME)_$(SEED_RAND).log log
	cp -rf  vsim.wlf log/$(TESTNAME)_$(SEED_RAND).wlf
	ln -sf log/$(TESTNAME)_$(SEED_RAND).log run.log
wave:
	$(VSIM) -i -view vsim.wlf -do "add wave vsim:/$(TB_NAME)/*; radix -$(RADIX)" &
cov_gui:
	$(VSIM) -i -viewcov ${TESTNAME}.ucdb &
cov_merge:
	$(VCOVER) merge IP_MERGE.ucdb *.ucdb
clean:
	rm -rf work
	rm -rf vsim.dbg
	rm -rf *.ini
	rm -rf *.log
	rm -rf log
	rm -rf tmp_report
	rm -rf *.rpt
	rm -rf *.wlf
	rm -rf *.ucdb
	rm -rf transcript
help:
	@echo ""
	@echo "**************************************"
	@echo "** make build: compile the design and testbench"
	@echo "** make run  : run simulation"
	@echo "** make all  : compile and run simulation"
	@echo "** make wave : open waveform"
	@echo "** make clean: clean all compiled data"
	@echo "**************************************"
	@echo ""
