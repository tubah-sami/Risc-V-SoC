`timescale 1ns/1ps

module pwm_tb;

    parameter WIDTH = 16;

    logic clk;
    logic reset_n;
    logic enable;
    logic [WIDTH-1:0] period;
    logic [WIDTH-1:0] duty;
    logic pwm_out;

    integer errors;


    // ========================================================
    // DUT
    // ========================================================
    pwm_rtl #(
        .WIDTH(WIDTH)
    ) dut (
        .clk     (clk),
        .reset_n (reset_n),
        .enable  (enable),
        .period  (period),
        .duty    (duty),
        .pwm_out (pwm_out)
    );


    // ========================================================
    // CLOCK: 10 ns
    // ========================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ========================================================
    // CONFIGURE PWM
    //
    // 1. Disable
    // 2. Wait for posedge -> counter becomes 0
    // 3. Apply new configuration
    // 4. Enable
    // 5. Counter starts cleanly from 0
    // ========================================================
    task automatic configure_pwm(
        input logic [WIDTH-1:0] new_period,
        input logic [WIDTH-1:0] new_duty
    );
        begin

            // Disable PWM
            @(negedge clk);
            enable = 1'b0;

            // Counter resets here
            @(posedge clk);

            // Apply new values while disabled
            @(negedge clk);
            period = new_period;
            duty   = new_duty;

            // Enable PWM
            enable = 1'b1;

            // Allow combinational PWM output to update
            #1;

        end
    endtask


    // ========================================================
    // CHECK ONE COMPLETE PERIOD
    // ========================================================
    task automatic check_pwm_period(
        input integer test_period,
        input integer test_duty
    );

        integer i;
        logic expected_pwm;

        begin

            for (i = 0; i < test_period; i = i + 1) begin

                // Expected PWM value
                if (test_duty >= test_period)
                    expected_pwm = 1'b1;
                else if (i < test_duty)
                    expected_pwm = 1'b1;
                else
                    expected_pwm = 1'b0;


                // Check current state
                #1;

                $display(
                    "TIME=%0t | COUNT=%0d | EXPECTED_PWM=%0b | ACTUAL_PWM=%0b",
                    $time,
                    dut.counter,
                    expected_pwm,
                    pwm_out
                );


                if (dut.counter !== i) begin
                    $display(
                        "  [FAIL] Counter: expected=%0d actual=%0d",
                        i,
                        dut.counter
                    );
                    errors = errors + 1;
                end


                if (pwm_out !== expected_pwm) begin
                    $display(
                        "  [FAIL] PWM: expected=%0b actual=%0b",
                        expected_pwm,
                        pwm_out
                    );
                    errors = errors + 1;
                end


                // Advance exactly one PWM count
                @(posedge clk);

                // Wait until stable before next check
                @(negedge clk);

            end


            // Verify wrap
            #1;

            if (dut.counter == '0)
                $display("[PASS] Completed full period and wrapped to COUNT=0");
            else begin
                $display(
                    "[FAIL] Counter did not wrap: COUNT=%0d",
                    dut.counter
                );
                errors = errors + 1;
            end

        end
    endtask


    // ========================================================
    // RUN ONE TEST
    // ========================================================
    task automatic run_test(
        input integer test_number,
        input integer test_period,
        input integer test_duty
    );

        begin

            $display("");
            $display("==============================================");
            $display(
                "TEST %0d: PERIOD=%0d, DUTY=%0d",
                test_number,
                test_period,
                test_duty
            );
            $display("==============================================");

            configure_pwm(test_period, test_duty);

            // Check from COUNT = 0
            check_pwm_period(test_period, test_duty);

        end
    endtask


    // ========================================================
    // MAIN TEST
    // ========================================================
    initial begin

        errors  = 0;
        reset_n = 1'b0;
        enable  = 1'b0;
        period  = '0;
        duty    = '0;


        // ----------------------------------------------------
        // TEST 1: RESET
        // ----------------------------------------------------
        $display("");
        $display("==============================================");
        $display("TEST 1: RESET");
        $display("==============================================");

        #2;

        if (dut.counter == '0 && pwm_out == 1'b0)
            $display("[PASS] Reset successful");
        else begin
            $display("[FAIL] Reset failed");
            errors = errors + 1;
        end


        // Release reset
        @(negedge clk);
        reset_n = 1'b1;


        // ----------------------------------------------------
        // TEST 2: PWM DISABLED
        // ----------------------------------------------------
        $display("");
        $display("==============================================");
        $display("TEST 2: PWM DISABLED");
        $display("==============================================");

        period = 16'd10;
        duty   = 16'd5;
        enable = 1'b0;

        repeat (3) begin
            @(posedge clk);
            #1;

            if (dut.counter == '0 && pwm_out == 1'b0)
                $display("[PASS] Disabled: COUNT=0 PWM=0");
            else begin
                $display(
                    "[FAIL] Disabled: COUNT=%0d PWM=%0b",
                    dut.counter,
                    pwm_out
                );
                errors = errors + 1;
            end
        end


        // ----------------------------------------------------
        // TEST 3: 50% DUTY
        // Expected: 1111100000
        // ----------------------------------------------------
        run_test(3, 10, 5);


        // ----------------------------------------------------
        // TEST 4: 25% DUTY
        // Expected: 11000000
        // ----------------------------------------------------
        run_test(4, 8, 2);


        // ----------------------------------------------------
        // TEST 5: 0% DUTY
        // Expected: 00000000
        // ----------------------------------------------------
        run_test(5, 8, 0);


        // ----------------------------------------------------
        // TEST 6: 100% DUTY
        // Expected: 11111111
        // ----------------------------------------------------
        run_test(6, 8, 8);


        // ----------------------------------------------------
        // TEST 7: DUTY > PERIOD
        // Expected: 11111111
        // ----------------------------------------------------
        run_test(7, 8, 12);


        // ----------------------------------------------------
        // TEST 8: PERIOD = 0
        // ----------------------------------------------------
        $display("");
        $display("==============================================");
        $display("TEST 8: PERIOD=0");
        $display("==============================================");

        configure_pwm(0, 0);

        repeat (3) begin
            @(posedge clk);
            #1;

            if (dut.counter == '0 && pwm_out == 1'b0)
                $display("[PASS] PERIOD=0: COUNT=0 PWM=0");
            else begin
                $display(
                    "[FAIL] PERIOD=0: COUNT=%0d PWM=%0b",
                    dut.counter,
                    pwm_out
                );
                errors = errors + 1;
            end
        end


        // ----------------------------------------------------
        // TEST 9: DISABLE / RE-ENABLE
        // ----------------------------------------------------
        $display("");
        $display("==============================================");
        $display("TEST 9: DISABLE / RE-ENABLE");
        $display("==============================================");

        configure_pwm(10, 5);

        // Let PWM run for 3 counts
        repeat (3) begin
            @(posedge clk);
        end

        // Disable
        @(negedge clk);
        enable = 1'b0;

        @(posedge clk);
        #1;

        if (dut.counter == '0 && pwm_out == 1'b0)
            $display("[PASS] PWM disabled and counter reset");
        else begin
            $display("[FAIL] PWM did not reset correctly");
            errors = errors + 1;
        end

        // Re-enable
        @(negedge clk);
        enable = 1'b1;
        #1;

        if (dut.counter == '0 && pwm_out == 1'b1)
            $display("[PASS] PWM restarted cleanly from COUNT=0");
        else begin
            $display(
                "[FAIL] PWM restart: COUNT=%0d PWM=%0b",
                dut.counter,
                pwm_out
            );
            errors = errors + 1;
        end


        // ====================================================
        // FINAL RESULT
        // ====================================================
        $display("");
        $display("==============================================");

        if (errors == 0)
            $display("ALL PWM TESTS PASSED");
        else
            $display("PWM TESTS FAILED: %0d ERRORS", errors);

        $display("==============================================");

        #20;
        $stop;

    end

endmodule