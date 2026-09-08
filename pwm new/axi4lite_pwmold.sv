`timescale 1ns/1ps
// AXI4-Lite PWM Peripheral
// Register Map (byte offsets):
//   0x00  CONTROL   R/W   bit[0] = enable
//   0x04  PERIOD    R/W   PWM period value
//   0x08  DUTY      R/W   PWM duty cycle value


module axi4lite_pwm #(
    parameter WIDTH = 16
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

    output logic         pwm_out
);

    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_SLVERR = 2'b10;

    logic              enable_reg;
    logic [WIDTH-1:0]  period_reg;
    logic [WIDTH-1:0]  duty_reg;

   
    // Write FSM
    typedef enum logic [1:0] {W_IDLE, W_RESP} wr_state_t;
    wr_state_t wr_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_state      <= W_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= RESP_OKAY;
            enable_reg    <= 1'b0;
            period_reg    <= '0;
            duty_reg      <= '0;
        end else begin
            case (wr_state)
                W_IDLE: begin
                    s_axi_bvalid <= 1'b0;
                    if (s_axi_awvalid && s_axi_wvalid) begin
                        s_axi_awready <= 1'b1;
                        s_axi_wready  <= 1'b1;

                        if (s_axi_awaddr[11:4] != 8'd0) begin
                            s_axi_bresp <= RESP_SLVERR; // outside this peripheral's 16-byte range
                        end else begin
                            case (s_axi_awaddr[3:0])
                                4'h0: begin enable_reg <= s_axi_wdata[0];          s_axi_bresp <= RESP_OKAY; end
                                4'h4: begin period_reg <= s_axi_wdata[WIDTH-1:0]; s_axi_bresp <= RESP_OKAY; end
                                4'h8: begin duty_reg   <= s_axi_wdata[WIDTH-1:0]; s_axi_bresp <= RESP_OKAY; end
                                default: s_axi_bresp <= RESP_SLVERR;
                            endcase
                        end

                        s_axi_bvalid <= 1'b1;
                        wr_state     <= W_RESP;
                    end else begin
                        s_axi_awready <= 1'b0;
                        s_axi_wready  <= 1'b0;
                    end
                end

                W_RESP: begin
                    s_axi_awready <= 1'b0;
                    s_axi_wready  <= 1'b0;
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
                                4'h0:    begin s_axi_rdata <= {31'b0, enable_reg};                     s_axi_rresp <= RESP_OKAY; end
                                4'h4:    begin s_axi_rdata <= {{(32-WIDTH){1'b0}}, period_reg};        s_axi_rresp <= RESP_OKAY; end
                                4'h8:    begin s_axi_rdata <= {{(32-WIDTH){1'b0}}, duty_reg};          s_axi_rresp <= RESP_OKAY; end
                                default: begin s_axi_rdata <= 32'b0;                                   s_axi_rresp <= RESP_SLVERR; end
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

    pwm_rtl #(
        .WIDTH(WIDTH)
    ) u_pwm_core (
        .clk      (clk),
        .reset_n  (~rst),        // core uses active-LOW reset_n, so invert
        .enable   (enable_reg),
        .period   (period_reg),
        .duty     (duty_reg),
        .pwm_out  (pwm_out)
    );

endmodule
