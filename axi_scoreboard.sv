class axi_scoreboard;

  mailbox #(axi_transaction) mon2scb;
  axi_reference_model        ref_model;

  int pass_count;
  int fail_count;

  function new(mailbox #(axi_transaction) mon2scb, axi_reference_model ref_model);
    this.mon2scb   = mon2scb;
    this.ref_model = ref_model;
    pass_count = 0;
    fail_count = 0;
  endfunction

  task run();
    axi_transaction tr;
    forever begin
      mon2scb.get(tr);
      check_transaction(tr);
    end
  endtask

  task check_transaction(axi_transaction tr);
    bit ok = 1'b1;

    if (!tr.saw_last) begin
      $error("[SCB] addr=%0h op=%s: LAST was never observed on this burst",
             tr.addr, tr.op.name());
      ok = 1'b0;
    end

    if (tr.op == axi_transaction::WRITE) begin
      bit [1:0] exp_response;

      if (tr.data.size() != tr.len + 1) begin
        $error("[SCB][WRITE] addr=%0h burst length mismatch: got %0d beats, expected %0d",
               tr.addr, tr.data.size(), tr.len + 1);
        ok = 1'b0;
      end else if (!tr.saw_last) begin
        $error("[SCB][WRITE] addr=%0h WLAST not asserted on final beat (beat %0d)",
               tr.addr, tr.data.size() - 1);
        ok = 1'b0;
      end

      ref_model.predict_write(tr, exp_response);
      if (tr.response !== exp_response) begin
        $error("[SCB][WRITE] addr=%0h BRESP mismatch: expected=%0b got=%0b",
               tr.addr, exp_response, tr.response);
        ok = 1'b0;
      end

    end else begin
      bit [31:0]  exp_rdata[];
      bit [1:0]   exp_response;
      bit [15:0]  exp_addrs[];

      ref_model.predict_read(tr, exp_rdata, exp_response);
      ref_model.expected_addr_sequence(tr, exp_addrs);

      if (tr.read_data.size() != tr.len + 1) begin
        $error("[SCB][READ] addr=%0h burst length mismatch: got %0d beats, expected %0d",
               tr.addr, tr.read_data.size(), tr.len + 1);
        ok = 1'b0;
      end else begin
        if (!tr.saw_last) begin
          $error("[SCB][READ] addr=%0h RLAST not asserted on final beat (beat %0d)",
                 tr.addr, tr.read_data.size() - 1);
          ok = 1'b0;
        end
        for (int i = 0; i < tr.read_data.size(); i++) begin
          if (tr.read_data[i] !== exp_rdata[i]) begin
            $error("[SCB][READ] addr=%0h(base) beat=%0d expected_addr=%0h DATA mismatch: expected=%0h got=%0h",
                   tr.addr, i, exp_addrs[i], exp_rdata[i], tr.read_data[i]);
            ok = 1'b0;
          end
        end
      end

      if (tr.response !== exp_response) begin
        $error("[SCB][READ] addr=%0h RRESP mismatch: expected=%0b got=%0b",
               tr.addr, exp_response, tr.response);
        ok = 1'b0;
      end
    end

    if (ok) pass_count++;
    else    fail_count++;
  endtask

  function void report();
    $display("=====================================================");
    $display(" AXI SCOREBOARD FINAL REPORT");
    $display("   PASS  = %0d", pass_count);
    $display("   FAIL  = %0d", fail_count);
    $display("   TOTAL = %0d", pass_count + fail_count);
    $display("=====================================================");
  endfunction

endclass
