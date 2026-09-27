`include "RISCV_PKG.vh"
module Adder(
    input [`INSTRUCTION_SIZE-1:0] in1,
    input [`INSTRUCTION_SIZE-1:0] in2,
    output [`INSTRUCTION_SIZE-1:0] out
);
    assign out = in1 + in2;

endmodule