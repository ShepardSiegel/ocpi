create_clock -period 4 -name CLK CLk
set_input_delay 1 -clock CLK [all_inputs]
set_output_delay 1 -clock CLK [all_outputs]
