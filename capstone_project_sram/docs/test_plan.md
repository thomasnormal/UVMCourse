# SRAM Controller - Verification Test Plan

**Document Version:** 1.0
**Date:** January 2025
**Author:** [Your Name]

---

## 1. Overview

This test plan defines the verification strategy for the SRAM Controller as specified in `sram_specification.md`.

### 1.1 Scope

- Verify APB interface compliance
- Verify SRAM interface timing
- Verify register functionality
- Verify memory read/write operations
- Verify error handling

### 1.2 References

- SRAM Controller Specification v1.0
- AMBA APB Protocol Specification

---

## 2. Features to Verify

### 2.1 Register Features

| ID | Feature | Priority |
|----|---------|----------|
| REG-001 | CTRL register read/write | High |
| REG-002 | STATUS register read-only behavior | High |
| REG-003 | TIMING0 register configuration | High |
| REG-004 | TIMING1 register configuration | High |
| REG-005 | Register reset values | High |
| REG-006 | Reserved bits read as zero | Medium |

### 2.2 Memory Access Features

| ID | Feature | Priority |
|----|---------|----------|
| MEM-001 | Byte (8-bit) read/write | High |
| MEM-002 | Half-word (16-bit) read/write | High |
| MEM-003 | Word (32-bit) read/write | High |
| MEM-004 | Address alignment | High |
| MEM-005 | Full address range coverage | Medium |
| MEM-006 | Back-to-back accesses | Medium |

### 2.3 Timing Features

| ID | Feature | Priority |
|----|---------|----------|
| TIM-001 | tAA (address access time) | High |
| TIM-002 | tOE (output enable time) | High |
| TIM-003 | tWC (write cycle time) | High |
| TIM-004 | tAS (address setup time) | High |
| TIM-005 | tDS (data setup time) | High |
| TIM-006 | Wait state insertion | Medium |

### 2.4 Error Handling

| ID | Feature | Priority |
|----|---------|----------|
| ERR-001 | Access when disabled | High |
| ERR-002 | Invalid address response | Medium |

---

## 3. Test Cases

### 3.1 Register Tests

| Test ID | Description | Features | Status |
|---------|-------------|----------|--------|
| TC-REG-001 | Write/read all registers | REG-001 to REG-004 | TODO |
| TC-REG-002 | Verify reset values | REG-005 | TODO |
| TC-REG-003 | Reserved bits behavior | REG-006 | TODO |
| TC-REG-004 | STATUS read-clear behavior | REG-002 | TODO |

### 3.2 Memory Tests

| Test ID | Description | Features | Status |
|---------|-------------|----------|--------|
| TC-MEM-001 | Byte write/read | MEM-001 | TODO |
| TC-MEM-002 | Half-word write/read | MEM-002 | TODO |
| TC-MEM-003 | Word write/read | MEM-003 | TODO |
| TC-MEM-004 | Address boundary test | MEM-004, MEM-005 | TODO |
| TC-MEM-005 | Walking ones pattern | MEM-001 | TODO |
| TC-MEM-006 | Walking zeros pattern | MEM-001 | TODO |
| TC-MEM-007 | Random address/data | MEM-001 to MEM-003 | TODO |
| TC-MEM-008 | Sequential burst access | MEM-006 | TODO |

### 3.3 Timing Tests

| Test ID | Description | Features | Status |
|---------|-------------|----------|--------|
| TC-TIM-001 | Minimum timing parameters | TIM-001 to TIM-005 | TODO |
| TC-TIM-002 | Maximum timing parameters | TIM-001 to TIM-005 | TODO |
| TC-TIM-003 | Wait state variation | TIM-006 | TODO |
| TC-TIM-004 | Read cycle timing verification | TIM-001, TIM-002 | TODO |
| TC-TIM-005 | Write cycle timing verification | TIM-003 to TIM-005 | TODO |

### 3.4 Error Tests

| Test ID | Description | Features | Status |
|---------|-------------|----------|--------|
| TC-ERR-001 | Access when EN=0 | ERR-001 | TODO |
| TC-ERR-002 | Invalid register address | ERR-002 | TODO |

