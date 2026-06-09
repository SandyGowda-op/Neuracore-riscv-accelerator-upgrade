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

### Entry 2 - Open Source Simulation Validation

Successfully compiled and simulated the baseline FPGA design using Icarus Verilog under Ubuntu 22.04 WSL.

Observations:

* Instruction memory loaded successfully.
* Data memory loaded successfully.
* Program counter advanced correctly.
* Register file writeback activity observed.
* Pipeline execution verified.
* AI accelerator launch sequence observed.
* MMUL busy signaling verified.
* MAC operations initiated successfully.

Result:

The original Vivado-validated design is now confirmed to execute correctly under the open-source simulation flow, establishing a golden reference for future upgrades.


### Observation

During Phase 0 validation, CPU execution and MMUL launch were successfully observed under Icarus Verilog.

However, MMUL MAC outputs were all zero despite non-zero matrix initialization files.

Preliminary analysis suggests that A.mem and B.mem were not present in the simulation working directory, causing matrix memories to initialize incorrectly.

This issue will be investigated and resolved before accelerator baseline validation is closed.

### MMUL Investigation

The matrix multiplier does not currently use external memory files.

Matrices A and B are initialized internally as diagonal matrices using an RTL initial block.

This explains the predominantly zero-valued MAC operations observed during simulation.

The external files A.mem and B.mem are currently unused and will later be replaced by a scratchpad SRAM + DMA based data-loading mechanism.

### Entry 3 - Simulation Automation

Created automated simulation infrastructure for the open-source verification flow.

Scripts Added:

* scripts/run_cpu_tb.sh
* scripts/run_mmul_tb.sh
* scripts/clean.sh

Results:

* CPU simulation successfully reproduced under Icarus Verilog.
* MMUL simulation infrastructure established.
* Manual simulation commands replaced by reusable automation scripts.

Impact:
This establishes the foundation for future regression testing, SystemVerilog migration, hazard verification, and coverage-driven verification.

### Entry 4 - First Yosys Compatibility Issue

During initial Yosys synthesis attempts, synthesis failed in data_memory.v due to the presence of simulation-only system tasks ($fopen).

Observation:

* The design simulates correctly under Icarus Verilog.
* Vivado accepted the RTL.
* Yosys rejected simulation-only file I/O constructs.

Impact:
This highlights the distinction between simulation code and synthesizable RTL and motivates a cleanup pass before ASIC-oriented synthesis.

