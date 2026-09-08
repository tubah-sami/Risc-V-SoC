`timescale 1ns/1ps
// ============================================================
// AXI4-Lite GPIO Peripheral
// ============================================================
// Register Map (byte offsets):
//   0x00  DIRECTION    R/W   bit=1 -> output, bit=0 -> input
//   0x04  OUTPUT_REG   R/W   output pin values
//   0x08  INPUT_REG    R     input pin values (gpio_in)
//
// Assumes upstream interconnect only asserts s_axi_aw/ar/w valid
// for this slave when the address decode has already selected it
// (standard AXI4-Lite interconnect behavior) - this wrapper only
// decodes the LOCAL register offset, not the base address.
// ============================================================

module axi4lite_gpio (
    input  logic         clk,
    input  logic         rst,           

    // Write address channel
    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    // Write data channel
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    // Write response channel
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    // Read address channel
    input  logic [31:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    // Read data channel
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // External GPIO pins
    input  logic [7:0]  gpio_in,
    output logic [7:0]  gpio_out
);

    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_SLVERR = 2'b10;

   
    // Write FSM
  
    typedef enum logic [1:0] {W_IDLE, W_DATA, W_RESP} wr_state_t;
    wr_state_t wr_state;

    logic [31:0] awaddr_latched;
    logic [31:0] wdata_latched;
    logic        core_wr_en;
    logic [1:0]  core_waddr; // register select (2 bits, matches gpio_peripheral)

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_state       <= W_IDLE;
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= RESP_OKAY;
            core_wr_en     <= 1'b0;
            awaddr_latched <= '0;
            wdata_latched  <= '0;
        end else begin
            core_wr_en    <= 1'b0; // default: 1-cycle pulse
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;

            case (wr_state)
                // Phase 1: accept the write ADDRESS on its own
                // (does not require WVALID at the same time - matches
                // axi_master_lite, which sends AWVALID and WVALID in
                // separate cycles, never simultaneously)
                W_IDLE: begin
                    s_axi_bvalid <= 1'b0;
                    if (s_axi_awvalid) begin
                        s_axi_awready  <= 1'b1;
                        awaddr_latched <= s_axi_awaddr;
                        wr_state       <= W_DATA;
                    end
                end

                // Phase 2: accept the write DATA on its own, then
                // perform the actual register write using the
                // address latched in phase 1.
                W_DATA: begin
                    if (s_axi_wvalid) begin
                        s_axi_wready  <= 1'b1;
                        wdata_latched <= s_axi_wdata;
                        core_wr_en    <= (awaddr_latched[11:4] == 8'd0) && (awaddr_latched[3:2] <= 2'b10);
                        s_axi_bresp   <= ((awaddr_latched[11:4] == 8'd0) && (awaddr_latched[3:2] <= 2'b10)) ? RESP_OKAY : RESP_SLVERR;
                        s_axi_bvalid  <= 1'b1;
                        wr_state      <= W_RESP;
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

    assign core_waddr = awaddr_latched[3:2];

    // Read FSM
   
    typedef enum logic [1:0] {R_IDLE, R_DATA} rd_state_t;
    rd_state_t rd_state;

    logic [31:0] araddr_latched;
    logic        core_rd_en;
    logic [1:0]  core_raddr;
    logic [31:0] core_rdata;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_state       <= R_IDLE;
            s_axi_arready  <= 1'b0;
            s_axi_rvalid   <= 1'b0;
            s_axi_rresp    <= RESP_OKAY;
            araddr_latched <= '0;
            core_rd_en     <= 1'b0;
        end else begin
            core_rd_en <= 1'b0;

            case (rd_state)
                R_IDLE: begin
                    s_axi_rvalid <= 1'b0;
                    if (s_axi_arvalid) begin
                        s_axi_arready  <= 1'b1;
                        araddr_latched <= s_axi_araddr;
                        core_rd_en     <= (s_axi_araddr[11:4] == 8'd0) && (s_axi_araddr[3:2] <= 2'b10);
                        s_axi_rresp    <= ((s_axi_araddr[11:4] == 8'd0) && (s_axi_araddr[3:2] <= 2'b10)) ? RESP_OKAY : RESP_SLVERR;
                        rd_state       <= R_DATA;
                    end else begin
                        s_axi_arready <= 1'b0;
                    end
                end

                R_DATA: begin
                    s_axi_arready <= 1'b0;
                    s_axi_rvalid  <= 1'b1;
                    s_axi_rdata   <= core_rdata;
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        rd_state     <= R_IDLE;
                    end
                end
                default: rd_state <= R_IDLE;
            endcase
        end
    end

    assign core_raddr = araddr_latched[3:2];


    gpio_peripheral u_gpio_core (
        .clk     (clk),
        .reset   (rst),        // core uses active-high reset (matches now)
        .wr_en   (core_wr_en),
        .rd_en   (core_rd_en),
        .addr    (core_wr_en ? core_waddr : core_raddr),
        .wdata   (wdata_latched),
        .rdata   (core_rdata),
        .gpio_in (gpio_in),
        .gpio_out(gpio_out)
    );

endmodule
