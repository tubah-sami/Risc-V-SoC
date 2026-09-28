`timescale 1ns/1ps

`include "TB_CLASSES.sv"


module tb_top;

    //========================================================
    // CLOCK
    //========================================================

    logic clk;

    initial begin

        clk = 1'b0;

        forever
            #10 clk = ~clk;

    end


    //========================================================
    // INTERFACE
    //========================================================

    soc_if vif(clk);


    //========================================================
    // DUT
    //========================================================

    soc_top #(
        .UART_BAUD_TICK_MAX(10)
    )
    dut (

        .clk      (clk),

        .rst_i    (vif.rst_i),

        .gpio_in  (vif.gpio_in),

        .gpio_out (vif.gpio_out),

        .uart_rx  (vif.uart_rx),

        .uart_tx  (vif.uart_tx),

        .pwm_out  (vif.pwm_out)

    );


    //========================================================
    // AXI MONITOR CONNECTION
    //========================================================

    assign vif.m_axi_awaddr  = dut.m_axi_awaddr;
    assign vif.m_axi_awvalid = dut.m_axi_awvalid;
    assign vif.m_axi_awready = dut.m_axi_awready;

    assign vif.m_axi_wdata   = dut.m_axi_wdata;
    assign vif.m_axi_wstrb   = dut.m_axi_wstrb;
    assign vif.m_axi_wvalid  = dut.m_axi_wvalid;
    assign vif.m_axi_wready  = dut.m_axi_wready;

    assign vif.m_axi_bresp   = dut.m_axi_bresp;
    assign vif.m_axi_bvalid  = dut.m_axi_bvalid;
    assign vif.m_axi_bready  = dut.m_axi_bready;

    assign vif.m_axi_araddr  = dut.m_axi_araddr;
    assign vif.m_axi_arvalid = dut.m_axi_arvalid;
    assign vif.m_axi_arready = dut.m_axi_arready;

    assign vif.m_axi_rdata   = dut.m_axi_rdata;
    assign vif.m_axi_rresp   = dut.m_axi_rresp;
    assign vif.m_axi_rvalid  = dut.m_axi_rvalid;
    assign vif.m_axi_rready  = dut.m_axi_rready;


    //========================================================
    // TEST
    //========================================================

    soc_test test;


    initial begin

        //====================================================
        // INITIAL VALUES
        //====================================================

        vif.rst_i   = 1'b0;

        vif.gpio_in = 8'h00;

        vif.uart_rx = 1'b1;


        //====================================================
        // CREATE TEST
        //====================================================

        test = new(vif);


        //====================================================
        // RUN TEST
        //====================================================

        test.run();


        //====================================================
        // END SIMULATION
        //====================================================

        #10000;

        $finish;

    end


    //========================================================
    // START MESSAGE
    //========================================================

    initial begin

        $display("");
        $display("==============================================");
        $display("              TB_TOP STARTED");
        $display("==============================================");
        $display("");

    end

endmodule
