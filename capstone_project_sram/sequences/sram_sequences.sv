// =============================================================================
// SRAM Sequences (for slave BFM configuration)
// =============================================================================
// These sequences configure the SRAM slave behavior.
// Typically not needed for basic testing since slave responds automatically.
// =============================================================================

class sram_base_sequence extends uvm_sequence #(sram_transaction);

  `uvm_object_utils(sram_base_sequence)

  function new(string name = "sram_base_sequence");
    super.new(name);
  endfunction

  task body();
    // Base sequence does nothing - slave responds reactively
    `uvm_info(get_type_name(), "SRAM slave sequence - reactive mode", UVM_HIGH)
  endtask

endclass : sram_base_sequence
