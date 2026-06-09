#!/bin/bash

set -e

echo "================================="
echo " Running CPU Testbench"
echo "================================="

rm -rf build/cpu
mkdir -p build/cpu

cp "mem files/instruction_memory.mem" build/cpu/
cp "mem files/data_memory.mem" build/cpu/

iverilog -g2012 \
-o build/cpu/cpu.out \
src/*.v \
tb/riscv_pipeline_tb.v

cd build/cpu

vvp cpu.out | tee cpu.log

echo ""
echo "CPU simulation completed."