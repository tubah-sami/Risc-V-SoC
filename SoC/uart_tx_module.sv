`timescale 1ns/1ps

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
