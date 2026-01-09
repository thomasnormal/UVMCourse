// =============================================================================
// SRAM Controller - Testbench Top (PROVIDED)
// =============================================================================

`timescale 1ns/1ps

module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import sram_pkg::*;

  // ===========================================================================
  // Clock and Reset
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
  apb_if  apb_vif  (PCLK, PRESETn);
  sram_if sram_vif (PCLK, PRESETn);

  // ===========================================================================
  // DUT Instantiation
  // ===========================================================================
  // TODO: Instantiate your DUT here
  //
  // sram_controller DUT (
  //   .PCLK       (PCLK),
  //   .PRESETn    (PRESETn),
  //   .PSEL       (apb_vif.PSEL),
  //   .PENABLE    (apb_vif.PENABLE),
  //   .PWRITE     (apb_vif.PWRITE),
  //   .PADDR      (apb_vif.PADDR),
  //   .PWDATA     (apb_vif.PWDATA),
  //   .PRDATA     (apb_vif.PRDATA),
  //   .PREADY     (apb_vif.PREADY),
  //   .PSLVERR    (apb_vif.PSLVERR),
  //   .SRAM_ADDR  (sram_vif.SRAM_ADDR),
  //   .SRAM_DATA  (sram_vif.SRAM_DATA),
  //   .SRAM_CE_N  (sram_vif.SRAM_CE_N),
  //   .SRAM_OE_N  (sram_vif.SRAM_OE_N),
  //   .SRAM_WE_N  (sram_vif.SRAM_WE_N)
  // );

  // ===========================================================================
  // Temporary Tie-offs (remove when DUT connected)
  // ===========================================================================
  assign apb_vif.PRDATA  = 32'h0;
  assign apb_vif.PREADY  = 1'b1;
  assign apb_vif.PSLVERR = 1'b0;

  assign sram_vif.SRAM_ADDR = 16'h0;
  assign sram_vif.SRAM_CE_N = 1'b1;
  assign sram_vif.SRAM_OE_N = 1'b1;
  assign sram_vif.SRAM_WE_N = 1'b1;
  assign sram_vif.sram_data_out = 8'h0;
  assign sram_vif.sram_data_oe  = 1'b0;

  // ===========================================================================
  // UVM Configuration
  // ===========================================================================
  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", apb_vif);
    uvm_config_db#(virtual sram_if)::set(null, "*", "sram_vif", sram_vif);
    run_test();
  end

  // ===========================================================================
  // Timeout
  // ===========================================================================
  initial begin
    #1000000;
    `uvm_fatal("TIMEOUT", "Simulation timeout")
  end

endmodule : tb_top
