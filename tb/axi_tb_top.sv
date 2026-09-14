`timescale 1ns/1ps

import axi_package::*;

module axi_tb_top;

  reg ACLK;
  reg ARESETn;

  axi_test test_obj;


  //============================================================
  // Clock
  //============================================================

  initial begin
    ACLK = 1'b0;
  end

  always #5 ACLK = ~ACLK;


  //============================================================
  // AXI Interface
  //============================================================

  axi_interface intf (
    .ACLK    (ACLK),
    .ARESETn (ARESETn)
  );


  //============================================================
  // DUT
  //============================================================

  axi4 #(
    .DATA_WIDTH   (32),
    .ADDR_WIDTH   (16),
    .MEMORY_DEPTH (1024)
  ) DUT (
    .ACLK    (ACLK),
    .ARESETn (ARESETn),

    .AWADDR  (intf.AWADDR),
    .AWLEN   (intf.AWLEN),
    .AWSIZE  (intf.AWSIZE),
    .AWVALID (intf.AWVALID),
    .AWREADY (intf.AWREADY),

    .WDATA   (intf.WDATA),
    .WVALID  (intf.WVALID),
    .WLAST   (intf.WLAST),
    .WREADY  (intf.WREADY),

    .BRESP   (intf.BRESP),
    .BVALID  (intf.BVALID),
    .BREADY  (intf.BREADY),

    .ARADDR  (intf.ARADDR),
    .ARLEN   (intf.ARLEN),
    .ARSIZE  (intf.ARSIZE),
    .ARVALID (intf.ARVALID),
    .ARREADY (intf.ARREADY),

    .RDATA   (intf.RDATA),
    .RRESP   (intf.RRESP),
    .RVALID  (intf.RVALID),
    .RLAST   (intf.RLAST),
    .RREADY  (intf.RREADY)
  );


  //============================================================
  // Assertions
  //============================================================

  axi_assertions u_axi_assertions (
    .ACLK    (ACLK),
    .ARESETn (ARESETn),

    .AWADDR  (intf.AWADDR),
    .AWLEN   (intf.AWLEN),
    .AWSIZE  (intf.AWSIZE),

    .AWVALID (intf.AWVALID),
    .AWREADY (intf.AWREADY),

    .WDATA   (intf.WDATA),
    .WVALID  (intf.WVALID),
    .WREADY  (intf.WREADY),
    .WLAST   (intf.WLAST),

    .BVALID  (intf.BVALID),
    .BREADY  (intf.BREADY),

    .ARADDR  (intf.ARADDR),
    .ARLEN   (intf.ARLEN),
    .ARSIZE  (intf.ARSIZE),

    .ARVALID (intf.ARVALID),
    .ARREADY (intf.ARREADY),

    .RVALID  (intf.RVALID),
    .RREADY  (intf.RREADY),
    .RLAST   (intf.RLAST)
  );


  //============================================================
  // Clear master-driven signals
  //============================================================

  task clear_master_signals();

    intf.AWADDR  = '0;
    intf.AWLEN   = '0;
    intf.AWSIZE  = '0;
    intf.AWVALID = 1'b0;

    intf.WDATA   = '0;
    intf.WVALID  = 1'b0;
    intf.WLAST   = 1'b0;

    intf.BREADY  = 1'b0;

    intf.ARADDR  = '0;
    intf.ARLEN   = '0;
    intf.ARSIZE  = '0;
    intf.ARVALID = 1'b0;

    intf.RREADY  = 1'b0;

  endtask


  //============================================================
  // Clean reset
  //============================================================

  task clean_reset();

    @(negedge ACLK);

    clear_master_signals();

    ARESETn = 1'b0;

    repeat (3)
      @(posedge ACLK);

    @(negedge ACLK);

    clear_master_signals();

    ARESETn = 1'b1;

    repeat (2)
      @(posedge ACLK);

  endtask


  //============================================================
  // FSM COVERAGE TEST 1
  //
  // W_ADDR -> W_IDLE
  //============================================================

  task cover_waddr_to_widle();

    $display("=====================================================");
    $display(" FSM COVERAGE: W_ADDR -> W_IDLE");
    $display("=====================================================");

    @(negedge ACLK);

    intf.AWADDR  = 16'h0100;
    intf.AWLEN   = 8'd0;
    intf.AWSIZE  = 3'd2;
    intf.AWVALID = 1'b1;

    @(posedge ACLK);

    @(negedge ACLK);

    intf.AWVALID = 1'b0;

    ARESETn = 1'b0;

    repeat (2)
      @(posedge ACLK);

    @(negedge ACLK);

    clear_master_signals();

    ARESETn = 1'b1;

    @(posedge ACLK);

  endtask


  //============================================================
  // FSM COVERAGE TEST 2
  //
  // W_DATA -> W_IDLE
  //============================================================

  task cover_wdata_to_widle();

    $display("=====================================================");
    $display(" FSM COVERAGE: W_DATA -> W_IDLE");
    $display("=====================================================");

    @(negedge ACLK);

    intf.AWADDR  = 16'h0120;
    intf.AWLEN   = 8'd0;
    intf.AWSIZE  = 3'd2;
    intf.AWVALID = 1'b1;

    @(posedge ACLK);

    @(negedge ACLK);

    intf.AWVALID = 1'b0;

    @(posedge ACLK);

    @(negedge ACLK);

    ARESETn = 1'b0;

    repeat (2)
      @(posedge ACLK);

    @(negedge ACLK);

    clear_master_signals();

    ARESETn = 1'b1;

    @(posedge ACLK);

  endtask


  //============================================================
  // FSM COVERAGE TEST 3
  //
  // R_ADDR -> R_IDLE
  //============================================================

  task cover_raddr_to_ridle();

    $display("=====================================================");
    $display(" FSM COVERAGE: R_ADDR -> R_IDLE");
    $display("=====================================================");

    @(negedge ACLK);

    intf.ARADDR  = 16'h0200;
    intf.ARLEN   = 8'd0;
    intf.ARSIZE  = 3'd2;
    intf.ARVALID = 1'b1;

    @(posedge ACLK);

    @(negedge ACLK);

    intf.ARVALID = 1'b0;

    ARESETn = 1'b0;

    repeat (2)
      @(posedge ACLK);

    @(negedge ACLK);

    clear_master_signals();

    ARESETn = 1'b1;

    @(posedge ACLK);

  endtask


  //============================================================
  // FSM COVERAGE TEST 4
  //
  // R_WAIT -> R_IDLE
  //============================================================

  task cover_rwait_to_ridle();

    $display("=====================================================");
    $display(" FSM COVERAGE: R_WAIT -> R_IDLE");
    $display("=====================================================");

    @(negedge ACLK);

    intf.ARADDR  = 16'h0220;
    intf.ARLEN   = 8'd0;
    intf.ARSIZE  = 3'd2;
    intf.ARVALID = 1'b1;

    @(posedge ACLK);

    @(negedge ACLK);

    intf.ARVALID = 1'b0;

    @(posedge ACLK);

    @(negedge ACLK);

    ARESETn = 1'b0;

    repeat (2)
      @(posedge ACLK);

    @(negedge ACLK);

    clear_master_signals();

    ARESETn = 1'b1;

    @(posedge ACLK);

  endtask


  //============================================================
  // CONDITION COVERAGE TEST
  //
  // Target:
  // WLAST || (write_burst_cnt == 0)
  //
  // Required:
  // WLAST = 0
  // write_burst_cnt == 0
  //
  // Invalid address is used so memory is not modified.
  //============================================================

  task cover_write_counter_without_wlast();

    $display("=====================================================");
    $display(" CONDITION COVERAGE:");
    $display(" WLAST=0 AND write_burst_cnt=0");
    $display("=====================================================");

    @(negedge ACLK);

    intf.AWADDR  = 16'h2000;
    intf.AWLEN   = 8'd0;
    intf.AWSIZE  = 3'd2;
    intf.AWVALID = 1'b1;


    do begin
      @(posedge ACLK);
    end
    while (!(intf.AWVALID && intf.AWREADY));


    @(negedge ACLK);

    intf.AWVALID = 1'b0;


    // W_ADDR -> W_DATA
    @(posedge ACLK);

    @(negedge ACLK);


    intf.WDATA  = 32'h55AA_AA55;
    intf.WVALID = 1'b1;
    intf.WLAST  = 1'b0;


    do begin
      @(posedge ACLK);
    end
    while (!(intf.WVALID && intf.WREADY));


    @(negedge ACLK);

    intf.WVALID = 1'b0;
    intf.WLAST  = 1'b0;


    intf.BREADY = 1'b1;


    do begin
      @(posedge ACLK);
    end
    while (!(intf.BVALID && intf.BREADY));


    @(negedge ACLK);

    intf.BREADY = 1'b0;


    $display("=====================================================");
    $display(" CONDITION COVERAGE TEST COMPLETE");
    $display("=====================================================");

  endtask


  //============================================================
  // TOGGLE COVERAGE HELPER
  //
  // Single legal AXI write.
  // These transactions are executed before the class-based
  // environment exists, so they do not affect the 52 normal
  // scoreboard transactions.
  //============================================================

  task toggle_single_write(
    input [15:0] address,
    input [31:0] data
  );

    //----------------------------------------------------------
    // AW channel
    //----------------------------------------------------------

    @(negedge ACLK);

    intf.AWADDR  = address;
    intf.AWLEN   = 8'd0;
    intf.AWSIZE  = 3'd2;
    intf.AWVALID = 1'b1;


    do begin
      @(posedge ACLK);
    end
    while (!(intf.AWVALID && intf.AWREADY));


    @(negedge ACLK);

    intf.AWVALID = 1'b0;


    //----------------------------------------------------------
    // Allow W_ADDR -> W_DATA
    //----------------------------------------------------------

    @(posedge ACLK);

    @(negedge ACLK);


    //----------------------------------------------------------
    // W channel
    //----------------------------------------------------------

    intf.WDATA  = data;
    intf.WVALID = 1'b1;
    intf.WLAST  = 1'b1;


    do begin
      @(posedge ACLK);
    end
    while (!(intf.WVALID && intf.WREADY));


    @(negedge ACLK);

    intf.WVALID = 1'b0;
    intf.WLAST  = 1'b0;


    //----------------------------------------------------------
    // B channel
    //----------------------------------------------------------

    intf.BREADY = 1'b1;


    do begin
      @(posedge ACLK);
    end
    while (!(intf.BVALID && intf.BREADY));


    @(negedge ACLK);

    intf.BREADY = 1'b0;

  endtask


  //============================================================
  // TOGGLE COVERAGE HELPER
  //
  // Single legal AXI read.
  //============================================================

  task toggle_single_read(
    input [15:0] address
  );

    //----------------------------------------------------------
    // AR channel
    //----------------------------------------------------------

    @(negedge ACLK);

    intf.ARADDR  = address;
    intf.ARLEN   = 8'd0;
    intf.ARSIZE  = 3'd2;
    intf.ARVALID = 1'b1;


    do begin
      @(posedge ACLK);
    end
    while (!(intf.ARVALID && intf.ARREADY));


    @(negedge ACLK);

    intf.ARVALID = 1'b0;


    //----------------------------------------------------------
    // R channel
    //----------------------------------------------------------

    intf.RREADY = 1'b1;


    do begin
      @(posedge ACLK);
    end
    while (!(intf.RVALID && intf.RREADY));


    $display(
      "[TOGGLE READ] addr=0x%04h data=0x%08h",
      address,
      intf.RDATA
    );


    @(negedge ACLK);

    intf.RREADY = 1'b0;

  endtask


  //============================================================
  // TOGGLE COVERAGE TEST 1
  //
  // DATA TOGGLE
  //
  // Target:
  // RDATA
  // mem_rdata
  // WDATA
  //
  // Patterns force every data bit through both directions:
  //
  // 0 -> 1
  // 1 -> 0
  //
  // Additional alternating patterns create extra transitions.
  //============================================================

  task cover_data_toggles();

    $display("=====================================================");
    $display(" TOGGLE COVERAGE: DATA PATTERNS");
    $display("=====================================================");


    //----------------------------------------------------------
    // All bits go high
    //----------------------------------------------------------

    toggle_single_write(
      16'h0700,
      32'hFFFF_FFFF
    );

    toggle_single_read(
      16'h0700
    );


    //----------------------------------------------------------
    // All bits go low
    //----------------------------------------------------------

    toggle_single_write(
      16'h0700,
      32'h0000_0000
    );

    toggle_single_read(
      16'h0700
    );


    //----------------------------------------------------------
    // Alternating pattern 1
    //----------------------------------------------------------

    toggle_single_write(
      16'h0700,
      32'hAAAA_AAAA
    );

    toggle_single_read(
      16'h0700
    );


    //----------------------------------------------------------
    // Alternating pattern 2
    //----------------------------------------------------------

    toggle_single_write(
      16'h0700,
      32'h5555_5555
    );

    toggle_single_read(
      16'h0700
    );


    $display("=====================================================");
    $display(" DATA TOGGLE COVERAGE TEST COMPLETE");
    $display("=====================================================");

  endtask


  //============================================================
  // TOGGLE COVERAGE TEST 2
  //
  // ADDRESS / LEN TOGGLE
  //
  // Missing reachable bits included:
  //
  // AWADDR[15]
  // ARADDR[12]
  // ARADDR[14]
  //
  // AWLEN[3]
  // AWLEN[5]
  // AWLEN[6]
  // AWLEN[7]
  //
  // ARLEN[3]
  // ARLEN[5]
  // ARLEN[6]
  // ARLEN[7]
  //
  // 8'hE8 = 1110_1000
  //
  // We only perform the address handshake and then reset.
  // This lets the DUT capture the address/LEN values without
  // having to complete a huge burst.
  //============================================================

  task cover_address_len_toggles();

    $display("=====================================================");
    $display(" TOGGLE COVERAGE: ADDRESS AND LEN BITS");
    $display("=====================================================");


    //----------------------------------------------------------
    // WRITE CONTROL TOGGLE
    //
    // 0x8000 toggles AWADDR[15].
    //
    // E8 toggles:
    // AWLEN[7]
    // AWLEN[6]
    // AWLEN[5]
    // AWLEN[3]
    //
    // Internal write_addr, write_burst_len and
    // write_burst_cnt are also loaded.
    //----------------------------------------------------------

    @(negedge ACLK);

    intf.AWADDR  = 16'h8000;
    intf.AWLEN   = 8'hE8;
    intf.AWSIZE  = 3'd2;
    intf.AWVALID = 1'b1;


    do begin
      @(posedge ACLK);
    end
    while (!(intf.AWVALID && intf.AWREADY));


    @(negedge ACLK);

    intf.AWVALID = 1'b0;


    //----------------------------------------------------------
    // Reset immediately after capture.
    //
    // This returns the captured internal values to zero,
    // producing the opposite toggle direction too.
    //----------------------------------------------------------

    ARESETn = 1'b0;

    clear_master_signals();

    repeat (3)
      @(posedge ACLK);

    @(negedge ACLK);

    ARESETn = 1'b1;

    repeat (2)
      @(posedge ACLK);


    //----------------------------------------------------------
    // READ CONTROL TOGGLE
    //
    // 0x5000 =
    //
    // bit 14 = 1
    // bit 12 = 1
    //
    // E8 toggles ARLEN[7:5] and ARLEN[3].
    //----------------------------------------------------------

    @(negedge ACLK);

    intf.ARADDR  = 16'h5000;
    intf.ARLEN   = 8'hE8;
    intf.ARSIZE  = 3'd2;
    intf.ARVALID = 1'b1;


    do begin
      @(posedge ACLK);
    end
    while (!(intf.ARVALID && intf.ARREADY));


    @(negedge ACLK);

    intf.ARVALID = 1'b0;


    //----------------------------------------------------------
    // Reset after AR capture.
    //----------------------------------------------------------

    ARESETn = 1'b0;

    clear_master_signals();

    repeat (3)
      @(posedge ACLK);

    @(negedge ACLK);

    ARESETn = 1'b1;

    repeat (2)
      @(posedge ACLK);


    $display("=====================================================");
    $display(" ADDRESS/LEN TOGGLE COVERAGE TEST COMPLETE");
    $display("=====================================================");

  endtask


  //============================================================
  // MAIN TEST
  //============================================================

  initial begin

    //----------------------------------------------------------
    // Initial reset
    //----------------------------------------------------------

    ARESETn = 1'b0;

    clear_master_signals();

    repeat (5)
      @(posedge ACLK);

    @(negedge ACLK);

    ARESETn = 1'b1;

    @(posedge ACLK);


    //----------------------------------------------------------
    // FSM transition coverage tests
    //----------------------------------------------------------

    cover_waddr_to_widle();

    cover_wdata_to_widle();

    cover_raddr_to_ridle();

    cover_rwait_to_ridle();


    //----------------------------------------------------------
    // Condition coverage-only test
    //----------------------------------------------------------

    cover_write_counter_without_wlast();


    //----------------------------------------------------------
    // Toggle coverage tests
    //----------------------------------------------------------

    cover_address_len_toggles();

    cover_data_toggles();


    //----------------------------------------------------------
    // Final clean reset
    //
    // Important:
    // erase all memory/state changes created by coverage-only
    // pre-tests before starting the real 52 transactions.
    //----------------------------------------------------------

    $display("=====================================================");
    $display(" COVERAGE PRE-TESTS COMPLETE");
    $display(" Performing final clean reset");
    $display("=====================================================");

    clean_reset();


    //----------------------------------------------------------
    // Start normal class-based verification
    //----------------------------------------------------------

    $display("=====================================================");
    $display(" STARTING NORMAL 52-TRANSACTION AXI TEST");
    $display("=====================================================");

    test_obj = new(intf);

    test_obj.run();


    //----------------------------------------------------------
    // End simulation
    //----------------------------------------------------------

    $display("=====================================================");
    $display(" SIMULATION COMPLETE");
    $display("=====================================================");

    $finish;

  end


  //============================================================
  // Waveform dump
  //============================================================

  initial begin

    $dumpfile("axi_tb.vcd");

    $dumpvars(
      0,
      axi_tb_top
    );

  end


endmodule
