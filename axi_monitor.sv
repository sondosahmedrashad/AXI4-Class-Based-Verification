class axi_monitor;

    virtual axi_interface.MONITOR vif;

    mailbox #(axi_transaction) mon2scb;
    mailbox #(axi_transaction) mon2cov;


    function new(
        virtual axi_interface.MONITOR vif,
        mailbox #(axi_transaction) mon2scb,
        mailbox #(axi_transaction) mon2cov
    );

        this.vif     = vif;
        this.mon2scb = mon2scb;
        this.mon2cov = mon2cov;

    endfunction


    //==========================================================
    // MAIN MONITOR
    //==========================================================

    task run();

        fork

            monitor_write();
            monitor_read();

        join

    endtask


    //==========================================================
    // WRITE MONITOR
    //==========================================================

    task monitor_write();

        forever begin

            axi_transaction tr;

            bit [31:0] data_q[$];

            int unsigned expected_beats;
            int unsigned beat_count;

            bit last_seen;
            bit last_on_final_beat;


            //==================================================
            // Capture AW handshake
            //==================================================

            do begin
                @(posedge vif.ACLK);
            end
            while (!(vif.ARESETn &&
                     vif.AWVALID &&
                     vif.AWREADY));


            tr = new();

            tr.op   = axi_transaction::WRITE;
            tr.addr = vif.AWADDR;
            tr.len  = vif.AWLEN;
            tr.size = vif.AWSIZE;


            expected_beats = int'(vif.AWLEN) + 1;

            beat_count        = 0;
            last_seen         = 1'b0;
            last_on_final_beat = 1'b0;

            data_q.delete();


            //==================================================
            // Capture exactly LEN+1 W handshakes
            //==================================================

            while (beat_count < expected_beats) begin

                @(posedge vif.ACLK);


                if (!vif.ARESETn) begin

                    $error(
                        "[MON][WRITE] Reset occurred during active transaction"
                    );

                    break;

                end


                if (vif.WVALID && vif.WREADY) begin

                    data_q.push_back(vif.WDATA);


                    // WLAST observed.
                    if (vif.WLAST) begin

                        last_seen = 1'b1;


                        if (beat_count == expected_beats - 1)
                            last_on_final_beat = 1'b1;

                        else
                            $error(
                                "[MON][WRITE] WLAST asserted early: beat=%0d expected_final=%0d",
                                beat_count,
                                expected_beats - 1
                            );

                    end


                    // Final expected beat but no WLAST.
                    if ((beat_count == expected_beats - 1) &&
                        !vif.WLAST) begin

                        $error(
                            "[MON][WRITE] WLAST missing on final beat %0d",
                            beat_count
                        );

                    end


                    beat_count++;

                end

            end


            //==================================================
            // Build monitored transaction
            //==================================================

            tr.data = new[data_q.size()];

            foreach (data_q[i])
                tr.data[i] = data_q[i];


            // saw_last means LAST was observed in the proper place.
            tr.saw_last = last_seen && last_on_final_beat;


            //==================================================
            // Capture B handshake
            //==================================================

            do begin
                @(posedge vif.ACLK);
            end
while (!(vif.BVALID && vif.BREADY));


            tr.response = vif.BRESP;


            //==================================================
            // Send completed transaction
            //==================================================

            mon2scb.put(tr);
            mon2cov.put(tr);

        end

    endtask


    //==========================================================
    // READ MONITOR
    //==========================================================

    task monitor_read();

        forever begin

            axi_transaction tr;

            bit [31:0] rdata_q[$];

            bit [1:0] last_rresp;

            int unsigned expected_beats;
            int unsigned beat_count;

            bit last_seen;
            bit last_on_final_beat;


            //==================================================
            // Capture AR handshake
            //==================================================

            do begin
                @(posedge vif.ACLK);
            end
            while (!(vif.ARESETn &&
                     vif.ARVALID &&
                     vif.ARREADY));


            tr = new();

            tr.op   = axi_transaction::READ;
            tr.addr = vif.ARADDR;
            tr.len  = vif.ARLEN;
            tr.size = vif.ARSIZE;


            expected_beats = int'(vif.ARLEN) + 1;

            beat_count         = 0;
            last_seen          = 1'b0;
            last_on_final_beat = 1'b0;

            rdata_q.delete();

            last_rresp = 2'b00;


            //==================================================
            // Capture exactly LEN+1 R handshakes
            //==================================================

            while (beat_count < expected_beats) begin

                @(posedge vif.ACLK);


                if (!vif.ARESETn) begin

                    $error(
                        "[MON][READ] Reset occurred during active transaction"
                    );

                    break;

                end


                if (vif.RVALID && vif.RREADY) begin

                    rdata_q.push_back(vif.RDATA);

                    last_rresp = vif.RRESP;


                    if (vif.RLAST) begin

                        last_seen = 1'b1;


                        if (beat_count == expected_beats - 1)
                            last_on_final_beat = 1'b1;

                        else
                            $error(
                                "[MON][READ] RLAST asserted early: beat=%0d expected_final=%0d",
                                beat_count,
                                expected_beats - 1
                            );

                    end


                    if ((beat_count == expected_beats - 1) &&
                        !vif.RLAST) begin

                        $error(
                            "[MON][READ] RLAST missing on final beat %0d",
                            beat_count
                        );

                    end


                    beat_count++;

                end

            end


            //==================================================
            // Build monitored transaction
            //==================================================

            tr.read_data = new[rdata_q.size()];

            foreach (rdata_q[i])
                tr.read_data[i] = rdata_q[i];


            tr.response = last_rresp;

            tr.saw_last =
                last_seen &&
                last_on_final_beat;


            //==================================================
            // Send completed transaction
            //==================================================

            mon2scb.put(tr);
            mon2cov.put(tr);

        end

    endtask

endclass