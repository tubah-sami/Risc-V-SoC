`timescale 1ns/1ps

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
