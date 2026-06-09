#!/bin/bash

set -e

echo "================================="
echo " Running Yosys Synthesis"
echo "================================="

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
" | tee results/yosys.log

echo ""
echo "================================="
echo " Synthesis Complete"
echo "================================="
echo ""

grep -A20 "Number of cells" results/yosys.log || true