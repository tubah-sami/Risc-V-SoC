# ####################################################################

#  Created by Genus(TM) Synthesis Solution 26.10-p002_1 on Fri Sep 11 12:13:06 PKT 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design soc_top

create_clock -name "clk" -period 25.0 -waveform {0.0 12.5} [get_ports clk]
set_clock_transition 0.3 [get_clocks clk]
set_load -pin_load 0.05 [get_ports {gpio_out[7]}]
set_load -pin_load 0.05 [get_ports {gpio_out[6]}]
set_load -pin_load 0.05 [get_ports {gpio_out[5]}]
set_load -pin_load 0.05 [get_ports {gpio_out[4]}]
set_load -pin_load 0.05 [get_ports {gpio_out[3]}]
set_load -pin_load 0.05 [get_ports {gpio_out[2]}]
set_load -pin_load 0.05 [get_ports {gpio_out[1]}]
set_load -pin_load 0.05 [get_ports {gpio_out[0]}]
set_load -pin_load 0.05 [get_ports uart_tx]
set_load -pin_load 0.05 [get_ports pwm_out]
set_false_path -from [get_ports rst_i]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks clk] -add_delay 15.0 [get_ports {gpio_in[7]}]
set_input_delay -clock [get_clocks clk] -add_delay 15.0 [get_ports {gpio_in[6]}]
set_input_delay -clock [get_clocks clk] -add_delay 15.0 [get_ports {gpio_in[5]}]
set_input_delay -clock [get_clocks clk] -add_delay 15.0 [get_ports {gpio_in[4]}]
set_input_delay -clock [get_clocks clk] -add_delay 15.0 [get_ports {gpio_in[3]}]
set_input_delay -clock [get_clocks clk] -add_delay 15.0 [get_ports {gpio_in[2]}]
set_input_delay -clock [get_clocks clk] -add_delay 15.0 [get_ports {gpio_in[1]}]
set_input_delay -clock [get_clocks clk] -add_delay 15.0 [get_ports {gpio_in[0]}]
set_input_delay -clock [get_clocks clk] -add_delay 15.0 [get_ports uart_rx]
set_output_delay -clock [get_clocks clk] -add_delay 10.0 [get_ports {gpio_out[7]}]
set_output_delay -clock [get_clocks clk] -add_delay 10.0 [get_ports {gpio_out[6]}]
set_output_delay -clock [get_clocks clk] -add_delay 10.0 [get_ports {gpio_out[5]}]
set_output_delay -clock [get_clocks clk] -add_delay 10.0 [get_ports {gpio_out[4]}]
set_output_delay -clock [get_clocks clk] -add_delay 10.0 [get_ports {gpio_out[3]}]
set_output_delay -clock [get_clocks clk] -add_delay 10.0 [get_ports {gpio_out[2]}]
set_output_delay -clock [get_clocks clk] -add_delay 10.0 [get_ports {gpio_out[1]}]
set_output_delay -clock [get_clocks clk] -add_delay 10.0 [get_ports {gpio_out[0]}]
set_output_delay -clock [get_clocks clk] -add_delay 10.0 [get_ports uart_tx]
set_output_delay -clock [get_clocks clk] -add_delay 10.0 [get_ports pwm_out]
set_max_fanout 15.000 [current_design]
set_max_transition 1.5 [current_design]
set_max_capacitance 0.5 [current_design]
set_driving_cell -lib_cell BUFX4 -library tsmc18 -pin "Y" [get_ports rst_i]
set_driving_cell -lib_cell BUFX4 -library tsmc18 -pin "Y" [get_ports {gpio_in[7]}]
set_driving_cell -lib_cell BUFX4 -library tsmc18 -pin "Y" [get_ports {gpio_in[6]}]
set_driving_cell -lib_cell BUFX4 -library tsmc18 -pin "Y" [get_ports {gpio_in[5]}]
set_driving_cell -lib_cell BUFX4 -library tsmc18 -pin "Y" [get_ports {gpio_in[4]}]
set_driving_cell -lib_cell BUFX4 -library tsmc18 -pin "Y" [get_ports {gpio_in[3]}]
set_driving_cell -lib_cell BUFX4 -library tsmc18 -pin "Y" [get_ports {gpio_in[2]}]
set_driving_cell -lib_cell BUFX4 -library tsmc18 -pin "Y" [get_ports {gpio_in[1]}]
set_driving_cell -lib_cell BUFX4 -library tsmc18 -pin "Y" [get_ports {gpio_in[0]}]
set_driving_cell -lib_cell BUFX4 -library tsmc18 -pin "Y" [get_ports uart_rx]
set_wire_load_mode "enclosed"
set_clock_uncertainty -setup 6.25 [get_clocks clk]
set_clock_uncertainty -hold 6.25 [get_clocks clk]
