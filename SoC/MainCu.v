`include "RISCV_PKG.vh"
module MainCu(
    input [6:0]opcode,
    output reg regwrite, memread, memwrite, branch, jump, memtoreg, alusrc1, alusrc2, lui, pcsrc,
    output reg [2:0] aluop
);

always @(*) begin
    // Default values
    regwrite = 0; memread = 0; memwrite = 0; branch = 0; jump = 0; memtoreg = 0; alusrc1 = 0; alusrc2 = 0; lui = 0; pcsrc = 0; aluop = `NOP;

    case (opcode)
        7'b0110011: begin // R-type
            regwrite = 1;
            aluop    = `R_TYPE;
        end
        7'b0010011: begin // I-type
            regwrite = 1;
            alusrc2  = 1;
            aluop    = `I_TYPE;
        end
        7'b0000011: begin // Load
            regwrite = 1;
            memread  = 1;
            alusrc2  = 1;
            memtoreg = 1;
            aluop    = `LOAD;
        end
        7'b0100011: begin // Store
            memwrite = 1;
            alusrc2  = 1;
            aluop    = `STORE;
        end
        7'b1100011: begin // Branch
            branch   = 1;
            aluop    = `BRANCH;
        end
        7'b1101111, 7'b1100111: begin // JAL and JALR
            regwrite = 1;
            jump     = 1;
            alusrc1  = 1; // For JALR immediate offset
            pcsrc    = (opcode == 7'b1100111) ? 1 : 0; // JALR only
            aluop    = `JUMP;
        end
        7'b0110111, 7'b0010111: begin // LUI and AUIPC
            regwrite = 1;
            alusrc2  = 1;
            lui      = (opcode == 7'b0110111) ? 1 : 0; // LUI only
				alusrc1  = (opcode == 7'b0010111) ? 1 : 0; // AUIPC: operand1 = pc_out
            aluop    = `U_TYPE;
        end
        default: ; // Do nothing; defaults already set

    endcase 
end
endmodule