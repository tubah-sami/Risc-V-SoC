`include "RISCV_PKG.vh"

//Behavioral Instruction SRAM  (1024 × 32-bit)

module InstrSRAM #(
    parameter DEPTH     = `IMEM_DEPTH,   // 1024 words
    parameter INIT_FILE = "imem.mem"     
) (
    input  wire        clk,              
    input  wire        ce,               
    input  wire [31:0] addr,             
    output wire [31:0] rdata             // instruction word
);

// ── Storage array ─────────────────────────────────────────────
(* ram_style = "block" *)               // macro replaces this
reg [31:0] mem [0:DEPTH-1];

integer i;
initial begin
    for (i = 0; i < DEPTH; i = i + 1)
        mem[i] = 32'h0000_0013;         // pre-fill with NOP 
    if (INIT_FILE != "")
        $readmemh(INIT_FILE, mem);
end

// ── Asynchronous read 
wire [`IMEM_ADDR_BITS-1:0] word_addr = addr[`IMEM_ADDR_BITS+1 : 2];

assign rdata = ce ? mem[word_addr] : 32'h0000_0013; // NOP when disabled

endmodule