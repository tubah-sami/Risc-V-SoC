interface soc_if(input logic clk);

    //========================================================
    // External DUT inputs
    //========================================================

    logic        rst_i;
    logic [7:0]  gpio_in;
    logic        uart_rx;

    //========================================================
    // External DUT outputs
    //========================================================

    logic [7:0]  gpio_out;
    logic        uart_tx;
    logic        pwm_out;


    //========================================================
    // AXI4-Lite MASTER MONITOR SIGNALS
    // These mirror the internal AXI master signals in soc_top
    //========================================================

    logic [31:0] m_axi_awaddr;
    logic        m_axi_awvalid;
    logic        m_axi_awready;

    logic [31:0] m_axi_wdata;
    logic [3:0]  m_axi_wstrb;
    logic        m_axi_wvalid;
    logic        m_axi_wready;

    logic [1:0]  m_axi_bresp;
    logic        m_axi_bvalid;
    logic        m_axi_bready;

    logic [31:0] m_axi_araddr;
    logic        m_axi_arvalid;
    logic        m_axi_arready;

    logic [31:0] m_axi_rdata;
    logic [1:0]  m_axi_rresp;
    logic        m_axi_rvalid;
    logic        m_axi_rready;

endinterface
