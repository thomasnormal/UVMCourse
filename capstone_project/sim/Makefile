# =============================================================================
# SPI Master Controller - Simulation Makefile
# =============================================================================
# Supports: VCS, Questa, Xcelium
# Usage: make <target> [SIM=vcs|questa|xcelium] [TEST=test_name]
# =============================================================================

# Default settings
SIM      ?= questa
TEST     ?= spi_sanity_test
SEED     ?= random
VERBOSITY ?= UVM_MEDIUM

# Directory structure
TB_DIR   = ../tb
ENV_DIR  = ../env
AGENTS_DIR = ../agents
SEQ_DIR  = ../sequences
TEST_DIR = ../tests
ASSERT_DIR = ../assertions
REF_DIR  = ../reference_model

# Source files
TB_FILES = \
    $(TB_DIR)/spi_if.sv \
    $(TB_DIR)/spi_pkg.sv \
    $(TB_DIR)/tb_top.sv

# RTL files - add when available
# RTL_FILES = \
#     ../rtl/spi_master.sv

# Assertion files
ASSERT_FILES = \
    $(ASSERT_DIR)/spi_assertions.sv

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
            +incdir+$(TB_DIR) +incdir+$(ENV_DIR) +incdir+$(AGENTS_DIR)

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
# Common targets
# =============================================================================

# Run regression - all tests
regress:
	$(MAKE) run TEST=spi_sanity_test
	$(MAKE) run TEST=spi_directed_test
	$(MAKE) run TEST=spi_random_test
	@echo "=== Regression Complete ==="

# Coverage merge and report
coverage:
	# Add coverage merge commands for your simulator
	@echo "TODO: Add coverage commands"

# Clean build artifacts
clean:
	rm -rf work simv simv.daidir csrc *.log *.key
	rm -rf xcelium.d xrun.* *.shm
	rm -rf transcript vsim.wlf
	rm -rf urgReport coverage.txt

# Display help
help:
	@echo "=== SPI Verification Makefile ==="
	@echo ""
	@echo "Usage: make <target> [OPTIONS]"
	@echo ""
	@echo "Targets:"
	@echo "  compile  - Compile the design"
	@echo "  run      - Run simulation"
	@echo "  gui      - Run simulation with GUI"
	@echo "  regress  - Run all tests"
	@echo "  coverage - Generate coverage report"
	@echo "  clean    - Remove build artifacts"
	@echo ""
	@echo "Options:"
	@echo "  SIM=questa|vcs|xcelium  - Select simulator (default: questa)"
	@echo "  TEST=<test_name>        - Select test (default: spi_sanity_test)"
	@echo "  SEED=<value>|random     - Random seed (default: random)"
	@echo "  VERBOSITY=<level>       - UVM verbosity (default: UVM_MEDIUM)"
	@echo ""
	@echo "Examples:"
	@echo "  make run TEST=spi_random_test"
	@echo "  make run SIM=vcs TEST=spi_sanity_test SEED=12345"
	@echo "  make regress SIM=xcelium"

.PHONY: compile run gui regress coverage clean help
