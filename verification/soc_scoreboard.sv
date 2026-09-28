class soc_scoreboard;

    //========================================================
    // MAILBOXES
    //========================================================

    mailbox #(soc_transaction) mon2scb;
    mailbox #(soc_transaction) axi2scb;
    mailbox #(soc_transaction) exp2scb;


    //========================================================
    // EXPECTED GPIO QUEUE
    //========================================================

    bit [7:0] expected_gpio_queue[$];


    //========================================================
    // COUNTERS
    //========================================================

    int gpio_checks;
    int pwm_checks;
    int timer_checks;
    int uart_checks;
    int invalid_checks;
    int axi_checks;

    int pass_count;
    int fail_count;


    //========================================================
    // CONSTRUCTOR
    //========================================================

    function new(
        mailbox #(soc_transaction) mon2scb,
        mailbox #(soc_transaction) axi2scb,
        mailbox #(soc_transaction) exp2scb
    );

        this.mon2scb = mon2scb;
        this.axi2scb = axi2scb;
        this.exp2scb = exp2scb;

        gpio_checks    = 0;
        pwm_checks     = 0;
        timer_checks   = 0;
        uart_checks    = 0;
        invalid_checks = 0;
        axi_checks     = 0;

        pass_count = 0;
        fail_count = 0;

    endfunction


    //========================================================
    // EXPECTED TRANSACTION PROCESSOR
    //========================================================

    task expected_main();

        soc_transaction tr;

        forever begin

            exp2scb.get(tr);

            case (tr.test_type)

                //================================================
                // GPIO EXPECTED VALUE
                //================================================

                soc_transaction::GPIO_TEST:
                begin

                    expected_gpio_queue.push_back(
                        tr.expected_gpio
                    );

                    $display(
                        "[SCOREBOARD] Expected GPIO queued = %02h",
                        tr.expected_gpio
                    );

                end


                //================================================
                // OTHER TESTS
                //================================================

                default:
                begin

                    // AXI expected values are checked
                    // using address/data mapping.
                    
                end

            endcase

        end

    endtask


    //========================================================
    // GPIO CHECK
    //========================================================

    task check_gpio(
        input bit [7:0] actual
    );

        bit [7:0] expected;

        gpio_checks++;

        if (expected_gpio_queue.size() == 0) begin

            $display(
                "[SCOREBOARD] GPIO FAIL: no expected transaction"
            );

            fail_count++;

        end
        else begin

            expected = expected_gpio_queue.pop_front();

            if (actual === expected) begin

                $display(
                    "[SCOREBOARD] GPIO PASS: expected=%02h actual=%02h",
                    expected,
                    actual
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] GPIO FAIL: expected=%02h actual=%02h",
                    expected,
                    actual
                );

                fail_count++;

            end

        end

    endtask


    //========================================================
    // AXI WRITE CHECK
    //========================================================

    task check_axi_write(
        soc_transaction tr
    );

        // Every AXI write is counted
        axi_checks++;


        //====================================================
        // GPIO DIRECTION
        //====================================================

        if (tr.axi_address == 32'h4000_0000) begin

            if (
                tr.axi_wdata[7:0] == 8'hFF &&
                tr.axi_bresp == 2'b00
            ) begin

                $display(
                    "[SCOREBOARD] AXI GPIO DIR PASS: data=%08h",
                    tr.axi_wdata
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI GPIO DIR FAIL: data=%08h resp=%b",
                    tr.axi_wdata,
                    tr.axi_bresp
                );

                fail_count++;

            end

        end


        //====================================================
        // GPIO OUTPUT
        //====================================================

        else if (tr.axi_address == 32'h4000_0004) begin

            if (
                tr.axi_wdata[7:0] == 8'hA5 &&
                tr.axi_bresp == 2'b00
            ) begin

                $display(
                    "[SCOREBOARD] AXI GPIO OUT PASS: data=%08h",
                    tr.axi_wdata
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI GPIO OUT FAIL: data=%08h resp=%b",
                    tr.axi_wdata,
                    tr.axi_bresp
                );

                fail_count++;

            end

        end


        //====================================================
        // PWM CONTROL WRITE
        //====================================================

        else if (tr.axi_address == 32'h4000_1000) begin

            pwm_checks++;

            if (
                tr.axi_wdata[0] == 1'b1 &&
                tr.axi_bresp == 2'b00
            ) begin

                $display(
                    "[SCOREBOARD] AXI PWM CONTROL PASS"
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI PWM CONTROL FAIL"
                );

                fail_count++;

            end

        end


        //====================================================
        // PWM PERIOD WRITE
        //====================================================

        else if (tr.axi_address == 32'h4000_1004) begin

            pwm_checks++;

            if (
                tr.axi_wdata == 32'd100 &&
                tr.axi_bresp == 2'b00
            ) begin

                $display(
                    "[SCOREBOARD] AXI PWM PERIOD PASS: %0d",
                    tr.axi_wdata
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI PWM PERIOD FAIL: %0d",
                    tr.axi_wdata
                );

                fail_count++;

            end

        end


        //====================================================
        // PWM DUTY WRITE
        //====================================================

        else if (tr.axi_address == 32'h4000_1008) begin

            pwm_checks++;

            if (
                tr.axi_wdata == 32'd50 &&
                tr.axi_bresp == 2'b00
            ) begin

                $display(
                    "[SCOREBOARD] AXI PWM DUTY PASS: %0d",
                    tr.axi_wdata
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI PWM DUTY FAIL: %0d",
                    tr.axi_wdata
                );

                fail_count++;

            end

        end


        //====================================================
        // TIMER CONTROL WRITE
        //====================================================

        else if (tr.axi_address == 32'h4000_2000) begin

            timer_checks++;

            if (
                tr.axi_wdata[0] == 1'b1 &&
                tr.axi_bresp == 2'b00
            ) begin

                $display(
                    "[SCOREBOARD] AXI TIMER CONTROL PASS"
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI TIMER CONTROL FAIL"
                );

                fail_count++;

            end

        end


        //====================================================
        // TIMER COMPARE WRITE
        //====================================================

        else if (tr.axi_address == 32'h4000_2004) begin

            timer_checks++;

            if (
                tr.axi_wdata == 32'd20 &&
                tr.axi_bresp == 2'b00
            ) begin

                $display(
                    "[SCOREBOARD] AXI TIMER COMPARE PASS: %0d",
                    tr.axi_wdata
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI TIMER COMPARE FAIL: %0d",
                    tr.axi_wdata
                );

                fail_count++;

            end

        end


        //====================================================
        // UART TX WRITE
        //====================================================

        else if (tr.axi_address == 32'h4000_3000) begin

            uart_checks++;

            if (
                tr.axi_wdata[7:0] == 8'h41 &&
                tr.axi_bresp == 2'b00
            ) begin

                $display(
                    "[SCOREBOARD] AXI UART TX PASS: data=%02h",
                    tr.axi_wdata[7:0]
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI UART TX FAIL: data=%02h resp=%b",
                    tr.axi_wdata[7:0],
                    tr.axi_bresp
                );

                fail_count++;

            end

        end


        //====================================================
        // INVALID WRITE
        //====================================================
if (tr.test_type == soc_transaction::INVALID_ACCESS) begin

    invalid_checks++;

    if (tr.axi_bresp != 2'b00) begin

        pass_count++;

        $display(
            "[SCOREBOARD] INVALID ACCESS PASS: address=%08h BRESP=%b",
            tr.axi_address,
            tr.axi_bresp
        );

    end
    else begin

        fail_count++;

        $display(
            "[SCOREBOARD] INVALID ACCESS FAIL: address=%08h BRESP=%b",
            tr.axi_address,
            tr.axi_bresp
        );

    end

end

        //====================================================
        // UNKNOWN WRITE
        //====================================================

        else begin

            $display(
                "[SCOREBOARD] AXI WRITE INFO: unrecognized address=%08h data=%08h",
                tr.axi_address,
                tr.axi_wdata
            );

        end

    endtask


    //========================================================
    // AXI READ CHECK
    //========================================================

    task check_axi_read(
        soc_transaction tr
    );

        // Every AXI read is counted
        axi_checks++;


        //====================================================
        // GPIO OUTPUT READ
        //====================================================

        if (tr.axi_address == 32'h4000_0004) begin

            if (
                tr.axi_rdata[7:0] == 8'hA5 &&
                tr.axi_rresp == 2'b00
            ) begin

                $display(
                    "[SCOREBOARD] AXI GPIO READ PASS: data=%08h",
                    tr.axi_rdata
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI GPIO READ FAIL: data=%08h resp=%b",
                    tr.axi_rdata,
                    tr.axi_rresp
                );

                fail_count++;

            end

        end


        //====================================================
        // PWM CONTROL READ
        //====================================================

        else if (tr.axi_address == 32'h4000_1000) begin

            pwm_checks++;

            if (
                tr.axi_rdata[0] == 1'b1 &&
                tr.axi_rresp == 2'b00
            ) begin

                $display(
                    "[SCOREBOARD] AXI PWM CONTROL READ PASS"
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI PWM CONTROL READ FAIL"
                );

                fail_count++;

            end

        end


        //====================================================
        // PWM PERIOD READ
        //====================================================

        else if (tr.axi_address == 32'h4000_1004) begin

            pwm_checks++;

            if (
                tr.axi_rdata == 32'd100 &&
                tr.axi_rresp == 2'b00
            ) begin

                $display(
                    "[SCOREBOARD] AXI PWM PERIOD READ PASS"
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI PWM PERIOD READ FAIL: data=%08h",
                    tr.axi_rdata
                );

                fail_count++;

            end

        end


        //====================================================
        // PWM DUTY READ
        //====================================================

        else if (tr.axi_address == 32'h4000_1008) begin

            pwm_checks++;

            if (
                tr.axi_rdata == 32'd50 &&
                tr.axi_rresp == 2'b00
            ) begin

                $display(
                    "[SCOREBOARD] AXI PWM DUTY READ PASS"
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI PWM DUTY READ FAIL: data=%08h",
                    tr.axi_rdata
                );

                fail_count++;

            end

        end


        //====================================================
        // TIMER COMPARE READ
        //====================================================

        else if (tr.axi_address == 32'h4000_2004) begin

            timer_checks++;

            if (
                tr.axi_rdata == 32'd20 &&
                tr.axi_rresp == 2'b00
            ) begin

                $display(
                    "[SCOREBOARD] AXI TIMER COMPARE READ PASS"
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI TIMER COMPARE READ FAIL"
                );

                fail_count++;

            end

        end


        //====================================================
        // TIMER CONTROL READ
        //====================================================

        else if (tr.axi_address == 32'h4000_2000) begin

            timer_checks++;

            if (
                tr.axi_rdata[0] == 1'b1 &&
                tr.axi_rresp == 2'b00
            ) begin

                $display(
                    "[SCOREBOARD] AXI TIMER CONTROL READ PASS"
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI TIMER CONTROL READ FAIL"
                );

                fail_count++;

            end

        end


        //====================================================
        // UART STATUS READ
        //====================================================

        else if (tr.axi_address == 32'h4000_3008) begin

            uart_checks++;

            if (tr.axi_rresp == 2'b00) begin

                $display(
                    "[SCOREBOARD] AXI UART STATUS READ PASS: data=%08h",
                    tr.axi_rdata
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] AXI UART STATUS READ FAIL: resp=%b",
                    tr.axi_rresp
                );

                fail_count++;

            end

        end


        //====================================================
        // INVALID READ
        //====================================================

        else if (tr.axi_address == 32'hFFFF_F000) begin

            invalid_checks++;

            // Current AXI interconnect returns SLVERR = 2'b10
            if (tr.axi_rresp == 2'b10) begin

                $display(
                    "[SCOREBOARD] INVALID READ PASS: addr=%08h RRESP=%b",
                    tr.axi_address,
                    tr.axi_rresp
                );

                pass_count++;

            end
            else begin

                $display(
                    "[SCOREBOARD] INVALID READ FAIL: addr=%08h RRESP=%b",
                    tr.axi_address,
                    tr.axi_rresp
                );

                fail_count++;

            end

        end


        //====================================================
        // UNKNOWN READ
        //====================================================

        else begin

            $display(
                "[SCOREBOARD] AXI READ INFO: unrecognized address=%08h data=%08h",
                tr.axi_address,
                tr.axi_rdata
            );

        end

    endtask


    //========================================================
    // MAIN MONITOR SCOREBOARD
    //========================================================

    task monitor_main();

        soc_transaction tr;

        forever begin

            mon2scb.get(tr);

            case (tr.test_type)

                //================================================
                // GPIO FUNCTIONAL CHECK
                //================================================

                soc_transaction::GPIO_TEST:
                begin

                    check_gpio(tr.gpio_value);

                end


                //================================================
                // UART ACTIVITY
                //================================================

                soc_transaction::UART_TEST:
                begin

                    $display(
                        "[SCOREBOARD] UART activity observed."
                    );

                end


                //================================================
                // PWM ACTIVITY
                //================================================

                soc_transaction::PWM_TEST:
                begin

                    $display(
                        "[SCOREBOARD] PWM activity observed."
                    );

                end


                //================================================
                // TIMER ACTIVITY
                //================================================

                soc_transaction::TIMER_TEST:
                begin

                    $display(
                        "[SCOREBOARD] TIMER activity observed."
                    );

                end


                //================================================
                // AXI TEST
                //================================================

                soc_transaction::AXI_TEST:
                begin

                    $display(
                        "[SCOREBOARD] AXI activity observed."
                    );

                end


                //================================================
                // INVALID ACCESS
                //================================================

                soc_transaction::INVALID_ACCESS:
                begin

                    $display(
                        "[SCOREBOARD] Invalid access test observed."
                    );

                end


                //================================================
                // DEFAULT
                //================================================

                default:
                begin

                    $display(
                        "[SCOREBOARD] Monitor transaction received."
                    );

                end

            endcase

        end

    endtask


    //========================================================
    // AXI SCOREBOARD
    //========================================================

    task axi_main();

        soc_transaction tr;

        forever begin

            axi2scb.get(tr);

            if (tr.axi_write) begin

                check_axi_write(tr);

            end

            if (tr.axi_read) begin

                check_axi_read(tr);

            end

        end

    endtask


    //========================================================
    // REPORT
    //========================================================

    task report();

        $display("");
        $display("");
        $display("================================================");
        $display("              VERIFICATION REPORT");
        $display("================================================");

        $display(
            "GPIO CHECKS    = %0d",
            gpio_checks
        );

        $display(
            "PWM CHECKS     = %0d",
            pwm_checks
        );

        $display(
            "TIMER CHECKS   = %0d",
            timer_checks
        );

        $display(
            "UART CHECKS    = %0d",
            uart_checks
        );

        $display(
            "INVALID CHECKS = %0d",
            invalid_checks
        );

        $display(
            "AXI CHECKS     = %0d",
            axi_checks
        );

        $display("-----------------------------------------------");

        $display(
            "PASS COUNT     = %0d",
            pass_count
        );

        $display(
            "FAIL COUNT     = %0d",
            fail_count
        );

        $display("-----------------------------------------------");

        if (fail_count == 0) begin

            $display(
                "              VERIFICATION PASSED"
            );

        end
        else begin

            $display(
                "              VERIFICATION FAILED"
            );

        end

        $display("================================================");
        $display("");

    endtask

endclass
