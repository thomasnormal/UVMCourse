# SRAM Controller Verification - Capstone Project

## Overview

This capstone project tests your UVM verification skills by having you complete a verification environment for an SRAM Controller. The project provides scaffolding code with clear TODOs for you to implement.

## Learning Objectives

By completing this project, you will demonstrate proficiency in:

- **SystemVerilog**: Interfaces, clocking blocks, assertions
- **UVM Architecture**: Agents, drivers, monitors, sequencers
- **Reference Modeling**: Predicting expected DUT behavior
- **Scoreboarding**: Comparing actual vs expected results
- **Functional Coverage**: Defining and collecting coverage metrics
- **Test Planning**: Translating specifications to test cases

## Project Structure

```
capstone_project_sram/
├── docs/
│   ├── sram_specification.md    # Design specification (READ FIRST)
│   ├── test_plan.md             # Test plan template
│   └── images/                  # Timing diagrams
├── agents/
│   ├── apb_agent/               # APB master agent (TODO: driver, monitor)
│   └── sram_agent/              # SRAM slave BFM (TODO: driver, monitor)
├── env/
│   ├── sram_env.sv              # Environment (PROVIDED)
│   ├── sram_scoreboard.sv       # Scoreboard (TODO: comparison logic)
│   └── sram_coverage.sv         # Coverage (TODO: covergroups)
├── reference_model/
│   └── sram_ref_model.sv        # Reference model (TODO: SRAM access prediction)
├── sequences/
│   └── apb_sequences.sv         # Sequences (PROVIDED, extend as needed)
├── tests/
│   ├── sram_base_test.sv        # Base test (PROVIDED)
│   └── sram_sanity_test.sv      # Sanity test (PROVIDED)
├── tb/
│   ├── sram_if.sv               # Interfaces (PROVIDED)
│   ├── sram_pkg.sv              # Package (PROVIDED)
│   └── tb_top.sv                # Testbench top (PROVIDED)
└── sim/
    └── Makefile                 # Build/run scripts
```

## Getting Started

### 1. Read the Specification

Start by thoroughly reading `docs/sram_specification.md`. Understand:
- Register map and bit fields
- Memory window addressing
- Read/write timing requirements
- Error conditions

### 2. Review the Test Plan

Read `docs/test_plan.md` to understand:
- Features to verify
- Test case requirements
- Coverage goals
- Your implementation tasks

### 3. Implement Components

Complete the TODO sections in this order:

#### Phase 1: APB Agent
1. `agents/apb_agent/apb_driver.sv` - Implement `drive_transfer()`
2. `agents/apb_agent/apb_monitor.sv` - Implement `monitor_transfer()`

#### Phase 2: SRAM Agent
3. `agents/sram_agent/sram_driver.sv` - Implement `monitor_and_respond()`
4. `agents/sram_agent/sram_monitor.sv` - Implement read/write monitoring

#### Phase 3: Reference Model
5. `reference_model/sram_ref_model.sv` - Implement `predict_sram_access()`

#### Phase 4: Scoreboard
6. `env/sram_scoreboard.sv` - Implement comparison logic

#### Phase 5: Coverage
7. `env/sram_coverage.sv` - Define covergroup bins

### 4. Run Simulations

```bash
cd sim

# Run sanity test
make run TEST=sram_sanity_test

# Run with GUI (if available)
make gui TEST=sram_sanity_test

# Use different simulator
make run SIM=vcs TEST=sram_sanity_test
```

## What's Provided vs What You Implement

### Provided (Complete)
- ✅ Interfaces with clocking blocks and modports
- ✅ Package with types and parameters
- ✅ Transaction classes
- ✅ Sequencer classes
- ✅ Agent shells
- ✅ Environment structure
- ✅ Base sequences
- ✅ Test infrastructure
- ✅ Register read/write in reference model

### You Implement (TODOs)
- ❌ APB driver protocol (setup, access, wait phases)
- ❌ APB monitor transaction capture
- ❌ SRAM slave response logic
- ❌ SRAM monitor read/write detection
- ❌ Reference model SRAM access prediction
- ❌ Scoreboard comparison logic
- ❌ Coverage bins and crosses
- ❌ Additional test sequences

## Tips for Success

1. **Start with APB Driver**: This is foundational - nothing works without it
2. **Test Incrementally**: Verify each component before moving on
3. **Use `uvm_info`**: Add debug messages to trace execution
4. **Check Waveforms**: Use GUI mode to debug timing issues
5. **Read the Spec**: Most answers are in the specification

## Evaluation Criteria

- **Functionality**: Do your implementations work correctly?
- **Code Quality**: Is your code clean and well-commented?
- **Coverage**: Did you achieve meaningful coverage?
- **Test Cases**: Are your tests thorough?
- **Understanding**: Can you explain your design decisions?

## Resources

- [UVM Cookbook](https://verificationacademy.com/cookbook/uvm)
- [AMBA APB Specification](https://developer.arm.com/documentation)
- Course materials in parent directory

---

Good luck!
