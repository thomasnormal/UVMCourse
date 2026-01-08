// =============================================================================
// SPI Master Controller - Testbench Package
// =============================================================================
// This package contains all UVM components for the SPI verification environment
// =============================================================================

package spi_pkg;

  // Import UVM
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ==========================================================================
  // Parameters and Defines
  // ==========================================================================

  // Register addresses (from spec section 5)
  parameter ADDR_CTRL    = 8'h00;
  parameter ADDR_STATUS  = 8'h04;
  parameter ADDR_CLKDIV  = 8'h08;
  parameter ADDR_SSCTL   = 8'h0C;
  parameter ADDR_TXDATA  = 8'h10;
  parameter ADDR_RXDATA  = 8'h14;
  parameter ADDR_INTEN   = 8'h18;
  parameter ADDR_INTSTAT = 8'h1C;
  parameter ADDR_FIFOST  = 8'h20;

  // Data size encoding
  typedef enum logic [1:0] {
    DSIZE_8  = 2'b00,
    DSIZE_16 = 2'b01,
    DSIZE_32 = 2'b10,
    DSIZE_4  = 2'b11
  } data_size_e;

  // SPI Mode encoding
  typedef enum logic [1:0] {
    SPI_MODE_0 = 2'b00,  // CPOL=0, CPHA=0
    SPI_MODE_1 = 2'b01,  // CPOL=0, CPHA=1
    SPI_MODE_2 = 2'b10,  // CPOL=1, CPHA=0
    SPI_MODE_3 = 2'b11   // CPOL=1, CPHA=1
  } spi_mode_e;

  // ==========================================================================
  // Include Files - Add your files in dependency order
  // ==========================================================================

  // ---- Reference Model ----
  // `include "spi_ref_model.sv"

  // ---- APB Agent ----
  // `include "../agents/apb_agent/apb_transaction.sv"
  // `include "../agents/apb_agent/apb_sequencer.sv"
  // `include "../agents/apb_agent/apb_driver.sv"
  // `include "../agents/apb_agent/apb_monitor.sv"
  // `include "../agents/apb_agent/apb_agent.sv"
  // `include "../agents/apb_agent/apb_seq_lib.sv"

  // ---- SPI Agent ----
  // `include "../agents/spi_agent/spi_transaction.sv"
  // `include "../agents/spi_agent/spi_sequencer.sv"
  // `include "../agents/spi_agent/spi_driver.sv"
  // `include "../agents/spi_agent/spi_monitor.sv"
  // `include "../agents/spi_agent/spi_agent.sv"
  // `include "../agents/spi_agent/spi_seq_lib.sv"

  // ---- Environment ----
  // `include "../env/spi_scoreboard.sv"
  // `include "../env/spi_coverage.sv"
  // `include "../env/spi_virtual_sequencer.sv"
  // `include "../env/spi_env.sv"

  // ---- Sequences ----
  // `include "../sequences/apb_sequences.sv"
  // `include "../sequences/spi_sequences.sv"
  // `include "../sequences/virtual_sequences.sv"

  // ---- Tests ----
  // `include "../tests/spi_base_test.sv"
  // `include "../tests/spi_sanity_test.sv"
  // `include "../tests/spi_directed_test.sv"
  // `include "../tests/spi_random_test.sv"

endpackage : spi_pkg
