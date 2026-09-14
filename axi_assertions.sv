module axi_assertions (
    input wire ACLK,
    input wire ARESETn,

    input wire [15:0] AWADDR,
    input wire [7:0]  AWLEN,
    input wire [2:0]  AWSIZE,
    input wire        AWVALID, AWREADY,

    input wire [31:0] WDATA,
    input wire        WVALID, WREADY, WLAST,
    input wire        BVALID, BREADY,

    input wire [15:0] ARADDR,
    input wire [7:0]  ARLEN,
    input wire [2:0]  ARSIZE,
    input wire        ARVALID, ARREADY,

    input wire         RVALID, RREADY, RLAST
);

  property p_valid_stable(valid, ready);
    @(posedge ACLK) disable iff (!ARESETn)
      (valid && !ready) |=> valid;
  endproperty

  assert_awvalid_stable: assert property (p_valid_stable(AWVALID, AWREADY))
    else $error("[ASSERT] AWVALID deasserted before AWREADY");

  assert_wvalid_stable: assert property (p_valid_stable(WVALID, WREADY))
    else $error("[ASSERT] WVALID deasserted before WREADY");

  assert_arvalid_stable: assert property (p_valid_stable(ARVALID, ARREADY))
    else $error("[ASSERT] ARVALID deasserted before ARREADY");

  assert_bvalid_stable: assert property (p_valid_stable(BVALID, BREADY))
    else $error("[ASSERT] BVALID deasserted before BREADY");

  assert_rvalid_stable: assert property (p_valid_stable(RVALID, RREADY))
    else $error("[ASSERT] RVALID deasserted before RREADY");

  property p_stable(valid, ready, sig);
    @(posedge ACLK) disable iff (!ARESETn)
      (valid && !ready) |=> $stable(sig);
  endproperty

  assert_awaddr_stable: assert property (p_stable(AWVALID, AWREADY, AWADDR))
    else $error("[ASSERT] AWADDR changed while AWVALID && !AWREADY");
  assert_awlen_stable: assert property (p_stable(AWVALID, AWREADY, AWLEN))
    else $error("[ASSERT] AWLEN changed while AWVALID && !AWREADY");
  assert_awsize_stable: assert property (p_stable(AWVALID, AWREADY, AWSIZE))
    else $error("[ASSERT] AWSIZE changed while AWVALID && !AWREADY");

  assert_wdata_stable: assert property (p_stable(WVALID, WREADY, WDATA))
    else $error("[ASSERT] WDATA changed while WVALID && !WREADY");
  assert_wlast_stable: assert property (p_stable(WVALID, WREADY, WLAST))
    else $error("[ASSERT] WLAST changed while WVALID && !WREADY");

  assert_araddr_stable: assert property (p_stable(ARVALID, ARREADY, ARADDR))
    else $error("[ASSERT] ARADDR changed while ARVALID && !ARREADY");
  assert_arlen_stable: assert property (p_stable(ARVALID, ARREADY, ARLEN))
    else $error("[ASSERT] ARLEN changed while ARVALID && !ARREADY");
  assert_arsize_stable: assert property (p_stable(ARVALID, ARREADY, ARSIZE))
    else $error("[ASSERT] ARSIZE changed while ARVALID && !ARREADY");

  property p_wlast_needs_wvalid;
    @(posedge ACLK) disable iff (!ARESETn)
      WLAST |-> WVALID;
  endproperty
  assert_wlast_needs_wvalid: assert property (p_wlast_needs_wvalid)
    else $error("[ASSERT] WLAST asserted while WVALID is low");

  property p_rlast_needs_rvalid;
    @(posedge ACLK) disable iff (!ARESETn)
      RLAST |-> RVALID;
  endproperty
  assert_rlast_needs_rvalid: assert property (p_rlast_needs_rvalid)
    else $error("[ASSERT] RLAST asserted while RVALID is low");

  property p_reset_clears_valids;
    @(posedge ACLK)
      !ARESETn |-> (!BVALID && !RVALID);
  endproperty
  assert_reset_clears_valids: assert property (p_reset_clears_valids)
    else $error("[ASSERT] BVALID/RVALID asserted during reset");

endmodule
