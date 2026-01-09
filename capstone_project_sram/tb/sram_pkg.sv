// =============================================================================
// SRAM Controller - Testbench Package
// =============================================================================
// This package contains all UVM components for the SRAM verification environment.
// Register addresses, types, and parameters are provided. Students will implement
// the components marked with TODO.
// =============================================================================

package sram_pkg;

  // Import UVM
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ===========================================================================
  // Parameters and Constants (PROVIDED - do not modify)
  // ===========================================================================

  // Register addresses
  parameter logic [31:0] ADDR_CTRL    = 32'h0000_0000;
  parameter logic [31:0] ADDR_STATUS  = 32'h0000_0004;
  parameter logic [31:0] ADDR_TIMING0 = 32'h0000_0008;
  parameter logic [31:0] ADDR_TIMING1 = 32'h0000_000C;

  // Memory window
  parameter logic [31:0] SRAM_BASE    = 32'h0001_0000;
  parameter logic [31:0] SRAM_SIZE    = 32'h0001_0000;  // 64KB

  // Default timing values (in PCLK cycles)
  parameter int DEFAULT_TAA = 5;
  parameter int DEFAULT_TOE = 5;
  parameter int DEFAULT_TWC = 3;
  parameter int DEFAULT_TAS = 3;
  parameter int DEFAULT_TDS = 2;

  // FIFO/Memory depths
  parameter int SRAM_DEPTH = 65536;  // 64KB

  // ===========================================================================
  // Type Definitions (PROVIDED - do not modify)
  // ===========================================================================

  // APB transaction type
  typedef enum {
    APB_READ,
    APB_WRITE
  } apb_op_e;

  // SRAM operation type
  typedef enum {
    SRAM_IDLE,
    SRAM_READ,
    SRAM_WRITE
  } sram_op_e;

  // Access size
  typedef enum {
    SIZE_BYTE,      // 8-bit
    SIZE_HALFWORD,  // 16-bit
    SIZE_WORD       // 32-bit
  } access_size_e;

  // ===========================================================================
  // Include Files - Uncomment as you implement each component
  // ===========================================================================

  // ---- Transactions ----
  `include "../agents/apb_agent/apb_transaction.sv"
  `include "../agents/sram_agent/sram_transaction.sv"

  // ---- APB Agent ----
  `include "../agents/apb_agent/apb_sequencer.sv"
  `include "../agents/apb_agent/apb_driver.sv"
  `include "../agents/apb_agent/apb_monitor.sv"
  `include "../agents/apb_agent/apb_agent.sv"

  // ---- SRAM Agent (Slave BFM) ----
  `include "../agents/sram_agent/sram_sequencer.sv"
  `include "../agents/sram_agent/sram_driver.sv"
  `include "../agents/sram_agent/sram_monitor.sv"
  `include "../agents/sram_agent/sram_agent.sv"

  // ---- Reference Model ----
  `include "../reference_model/sram_ref_model.sv"

  // ---- Environment ----
  `include "../env/sram_scoreboard.sv"
  `include "../env/sram_coverage.sv"
  `include "../env/sram_env.sv"

  // ---- Sequences ----
  `include "../sequences/apb_sequences.sv"
  `include "../sequences/sram_sequences.sv"

  // ---- Tests ----
  `include "../tests/sram_base_test.sv"
  `include "../tests/sram_sanity_test.sv"

endpackage : sram_pkg
