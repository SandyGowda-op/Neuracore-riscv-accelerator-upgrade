# RISC-V AI Accelerator Upgrade Project

## Engineering Journal

### Entry 0 - Baseline FPGA Implementation

**Date:** 2026-06-09

### Project Overview

The project consists of a custom 5-stage pipelined RISC-V CPU integrated with a matrix multiplication AI accelerator. The design has been successfully simulated, synthesized, implemented, and validated on an Artix-7 FPGA using Vivado.

### Current CPU Architecture

* 5-stage RISC-V pipeline

  * IF
  * ID
  * EX
  * MEM
  * WB
* Pipeline registers:

  * IF/ID
  * ID/EX
  * EX/MEM
  * MEM/WB
* Register file
* Immediate generator
* ALU
* Instruction memory
* Data memory

### Current Accelerator Architecture

* Matrix multiplication accelerator
* Memory-mapped accelerator interface (MMIO)
* CPU stalls while accelerator is busy
* Fixed matrix size implementation

### Current Verification Methodology

* Directed Verilog testbenches
* CPU functionality testbench
* Matrix multiplication accelerator testbench

### Current RTL Language

* Verilog HDL

### FPGA Implementation Status

* Successfully synthesized in Vivado
* Successfully implemented on Artix-7 FPGA
* Functional validation completed

### Timing Results (Vivado)

* Worst Negative Slack (WNS): +0.382 ns
* Total Negative Slack (TNS): 0 ns
* Failing Endpoints: 0

### Existing Limitations

CPU:

* No forwarding unit
* No hazard detection unit
* No load-use hazard handling
* No branch prediction

Accelerator:

* Fixed-size matrix multiplier
* No scratchpad SRAM
* No DMA engine
* No double buffering

Verification:

* No SystemVerilog assertions
* No functional coverage
* No constrained-random verification
* No formal verification

### Upgrade Roadmap

Phase 0:

* Open-source flow validation
* Icarus Verilog
* Verilator
* Yosys
* SystemVerilog migration

Phase 1:

* Hazard detection
* Data forwarding
* Load-use stall handling

Phase 2:

* Custom ISA extension
* FMAC instruction
* ReLU instruction

Phase 3:

* Parameterized matrix accelerator
* Scratchpad SRAM
* DMA controller
* Double buffering

Phase 4:

* Assertions
* Cocotb verification
* Formal verification
* Coverage collection

Phase 5:

* OpenSTA timing analysis
* OpenROAD physical design flow
* ASIC-style implementation


### Entry 1 - Open Source Flow Setup

- Migrated project to WSL Ubuntu 22.04
- Initialized Git repository
- Created upgrade branch structure
- Created baseline FPGA commit
- Installed and verified:
  - Icarus Verilog
  - Verilator
  - Yosys
  - GTKWave
- Identified memory initialization dependencies:
  - instruction_memory.mem
  - data_memory.mem
  - A.mem
  - B.mem
- Beginning Phase 0 validation under open-source toolchain.