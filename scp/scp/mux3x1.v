module mux3x1(
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [31:0] c,
    input  wire [1:0]  sel,
    output reg  [31:0] y
);

always @(*) begin
    case (sel)
        2'b00: y = a;
        2'b01: y = b;
        2'b10: y = c;
        default: y = 32'bx;
    endcase
end

endmodule

