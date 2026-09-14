// ============================================================ //
// RISCV_PKG.vh  –  Package file for RV32I Processor           //
// ============================================================ //

`ifndef RISCV_PKG_VH
`define RISCV_PKG_VH

// ── Core widths ──────────────────────────────────────────────
`define INSTRUCTION_SIZE  32
`define WORD_LENGTH       32
`define REG_COUNT         32

// SRAM 
`define IMEM_DEPTH        1024
`define DMEM_DEPTH        1024
`define IMEM_ADDR_BITS    10          // log2(1024)
`define DMEM_ADDR_BITS    10          // log2(1024)

// Memory Map
//   0x0000_0000 – 0x0000_0FFF   Instruction SRAM  (4 KB)
//   0x0001_0000 – 0x0001_0FFF   Data SRAM         (4 KB)
//   0x4000_0000 – 0x4FFF_FFFF   Peripheral space  (AXI4-Lite)
//       0x4000_0000  GPIO base
//       0x4001_0000  UART base
//       0x4002_0000  PWM  base
//       0x4003_0000  Timer base

`define IMEM_BASE         32'h0000_0000
`define IMEM_MASK         32'h0000_0FFF   // 4 KB window

`define DMEM_BASE         32'h0001_0000
`define DMEM_MASK         32'h0000_0FFF   // 4 KB window

`define PERIPH_BASE       32'h4000_0000   // AXI peripheral base
`define PERIPH_TOP        32'h4FFF_FFFF

// Peripheral slot offset
`define GPIO_OFFSET       20'h0_0000
`define PWM_OFFSET        20'h2_0000
`define TIMER_OFFSET      20'h3_0000

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
