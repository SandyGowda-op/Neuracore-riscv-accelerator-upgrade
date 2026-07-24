#!/bin/bash

mkdir -p build
mkdir -p tb/waveforms

echo "Compiling..."

iverilog -g2012 \
-o build/dfu_tb.out \
src/descriptor_pkg.sv \
src/descriptor_memory.sv \
src/descriptor_fetch_unit.sv \
tb/descriptor_fetch_unit_tb.sv

if [ $? -ne 0 ]; then
    echo "Compilation Failed!"
    exit 1
fi

echo "Running Simulation..."

vvp build/dfu_tb.out

echo "Opening GTKWave..."

gtkwave tb/waveforms/dfu_tb.vcd