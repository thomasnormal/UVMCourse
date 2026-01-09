// =============================================================================
// SRAM Controller - Reference Model
// =============================================================================
// This reference model implements the expected behavior of the SRAM Controller.
// Register operations are implemented. Students must implement the SRAM
// access prediction logic.
// =============================================================================

class sram_ref_model extends uvm_component;

  `uvm_component_utils(sram_ref_model)

  // ===========================================================================
  // Internal State - Register Mirror (PROVIDED)
  // ===========================================================================

  // CTRL Register (0x00)
  bit        ctrl_en;         // [0]    Controller Enable
  bit        ctrl_width;      // [1]    Data width (0=8-bit, 1=16-bit)
  bit [7:0]  ctrl_wait;       // [15:8] Additional wait states

  // STATUS Register (0x04)
  bit        status_busy;     // [0]    Controller busy
  bit        status_error;    // [1]    Access error

  // TIMING0 Register (0x08)
  bit [7:0]  timing_taa;      // [7:0]  Address access time
  bit [7:0]  timing_toe;      // [15:8] Output enable access time

  // TIMING1 Register (0x0C)
  bit [7:0]  timing_twc;      // [7:0]  Write cycle time
  bit [7:0]  timing_tas;      // [15:8] Address setup time
  bit [7:0]  timing_tds;      // [23:16] Data setup time

  // ===========================================================================
  // Memory Model (PROVIDED)
  // ===========================================================================
  bit [7:0]  memory[logic [15:0]];  // Expected memory contents

  // ===========================================================================
  // Analysis Ports
  // ===========================================================================
  uvm_analysis_port #(apb_transaction)  expected_apb_ap;
  uvm_analysis_port #(sram_transaction) expected_sram_ap;

  // ===========================================================================
  // Constructor
  // ===========================================================================
  function new(string name = "sram_ref_model", uvm_component parent = null);
    super.new(name, parent);
    expected_apb_ap = new("expected_apb_ap", this);
    expected_sram_ap = new("expected_sram_ap", this);
  endfunction

  // ===========================================================================
  // Build Phase
  // ===========================================================================
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    reset();
  endfunction

  // ===========================================================================
  // Reset - Initialize all state (PROVIDED)
  // ===========================================================================
  function void reset();
    // CTRL - Reset value 0x0000_0001
    ctrl_en     = 1;
    ctrl_width  = 0;
    ctrl_wait   = 0;

    // STATUS - Reset value 0x0000_0000
    status_busy  = 0;
    status_error = 0;

    // TIMING0 - Reset value 0x0000_0505
    timing_taa = DEFAULT_TAA;
    timing_toe = DEFAULT_TOE;

    // TIMING1 - Reset value 0x0000_0303
    timing_twc = DEFAULT_TWC;
    timing_tas = DEFAULT_TAS;
    timing_tds = DEFAULT_TDS;

    // Clear memory
    memory.delete();

    `uvm_info(get_type_name(), "Reference model reset complete", UVM_MEDIUM)
  endfunction

  // ===========================================================================
  // Register Write (PROVIDED)
  // ===========================================================================
  function void register_write(bit [31:0] addr, bit [31:0] data);
    `uvm_info(get_type_name(), $sformatf("REG WRITE: addr=0x%08h data=0x%08h", addr, data), UVM_HIGH)

    case (addr)
      ADDR_CTRL: begin
        ctrl_en    = data[0];
        ctrl_width = data[1];
        ctrl_wait  = data[15:8];
      end

      ADDR_STATUS: begin
        // STATUS is read-only, writes ignored
      end

      ADDR_TIMING0: begin
        timing_taa = data[7:0];
        timing_toe = data[15:8];
      end

      ADDR_TIMING1: begin
        timing_twc = data[7:0];
        timing_tas = data[15:8];
        timing_tds = data[23:16];
      end

      default: begin
        `uvm_info(get_type_name(), $sformatf("Write to unknown register: 0x%08h", addr), UVM_MEDIUM)
      end
    endcase
  endfunction

  // ===========================================================================
  // Register Read (PROVIDED)
  // ===========================================================================
  function bit [31:0] register_read(bit [31:0] addr);
    bit [31:0] data;

    case (addr)
      ADDR_CTRL: begin
        data = {16'h0, ctrl_wait, 6'h0, ctrl_width, ctrl_en};
      end

      ADDR_STATUS: begin
        data = {30'h0, status_error, status_busy};
        status_error = 0;  // Clear on read
      end

      ADDR_TIMING0: begin
        data = {16'h0, timing_toe, timing_taa};
      end

      ADDR_TIMING1: begin
        data = {8'h0, timing_tds, timing_tas, timing_twc};
      end

      default: begin
        data = 32'h0;
      end
    endcase

    `uvm_info(get_type_name(), $sformatf("REG READ: addr=0x%08h data=0x%08h", addr, data), UVM_HIGH)
    return data;
  endfunction

  // ===========================================================================
  // TODO: Process APB Transaction
  // ===========================================================================
  // This function is called for each APB transaction observed.
  // Determine if it's a register access or memory access and handle accordingly.
  //
  // For register accesses (addr < SRAM_BASE):
  //   - Use register_write() or register_read()
  //
  // For memory accesses (addr >= SRAM_BASE && addr < SRAM_BASE + SRAM_SIZE):
  //   - Call predict_sram_access() to predict expected SRAM behavior
  //
  // Return the expected APB response
  // ===========================================================================
  function apb_transaction process_apb_transaction(apb_transaction txn);
    apb_transaction expected;
    expected = new("expected");
    expected.copy(txn);

    // TODO: Implement transaction processing
    //
    // Hints:
    // - Check if addr is in register space or memory window
    // - For registers: use register_write/register_read
    // - For memory: call predict_sram_access()
    // - Set expected.rdata for reads
    // - Set expected.error if access when disabled

    if (txn.addr < SRAM_BASE) begin
      // Register access
      if (txn.op == APB_WRITE) begin
        register_write(txn.addr, txn.data);
      end else begin
        expected.rdata = register_read(txn.addr);
      end
      expected.error = 0;
    end
    else if (txn.addr < SRAM_BASE + SRAM_SIZE) begin
      // Memory window access
      // TODO: Check if controller is enabled
      // TODO: Call predict_sram_access()
      // TODO: Set expected.rdata for reads
      // TODO: Set expected.error if disabled

    end
    else begin
      // Invalid address
      expected.error = 1;
    end

    return expected;
  endfunction

  // ===========================================================================
  // TODO: Predict SRAM Access
  // ===========================================================================
  // Given an APB memory access, predict the expected SRAM bus activity:
  //
  // 1. Calculate SRAM address from APB address
  // 2. Determine number of SRAM cycles (1 for byte, 2 for halfword, 4 for word)
  // 3. For writes: update memory[] model
  // 4. For reads: return expected data from memory[]
  // 5. Create sram_transaction(s) and write to expected_sram_ap
  //
  // Consider:
  // - Address alignment
  // - Byte ordering (little-endian)
  // - Multi-byte access sequencing
  // ===========================================================================
  function bit [31:0] predict_sram_access(apb_transaction txn);
    bit [15:0] sram_addr;
    bit [31:0] rdata;
    int num_bytes;

    // Calculate SRAM address
    sram_addr = txn.addr[15:0];

    // Determine number of bytes based on access size
    case (txn.size)
      SIZE_BYTE:     num_bytes = 1;
      SIZE_HALFWORD: num_bytes = 2;
      SIZE_WORD:     num_bytes = 4;
    endcase

    // TODO: Implement SRAM access prediction
    //
    // For WRITE:
    //   - Extract bytes from txn.data
    //   - Store each byte in memory[sram_addr + i]
    //   - Create sram_transaction for each byte
    //
    // For READ:
    //   - Read bytes from memory[sram_addr + i]
    //   - Assemble into rdata (little-endian)
    //   - Create sram_transaction for each byte

    `uvm_info(get_type_name(), $sformatf("SRAM %s: addr=0x%04h bytes=%0d",
              txn.op == APB_WRITE ? "WRITE" : "READ", sram_addr, num_bytes), UVM_HIGH)

    return rdata;
  endfunction

  // ===========================================================================
  // Calculate Expected Wait States (PROVIDED)
  // ===========================================================================
  function int get_read_cycles();
    // Read takes max(tAA, tOE) + wait states
    int cycles = (timing_taa > timing_toe) ? timing_taa : timing_toe;
    return cycles + ctrl_wait;
  endfunction

  function int get_write_cycles();
    // Write takes tWC + wait states
    return timing_twc + ctrl_wait;
  endfunction

  // ===========================================================================
  // Debug Print (PROVIDED)
  // ===========================================================================
  function void print_state();
    `uvm_info(get_type_name(), $sformatf(
      "\n=== Reference Model State ===\n" +
      "CTRL: EN=%0d WIDTH=%0d WAIT=%0d\n" +
      "TIMING0: tAA=%0d tOE=%0d\n" +
      "TIMING1: tWC=%0d tAS=%0d tDS=%0d\n" +
      "Memory entries: %0d\n",
      ctrl_en, ctrl_width, ctrl_wait,
      timing_taa, timing_toe,
      timing_twc, timing_tas, timing_tds,
      memory.size()
    ), UVM_LOW)
  endfunction

endclass : sram_ref_model
