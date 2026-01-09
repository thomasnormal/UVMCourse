// =============================================================================
// APB Sequences (PROVIDED - students can extend)
// =============================================================================

// -----------------------------------------------------------------------------
// Base APB Sequence
// -----------------------------------------------------------------------------
class apb_base_sequence extends uvm_sequence #(apb_transaction);

  `uvm_object_utils(apb_base_sequence)

  function new(string name = "apb_base_sequence");
    super.new(name);
  endfunction

  // Helper task: Write to register
  task write_reg(bit [31:0] addr, bit [31:0] data);
    apb_transaction txn;
    txn = apb_transaction::type_id::create("txn");
    start_item(txn);
    txn.op   = APB_WRITE;
    txn.addr = addr;
    txn.data = data;
    txn.size = SIZE_WORD;
    finish_item(txn);
  endtask

  // Helper task: Read from register
  task read_reg(bit [31:0] addr, output bit [31:0] data);
    apb_transaction txn;
    txn = apb_transaction::type_id::create("txn");
    start_item(txn);
    txn.op   = APB_READ;
    txn.addr = addr;
    txn.size = SIZE_WORD;
    finish_item(txn);
    data = txn.rdata;
  endtask

  // Helper task: Write to memory
  task write_mem(bit [31:0] addr, bit [31:0] data, access_size_e size = SIZE_BYTE);
    apb_transaction txn;
    txn = apb_transaction::type_id::create("txn");
    start_item(txn);
    txn.op   = APB_WRITE;
    txn.addr = SRAM_BASE + addr;
    txn.data = data;
    txn.size = size;
    finish_item(txn);
  endtask

  // Helper task: Read from memory
  task read_mem(bit [31:0] addr, output bit [31:0] data, access_size_e size = SIZE_BYTE);
    apb_transaction txn;
    txn = apb_transaction::type_id::create("txn");
    start_item(txn);
    txn.op   = APB_READ;
    txn.addr = SRAM_BASE + addr;
    txn.size = size;
    finish_item(txn);
    data = txn.rdata;
  endtask

endclass : apb_base_sequence


// -----------------------------------------------------------------------------
// Register Configuration Sequence
// -----------------------------------------------------------------------------
class apb_config_sequence extends apb_base_sequence;

  `uvm_object_utils(apb_config_sequence)

  // Configuration parameters
  rand bit [7:0] taa;
  rand bit [7:0] toe;
  rand bit [7:0] twc;
  rand bit [7:0] tas;
  rand bit [7:0] tds;
  rand bit [7:0] wait_states;

  constraint reasonable_timing_c {
    taa inside {[2:10]};
    toe inside {[2:10]};
    twc inside {[2:10]};
    tas inside {[1:5]};
    tds inside {[1:5]};
    wait_states inside {[0:3]};
  }

  function new(string name = "apb_config_sequence");
    super.new(name);
  endfunction

  task body();
    bit [31:0] data;

    `uvm_info(get_type_name(), "Configuring SRAM controller", UVM_MEDIUM)

    // Write timing registers
    write_reg(ADDR_TIMING0, {16'h0, toe, taa});
    write_reg(ADDR_TIMING1, {8'h0, tds, tas, twc});

    // Enable controller with wait states
    write_reg(ADDR_CTRL, {16'h0, wait_states, 6'h0, 1'b0, 1'b1});

    // Verify configuration
    read_reg(ADDR_CTRL, data);
    `uvm_info(get_type_name(), $sformatf("CTRL = 0x%08h", data), UVM_MEDIUM)

  endtask

endclass : apb_config_sequence


// -----------------------------------------------------------------------------
// Memory Write-Read Sequence
// -----------------------------------------------------------------------------
class apb_mem_wr_rd_sequence extends apb_base_sequence;

  `uvm_object_utils(apb_mem_wr_rd_sequence)

  rand bit [15:0] start_addr;
  rand int        num_bytes;
  rand bit [7:0]  pattern;

  constraint addr_c {
    start_addr inside {[0:16'hFFF0]};
    num_bytes inside {[1:16]};
    start_addr + num_bytes <= 16'hFFFF;
  }

  function new(string name = "apb_mem_wr_rd_sequence");
    super.new(name);
  endfunction

  task body();
    bit [31:0] wdata, rdata;

    `uvm_info(get_type_name(), $sformatf("Write-Read test: addr=0x%04h, %0d bytes, pattern=0x%02h",
              start_addr, num_bytes, pattern), UVM_MEDIUM)

    // Write bytes
    for (int i = 0; i < num_bytes; i++) begin
      wdata = pattern + i;
      write_mem(start_addr + i, wdata, SIZE_BYTE);
    end

    // Read back and verify
    for (int i = 0; i < num_bytes; i++) begin
      read_mem(start_addr + i, rdata, SIZE_BYTE);
      if (rdata[7:0] !== (pattern + i)) begin
        `uvm_error(get_type_name(), $sformatf("Mismatch at 0x%04h: exp=0x%02h, got=0x%02h",
                   start_addr + i, pattern + i, rdata[7:0]))
      end
    end

  endtask

endclass : apb_mem_wr_rd_sequence
