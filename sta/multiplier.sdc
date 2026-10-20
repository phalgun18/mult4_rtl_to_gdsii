create_clock -name clk -period 10 [get_ports clk]

# Input timing
set_input_delay -clock clk -max 2.0 [get_ports {a[*] b[*] rst_n}]
set_input_delay -clock clk -min 0.5 [get_ports {a[*] b[*] rst_n}]

# Output timing
set_output_delay -clock clk -max 2.0 [get_ports {p[*]}]
set_output_delay -clock clk -min 0.5 [get_ports {p[*]}]