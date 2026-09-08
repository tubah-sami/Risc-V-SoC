`timescale 1ns/1ps

// Register Map (byte offsets):
//   0x00  TX_DATA   W     writing a byte here triggers transmit
//   0x04  RX_DATA   R     last received byte (clears rx_done on read)
//   0x08  STATUS    R     bit[0] = tx_busy, bit[1] = rx_done

module axi4lite_uart #(
    parameter integer BAUD_TICK_MAX = 434 // 50MHz / 115200
)(
    input  logic         clk,
    input  logic         rst,             

    input  logic [31:0]  s_axi_awaddr,
    input  logic         s_axi_awvalid,
    output logic         s_axi_awready,

    input  logic [31:0]  s_axi_wdata,
    input  logic [3:0]   s_axi_wstrb,
    input  logic         s_axi_wvalid,
    output logic         s_axi_wready,

    output logic [1:0]   s_axi_bresp,
    output logic         s_axi_bvalid,
    input  logic         s_axi_bready,

    input  logic [31:0]  s_axi_araddr,
    input  logic         s_axi_arvalid,
    output logic         s_axi_arready,

    output logic [31:0]  s_axi_rdata,
    output logic [1:0]   s_axi_rresp,
    output logic         s_axi_rvalid,
    input  logic         s_axi_rready,

    input  logic         uart_rx,
    output logic         uart_tx
);

    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_SLVERR = 2'b10;

    // 2-stage synchronizer for incoming async UART_RX signal

    logic rx_sync0, rx_sync1;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_sync0 <= 1'b1;
            rx_sync1 <= 1'b1;
        end else begin
            rx_sync0 <= uart_rx;
            rx_sync1 <= rx_sync0;
        end
    end

    logic [7:0] rx_byte_w;
    logic       rx_done_w;
    logic       tx_busy_w;

    logic [7:0] tx_data_reg;
    logic       tx_start_pulse;
    logic [7:0] rx_data_reg;
    logic       rx_done_flag;

    // RX capture (independent of AXI, always running)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_data_reg  <= 8'h00;
            rx_done_flag <= 1'b0;
        end else begin
            if (rx_done_w) begin
                rx_data_reg  <= rx_byte_w;
                rx_done_flag <= 1'b1;
            end
            else if (s_axi_arvalid && s_axi_arready && s_axi_araddr[3:0] == 4'h4) begin
                rx_done_flag <= 1'b0; // clear on RX_DATA read
            end
        end
    end

 
    // Write FSM (TX_DATA only)

    typedef enum logic [1:0] {W_IDLE, W_DATA, W_RESP} wr_state_t;
    wr_state_t wr_state;
    logic [31:0] awaddr_latched;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_state       <= W_IDLE;
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= RESP_OKAY;
            awaddr_latched <= '0;
            tx_data_reg    <= 8'h00;
            tx_start_pulse <= 1'b0;
        end else begin
            tx_start_pulse <= 1'b0; // default: 1-cycle pulse
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;

            case (wr_state)
                W_IDLE: begin
                    s_axi_bvalid <= 1'b0;
                    if (s_axi_awvalid) begin
                        s_axi_awready  <= 1'b1;
                        awaddr_latched <= s_axi_awaddr;
                        wr_state       <= W_DATA;
                    end
                end

                W_DATA: begin
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b1;

                        if (awaddr_latched[11:4] != 8'd0) begin
                            s_axi_bresp <= RESP_SLVERR; // outside this peripheral's 16-byte range
                        end else if (awaddr_latched[3:0] == 4'h0) begin
                            tx_data_reg    <= s_axi_wdata[7:0];
                            tx_start_pulse <= 1'b1;
                            s_axi_bresp    <= RESP_OKAY;
                        end else begin
                            s_axi_bresp <= RESP_SLVERR; // RX_DATA/STATUS are read-only
                        end

                        s_axi_bvalid <= 1'b1;
                        wr_state     <= W_RESP;
                    end
                end

                W_RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        wr_state     <= W_IDLE;
                    end
                end
                default: wr_state <= W_IDLE;
            endcase
        end
    end

   
    // Read FSM

    typedef enum logic [1:0] {R_IDLE, R_DATA} rd_state_t;
    rd_state_t rd_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_state      <= R_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= RESP_OKAY;
            s_axi_rdata   <= '0;
        end else begin
            case (rd_state)
                R_IDLE: begin
                    s_axi_rvalid <= 1'b0;
                    if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b1;

                        if (s_axi_araddr[11:4] != 8'd0) begin
                            s_axi_rdata <= 32'b0;
                            s_axi_rresp <= RESP_SLVERR; // outside this peripheral's 16-byte range
                        end else begin
                            case (s_axi_araddr[3:0])
                                4'h4:    begin s_axi_rdata <= {24'b0, rx_data_reg};                    s_axi_rresp <= RESP_OKAY; end
                                4'h8:    begin s_axi_rdata <= {30'b0, rx_done_flag, tx_busy_w};         s_axi_rresp <= RESP_OKAY; end
                                default: begin s_axi_rdata <= 32'b0;                                    s_axi_rresp <= RESP_SLVERR; end
                            endcase
                        end

                        rd_state <= R_DATA;
                    end else begin
                        s_axi_arready <= 1'b0;
                    end
                end

                R_DATA: begin
                    s_axi_arready <= 1'b0;
                    s_axi_rvalid  <= 1'b1;
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        rd_state     <= R_IDLE;
                    end
                end
                default: rd_state <= R_IDLE;
            endcase
        end
    end


    uart_rx_module #(.BAUD_TICK_MAX(BAUD_TICK_MAX)) u_uart_rx (
        .clk     (clk),
        .rst_n   (~rst),        // core uses active-LOW rst_n, so invert
        .rx      (rx_sync1),
        .rx_data (rx_byte_w),
        .rx_done (rx_done_w)
    );

    uart_tx_module #(.BAUD_TICK_MAX(BAUD_TICK_MAX)) u_uart_tx (
        .clk      (clk),
        .rst_n    (~rst),        // core uses active-LOW rst_n, so invert
        .tx_start (tx_start_pulse),
        .tx_data  (tx_data_reg),
        .tx       (uart_tx),
        .tx_busy  (tx_busy_w)
    );

endmodule
