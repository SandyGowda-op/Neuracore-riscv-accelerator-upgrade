#!/bin/bash

set -e

echo "================================="
echo " Running MMUL Testbench"
echo "================================="

rm -rf build/mmul
mkdir -p build/mmul

iverilog -g2012 \
-o build/mmul/mmul.out \
src/*.v \
tb/riscv_pipeline_tb_cpu.v

cd build/mmul

vvp mmul.out | tee mmul.log

echo ""
echo "MMUL simulation completed."