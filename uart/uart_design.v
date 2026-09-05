// ====================================================================
// Top Module: UART Receive -> LED Display -> UART Echo (Corrected)
// Board: Terasic Cyclone V GX Starter Kit (C5G)
// Baud Rate: 115200
// ====================================================================
module cyclone5_uart_led (
    input  wire       CLOCK_50_B5B, // Confirmed correct 50MHz oscillator
    input  wire       CPU_RESET_n,  // Active Low Pushbutton Reset
    input  wire       UART_RX,      // USB-to-UART RX Pin
    output wire       UART_TX,      // USB-to-UART TX Pin
    output wire [7:0] LEDR          // FIXED: Red LEDs utilized for full 8-bit output
);

    // Clock and Baud Rate Configurations
    parameter CLK_FREQ  = 50000000;
    parameter BAUD_RATE = 115200;
    localparam integer BAUD_TICK_MAX = CLK_FREQ / BAUD_RATE; // 434

    // 2-stage synchronizer for incoming async UART_RX signal
    reg rx_sync0, rx_sync1;
    always @(posedge CLOCK_50_B5B or negedge CPU_RESET_n) begin
        if (!CPU_RESET_n) begin
            rx_sync0 <= 1'b1;
            rx_sync1 <= 1'b1;
        end else begin
            rx_sync0 <= UART_RX;
            rx_sync1 <= rx_sync0;
        end
    end

    wire [7:0] rx_byte;
    wire       rx_done;
    reg  [7:0] data_reg;
    
    // TX Control Register Pipeline
    reg        tx_trigger;
    wire       tx_busy;

    assign LEDR = data_reg; // Display received byte directly on Red LEDs

    // Inter-module synchronization loop
    always @(posedge CLOCK_50_B5B or negedge CPU_RESET_n) begin
        if (!CPU_RESET_n) begin
            data_reg   <= 8'h00;
            tx_trigger <= 1'b0;
        end else begin
            if (rx_done) begin
                data_reg   <= rx_byte;
                tx_trigger <= 1'b1; // Hold trigger high until TX accepts it
            end else if (tx_busy) begin
                tx_trigger <= 1'b0; // Handshake clear
            end
        end
    end

    uart_rx_module #(.BAUD_TICK_MAX(BAUD_TICK_MAX)) rx_inst (
        .clk(CLOCK_50_B5B),
        .rst_n(CPU_RESET_n),
        .rx(rx_sync1),
        .rx_data(rx_byte),
        .rx_done(rx_done)
    );

    uart_tx_module #(.BAUD_TICK_MAX(BAUD_TICK_MAX)) tx_inst (
        .clk(CLOCK_50_B5B),
        .rst_n(CPU_RESET_n),
        .tx_start(tx_trigger), // Driven by clean buffered logic
        .tx_data(data_reg),
        .tx(UART_TX),
        .tx_busy(tx_busy)
    );

endmodule


// ====================================================================
// UART Receiver Module with Framing Error Check (Verified)
// ====================================================================
module uart_rx_module #(parameter integer BAUD_TICK_MAX = 434) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg  [7:0] rx_data,
    output reg        rx_done
);
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    reg [1:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  rx_shift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            rx_done   <= 1'b0;
            rx_data   <= 8'h00;
            clk_count <= 16'h0000;
            bit_index <= 3'b000;
            rx_shift  <= 8'h00;
        end else begin
            rx_done <= 1'b0;
            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    if (rx == 1'b0) begin
                        state <= START;
                    end
                end

                START: begin
                    if (clk_count == (BAUD_TICK_MAX / 2) - 1) begin
                        if (rx == 1'b0) begin
                            clk_count <= 0;
                            state     <= DATA;
                        end else
                            state     <= IDLE;
                    end else
                        clk_count <= clk_count + 1;
                end

                DATA: begin
                    if (clk_count == BAUD_TICK_MAX - 1) begin
                        clk_count <= 0;
                        rx_shift[bit_index] <= rx;
                        if (bit_index == 7)
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1;
                    end else
                        clk_count <= clk_count + 1;
                end

                STOP: begin
                    if (clk_count == BAUD_TICK_MAX - 1) begin
                        clk_count <= 0;
                        if (rx == 1'b1) begin
                            rx_data <= rx_shift;
                            rx_done <= 1'b1;
                        end
                        state <= IDLE;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule


// ====================================================================
// UART Transmitter Module with Explicit Busy Control (Verified)
// ====================================================================
module uart_tx_module #(parameter integer BAUD_TICK_MAX = 434) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output reg        tx,
    output reg        tx_busy
);
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    reg [1:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  tx_shift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            tx        <= 1'b1;
            tx_busy   <= 1'b0;
            clk_count <= 16'h0000;
            bit_index <= 3'b000;
            tx_shift  <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    tx        <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (tx_start) begin
                        tx_shift  <= tx_data;
                        tx_busy   <= 1'b1;
                        state     <= START;
                    end else
                        tx_busy   <= 1'b0;
                end

                START: begin
                    tx      <= 1'b0;
                    tx_busy <= 1'b1;
                    if (clk_count == BAUD_TICK_MAX - 1) begin
                        clk_count <= 0;
                        state     <= DATA;
                    end else
                        clk_count <= clk_count + 1;
                end

                DATA: begin
                    tx      <= tx_shift[bit_index];
                    tx_busy <= 1'b1;
                    if (clk_count == BAUD_TICK_MAX - 1) begin
                        clk_count <= 0;
                        if (bit_index == 7)
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1;
                    end else
                        clk_count <= clk_count + 1;
                end

                STOP: begin
                    tx      <= 1'b1;
                    tx_busy <= 1'b1;
                    if (clk_count == BAUD_TICK_MAX - 1) begin
                        clk_count <= 0;
                        tx_busy   <= 1'b0;
                        state     <= IDLE;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule