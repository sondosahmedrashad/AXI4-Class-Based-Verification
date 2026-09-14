class axi_driver;

    virtual axi_interface.MASTER vif;
    mailbox #(axi_transaction) gen2drv;

    event done;
    int unsigned driven_transactions = 0;

    // One-time legal backpressure tests
    bit did_aw_backpressure;
    bit did_ar_backpressure;
    bit did_b_backpressure;
    bit did_r_backpressure;

    // One pending transaction
    axi_transaction pending_tr;

    bit has_pending_tr;
    bit pending_aw_done;
    bit pending_ar_done;


    function new(
        virtual axi_interface.MASTER vif,
        mailbox #(axi_transaction) gen2drv
    );

        this.vif     = vif;
        this.gen2drv = gen2drv;

        did_aw_backpressure = 1'b0;
        did_ar_backpressure = 1'b0;
        did_b_backpressure  = 1'b0;
        did_r_backpressure  = 1'b0;

        has_pending_tr  = 1'b0;
        pending_aw_done = 1'b0;
        pending_ar_done = 1'b0;

    endfunction


    //==========================================================
    // Reset master-driven signals
    //==========================================================

    task reset_master_signals();

        vif.AWADDR  <= '0;
        vif.AWLEN   <= '0;
        vif.AWSIZE  <= '0;
        vif.AWVALID <= 1'b0;

        vif.WDATA   <= '0;
        vif.WVALID  <= 1'b0;
        vif.WLAST   <= 1'b0;

        vif.BREADY  <= 1'b0;

        vif.ARADDR  <= '0;
        vif.ARLEN   <= '0;
        vif.ARSIZE  <= '0;
        vif.ARVALID <= 1'b0;

        vif.RREADY  <= 1'b0;

    endtask


    //==========================================================
    // Wait for reset release
    //==========================================================

    task wait_for_reset_release();

        reset_master_signals();

        wait (vif.ARESETn === 1'b1);

        @(negedge vif.ACLK);

    endtask


    //==========================================================
    // Prefetch next WRITE address
    //
    // Used to create:
    //
    // AWVALID = 1
    // AWREADY = 0
    //
    // while DUT is busy with current write.
    //==========================================================

    task prefetch_next_aw(output bit aw_started);

        axi_transaction next_tr;

        aw_started = 1'b0;


        if (did_aw_backpressure)
            return;


        gen2drv.get(next_tr);


        pending_tr      = next_tr;
        has_pending_tr  = 1'b1;

        pending_aw_done = 1'b0;
        pending_ar_done = 1'b0;


        if (!next_tr.end_of_test &&
            next_tr.op == axi_transaction::WRITE) begin

            @(negedge vif.ACLK);

            vif.AWADDR  <= next_tr.addr;
            vif.AWLEN   <= next_tr.len;
            vif.AWSIZE  <= next_tr.size;
            vif.AWVALID <= 1'b1;

            aw_started = 1'b1;


            $display(
                "[%0t] AXI_DRIVER: AW-channel stability/backpressure coverage started",
                $time
            );

        end

    endtask


    //==========================================================
    // Prefetch next READ address
    //
    // IMPORTANT:
    //
    // This task must be called while current read transaction
    // is STILL active.
    //
    // At that time DUT ARREADY = 0.
    //
    // Therefore:
    //
    // ARVALID = 1
    // ARREADY = 0
    //
    // is generated legally.
    //==========================================================

    task prefetch_next_ar(output bit ar_started);

        axi_transaction next_tr;

        ar_started = 1'b0;


        if (did_ar_backpressure)
            return;


        gen2drv.get(next_tr);


        pending_tr      = next_tr;
        has_pending_tr  = 1'b1;

        pending_aw_done = 1'b0;
        pending_ar_done = 1'b0;


        // Only create AR overlap if next transaction is READ
        if (!next_tr.end_of_test &&
            next_tr.op == axi_transaction::READ) begin

            @(negedge vif.ACLK);


            vif.ARADDR  <= next_tr.addr;
            vif.ARLEN   <= next_tr.len;
            vif.ARSIZE  <= next_tr.size;
            vif.ARVALID <= 1'b1;


            ar_started = 1'b1;


            $display(
                "[%0t] AXI_DRIVER: AR-channel stability/backpressure coverage STARTED",
                $time
            );


            $display(
                "[%0t] AXI_DRIVER: ARVALID=%0b ARREADY=%0b",
                $time,
                vif.ARVALID,
                vif.ARREADY
            );

        end

    endtask


    //==========================================================
    // WRITE TRANSACTION
    //==========================================================

    task drive_write(
        axi_transaction tr,
        bit aw_already_done
    );

        int unsigned beat_count;
        bit aw_prefetched;


        aw_prefetched = 1'b0;


        //======================================================
        // AW Channel
        //======================================================

        if (!aw_already_done) begin

            @(negedge vif.ACLK);


            vif.AWADDR  <= tr.addr;
            vif.AWLEN   <= tr.len;
            vif.AWSIZE  <= tr.size;
            vif.AWVALID <= 1'b1;


            do begin

                @(posedge vif.ACLK);

            end
            while (!(vif.AWVALID && vif.AWREADY));


            @(negedge vif.ACLK);

            vif.AWVALID <= 1'b0;

        end

        else begin

            $display(
                "[%0t] AXI_DRIVER: using prefetched AW handshake",
                $time
            );

        end


        //======================================================
        // W Channel
        //======================================================

        beat_count = tr.beats();


        for (int i = 0; i < beat_count; i++) begin


            if (i != 0)
                @(negedge vif.ACLK);


            vif.WDATA  <= tr.data[i];
            vif.WLAST  <= (i == beat_count - 1);
            vif.WVALID <= 1'b1;


            if (i == 0) begin

                $display(
                    "[%0t] AXI_DRIVER: W-channel stability/backpressure coverage",
                    $time
                );

            end


            // Hold data stable until handshake
            do begin

                @(posedge vif.ACLK);

            end
            while (!(vif.WVALID && vif.WREADY));


            @(negedge vif.ACLK);


            vif.WVALID <= 1'b0;
            vif.WLAST  <= 1'b0;

        end


        //======================================================
        // AW coverage prefetch
        //======================================================

        if (!did_aw_backpressure &&
            !has_pending_tr) begin

            prefetch_next_aw(aw_prefetched);

        end


        //======================================================
        // B Channel
        //======================================================

        if (!did_b_backpressure) begin

            vif.BREADY <= 1'b0;


            wait (vif.BVALID === 1'b1);


            $display(
                "[%0t] AXI_DRIVER: legal B-channel backpressure test",
                $time
            );


            repeat (2)
                @(posedge vif.ACLK);


            @(negedge vif.ACLK);


            vif.BREADY <= 1'b1;

            did_b_backpressure = 1'b1;

        end

        else begin

            @(negedge vif.ACLK);

            vif.BREADY <= 1'b1;

        end


        do begin

            @(posedge vif.ACLK);

        end
        while (!(vif.BVALID && vif.BREADY));


        tr.response = vif.BRESP;


        @(negedge vif.ACLK);

        vif.BREADY <= 1'b0;


        //======================================================
        // Complete prefetched AW
        //======================================================

        if (aw_prefetched) begin


            // Hold AWVALID/address/control stable
            // until DUT accepts the prefetched address.

            do begin

                @(posedge vif.ACLK);

            end
            while (!(vif.AWVALID && vif.AWREADY));


            @(negedge vif.ACLK);


            vif.AWVALID <= 1'b0;


            pending_aw_done = 1'b1;

            did_aw_backpressure = 1'b1;


            $display(
                "[%0t] AXI_DRIVER: AW-channel backpressure coverage COMPLETED",
                $time
            );

        end


        tr.display("AXI_DRIVER_WRITE_DONE");

    endtask


    //==========================================================
    // READ TRANSACTION
    //==========================================================

    task drive_read(
        axi_transaction tr,
        bit ar_already_done
    );

        int unsigned beat_index;
        int unsigned expected_beats;

        bit ar_prefetched;


        ar_prefetched = 1'b0;


        //======================================================
        // AR Channel
        //======================================================

        if (!ar_already_done) begin

            @(negedge vif.ACLK);


            vif.ARADDR  <= tr.addr;
            vif.ARLEN   <= tr.len;
            vif.ARSIZE  <= tr.size;
            vif.ARVALID <= 1'b1;

            vif.RREADY  <= 1'b0;


            // Wait for normal AR handshake
            do begin

                @(posedge vif.ACLK);

            end
            while (!(vif.ARVALID && vif.ARREADY));


            // At this point DUT accepted current read.
            //
            // DUT changes:
            //
            // ARREADY <= 0
            // read_state <= R_ADDR


            @(negedge vif.ACLK);


            // Drop current transaction's ARVALID
            vif.ARVALID <= 1'b0;


            //==================================================
            // IMPORTANT AR COVERAGE PART
            //
            // Try to launch NEXT read address NOW,
            // while current read is still active.
            //
            // Current DUT state is R_ADDR/R_WAIT,
            // therefore ARREADY must be 0.
            //==================================================

            if (!did_ar_backpressure &&
                !has_pending_tr) begin

                prefetch_next_ar(ar_prefetched);

            end

        end

        else begin

            // AR handshake already happened while previous
            // read transaction was still finishing.

            vif.RREADY <= 1'b0;


            $display(
                "[%0t] AXI_DRIVER: using prefetched AR handshake",
                $time
            );

        end


        //======================================================
        // R Channel
        //======================================================

        expected_beats = tr.beats();

        tr.read_data = new[expected_beats];


        beat_index  = 0;
        tr.saw_last = 1'b0;


        //======================================================
        // R backpressure once only
        //======================================================

        if (!did_r_backpressure) begin


            wait (vif.RVALID === 1'b1);


            $display(
                "[%0t] AXI_DRIVER: legal R-channel backpressure test",
                $time
            );


            repeat (2)
                @(posedge vif.ACLK);


            @(negedge vif.ACLK);


            vif.RREADY <= 1'b1;

            did_r_backpressure = 1'b1;

        end

        else begin

            @(negedge vif.ACLK);

            vif.RREADY <= 1'b1;

        end


        //======================================================
        // Receive all read beats
        //======================================================

        while (beat_index < expected_beats) begin


            @(posedge vif.ACLK);


            if (vif.RVALID && vif.RREADY) begin


                tr.read_data[beat_index] = vif.RDATA;

                tr.response = vif.RRESP;


                if (vif.RLAST)
                    tr.saw_last = 1'b1;


                beat_index++;

            end

        end


        @(negedge vif.ACLK);


        vif.RREADY <= 1'b0;


        //======================================================
        // Complete prefetched AR transaction
        //======================================================

        if (ar_prefetched) begin


            // IMPORTANT:
            //
            // ARVALID has been high during the whole current
            // read transaction.
            //
            // ARADDR / ARLEN / ARSIZE were never changed.
            //
            // Wait until current transaction finishes and DUT
            // goes back to R_IDLE where ARREADY becomes 1.


            do begin

                @(posedge vif.ACLK);

            end
            while (!(vif.ARVALID && vif.ARREADY));


            @(negedge vif.ACLK);


            vif.ARVALID <= 1'b0;


            pending_ar_done = 1'b1;

            did_ar_backpressure = 1'b1;


            $display(
                "[%0t] AXI_DRIVER: AR-channel backpressure coverage COMPLETED",
                $time
            );

        end


        tr.display("AXI_DRIVER_READ_DONE");

    endtask


    //==========================================================
    // MAIN RUN
    //==========================================================

    task run();

        axi_transaction tr;

        bit aw_done_for_transaction;
        bit ar_done_for_transaction;


        wait_for_reset_release();


        $display(
            "[%0t] AXI_DRIVER: started",
            $time
        );


        forever begin


            //==================================================
            // Get transaction
            //==================================================

            if (has_pending_tr) begin


                tr = pending_tr;


                has_pending_tr = 1'b0;


                aw_done_for_transaction =
                    pending_aw_done;


                ar_done_for_transaction =
                    pending_ar_done;


                pending_aw_done = 1'b0;
                pending_ar_done = 1'b0;

            end

            else begin


                gen2drv.get(tr);


                aw_done_for_transaction = 1'b0;
                ar_done_for_transaction = 1'b0;

            end


            //==================================================
            // End-of-test sentinel
            //==================================================

            if (tr.end_of_test) begin


                $display(
                    "[%0t] AXI_DRIVER: received end-of-test after %0d transactions",
                    $time,
                    driven_transactions
                );


                -> done;

                break;

            end


            //==================================================
            // Execute transaction
            //==================================================

            if (tr.op == axi_transaction::WRITE) begin


                drive_write(
                    tr,
                    aw_done_for_transaction
                );

            end

            else begin


                drive_read(
                    tr,
                    ar_done_for_transaction
                );

            end


            driven_transactions++;

        end

    endtask

endclass
