// =============================================================================
// SRAM Controller - Interface Definitions
// =============================================================================
// This file contains all interface definitions for the SRAM verification
// environment. These interfaces are ACTIVE and complete - no modifications needed.
// =============================================================================

// =============================================================================
// APB Interface
// =============================================================================
interface apb_if (
  input logic PCLK,
  input logic PRESETn
);

  // APB signals
  logic        PSEL;
  logic        PENABLE;
  logic        PWRITE;
  logic [31:0] PADDR;
  logic [31:0] PWDATA;
  logic [31:0] PRDATA;
  logic        PREADY;
  logic        PSLVERR;

  // ==========================================================================
  // Clocking Blocks
  // ==========================================================================

  // Driver clocking block (drives APB signals)
  clocking driver_cb @(posedge PCLK);
    default input #1step output #1;
    output PSEL, PENABLE, PWRITE, PADDR, PWDATA;
    input  PRDATA, PREADY, PSLVERR;
  endclocking

  // Monitor clocking block (samples all signals)
  clocking monitor_cb @(posedge PCLK);
    default input #1step;
    input PSEL, PENABLE, PWRITE, PADDR, PWDATA;
    input PRDATA, PREADY, PSLVERR;
  endclocking

  // ==========================================================================
  // Modports
  // ==========================================================================

  modport driver  (clocking driver_cb, input PCLK, PRESETn);
  modport monitor (clocking monitor_cb, input PCLK, PRESETn);
  modport dut     (input PCLK, PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA,
                   output PRDATA, PREADY, PSLVERR);

  // ==========================================================================
  // Assertions (provided - students can add more)
  // ==========================================================================

  // APB protocol: PENABLE must follow PSEL
  property apb_enable_follows_select;
    @(posedge PCLK) disable iff (!PRESETn)
    $rose(PSEL) && !PENABLE |-> ##1 PENABLE;
  endproperty
  assert property (apb_enable_follows_select)
    else $error("APB: PENABLE not asserted after PSEL");

  // APB protocol: Signals stable during access phase
  property apb_stable_during_access;
    @(posedge PCLK) disable iff (!PRESETn)
    (PSEL && PENABLE && !PREADY) |-> ##1 $stable(PADDR) && $stable(PWRITE);
  endproperty
  assert property (apb_stable_during_access)
    else $error("APB: Address/control changed during access phase");

endinterface : apb_if


// =============================================================================
// SRAM Interface
// =============================================================================
interface sram_if (
  input logic PCLK,
  input logic PRESETn
);

  // SRAM signals
  logic [15:0] SRAM_ADDR;
  wire  [7:0]  SRAM_DATA;    // Bidirectional
  logic        SRAM_CE_N;
  logic        SRAM_OE_N;
  logic        SRAM_WE_N;

  // Internal signals for bidirectional control
  logic [7:0]  sram_data_out;   // Data driven by DUT (for writes)
  logic [7:0]  sram_data_in;    // Data driven by slave model (for reads)
  logic        sram_data_oe;    // Output enable from DUT

  // Bidirectional data bus implementation
  assign SRAM_DATA = sram_data_oe ? sram_data_out : 8'bz;
  assign sram_data_in = SRAM_DATA;

  // ==========================================================================
  // Clocking Blocks
  // ==========================================================================

  // Driver clocking block (for SRAM slave model - drives read data)
  clocking driver_cb @(posedge PCLK);
    default input #1step output #1;
    input  SRAM_ADDR, SRAM_CE_N, SRAM_OE_N, SRAM_WE_N;
    input  sram_data_out;
    output sram_data_in;
  endclocking

  // Monitor clocking block (samples all signals)
  clocking monitor_cb @(posedge PCLK);
    default input #1step;
    input SRAM_ADDR, SRAM_DATA, SRAM_CE_N, SRAM_OE_N, SRAM_WE_N;
  endclocking

  // ==========================================================================
  // Modports
  // ==========================================================================

  modport driver  (clocking driver_cb, input PCLK, PRESETn);
  modport monitor (clocking monitor_cb, input PCLK, PRESETn);
  modport dut     (input PCLK, PRESETn,
                   output SRAM_ADDR, SRAM_CE_N, SRAM_OE_N, SRAM_WE_N,
                   output sram_data_out, sram_data_oe,
                   input sram_data_in);

  // ==========================================================================
  // Helper Tasks (for debug/monitoring)
  // ==========================================================================

  function bit is_read_active();
    return (!SRAM_CE_N && !SRAM_OE_N && SRAM_WE_N);
  endfunction

  function bit is_write_active();
    return (!SRAM_CE_N && SRAM_OE_N && !SRAM_WE_N);
  endfunction

  function bit is_idle();
    return (SRAM_CE_N);
  endfunction

endinterface : sram_if
