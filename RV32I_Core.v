`include "RISCV_PKG.vh"

module RV32I_Core #(
    parameter IMEM_INIT = "imem.mem"    // instruction memory init file
) (
    input wire clk,
    input wire rst,

    output wire [31:0] dmem_addr,   
    output wire [31:0] dmem_wdata,  
    output wire		  dmem_we,     
    output wire		  dmem_re,     
    output wire [3:0]  dmem_be,     

    input  wire [31:0] dmem_rdata,  
    input  wire		  dmem_ack,    

    output wire [31:0] pc_out       
);


wire [31:0] imem_addr;
wire [31:0] imem_rdata;

wire [31:0] dmem_addr_i;
wire [31:0] dmem_wdata_i;
wire			dmem_we_i;
wire			dmem_re_i;
wire [3:0]  dmem_be_i;
wire [31:0] pc_out_i;

wire stall = (dmem_we_i | dmem_re_i) & ~dmem_ack;

InstrSRAM #(
    .DEPTH     (`IMEM_DEPTH),
    .INIT_FILE (IMEM_INIT)
) u_imem (
    .clk   (clk),
    .ce    (1'b1),
    .addr  (imem_addr),
    .rdata (imem_rdata)
);

// ─────────────────────────────────────────────────────────────
//  Datapath (SCDP)
// ─────────────────────────────────────────────────────────────
SCDP u_scdp (
    .clk        (clk),
    .rst        (rst),
    .stall      (stall),
    // Instruction memory
    .imem_addr  (imem_addr),
    .imem_rdata (imem_rdata),
    // Data memory
    .dmem_addr  (dmem_addr_i),
    .dmem_wdata (dmem_wdata_i),
    .dmem_we    (dmem_we_i),
    .dmem_re    (dmem_re_i),
    .dmem_be    (dmem_be_i),
    .dmem_rdata (dmem_rdata),
    // Debug
    .pc_out_dbg (pc_out_i)
);

// ─────────────────────────────────────────────────────────────
//  Output Assignments
// ─────────────────────────────────────────────────────────────
assign dmem_addr  = dmem_addr_i;
assign dmem_wdata = dmem_wdata_i;
assign dmem_we    = dmem_we_i;
assign dmem_re    = dmem_re_i;
assign dmem_be    = dmem_be_i;
assign pc_out     = pc_out_i;

endmodule