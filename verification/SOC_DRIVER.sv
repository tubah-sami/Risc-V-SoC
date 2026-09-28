class soc_driver;

    virtual soc_if vif;

    mailbox #(soc_transaction) gen2drv;

    // Event used to notify the environment that
    // the final transaction has been completed.
    event test_done;


    //========================================================
    // CONSTRUCTOR
    //========================================================

    function new(
        virtual soc_if vif,
        mailbox #(soc_transaction) gen2drv,
        event test_done
    );

        this.vif       = vif;
        this.gen2drv   = gen2drv;
        this.test_done = test_done;

    endfunction


    //========================================================
    // RESET
    //========================================================

    task reset_dut();

        $display("");
        $display("================================================");
        $display("[TEST CASE 1] RESET TEST");
        $display("================================================");

        $display("[DRIVER] Applying reset...");

        vif.rst_i = 1'b1;

        repeat (5)
            @(posedge vif.clk);

        vif.rst_i = 1'b0;

        repeat (5)
            @(posedge vif.clk);

        $display("[DRIVER] Reset released.");
        $display("[DRIVER] RESET TEST COMPLETED");

    endtask


    //========================================================
    // GPIO
    //========================================================

    task drive_gpio(soc_transaction tr);

        $display("");
        $display("================================================");
        $display("[TEST CASE 2/3] GPIO TEST");
        $display("================================================");

        $display(
            "[DRIVER] Driving GPIO input = %02h",
            tr.gpio_value
        );

        vif.gpio_in = tr.gpio_value;

        repeat (10)
            @(posedge vif.clk);

        $display(
            "[DRIVER] GPIO stimulus completed. DUT gpio_out = %02h",
            vif.gpio_out
        );

    endtask


    //========================================================
    // PWM
    //========================================================

    task drive_pwm(soc_transaction tr);

        $display("");
        $display("================================================");
        $display("[TEST CASE 4] PWM TEST");
        $display("================================================");

        $display(
            "[DRIVER] PWM period = %0d duty = %0d",
            tr.pwm_period,
            tr.pwm_duty
        );

        repeat (100)
            @(posedge vif.clk);

        $display("[DRIVER] PWM TEST COMPLETED");

    endtask


    //========================================================
    // TIMER
    //========================================================

    task drive_timer(soc_transaction tr);

        $display("");
        $display("================================================");
        $display("[TEST CASE 5] TIMER TEST");
        $display("================================================");

        $display(
            "[DRIVER] TIMER value = %0d",
            tr.timer_value
        );

        repeat (100)
            @(posedge vif.clk);

        $display("[DRIVER] TIMER TEST COMPLETED");

    endtask


    //========================================================
    // UART
    //========================================================

    task drive_uart(soc_transaction tr);

        $display("");
        $display("================================================");
        $display("[TEST CASE 6] UART TEST");
        $display("================================================");

        $display(
            "[DRIVER] UART data = %02h",
            tr.uart_data
        );

        repeat (100)
            @(posedge vif.clk);

        $display("[DRIVER] UART TEST COMPLETED");

    endtask


    //========================================================
    // AXI
    //========================================================

    task drive_axi(soc_transaction tr);

        $display("");
        $display("================================================");
        $display("[TEST CASE 7] AXI TEST");
        $display("================================================");

        $display("[DRIVER] AXI transaction requested.");

        $display(
            "[DRIVER] AXI Address = %08h",
            tr.axi_address
        );

        $display(
            "[DRIVER] AXI WDATA   = %08h",
            tr.axi_wdata
        );

        $display(
            "[DRIVER] AXI WSTRB   = %h",
            tr.axi_wstrb
        );

        $display(
            "[DRIVER] AXI WRITE   = %b",
            tr.axi_write
        );

        $display(
            "[DRIVER] AXI READ    = %b",
            tr.axi_read
        );

        /*
         * CPU is the AXI master.
         * Driver does not directly drive AXI signals.
         */

        repeat (100)
            @(posedge vif.clk);

        $display("[DRIVER] AXI TEST COMPLETED");

    endtask


    //========================================================
    // INVALID ACCESS
    //========================================================

    task drive_invalid_access(soc_transaction tr);

        $display("");
        $display("================================================");
        $display("[TEST CASE 8] INVALID ADDRESS TEST");
        $display("================================================");

        $display(
            "[DRIVER] Invalid AXI address = %08h",
            tr.axi_address
        );

        $display(
            "[DRIVER] Invalid AXI data    = %08h",
            tr.axi_wdata
        );

        $display(
            "[DRIVER] AXI WSTRB            = %h",
            tr.axi_wstrb
        );

        $display(
            "[DRIVER] AXI WRITE            = %b",
            tr.axi_write
        );

        $display(
            "[DRIVER] AXI READ             = %b",
            tr.axi_read
        );

        /*
         * CPU firmware generates the actual AXI transaction.
         */

        repeat (500)
            @(posedge vif.clk);

        $display("[DRIVER] INVALID ADDRESS TEST COMPLETED");

    endtask


    //========================================================
    // MAIN DRIVER
    //========================================================

    task run();

        soc_transaction tr;

        forever begin

            gen2drv.get(tr);

            tr.display();

            case (tr.test_type)

                soc_transaction::RESET_TEST:
                    reset_dut();

                soc_transaction::GPIO_TEST:
                    drive_gpio(tr);

                soc_transaction::PWM_TEST:
                    drive_pwm(tr);

                soc_transaction::TIMER_TEST:
                    drive_timer(tr);

                soc_transaction::UART_TEST:
                    drive_uart(tr);

                soc_transaction::AXI_TEST:
                    drive_axi(tr);

                soc_transaction::INVALID_ACCESS:
                    begin

                        drive_invalid_access(tr);

                        $display("");
                        $display(
                            "[DRIVER] ALL DRIVER TRANSACTIONS COMPLETED."
                        );

                        // Notify environment
                        -> test_done;

                        // Stop driver after final transaction
                        return;

                    end

                default:
                    $display(
                        "[DRIVER] ERROR: Unknown transaction."
                    );

            endcase

        end

    endtask

endclass
