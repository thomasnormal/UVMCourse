// =============================================================================
// APB Driver
// =============================================================================
// This driver executes APB transactions on the bus.
// The basic structure is provided. Students must implement the drive_transfer task.
// =============================================================================

class apb_driver extends uvm_driver #(apb_transaction);

  `uvm_component_utils(apb_driver)

  // Virtual interface handle
  virtual apb_if vif;

  function new(string name = "apb_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    // Initialize signals
    vif.driver_cb.PSEL    <= 0;
    vif.driver_cb.PENABLE <= 0;
    vif.driver_cb.PWRITE  <= 0;
    vif.driver_cb.PADDR   <= 0;
    vif.driver_cb.PWDATA  <= 0;

    // Wait for reset
    @(posedge vif.PRESETn);
    @(vif.driver_cb);

    forever begin
      seq_item_port.get_next_item(req);
      drive_transfer(req);
      seq_item_port.item_done();
    end
  endtask

  // ===========================================================================
  // TODO: Implement the APB transfer protocol
  // ===========================================================================
  // Refer to the AMBA APB specification:
  // 1. Setup phase: Assert PSEL, drive PADDR, PWRITE, PWDATA (for writes)
  // 2. Access phase: Assert PENABLE
  // 3. Wait for PREADY
  // 4. Capture PRDATA (for reads) and PSLVERR
  // 5. Deassert PSEL and PENABLE
  // ===========================================================================
  task drive_transfer(apb_transaction txn);
    // TODO: Implement APB protocol
    //
    // Hints:
    // - Use vif.driver_cb to drive/sample signals
    // - Use @(vif.driver_cb) to wait for clock edges
    // - txn.op tells you if it's APB_READ or APB_WRITE
    // - Set txn.rdata and txn.error before returning

    `uvm_info(get_type_name(), $sformatf("Driving: %s", txn.convert2string()), UVM_MEDIUM)

    // ----- SETUP PHASE -----
    // TODO: Drive PSEL=1, PADDR, PWRITE, PWDATA

    // ----- ACCESS PHASE -----
    // TODO: Drive PENABLE=1

    // ----- WAIT FOR READY -----
    // TODO: Wait for PREADY, capture response

    // ----- CLEANUP -----
    // TODO: Deassert PSEL, PENABLE

    `uvm_info(get_type_name(), $sformatf("Completed: %s", txn.convert2string()), UVM_MEDIUM)
  endtask

endclass : apb_driver
