#!/bin/bash

mkdir -p results

yosys -p "
read_verilog src/*.v
hierarchy -check -top riscv_pipeline
proc
opt
fsm
opt
memory
opt
techmap
opt
stat
write_verilog results/riscv_pipeline_netlist.v
" 2>&1 | tee results/yosys.log