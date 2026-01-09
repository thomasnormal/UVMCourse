// =============================================================================
// SPI Master Controller - Reference Model
// =============================================================================
// This reference model implements the expected behavior of the SPI Master
// as defined in the specification. It is used by the scoreboard to predict
// expected outputs and compare against actual DUT behavior.
// =============================================================================

class spi_ref_model extends uvm_component;

  `uvm_component_utils(spi_ref_model)

  // ===========================================================================
  // Configuration
  // ===========================================================================
  // Reference to configuration object if needed
  // spi_env_config cfg;

  // ===========================================================================
  // Internal State - Mirror of DUT Registers
  // ===========================================================================

  // Control Register (CTRL) - Offset 0x00
  bit        ctrl_en;        // [0]    SPI Enable
  bit        ctrl_cpol;      // [1]    Clock Polarity
  bit        ctrl_cpha;      // [2]    Clock Phase
  bit        ctrl_lsbf;      // [3]    LSB First
  bit        ctrl_loop;      // [4]    Loopback Mode
  bit [1:0]  ctrl_dsize;     // [6:5]  Data Size: 00=8, 01=16, 10=32, 11=4
  bit        ctrl_manual_ss; // [7]    Manual SS Control
  bit [7:0]  ctrl_ifd;       // [15:8] Inter-Frame Delay

  // Status Register (STATUS) - Read-only reflections of state
  bit        status_busy;    // SPI Busy
  bit        status_rxovr;   // RX Overrun (W1C)

  // Clock Divider Register (CLKDIV) - Offset 0x08
  bit [7:0]  clkdiv;

  // Slave Select Control (SSCTL) - Offset 0x0C
  bit [3:0]  ssctl_ss_sel;   // [3:0] Slave select mask
  bit        ssctl_ss_level; // [4]   Manual SS level

  // Interrupt Enable (INTEN) - Offset 0x18
  bit [5:0]  inten;

  // Interrupt Status flags
  bit        intstat_tc;     // Transfer Complete (W1C)
  bit        intstat_rxovr;  // RX Overrun (W1C)

  // ===========================================================================
  // FIFOs
  // ===========================================================================
  bit [31:0] tx_fifo[$];     // TX FIFO - max 8 entries
  bit [31:0] rx_fifo[$];     // RX FIFO - max 8 entries
  bit [31:0] last_rx_data;   // Last valid RX data read

  parameter int FIFO_DEPTH = 8;

  // ===========================================================================
  // Transfer State Machine
  // ===========================================================================
  typedef enum {
    SPI_IDLE,
    SPI_SS_SETUP,
    SPI_TRANSFER,
    SPI_IFD_WAIT,
    SPI_SS_HOLD
  } spi_state_e;

  spi_state_e spi_state;

  // Transfer tracking
  bit [31:0] shift_reg_tx;   // TX shift register
  bit [31:0] shift_reg_rx;   // RX shift register
  int        bit_count;      // Bits transferred in current word
  int        ifd_count;      // Inter-frame delay counter

  // ===========================================================================
  // Expected Output Signals
  // ===========================================================================
  bit        expected_sclk;
  bit        expected_mosi;
  bit [3:0]  expected_ss_n;
  bit        expected_irq;

  // ===========================================================================
  // Analysis Ports - For scoreboard connection
  // ===========================================================================
  uvm_analysis_port #(bit [31:0]) expected_rx_data_ap;
  uvm_analysis_port #(bit)        expected_irq_ap;
  uvm_analysis_port #(bit [3:0])  expected_ss_ap;

  // ===========================================================================
  // Constructor
  // ===========================================================================
  function new(string name = "spi_ref_model", uvm_component parent = null);
    super.new(name, parent);
    expected_rx_data_ap = new("expected_rx_data_ap", this);
    expected_irq_ap = new("expected_irq_ap", this);
    expected_ss_ap = new("expected_ss_ap", this);
  endfunction

  // ===========================================================================
  // Build Phase
  // ===========================================================================
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    reset();
  endfunction

  // ===========================================================================
  // Reset - Initialize all state to reset values per spec section 5
  // ===========================================================================
  function void reset();
    // Control Register - Reset value 0x00000000
    ctrl_en        = 0;
    ctrl_cpol      = 0;
    ctrl_cpha      = 0;
    ctrl_lsbf      = 0;
    ctrl_loop      = 0;
    ctrl_dsize     = 2'b00;  // 8-bit
    ctrl_manual_ss = 0;
    ctrl_ifd       = 0;

    // Status Register - Reset value 0x00000002 (TXE=1, TXNF=1)
    status_busy    = 0;
    status_rxovr   = 0;

    // Clock Divider - Reset value 0x00000002
    clkdiv         = 8'h02;

    // Slave Select Control - Reset value 0x0000000F
    ssctl_ss_sel   = 4'hF;   // All deselected (active low)
    ssctl_ss_level = 1;

    // Interrupt Enable - Reset value 0x00000000
    inten          = 0;

    // Interrupt Status - Reset value 0x00000000
    intstat_tc     = 0;
    intstat_rxovr  = 0;

    // Clear FIFOs
    tx_fifo.delete();
    rx_fifo.delete();
    last_rx_data = 0;

    // State machine
    spi_state = SPI_IDLE;
    shift_reg_tx = 0;
    shift_reg_rx = 0;
    bit_count = 0;
    ifd_count = 0;

    // Output signals
    expected_sclk = 0;  // Depends on CPOL
    expected_mosi = 0;
    expected_ss_n = 4'hF;  // All deselected
    expected_irq = 0;

    `uvm_info(get_type_name(), "Reference model reset complete", UVM_MEDIUM)
  endfunction

  // ===========================================================================
  // Get Number of Bits for Current Data Size
  // ===========================================================================
  function int get_num_bits();
    case (ctrl_dsize)
      2'b00: return 8;
      2'b01: return 16;
      2'b10: return 32;
      2'b11: return 4;
    endcase
  endfunction

  // ===========================================================================
  // Mask Data to Current Data Size
  // ===========================================================================
  function bit [31:0] mask_data(bit [31:0] data);
    case (ctrl_dsize)
      2'b00: return data & 32'h000000FF;  // 8-bit
      2'b01: return data & 32'h0000FFFF;  // 16-bit
      2'b10: return data;                  // 32-bit
      2'b11: return data & 32'h0000000F;  // 4-bit
    endcase
  endfunction

  // ===========================================================================
  // Reverse Bits (for LSB-first mode)
  // ===========================================================================
  function bit [31:0] reverse_bits(bit [31:0] data, int num_bits);
    bit [31:0] result = 0;
    for (int i = 0; i < num_bits; i++) begin
      result[i] = data[num_bits - 1 - i];
    end
    return result;
  endfunction

  // ===========================================================================
  // Register Write - Process APB writes to registers
  // ===========================================================================
  function void register_write(bit [7:0] addr, bit [31:0] data);
    `uvm_info(get_type_name(), $sformatf("REG WRITE: addr=0x%02h data=0x%08h", addr, data), UVM_HIGH)

    case (addr)
      8'h00: begin // CTRL
        ctrl_en        = data[0];
        ctrl_cpol      = data[1];
        ctrl_cpha      = data[2];
        ctrl_lsbf      = data[3];
        ctrl_loop      = data[4];
        ctrl_dsize     = data[6:5];
        ctrl_manual_ss = data[7];
        ctrl_ifd       = data[15:8];

        // When disabled, return to idle
        if (!ctrl_en) begin
          spi_state = SPI_IDLE;
          status_busy = 0;
          expected_ss_n = 4'hF;
        end

        // Update SCLK idle state based on CPOL
        if (spi_state == SPI_IDLE) begin
          expected_sclk = ctrl_cpol;
        end

        `uvm_info(get_type_name(), $sformatf("CTRL: EN=%0d CPOL=%0d CPHA=%0d LSBF=%0d LOOP=%0d DSIZE=%0d MANUAL_SS=%0d IFD=%0d",
          ctrl_en, ctrl_cpol, ctrl_cpha, ctrl_lsbf, ctrl_loop, ctrl_dsize, ctrl_manual_ss, ctrl_ifd), UVM_HIGH)
      end

      8'h04: begin // STATUS - W1C bits
        if (data[5]) begin
          status_rxovr = 0;
          `uvm_info(get_type_name(), "STATUS.RXOVR cleared", UVM_HIGH)
        end
      end

      8'h08: begin // CLKDIV
        clkdiv = data[7:0];
        // Enforce constraints: even value >= 2
        if (clkdiv < 2) clkdiv = 2;
        if (clkdiv[0]) clkdiv = clkdiv - 1; // Round down odd to even
        `uvm_info(get_type_name(), $sformatf("CLKDIV set to %0d", clkdiv), UVM_HIGH)
      end

      8'h0C: begin // SSCTL
        ssctl_ss_sel   = data[3:0];
        ssctl_ss_level = data[4];

        // In manual mode, update SS_N immediately
        if (ctrl_manual_ss) begin
          expected_ss_n = ssctl_ss_level ? 4'hF : ssctl_ss_sel;
          expected_ss_ap.write(expected_ss_n);
        end

        `uvm_info(get_type_name(), $sformatf("SSCTL: SS_SEL=0x%01h SS_LEVEL=%0d", ssctl_ss_sel, ssctl_ss_level), UVM_HIGH)
      end

      8'h10: begin // TXDATA
        if (tx_fifo.size() < FIFO_DEPTH) begin
          bit [31:0] masked_data = mask_data(data);
          tx_fifo.push_back(masked_data);
          `uvm_info(get_type_name(), $sformatf("TX FIFO push: 0x%08h (depth=%0d)", masked_data, tx_fifo.size()), UVM_HIGH)

          // If enabled and idle, start transfer
          if (ctrl_en && spi_state == SPI_IDLE) begin
            start_transfer();
          end
        end else begin
          `uvm_warning(get_type_name(), "TX FIFO full - write ignored")
        end
      end

      8'h18: begin // INTEN
        inten = data[5:0];
        `uvm_info(get_type_name(), $sformatf("INTEN set to 0x%02h", inten), UVM_HIGH)
        // Recalculate IRQ
        update_irq();
      end

      8'h1C: begin // INTSTAT - W1C bits
        if (data[0]) begin
          intstat_tc = 0;
          `uvm_info(get_type_name(), "INTSTAT.TC cleared", UVM_HIGH)
        end
        if (data[5]) begin
          intstat_rxovr = 0;
          `uvm_info(get_type_name(), "INTSTAT.RXOVR cleared", UVM_HIGH)
        end
        update_irq();
      end

      default: begin
        `uvm_warning(get_type_name(), $sformatf("Write to unknown/read-only register address: 0x%02h", addr))
      end
    endcase
  endfunction

  // ===========================================================================
  // Register Read - Return expected value for APB reads
  // ===========================================================================
  function bit [31:0] register_read(bit [7:0] addr);
    bit [31:0] data;

    case (addr)
      8'h00: begin // CTRL
        data = {16'h0, ctrl_ifd, ctrl_manual_ss, ctrl_dsize, ctrl_loop,
                ctrl_lsbf, ctrl_cpha, ctrl_cpol, ctrl_en};
      end

      8'h04: begin // STATUS
        data = {26'h0, status_rxovr, is_rx_full(), is_rx_not_empty(),
                is_tx_not_full(), is_tx_empty(), status_busy};
      end

      8'h08: begin // CLKDIV
        data = {24'h0, clkdiv};
      end

      8'h0C: begin // SSCTL
        data = {27'h0, ssctl_ss_level, ssctl_ss_sel};
      end

      8'h14: begin // RXDATA - Pop from RX FIFO
        if (rx_fifo.size() > 0) begin
          data = rx_fifo.pop_front();
          last_rx_data = data;
          `uvm_info(get_type_name(), $sformatf("RX FIFO pop: 0x%08h (depth=%0d)", data, rx_fifo.size()), UVM_HIGH)
        end else begin
          data = last_rx_data;  // Return last valid data if empty
          `uvm_info(get_type_name(), $sformatf("RX FIFO empty - returning last data: 0x%08h", data), UVM_MEDIUM)
        end
        update_irq();  // Update FIFO-related interrupts
      end

      8'h18: begin // INTEN
        data = {26'h0, inten};
      end

      8'h1C: begin // INTSTAT
        data = {26'h0, intstat_rxovr, is_rx_half_full(), is_rx_full(),
                is_tx_half_empty(), is_tx_empty(), intstat_tc};
      end

      8'h20: begin // FIFOST
        data = {20'h0, get_rx_level(), 4'h0, get_tx_level()};
      end

      default: begin
        `uvm_warning(get_type_name(), $sformatf("Read from unknown register address: 0x%02h", addr))
        data = 32'h0;
      end
    endcase

    `uvm_info(get_type_name(), $sformatf("REG READ: addr=0x%02h data=0x%08h", addr, data), UVM_HIGH)
    return data;
  endfunction

  // ===========================================================================
  // Start Transfer - Begin a new SPI transfer
  // ===========================================================================
  function void start_transfer();
    if (tx_fifo.size() == 0) begin
      `uvm_info(get_type_name(), "Cannot start transfer - TX FIFO empty", UVM_HIGH)
      return;
    end

    // Load shift register from TX FIFO
    shift_reg_tx = tx_fifo.pop_front();
    shift_reg_rx = 0;
    bit_count = 0;

    // Handle LSB-first mode
    if (ctrl_lsbf) begin
      shift_reg_tx = reverse_bits(shift_reg_tx, get_num_bits());
    end

    // Set busy
    status_busy = 1;

    // Assert SS_N (unless manual mode)
    if (!ctrl_manual_ss) begin
      expected_ss_n = ssctl_ss_sel;
      expected_ss_ap.write(expected_ss_n);
    end

    // Set initial SCLK state
    expected_sclk = ctrl_cpol;

    // Set initial MOSI based on CPHA
    if (!ctrl_cpha) begin
      // CPHA=0: Data valid before first clock edge
      int msb_pos = get_num_bits() - 1;
      expected_mosi = shift_reg_tx[msb_pos];
    end

    spi_state = SPI_SS_SETUP;
    `uvm_info(get_type_name(), $sformatf("Starting transfer: TX=0x%08h", shift_reg_tx), UVM_MEDIUM)
  endfunction

  // ===========================================================================
  // SPI Transfer - Process one bit at a time
  // ===========================================================================
  // This should be called on each SCLK edge by the testbench
  function void process_sclk_edge(bit sclk_rising, bit miso_in);
    int num_bits = get_num_bits();
    int msb_pos = num_bits - 1;
    bit sample_edge;
    bit shift_edge;

    // Determine sample and shift edges based on mode
    // Mode 0: CPOL=0, CPHA=0 -> Sample on rising, shift on falling
    // Mode 1: CPOL=0, CPHA=1 -> Sample on falling, shift on rising
    // Mode 2: CPOL=1, CPHA=0 -> Sample on falling, shift on rising
    // Mode 3: CPOL=1, CPHA=1 -> Sample on rising, shift on falling
    if (ctrl_cpha == 0) begin
      // CPHA=0: Sample on first edge of SCLK in the cycle
      sample_edge = (ctrl_cpol == 0) ? sclk_rising : !sclk_rising;
      shift_edge = !sample_edge;
    end else begin
      // CPHA=1: Sample on second edge of SCLK in the cycle
      sample_edge = (ctrl_cpol == 0) ? !sclk_rising : sclk_rising;
      shift_edge = !sample_edge;
    end

    if (sample_edge && spi_state == SPI_TRANSFER) begin
      // Sample MISO (or loopback)
      bit miso_bit;
      if (ctrl_loop) begin
        miso_bit = expected_mosi;  // Loopback mode
      end else begin
        miso_bit = miso_in;
      end

      // Shift in from MSB position
      shift_reg_rx = {shift_reg_rx[30:0], miso_bit};
      bit_count++;

      `uvm_info(get_type_name(), $sformatf("Sample bit %0d: MISO=%0b RX=0x%08h", bit_count, miso_bit, shift_reg_rx), UVM_DEBUG)

      // Check if transfer complete
      if (bit_count >= num_bits) begin
        complete_word_transfer();
      end
    end

    if (shift_edge && spi_state == SPI_TRANSFER && bit_count < num_bits) begin
      // Shift out next bit
      shift_reg_tx = {shift_reg_tx[30:0], 1'b0};
      expected_mosi = shift_reg_tx[msb_pos];

      `uvm_info(get_type_name(), $sformatf("Shift: MOSI=%0b TX=0x%08h", expected_mosi, shift_reg_tx), UVM_DEBUG)
    end
  endfunction

  // ===========================================================================
  // Complete Word Transfer
  // ===========================================================================
  function void complete_word_transfer();
    bit [31:0] rx_data;
    int num_bits = get_num_bits();

    // Mask received data
    rx_data = shift_reg_rx & ((1 << num_bits) - 1);

    // Handle LSB-first mode
    if (ctrl_lsbf) begin
      rx_data = reverse_bits(rx_data, num_bits);
    end

    // Push to RX FIFO
    if (rx_fifo.size() < FIFO_DEPTH) begin
      rx_fifo.push_back(rx_data);
      expected_rx_data_ap.write(rx_data);
      `uvm_info(get_type_name(), $sformatf("RX FIFO push: 0x%08h (depth=%0d)", rx_data, rx_fifo.size()), UVM_MEDIUM)
    end else begin
      // RX Overrun
      status_rxovr = 1;
      intstat_rxovr = 1;
      `uvm_warning(get_type_name(), $sformatf("RX FIFO overrun! Data 0x%08h lost", rx_data))
    end

    // Check for more data in TX FIFO
    if (tx_fifo.size() > 0) begin
      // More data to transfer - go to IFD state
      if (ctrl_ifd > 0) begin
        spi_state = SPI_IFD_WAIT;
        ifd_count = 0;
      end else begin
        // No IFD delay - start next transfer immediately
        shift_reg_tx = tx_fifo.pop_front();
        if (ctrl_lsbf) begin
          shift_reg_tx = reverse_bits(shift_reg_tx, num_bits);
        end
        shift_reg_rx = 0;
        bit_count = 0;
        spi_state = SPI_TRANSFER;
      end
    end else begin
      // TX FIFO empty - complete transfer
      if (!ctrl_manual_ss) begin
        spi_state = SPI_SS_HOLD;
      end else begin
        // Manual SS mode - just complete
        complete_all_transfers();
      end
    end

    update_irq();
  endfunction

  // ===========================================================================
  // Complete All Transfers
  // ===========================================================================
  function void complete_all_transfers();
    // Deassert SS_N (unless manual mode)
    if (!ctrl_manual_ss) begin
      expected_ss_n = 4'hF;
      expected_ss_ap.write(expected_ss_n);
    end

    // Return to idle
    spi_state = SPI_IDLE;
    expected_sclk = ctrl_cpol;
    status_busy = 0;

    // Set transfer complete
    intstat_tc = 1;

    update_irq();

    `uvm_info(get_type_name(), "All transfers complete", UVM_MEDIUM)
  endfunction

  // ===========================================================================
  // Process IFD (Inter-Frame Delay)
  // ===========================================================================
  function void process_ifd_tick();
    if (spi_state == SPI_IFD_WAIT) begin
      ifd_count++;
      if (ifd_count >= ctrl_ifd) begin
        // IFD complete, start next transfer
        int num_bits = get_num_bits();
        shift_reg_tx = tx_fifo.pop_front();
        if (ctrl_lsbf) begin
          shift_reg_tx = reverse_bits(shift_reg_tx, num_bits);
        end
        shift_reg_rx = 0;
        bit_count = 0;
        spi_state = SPI_TRANSFER;

        // Set initial MOSI based on CPHA
        if (!ctrl_cpha) begin
          int msb_pos = num_bits - 1;
          expected_mosi = shift_reg_tx[msb_pos];
        end
      end
    end
  endfunction

  // ===========================================================================
  // Predict Expected RX Data for Single Transfer
  // ===========================================================================
  // This is a simplified function for use when not doing cycle-accurate modeling
  function bit [31:0] do_spi_transfer(bit [31:0] tx_data, bit [31:0] miso_data);
    bit [31:0] rx_data;
    int num_bits = get_num_bits();

    // In loopback mode, rx = tx
    if (ctrl_loop) begin
      rx_data = tx_data;
    end else begin
      rx_data = miso_data;
    end

    // Mask to relevant bits
    rx_data = mask_data(rx_data);

    return rx_data;
  endfunction

  // ===========================================================================
  // Predict RX Data (for non-cycle-accurate mode)
  // ===========================================================================
  function void predict_rx_data(bit [31:0] miso_data);
    bit [31:0] expected_data;

    if (tx_fifo.size() > 0) begin
      bit [31:0] tx_data = tx_fifo.pop_front();
      expected_data = do_spi_transfer(tx_data, miso_data);

      // Push to RX FIFO
      if (rx_fifo.size() < FIFO_DEPTH) begin
        rx_fifo.push_back(expected_data);
        expected_rx_data_ap.write(expected_data);
        `uvm_info(get_type_name(), $sformatf("Predicted RX: 0x%08h", expected_data), UVM_MEDIUM)
      end else begin
        status_rxovr = 1;
        intstat_rxovr = 1;
        `uvm_warning(get_type_name(), "RX FIFO overrun!")
      end
    end
  endfunction

  // ===========================================================================
  // Helper Functions - FIFO Status
  // ===========================================================================

  function bit is_tx_empty();
    return (tx_fifo.size() == 0);
  endfunction

  function bit is_tx_not_full();
    return (tx_fifo.size() < FIFO_DEPTH);
  endfunction

  function bit is_tx_half_empty();
    return (tx_fifo.size() <= 4);
  endfunction

  function bit is_rx_not_empty();
    return (rx_fifo.size() > 0);
  endfunction

  function bit is_rx_full();
    return (rx_fifo.size() >= FIFO_DEPTH);
  endfunction

  function bit is_rx_half_full();
    return (rx_fifo.size() >= 4);
  endfunction

  function bit [3:0] get_tx_level();
    return tx_fifo.size();
  endfunction

  function bit [3:0] get_rx_level();
    return rx_fifo.size();
  endfunction

  // ===========================================================================
  // Interrupt Prediction
  // ===========================================================================
  function void update_irq();
    bit new_irq;

    new_irq = (intstat_tc       & inten[0]) |  // Transfer Complete
              (is_tx_empty()    & inten[1]) |  // TX FIFO Empty
              (is_tx_half_empty() & inten[2]) | // TX FIFO Half-Empty
              (is_rx_full()     & inten[3]) |  // RX FIFO Full
              (is_rx_half_full() & inten[4]) | // RX FIFO Half-Full
              (intstat_rxovr    & inten[5]);   // RX Overrun

    if (new_irq != expected_irq) begin
      expected_irq = new_irq;
      expected_irq_ap.write(expected_irq);
      `uvm_info(get_type_name(), $sformatf("IRQ changed to %0d", expected_irq), UVM_HIGH)
    end
  endfunction

  function bit predict_irq();
    return expected_irq;
  endfunction

  // ===========================================================================
  // Get Expected SS_N Output
  // ===========================================================================
  function bit [3:0] get_expected_ss_n();
    if (ctrl_manual_ss) begin
      return ssctl_ss_level ? 4'hF : ssctl_ss_sel;
    end else begin
      return expected_ss_n;
    end
  endfunction

  // ===========================================================================
  // Get Current State (for debug)
  // ===========================================================================
  function string get_state_name();
    case (spi_state)
      SPI_IDLE:     return "IDLE";
      SPI_SS_SETUP: return "SS_SETUP";
      SPI_TRANSFER: return "TRANSFER";
      SPI_IFD_WAIT: return "IFD_WAIT";
      SPI_SS_HOLD:  return "SS_HOLD";
      default:      return "UNKNOWN";
    endcase
  endfunction

  // ===========================================================================
  // Debug Print
  // ===========================================================================
  function void print_state();
    `uvm_info(get_type_name(), $sformatf(
      "\n=== Reference Model State ===\n" +
      "State: %s\n" +
      "CTRL: EN=%0d CPOL=%0d CPHA=%0d LSBF=%0d LOOP=%0d DSIZE=%0d MANUAL_SS=%0d IFD=%0d\n" +
      "STATUS: BUSY=%0d RXOVR=%0d\n" +
      "CLKDIV: %0d\n" +
      "SSCTL: SS_SEL=0x%01h SS_LEVEL=%0d\n" +
      "TX FIFO: %0d entries\n" +
      "RX FIFO: %0d entries\n" +
      "INTEN: 0x%02h\n" +
      "INTSTAT: TC=%0d RXOVR=%0d\n" +
      "IRQ: %0d\n" +
      "Expected SS_N: 0x%01h\n" +
      "Expected SCLK: %0d\n",
      get_state_name(),
      ctrl_en, ctrl_cpol, ctrl_cpha, ctrl_lsbf, ctrl_loop, ctrl_dsize, ctrl_manual_ss, ctrl_ifd,
      status_busy, status_rxovr,
      clkdiv,
      ssctl_ss_sel, ssctl_ss_level,
      tx_fifo.size(),
      rx_fifo.size(),
      inten,
      intstat_tc, intstat_rxovr,
      expected_irq,
      expected_ss_n,
      expected_sclk
    ), UVM_LOW)
  endfunction

endclass : spi_ref_model
