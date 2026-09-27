`include "RISCV_PKG.vh"

module RegisterFile(
 input clk, rst, regwrite,
 input [$clog2(`REG_COUNT) - 1 : 0] rs1, rs2, rd,
 input [`INSTRUCTION_SIZE - 1 : 0] write_data,
 output [`INSTRUCTION_SIZE - 1 : 0] read_data1, read_data2
 );

 integer k;
 reg [`INSTRUCTION_SIZE - 1 : 0] Registers [`REG_COUNT - 1 : 0];  //32 reg each of 32 bit 
 
 assign read_data1=Registers[rs1];
 assign read_data2=Registers[rs2];

 always @ (posedge clk)
    begin
        if (rst) begin
            for (k=0;k<`REG_COUNT;k=k+1)
                Registers[k]<=32'b0;
        end         
        else begin 
            if(regwrite && rd!=0) Registers[rd]<= write_data;
        end
    end
        
endmodule