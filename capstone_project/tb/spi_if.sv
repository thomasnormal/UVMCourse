// =============================================================================
// SPI Master Controller - Interface Definitions
// =============================================================================
// TODO: Complete these interface definitions based on the specification
// =============================================================================

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// APB Interface
// -----------------------------------------------------------------------------
// Used for register access to the SPI Master
// Reference: Specification Section 4.1
// -----------------------------------------------------------------------------
interface apb_if (input logic PCLK, input logic PRESETn);

  // APB Signals - TODO: Add all signals from spec section 4.1
  logic        PSEL;
  logic        PENABLE;
  logic        PWRITE;
  logic [7:0]  PADDR;
  logic [31:0] PWDATA;
  logic [31:0] PRDATA;
  logic        PREADY;

  // ---------------------------------------------
  // Master Clocking Block (for APB Agent Driver)
  // ---------------------------------------------
  clocking master_cb @(posedge PCLK);
    default input #1step output #1ns;
    output PSEL, PENABLE, PWRITE, PADDR, PWDATA;
    input  PRDATA, PREADY;
  endclocking

  // ---------------------------------------------
  // Monitor Clocking Block (for APB Agent Monitor)
  // ---------------------------------------------
  clocking monitor_cb @(posedge PCLK);
    default input #1step;
    input PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA, PREADY;
  endclocking

  // ---------------------------------------------
  // Modports
  // ---------------------------------------------
  modport master  (clocking master_cb, input PRESETn);
  modport monitor (clocking monitor_cb, input PRESETn);
  modport slave   (input PCLK, PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA,
                   output PRDATA, PREADY);

  // ---------------------------------------------
  // Assertions - TODO: Add APB protocol assertions
  // ---------------------------------------------
  // Example:
  // property p_psel_penable;
  //   @(posedge PCLK) disable iff (!PRESETn)
  //   $rose(PSEL) |-> ##1 PENABLE;
  // endproperty
  // assert property (p_psel_penable) else $error("APB: PENABLE not asserted after PSEL");

endinterface : apb_if


// -----------------------------------------------------------------------------
// SPI Interface
// -----------------------------------------------------------------------------
// SPI Master signals to external slave devices
// Reference: Specification Section 4.2
// -----------------------------------------------------------------------------
interface spi_if (input logic PCLK, input logic PRESETn);

  // SPI Signals - TODO: Verify against spec section 4.2
  logic        SCLK;
  logic        MOSI;
  logic        MISO;
  logic [3:0]  SS_N;

  // ---------------------------------------------
  // Master Clocking Block (from DUT perspective)
  // Used by SPI monitor
  // ---------------------------------------------
  clocking master_cb @(posedge PCLK);
    default input #1step;
    input SCLK, MOSI, SS_N;
    output MISO;
  endclocking

  // ---------------------------------------------
  // Monitor Clocking Block
  // Samples all signals for protocol monitoring
  // ---------------------------------------------
  clocking monitor_cb @(posedge PCLK);
    default input #1step;
    input SCLK, MOSI, MISO, SS_N;
  endclocking

  // ---------------------------------------------
  // Modports
  // ---------------------------------------------
  modport master  (output SCLK, MOSI, SS_N, input MISO);
  modport slave   (input SCLK, MOSI, SS_N, output MISO);
  modport monitor (clocking monitor_cb, input PRESETn);

  // ---------------------------------------------
  // Assertions - TODO: Add SPI protocol assertions
  // ---------------------------------------------
  // Things to check:
  // - SS_N must be low during transfer
  // - SCLK should not toggle when SS_N is high
  // - Data stability requirements
  // - etc.

endinterface : spi_if


// -----------------------------------------------------------------------------
// Interrupt Interface
// -----------------------------------------------------------------------------
interface irq_if (input logic PCLK, input logic PRESETn);

  logic IRQ;

  clocking monitor_cb @(posedge PCLK);
    default input #1step;
    input IRQ;
  endclocking

  modport dut     (output IRQ);
  modport monitor (clocking monitor_cb, input PRESETn);

endinterface : irq_if
