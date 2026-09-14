class axi_test;

    virtual axi_interface vif;

    axi_environment env;


    function new(
        virtual axi_interface vif
    );

        this.vif = vif;

        env = new(vif);

    endfunction


    task run(
        int unsigned random_transactions = 20
    );

        env.gen.random_transactions =
            random_transactions;


        $display("============================================================");
        $display(" AXI CLASS-BASED VERIFICATION TEST START");
        $display(" Random transaction count = %0d",
                 random_transactions);
        $display("============================================================");


        // Run complete verification environment
        env.run();


        // Print scoreboard and functional coverage results
        env.report();


        $display("============================================================");
        $display(" AXI CLASS-BASED VERIFICATION TEST COMPLETE");
        $display(
            " Driver processed %0d transactions",
            env.drv.driven_transactions
        );
        $display("============================================================");

    endtask

endclass