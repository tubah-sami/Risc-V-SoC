module gpio_peripheral (
    input  logic        clk,
    input  logic        reset,

    // Simplified CPU interface
    input  logic        wr_en,
    input  logic        rd_en,
    input  logic [1:0]  addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,

    // External GPIO pins
    input  logic [7:0]  gpio_in,
    output logic [7:0]  gpio_out
);

    // Registers
    logic [7:0] direction;
    logic [7:0] output_reg;

    // Write operation
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            direction  <= 8'b0;
            output_reg <= 8'b0;
        end
        else if (wr_en) begin
            case (addr)
                2'b00: direction  <= wdata[7:0];
                2'b01: output_reg <= wdata[7:0];
                default: ;
            endcase
        end
    end

    // GPIO output
    assign gpio_out = output_reg & direction;

    // Read operation
    always_comb begin
        rdata = 32'b0;

        if (rd_en) begin
            case (addr)
                2'b00: rdata = {24'b0, direction};
                2'b01: rdata = {24'b0, output_reg};
                2'b10: rdata = {24'b0, gpio_in};
                default: rdata = 32'b0;
            endcase
        end
    end

endmodule