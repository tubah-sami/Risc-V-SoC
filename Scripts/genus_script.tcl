# ============================================================
# run_genus_tsmc18.tcl  –  Genus Logic Synthesis Script
# ============================================================

# ── Directories & Files ──────────────────────────────────────
set DESIGN_NAME  "soc_top"
set WORK_DIR     "../synthesis"
set RTL_DIR      "../rtl"
set SDC_FILE     "../constraints/constraints_top.sdc"

# ── PDK Paths (TSMC 0.18um & SRAM Macros) ────────────────────
# Ensure this points to the directory containing your .lib files
set PDK_DIR      "../pdk/lib"

# Using the Slow (Worst-Case) corner for setup timing closure
set LIB_TYP      "slow.lib"
set RAM_LIB      "ram_256x16A_slow_syn.lib"

# ── 1. Set libraries ─────────────────────────────────────────
set_db init_lib_search_path $PDK_DIR
set_db library [list $LIB_TYP $RAM_LIB]

# ── 2. Read RTL ──────────────────────────────────────────────
# Using -sv to support both Verilog-2001 and SystemVerilog files
read_hdl -sv \
    $RTL_DIR/RISCV_PKG.vh \
    $RTL_DIR/Adder.v \
    $RTL_DIR/Alu.v \
    $RTL_DIR/AluCu.v \
    $RTL_DIR/ImmGen.v \
    $RTL_DIR/MainCu.v \
    $RTL_DIR/mux.v \
    $RTL_DIR/mux3x1.v \
    $RTL_DIR/ProgramCounter.v \
    $RTL_DIR/RegisterFile.v \
    $RTL_DIR/SCDP.v \
    $RTL_DIR/RV32I_Core.v \
    $RTL_DIR/axi_master_lite.v \
    $RTL_DIR/axi_interconnect.v \
    $RTL_DIR/gpio_peripheral.sv \
    $RTL_DIR/axi4lite_gpio.sv \
    $RTL_DIR/pwm_rtl.sv \
    $RTL_DIR/axi4lite_pwm.sv \
    $RTL_DIR/timer_peripheral.sv \
    $RTL_DIR/axi4lite_timer.sv \
    $RTL_DIR/uart_rx_module.sv \
    $RTL_DIR/uart_tx_module.sv \
    $RTL_DIR/axi4lite_uart.sv \
    $RTL_DIR/soc_top.v

# ── 3. Elaborate ─────────────────────────────────────────────
elaborate $DESIGN_NAME
check_design -unresolved

# ── 4. Read constraints ──────────────────────────────────────
read_sdc $SDC_FILE

# ── 5. Synthesize ────────────────────────────────────────────
syn_generic
syn_map
syn_opt

# ── 6. Reports ───────────────────────────────────────────────
report_timing               > $WORK_DIR/reports/timing.rpt
report_area                 > $WORK_DIR/reports/area.rpt
report_power                > $WORK_DIR/reports/power.rpt
report_gates                > $WORK_DIR/reports/gates.rpt
report_qor                  > $WORK_DIR/reports/qor.rpt

# ── 7. Write outputs ─────────────────────────────────────────
write_hdl > $WORK_DIR/outputs/${DESIGN_NAME}_netlist.v
write_sdc > $WORK_DIR/outputs/${DESIGN_NAME}_mapped.sdc
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge  -setuphold split > $WORK_DIR/outputs/${DESIGN_NAME}_delays.sdf
write_db  $WORK_DIR/outputs/${DESIGN_NAME}_genus.db

puts "\n=== Genus synthesis complete ==="
puts "Netlist: $WORK_DIR/outputs/${DESIGN_NAME}_netlist.v"
