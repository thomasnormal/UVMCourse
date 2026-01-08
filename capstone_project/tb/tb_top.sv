// =============================================================================
// SPI Master Controller - Testbench Top
// =============================================================================
// Top-level testbench module that instantiates DUT, interfaces, and runs tests
// =============================================================================

`timescale 1ns/1ps

module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import spi_pkg::*;

  // ===========================================================================
  // Clock and Reset Generation
  // ===========================================================================
  logic PCLK;
  logic PRESETn;

  // Clock generation - 100MHz (10ns period)
  initial begin
    PCLK = 0;
    forever #5 PCLK = ~PCLK;
  end

  // Reset generation
  initial begin
    PRESETn = 0;
    repeat(10) @(posedge PCLK);
    PRESETn = 1;
  end

  // ===========================================================================
  // Interface Instantiation
  // ===========================================================================
  apb_if apb_vif (PCLK, PRESETn);
  spi_if spi_vif (PCLK, PRESETn);
  irq_if irq_vif (PCLK, PRESETn);

  // ===========================================================================
  // DUT Instantiation
  // ===========================================================================
  // TODO: Instantiate your DUT here when RTL is available
  // For now, you can use a behavioral model or leave unconnected

  /*
  spi_master DUT (
    // APB Interface
    .PCLK     (PCLK),
    .PRESETn  (PRESETn),
    .PSEL     (apb_vif.PSEL),
    .PENABLE  (apb_vif.PENABLE),
    .PWRITE   (apb_vif.PWRITE),
    .PADDR    (apb_vif.PADDR),
    .PWDATA   (apb_vif.PWDATA),
    .PRDATA   (apb_vif.PRDATA),
    .PREADY   (apb_vif.PREADY),

    // SPI Interface
    .SCLK     (spi_vif.SCLK),
    .MOSI     (spi_vif.MOSI),
    .MISO     (spi_vif.MISO),
    .SS_N     (spi_vif.SS_N),

    // Interrupt
    .IRQ      (irq_vif.IRQ)
  );
  */

  // ===========================================================================
  // Temporary: Tie-off signals when DUT not present
  // ===========================================================================
  // Remove this section when DUT is connected
  assign apb_vif.PRDATA = 32'h0;
  assign apb_vif.PREADY = 1'b1;
  assign spi_vif.SCLK   = 1'b0;
  assign spi_vif.MOSI   = 1'b0;
  assign spi_vif.SS_N   = 4'hF;
  assign irq_vif.IRQ    = 1'b0;

  // ===========================================================================
  // Bind Assertions
  // ===========================================================================
  // TODO: Bind your assertion module to the DUT
  // bind spi_master spi_assertions spi_assert_inst (.*);

  // ===========================================================================
  // UVM Configuration and Test Execution
  // ===========================================================================
  initial begin
    // Register interfaces with config_db
    uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", apb_vif);
    uvm_config_db#(virtual spi_if)::set(null, "*", "spi_vif", spi_vif);
    uvm_config_db#(virtual irq_if)::set(null, "*", "irq_vif", irq_vif);

    // Run the test
    run_test();
  end

  // ===========================================================================
  // Waveform Dumping
  // ===========================================================================
  initial begin
    // Uncomment for your simulator
    // VCS:
    // $fsdbDumpfile("waves.fsdb");
    // $fsdbDumpvars(0, tb_top);

    // Questa/ModelSim:
    // $wlfdumpvars(0, tb_top);

    // Xcelium:
    // $shm_open("waves.shm");
    // $shm_probe(tb_top, "AS");
  end

  // ===========================================================================
  // Timeout Watchdog
  // ===========================================================================
  initial begin
    #1000000; // 1ms timeout
    `uvm_fatal("TIMEOUT", "Simulation timeout - test did not complete")
  end

endmodule : tb_top
