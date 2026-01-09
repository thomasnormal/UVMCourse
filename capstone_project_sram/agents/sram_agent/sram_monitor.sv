// =============================================================================
// SRAM Monitor
// =============================================================================
// This monitor observes SRAM bus transactions and broadcasts them.
// It detects read and write cycles based on control signal timing.
// =============================================================================

class sram_monitor extends uvm_monitor;

  `uvm_component_utils(sram_monitor)

  // Virtual interface handle
  virtual sram_if vif;

  // Analysis port to broadcast observed transactions
  uvm_analysis_port #(sram_transaction) ap;

  function new(string name = "sram_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sram_if)::get(this, "", "sram_vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    // Wait for reset
    @(posedge vif.PRESETn);

    fork
      monitor_reads();
      monitor_writes();
    join
  endtask

  // ===========================================================================
  // TODO: Implement read cycle monitoring
  // ===========================================================================
  // Detect and capture read transactions:
  // 1. Wait for CE_N=0 and OE_N=0 (read active)
  // 2. Capture address
  // 3. Count cycles while OE_N is low
  // 4. Capture data when available
  // 5. Create transaction and write to analysis port
  // ===========================================================================
  task monitor_reads();
    forever begin
      sram_transaction txn;
      // TODO: Implement read monitoring
      //
      // Hints:
      // - Wait for: !vif.monitor_cb.SRAM_CE_N && !vif.monitor_cb.SRAM_OE_N
      // - Capture vif.monitor_cb.SRAM_ADDR
      // - Count cycles, capture vif.monitor_cb.SRAM_DATA
      // - Set txn.op = SRAM_READ

      @(vif.monitor_cb);  // Placeholder - remove when implementing
    end
  endtask

  // ===========================================================================
  // TODO: Implement write cycle monitoring
  // ===========================================================================
  // Detect and capture write transactions:
  // 1. Wait for CE_N=0 and WE_N falling edge
  // 2. Capture address
  // 3. Wait for WE_N rising edge
  // 4. Capture data (valid at WE_N rising edge)
  // 5. Create transaction and write to analysis port
  // ===========================================================================
  task monitor_writes();
    forever begin
      sram_transaction txn;
      // TODO: Implement write monitoring
      //
      // Hints:
      // - Detect falling edge: $fell(vif.monitor_cb.SRAM_WE_N)
      // - Detect rising edge: $rose(vif.monitor_cb.SRAM_WE_N)
      // - Set txn.op = SRAM_WRITE

      @(vif.monitor_cb);  // Placeholder - remove when implementing
    end
  endtask

endclass : sram_monitor
