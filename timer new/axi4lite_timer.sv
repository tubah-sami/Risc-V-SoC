`timescale 1ns/1ps
// AXI4-Lite Timer Peripheral
// Register Map (byte offsets):
//   0x00  CONTROL        R/W   bit[0] = enable
//   0x04  COMPARE_VALUE  R/W   compare value for timeout
//   0x08  COUNT          R     current count value
//   0x0C  STATUS         R     bit[0] = timeout flag

module axi4lite_timer (
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
    input  logic         s_axi_rready
);

    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_SLVERR = 2'b10;

    // ------------------------------------------------------------
    // Register-mapped storage (feeds the core timer)
    // ------------------------------------------------------------
    logic        enable_reg;
    logic [31:0] compare_value_reg;
    logic [31:0] count_w;
    logic        timeout_w;

    // ------------------------------------------------------------
    // Write FSM
    // ------------------------------------------------------------
    typedef enum logic [1:0] {W_IDLE, W_DATA, W_RESP} wr_state_t;
    wr_state_t wr_state;
    logic [31:0] awaddr_latched;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_state          <= W_IDLE;
            s_axi_awready     <= 1'b0;
            s_axi_wready      <= 1'b0;
            s_axi_bvalid      <= 1'b0;
            s_axi_bresp       <= RESP_OKAY;
            awaddr_latched    <= '0;
            enable_reg        <= 1'b0;
            compare_value_reg <= 32'd1; // must stay >= 1 per core module note
        end else begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;

            case (wr_state)
                // Phase 1: accept write ADDRESS alone
                W_IDLE: begin
                    s_axi_bvalid <= 1'b0;
                    if (s_axi_awvalid) begin
                        s_axi_awready  <= 1'b1;
                        awaddr_latched <= s_axi_awaddr;
                        wr_state       <= W_DATA;
                    end
                end

                // Phase 2: accept write DATA alone, then commit
                W_DATA: begin
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b1;

                        if (awaddr_latched[11:4] != 8'd0) begin
                            s_axi_bresp <= RESP_SLVERR; // outside this peripheral's 16-byte range
                        end else begin
                            case (awaddr_latched[3:0])
                                4'h0: begin
                                    enable_reg   <= s_axi_wdata[0];
                                    s_axi_bresp  <= RESP_OKAY;
                                end
                                4'h4: begin
                                    compare_value_reg <= (s_axi_wdata == 32'd0) ? 32'd1 : s_axi_wdata;
                                    s_axi_bresp       <= RESP_OKAY;
                                end
                                default: s_axi_bresp <= RESP_SLVERR; // COUNT/STATUS are read-only
                            endcase
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
    logic [31:0] araddr_latched;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_state       <= R_IDLE;
            s_axi_arready  <= 1'b0;
            s_axi_rvalid   <= 1'b0;
            s_axi_rresp    <= RESP_OKAY;
            araddr_latched <= '0;
            s_axi_rdata    <= '0;
        end else begin
            case (rd_state)
                R_IDLE: begin
                    s_axi_rvalid <= 1'b0;
                    if (s_axi_arvalid) begin
                        s_axi_arready  <= 1'b1;
                        araddr_latched <= s_axi_araddr;

                        if (s_axi_araddr[11:4] != 8'd0) begin
                            s_axi_rdata <= 32'b0;
                            s_axi_rresp <= RESP_SLVERR; // outside this peripheral's 16-byte range
                        end else begin
                            case (s_axi_araddr[3:0])
                                4'h0:    begin s_axi_rdata <= {31'b0, enable_reg};      s_axi_rresp <= RESP_OKAY; end
                                4'h4:    begin s_axi_rdata <= compare_value_reg;        s_axi_rresp <= RESP_OKAY; end
                                4'h8:    begin s_axi_rdata <= count_w;                  s_axi_rresp <= RESP_OKAY; end
                                4'hC:    begin s_axi_rdata <= {31'b0, timeout_w};       s_axi_rresp <= RESP_OKAY; end
                                default: begin s_axi_rdata <= 32'b0;                    s_axi_rresp <= RESP_SLVERR; end
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

    timer_peripheral u_timer_core (
        .clk           (clk),
        .reset_n       (~rst),        // core uses active-LOW reset_n, so invert
        .enable        (enable_reg),
        .compare_value (compare_value_reg),
        .count         (count_w),
        .timeout       (timeout_w)
    );

endmodule
