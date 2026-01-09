# =============================================================================
# SRAM Controller - Simulation Makefile
# =============================================================================
# Supports: VCS, Questa, Xcelium
# Usage: make <target> [SIM=vcs|questa|xcelium] [TEST=test_name]
# =============================================================================

SIM      ?= questa
TEST     ?= sram_sanity_test
SEED     ?= random
VERBOSITY ?= UVM_MEDIUM

# Directories
TB_DIR     = ../tb
ENV_DIR    = ../env
AGENTS_DIR = ../agents
SEQ_DIR    = ../sequences
TEST_DIR   = ../tests
REF_DIR    = ../reference_model

# Source files
TB_FILES = \
    $(TB_DIR)/sram_if.sv \
    $(TB_DIR)/sram_pkg.sv \
    $(TB_DIR)/tb_top.sv

# =============================================================================
# Questa/ModelSim
# =============================================================================
ifeq ($(SIM),questa)

VLOG_OPTS = -sv +acc -timescale 1ns/1ps
VSIM_OPTS = -c -do "run -all; quit" +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY)

ifeq ($(SEED),random)
    VSIM_OPTS += -sv_seed random
else
    VSIM_OPTS += -sv_seed $(SEED)
endif

compile:
	vlib work
	vlog $(VLOG_OPTS) +incdir+$(TB_DIR) +incdir+$(ENV_DIR) +incdir+$(AGENTS_DIR) \
        +incdir+$(AGENTS_DIR)/apb_agent +incdir+$(AGENTS_DIR)/sram_agent \
        +incdir+$(SEQ_DIR) +incdir+$(TEST_DIR) +incdir+$(REF_DIR) \
        $(TB_FILES)

run: compile
	vsim $(VSIM_OPTS) tb_top

gui: compile
	vsim -gui +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) tb_top

endif

# =============================================================================
# VCS
# =============================================================================
ifeq ($(SIM),vcs)

VCS_OPTS = -full64 -sverilog -timescale=1ns/1ps -debug_access+all \
           +incdir+$(TB_DIR) +incdir+$(ENV_DIR) +incdir+$(AGENTS_DIR) \
           +incdir+$(AGENTS_DIR)/apb_agent +incdir+$(AGENTS_DIR)/sram_agent \
           +incdir+$(SEQ_DIR) +incdir+$(TEST_DIR) +incdir+$(REF_DIR) \
           -ntb_opts uvm-1.2

ifeq ($(SEED),random)
    RUN_OPTS = +ntb_random_seed_automatic
else
    RUN_OPTS = +ntb_random_seed=$(SEED)
endif

compile:
	vcs $(VCS_OPTS) $(TB_FILES) -o simv

run: compile
	./simv +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) $(RUN_OPTS)

gui: compile
	./simv +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) $(RUN_OPTS) -gui

endif

# =============================================================================
# Xcelium
# =============================================================================
ifeq ($(SIM),xcelium)

XRUN_OPTS = -64bit -sv -uvm -timescale 1ns/1ps -access +rwc \
            +incdir+$(TB_DIR) +incdir+$(ENV_DIR) +incdir+$(AGENTS_DIR) \
            +incdir+$(AGENTS_DIR)/apb_agent +incdir+$(AGENTS_DIR)/sram_agent \
            +incdir+$(SEQ_DIR) +incdir+$(TEST_DIR) +incdir+$(REF_DIR)

ifeq ($(SEED),random)
    XRUN_OPTS += -svseed random
else
    XRUN_OPTS += -svseed $(SEED)
endif

compile:
	xrun -compile $(XRUN_OPTS) $(TB_FILES)

run:
	xrun $(XRUN_OPTS) $(TB_FILES) +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY)

gui:
	xrun $(XRUN_OPTS) $(TB_FILES) +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) -gui

endif

# =============================================================================
# Common
# =============================================================================
clean:
	rm -rf work simv simv.daidir csrc *.log *.key
	rm -rf xcelium.d xrun.* *.shm
	rm -rf transcript vsim.wlf

help:
	@echo "=== SRAM Verification Makefile ==="
	@echo ""
	@echo "Usage: make <target> [OPTIONS]"
	@echo ""
	@echo "Targets:"
	@echo "  compile  - Compile the design"
	@echo "  run      - Run simulation"
	@echo "  gui      - Run with GUI"
	@echo "  clean    - Remove build artifacts"
	@echo ""
	@echo "Options:"
	@echo "  SIM=questa|vcs|xcelium  - Simulator (default: questa)"
	@echo "  TEST=<test_name>        - Test (default: sram_sanity_test)"
	@echo "  SEED=<value>|random     - Seed (default: random)"
	@echo ""

.PHONY: compile run gui clean help
