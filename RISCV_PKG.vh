// ============================================================ //
// RISCV_PKG.vh  –  Package file for RV32I Processor           //
// ============================================================ //

`ifndef RISCV_PKG_VH
`define RISCV_PKG_VH

// ── Core widths ──────────────────────────────────────────────
`define INSTRUCTION_SIZE  32
`define WORD_LENGTH       32
`define REG_COUNT         32

// ── SRAM geometry (1024 words × 32 bit = 4 KB each) 
`define IMEM_DEPTH        1024
`define DMEM_DEPTH        1024
`define IMEM_ADDR_BITS    10          // log2(1024)
`define DMEM_ADDR_BITS    10          // log2(1024)
`define IMEM_BYTE_SIZE    4096        // 4 KB  (DEPTH × 4)
`define DMEM_BYTE_SIZE    4096        // 4 KB

// ── ALU Operation Codes (alu_control[3:0]) ───────────────────
`define ADD                     4'b0000
`define SUB                     4'b0001
`define less_than               4'b0010
`define less_than_unsigned      4'b0011
`define greater_than            4'b0100
`define greater_than_unsigned   4'b0101
`define XOR                     4'b0110
`define OR                      4'b0111
`define AND                     4'b1000
`define SLL                     4'b1001
`define SRL                     4'b1010
`define SRA                     4'b1011
`define equal                   4'b1100
`define not_equal               4'b1101
`define pc_plus_4               4'b1110

// ── ALUOp encoding (aluop[2:0]) ──────────────────────────────
`define R_TYPE      3'b000   // ADD/SUB/AND/OR/XOR/SLT/SLTU/SLL/SRL/SRA
`define I_TYPE      3'b001   // ADDI/ANDI/ORI/XORI/SLTI/SLTIU/SLLI/SRLI/SRAI/JALR
`define STORE       3'b010   // SB/SH/SW
`define BRANCH      3'b011   // BEQ/BNE/BLT/BGE/BLTU/BGEU
`define U_TYPE      3'b100   // LUI/AUIPC
`define JUMP        3'b101   // JAL/JALR
`define LOAD        3'b110   // LW/LH/LB/LHU/LBU
`define NOP         3'b111   // no-op

`endif // RISCV_PKG_VH
