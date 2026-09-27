module axi_interconnect #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic clk,
    input  logic rst,

    input  logic [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  logic                  s_axi_awvalid,
    output logic                  s_axi_awready,

    input  logic [DATA_WIDTH-1:0]   s_axi_wdata,
    input  logic [DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  logic                    s_axi_wvalid,
    output logic                    s_axi_wready,

    output logic [1:0] s_axi_bresp,
    output logic       s_axi_bvalid,
    input  logic       s_axi_bready,

    input  logic [ADDR_WIDTH-1:0] s_axi_araddr,
    input  logic                  s_axi_arvalid,
    output logic                  s_axi_arready,

    output logic [DATA_WIDTH-1:0] s_axi_rdata,
    output logic [1:0]            s_axi_rresp,
    output logic                  s_axi_rvalid,
    input  logic                  s_axi_rready,

    // GPIO SLAVE
    output logic [ADDR_WIDTH-1:0] gpio_awaddr,
    output logic                  gpio_awvalid,
    input  logic                  gpio_awready,
    output logic [DATA_WIDTH-1:0]   gpio_wdata,
    output logic [DATA_WIDTH/8-1:0] gpio_wstrb,
    output logic                    gpio_wvalid,
    input  logic                    gpio_wready,
    input  logic [1:0] gpio_bresp,
    input  logic       gpio_bvalid,
    output logic       gpio_bready,
    output logic [ADDR_WIDTH-1:0] gpio_araddr,
    output logic                  gpio_arvalid,
    input  logic                  gpio_arready,
    input  logic [DATA_WIDTH-1:0] gpio_rdata,
    input  logic [1:0]            gpio_rresp,
    input  logic                  gpio_rvalid,
    output logic                  gpio_rready,

    // PWM SLAVE
    output logic [ADDR_WIDTH-1:0] pwm_awaddr,
    output logic                  pwm_awvalid,
    input  logic                  pwm_awready,
    output logic [DATA_WIDTH-1:0]   pwm_wdata,
    output logic [DATA_WIDTH/8-1:0] pwm_wstrb,
    output logic                    pwm_wvalid,
    input  logic                    pwm_wready,
    input  logic [1:0] pwm_bresp,
    input  logic       pwm_bvalid,
    output logic       pwm_bready,
    output logic [ADDR_WIDTH-1:0] pwm_araddr,
    output logic                  pwm_arvalid,
    input  logic                  pwm_arready,
    input  logic [DATA_WIDTH-1:0] pwm_rdata,
    input  logic [1:0]            pwm_rresp,
    input  logic                  pwm_rvalid,
    output logic                  pwm_rready,

    // TIMER SLAVE
    output logic [ADDR_WIDTH-1:0] timer_awaddr,
    output logic                  timer_awvalid,
    input  logic                  timer_awready,
    output logic [DATA_WIDTH-1:0]   timer_wdata,
    output logic [DATA_WIDTH/8-1:0] timer_wstrb,
    output logic                    timer_wvalid,
    input  logic                    timer_wready,
    input  logic [1:0] timer_bresp,
    input  logic       timer_bvalid,
    output logic       timer_bready,
    output logic [ADDR_WIDTH-1:0] timer_araddr,
    output logic                  timer_arvalid,
    input  logic                  timer_arready,
    input  logic [DATA_WIDTH-1:0] timer_rdata,
    input  logic [1:0]            timer_rresp,
    input  logic                  timer_rvalid,
    output logic                  timer_rready,

    // UART SLAVE
    output logic [ADDR_WIDTH-1:0] uart_awaddr,
    output logic                  uart_awvalid,
    input  logic                  uart_awready,
    output logic [DATA_WIDTH-1:0]   uart_wdata,
    output logic [DATA_WIDTH/8-1:0] uart_wstrb,
    output logic                    uart_wvalid,
    input  logic                    uart_wready,
    input  logic [1:0] uart_bresp,
    input  logic       uart_bvalid,
    output logic       uart_bready,
    output logic [ADDR_WIDTH-1:0] uart_araddr,
    output logic                  uart_arvalid,
    input  logic                  uart_arready,
    input  logic [DATA_WIDTH-1:0] uart_rdata,
    input  logic [1:0]            uart_rresp,
    input  logic                  uart_rvalid,
    output logic                  uart_rready
);

    localparam logic [ADDR_WIDTH-1:0] GPIO_BASE  = 32'h4000_0000;
    localparam logic [ADDR_WIDTH-1:0] PWM_BASE   = 32'h4000_1000;
    localparam logic [ADDR_WIDTH-1:0] TIMER_BASE = 32'h4000_2000;
    localparam logic [ADDR_WIDTH-1:0] UART_BASE  = 32'h4000_3000;

    localparam logic [ADDR_WIDTH-1:0] PERIPH_MASK = 32'hFFFF_F000;

    typedef enum logic [2:0] {
        SLAVE_NONE  = 3'd0,
        SLAVE_GPIO  = 3'd1,
        SLAVE_PWM   = 3'd2,
        SLAVE_TIMER = 3'd3,
        SLAVE_UART  = 3'd4
    } slave_sel_t;

    slave_sel_t write_slave;
    logic write_addr_received;

    slave_sel_t read_slave;
    logic read_addr_received;

    function automatic slave_sel_t decode_address(
        input logic [ADDR_WIDTH-1:0] address
    );
        begin
            if ((address & PERIPH_MASK) == (GPIO_BASE & PERIPH_MASK)) begin
                decode_address = SLAVE_GPIO;
            end
            else if ((address & PERIPH_MASK) == (PWM_BASE & PERIPH_MASK)) begin
                decode_address = SLAVE_PWM;
            end
            else if ((address & PERIPH_MASK) == (TIMER_BASE & PERIPH_MASK)) begin
                decode_address = SLAVE_TIMER;
            end
            else if ((address & PERIPH_MASK) == (UART_BASE & PERIPH_MASK)) begin
                decode_address = SLAVE_UART;
            end
            else begin
                decode_address = SLAVE_NONE;
            end
        end
    endfunction

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            write_slave         <= SLAVE_NONE;
            write_addr_received <= 1'b0;
        end else begin
            if (s_axi_awvalid && s_axi_awready) begin
                write_slave         <= decode_address(s_axi_awaddr);
                write_addr_received <= 1'b1;
            end
            if (s_axi_bvalid && s_axi_bready) begin
                write_slave         <= SLAVE_NONE;
                write_addr_received <= 1'b0;
            end
        end
    end

    always_comb begin
        gpio_awaddr  = s_axi_awaddr;
        pwm_awaddr   = s_axi_awaddr;
        timer_awaddr = s_axi_awaddr;
        uart_awaddr  = s_axi_awaddr;

        gpio_awvalid  = 1'b0;
        pwm_awvalid   = 1'b0;
        timer_awvalid = 1'b0;
        uart_awvalid  = 1'b0;

        if (s_axi_awvalid) begin
            case (decode_address(s_axi_awaddr))
                SLAVE_GPIO:  gpio_awvalid  = s_axi_awvalid;
                SLAVE_PWM:   pwm_awvalid   = s_axi_awvalid;
                SLAVE_TIMER: timer_awvalid = s_axi_awvalid;
                SLAVE_UART:  uart_awvalid  = s_axi_awvalid;
                default: begin
                    gpio_awvalid  = 1'b0;
                    pwm_awvalid   = 1'b0;
                    timer_awvalid = 1'b0;
                    uart_awvalid  = 1'b0;
                end
            endcase
        end
    end

    always_comb begin
        s_axi_awready = 1'b0;
        if (!write_addr_received) begin
            case (decode_address(s_axi_awaddr))
                SLAVE_GPIO:  s_axi_awready = gpio_awready;
                SLAVE_PWM:   s_axi_awready = pwm_awready;
                SLAVE_TIMER: s_axi_awready = timer_awready;
                SLAVE_UART:  s_axi_awready = uart_awready;
                SLAVE_NONE:  s_axi_awready = 1'b1;
                default:     s_axi_awready = 1'b0;
            endcase
        end
    end

    always_comb begin
        gpio_wdata  = s_axi_wdata;
        pwm_wdata   = s_axi_wdata;
        timer_wdata = s_axi_wdata;
        uart_wdata  = s_axi_wdata;

        gpio_wstrb  = s_axi_wstrb;
        pwm_wstrb   = s_axi_wstrb;
        timer_wstrb = s_axi_wstrb;
        uart_wstrb  = s_axi_wstrb;

        gpio_wvalid  = 1'b0;
        pwm_wvalid   = 1'b0;
        timer_wvalid = 1'b0;
        uart_wvalid  = 1'b0;

        if (s_axi_wvalid && write_addr_received) begin
            case (write_slave)
                SLAVE_GPIO:  gpio_wvalid  = s_axi_wvalid;
                SLAVE_PWM:   pwm_wvalid   = s_axi_wvalid;
                SLAVE_TIMER: timer_wvalid = s_axi_wvalid;
                SLAVE_UART:  uart_wvalid  = s_axi_wvalid;
                default: begin
                    gpio_wvalid  = 1'b0;
                    pwm_wvalid   = 1'b0;
                    timer_wvalid = 1'b0;
                    uart_wvalid  = 1'b0;
                end
            endcase
        end
    end

    always_comb begin
        s_axi_wready = 1'b0;
        if (write_addr_received) begin
            case (write_slave)
                SLAVE_GPIO:  s_axi_wready = gpio_wready;
                SLAVE_PWM:   s_axi_wready = pwm_wready;
                SLAVE_TIMER: s_axi_wready = timer_wready;
                SLAVE_UART:  s_axi_wready = uart_wready;
                SLAVE_NONE:  s_axi_wready = 1'b1;
                default:     s_axi_wready = 1'b0;
            endcase
        end
    end

    always_comb begin
        s_axi_bvalid = 1'b0;
        s_axi_bresp  = 2'b00;

        gpio_bready  = 1'b0;
        pwm_bready   = 1'b0;
        timer_bready = 1'b0;
        uart_bready  = 1'b0;

        case (write_slave)
            SLAVE_GPIO: begin
                s_axi_bvalid = gpio_bvalid;
                s_axi_bresp  = gpio_bresp;
                gpio_bready  = s_axi_bready;
            end
            SLAVE_PWM: begin
                s_axi_bvalid = pwm_bvalid;
                s_axi_bresp  = pwm_bresp;
                pwm_bready   = s_axi_bready;
            end
            SLAVE_TIMER: begin
                s_axi_bvalid = timer_bvalid;
                s_axi_bresp  = timer_bresp;
                timer_bready = s_axi_bready;
            end
            SLAVE_UART: begin
                s_axi_bvalid = uart_bvalid;
                s_axi_bresp  = uart_bresp;
                uart_bready  = s_axi_bready;
            end
            SLAVE_NONE: begin
                s_axi_bvalid = write_addr_received && s_axi_wvalid && s_axi_wready;
                s_axi_bresp  = 2'b10;
            end
            default: begin
                s_axi_bvalid = 1'b0;
                s_axi_bresp  = 2'b00;
            end
        endcase
    end

    always_comb begin
        s_axi_arready = 1'b0;
        if (!read_addr_received) begin
            case (decode_address(s_axi_araddr))
                SLAVE_GPIO:  s_axi_arready = gpio_arready;
                SLAVE_PWM:   s_axi_arready = pwm_arready;
                SLAVE_TIMER: s_axi_arready = timer_arready;
                SLAVE_UART:  s_axi_arready = uart_arready;
                SLAVE_NONE:  s_axi_arready = 1'b1;
                default:     s_axi_arready = 1'b0;
            endcase
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            read_slave         <= SLAVE_NONE;
            read_addr_received <= 1'b0;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                read_slave         <= decode_address(s_axi_araddr);
                read_addr_received <= 1'b1;
            end
            if (s_axi_rvalid && s_axi_rready) begin
                read_slave         <= SLAVE_NONE;
                read_addr_received <= 1'b0;
            end
        end
    end

    always_comb begin
        gpio_araddr  = s_axi_araddr;
        pwm_araddr   = s_axi_araddr;
        timer_araddr = s_axi_araddr;
        uart_araddr  = s_axi_araddr;

        gpio_arvalid  = 1'b0;
        pwm_arvalid   = 1'b0;
        timer_arvalid = 1'b0;
        uart_arvalid  = 1'b0;

        if (s_axi_arvalid) begin
            case (decode_address(s_axi_araddr))
                SLAVE_GPIO:  gpio_arvalid  = s_axi_arvalid;
                SLAVE_PWM:   pwm_arvalid   = s_axi_arvalid;
                SLAVE_TIMER: timer_arvalid = s_axi_arvalid;
                SLAVE_UART:  uart_arvalid  = s_axi_arvalid;
                default: begin
                    gpio_arvalid  = 1'b0;
                    pwm_arvalid   = 1'b0;
                    timer_arvalid = 1'b0;
                    uart_arvalid  = 1'b0;
                end
            endcase
        end
    end

    always_comb begin
        s_axi_rvalid = 1'b0;
        s_axi_rdata  = '0;
        s_axi_rresp  = 2'b00;

        gpio_rready  = 1'b0;
        pwm_rready   = 1'b0;
        timer_rready = 1'b0;
        uart_rready  = 1'b0;

        case (read_slave)
            SLAVE_GPIO: begin
                s_axi_rvalid = gpio_rvalid;
                s_axi_rdata  = gpio_rdata;
                s_axi_rresp  = gpio_rresp;
                gpio_rready  = s_axi_rready;
            end
            SLAVE_PWM: begin
                s_axi_rvalid = pwm_rvalid;
                s_axi_rdata  = pwm_rdata;
                s_axi_rresp  = pwm_rresp;
                pwm_rready   = s_axi_rready;
            end
            SLAVE_TIMER: begin
                s_axi_rvalid = timer_rvalid;
                s_axi_rdata  = timer_rdata;
                s_axi_rresp  = timer_rresp;
                timer_rready = s_axi_rready;
            end
            SLAVE_UART: begin
                s_axi_rvalid = uart_rvalid;
                s_axi_rdata  = uart_rdata;
                s_axi_rresp  = uart_rresp;
                uart_rready  = s_axi_rready;
            end
            SLAVE_NONE: begin
                s_axi_rvalid = read_addr_received;
                s_axi_rdata  = '0;
                s_axi_rresp  = 2'b10;
            end
            default: begin
                s_axi_rvalid = 1'b0;
                s_axi_rdata  = '0;
                s_axi_rresp  = 2'b00;
            end
        endcase
    end

endmodule
