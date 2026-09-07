`include "RISCV_PKG.vh"


// DataSRAM.v  –  Behavioral Data SRAM  (1024 × 32-bit)        //

module DataSRAM #(
    parameter DEPTH = `DMEM_DEPTH   // 1024 words
) (
    input  wire        clk,         
    input  wire        ce,          
    input  wire [31:0] addr,        
    input  wire [31:0] wdata,       
    input  wire        we,          
    input  wire [3:0]  be,          
    output wire [31:0] rdata        
);

// ── Storage array ─────────────────────────────────────────────
(* ram_style = "block" *)
reg [31:0] mem [0:DEPTH-1];

integer i;
initial begin
    for (i = 0; i < DEPTH; i = i + 1)
        mem[i] = 32'h0000_0000;
end

wire [`DMEM_ADDR_BITS-1:0] word_addr = addr[`DMEM_ADDR_BITS+1 : 2];

// ── Asynchronous read ─────────────────────────────────────────
assign rdata = ce ? mem[word_addr] : 32'b0;

// ── Synchronous write with byte enables ───────────────────────
always @(posedge clk) begin
    if (ce && we) begin
        if (be[0]) mem[word_addr][ 7: 0] <= wdata[ 7: 0];
        if (be[1]) mem[word_addr][15: 8] <= wdata[15: 8];
        if (be[2]) mem[word_addr][23:16] <= wdata[23:16];
        if (be[3]) mem[word_addr][31:24] <= wdata[31:24];
    end
end

endmodule