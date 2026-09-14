class axi_reference_model;

  localparam int DEPTH      = 1024;
  localparam int ADDR_WIDTH = 16;

  bit [31:0] mem_model [0:DEPTH-1];

  function new();
    reset_model();
  endfunction

  function void reset_model();
    for (int i = 0; i < DEPTH; i++) mem_model[i] = '0;
  endfunction

  function bit is_valid(bit [ADDR_WIDTH-1:0] addr, bit [7:0] len, bit [2:0] size);
    int unsigned total_bytes;
    bit          boundary_cross;
    bit          in_range;

    total_bytes    = (int'(len) + 1) * (1 << size);
    boundary_cross = ((addr & 16'hFFF) + total_bytes) > 16'h1000;
    in_range       = ((addr >> 2) < DEPTH);
    return (in_range && !boundary_cross);
  endfunction

  function void predict_write(axi_transaction tr, output bit [1:0] exp_response);
    bit [ADDR_WIDTH-1:0] addr;
    bit [ADDR_WIDTH-1:0] incr;
    bit                  valid;

    addr  = tr.addr;
    incr  = (1 << tr.size);
    valid = is_valid(tr.addr, tr.len, tr.size);

    if (valid) begin
      foreach (tr.data[i]) begin
        mem_model[addr >> 2] = tr.data[i];
        addr += incr;
      end
      exp_response = 2'b00;
    end else begin
      exp_response = 2'b10;
    end
  endfunction

  function void predict_read(axi_transaction tr,
                              output bit [31:0] exp_rdata[],
                              output bit [1:0]  exp_response);
    bit [ADDR_WIDTH-1:0] addr;
    bit [ADDR_WIDTH-1:0] incr;
    bit                  valid;

    addr  = tr.addr;
    incr  = (1 << tr.size);
    valid = is_valid(tr.addr, tr.len, tr.size);

    exp_rdata = new[tr.len + 1];

    if (valid) begin
      for (int i = 0; i <= tr.len; i++) begin
        exp_rdata[i] = mem_model[addr >> 2];
        addr += incr;
      end
      exp_response = 2'b00;
    end else begin
      for (int i = 0; i <= tr.len; i++) exp_rdata[i] = '0;
      exp_response = 2'b10;
    end
  endfunction

  function void expected_addr_sequence(axi_transaction tr, output bit [ADDR_WIDTH-1:0] addrs[]);
    bit [ADDR_WIDTH-1:0] addr;
    bit [ADDR_WIDTH-1:0] incr;

    addr = tr.addr;
    incr = (1 << tr.size);
    addrs = new[tr.len + 1];
    for (int i = 0; i <= tr.len; i++) begin
      addrs[i] = addr;
      addr += incr;
    end
  endfunction

endclass
