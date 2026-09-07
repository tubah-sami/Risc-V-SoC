module axi_master_lite #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic clk,
    input  logic rst,

    // INTERNAL / CPU-SIDE REQUEST INTERFACE
    input  logic                     req_valid,
    input  logic                     req_write,
    input  logic [ADDR_WIDTH-1:0]     req_addr,
    input  logic [DATA_WIDTH-1:0]     req_wdata,
    input  logic [DATA_WIDTH/8-1:0]   req_wstrb,

    output logic                     req_ready,

    // Response to CPU
    output logic                     resp_valid,
    output logic [DATA_WIDTH-1:0]     resp_rdata,
    output logic                     resp_error,


    // AXI4-LITE WRITE ADDRESS CHANNEL
  

    output logic [ADDR_WIDTH-1:0]     m_axi_awaddr,
    output logic                     m_axi_awvalid,
    input  logic                     m_axi_awready,


    
    // AXI4-LITE WRITE DATA CHANNEL

    output logic [DATA_WIDTH-1:0]     m_axi_wdata,
    output logic [DATA_WIDTH/8-1:0]   m_axi_wstrb,
    output logic                     m_axi_wvalid,
    input  logic                     m_axi_wready,

    // AXI4-LITE WRITE RESPONSE CHANNEL

    input  logic [1:0]               m_axi_bresp,
    input  logic                     m_axi_bvalid,
    output logic                     m_axi_bready,


    // AXI4-LITE READ ADDRESS CHANNEL

    output logic [ADDR_WIDTH-1:0]     m_axi_araddr,
    output logic                     m_axi_arvalid,
    input  logic                     m_axi_arready,

    // AXI4-LITE READ DATA CHANNEL

    input  logic [DATA_WIDTH-1:0]     m_axi_rdata,
    input  logic [1:0]               m_axi_rresp,
    input  logic                     m_axi_rvalid,
    output logic                     m_axi_rready
);


    typedef enum logic [2:0] {
        IDLE,
        WRITE_ADDR,
        WRITE_DATA,
        WRITE_RESP,
        READ_ADDR,
        READ_DATA
    } state_t;

    state_t state;


    // INTERNAL REGISTERS


    logic [ADDR_WIDTH-1:0]   addr_reg;
    logic [DATA_WIDTH-1:0]   wdata_reg;
    logic [DATA_WIDTH/8-1:0] wstrb_reg;

    // REQUEST READY


    assign req_ready = (state == IDLE);

    always_comb begin

        // Default values
        m_axi_awaddr  = addr_reg;
        m_axi_awvalid = 1'b0;

        m_axi_wdata   = wdata_reg;
        m_axi_wstrb   = wstrb_reg;
        m_axi_wvalid  = 1'b0;

        m_axi_bready  = 1'b0;

        m_axi_araddr  = addr_reg;
        m_axi_arvalid = 1'b0;

        m_axi_rready  = 1'b0;



        if (state == WRITE_ADDR) begin
            m_axi_awvalid = 1'b1;
        end


        if (state == WRITE_DATA) begin
            m_axi_wvalid = 1'b1;
        end


        if (state == WRITE_RESP) begin
            m_axi_bready = 1'b1;
        end



        if (state == READ_ADDR) begin
            m_axi_arvalid = 1'b1;
        end

        if (state == READ_DATA) begin
            m_axi_rready = 1'b1;
        end

    end


    always_comb begin

        resp_valid = 1'b0;
        resp_rdata = '0;
        resp_error = 1'b0;

        // Write response
        if ((state == WRITE_RESP) && m_axi_bvalid) begin

            resp_valid = 1'b1;

            if (m_axi_bresp != 2'b00)
                resp_error = 1'b1;

        end


        // Read response
        if ((state == READ_DATA) && m_axi_rvalid) begin

            resp_valid = 1'b1;
            resp_rdata = m_axi_rdata;

            if (m_axi_rresp != 2'b00)
                resp_error = 1'b1;

        end

    end


    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            state     <= IDLE;

            addr_reg  <= '0;
            wdata_reg <= '0;
            wstrb_reg <= '0;

        end

        else begin

            case (state)


                IDLE: begin

                    if (req_valid && req_ready) begin

                        // Save request
                        addr_reg  <= req_addr;
                        wdata_reg <= req_wdata;
                        wstrb_reg <= req_wstrb;

                        if (req_write)
                            state <= WRITE_ADDR;
                        else
                            state <= READ_ADDR;

                    end

                end


                WRITE_ADDR: begin

                    if (m_axi_awvalid && m_axi_awready) begin
                        state <= WRITE_DATA;
                    end

                end

                WRITE_DATA: begin

                    if (m_axi_wvalid && m_axi_wready) begin
                        state <= WRITE_RESP;
                    end

                end


                WRITE_RESP: begin

                    if (m_axi_bvalid && m_axi_bready) begin
                        state <= IDLE;
                    end

                end

                READ_ADDR: begin

                    if (m_axi_arvalid && m_axi_arready) begin
                        state <= READ_DATA;
                    end

                end

                READ_DATA: begin

                    if (m_axi_rvalid && m_axi_rready) begin
                        state <= IDLE;
                    end

                end
         
                default: begin
                    state <= IDLE;
                end

            endcase

        end

    end

endmodule
