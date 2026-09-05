`timescale 1ns/1ps

module gpio_tb;

    // =========================================================
    // SIGNAL DECLARATIONS
    // =========================================================

    logic        clk;
    logic        reset;

    // CPU interface
    logic        wr_en;
    logic        rd_en;
    logic [1:0]  addr;
    logic [31:0] wdata;
    logic [31:0] rdata;

    // External GPIO
    logic [7:0]  gpio_in;
    logic [7:0]  gpio_out;

    // =========================================================
    // DUT
    // =========================================================

    gpio_peripheral dut (
        .clk      (clk),
        .reset    (reset),
        .wr_en    (wr_en),
        .rd_en    (rd_en),
        .addr     (addr),
        .wdata    (wdata),
        .rdata    (rdata),
        .gpio_in  (gpio_in),
        .gpio_out (gpio_out)
    );

    // =========================================================
    // CLOCK GENERATION
    // 10 ns clock period
    // =========================================================

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // =========================================================
    // WRITE TASK
    // =========================================================

    task automatic write_reg(
        input logic [1:0]  address,
        input logic [31:0] data
    );
    begin
        @(negedge clk);

        wr_en = 1'b1;
        rd_en = 1'b0;
        addr  = address;
        wdata = data;

        @(posedge clk);
        #1;

        wr_en = 1'b0;
        addr  = 2'b00;
        wdata = 32'b0;
    end
    endtask

    // =========================================================
    // READ TASK
    // =========================================================

    task automatic read_reg(
        input  logic [1:0]  address,
        output logic [31:0] data
    );
    begin
        @(negedge clk);

        wr_en = 1'b0;
        rd_en = 1'b1;
        addr  = address;

        #1;
        data = rdata;

        @(negedge clk);

        rd_en = 1'b0;
        addr  = 2'b00;
    end
    endtask


    // =========================================================
    // TEST SEQUENCE
    // =========================================================

    logic [31:0] read_data;

    initial begin

        // -----------------------------------------------------
        // INITIAL VALUES
        // -----------------------------------------------------

        reset   = 1'b1;
        wr_en   = 1'b0;
        rd_en   = 1'b0;
        addr    = 2'b00;
        wdata   = 32'b0;
        gpio_in = 8'b0;

        // -----------------------------------------------------
        // TEST 1: RESET
        // -----------------------------------------------------

        #12;
        reset = 1'b0;

        #1;

        if (gpio_out === 8'b00000000)
            $display("[%0t] TEST 1 RESET : PASS | gpio_out = %b",
                     $time, gpio_out);
        else
            $display("[%0t] TEST 1 RESET : FAIL | gpio_out = %b",
                     $time, gpio_out);


        // -----------------------------------------------------
        // TEST 2: SET DIRECTION
        // All pins = OUTPUT
        // -----------------------------------------------------

        write_reg(2'b00, 32'h000000FF);

        read_reg(2'b00, read_data);

        if (read_data == 32'h000000FF)
            $display("[%0t] TEST 2 DIRECTION : PASS | direction = %b",
                     $time, read_data[7:0]);
        else
            $display("[%0t] TEST 2 DIRECTION : FAIL | Expected = 11111111 | Actual = %b",
                     $time, read_data[7:0]);


        // -----------------------------------------------------
        // TEST 3: WRITE OUTPUT
        // -----------------------------------------------------

        write_reg(2'b01, 32'h000000AA);

        if (gpio_out == 8'b10101010) begin
            $display("[%0t] TEST 3 WRITE OUTPUT : PASS | gpio_out = %b",
                     $time, gpio_out);
        end
        else begin
            $display("[%0t] TEST 3 WRITE OUTPUT : FAIL | Expected = 10101010 | Actual = %b",
                     $time, gpio_out);
        end


        // -----------------------------------------------------
        // TEST 4: CHANGE OUTPUT
        // -----------------------------------------------------

        write_reg(2'b01, 32'h000000CC);

        if (gpio_out == 8'b11001100) begin
            $display("[%0t] TEST 4 CHANGE OUTPUT : PASS | gpio_out = %b",
                     $time, gpio_out);
        end
        else begin
            $display("[%0t] TEST 4 CHANGE OUTPUT : FAIL | Expected = 11001100 | Actual = %b",
                     $time, gpio_out);
        end


        // -----------------------------------------------------
        // TEST 5: READ INPUT
        // -----------------------------------------------------

        gpio_in = 8'b11110000;

        read_reg(2'b10, read_data);

        if (read_data == 32'h000000F0)
            $display("[%0t] TEST 5 READ INPUT : PASS | gpio_in = %b",
                     $time, read_data[7:0]);
        else
            $display("[%0t] TEST 5 READ INPUT : FAIL | Expected = 11110000 | Actual = %b",
                     $time, read_data[7:0]);


        // -----------------------------------------------------
        // TEST 6: CHANGE INPUT
        // -----------------------------------------------------

        gpio_in = 8'b01010101;

        read_reg(2'b10, read_data);

        if (read_data == 32'h00000055)
            $display("[%0t] TEST 6 CHANGE INPUT : PASS | gpio_in = %b",
                     $time, read_data[7:0]);
        else
            $display("[%0t] TEST 6 CHANGE INPUT : FAIL | Expected = 01010101 | Actual = %b",
                     $time, read_data[7:0]);


        // -----------------------------------------------------
        // TEST 7: READ DIRECTION
        // -----------------------------------------------------

        read_reg(2'b00, read_data);

        if (read_data == 32'h000000FF)
            $display("[%0t] TEST 7 READ DIRECTION : PASS | direction = %b",
                     $time, read_data[7:0]);
        else
            $display("[%0t] TEST 7 READ DIRECTION : FAIL | Expected = 11111111 | Actual = %b",
                     $time, read_data[7:0]);


        // -----------------------------------------------------
        // TEST 8: READ OUTPUT REGISTER
        // -----------------------------------------------------

        read_reg(2'b01, read_data);

        if (read_data == 32'h000000CC)
            $display("[%0t] TEST 8 READ OUTPUT : PASS | output = %b",
                     $time, read_data[7:0]);
        else
            $display("[%0t] TEST 8 READ OUTPUT : FAIL | Expected = 11001100 | Actual = %b",
                     $time, read_data[7:0]);


        // =====================================================
        // TEST COMPLETED
        // =====================================================

        $display("");
        $display("==============================================");
        $display("          GPIO PERIPHERAL TEST");
        $display("==============================================");
        $display("ALL TESTS COMPLETED");
        $display("==============================================");

        #10;
        $finish;

    end

endmodule