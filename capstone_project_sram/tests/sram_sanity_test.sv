// =============================================================================
// SRAM Sanity Test (PROVIDED - simple test to verify basic functionality)
// =============================================================================

class sram_sanity_test extends sram_base_test;

  `uvm_component_utils(sram_sanity_test)

  function new(string name = "sram_sanity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_test_sequence();
    apb_config_sequence   cfg_seq;
    apb_mem_wr_rd_sequence wr_rd_seq;

    `uvm_info(get_type_name(), "Starting sanity test", UVM_LOW)

    // Configure the controller with default timing
    cfg_seq = apb_config_sequence::type_id::create("cfg_seq");
    cfg_seq.taa = 5;
    cfg_seq.toe = 5;
    cfg_seq.twc = 3;
    cfg_seq.tas = 2;
    cfg_seq.tds = 2;
    cfg_seq.wait_states = 0;
    cfg_seq.start(env.apb_agt.sqr);

    // Simple write-read test
    wr_rd_seq = apb_mem_wr_rd_sequence::type_id::create("wr_rd_seq");
    wr_rd_seq.start_addr = 16'h0000;
    wr_rd_seq.num_bytes = 8;
    wr_rd_seq.pattern = 8'hA5;
    wr_rd_seq.start(env.apb_agt.sqr);

    // Another write-read at different address
    wr_rd_seq.start_addr = 16'h1000;
    wr_rd_seq.num_bytes = 4;
    wr_rd_seq.pattern = 8'h5A;
    wr_rd_seq.start(env.apb_agt.sqr);

    `uvm_info(get_type_name(), "Sanity test complete", UVM_LOW)
  endtask

endclass : sram_sanity_test
