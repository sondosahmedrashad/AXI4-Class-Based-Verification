class axi_environment;

    virtual axi_interface vif;

    virtual axi_interface.MASTER  master_vif;
    virtual axi_interface.MONITOR monitor_vif;


    //==========================================================
    // Mailboxes
    //==========================================================

    mailbox #(axi_transaction) gen2drv;
    mailbox #(axi_transaction) mon2scb;
    mailbox #(axi_transaction) mon2cov;


    //==========================================================
    // Person 1 Components
    //==========================================================

    axi_generator gen;
    axi_driver    drv;


    //==========================================================
    // Person 2 Components
    //==========================================================

    axi_monitor         mon;
    axi_reference_model ref_model;
    axi_scoreboard      scb;
    axi_coverage        cov;


    //==========================================================
    // Constructor
    //==========================================================

    function new(virtual axi_interface vif);

        this.vif = vif;

        // Restricted interface views
        this.master_vif  = vif;
        this.monitor_vif = vif;


        // Create mailboxes
        gen2drv = new();
        mon2scb = new();
        mon2cov = new();


        // Person 1
        gen = new(
            gen2drv
        );

        drv = new(
            master_vif,
            gen2drv
        );


        // Person 2
        ref_model = new();

        mon = new(
            monitor_vif,
            mon2scb,
            mon2cov
        );

        scb = new(
            mon2scb,
            ref_model
        );

        cov = new(
            mon2cov
        );

    endfunction


    //==========================================================
    // RUN
    //==========================================================

    task run();

        bit driver_finished;

        driver_finished = 1'b0;


        $display("=====================================================");
        $display(" AXI ENVIRONMENT STARTED");
        $display("=====================================================");


        //======================================================
        // Start all background verification components
        //======================================================

        fork

            drv.run();
            mon.run();
            scb.run();
            cov.run();

        join_none


        //======================================================
        // IMPORTANT:
        // Start waiting for drv.done BEFORE generator runs.
        //
        // This prevents missing the event if the driver finishes
        // before the main environment thread reaches the wait.
        //======================================================

        fork

            begin
                @drv.done;
                driver_finished = 1'b1;

                $display(
                    "[%0t] AXI_ENVIRONMENT: driver completion detected",
                    $time
                );
            end

        join_none


        //======================================================
        // Run stimulus generation
        //======================================================

        gen.run();


        //======================================================
        // Wait for actual driver completion
        //
        // Do NOT depend only on mailbox.num().
        // An empty mailbox only means the driver has removed the
        // item; it does not guarantee the transaction is finished.
        //======================================================

        wait (driver_finished == 1'b1);


        //======================================================
        // Allow monitor / scoreboard / coverage to process
        // the final completed transaction.
        //======================================================

        repeat (20)
            @(posedge vif.ACLK);


        //======================================================
        // Stop forever-running background processes
        //======================================================

        disable fork;


        $display("=====================================================");
        $display(" AXI ENVIRONMENT FINISHED");
        $display("=====================================================");

    endtask


    //==========================================================
    // REPORT
    //==========================================================

    function void report();

        $display("");

        $display("=====================================================");
        $display("              AXI ENVIRONMENT REPORT");
        $display("=====================================================");

        scb.report();
        cov.report();

        $display("=====================================================");
        $display("");

    endfunction

endclass
