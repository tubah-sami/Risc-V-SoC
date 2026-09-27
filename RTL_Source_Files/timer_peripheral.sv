module timer_peripheral (
    input  logic        clk,
    input  logic        reset_n,

    input  logic        enable,
    input  logic [31:0] compare_value,

    output logic [31:0] count,
    output logic        timeout
);

    // NOTE: reset_n is active-LOW, asynchronous - must be in the
    // sensitivity list (matches pwm_rtl / uart_rx / uart_tx style).
    // It was missing here, which silently turned this into a
    // synchronous-only reset (reset_n glitches / async resets were
    // never seen unless a clk edge happened to coincide).
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            count   <= 32'd0;
            timeout <= 1'b0;
        end
        else if (!enable) begin
            timeout <= 1'b0;
        end
        else begin
            if (count == compare_value - 32'd1) begin
                count   <= compare_value;
                timeout <= 1'b1;
            end
            else if (count == compare_value) begin
                count   <= 32'd0;
                timeout <= 1'b0;
            end
            else begin
                count   <= count + 32'd1;
                timeout <= 1'b0;
            end
        end
    end

endmodule
