
`include "RISCV_PKG.vh"
module mux(
    input sel, 
    input [`INSTRUCTION_SIZE-1:0] in0, 
    input [`INSTRUCTION_SIZE-1:0] in1,  
    output [`INSTRUCTION_SIZE-1:0] out
);
    assign out = (sel) ? in1 : in0;
endmodule