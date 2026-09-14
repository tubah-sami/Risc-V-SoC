`include "RISCV_PKG.vh"

module soc_top #(
    parameter integer UART_BAUD_TICK_MAX = 434  // 50MHz/115200 by default; override for faster sim
) (
    input  wire        clk,

    // Raw external reset pin - asynchronous, active-HIGH (e.g. driven by a
    // POR cell / external reset button, can assert or glitch at any time,
    // with no relationship to clk). This is NOT distributed directly to
    // the design - see the reset synchronizer below.
    input  wire        rst_i,

    // -------------------- GPIO pins --------------------
    input  wire [7:0]  gpio_in,
    output wire [7:0]  gpio_out,

    // -------------------- UART pins --------------------
    input  wire        uart_rx,
    output wire        uart_tx,

    // -------------------- PWM pin --------------------
    output wire         pwm_out
);

    // ============================================================
    // Reset synchronizer (assert-async / de-assert-sync)
    // ============================================================
    // One clean reset is generated here and fanned out to the whole
    // chip, instead of every module independently sampling the raw
    // async pin. rst_i can assert (or glitch) at any time and takes
    // effect immediately (async set on the first flop), but it only
    // de-asserts synchronously with clk, two flops later - this is
    // what avoids reset-removal (recovery) timing violations at the
    // fan-out registers and gives Innovus/Genus a clean, well-defined
    // reset tree instead of ad-hoc `~rst` inversions scattered per
    // instance driving directly off a raw pin.
    //
    // `rst` below (active-HIGH, synchronously de-asserted) is the one
    // signal used everywhere downstream in this module - the core,
    // the AXI master/interconnect, and all 4 peripheral wrappers.
    reg rst_sync_ff1, rst_sync_ff2;
    always @(posedge clk or posedge rst_i) begin
        if (rst_i) begin
            rst_sync_ff1 <= 1'b1;
            rst_sync_ff2 <= 1'b1;
        end else begin
            rst_sync_ff1 <= 1'b0;
            rst_sync_ff2 <= rst_sync_ff1;
        end
    end
    wire rst = rst_sync_ff2;   // clean, active-HIGH, sync-de-asserted

    // -------------------- Instruction memory --------------------
    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;

    // -------------------- Data SRAM --------------------
    wire [31:0] dsram_addr;
    wire [31:0] dsram_wdata;
    wire        dsram_we;
    wire [3:0]  dsram_be;
    wire        dsram_ce;
    wire [31:0] dsram_rdata;

    // -------------------- Peripheral port (from core) --------------------
    wire [31:0] periph_addr;
    wire [31:0] periph_wdata;
    wire        periph_we;
    wire        periph_re;
    wire [3:0]  periph_be;
    wire        periph_valid;
    wire [31:0] periph_rdata;
    wire        periph_ack;

    // ============================================================
    // RISC-V Core
    // ============================================================
    RV32I_Core u_core (
        .clk         (clk),
        .rst         (rst),
        .imem_addr   (imem_addr),
        .imem_rdata  (imem_rdata),
        .dsram_addr  (dsram_addr),
        .dsram_wdata (dsram_wdata),
        .dsram_we    (dsram_we),
        .dsram_be    (dsram_be),
        .dsram_ce    (dsram_ce),
        .dsram_rdata (dsram_rdata),
        .periph_addr  (periph_addr),
        .periph_wdata (periph_wdata),
        .periph_we    (periph_we),
        .periph_re    (periph_re),
        .periph_be    (periph_be),
        .periph_valid (periph_valid),
        .periph_rdata (periph_rdata),
        .periph_ack   (periph_ack)
    );

    // ============================================================
    // Instruction / Data SRAM
    // ============================================================
    InstrSRAM u_imem (
        .clk   (clk),
        .ce    (1'b1),
        .addr  (imem_addr),
        .rdata (imem_rdata)
    );

    DataSRAM u_dmem (
        .clk   (clk),
        .ce    (dsram_ce),
        .addr  (dsram_addr),
        .wdata (dsram_wdata),
        .we    (dsram_we),
        .be    (dsram_be),
        .rdata (dsram_rdata)
    );

    // ============================================================
    // AXI4-Lite Master
    // ============================================================
    wire [31:0] m_axi_awaddr, m_axi_wdata, m_axi_araddr, m_axi_rdata;
    wire [3:0]  m_axi_wstrb;
    wire        m_axi_awvalid, m_axi_awready;
    wire        m_axi_wvalid, m_axi_wready;
    wire [1:0]  m_axi_bresp;
    wire        m_axi_bvalid, m_axi_bready;
    wire        m_axi_arvalid, m_axi_arready;
    wire [1:0]  m_axi_rresp;
    wire        m_axi_rvalid, m_axi_rready;

    axi_master_lite u_master (
        .clk           (clk),
        .rst           (rst),
        .req_valid     (periph_valid),
        .req_write     (periph_we),
        .req_addr      (periph_addr),
        .req_wdata     (periph_wdata),
        .req_wstrb     (periph_be),
        .req_ready     (),
        .resp_valid    (periph_ack),
        .resp_rdata    (periph_rdata),
        .resp_error    (),
        .m_axi_awaddr  (m_axi_awaddr),
        .m_axi_awvalid (m_axi_awvalid),
        .m_axi_awready (m_axi_awready),
        .m_axi_wdata   (m_axi_wdata),
        .m_axi_wstrb   (m_axi_wstrb),
        .m_axi_wvalid  (m_axi_wvalid),
        .m_axi_wready  (m_axi_wready),
        .m_axi_bresp   (m_axi_bresp),
        .m_axi_bvalid  (m_axi_bvalid),
        .m_axi_bready  (m_axi_bready),
        .m_axi_araddr  (m_axi_araddr),
        .m_axi_arvalid (m_axi_arvalid),
        .m_axi_arready (m_axi_arready),
        .m_axi_rdata   (m_axi_rdata),
        .m_axi_rresp   (m_axi_rresp),
        .m_axi_rvalid  (m_axi_rvalid),
        .m_axi_rready  (m_axi_rready)
    );

    // ============================================================
    // Per-peripheral AXI signal groups (interconnect <-> peripheral)
    // ============================================================
    // GPIO
    wire [31:0] gpio_awaddr, gpio_wdata, gpio_araddr, gpio_rdata;
    wire [3:0]  gpio_wstrb;
    wire        gpio_awvalid, gpio_awready, gpio_wvalid, gpio_wready;
    wire [1:0]  gpio_bresp;
    wire        gpio_bvalid, gpio_bready;
    wire        gpio_arvalid, gpio_arready;
    wire [1:0]  gpio_rresp;
    wire        gpio_rvalid, gpio_rready;

    // PWM
    wire [31:0] pwm_awaddr, pwm_wdata, pwm_araddr, pwm_rdata;
    wire [3:0]  pwm_wstrb;
    wire        pwm_awvalid, pwm_awready, pwm_wvalid, pwm_wready;
    wire [1:0]  pwm_bresp;
    wire        pwm_bvalid, pwm_bready;
    wire        pwm_arvalid, pwm_arready;
    wire [1:0]  pwm_rresp;
    wire        pwm_rvalid, pwm_rready;

    // TIMER
    wire [31:0] timer_awaddr, timer_wdata, timer_araddr, timer_rdata;
    wire [3:0]  timer_wstrb;
    wire        timer_awvalid, timer_awready, timer_wvalid, timer_wready;
    wire [1:0]  timer_bresp;
    wire        timer_bvalid, timer_bready;
    wire        timer_arvalid, timer_arready;
    wire [1:0]  timer_rresp;
    wire        timer_rvalid, timer_rready;

    // UART
    wire [31:0] uart_awaddr, uart_wdata, uart_araddr, uart_rdata;
    wire [3:0]  uart_wstrb;
    wire        uart_awvalid, uart_awready, uart_wvalid, uart_wready;
    wire [1:0]  uart_bresp;
    wire        uart_bvalid, uart_bready;
    wire        uart_arvalid, uart_arready;
    wire [1:0]  uart_rresp;
    wire        uart_rvalid, uart_rready;

    // ============================================================
    // AXI Interconnect
    // ============================================================
    axi_interconnect u_interconnect (
        .clk (clk), .rst (rst),

        .s_axi_awaddr  (m_axi_awaddr),  .s_axi_awvalid (m_axi_awvalid), .s_axi_awready (m_axi_awready),
        .s_axi_wdata   (m_axi_wdata),   .s_axi_wstrb   (m_axi_wstrb),   .s_axi_wvalid  (m_axi_wvalid),  .s_axi_wready (m_axi_wready),
        .s_axi_bresp   (m_axi_bresp),   .s_axi_bvalid  (m_axi_bvalid),  .s_axi_bready  (m_axi_bready),
        .s_axi_araddr  (m_axi_araddr),  .s_axi_arvalid (m_axi_arvalid), .s_axi_arready (m_axi_arready),
        .s_axi_rdata   (m_axi_rdata),   .s_axi_rresp   (m_axi_rresp),   .s_axi_rvalid  (m_axi_rvalid),  .s_axi_rready (m_axi_rready),

        .gpio_awaddr (gpio_awaddr), .gpio_awvalid (gpio_awvalid), .gpio_awready (gpio_awready),
        .gpio_wdata  (gpio_wdata),  .gpio_wstrb   (gpio_wstrb),   .gpio_wvalid  (gpio_wvalid), .gpio_wready (gpio_wready),
        .gpio_bresp  (gpio_bresp),  .gpio_bvalid  (gpio_bvalid),  .gpio_bready  (gpio_bready),
        .gpio_araddr (gpio_araddr), .gpio_arvalid (gpio_arvalid), .gpio_arready (gpio_arready),
        .gpio_rdata  (gpio_rdata),  .gpio_rresp   (gpio_rresp),   .gpio_rvalid  (gpio_rvalid), .gpio_rready (gpio_rready),

        .pwm_awaddr (pwm_awaddr), .pwm_awvalid (pwm_awvalid), .pwm_awready (pwm_awready),
        .pwm_wdata  (pwm_wdata),  .pwm_wstrb   (pwm_wstrb),   .pwm_wvalid  (pwm_wvalid), .pwm_wready (pwm_wready),
        .pwm_bresp  (pwm_bresp),  .pwm_bvalid  (pwm_bvalid),  .pwm_bready  (pwm_bready),
        .pwm_araddr (pwm_araddr), .pwm_arvalid (pwm_arvalid), .pwm_arready (pwm_arready),
        .pwm_rdata  (pwm_rdata),  .pwm_rresp   (pwm_rresp),   .pwm_rvalid  (pwm_rvalid), .pwm_rready (pwm_rready),

        .timer_awaddr (timer_awaddr), .timer_awvalid (timer_awvalid), .timer_awready (timer_awready),
        .timer_wdata  (timer_wdata),  .timer_wstrb   (timer_wstrb),   .timer_wvalid  (timer_wvalid), .timer_wready (timer_wready),
        .timer_bresp  (timer_bresp),  .timer_bvalid  (timer_bvalid),  .timer_bready  (timer_bready),
        .timer_araddr (timer_araddr), .timer_arvalid (timer_arvalid), .timer_arready (timer_arready),
        .timer_rdata  (timer_rdata),  .timer_rresp   (timer_rresp),   .timer_rvalid  (timer_rvalid), .timer_rready (timer_rready),

        .uart_awaddr (uart_awaddr), .uart_awvalid (uart_awvalid), .uart_awready (uart_awready),
        .uart_wdata  (uart_wdata),  .uart_wstrb   (uart_wstrb),   .uart_wvalid  (uart_wvalid), .uart_wready (uart_wready),
        .uart_bresp  (uart_bresp),  .uart_bvalid  (uart_bvalid),  .uart_bready  (uart_bready),
        .uart_araddr (uart_araddr), .uart_arvalid (uart_arvalid), .uart_arready (uart_arready),
        .uart_rdata  (uart_rdata),  .uart_rresp   (uart_rresp),   .uart_rvalid  (uart_rvalid), .uart_rready (uart_rready)
    );

    // ============================================================
    // Peripherals
    // (gpio_out, pwm_out, uart_tx, gpio_in, uart_rx are now real
    //  top-level chip pins declared in the port list above, not
    //  internal-only wires - required for Innovus to build the
    //  floorplan / IO ring.)
    // ============================================================
    axi4lite_gpio u_gpio (
        .clk (clk), .rst (rst),
        .s_axi_awaddr (gpio_awaddr), .s_axi_awvalid (gpio_awvalid), .s_axi_awready (gpio_awready),
        .s_axi_wdata  (gpio_wdata),  .s_axi_wstrb   (gpio_wstrb),   .s_axi_wvalid  (gpio_wvalid),  .s_axi_wready (gpio_wready),
        .s_axi_bresp  (gpio_bresp),  .s_axi_bvalid  (gpio_bvalid),  .s_axi_bready  (gpio_bready),
        .s_axi_araddr (gpio_araddr), .s_axi_arvalid (gpio_arvalid), .s_axi_arready (gpio_arready),
        .s_axi_rdata  (gpio_rdata),  .s_axi_rresp   (gpio_rresp),   .s_axi_rvalid  (gpio_rvalid),  .s_axi_rready (gpio_rready),
        .gpio_in (gpio_in), .gpio_out (gpio_out)
    );

    axi4lite_pwm u_pwm (
        .clk (clk), .rst (rst),
        .s_axi_awaddr (pwm_awaddr), .s_axi_awvalid (pwm_awvalid), .s_axi_awready (pwm_awready),
        .s_axi_wdata  (pwm_wdata),  .s_axi_wstrb   (pwm_wstrb),   .s_axi_wvalid  (pwm_wvalid),  .s_axi_wready (pwm_wready),
        .s_axi_bresp  (pwm_bresp),  .s_axi_bvalid  (pwm_bvalid),  .s_axi_bready  (pwm_bready),
        .s_axi_araddr (pwm_araddr), .s_axi_arvalid (pwm_arvalid), .s_axi_arready (pwm_arready),
        .s_axi_rdata  (pwm_rdata),  .s_axi_rresp   (pwm_rresp),   .s_axi_rvalid  (pwm_rvalid),  .s_axi_rready (pwm_rready),
        .pwm_out (pwm_out)
    );

    axi4lite_timer u_timer (
        .clk (clk), .rst (rst),
        .s_axi_awaddr (timer_awaddr), .s_axi_awvalid (timer_awvalid), .s_axi_awready (timer_awready),
        .s_axi_wdata  (timer_wdata),  .s_axi_wstrb   (timer_wstrb),   .s_axi_wvalid  (timer_wvalid),  .s_axi_wready (timer_wready),
        .s_axi_bresp  (timer_bresp),  .s_axi_bvalid  (timer_bvalid),  .s_axi_bready  (timer_bready),
        .s_axi_araddr (timer_araddr), .s_axi_arvalid (timer_arvalid), .s_axi_arready (timer_arready),
        .s_axi_rdata  (timer_rdata),  .s_axi_rresp   (timer_rresp),   .s_axi_rvalid  (timer_rvalid),  .s_axi_rready (timer_rready)
    );

    axi4lite_uart #(.BAUD_TICK_MAX(UART_BAUD_TICK_MAX)) u_uart (
        .clk (clk), .rst (rst),
        .s_axi_awaddr (uart_awaddr), .s_axi_awvalid (uart_awvalid), .s_axi_awready (uart_awready),
        .s_axi_wdata  (uart_wdata),  .s_axi_wstrb   (uart_wstrb),   .s_axi_wvalid  (uart_wvalid),  .s_axi_wready (uart_wready),
        .s_axi_bresp  (uart_bresp),  .s_axi_bvalid  (uart_bvalid),  .s_axi_bready  (uart_bready),
        .s_axi_araddr (uart_araddr), .s_axi_arvalid (uart_arvalid), .s_axi_arready (uart_arready),
        .s_axi_rdata  (uart_rdata),  .s_axi_rresp   (uart_rresp),   .s_axi_rvalid  (uart_rvalid),  .s_axi_rready (uart_rready),
        .uart_rx (uart_rx), .uart_tx (uart_tx)
    );

endmodule
