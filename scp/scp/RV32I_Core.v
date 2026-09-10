`include "RISCV_PKG.vh"

module RV32I_Core (
    input  wire        clk,
    input  wire        rst,

    output wire [31:0] imem_addr,    
    input  wire [31:0] imem_rdata,   

    output wire [31:0] dsram_addr,
    output wire [31:0] dsram_wdata,
    output wire        dsram_we,     
    output wire [3:0]  dsram_be,     
    output wire        dsram_ce,     
    input  wire [31:0] dsram_rdata,  

    output wire [31:0] periph_addr,
    output wire [31:0] periph_wdata,
    output wire        periph_we,    
    output wire        periph_re,    
    output wire [3:0]  periph_be,
    output wire        periph_valid,
    input  wire [31:0] periph_rdata, 
    input  wire        periph_ack 
);


wire [31:0] dmem_addr_i;    
wire [31:0] dmem_wdata_i;   
wire        dmem_we_i;      
wire        dmem_re_i;      
wire [3:0]  dmem_be_i;      

//  Address Decoder
wire periph_sel = (dmem_addr_i[31:28] == 4'h4);
wire dsram_sel  = ~periph_sel;

//stall mechanism
wire mem_active = dmem_we_i | dmem_re_i;
wire stall      = periph_sel & mem_active & ~periph_ack;

//read data (data mem or peripherals)
wire [31:0] dmem_rdata_mux = periph_sel ? periph_rdata : dsram_rdata;

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
    .dmem_rdata (dmem_rdata_mux)
);

assign dsram_addr  = dmem_addr_i;
assign dsram_wdata = dmem_wdata_i;
assign dsram_we    = dmem_we_i & dsram_sel;   
assign dsram_be    = dmem_be_i;
assign dsram_ce    = dsram_sel & mem_active;                

assign periph_addr  = dmem_addr_i;
assign periph_wdata = dmem_wdata_i;
assign periph_we    = dmem_we_i & periph_sel;  
assign periph_re    = dmem_re_i & periph_sel;  
assign periph_be    = dmem_be_i;  
assign periph_valid = periph_sel & mem_active;

endmodule
