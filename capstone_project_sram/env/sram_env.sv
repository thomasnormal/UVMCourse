// =============================================================================
// SRAM Environment (PROVIDED - complete implementation)
// =============================================================================

class sram_env extends uvm_env;

  `uvm_component_utils(sram_env)

  // ===========================================================================
  // Components
  // ===========================================================================
  apb_agent      apb_agt;
  sram_agent     sram_agt;
  sram_ref_model ref_model;
  sram_scoreboard scoreboard;
  sram_coverage  coverage;

  // ===========================================================================
  // Constructor
  // ===========================================================================
  function new(string name = "sram_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // ===========================================================================
  // Build Phase
  // ===========================================================================
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create APB agent (active - drives transactions)
    apb_agt = apb_agent::type_id::create("apb_agt", this);
    apb_agt.set_is_active();

    // Create SRAM agent (active - acts as slave BFM)
    sram_agt = sram_agent::type_id::create("sram_agt", this);
    sram_agt.set_is_active();

    // Create reference model
    ref_model = sram_ref_model::type_id::create("ref_model", this);

    // Create scoreboard
    scoreboard = sram_scoreboard::type_id::create("scoreboard", this);

    // Create coverage collector
    coverage = sram_coverage::type_id::create("coverage", this);
  endfunction

  // ===========================================================================
  // Connect Phase
  // ===========================================================================
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect reference model to scoreboard
    scoreboard.ref_model = ref_model;

    // Connect APB monitor to scoreboard and coverage
    apb_agt.mon.ap.connect(scoreboard.apb_export);
    apb_agt.mon.ap.connect(coverage.analysis_export);
  endfunction

endclass : sram_env
