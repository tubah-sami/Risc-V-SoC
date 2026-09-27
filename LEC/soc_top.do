set log file soc_top_lec.log -replace

read library -liberty ../pdk/lib/slow.lib ../pdk/lib/ram_256x16A_slow_syn.lib -both

read design \
    ../rtl/RISCV_PKG.vh \
    ../rtl/Adder.v \
    ../rtl/Alu.v \
    ../rtl/AluCu.v \
    ../rtl/ImmGen.v \
    ../rtl/MainCu.v \
    ../rtl/mux.v \
    ../rtl/mux3x1.v \
    ../rtl/ProgramCounter.v \
    ../rtl/RegisterFile.v \
    ../rtl/SCDP.v \
    ../rtl/RV32I_Core.v \
    ../rtl/axi_master_lite.v \
    ../rtl/axi_interconnect.v \
    ../rtl/gpio_peripheral.sv \
    ../rtl/axi4lite_gpio.sv \
    ../rtl/pwm_rtl.sv \
    ../rtl/axi4lite_pwm.sv \
    ../rtl/timer_peripheral.sv \
    ../rtl/axi4lite_timer.sv \
    ../rtl/uart_rx_module.sv \
    ../rtl/uart_tx_module.sv \
    ../rtl/axi4lite_uart.sv \
    ../rtl/soc_top.v \
    -systemverilog -golden -root RV32I_Core

read design ../synthesis/outputs/soc_top_netlist.v -verilog -revised -root RV32I_Core

set flatten model -seq_constant
set flatten model -seq_constant_x_to 0
set analyze option -auto

set system mode lec
add compared points -all
compare

report verification -summary
