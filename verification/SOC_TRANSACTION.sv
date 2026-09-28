class soc_transaction;

    //========================================================
    // TEST TYPE
    //========================================================

    typedef enum {

        RESET_TEST,
        GPIO_TEST,
        PWM_TEST,
        TIMER_TEST,
        UART_TEST,
        AXI_TEST,
        INVALID_ACCESS

    } test_type_e;

    test_type_e test_type;


    //========================================================
    // GENERIC INFORMATION
    //========================================================

    bit [31:0] address;
    bit [31:0] data;
    bit [3:0]  strb;


    //========================================================
    // GPIO
    //========================================================

    bit [7:0] gpio_value;
    bit [7:0] expected_gpio;


    //========================================================
    // PWM
    //========================================================

    bit [31:0] pwm_period;
    bit [31:0] pwm_duty;

    bit expected_pwm;


    //========================================================
    // TIMER
    //========================================================

    bit [31:0] timer_value;

    bit expected_timer;


    //========================================================
    // UART
    //========================================================

    bit [7:0] uart_data;

    bit [7:0] expected_uart;


    //========================================================
    // AXI
    //========================================================

    bit [31:0] axi_address;
    bit [31:0] axi_wdata;
    bit [31:0] axi_rdata;

    bit [3:0] axi_wstrb;

    bit axi_write;
    bit axi_read;

    bit [1:0] axi_bresp;
    bit [1:0] axi_rresp;


    //========================================================
    // CONSTRUCTOR
    //========================================================

    function new();

        test_type = RESET_TEST;

        address = 32'h0000_0000;
        data    = 32'h0000_0000;
        strb    = 4'h0;


        // GPIO
        gpio_value    = 8'h00;
        expected_gpio = 8'h00;


        // PWM
        pwm_period   = 32'd0;
        pwm_duty     = 32'd0;
        expected_pwm = 1'b0;


        // TIMER
        timer_value    = 32'd0;
        expected_timer = 1'b0;


        // UART
        uart_data     = 8'h00;
        expected_uart = 8'h00;


        // AXI
        axi_address = 32'h0000_0000;
        axi_wdata   = 32'h0000_0000;
        axi_rdata   = 32'h0000_0000;

        axi_wstrb = 4'h0;

        axi_write = 1'b0;
        axi_read  = 1'b0;

        axi_bresp = 2'b00;
        axi_rresp = 2'b00;

    endfunction


    //========================================================
    // CLONE
    //========================================================

    function soc_transaction clone();

        soc_transaction tr;

        tr = new();

        tr.test_type = this.test_type;

        tr.address = this.address;
        tr.data    = this.data;
        tr.strb    = this.strb;


        // GPIO
        tr.gpio_value    = this.gpio_value;
        tr.expected_gpio = this.expected_gpio;


        // PWM
        tr.pwm_period   = this.pwm_period;
        tr.pwm_duty     = this.pwm_duty;
        tr.expected_pwm = this.expected_pwm;


        // TIMER
        tr.timer_value    = this.timer_value;
        tr.expected_timer = this.expected_timer;


        // UART
        tr.uart_data     = this.uart_data;
        tr.expected_uart = this.expected_uart;


        // AXI
        tr.axi_address = this.axi_address;
        tr.axi_wdata   = this.axi_wdata;
        tr.axi_rdata   = this.axi_rdata;

        tr.axi_wstrb = this.axi_wstrb;

        tr.axi_write = this.axi_write;
        tr.axi_read  = this.axi_read;

        tr.axi_bresp = this.axi_bresp;
        tr.axi_rresp = this.axi_rresp;

        return tr;

    endfunction


    //========================================================
    // DISPLAY
    //========================================================

    function void display();

        $display("--------------------------------------------");

        case (test_type)

            RESET_TEST:
                $display("TRANSACTION : RESET");

            GPIO_TEST:
                $display("TRANSACTION : GPIO");

            PWM_TEST:
                $display("TRANSACTION : PWM");

            TIMER_TEST:
                $display("TRANSACTION : TIMER");

            UART_TEST:
                $display("TRANSACTION : UART");

            AXI_TEST:
                $display("TRANSACTION : AXI");

            INVALID_ACCESS:
                $display("TRANSACTION : INVALID ACCESS");

            default:
                $display("TRANSACTION : UNKNOWN");

        endcase


        $display("ADDRESS = %08h", address);
        $display("DATA    = %08h", data);
        $display("STRB    = %b", strb);

        $display("--------------------------------------------");

    endfunction

endclass