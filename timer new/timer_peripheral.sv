
module timer_peripheral (
    input  logic        clk,
    input  logic        reset_n,

    input  logic        enable,
    input  logic [31:0] compare_value,

    output logic [31:0] count,
    output logic        timeout
);

    always_ff @(posedge clk) begin

        if (!reset_n) begin

            count   <= 32'd0;
            timeout <= 1'b0;

        end

        else if (!enable)
        begin
            timeout <= 1'b0;

        end

      
        // Timer enabled
  
        else begin

            // Reach compare value
          
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