---

## 4. Coverage Plan

### 4.1 Functional Coverage

#### 4.1.1 APB Coverage

```systemverilog
// Cover all operations
coverpoint operation { bins read, write; }

// Cover register vs memory access
coverpoint is_memory_access { bins reg_access, mem_access; }

// Cross operation with access type
cross operation, is_memory_access;
```

#### 4.1.2 Register Coverage

```systemverilog
// Cover all registers accessed
coverpoint reg_addr {
    bins ctrl    = {ADDR_CTRL};
    bins status  = {ADDR_STATUS};
    bins timing0 = {ADDR_TIMING0};
    bins timing1 = {ADDR_TIMING1};
}

// Cross registers with operations
cross reg_addr, operation;
```

#### 4.1.3 Memory Coverage

```systemverilog
// Cover address ranges
coverpoint mem_addr[15:12] {
    bins range[] = {[0:15]};
}

// Cover access sizes
coverpoint access_size {
    bins byte_acc = {SIZE_BYTE};
    bins half_acc = {SIZE_HALFWORD};
    bins word_acc = {SIZE_WORD};
}

// Cross address and size
cross mem_addr, access_size;
```

#### 4.1.4 Timing Coverage

```systemverilog
// Cover timing parameter ranges
coverpoint taa_value {
    bins min = {1};
    bins low = {[2:5]};
    bins mid = {[6:10]};
    bins high = {[11:20]};
}

// Similar for other timing parameters
```

### 4.2 Code Coverage

- Statement coverage: >95%
- Branch coverage: >90%
- Toggle coverage: >85%

---

## 5. Verification Environment

### 5.1 Block Diagram

```
  +-------------------+
  |    Test          |
  +-------------------+
           |
  +-------------------+
  |   Environment    |
  | +-------+ +----+ |
  | |APB Agt| |SRAM| |
  | +-------+ |Agt | |
  |     |     +----+ |
  | +---------------+|
  | | Scoreboard    ||
  | | + Ref Model   ||
  | +---------------+|
  | +---------------+|
  | | Coverage      ||
  | +---------------+|
  +-------------------+
           |
  +-------------------+
  |       DUT        |
  +-------------------+
```

### 5.2 Components

| Component | Description | Status |
|-----------|-------------|--------|
| APB Agent | Drives APB transactions | Scaffolding provided |
| SRAM Agent | Slave BFM for SRAM | Scaffolding provided |
| Reference Model | Predicts expected behavior | Partial implementation |
| Scoreboard | Compares actual vs expected | Scaffolding provided |
| Coverage | Collects functional coverage | Scaffolding provided |

---

## 6. Tasks for Completion

### Phase 1: Complete Agent Implementation
- [ ] Implement APB driver `drive_transfer()` task
- [ ] Implement APB monitor `monitor_transfer()` task
- [ ] Implement SRAM driver `monitor_and_respond()` task
- [ ] Implement SRAM monitor read/write detection

### Phase 2: Complete Reference Model
- [ ] Implement `process_apb_transaction()` memory handling
- [ ] Implement `predict_sram_access()` function
- [ ] Verify reference model with standalone test

### Phase 3: Complete Scoreboard
- [ ] Implement APB transaction comparison
- [ ] Add SRAM transaction checking (optional)

### Phase 4: Complete Coverage
- [ ] Define APB covergroup bins
- [ ] Define register covergroup bins
- [ ] Define memory covergroup bins
- [ ] Add timing coverage

### Phase 5: Create Tests
- [ ] Implement register test sequence
- [ ] Implement memory test sequences
- [ ] Implement timing test sequence
- [ ] Implement error test sequence

### Phase 6: Run Regression
- [ ] Execute all test cases
- [ ] Achieve coverage goals
- [ ] Document results

---

## 7. Sign-off Criteria

- All test cases passing
- Functional coverage > 90%
- Code coverage > 85%
- No critical bugs open

---

*End of Test Plan*
