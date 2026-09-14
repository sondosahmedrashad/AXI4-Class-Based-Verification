class axi_coverage;

  mailbox #(axi_transaction) mon2cov;
  axi_transaction tr;

  bit       addr_valid_flag;
  bit       boundary_cross_flag;
  bit [1:0] resp_flag;
  bit       is_write_flag;
  bit [7:0] len_flag;
  bit [2:0] size_flag;

  covergroup cg;
    option.per_instance = 1;

    cp_op: coverpoint is_write_flag {
      bins wr = {1};
      bins rd = {0};
    }

    cp_addr_valid: coverpoint addr_valid_flag {
      bins valid   = {1};
      bins invalid = {0};
    }

    cp_boundary: coverpoint boundary_cross_flag {
      bins no_cross = {0};
      bins crossed  = {1};
    }

    cp_len: coverpoint len_flag {
      bins single      = {0};
      bins burst_small = {[1:3]};
      bins burst_mid   = {[4:15]};
      bins burst_large = {[16:255]};
    }

    cp_size: coverpoint size_flag {
      bins byte_xfer = {0};
      bins half_xfer = {1};
      bins word_xfer = {2};

      // Unsupported transfer sizes for this 32-bit datapath
      illegal_bins unsupported_size = {[3:7]};
    }

    cp_resp: coverpoint resp_flag {
      bins okay   = {2'b00};
      bins slverr = {2'b10};
    }

    cx_op_resp:       cross cp_op, cp_resp;
    cx_op_len:        cross cp_op, cp_len;
    cx_len_size:      cross cp_len, cp_size;

    // The reference model makes valid/invalid <-> OKAY/SLVERR a strict
    // 1:1 mapping (see axi_reference_model::is_valid()/predict_write()/
    // predict_read()), so valid+SLVERR and invalid+OKAY can never occur.
    // These are excluded as unreachable, not hidden by lowering the goal.
    cx_valid_resp: cross cp_addr_valid, cp_resp {
      ignore_bins valid_slverr =
          binsof(cp_addr_valid.valid) && binsof(cp_resp.slverr);
      ignore_bins invalid_okay =
          binsof(cp_addr_valid.invalid) && binsof(cp_resp.okay);
    }

    // A boundary-crossing transaction is always flagged invalid by
    // is_valid_addr(), so "crossed" can only ever pair with SLVERR.
    // crossed+OKAY is unreachable and is excluded.
    cx_boundary_resp: cross cp_boundary, cp_resp {
      ignore_bins crossed_okay =
          binsof(cp_boundary.crossed) && binsof(cp_resp.okay);
    }
  endgroup


  function new(mailbox #(axi_transaction) mon2cov);
    this.mon2cov = mon2cov;
    cg = new();
  endfunction


  function bit crosses_4kb(axi_transaction tr);

    int unsigned bytes_per_beat;
    int unsigned total_bytes;
    int unsigned last_addr;

    bytes_per_beat = (1 << tr.size);
    total_bytes    = (tr.len + 1) * bytes_per_beat;
    last_addr      = tr.addr + total_bytes - 1;

    return (tr.addr[15:12] != last_addr[15:12]);

  endfunction


  function bit is_valid_addr(axi_transaction tr);

    int unsigned bytes_per_beat;
    int unsigned total_bytes;
    int unsigned last_addr;

    bytes_per_beat = (1 << tr.size);
    total_bytes    = (tr.len + 1) * bytes_per_beat;
    last_addr      = tr.addr + total_bytes - 1;

    // Starting address must be inside the memory range
    if ((tr.addr >> 2) >= 1024)
      return 0;

    // Entire burst must stay inside the memory range
    if ((last_addr >> 2) >= 1024)
      return 0;

    // AXI burst must not cross a 4 KB boundary
    if (tr.addr[15:12] != last_addr[15:12])
      return 0;

    return 1;

  endfunction


  task run();

    forever begin

      mon2cov.get(tr);

      is_write_flag       = (tr.op == axi_transaction::WRITE);
      len_flag            = tr.len;
      size_flag           = tr.size;
      addr_valid_flag     = is_valid_addr(tr);
      boundary_cross_flag = crosses_4kb(tr);
      resp_flag           = tr.response;

      cg.sample();

    end

  endtask


  function void report();

    $display("=====================================================");
    $display(" FUNCTIONAL COVERAGE = %0.2f %%", cg.get_coverage());
    $display("=====================================================");

  endfunction

endclass