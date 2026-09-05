module pwm_rtl #(
    parameter WIDTH = 16
)(
    input  logic             clk,
    input  logic             reset_n,
    input  logic             enable,

    input  logic [WIDTH-1:0] period,
    input  logic [WIDTH-1:0] duty,

    output logic             pwm_out
);

    // Internal PWM counter
    logic [WIDTH-1:0] counter;


    // ========================================================
    // COUNTER
    // ========================================================
    always_ff @(posedge clk or negedge reset_n) begin

        if (!reset_n) begin
            counter <= '0;

        end
        else if (!enable) begin
            counter <= '0;

        end
        else if (period == '0) begin
            counter <= '0;

        end
        else if (counter == (period - 1'b1)) begin
            counter <= '0;

        end
        else begin
            counter <= counter + 1'b1;
        end

    end


    // ========================================================
    // PWM OUTPUT
    //
    // PERIOD = 10, DUTY = 5:
    //
    // counter: 0 1 2 3 4 5 6 7 8 9
    // pwm_out: 1 1 1 1 1 0 0 0 0 0
    // ========================================================
    always_comb begin

        if (!enable)
            pwm_out = 1'b0;

        else if (period == '0)
            pwm_out = 1'b0;

        else if (duty == '0)
            pwm_out = 1'b0;

        else if (duty >= period)
            pwm_out = 1'b1;

        else
            pwm_out = (counter < duty);

    end

endmodule
