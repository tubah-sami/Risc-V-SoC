# ==============================================================================

set sdc_version 1.2
current_design soc_top

# ── 1. Clock Definition ───────────────────────────────────────────────────────
# 50 MHz system clock (20.0 ns period, 50% duty cycle)
create_clock -name clk -period 25.0 -waveform {0.0 12.5} [get_ports {clk}]

# Clock network margins (25% of period = 5.0 ns uncertainty)
set_clock_uncertainty 6.25 [get_clocks {clk}]
set_clock_transition 0.3 [get_clocks {clk}]

# ── 2. Design Rules & Limits ──────────────────────────────────────────────────
set_max_fanout 15 [current_design]
set_max_transition 1.5 [current_design]
set_max_capacitance 0.5 [current_design]

# ── 3. Input Delays ───────────────────────────────────────────────────────────
# Budgeted at 60% of clock period (12.0 ns)
set_input_delay 15.0 -clock [get_clocks {clk}] [get_ports {gpio_in[*]}]
set_input_delay 15.0 -clock [get_clocks {clk}] [get_ports {uart_rx}]

# ── 4. Output Delays ──────────────────────────────────────────────────────────
# Budgeted at 40% of clock period (8.0 ns)
set_output_delay 10.0 -clock [get_clocks {clk}] [get_ports {gpio_out[*]}]
set_output_delay 10.0 -clock [get_clocks {clk}] [get_ports {uart_tx}]
set_output_delay 10.0 -clock [get_clocks {clk}] [get_ports {pwm_out}]

# ── 5. Driving Cell & External Load ───────────────────────────────────────────
# Exclude the clock port from driving-cell constraints
set in_ports [remove_from_collection [all_inputs] [get_ports {clk}]]

# Artisan TSMC 0.18um standard buffer cell BUFX4 (Input: A, Output: Y)
set_driving_cell -lib_cell BUFX4 -pin Y $in_ports

# External capacitive load on primary outputs (50 fF)
set_load 0.05 [all_outputs]

# ── 6. Path Exceptions ────────────────────────────────────────────────────────
# rst_i is an asynchronous reset driven externally and sampled by a 2-stage
# synchronizer flop chain in soc_top. It is excluded from synchronous path timing.
set_false_path -from [get_ports {rst_i}]
