read_liberty ~/eda_libs/NangateOpenCellLibrary_typical.lib

read_verilog yosys/riscv_pipeline_mapped.v

link_design riscv_pipeline

create_clock -name clk -period 10 [get_ports clk]

report_checks -path_delay max -fields {slew cap input_pins} > opensta/timing_report.txt

report_wns > opensta/wns.txt

report_tns > opensta/tns.txt

