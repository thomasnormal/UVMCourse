// =============================================================================
// SRAM Driver (Slave BFM)
// =============================================================================
// This driver acts as an SRAM slave device, responding to read/write requests.
// It maintains an internal memory array and drives read data when requested.
// =============================================================================

class sram_driver extends uvm_driver #(sram_transaction);

  `uvm_component_utils(sram_driver)

  // Virtual interface handle
  virtual sram_if vif;

  // Internal memory model
  logic [7:0] memory[logic [15:0]];

  // Configuration
  int read_delay = 2;  // Cycles before driving read data

  function new(string name = "sram_driver", uvm_component parent = null);
    super.new(name, parent);
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
      monitor_and_respond();
    join
  endtask

  // ===========================================================================
  // TODO: Implement SRAM slave response logic
  // ===========================================================================
  // Monitor the SRAM interface and respond to transactions:
  //
  // For READS (CE_N=0, OE_N=0, WE_N=1):
  //   1. Detect read request (CE_N and OE_N both low)
  //   2. Look up address in memory[] array
  //   3. After read_delay cycles, drive data onto bus
  //   4. Hold data until OE_N goes high
  //
  // For WRITES (CE_N=0, OE_N=1, WE_N=0):
  //   1. Detect write request (CE_N low, WE_N goes low)
  //   2. Capture address and data when WE_N rises
  //   3. Store data in memory[] array
  //
  // Hints:
  //   - Use vif.driver_cb for clocked access
  //   - Drive read data via: vif.driver_cb.sram_data_in <= data;
  //   - Sample write data via: vif.monitor_cb.SRAM_DATA
  //   - Use memory.exists(addr) to check if address has been written
  // ===========================================================================
  task monitor_and_respond();
    forever begin
      @(vif.driver_cb);

      // TODO: Check for read request
      // if (!vif.driver_cb.SRAM_CE_N && !vif.driver_cb.SRAM_OE_N && vif.driver_cb.SRAM_WE_N) begin
      //   // Handle read - drive data after delay
      // end

      // TODO: Check for write request
      // Detect falling edge of WE_N, then capture on rising edge

    end
  endtask

  // Helper function to read memory
  function logic [7:0] read_memory(logic [15:0] addr);
    if (memory.exists(addr))
      return memory[addr];
    else
      return 8'hXX;  // Uninitialized memory
  endfunction

  // Helper function to write memory
  function void write_memory(logic [15:0] addr, logic [7:0] data);
    memory[addr] = data;
    `uvm_info(get_type_name(), $sformatf("Memory[0x%04h] = 0x%02h", addr, data), UVM_HIGH)
  endfunction

  // Initialize memory with a pattern (optional, for testing)
  function void init_memory(logic [7:0] pattern = 8'h00);
    memory.delete();
    `uvm_info(get_type_name(), "Memory cleared", UVM_MEDIUM)
  endfunction

endclass : sram_driver
