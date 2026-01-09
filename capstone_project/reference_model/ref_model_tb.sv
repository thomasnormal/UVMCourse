// =============================================================================
// SPI Reference Model - Standalone Testbench
// =============================================================================
// This testbench verifies the SPI reference model works correctly without
// requiring an actual DUT. It tests:
// - Register read/write operations
// - FIFO behavior
// - SPI transfer prediction (loopback mode)
// - Interrupt generation
// - All data sizes and modes
// =============================================================================

`timescale 1ns/1ps

// Minimal UVM-like macros for standalone simulation
`define uvm_info(ID, MSG, VERBOSITY) $display("[%0t] %s: %s", $time, ID, MSG)
`define uvm_warning(ID, MSG) $display("[%0t] WARNING %s: %s", $time, ID, MSG)
`define uvm_error(ID, MSG) begin $display("[%0t] ERROR %s: %s", $time, ID, MSG); error_count++; end

module ref_model_tb;

  // ==========================================================================
  // Test Results Tracking
  // ==========================================================================
  int test_count = 0;
  int pass_count = 0;
  int error_count = 0;

  // ==========================================================================
  // Reference Model Instance (simplified - no UVM)
  // ==========================================================================

  // Register addresses
  localparam ADDR_CTRL    = 8'h00;
  localparam ADDR_STATUS  = 8'h04;
  localparam ADDR_CLKDIV  = 8'h08;
  localparam ADDR_SSCTL   = 8'h0C;
  localparam ADDR_TXDATA  = 8'h10;
  localparam ADDR_RXDATA  = 8'h14;
  localparam ADDR_INTEN   = 8'h18;
  localparam ADDR_INTSTAT = 8'h1C;
  localparam ADDR_FIFOST  = 8'h20;

  // FIFO depth
  localparam FIFO_DEPTH = 8;

  // Internal state
  bit        ctrl_en;
  bit        ctrl_cpol;
  bit        ctrl_cpha;
  bit        ctrl_lsbf;
  bit        ctrl_loop;
  bit [1:0]  ctrl_dsize;
  bit        ctrl_manual_ss;
  bit [7:0]  ctrl_ifd;
  bit        status_busy;
  bit        status_rxovr;
  bit [7:0]  clkdiv;
  bit [3:0]  ssctl_ss_sel;
  bit        ssctl_ss_level;
  bit [5:0]  inten;
  bit        intstat_tc;
  bit        intstat_rxovr;
  bit [31:0] tx_fifo[$];
  bit [31:0] rx_fifo[$];
  bit [31:0] last_rx_data;

  // ==========================================================================
  // Helper Functions
  // ==========================================================================

  function automatic void reset_model();
    ctrl_en        = 0;
    ctrl_cpol      = 0;
    ctrl_cpha      = 0;
    ctrl_lsbf      = 0;
    ctrl_loop      = 0;
    ctrl_dsize     = 2'b00;
    ctrl_manual_ss = 0;
    ctrl_ifd       = 0;
    status_busy    = 0;
    status_rxovr   = 0;
    clkdiv         = 8'h02;
    ssctl_ss_sel   = 4'hF;
    ssctl_ss_level = 1;
    inten          = 0;
    intstat_tc     = 0;
    intstat_rxovr  = 0;
    tx_fifo.delete();
    rx_fifo.delete();
    last_rx_data   = 0;
  endfunction

  function automatic int get_num_bits();
    case (ctrl_dsize)
      2'b00: return 8;
      2'b01: return 16;
      2'b10: return 32;
      2'b11: return 4;
    endcase
  endfunction

  function automatic bit [31:0] mask_data(bit [31:0] data);
    case (ctrl_dsize)
      2'b00: return data & 32'h000000FF;
      2'b01: return data & 32'h0000FFFF;
      2'b10: return data;
      2'b11: return data & 32'h0000000F;
    endcase
  endfunction

  function automatic bit [31:0] reverse_bits(bit [31:0] data, int num_bits);
    bit [31:0] result = 0;
    for (int i = 0; i < num_bits; i++) begin
      result[i] = data[num_bits - 1 - i];
    end
    return result;
  endfunction

  function automatic bit is_tx_empty();
    return (tx_fifo.size() == 0);
  endfunction

  function automatic bit is_tx_not_full();
    return (tx_fifo.size() < FIFO_DEPTH);
  endfunction

  function automatic bit is_tx_half_empty();
    return (tx_fifo.size() <= 4);
  endfunction

  function automatic bit is_rx_not_empty();
    return (rx_fifo.size() > 0);
  endfunction

  function automatic bit is_rx_full();
    return (rx_fifo.size() >= FIFO_DEPTH);
  endfunction

  function automatic bit is_rx_half_full();
    return (rx_fifo.size() >= 4);
  endfunction

  function automatic bit [3:0] get_tx_level();
    return tx_fifo.size();
  endfunction

  function automatic bit [3:0] get_rx_level();
    return rx_fifo.size();
  endfunction

  function automatic bit predict_irq();
    return (intstat_tc       & inten[0]) |
           (is_tx_empty()    & inten[1]) |
           (is_tx_half_empty() & inten[2]) |
           (is_rx_full()     & inten[3]) |
           (is_rx_half_full() & inten[4]) |
           (intstat_rxovr    & inten[5]);
  endfunction

  // ==========================================================================
  // Register Write
  // ==========================================================================
  function automatic void register_write(bit [7:0] addr, bit [31:0] data);
    case (addr)
      ADDR_CTRL: begin
        ctrl_en        = data[0];
        ctrl_cpol      = data[1];
        ctrl_cpha      = data[2];
        ctrl_lsbf      = data[3];
        ctrl_loop      = data[4];
        ctrl_dsize     = data[6:5];
        ctrl_manual_ss = data[7];
        ctrl_ifd       = data[15:8];
      end
      ADDR_STATUS: begin
        if (data[5]) status_rxovr = 0;
      end
      ADDR_CLKDIV: begin
        clkdiv = data[7:0];
        if (clkdiv < 2) clkdiv = 2;
        if (clkdiv[0]) clkdiv = clkdiv - 1;
      end
      ADDR_SSCTL: begin
        ssctl_ss_sel   = data[3:0];
        ssctl_ss_level = data[4];
      end
      ADDR_TXDATA: begin
        if (tx_fifo.size() < FIFO_DEPTH) begin
          tx_fifo.push_back(mask_data(data));
        end
      end
      ADDR_INTEN: begin
        inten = data[5:0];
      end
      ADDR_INTSTAT: begin
        if (data[0]) intstat_tc = 0;
        if (data[5]) intstat_rxovr = 0;
      end
    endcase
  endfunction

  // ==========================================================================
  // Register Read
  // ==========================================================================
  function automatic bit [31:0] register_read(bit [7:0] addr);
    bit [31:0] data;
    case (addr)
      ADDR_CTRL: begin
        data = {16'h0, ctrl_ifd, ctrl_manual_ss, ctrl_dsize, ctrl_loop,
                ctrl_lsbf, ctrl_cpha, ctrl_cpol, ctrl_en};
      end
      ADDR_STATUS: begin
        data = {26'h0, status_rxovr, is_rx_full(), is_rx_not_empty(),
                is_tx_not_full(), is_tx_empty(), status_busy};
      end
      ADDR_CLKDIV: begin
        data = {24'h0, clkdiv};
      end
      ADDR_SSCTL: begin
        data = {27'h0, ssctl_ss_level, ssctl_ss_sel};
      end
      ADDR_RXDATA: begin
        if (rx_fifo.size() > 0) begin
          data = rx_fifo.pop_front();
          last_rx_data = data;
        end else begin
          data = last_rx_data;
        end
      end
      ADDR_INTEN: begin
        data = {26'h0, inten};
      end
      ADDR_INTSTAT: begin
        data = {26'h0, intstat_rxovr, is_rx_half_full(), is_rx_full(),
                is_tx_half_empty(), is_tx_empty(), intstat_tc};
      end
      ADDR_FIFOST: begin
        data = {20'h0, get_rx_level(), 4'h0, get_tx_level()};
      end
      default: data = 0;
    endcase
    return data;
  endfunction

  // ==========================================================================
  // SPI Transfer Simulation (Loopback)
  // ==========================================================================
  function automatic void simulate_loopback_transfer();
    bit [31:0] tx_data, rx_data;
    int num_bits = get_num_bits();

    while (tx_fifo.size() > 0) begin
      tx_data = tx_fifo.pop_front();

      // In loopback, RX = TX
      rx_data = tx_data;

      // Push to RX FIFO
      if (rx_fifo.size() < FIFO_DEPTH) begin
        rx_fifo.push_back(rx_data);
      end else begin
        status_rxovr = 1;
        intstat_rxovr = 1;
      end
    end

    // Set transfer complete
    intstat_tc = 1;
  endfunction

  // ==========================================================================
  // Test Utilities
  // ==========================================================================
  function automatic void check_value(string name, bit [31:0] actual, bit [31:0] expected);
    test_count++;
    if (actual === expected) begin
      pass_count++;
      $display("  [PASS] %s: 0x%08h == 0x%08h", name, actual, expected);
    end else begin
      error_count++;
      $display("  [FAIL] %s: got 0x%08h, expected 0x%08h", name, actual, expected);
    end
  endfunction

  // ==========================================================================
  // Test Cases
  // ==========================================================================

  task test_reset_values();
    bit [31:0] data;
    $display("\n=== Test: Reset Values ===");
    reset_model();

    data = register_read(ADDR_CTRL);
    check_value("CTRL reset", data, 32'h0);

    data = register_read(ADDR_STATUS);
    check_value("STATUS reset (TXE=1, TXNF=1)", data, 32'h06);

    data = register_read(ADDR_CLKDIV);
    check_value("CLKDIV reset", data, 32'h02);

    data = register_read(ADDR_SSCTL);
    check_value("SSCTL reset (SS_SEL=F, SS_LEVEL=1)", data, 32'h1F);

    data = register_read(ADDR_FIFOST);
    check_value("FIFOST reset (empty)", data, 32'h0);
  endtask

  task test_ctrl_register();
    bit [31:0] data;
    $display("\n=== Test: CTRL Register ===");
    reset_model();

    // Write all fields (0xFFFF sets bits 0-15)
    register_write(ADDR_CTRL, 32'h0000_FFFF);
    data = register_read(ADDR_CTRL);
    check_value("CTRL write/read", data, 32'h0000_FFFF);

    // Check individual fields
    check_value("CTRL.EN", ctrl_en, 1);
    check_value("CTRL.CPOL", ctrl_cpol, 1);
    check_value("CTRL.CPHA", ctrl_cpha, 1);
    check_value("CTRL.LSBF", ctrl_lsbf, 1);
    check_value("CTRL.LOOP", ctrl_loop, 1);
    check_value("CTRL.DSIZE", ctrl_dsize, 2'b11);
    check_value("CTRL.MANUAL_SS", ctrl_manual_ss, 1);
    check_value("CTRL.IFD", ctrl_ifd, 8'hFF);
  endtask

  task test_clkdiv_constraints();
    bit [31:0] data;
    $display("\n=== Test: CLKDIV Constraints ===");
    reset_model();

    // Test minimum value
    register_write(ADDR_CLKDIV, 32'h00);
    data = register_read(ADDR_CLKDIV);
    check_value("CLKDIV min (0->2)", data, 32'h02);

    // Test odd value rounding
    register_write(ADDR_CLKDIV, 32'h05);
    data = register_read(ADDR_CLKDIV);
    check_value("CLKDIV odd (5->4)", data, 32'h04);

    // Test valid even value
    register_write(ADDR_CLKDIV, 32'h10);
    data = register_read(ADDR_CLKDIV);
    check_value("CLKDIV even (16)", data, 32'h10);
  endtask

  task test_tx_fifo();
    bit [31:0] data;
    $display("\n=== Test: TX FIFO ===");
    reset_model();

    // Write 8 entries
    for (int i = 0; i < 8; i++) begin
      register_write(ADDR_TXDATA, i + 1);
    end

    data = register_read(ADDR_FIFOST);
    check_value("TX FIFO level (8)", data[3:0], 8);

    data = register_read(ADDR_STATUS);
    check_value("STATUS.TXE (not empty)", data[1], 0);
    check_value("STATUS.TXNF (full)", data[2], 0);

    // Try to write when full (should be ignored)
    register_write(ADDR_TXDATA, 32'hDEAD);
    data = register_read(ADDR_FIFOST);
    check_value("TX FIFO still 8 after overflow write", data[3:0], 8);
  endtask

  task test_rx_fifo();
    bit [31:0] data;
    $display("\n=== Test: RX FIFO ===");
    reset_model();

    // Manually push to RX FIFO
    for (int i = 0; i < 8; i++) begin
      rx_fifo.push_back((i + 1) * 10);
    end

    data = register_read(ADDR_FIFOST);
    check_value("RX FIFO level (8)", data[11:8], 8);

    data = register_read(ADDR_STATUS);
    check_value("STATUS.RXNE (not empty)", data[3], 1);
    check_value("STATUS.RXF (full)", data[4], 1);

    // Read and verify FIFO order
    data = register_read(ADDR_RXDATA);
    check_value("RX FIFO pop 1", data, 10);

    data = register_read(ADDR_RXDATA);
    check_value("RX FIFO pop 2", data, 20);

    // Read remaining
    for (int i = 2; i < 8; i++) begin
      data = register_read(ADDR_RXDATA);
    end

    // Read when empty (should return last value)
    data = register_read(ADDR_RXDATA);
    check_value("RX FIFO read when empty (last value)", data, 80);
  endtask

  task test_loopback_8bit();
    bit [31:0] data;
    $display("\n=== Test: Loopback Mode (8-bit) ===");
    reset_model();

    // Configure: Enable, Loopback, 8-bit
    register_write(ADDR_CTRL, 32'h0000_0011); // EN=1, LOOP=1
    check_value("CTRL.LOOP", ctrl_loop, 1);

    // Write test data
    register_write(ADDR_TXDATA, 32'h000000A5);
    register_write(ADDR_TXDATA, 32'h0000005A);

    // Simulate transfer
    simulate_loopback_transfer();

    // Verify RX data
    data = register_read(ADDR_RXDATA);
    check_value("Loopback RX 1 (8-bit)", data, 32'h000000A5);

    data = register_read(ADDR_RXDATA);
    check_value("Loopback RX 2 (8-bit)", data, 32'h0000005A);

    // Check transfer complete
    data = register_read(ADDR_INTSTAT);
    check_value("INTSTAT.TC set", data[0], 1);
  endtask

  task test_loopback_16bit();
    bit [31:0] data;
    $display("\n=== Test: Loopback Mode (16-bit) ===");
    reset_model();

    // Configure: Enable, Loopback, 16-bit
    register_write(ADDR_CTRL, 32'h0000_0031); // EN=1, LOOP=1, DSIZE=01
    check_value("CTRL.DSIZE", ctrl_dsize, 2'b01);

    // Write test data
    register_write(ADDR_TXDATA, 32'h0000CAFE);
    register_write(ADDR_TXDATA, 32'h0000BEEF);

    // Simulate transfer
    simulate_loopback_transfer();

    // Verify RX data
    data = register_read(ADDR_RXDATA);
    check_value("Loopback RX 1 (16-bit)", data, 32'h0000CAFE);

    data = register_read(ADDR_RXDATA);
    check_value("Loopback RX 2 (16-bit)", data, 32'h0000BEEF);
  endtask

  task test_loopback_32bit();
    bit [31:0] data;
    $display("\n=== Test: Loopback Mode (32-bit) ===");
    reset_model();

    // Configure: Enable, Loopback, 32-bit
    register_write(ADDR_CTRL, 32'h0000_0051); // EN=1, LOOP=1, DSIZE=10
    check_value("CTRL.DSIZE", ctrl_dsize, 2'b10);

    // Write test data
    register_write(ADDR_TXDATA, 32'hDEADBEEF);
    register_write(ADDR_TXDATA, 32'h12345678);

    // Simulate transfer
    simulate_loopback_transfer();

    // Verify RX data
    data = register_read(ADDR_RXDATA);
    check_value("Loopback RX 1 (32-bit)", data, 32'hDEADBEEF);

    data = register_read(ADDR_RXDATA);
    check_value("Loopback RX 2 (32-bit)", data, 32'h12345678);
  endtask

  task test_loopback_4bit();
    bit [31:0] data;
    $display("\n=== Test: Loopback Mode (4-bit) ===");
    reset_model();

    // Configure: Enable, Loopback, 4-bit
    register_write(ADDR_CTRL, 32'h0000_0071); // EN=1, LOOP=1, DSIZE=11
    check_value("CTRL.DSIZE", ctrl_dsize, 2'b11);

    // Write test data (only lower 4 bits should be used)
    register_write(ADDR_TXDATA, 32'hFFFFFFFF); // Should mask to 0xF
    register_write(ADDR_TXDATA, 32'h0000000A);

    // Simulate transfer
    simulate_loopback_transfer();

    // Verify RX data
    data = register_read(ADDR_RXDATA);
    check_value("Loopback RX 1 (4-bit masked)", data, 32'h0000000F);

    data = register_read(ADDR_RXDATA);
    check_value("Loopback RX 2 (4-bit)", data, 32'h0000000A);
  endtask

  task test_interrupts();
    bit [31:0] data;
    $display("\n=== Test: Interrupts ===");
    reset_model();

    // Enable TX empty interrupt
    register_write(ADDR_INTEN, 32'h02); // TXE_IE

    // TX FIFO is empty, so IRQ should be asserted
    check_value("IRQ (TXE enabled, FIFO empty)", predict_irq(), 1);

    // Write data to TX FIFO
    register_write(ADDR_TXDATA, 32'h12345678);
    check_value("IRQ (TXE enabled, FIFO not empty)", predict_irq(), 0);

    // Enable TC interrupt
    register_write(ADDR_INTEN, 32'h01); // TC_IE

    // Simulate transfer to set TC
    ctrl_loop = 1;
    ctrl_en = 1;
    simulate_loopback_transfer();

    check_value("IRQ (TC enabled, TC set)", predict_irq(), 1);

    // Clear TC
    register_write(ADDR_INTSTAT, 32'h01);
    check_value("IRQ after TC clear", predict_irq(), 0);
  endtask

  task test_w1c_bits();
    bit [31:0] data;
    $display("\n=== Test: Write-1-to-Clear Bits ===");
    reset_model();

    // Set RXOVR manually
    status_rxovr = 1;
    intstat_rxovr = 1;

    data = register_read(ADDR_STATUS);
    check_value("STATUS.RXOVR set", data[5], 1);

    // Clear via STATUS write
    register_write(ADDR_STATUS, 32'h20);
    data = register_read(ADDR_STATUS);
    check_value("STATUS.RXOVR cleared", data[5], 0);

    // Set TC
    intstat_tc = 1;
    data = register_read(ADDR_INTSTAT);
    check_value("INTSTAT.TC set", data[0], 1);

    // Clear via INTSTAT write
    register_write(ADDR_INTSTAT, 32'h01);
    data = register_read(ADDR_INTSTAT);
    check_value("INTSTAT.TC cleared", data[0], 0);
  endtask

  task test_data_masking();
    bit [31:0] data;
    $display("\n=== Test: Data Masking ===");
    reset_model();

    // 8-bit mode - should mask to 0xFF
    register_write(ADDR_CTRL, 32'h0000_0001); // EN=1, DSIZE=00
    register_write(ADDR_TXDATA, 32'hFFFFFFFF);
    check_value("TX FIFO 8-bit mask", tx_fifo[0], 32'h000000FF);
    tx_fifo.delete();

    // 16-bit mode - should mask to 0xFFFF
    register_write(ADDR_CTRL, 32'h0000_0021); // EN=1, DSIZE=01
    register_write(ADDR_TXDATA, 32'hFFFFFFFF);
    check_value("TX FIFO 16-bit mask", tx_fifo[0], 32'h0000FFFF);
    tx_fifo.delete();

    // 32-bit mode - no masking
    register_write(ADDR_CTRL, 32'h0000_0041); // EN=1, DSIZE=10
    register_write(ADDR_TXDATA, 32'hFFFFFFFF);
    check_value("TX FIFO 32-bit mask", tx_fifo[0], 32'hFFFFFFFF);
    tx_fifo.delete();

    // 4-bit mode - should mask to 0xF
    register_write(ADDR_CTRL, 32'h0000_0061); // EN=1, DSIZE=11
    register_write(ADDR_TXDATA, 32'hFFFFFFFF);
    check_value("TX FIFO 4-bit mask", tx_fifo[0], 32'h0000000F);
  endtask

  task test_ssctl();
    bit [31:0] data;
    $display("\n=== Test: Slave Select Control ===");
    reset_model();

    // Write SS_SEL and SS_LEVEL
    register_write(ADDR_SSCTL, 32'h0000_0015); // SS_LEVEL=1, SS_SEL=0101
    data = register_read(ADDR_SSCTL);
    check_value("SSCTL write/read", data, 32'h0000_0015);

    check_value("SSCTL.SS_SEL", ssctl_ss_sel, 4'h5);
    check_value("SSCTL.SS_LEVEL", ssctl_ss_level, 1);

    // Change to select slave 0
    register_write(ADDR_SSCTL, 32'h0000_000E); // SS_LEVEL=0, SS_SEL=1110
    data = register_read(ADDR_SSCTL);
    check_value("SSCTL select slave 0", data, 32'h0000_000E);
  endtask

  task test_fifo_thresholds();
    bit [31:0] data;
    $display("\n=== Test: FIFO Thresholds ===");
    reset_model();

    // TX FIFO half-empty threshold (<=4)
    for (int i = 0; i < 4; i++) begin
      register_write(ADDR_TXDATA, i);
    end
    check_value("TX half-empty (4 entries)", is_tx_half_empty(), 1);

    register_write(ADDR_TXDATA, 32'h99);
    check_value("TX not half-empty (5 entries)", is_tx_half_empty(), 0);

    // RX FIFO half-full threshold (>=4)
    for (int i = 0; i < 3; i++) begin
      rx_fifo.push_back(i);
    end
    check_value("RX not half-full (3 entries)", is_rx_half_full(), 0);

    rx_fifo.push_back(32'h99);
    check_value("RX half-full (4 entries)", is_rx_half_full(), 1);
  endtask

  // ==========================================================================
  // Main Test Runner
  // ==========================================================================
  initial begin
    $display("\n");
    $display("==========================================================");
    $display("     SPI Reference Model - Standalone Testbench");
    $display("==========================================================");

    // Run all tests
    test_reset_values();
    test_ctrl_register();
    test_clkdiv_constraints();
    test_tx_fifo();
    test_rx_fifo();
    test_loopback_8bit();
    test_loopback_16bit();
    test_loopback_32bit();
    test_loopback_4bit();
    test_interrupts();
    test_w1c_bits();
    test_data_masking();
    test_ssctl();
    test_fifo_thresholds();

    // Summary
    $display("\n");
    $display("==========================================================");
    $display("                    TEST SUMMARY");
    $display("==========================================================");
    $display("  Total Tests:  %0d", test_count);
    $display("  Passed:       %0d", pass_count);
    $display("  Failed:       %0d", error_count);
    $display("==========================================================");

    if (error_count == 0) begin
      $display("  *** ALL TESTS PASSED ***");
    end else begin
      $display("  *** SOME TESTS FAILED ***");
    end
    $display("==========================================================\n");

    $finish;
  end

endmodule
