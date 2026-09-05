// ============================================================
// Simple Timer Peripheral Testbench
// ============================================================

module timer_peripheral_tb;

    // =========================================================
    // DUT signals
    // =========================================================

    logic        clk;
    logic        reset_n;
    logic        enable;

    logic [31:0] compare_value;

    logic [31:0] count;
    logic        timeout;


    // =========================================================
    // Instantiate DUT
    // =========================================================

    timer_peripheral dut (
        .clk           (clk),
        .reset_n       (reset_n),
        .enable        (enable),
        .compare_value (compare_value),
        .count         (count),
        .timeout       (timeout)
    );


    // =========================================================
    // 100 MHz clock
    // 10 ns period
    // =========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // =========================================================
    // Main test
    // =========================================================

    initial begin

        // -----------------------------------------------------
        // Initial conditions
        // -----------------------------------------------------

        reset_n       = 1'b0;
        enable        = 1'b0;
        compare_value = 32'd3;


        // =====================================================
        // TEST 1: RESET
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 1: ACTIVE-LOW RESET");
        $display("========================================");

        repeat (2)
            @(posedge clk);

        #1;

        if ((count == 32'd0) && (timeout == 1'b0)) begin
            $display("[PASS] Reset successful");
        end
        else begin
            $display("[FAIL] Reset incorrect");
        end


        // =====================================================
        // RELEASE RESET
        // =====================================================

        reset_n = 1'b1;


        // =====================================================
        // TEST 2: TIMER DISABLED
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 2: TIMER DISABLED");
        $display("========================================");

        repeat (3)
            @(posedge clk);

        #1;

        if ((count == 32'd0) && (timeout == 1'b0)) begin
            $display("[PASS] Timer remains stopped");
        end
        else begin
            $display("[FAIL] Timer changed while disabled");
        end


        // =====================================================
        // TEST 3: COUNTING 0 → 1 → 2 → 3
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 3: COUNTING");
        $display("========================================");

        enable = 1'b1;


        // -------------------------
        // Check COUNT = 0
        // -------------------------

        @(posedge clk);
        #1;

        if (count == 32'd1) begin
            $display("[PASS] COUNT reached 1");
        end
        else begin
            $display("[FAIL] Expected COUNT=1, got %0d", count);
        end

        $display(
            "TIME=%0t ns | COUNT=%0d | TIMEOUT=%b",
            $time, count, timeout
        );


        // -------------------------
        // COUNT = 2
        // -------------------------

        @(posedge clk);
        #1;

        if (count == 32'd2) begin
            $display("[PASS] COUNT reached 2");
        end
        else begin
            $display("[FAIL] Expected COUNT=2, got %0d", count);
        end

        $display(
            "TIME=%0t ns | COUNT=%0d | TIMEOUT=%b",
            $time, count, timeout
        );


        // -------------------------
        // COUNT = 3
        // -------------------------

        @(posedge clk);
        #1;

        if (count == 32'd3) begin
            $display("[PASS] COUNT reached 3");
        end
        else begin
            $display("[FAIL] Expected COUNT=3, got %0d", count);
        end

        $display(
            "TIME=%0t ns | COUNT=%0d | TIMEOUT=%b",
            $time, count, timeout
        );


        // =====================================================
        // TEST 4: TIMEOUT PULSE
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 4: TIMEOUT PULSE");
        $display("========================================");

        // At this edge count=3, so timer should timeout
        @(posedge clk);
        #1;

        $display(
            "TIME=%0t ns | COUNT=%0d | TIMEOUT=%b",
            $time, count, timeout
        );

        if ((count == 32'd0) && (timeout == 1'b1)) begin
            $display("[PASS] Timeout generated correctly");
        end
        else begin
            $display("[FAIL] Timeout behavior incorrect");
        end


        // =====================================================
        // TEST 5: TIMEOUT RETURNS LOW
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 5: TIMEOUT ONE-CYCLE PULSE");
        $display("========================================");

        @(posedge clk);
        #1;

        $display(
            "TIME=%0t ns | COUNT=%0d | TIMEOUT=%b",
            $time, count, timeout
        );

        if ((count == 32'd1) && (timeout == 1'b0)) begin
            $display("[PASS] Timeout returned LOW");
        end
        else begin
            $display("[FAIL] Timeout did not return LOW");
        end


        // =====================================================
        // TEST 6: PERIODIC OPERATION
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 6: PERIODIC OPERATION");
        $display("========================================");

        repeat (8) begin

            @(posedge clk);
            #1;

            $display(
                "TIME=%0t ns | COUNT=%0d | TIMEOUT=%b",
                $time,
                count,
                timeout
            );

        end


        // =====================================================
        // TEST 7: DISABLE TIMER
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 7: DISABLE TIMER");
        $display("========================================");

        enable = 1'b0;

        @(posedge clk);
        #1;

        if (timeout == 1'b0) begin
            $display("[PASS] Timeout LOW when disabled");
        end
        else begin
            $display("[FAIL] Timeout still HIGH when disabled");
        end

        $display(
            "TIME=%0t ns | COUNT=%0d | TIMEOUT=%b | ENABLE=%b",
            $time,
            count,
            timeout,
            enable
        );


        // =====================================================
        // FINISH
        // =====================================================

        $display("");
        $display("========================================");
        $display("ALL TIMER TESTS COMPLETED");
        $display("========================================");

        #20;

        $finish;

    end

endmodule