// =============================================================================
// SRAM Base Test (PROVIDED - complete implementation)
// =============================================================================

class sram_base_test extends uvm_test;

  `uvm_component_utils(sram_base_test)

  // Environment
  sram_env env;

  function new(string name = "sram_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = sram_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    // Wait for reset
    #100ns;

    // Run test-specific sequences (override in derived tests)
    run_test_sequence();

    // Allow time for completion
    #1000ns;

    phase.drop_objection(this);
  endtask

  // Override this in derived tests
  virtual task run_test_sequence();
    `uvm_info(get_type_name(), "Base test - no sequence", UVM_MEDIUM)
  endtask

endclass : sram_base_test
