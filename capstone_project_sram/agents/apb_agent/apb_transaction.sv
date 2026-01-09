// =============================================================================
// APB Transaction (PROVIDED - complete implementation)
// =============================================================================

class apb_transaction extends uvm_sequence_item;

  // Transaction fields
  rand apb_op_e       op;
  rand logic [31:0]   addr;
  rand logic [31:0]   data;
  rand access_size_e  size;

  // Response fields (set by driver/monitor)
  logic [31:0]        rdata;
  logic               error;

  // Constraints
  constraint addr_align_c {
    (size == SIZE_HALFWORD) -> (addr[0] == 0);
    (size == SIZE_WORD) -> (addr[1:0] == 0);
  }

  // UVM macros
  `uvm_object_utils_begin(apb_transaction)
    `uvm_field_enum(apb_op_e, op, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
    `uvm_field_enum(access_size_e, size, UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(error, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "apb_transaction");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("%s addr=0x%08h data=0x%08h size=%s rdata=0x%08h err=%0d",
                     op.name(), addr, data, size.name(), rdata, error);
  endfunction

endclass : apb_transaction
