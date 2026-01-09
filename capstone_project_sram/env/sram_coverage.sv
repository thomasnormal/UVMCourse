// =============================================================================
// SRAM Coverage Collector
// =============================================================================
// Collects functional coverage for the SRAM controller verification.
// Covergroup structure is provided. Students must define bins and crosses.
// =============================================================================

class sram_coverage extends uvm_subscriber #(apb_transaction);

  `uvm_component_utils(sram_coverage)

  // ===========================================================================
  // Coverage Variables
  // ===========================================================================
  apb_op_e      cov_op;
  logic [31:0]  cov_addr;
  access_size_e cov_size;
  bit           cov_error;

  // Address regions
  bit is_register_access;
  bit is_memory_access;

  // ===========================================================================
  // TODO: Define Covergroups
  // ===========================================================================
  // Create covergroups to measure:
  //
  // 1. APB Operation Coverage:
  //    - Read vs Write operations
  //    - Cross with address region (register vs memory)
  //
  // 2. Register Coverage:
  //    - All registers accessed (CTRL, STATUS, TIMING0, TIMING1)
  //    - Read and write to each register
  //
  // 3. Memory Access Coverage:
  //    - Address ranges (low, mid, high)
  //    - Access sizes (byte, halfword, word)
  //    - Cross of address range and size
  //
  // 4. Timing Configuration Coverage:
  //    - Different tAA values
  //    - Different tWC values
  //
  // 5. Error Coverage:
  //    - Access when disabled
  //    - Invalid address access
  // ===========================================================================

  covergroup apb_cg;
    // TODO: Define coverpoints and crosses

    // Example structure:
    // operation_cp: coverpoint cov_op {
    //   bins read  = {APB_READ};
    //   bins write = {APB_WRITE};
    // }

    // access_type_cp: coverpoint is_memory_access {
    //   bins register = {0};
    //   bins memory   = {1};
    // }

    // size_cp: coverpoint cov_size {
    //   bins byte_access = {SIZE_BYTE};
    //   bins half_access = {SIZE_HALFWORD};
    //   bins word_access = {SIZE_WORD};
    // }

    // op_x_type: cross operation_cp, access_type_cp;

  endgroup

  covergroup register_cg;
    // TODO: Cover all register addresses

    // reg_addr_cp: coverpoint cov_addr {
    //   bins ctrl    = {ADDR_CTRL};
    //   bins status  = {ADDR_STATUS};
    //   bins timing0 = {ADDR_TIMING0};
    //   bins timing1 = {ADDR_TIMING1};
    // }

  endgroup

  covergroup memory_cg;
    // TODO: Cover memory address ranges and sizes

    // mem_addr_cp: coverpoint cov_addr[15:0] {
    //   bins low_addr  = {[0:16'h3FFF]};
    //   bins mid_addr  = {[16'h4000:16'hBFFF]};
    //   bins high_addr = {[16'hC000:16'hFFFF]};
    // }

  endgroup

  // ===========================================================================
  // Constructor
  // ===========================================================================
  function new(string name = "sram_coverage", uvm_component parent = null);
    super.new(name, parent);
    apb_cg = new();
    register_cg = new();
    memory_cg = new();
  endfunction

  // ===========================================================================
  // Write Function (called for each transaction)
  // ===========================================================================
  function void write(apb_transaction t);
    // Extract coverage values from transaction
    cov_op    = t.op;
    cov_addr  = t.addr;
    cov_size  = t.size;
    cov_error = t.error;

    // Determine address region
    is_register_access = (t.addr < SRAM_BASE);
    is_memory_access   = (t.addr >= SRAM_BASE) && (t.addr < SRAM_BASE + SRAM_SIZE);

    // Sample covergroups
    apb_cg.sample();

    if (is_register_access) begin
      register_cg.sample();
    end

    if (is_memory_access) begin
      memory_cg.sample();
    end
  endfunction

  // ===========================================================================
  // Report Phase
  // ===========================================================================
  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf(
      "\n========================================\n" +
      "       COVERAGE SUMMARY\n" +
      "========================================\n" +
      "  APB Coverage:      %.2f%%\n" +
      "  Register Coverage: %.2f%%\n" +
      "  Memory Coverage:   %.2f%%\n" +
      "========================================",
      apb_cg.get_coverage(),
      register_cg.get_coverage(),
      memory_cg.get_coverage()), UVM_LOW)
  endfunction

endclass : sram_coverage
