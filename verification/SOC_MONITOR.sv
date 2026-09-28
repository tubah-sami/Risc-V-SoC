class soc_monitor;

    virtual soc_if vif;

    mailbox #(soc_transaction) mon2scb;


    //========================================================
    // LAST OBSERVED VALUES
    //========================================================

    bit [7:0] last_gpio_out;
    bit       last_uart;
    bit       last_pwm;


    //========================================================
    // CONSTRUCTOR
    //========================================================

    function new(
        virtual soc_if vif,
        mailbox #(soc_transaction) mon2scb
    );

        this.vif     = vif;
        this.mon2scb = mon2scb;

        last_gpio_out = 8'h00;
        last_uart     = 1'b1;
        last_pwm      = 1'b0;

    endfunction


    //========================================================
    // RUN
    //========================================================

    task run();

        soc_transaction tr;

        forever begin

            @(posedge vif.clk);


            //================================================
            // GPIO OUTPUT
            //================================================

            if (vif.gpio_out !== last_gpio_out) begin

                tr = new();

                tr.test_type  = soc_transaction::GPIO_TEST;
                tr.gpio_value = vif.gpio_out;

                $display(
                    "[MONITOR] GPIO OUTPUT observed = %02h",
                    vif.gpio_out
                );

                mon2scb.put(tr);

                last_gpio_out = vif.gpio_out;

            end


            //================================================
            // UART OUTPUT
            //================================================

            if (vif.uart_tx !== last_uart) begin

                tr = new();

                tr.test_type = soc_transaction::UART_TEST;

                // This is ACTUAL observed value.
                tr.uart_data = {7'b0, vif.uart_tx};

                $display(
                    "[MONITOR] UART TX activity = %b",
                    vif.uart_tx
                );

                mon2scb.put(tr);

                last_uart = vif.uart_tx;

            end


            //================================================
            // PWM OUTPUT
            //================================================

            if (vif.pwm_out !== last_pwm) begin

                tr = new();

                tr.test_type = soc_transaction::PWM_TEST;

                // Actual PWM output
                tr.expected_pwm = vif.pwm_out;

                $display(
                    "[MONITOR] PWM activity = %b",
                    vif.pwm_out
                );

                mon2scb.put(tr);

                last_pwm = vif.pwm_out;

            end

        end

    endtask

endclass
