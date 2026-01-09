// =============================================================================
// SRAM Scoreboard
// =============================================================================
// Compares actual DUT behavior against reference model predictions.
// The structure is provided. Students must implement comparison logic.
// =============================================================================

class sram_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(sram_scoreboard)

  // ===========================================================================
  // Analysis Exports (to receive transactions)
  // ===========================================================================
  uvm_analysis_imp #(apb_transaction, sram_scoreboard) apb_export;

  // ===========================================================================
  // Reference Model Handle
  // ===========================================================================
  sram_ref_model ref_model;

  // ===========================================================================
  // Statistics
  // ===========================================================================
  int total_transactions;
  int passed_transactions;
  int failed_transactions;

  // ===========================================================================
  // Constructor
  // ===========================================================================
  function new(string name = "sram_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    apb_export = new("apb_export", this);
  endfunction

  // ===========================================================================
  // Build Phase
  // ===========================================================================
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    total_transactions = 0;
    passed_transactions = 0;
    failed_transactions = 0;
  endfunction

  // ===========================================================================
  // TODO: Implement APB Transaction Comparison
  // ===========================================================================
  // This function is called for each APB transaction observed by the monitor.
  //
  // Steps:
  // 1. Get expected result from reference model
  // 2. Compare actual vs expected:
  //    - For reads: compare rdata
  //    - For all: compare error status
  // 3. Report pass/fail
  // 4. Update statistics
  // ===========================================================================
  function void write(apb_transaction txn);
    apb_transaction expected;

    total_transactions++;

    // Get expected transaction from reference model
    expected = ref_model.process_apb_transaction(txn);

    // TODO: Implement comparison
    //
    // Hints:
    // - For APB_READ: compare txn.rdata vs expected.rdata
    // - Compare txn.error vs expected.error
    // - Use `uvm_error for mismatches
    // - Use `uvm_info for matches (UVM_HIGH verbosity)

    `uvm_info(get_type_name(), $sformatf("Checking: %s", txn.convert2string()), UVM_HIGH)

    // Example comparison structure:
    // if (txn.op == APB_READ) begin
    //   if (txn.rdata !== expected.rdata) begin
    //     `uvm_error(get_type_name(), $sformatf("RDATA mismatch: got 0x%08h, exp 0x%08h",
    //                txn.rdata, expected.rdata))
    //     failed_transactions++;
    //   end else begin
    //     passed_transactions++;
    //   end
    // end

  endfunction

  // ===========================================================================
  // Report Phase (PROVIDED)
  // ===========================================================================
  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf(
      "\n========================================\n" +
      "       SCOREBOARD SUMMARY\n" +
      "========================================\n" +
      "  Total Transactions: %0d\n" +
      "  Passed:             %0d\n" +
      "  Failed:             %0d\n" +
      "========================================",
      total_transactions, passed_transactions, failed_transactions), UVM_LOW)

    if (failed_transactions > 0)
      `uvm_error(get_type_name(), "TEST FAILED - Mismatches detected")
    else if (total_transactions > 0)
      `uvm_info(get_type_name(), "TEST PASSED - All transactions matched", UVM_LOW)
  endfunction

endclass : sram_scoreboard
