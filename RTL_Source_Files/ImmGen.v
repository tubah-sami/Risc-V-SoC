`include "RISCV_PKG.vh"

module ImmGen(
    input  [`INSTRUCTION_SIZE-1:0] instruction,
    output reg [`INSTRUCTION_SIZE-1:0] imm_out
);

wire [6:0] opcode = instruction[6:0];
wire [2:0] funct3 = instruction[14:12];

always @(*) begin
    case (opcode)
        
        // I-type (Load): LB, LH, LW, LBU, LHU
        7'b0000011:
            imm_out = {{20{instruction[31]}}, instruction[31:20]};
        // I-type (ALU immediate): ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
        7'b0010011: begin
            // Shift instructions use shamt (bits [24:20])
            case (funct3)
                3'b001, 3'b101:  imm_out = {{27{1'b0}}, instruction[24:20]}; // SLLI, SRLI, SRAI
                default:          imm_out = {{20{instruction[31]}}, instruction[31:20]};
            endcase
        end
        // S-type (Store): SB, SH, SW
        7'b0100011:
            imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        // B-type (Branch): BEQ, BNE, BLT, BGE, BLTU, BGEU
        7'b1100011:
            imm_out = {{19{instruction[31]}}, instruction[31], instruction[7],
                       instruction[30:25], instruction[11:8], 1'b0};
        // J-type (JAL)
        7'b1101111:
            imm_out = {{11{instruction[31]}}, instruction[31], instruction[19:12],
                       instruction[20], instruction[30:21], 1'b0};
        // I-type (JALR)
        7'b1100111:
            imm_out = {{20{instruction[31]}}, instruction[31:20]};
        // U-type (LUI, AUIPC)
        7'b0110111, // LUI
        7'b0010111: // AUIPC
            imm_out = {instruction[31:12], 12'b0};
        // Default
        default:
            imm_out = 32'b0;
    endcase
end

endmodule