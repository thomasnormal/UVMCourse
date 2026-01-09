// =============================================================================
// SRAM Agent (PROVIDED - complete implementation)
// =============================================================================

class sram_agent extends uvm_agent;

  `uvm_component_utils(sram_agent)

  // Components
  sram_sequencer sqr;
  sram_driver    drv;
  sram_monitor   mon;

  function new(string name = "sram_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Always create monitor
    mon = sram_monitor::type_id::create("mon", this);

    // Create driver and sequencer only if active (slave mode)
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = sram_sequencer::type_id::create("sqr", this);
      drv = sram_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction

endclass : sram_agent
