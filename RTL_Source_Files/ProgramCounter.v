`include "RISCV_PKG.vh"
module ProgramCounter(
    input clk, rst, stall,
    input [`INSTRUCTION_SIZE - 1 : 0] in,
    output reg [`INSTRUCTION_SIZE - 1 : 0] out
);
always @(posedge clk) begin
    if (rst) begin
        out <= 32'b0;
    end else if (!stall) begin
        out <= in; // update PC only when no stall
    end
end
endmodule