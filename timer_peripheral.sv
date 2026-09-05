// ============================================================
// Simple Timer Peripheral
// ============================================================
// Active-Low Synchronous Reset
//
// Operation:
//
// COUNT   : 0 -> 1 -> 2 -> 3 -> 0 -> ...
// TIMEOUT : 0    0    0    1    0    ...
//
// For compare_value = 3:
//
// COUNT    0 -> 1 -> 2 -> 3 -> 0 -> 1 -> 2 -> 3 ...
// TIMEOUT  0    0    0 ->1 -> 0 -> 0 -> 0 -> 1 ...
//
// Design goals:
//   - Simple
//   - Small hardware
//   - Low switching activity
//   - Short timing path
//   - Easy AXI4-Lite integration later
//
// NOTE:
//   compare_value must be >= 1.
// ============================================================

module timer_peripheral (
    input  logic        clk,
    input  logic        reset_n,

    input  logic        enable,
    input  logic [31:0] compare_value,

    output logic [31:0] count,
    output logic        timeout
);

    always_ff @(posedge clk) begin

        // --------------------------------------------------------
        // Active-low synchronous reset
        // --------------------------------------------------------
        if (!reset_n) begin

            count   <= 32'd0;
            timeout <= 1'b0;

        end

        // --------------------------------------------------------
        // Timer disabled
        // --------------------------------------------------------
        else if (!enable) begin

            // Keep the counter value unchanged
            // and force timeout LOW.
            timeout <= 1'b0;

        end

        // --------------------------------------------------------
        // Timer enabled
        // --------------------------------------------------------
        else begin

            // ----------------------------------------------------
            // Reach compare value
            // ----------------------------------------------------
            if (count == compare_value - 32'd1) begin

                count   <= compare_value;
                timeout <= 1'b1;

            end

            // ----------------------------------------------------
            // Compare value reached
            // ----------------------------------------------------
            else if (count == compare_value) begin

                count   <= 32'd0;
                timeout <= 1'b0;

            end

            // ----------------------------------------------------
            // Normal counting
            // ----------------------------------------------------
            else begin

                count   <= count + 32'd1;
                timeout <= 1'b0;

            end

        end

    end

endmodule