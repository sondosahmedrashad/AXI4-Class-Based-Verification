class axi_generator;

    mailbox #(axi_transaction) gen2drv;

    int unsigned random_transactions = 500;


    function new(mailbox #(axi_transaction) gen2drv);

        this.gen2drv = gen2drv;

    endfunction


    task send_random_transaction();

        axi_transaction tr = new();

        if (!tr.randomize())
            $fatal(1,
                   "AXI generator: transaction randomization failed");

        gen2drv.put(tr.copy());

    endtask


    task run();

        axi_single_write_sequence       single_wr;
        axi_single_read_sequence        single_rd;
        axi_burst_write_sequence        burst_wr;
        axi_burst_read_sequence         burst_rd;
        axi_invalid_address_sequence    invalid_seq;
        axi_boundary_cross_sequence     boundary_seq;

        // New targeted coverage sequence
        axi_coverage_closure_sequence   coverage_seq;

        axi_transaction                 stop_tr;


        //======================================================
        // Create sequences
        //======================================================

        single_wr    = new(gen2drv);
        single_rd    = new(gen2drv);

        burst_wr     = new(gen2drv);
        burst_rd     = new(gen2drv);

        invalid_seq  = new(gen2drv);
        boundary_seq = new(gen2drv);

        coverage_seq = new(gen2drv);


        //======================================================
        // Directed Functional Tests
        //======================================================

        $display("[%0t] AXI_GENERATOR: directed tests started",
                 $time);


        // Basic write followed by read
        single_wr.start(
            16'h0020,
            32'hA5A5_1234
        );

        single_rd.start(
            16'h0020
        );


        // Four-beat burst write/read
        burst_wr.start(
            16'h0100,
            4
        );

        burst_rd.start(
            16'h0100,
            4
        );


        // Invalid address tests
        invalid_seq.start_write();
        invalid_seq.start_read();


        // 4 KB boundary-crossing tests
        boundary_seq.start_write();
        boundary_seq.start_read();


        //======================================================
        // Targeted Coverage Closure
        //======================================================

        coverage_seq.start();


        //======================================================
        // Constrained Random Tests
        //======================================================

        $display(
            "[%0t] AXI_GENERATOR: %0d constrained-random transactions started",
            $time,
            random_transactions
        );

        repeat (random_transactions)
            send_random_transaction();


        //======================================================
        // End-of-Test Sentinel
        //======================================================

        stop_tr = new();

        stop_tr.end_of_test = 1'b1;

        gen2drv.put(stop_tr);


        $display(
            "[%0t] AXI_GENERATOR: generation complete",
            $time
        );

    endtask

endclass