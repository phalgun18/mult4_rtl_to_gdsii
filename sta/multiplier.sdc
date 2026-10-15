create_clock -name clk -period 10 [get_ports clk]

set_input_delay 0 -clock clk [get_ports a]
set_input_delay 0 -clock clk [get_ports b]
set_input_delay 0 -clock clk [get_ports rst_n]

set_output_delay 0 -clock clk [get_ports p]

