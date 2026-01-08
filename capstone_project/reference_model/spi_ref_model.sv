// =============================================================================
// SPI Master Controller - Reference Model
// =============================================================================
// This reference model implements the expected behavior of the SPI Master
// as defined in the specification. It is used by the scoreboard to predict
// expected outputs and compare against actual DUT behavior.
// =============================================================================
// TODO: Implement this reference model based on the specification
// =============================================================================

class spi_ref_model extends uvm_component;

  `uvm_component_utils(spi_ref_model)

  // ===========================================================================
  // Configuration
  // ===========================================================================
  // TODO: Add configuration object if needed

  // ===========================================================================
  // Internal State - Mirror of DUT Registers
  // ===========================================================================

  // Control Register (CTRL)
  bit        ctrl_en;        // SPI Enable
  bit        ctrl_cpol;      // Clock Polarity
  bit        ctrl_cpha;      // Clock Phase
  bit        ctrl_lsbf;      // LSB First
  bit        ctrl_loop;      // Loopback Mode
  bit [1:0]  ctrl_dsize;     // Data Size
  bit        ctrl_manual_ss; // Manual SS Control
  bit [7:0]  ctrl_ifd;       // Inter-Frame Delay

  // Status Register (STATUS) - Read-only reflections of state
  bit        status_busy;    // SPI Busy
  bit        status_rxovr;   // RX Overrun

  // Clock Divider Register
  bit [7:0]  clkdiv;

  // Slave Select Control
  bit [3:0]  ssctl_ss_sel;
  bit        ssctl_ss_level;

  // Interrupt Enable
  bit [5:0]  inten;

  // Interrupt Status
  bit        intstat_tc;     // Transfer Complete
  bit        intstat_rxovr;  // RX Overrun

  // ===========================================================================
  // FIFOs
  // ===========================================================================
  bit [31:0] tx_fifo[$];     // TX FIFO - max 8 entries
  bit [31:0] rx_fifo[$];     // RX FIFO - max 8 entries

  parameter int FIFO_DEPTH = 8;

  // ===========================================================================
  // Analysis Ports - For scoreboard connection
  // ===========================================================================
  uvm_analysis_port #(bit [31:0]) expected_rx_data_ap;
  uvm_analysis_port #(bit)        expected_irq_ap;

  // ===========================================================================
  // Constructor
  // ===========================================================================
  function new(string name = "spi_ref_model", uvm_component parent = null);
    super.new(name, parent);
    expected_rx_data_ap = new("expected_rx_data_ap", this);
    expected_irq_ap = new("expected_irq_ap", this);
  endfunction

  // ===========================================================================
  // Build Phase
  // ===========================================================================
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    reset();
  endfunction

  // ===========================================================================
  // Reset - Initialize all state to reset values
  // ===========================================================================
  function void reset();
    // TODO: Initialize all registers to their reset values per spec section 5
    ctrl_en        = 0;
    ctrl_cpol      = 0;
    ctrl_cpha      = 0;
    ctrl_lsbf      = 0;
    ctrl_loop      = 0;
    ctrl_dsize     = 2'b00;  // 8-bit
    ctrl_manual_ss = 0;
    ctrl_ifd       = 0;

    status_busy    = 0;
    status_rxovr   = 0;

    clkdiv         = 8'h02;  // Reset value per spec

    ssctl_ss_sel   = 4'hF;   // All deselected
    ssctl_ss_level = 1;

    inten          = 0;

    intstat_tc     = 0;
    intstat_rxovr  = 0;

    // Clear FIFOs
    tx_fifo.delete();
    rx_fifo.delete();

    `uvm_info(get_type_name(), "Reference model reset complete", UVM_MEDIUM)
  endfunction

  // ===========================================================================
  // Register Write - Process APB writes to registers
  // ===========================================================================
  function void register_write(bit [7:0] addr, bit [31:0] data);
    `uvm_info(get_type_name(), $sformatf("REG WRITE: addr=0x%02h data=0x%08h", addr, data), UVM_HIGH)

    case (addr)
      8'h00: begin // CTRL
        // TODO: Extract all fields from data and update internal state
        ctrl_en        = data[0];
        ctrl_cpol      = data[1];
        ctrl_cpha      = data[2];
        ctrl_lsbf      = data[3];
        ctrl_loop      = data[4];
        ctrl_dsize     = data[6:5];
        ctrl_manual_ss = data[7];
        ctrl_ifd       = data[15:8];
      end

      8'h04: begin // STATUS - W1C bits
        // TODO: Handle W1C (write-1-to-clear) for RXOVR
        if (data[5]) status_rxovr = 0;
      end

      8'h08: begin // CLKDIV
        // TODO: Handle clock divider constraints (even values >= 2)
        clkdiv = data[7:0];
        if (clkdiv < 2) clkdiv = 2;
        if (clkdiv[0]) clkdiv = clkdiv - 1; // Round down odd values
      end

      8'h0C: begin // SSCTL
        ssctl_ss_sel   = data[3:0];
        ssctl_ss_level = data[4];
      end

      8'h10: begin // TXDATA
        // TODO: Push to TX FIFO if not full
        if (tx_fifo.size() < FIFO_DEPTH) begin
          tx_fifo.push_back(mask_data(data));
          `uvm_info(get_type_name(), $sformatf("TX FIFO push: 0x%08h (depth=%0d)", data, tx_fifo.size()), UVM_HIGH)
        end else begin
          `uvm_info(get_type_name(), "TX FIFO full - write ignored", UVM_MEDIUM)
        end
      end

      8'h18: begin // INTEN
        inten = data[5:0];
      end

      8'h1C: begin // INTSTAT - W1C bits
        if (data[0]) intstat_tc = 0;
        if (data[5]) intstat_rxovr = 0;
      end

      default: begin
        `uvm_warning(get_type_name(), $sformatf("Write to unknown register address: 0x%02h", addr))
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

      8'h14: begin // RXDATA
        // TODO: Pop from RX FIFO if not empty
        if (rx_fifo.size() > 0) begin
          data = rx_fifo.pop_front();
          `uvm_info(get_type_name(), $sformatf("RX FIFO pop: 0x%08h (depth=%0d)", data, rx_fifo.size()), UVM_HIGH)
        end else begin
          data = 32'h0; // Return 0 if empty (or last value - check spec)
          `uvm_info(get_type_name(), "RX FIFO empty - returning 0", UVM_MEDIUM)
        end
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
  // SPI Transfer Model
  // ===========================================================================
  // TODO: Implement the SPI transfer logic
  // This should model:
  // - Shift register operation
  // - CPOL/CPHA timing
  // - Data size handling
  // - LSB/MSB first
  // - Loopback mode

  function bit [31:0] do_spi_transfer(bit [31:0] tx_data, bit [31:0] miso_data);
    bit [31:0] rx_data;
    int num_bits;

    // Determine number of bits based on DSIZE
    case (ctrl_dsize)
      2'b00: num_bits = 8;
      2'b01: num_bits = 16;
      2'b10: num_bits = 32;
      2'b11: num_bits = 4;
    endcase

    // TODO: Implement bit-by-bit transfer logic
    // For loopback mode, rx_data = tx_data
    if (ctrl_loop) begin
      rx_data = tx_data;
    end else begin
      rx_data = miso_data;
    end

    // Mask to relevant bits
    rx_data = rx_data & ((1 << num_bits) - 1);

    return rx_data;
  endfunction

  // ===========================================================================
  // Predict Expected RX Data
  // ===========================================================================
  // Call this when a transfer completes to predict what should be in RX FIFO
  function void predict_rx_data(bit [31:0] miso_data);
    bit [31:0] expected_data;

    if (tx_fifo.size() > 0) begin
      bit [31:0] tx_data = tx_fifo.pop_front();
      expected_data = do_spi_transfer(tx_data, miso_data);

      // Push to RX FIFO
      if (rx_fifo.size() < FIFO_DEPTH) begin
        rx_fifo.push_back(expected_data);
        expected_rx_data_ap.write(expected_data);
      end else begin
        // RX Overrun
        status_rxovr = 1;
        intstat_rxovr = 1;
        `uvm_info(get_type_name(), "RX FIFO overrun!", UVM_MEDIUM)
      end
    end
  endfunction

  // ===========================================================================
  // Helper Functions
  // ===========================================================================

  function bit [31:0] mask_data(bit [31:0] data);
    // Mask data based on current DSIZE setting
    case (ctrl_dsize)
      2'b00: return data & 32'h000000FF;  // 8-bit
      2'b01: return data & 32'h0000FFFF;  // 16-bit
      2'b10: return data;                  // 32-bit
      2'b11: return data & 32'h0000000F;  // 4-bit
    endcase
  endfunction

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
  function bit predict_irq();
    bit irq;
    irq = (intstat_tc     & inten[0]) |
          (is_tx_empty()  & inten[1]) |
          (is_tx_half_empty() & inten[2]) |
          (is_rx_full()   & inten[3]) |
          (is_rx_half_full()  & inten[4]) |
          (intstat_rxovr  & inten[5]);
    return irq;
  endfunction

endclass : spi_ref_model
