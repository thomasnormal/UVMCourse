# UVM Capstone Project: SPI Master Controller Verification

## Overview

This capstone project requires you to build a complete verification environment for an SPI (Serial Peripheral Interface) Master Controller. You will receive a specification document and must develop everything from scratch, including the reference model.

**Duration:** 1-4 weeks (see milestones below)

**Skills Tested:**
- SystemVerilog (testbench development, behavioral modeling)
- UVM (full methodology)
- SVA Assertions
- Functional & Code Coverage
- BFM Development
- Specification Analysis
- Test Planning
- Reference Model Development

---

## Project Philosophy

In real-world verification, you often don't have a working RTL when you start. You must:
1. Understand the specification deeply
2. Build your verification environment
3. Write a reference model to predict expected behavior
4. Be ready to verify any RTL implementation that claims to meet the spec

This project follows that philosophy. You will build everything needed to verify an SPI Master - when RTL becomes available (from another team, IP vendor, etc.), your environment should be ready to use.

---

## Project Structure

```
capstone_project/
├── README.md                   # This file
├── docs/
│   ├── spi_specification.md    # Complete SPI Master specification
│   └── test_plan_template.md   # Template for your test plan
├── reference_model/
│   └── spi_ref_model.sv        # YOUR reference model implementation
├── tb/
│   ├── spi_pkg.sv              # Your testbench package
│   ├── spi_if.sv               # Your interfaces
│   └── tb_top.sv               # Top-level testbench
├── env/
│   ├── spi_env.sv              # UVM environment
│   ├── spi_scoreboard.sv       # Scoreboard using reference model
│   ├── spi_coverage.sv         # Functional coverage
│   └── spi_virtual_sequencer.sv
├── agents/
│   ├── apb_agent/              # APB agent for register interface
│   │   ├── apb_transaction.sv
│   │   ├── apb_driver.sv
│   │   ├── apb_monitor.sv
│   │   ├── apb_sequencer.sv
│   │   └── apb_agent.sv
│   └── spi_agent/              # SPI slave agent (BFM)
│       ├── spi_transaction.sv
│       ├── spi_driver.sv       # Acts as SPI slave
│       ├── spi_monitor.sv
│       ├── spi_sequencer.sv
│       └── spi_agent.sv
├── sequences/
│   ├── apb_sequences.sv        # Register access sequences
│   ├── spi_sequences.sv        # SPI response sequences
│   └── virtual_sequences.sv    # Coordinated test sequences
├── tests/
│   ├── spi_base_test.sv
│   ├── spi_sanity_test.sv
│   ├── spi_directed_test.sv
│   └── spi_random_test.sv
├── assertions/
│   └── spi_assertions.sv       # SVA protocol assertions
└── sim/
    └── Makefile
```

---

## Deliverables by Week

### Week 1: Specification Analysis & Planning
**Deliverables:**
- [ ] Completed test plan document (use template)
- [ ] Feature list extracted from specification
- [ ] Coverage plan document
- [ ] Interface definitions (spi_if.sv)
- [ ] Transaction classes defined

**Key Activities:**
- Read specification multiple times
- Identify all features, modes, edge cases
- Determine what coverage points matter
- Define transaction fields and constraints

---

### Week 2: Reference Model & BFMs
**Deliverables:**
- [ ] Complete reference model (spi_ref_model.sv)
- [ ] APB Agent (driver, monitor, sequencer, agent)
- [ ] SPI Slave Agent (driver, monitor, sequencer, agent)
- [ ] Basic sequences for each agent

**Key Activities:**
- Implement behavioral model matching spec exactly
- Build protocol-compliant BFMs
- Test agents independently before integration

---

### Week 3: Environment Integration
**Deliverables:**
- [ ] Complete UVM environment
- [ ] Scoreboard connected to reference model
- [ ] Virtual sequencer and sequences
- [ ] SVA assertions bound to interfaces
- [ ] Functional coverage collectors

**Key Activities:**
- Connect all components via TLM
- Implement self-checking via scoreboard
- Add protocol assertions
- Define coverage groups and bins

---

### Week 4: Tests, Debug & Documentation
**Deliverables:**
- [ ] All test cases from test plan implemented
- [ ] Coverage report showing closure
- [ ] Final test plan with results
- [ ] Bug report template (ready for RTL bugs)
- [ ] Project documentation/README

**Key Activities:**
- Run all tests, analyze results
- Achieve coverage goals
- Document any specification ambiguities found
- Prepare for RTL integration

---

## Grading Rubric (100 points)

| Category | Points | Criteria |
|----------|--------|----------|
| **Test Plan** | 15 | Complete, traceable to spec features, prioritized, realistic |
| **Reference Model** | 15 | Accurate to spec, handles all modes, well-structured |
| **UVM Architecture** | 15 | Proper hierarchy, factory usage, config_db, reusability |
| **BFMs/Agents** | 15 | Protocol-correct, configurable, proper handshaking |
| **Sequences** | 10 | Variety, constraints, virtual sequence coordination |
| **Scoreboard** | 10 | Uses ref model correctly, clear error messages |
| **Assertions** | 10 | Protocol rules, timing checks, meaningful messages |
| **Coverage** | 5 | Comprehensive, meaningful bins, crosses |
| **Code Quality** | 5 | Style, comments, organization, reusability |

**Bonus Points (up to 15):**
- RAL (Register Abstraction Layer) implementation (+5)
- Advanced UVM features (callbacks, custom phases, etc.) (+3)
- Excellent documentation (+2)
- Finding specification ambiguities/issues (+5)

---

## Evaluation Method

Your environment will be tested against:
1. **Golden RTL** - A correct implementation (all tests should pass)
2. **Buggy RTL** - Implementation with intentional bugs (your env should catch them)
3. **Code Review** - Architecture, style, completeness

---

## Getting Started

1. **Read the spec thoroughly** - `docs/spi_specification.md`
   - Read it 3 times minimum
   - Take notes on features, modes, edge cases

2. **Complete the test plan** - `docs/test_plan_template.md`
   - This forces you to understand what needs testing

3. **Start with interfaces and transactions**
   - These define your data structures

4. **Build reference model early**
   - You need this for your scoreboard
   - It also deepens your spec understanding

5. **Build agents incrementally**
   - Test each agent standalone before integration

---

## Tips for Success

1. **Don't skip the test plan** - It saves time later
2. **Reference model is critical** - Get it right, test it independently
3. **Use UVM factory everywhere** - Makes debugging easier
4. **Assertions catch bugs early** - Write them as you understand the protocol
5. **Coverage drives completeness** - Know what you haven't tested
6. **Ask questions about the spec** - Real specs have ambiguities

---

## Submission Checklist

- [ ] All source code (compiles without errors)
- [ ] Completed test plan with traceability matrix
- [ ] Coverage report
- [ ] Brief write-up (approach, challenges, lessons learned)
- [ ] List of any spec ambiguities discovered
- [ ] Self-assessment against rubric

Good luck!
