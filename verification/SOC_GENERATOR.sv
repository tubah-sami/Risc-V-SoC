class soc_generator;

    mailbox #(soc_transaction) gen2drv;
    mailbox #(soc_transaction) exp2scb;


    //========================================================
    // CONSTRUCTOR
    //========================================================

    function new(
        mailbox #(soc_transaction) gen2drv,
        mailbox #(soc_transaction) exp2scb
    );

        this.gen2drv = gen2drv;
        this.exp2scb = exp2scb;

    endfunction


    //========================================================
    // SEND TRANSACTION
    //========================================================

    task send_transaction(soc_transaction tr);

        // Send independent copy to scoreboard
        exp2scb.put(tr.clone());

        // Send original transaction to driver
        gen2drv.put(tr);

    endtask


    //========================================================
    // GENERATOR
    //========================================================

    task run();

        soc_transaction tr;


        //====================================================
        // RESET
        //====================================================

        tr = new();

        tr.test_type = soc_transaction::RESET_TEST;

        send_transaction(tr);


        //====================================================
        // GPIO TEST 1
        //====================================================

        tr = new();

        tr.test_type = soc_transaction::GPIO_TEST;

        tr.gpio_value    = 8'hA5;
        tr.expected_gpio = 8'hA5;

        send_transaction(tr);


        //====================================================
        // GPIO TEST 2
        //====================================================

        tr = new();

        tr.test_type = soc_transaction::GPIO_TEST;

        tr.gpio_value    = 8'h55;
        tr.expected_gpio = 8'h55;

        send_transaction(tr);


        //====================================================
        // PWM TEST
        //====================================================

        tr = new();

        tr.test_type = soc_transaction::PWM_TEST;

        tr.pwm_period = 32'd100;
        tr.pwm_duty   = 32'd50;

        send_transaction(tr);


        //====================================================
        // TIMER TEST
        //====================================================

        tr = new();

        tr.test_type = soc_transaction::TIMER_TEST;

        tr.timer_value = 32'd20;

        send_transaction(tr);


        //====================================================
        // UART TEST
        //====================================================

        tr = new();

        tr.test_type = soc_transaction::UART_TEST;

        tr.uart_data = 8'h55;

        send_transaction(tr);


        //====================================================
        // AXI TEST
        //====================================================

        tr = new();

        tr.test_type = soc_transaction::AXI_TEST;

        tr.axi_address = 32'h0000_1000;
        tr.axi_wdata   = 32'h1234_5678;
        tr.axi_wstrb   = 4'hF;

        tr.axi_write = 1'b1;
        tr.axi_read  = 1'b0;

        send_transaction(tr);


        //====================================================
        // INVALID WRITE
        //====================================================

        tr = new();

        tr.test_type = soc_transaction::INVALID_ACCESS;

        // IMPORTANT:
        // Use AXI fields, not generic address/data fields.
        tr.axi_address = 32'hFFFF_F000;
        tr.axi_wdata   = 32'hDEAD_BEEF;
        tr.axi_wstrb   = 4'hF;

        tr.axi_write = 1'b1;
        tr.axi_read  = 1'b0;

        send_transaction(tr);


        //====================================================
        // INVALID READ
        //====================================================

        tr = new();

        tr.test_type = soc_transaction::INVALID_ACCESS;

        tr.axi_address = 32'hFFFF_F000;

        tr.axi_wdata   = 32'h0000_0000;
        tr.axi_wstrb   = 4'h0;

        tr.axi_write = 1'b0;
        tr.axi_read  = 1'b1;

        send_transaction(tr);


        //====================================================
        // GENERATION COMPLETE
        //====================================================

        $display("");
        $display("[GENERATOR] All transactions generated.");
        $display("");

    endtask

endclass
