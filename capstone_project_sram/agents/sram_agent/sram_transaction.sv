// =============================================================================
// SRAM Transaction (PROVIDED - complete implementation)
// =============================================================================

class sram_transaction extends uvm_sequence_item;

  // Transaction fields
  sram_op_e       op;
  logic [15:0]    addr;
  logic [7:0]     data;      // Write data (from DUT) or read data (to DUT)

  // Timing observed
  int             ce_cycles;  // CE_N active cycles
  int             we_cycles;  // WE_N active cycles
  int             oe_cycles;  // OE_N active cycles

  // UVM macros
  `uvm_object_utils_begin(sram_transaction)
    `uvm_field_enum(sram_op_e, op, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(ce_cycles, UVM_ALL_ON)
    `uvm_field_int(we_cycles, UVM_ALL_ON)
    `uvm_field_int(oe_cycles, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "sram_transaction");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("%s addr=0x%04h data=0x%02h CE=%0d WE=%0d OE=%0d",
                     op.name(), addr, data, ce_cycles, we_cycles, oe_cycles);
  endfunction

endclass : sram_transaction
