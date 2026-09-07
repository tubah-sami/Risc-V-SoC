`include "RISCV_PKG.vh"

module AluCu(
    input [2:0] aluop,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg [3:0] alu_control
);

always @(*) begin
    casez ({aluop, funct7[5], funct3})

        {`STORE, 1'b?, 3'b???}, {`U_TYPE, 1'b?, 3'b???}, {`NOP, 1'b?, 3'b???}, {`R_TYPE, 1'b0, 3'b000}, {`I_TYPE, 1'b?, 3'b000}, {`LOAD, 1'b?, 3'b???}: alu_control = `ADD;  // ADD, LW, SW, AUIPC, ADDI, NOP
        {`R_TYPE, 1'b1, 3'b000}: alu_control = `SUB;  // SUB
        {`BRANCH, 1'b?, 3'b100},{`I_TYPE,  1'b?, 3'b010},{`R_TYPE,  1'b0, 3'b010}: alu_control = `less_than;  // SLT, SLTI, BLT
        {`BRANCH, 1'b?, 3'b101}: alu_control = `greater_than;  // BGE
        {`BRANCH, 1'b?, 3'b110}, {`I_TYPE,  1'b?, 3'b011}, {`R_TYPE,  1'b0, 3'b011}: alu_control = `less_than_unsigned;  // SLTU, SLTIU, BLTU
        {`BRANCH, 1'b?, 3'b111}: alu_control = `greater_than_unsigned;  // BGEU
        {`R_TYPE, 1'b0, 3'b100}, {`I_TYPE, 1'b?, 3'b100}: alu_control = `XOR;  // XOR, XORI
        {`R_TYPE, 1'b0, 3'b110}, {`I_TYPE, 1'b?, 3'b110}: alu_control = `OR;   // OR, ORI
        {`R_TYPE, 1'b0, 3'b111}, {`I_TYPE, 1'b?, 3'b111}: alu_control = `AND;  // AND, ANDI
        {`I_TYPE, 1'b0, 3'b001}, {`R_TYPE, 1'b0, 3'b001}: alu_control = `SLL;  // SLL, SLLI
        {`I_TYPE, 1'b0, 3'b101}, {`R_TYPE, 1'b0, 3'b101}: alu_control = `SRL;  // SRL, SRLI
        {`R_TYPE, 1'b1, 3'b101}, {`I_TYPE, 1'b1, 3'b101}: alu_control = `SRA;  // SRA, SRAI
        {`BRANCH, 1'b?, 3'b000}: alu_control = `equal;      // BEQ
        {`BRANCH, 1'b?, 3'b001}: alu_control = `not_equal;  // BNE
        {`JUMP, 1'b?, 3'b???}: alu_control = `pc_plus_4;  // JAL and JALR
        default: alu_control = 4'b0000;

    endcase
end

endmodule