class soc_env;

    //========================================================
    // VIRTUAL INTERFACE
    //========================================================

    virtual soc_if vif;


    //========================================================
    // MAILBOXES
    //========================================================

    mailbox #(soc_transaction) gen2drv;
    mailbox #(soc_transaction) exp2scb;
    mailbox #(soc_transaction) mon2scb;
    mailbox #(soc_transaction) axi2scb;


    //========================================================
    // COMPONENTS
    //========================================================

    soc_generator    generator;
    soc_driver       driver;
    soc_monitor      monitor;
    soc_axi_monitor  axi_monitor;
    soc_scoreboard   scoreboard;


    //========================================================
    // TEST DONE EVENT
    //========================================================

    event test_done;


    //========================================================
    // CONSTRUCTOR
    //========================================================

    function new(
        virtual soc_if vif
    );

        this.vif = vif;


        //====================================================
        // CREATE MAILBOXES
        //====================================================

        gen2drv = new();
        exp2scb = new();
        mon2scb = new();
        axi2scb = new();


        //====================================================
        // CREATE GENERATOR
        //====================================================

        generator = new(
            gen2drv,
            exp2scb
        );


        //====================================================
        // CREATE DRIVER
        //====================================================

        driver = new(
            vif,
            gen2drv,
            test_done
        );


        //====================================================
        // CREATE MONITOR
        //====================================================

        monitor = new(
            vif,
            mon2scb
        );


        //====================================================
        // CREATE AXI MONITOR
        //====================================================

        axi_monitor = new(
            vif,
            axi2scb
        );


        //====================================================
        // CREATE SCOREBOARD
        //====================================================

        scoreboard = new(
            mon2scb,
            axi2scb,
            exp2scb
        );

    endfunction


    //========================================================
    // RUN
    //========================================================

    task run();

        //====================================================
        // START BACKGROUND COMPONENTS
        //====================================================

        fork

            driver.run();

            monitor.run();

            axi_monitor.run();

            scoreboard.expected_main();

            scoreboard.monitor_main();

            scoreboard.axi_main();

        join_none


        //====================================================
        // START GENERATOR
        //====================================================

        generator.run();

//========================================================
// WAIT FOR DRIVER COMPLETION
//========================================================

@(test_done);

$display("");
$display("[ENV] Test completion event received.");
$display("[ENV] All driver transactions completed.");


//========================================================
// ALLOW MONITORS / SCOREBOARD TO DRAIN
//========================================================

repeat (20)
    @(posedge vif.clk);


//========================================================
// STOP BACKGROUND COMPONENTS
//========================================================

disable fork;


//========================================================
// REPORT
//========================================================

scoreboard.report();

    endtask

endclass