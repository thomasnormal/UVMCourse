// =============================================================================
// APB Agent (PROVIDED - complete implementation)
// =============================================================================

class apb_agent extends uvm_agent;

  `uvm_component_utils(apb_agent)

  // Components
  apb_sequencer sqr;
  apb_driver    drv;
  apb_monitor   mon;

  function new(string name = "apb_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Always create monitor
    mon = apb_monitor::type_id::create("mon", this);

    // Create driver and sequencer only if active
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = apb_sequencer::type_id::create("sqr", this);
      drv = apb_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect driver to sequencer
    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction

endclass : apb_agent
