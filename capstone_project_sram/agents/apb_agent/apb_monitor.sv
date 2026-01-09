// =============================================================================
// APB Monitor
// =============================================================================
// This monitor observes APB transactions and broadcasts them via analysis port.
// The basic structure is provided. Students must implement the monitor_transfer task.
// =============================================================================

class apb_monitor extends uvm_monitor;

  `uvm_component_utils(apb_monitor)

  // Virtual interface handle
  virtual apb_if vif;

  // Analysis port to broadcast observed transactions
  uvm_analysis_port #(apb_transaction) ap;

  function new(string name = "apb_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    // Wait for reset
    @(posedge vif.PRESETn);

    forever begin
      apb_transaction txn;
      txn = apb_transaction::type_id::create("txn");
      monitor_transfer(txn);
      ap.write(txn);
    end
  endtask

  // ===========================================================================
  // TODO: Implement APB transaction monitoring
  // ===========================================================================
  // Observe the APB bus and capture complete transactions:
  // 1. Wait for PSEL to be asserted (start of transaction)
  // 2. Capture address, write data, and operation type
  // 3. Wait for PENABLE and PREADY (completion)
  // 4. Capture read data and error status
  // ===========================================================================
  task monitor_transfer(apb_transaction txn);
    // TODO: Implement APB monitoring
    //
    // Hints:
    // - Use vif.monitor_cb to sample signals
    // - Wait for PSEL && PENABLE && PREADY to capture complete transaction
    // - Fill in txn.op, txn.addr, txn.data, txn.rdata, txn.error

    // ----- WAIT FOR TRANSACTION START -----
    // TODO: Wait for PSEL assertion

    // ----- CAPTURE TRANSACTION INFO -----
    // TODO: Sample address, write/read, write data

    // ----- WAIT FOR COMPLETION -----
    // TODO: Wait for PREADY, sample response

    `uvm_info(get_type_name(), $sformatf("Observed: %s", txn.convert2string()), UVM_MEDIUM)
  endtask

endclass : apb_monitor
