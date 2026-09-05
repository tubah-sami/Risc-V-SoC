`timescale 1ns/1ps

module uart_tb;

    // =========================================================
    // Clock and Reset
    // =========================================================

    reg CLOCK_50_B5B;
    reg CPU_RESET_n;
    reg UART_RX;

    wire UART_TX;
    wire [7:0] LEDR;

    // =========================================================
    // Baud Rate Parameters
    // =========================================================

    parameter CLK_FREQ  = 50000000;
    parameter BAUD_RATE = 115200;

    parameter BAUD_TICK_MAX = CLK_FREQ / BAUD_RATE;

    // =========================================================
    // DUT
    // =========================================================

    cyclone5_uart_led dut (

        .CLOCK_50_B5B(CLOCK_50_B5B),
        .CPU_RESET_n(CPU_RESET_n),
        .UART_RX(UART_RX),
        .UART_TX(UART_TX),
        .LEDR(LEDR)

    );


    // =========================================================
    // 50 MHz Clock
    // Clock Period = 20 ns
    // =========================================================

    initial begin

        CLOCK_50_B5B = 0;

        forever #10 CLOCK_50_B5B = ~CLOCK_50_B5B;

    end


    // =========================================================
    // TASK: Send One UART Byte to UART_RX
    // =========================================================

    task send_uart_byte;

        input [7:0] data;

        integer i;

        begin

            // -------------------------------
            // START BIT
            // -------------------------------

            UART_RX = 1'b0;

            repeat (BAUD_TICK_MAX)
                @(posedge CLOCK_50_B5B);


            // -------------------------------
            // DATA BITS
            // UART sends LSB first
            // -------------------------------

            for (i = 0; i < 8; i = i + 1) begin

                UART_RX = data[i];

                repeat (BAUD_TICK_MAX)
                    @(posedge CLOCK_50_B5B);

            end


            // -------------------------------
            // STOP BIT
            // -------------------------------

            UART_RX = 1'b1;

            repeat (BAUD_TICK_MAX)
                @(posedge CLOCK_50_B5B);

        end

    endtask


    // =========================================================
    // TASK: Check UART_TX Echo Data
    // =========================================================

    task check_uart_tx;

        input [7:0] expected_data;

        integer i;

        reg [7:0] received_data;

        begin

            // Wait for START bit on UART_TX
            @(negedge UART_TX);

            // Go to middle of start bit
            repeat (BAUD_TICK_MAX / 2)
                @(posedge CLOCK_50_B5B);

            // Check Start Bit
            if (UART_TX !== 1'b0)
                $display("ERROR: Invalid START bit at time %0t", $time);


            // Move to middle of first data bit
            repeat (BAUD_TICK_MAX)
                @(posedge CLOCK_50_B5B);


            // Receive 8 bits
            for (i = 0; i < 8; i = i + 1) begin

                received_data[i] = UART_TX;

                repeat (BAUD_TICK_MAX)
                    @(posedge CLOCK_50_B5B);

            end


            // Check STOP bit
            if (UART_TX !== 1'b1)
                $display("ERROR: Invalid STOP bit at time %0t", $time);


            // Compare data
            if (received_data == expected_data)

                $display(
                    "UART TX PASS: Expected = %h, Received = %h",
                    expected_data,
                    received_data
                );

            else

                $display(
                    "UART TX FAIL: Expected = %h, Received = %h",
                    expected_data,
                    received_data
                );

        end

    endtask


    // =========================================================
    // Main Test
    // =========================================================

    initial begin

        // Initial values

        CPU_RESET_n = 0;
        UART_RX     = 1'b1;


        // -------------------------------
        // RESET
        // -------------------------------

        #100;

        CPU_RESET_n = 1;

        $display("RESET RELEASED");


        // Wait a little

        repeat (10)
            @(posedge CLOCK_50_B5B);


        // =====================================================
        // TEST 1: Send 'A' = 8'h41
        // =====================================================

        $display("--------------------------------");
        $display("TEST 1: Sending A = 8'h41");
        $display("--------------------------------");

        fork

            send_uart_byte(8'h41);

            check_uart_tx(8'h41);

        join


        // Check LED

        if (LEDR == 8'h41)

            $display(
                "LED PASS: Expected = 41, LEDR = %h",
                LEDR
            );

        else

            $display(
                "LED FAIL: Expected = 41, LEDR = %h",
                LEDR
            );


        // Wait before next test

        repeat (1000)
            @(posedge CLOCK_50_B5B);


        // =====================================================
        // TEST 2: Send 8'h55
        // =====================================================

        $display("--------------------------------");
        $display("TEST 2: Sending 8'h55");
        $display("--------------------------------");

        fork

            send_uart_byte(8'h55);

            check_uart_tx(8'h55);

        join


        if (LEDR == 8'h55)

            $display(
                "LED PASS: Expected = 55, LEDR = %h",
                LEDR
            );

        else

            $display(
                "LED FAIL: Expected = 55, LEDR = %h",
                LEDR
            );


        // =====================================================
        // TEST 3: Send 8'hAA
        // =====================================================

        $display("--------------------------------");
        $display("TEST 3: Sending 8'hAA");
        $display("--------------------------------");

        fork

            send_uart_byte(8'hAA);

            check_uart_tx(8'hAA);

        join


        if (LEDR == 8'hAA)

            $display(
                "LED PASS: Expected = AA, LEDR = %h",
                LEDR
            );

        else

            $display(
                "LED FAIL: Expected = AA, LEDR = %h",
                LEDR
            );


        // =====================================================
        // FINISH
        // =====================================================

        #1000;

        $display("--------------------------------");
        $display("ALL UART TESTS COMPLETED");
        $display("--------------------------------");

        $stop;

    end

endmodule