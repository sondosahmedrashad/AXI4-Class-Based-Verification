class axi_base_sequence;

    mailbox #(axi_transaction) gen2drv;

    function new(mailbox #(axi_transaction) gen2drv);
        this.gen2drv = gen2drv;
    endfunction

    task send(axi_transaction tr);
        gen2drv.put(tr.copy());
    endtask

endclass


//============================================================
// Single Write
//============================================================
class axi_single_write_sequence extends axi_base_sequence;

    function new(mailbox #(axi_transaction) gen2drv);
        super.new(gen2drv);
    endfunction

    task start(bit [15:0] addr = 16'h0020,
               bit [31:0] value = 32'hA5A5_1234);

        axi_transaction tr = new();

        tr.op   = axi_transaction::WRITE;
        tr.addr = addr;
        tr.len  = 0;
        tr.size = 2;

        tr.data = new[1];
        tr.data[0] = value;

        send(tr);

    endtask

endclass


//============================================================
// Single Read
//============================================================
class axi_single_read_sequence extends axi_base_sequence;

    function new(mailbox #(axi_transaction) gen2drv);
        super.new(gen2drv);
    endfunction

    task start(bit [15:0] addr = 16'h0020);

        axi_transaction tr = new();

        tr.op   = axi_transaction::READ;
        tr.addr = addr;
        tr.len  = 0;
        tr.size = 2;

        tr.data = new[1];
        tr.data[0] = '0;

        send(tr);

    endtask

endclass


//============================================================
// Burst Write
//============================================================
class axi_burst_write_sequence extends axi_base_sequence;

    function new(mailbox #(axi_transaction) gen2drv);
        super.new(gen2drv);
    endfunction

    task start(bit [15:0] addr = 16'h0100,
               int unsigned beat_count = 4);

        axi_transaction tr = new();

        if (beat_count < 1)
            beat_count = 1;

        if (beat_count > 256)
            beat_count = 256;

        tr.op   = axi_transaction::WRITE;
        tr.addr = addr;
        tr.len  = beat_count - 1;
        tr.size = 2;

        tr.data = new[beat_count];

        foreach (tr.data[i])
            tr.data[i] = 32'h1000_0000 + i;

        send(tr);

    endtask

endclass


//============================================================
// Burst Read
//============================================================
class axi_burst_read_sequence extends axi_base_sequence;

    function new(mailbox #(axi_transaction) gen2drv);
        super.new(gen2drv);
    endfunction

    task start(bit [15:0] addr = 16'h0100,
               int unsigned beat_count = 4);

        axi_transaction tr = new();

        if (beat_count < 1)
            beat_count = 1;

        if (beat_count > 256)
            beat_count = 256;

        tr.op   = axi_transaction::READ;
        tr.addr = addr;
        tr.len  = beat_count - 1;
        tr.size = 2;

        tr.data = new[beat_count];

        foreach (tr.data[i])
            tr.data[i] = '0;

        send(tr);

    endtask

endclass


//============================================================
// Invalid Address
//============================================================
class axi_invalid_address_sequence extends axi_base_sequence;

    function new(mailbox #(axi_transaction) gen2drv);
        super.new(gen2drv);
    endfunction

    task start_write();

        axi_transaction tr = new();

        tr.op   = axi_transaction::WRITE;
        tr.addr = 16'h2000;
        tr.len  = 0;
        tr.size = 2;

        tr.data = new[1];
        tr.data[0] = 32'hDEAD_BEEF;

        send(tr);

    endtask


    task start_read();

        axi_transaction tr = new();

        tr.op   = axi_transaction::READ;
        tr.addr = 16'h2000;
        tr.len  = 0;
        tr.size = 2;

        tr.data = new[1];
        tr.data[0] = '0;

        send(tr);

    endtask

endclass


//============================================================
// 4 KB Boundary Crossing
//============================================================
class axi_boundary_cross_sequence extends axi_base_sequence;

    function new(mailbox #(axi_transaction) gen2drv);
        super.new(gen2drv);
    endfunction


    //========================================================
    // Boundary-crossing WRITE
    //
    // Coverage target:
    //
    // write_addr_valid     = 1
    // write_boundary_error = 1
    //
    // Start address = 0x0FFF
    // LEN            = 0  -> one beat
    // SIZE           = 2  -> four bytes
    //
    // Transfer covers:
    //
    // 0x0FFF -> 0x1002
    //
    // Therefore the transfer crosses the 4 KB boundary.
    //
    // But write_addr itself is still 0x0FFF when BRESP is
    // generated, therefore:
    //
    // (0x0FFF >> 2) = 1023 < 1024
    //
    // so write_addr_valid remains 1.
    //
    // This deliberately targets the previously masked
    // write_boundary_error condition.
    //========================================================

    task start_write();

        axi_transaction tr = new();

        tr.op   = axi_transaction::WRITE;
        tr.addr = 16'h0FFF;
        tr.len  = 0;
        tr.size = 2;

        tr.data = new[1];
        tr.data[0] = 32'hCAFE_0001;

        send(tr);

    endtask


    //========================================================
    // Boundary-crossing READ
    //
    // Keep the existing read boundary test unchanged.
    //========================================================

    task start_read();

        axi_transaction tr = new();

        tr.op   = axi_transaction::READ;
        tr.addr = 16'h0FFC;
        tr.len  = 1;
        tr.size = 2;

        tr.data = new[2];

        foreach (tr.data[i])
            tr.data[i] = '0;

        send(tr);

    endtask

endclass


//============================================================
// Coverage Closure Sequence
//============================================================
class axi_coverage_closure_sequence extends axi_base_sequence;

    function new(mailbox #(axi_transaction) gen2drv);
        super.new(gen2drv);
    endfunction


    // ---------------------------------------------------------
    // Sends one directed, legal transaction with a given
    // op / len / size. Used to deliberately hit every
    // op x len x size combination, which guarantees every
    // legal bin of cx_op_len and cx_len_size gets sampled
    // (cx_op_resp's OKAY side comes along for free since every
    // one of these is a valid, non-boundary-crossing transfer).
    // ---------------------------------------------------------

    task send_combo(axi_transaction::op_t op,
                     bit [15:0]            addr,
                     bit [7:0]             len,
                     bit [2:0]             size,
                     bit [31:0]            data_seed);

        axi_transaction tr = new();
        int unsigned beats = len + 1;

        tr.op   = op;
        tr.addr = addr;
        tr.len  = len;
        tr.size = size;

        tr.data = new[beats];

        if (op == axi_transaction::WRITE)
            foreach (tr.data[i])
                tr.data[i] = data_seed + i;
        else
            foreach (tr.data[i])
                tr.data[i] = '0;

        send(tr);

    endtask


    task start();

        // len-category encodings:
        //
        // single      -> len = 0
        // burst_small -> len = 2
        // burst_mid   -> len = 4
        // burst_large -> len = 16

        $display(
            "[%0t] AXI_COVERAGE_CLOSURE: targeted tests started",
            $time
        );


        //======================================================
        // SINGLE - LEN = 0
        //======================================================

        send_combo(
            axi_transaction::READ,
            16'h0100,
            0,
            0,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0110,
            0,
            0,
            32'h1000_0000
        );

        send_combo(
            axi_transaction::READ,
            16'h0120,
            0,
            1,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0130,
            0,
            1,
            32'h1000_0010
        );

        send_combo(
            axi_transaction::READ,
            16'h0140,
            0,
            2,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0150,
            0,
            2,
            32'h1000_0020
        );


        //======================================================
        // SMALL - LEN = 2
        //======================================================

        send_combo(
            axi_transaction::READ,
            16'h0200,
            2,
            0,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0210,
            2,
            0,
            32'h2000_0000
        );

        send_combo(
            axi_transaction::READ,
            16'h0220,
            2,
            1,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0230,
            2,
            1,
            32'h2000_0010
        );

        send_combo(
            axi_transaction::READ,
            16'h0240,
            2,
            2,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0250,
            2,
            2,
            32'h2000_0020
        );


        //======================================================
        // MID - LEN = 4
        //======================================================

        send_combo(
            axi_transaction::READ,
            16'h0300,
            4,
            0,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0310,
            4,
            0,
            32'h3000_0000
        );

        send_combo(
            axi_transaction::READ,
            16'h0320,
            4,
            1,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0330,
            4,
            1,
            32'h3000_0010
        );

        send_combo(
            axi_transaction::READ,
            16'h0340,
            4,
            2,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0350,
            4,
            2,
            32'h3000_0020
        );


        //======================================================
        // LARGE - LEN = 16
        //======================================================

        send_combo(
            axi_transaction::READ,
            16'h0400,
            16,
            0,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0420,
            16,
            0,
            32'h4000_0000
        );

        send_combo(
            axi_transaction::READ,
            16'h0440,
            16,
            1,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0460,
            16,
            1,
            32'h4000_0010
        );

        send_combo(
            axi_transaction::READ,
            16'h0480,
            16,
            2,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h04A0,
            16,
            2,
            32'h4000_0020
        );


        $display(
            "[%0t] AXI_COVERAGE_CLOSURE: targeted tests generated",
            $time
        );

    endtask

endclass