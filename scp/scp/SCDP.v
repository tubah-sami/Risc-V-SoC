`include "RISCV_PKG.vh"

module SCDP (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,

    //Instruction Memory
    output wire [31:0] imem_addr,   
    input  wire [31:0] imem_rdata,  

    output wire [31:0] dmem_addr,   
    output wire [31:0] dmem_wdata,  
    output wire        dmem_we,       
    output wire        dmem_re,
    output wire [3:0]  dmem_be,
    input  wire [31:0] dmem_rdata
);

// ─────────────────────────────────────────────────────────────
//  Internal wires
// ─────────────────────────────────────────────────────────────
wire        memread, memwrite;
wire        branch, jump, regwrite_en, pcsrc;
wire        alusrc1, alusrc2, lui, memtoreg;
wire [2:0]  aluop;
wire [3:0]  alu_control;

wire [31:0] instruction;
wire [31:0] rs1_data, rs2_data, rd_data;
wire [31:0] pc_out;
wire [31:0] operand1, operand2, alu_result;
wire [31:0] immediate;
wire [31:0] adder_in1, adder_in2, pc_next_raw, pc_next;
wire [31:0] load_data, alu_or_load, wb_data;
wire        branch_taken, b_or_j;

// ─────────────────────────────────────────────────────────────
//  Instruction memory drive
// ─────────────────────────────────────────────────────────────
assign imem_addr  = pc_out;
assign instruction = imem_rdata;

// ─────────────────────────────────────────────────────────────
//  Main Control Unit
// ─────────────────────────────────────────────────────────────
MainCu control_unit (
    .opcode   (instruction[6:0]),
    .aluop    (aluop),
    .memread  (memread),
    .memwrite (memwrite),
    .branch   (branch),
    .jump     (jump),
    .regwrite (regwrite_en),
    .pcsrc    (pcsrc),
    .alusrc1  (alusrc1),
    .alusrc2  (alusrc2),
    .lui      (lui),
    .memtoreg (memtoreg)
);


//  Register File

wire regwrite_gated = regwrite_en & ~stall;

RegisterFile register_file (
    .clk        (clk),
    .rst        (rst),
    .rs1        (instruction[19:15]),
    .rs2        (instruction[24:20]),
    .rd         (instruction[11:7]),
    .read_data1 (rs1_data),
    .read_data2 (rs2_data),
    .write_data (rd_data),
    .regwrite   (regwrite_gated)
);

// ─────────────────────────────────────────────────────────────
//  Immediate Generator
// ─────────────────────────────────────────────────────────────
ImmGen Immediate_Generator (
    .instruction (instruction),
    .imm_out     (immediate)
);

// ─────────────────────────────────────────────────────────────
//  ALU Source Muxes
// ─────────────────────────────────────────────────────────────
//  ALUSRC1: 0 = rs1  |  1 = PC  (JAL/AUIPC: pc+imm)
mux ALUSRC1_mux (
    .sel (alusrc1),
    .in0 (rs1_data),
    .in1 (pc_out),
    .out (operand1)
);

//  ALUSRC2: 0 = rs2  |  1 = imm
mux ALUSRC2_mux (
    .sel (alusrc2),
    .in0 (rs2_data),
    .in1 (immediate),
    .out (operand2)
);

// ─────────────────────────────────────────────────────────────
//  ALU Control + ALU
// ─────────────────────────────────────────────────────────────
AluCu ALU_control_unit (
    .aluop       (aluop),
    .funct3      (instruction[14:12]),
    .funct7      (instruction[31:25]),
    .alu_control (alu_control)
);

Alu ALU (
    .rs1         (operand1),
    .rs2         (operand2),
    .alu_control (alu_control),
    .result      (alu_result)
);

// ─────────────────────────────────────────────────────────────
//  Data Memory Interface Logic
// ─────────────────────────────────────────────────────────────
wire [2:0] funct3    = instruction[14:12];
wire [1:0] byte_off  = alu_result[1:0];  

reg [3:0] be_gen;
always @(*) begin
    case (funct3[1:0])
        2'b00:   be_gen = 4'b0001 << byte_off;                  
        2'b01:   be_gen = byte_off[1] ? 4'b1100 : 4'b0011;     
        2'b10:   be_gen = 4'b1111;
        default: be_gen = 4'b1111;
    endcase
end

reg [31:0] wdata_aligned;
always @(*) begin
    case (funct3[1:0])
        2'b00:   wdata_aligned = {4{rs2_data[7:0]}};    
        2'b01:   wdata_aligned = {2{rs2_data[15:0]}};   
        2'b10:   wdata_aligned = rs2_data;               
        default: wdata_aligned = rs2_data;
    endcase
end

assign dmem_addr  = alu_result;       
assign dmem_wdata = wdata_aligned;
assign dmem_we    = memwrite;         
assign dmem_re    = memread;
assign dmem_be    = be_gen;

reg [31:0] load_data_r;
always @(*) begin
    case (funct3)
        3'b000: begin   
            case (byte_off)
                2'b00: load_data_r = {{24{dmem_rdata[7]}},  dmem_rdata[7:0]};
                2'b01: load_data_r = {{24{dmem_rdata[15]}}, dmem_rdata[15:8]};
                2'b10: load_data_r = {{24{dmem_rdata[23]}}, dmem_rdata[23:16]};
                2'b11: load_data_r = {{24{dmem_rdata[31]}}, dmem_rdata[31:24]};
                default: load_data_r = 32'b0;
            endcase
        end
        3'b001: begin   // LH  
            case (byte_off[1])
                1'b0: load_data_r = {{16{dmem_rdata[15]}}, dmem_rdata[15:0]};
                1'b1: load_data_r = {{16{dmem_rdata[31]}}, dmem_rdata[31:16]};
                default: load_data_r = 32'b0;
            endcase
        end
        3'b010:  load_data_r = dmem_rdata;                          // LW
        3'b100: begin   // LBU 
            case (byte_off)
                2'b00: load_data_r = {24'b0, dmem_rdata[7:0]};
                2'b01: load_data_r = {24'b0, dmem_rdata[15:8]};
                2'b10: load_data_r = {24'b0, dmem_rdata[23:16]};
                2'b11: load_data_r = {24'b0, dmem_rdata[31:24]};
                default: load_data_r = 32'b0;
            endcase
        end
        3'b101: begin   // LHU 
            case (byte_off[1])
                1'b0: load_data_r = {16'b0, dmem_rdata[15:0]};
                1'b1: load_data_r = {16'b0, dmem_rdata[31:16]};
                default: load_data_r = 32'b0;
            endcase
        end
        default: load_data_r = dmem_rdata;
    endcase
end
assign load_data = load_data_r;

// ─────────────────────────────────────────────────────────────
//  Write-Back Muxes
// ─────────────────────────────────────────────────────────────
//  MEMTOREG: 0 = ALU result  |  1 = load data
mux MEMTOREG_MUX (
    .sel (memtoreg),
    .in0 (alu_result),
    .in1 (load_data),
    .out (alu_or_load)
);

//  LUI MUX: 0 = ALU/MEM result  |  1 = immediate (LUI)
mux LUI_MUX (
    .sel (lui),
    .in0 (alu_or_load),
    .in1 (immediate),
    .out (rd_data)
);

//  Branch / Jump Decision

and branch_gate (branch_taken, branch, alu_result[0]);
or  jump_or_br  (b_or_j,       jump,   branch_taken);

mux PC_MUX1 (
    .sel (b_or_j),
    .in0 (32'd4),
    .in1 (immediate),
    .out (adder_in1)
);

mux PC_MUX2 (
    .sel (pcsrc),
    .in0 (pc_out),
    .in1 (rs1_data),
    .out (adder_in2)
);

Adder PC_adder (
    .in1 (adder_in2),
    .in2 (adder_in1),
    .out (pc_next_raw)
);

// Clear bit 0 for JALR (pcsrc=1)
assign pc_next = pcsrc ? {pc_next_raw[31:1], 1'b0} : pc_next_raw;

ProgramCounter program_counter (
    .clk   (clk),
    .rst   (rst),
    .stall (stall),    
    .in    (pc_next),
    .out   (pc_out)
);

endmodule
