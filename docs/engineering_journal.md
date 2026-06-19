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


### Entry 5 - Open Source EDA Migration

Successfully migrated from Ubuntu package versions to OSS CAD Suite.

Previous tool versions:
- Yosys 0.9
- Verilator 4.038

Current tool versions:
- Yosys 0.64+351
- Verilator 5.049

Reason:
Improved SystemVerilog support, synthesis compatibility, OpenROAD/OpenSTA integration, and formal verification support.

This establishes the open-source ASIC-oriented toolchain for future development.

# Phase 0A – Open Source Flow Validation

## Objective

Validate the existing RISC-V + AI Accelerator design in an open-source RTL flow before beginning architectural upgrades.

Target flow:

* Icarus Verilog
* GTKWave
* Yosys
* OSS CAD Suite
* Future OpenROAD/OpenSTA integration

---

## Baseline Design Status

Existing project capabilities:

* 5-stage pipelined RV32I CPU
* Matrix multiplication accelerator
* FPGA implementation completed on Artix-7
* Vivado synthesis and implementation completed
* Functional simulation completed

---

## Repository Migration

Original project imported into:

riscv_accelerator_upgrade

Git workflow established:

* phase0_validation branch created
* Simulation scripts added
* Engineering journal created

---

## Simulation Infrastructure

Created automated scripts:

* scripts/run_cpu_tb.sh
* scripts/run_mmul_tb.sh
* scripts/clean.sh

Purpose:

* Standardized simulation execution
* Repeatable verification flow
* Easier migration to SystemVerilog/UVM later

---

## CPU Simulation Results

CPU testbench executed successfully.

Observed:

* Program counter increments correctly
* Instruction fetch functioning
* Register writes observed
* Memory operations observed
* Accelerator stall mechanism active

Example observations:

* x1 loaded with 0x1000
* x2 loaded with 0x1
* Store instruction executed
* MMUL start condition detected

Status:

PASS

---

## MMUL Accelerator Simulation Results

Observed:

* MMUL start signal asserted
* Busy signal asserted
* MAC operations executed sequentially

Example output:

MAC: C[0][0] += A[0][0] * B[0][0]
MAC: C[0][0] += A[0][1] * B[1][0]
...

Observation:

Simulation terminated before complete matrix verification because the provided testbench timeout was insufficient for full 8×8 completion.

Result:

Partial functional verification completed.

Future action:

Create dedicated accelerator verification environment.

---

## Open Source Toolchain Upgrade

Initial tool versions:

* Yosys 0.9
* Verilator 4.038

Upgraded to OSS CAD Suite.

New versions:

* Yosys 0.64+351
* Verilator 5.049

Benefits:

* Better SystemVerilog support
* Improved synthesis compatibility
* OpenROAD/OpenSTA availability
* ASIC-oriented flow support

---

## Synthesis Issues Encountered

### Issue 1 – Simulation-Only File I/O

Module:

data_memory.v

Original code:

$fopen(...)

Problem:

Yosys cannot synthesize simulation-only file operations.

Resolution:

Removed $fopen dependency.

Status:

Resolved.

---

### Issue 2 – Memory Initialization Path

Modules:

* instr_mem.v
* data_memory.v

Problem:

Yosys could not locate:

* instruction_memory.mem
* data_memory.mem

Resolution:

Simulation-only memory loading wrapped for synthesis compatibility.

Status:

Resolved.

---

### Issue 3 – Pipeline Register Synthesis Failure

Error:

ERROR: Multiple edge sensitive events found for this signal!

Investigation:

Failure occurred during synthesis of id_ex pipeline register.

Original logic:

if (rst || flush)

inside

always @(posedge clk or posedge rst)

Problem:

Mixing asynchronous reset behavior with synchronous flush control caused synthesis ambiguity.

Resolution:

Separated logic into:

if (rst)
else if (flush)
else

Status:

Resolved.

---

## Yosys Synthesis Results

Synthesis completed successfully.

Tool:

Yosys 0.64+351

Runtime:

Approximately 6.6 seconds

Peak memory:

278.8 MB

Generated:

* Synthesized netlist
* Module statistics

Status:

PASS

---

## Module Statistics

### riscv_pipeline

Cells: 607

### mmul_mem

Cells: 13,327

### register_file

Cells: 5,393

### data_memory

Cells: 67,732

### id_ex

Cells: 310

### if_id

Cells: 196

### ex_mem

Cells: 73

### mem_wb

Cells: 72

---

## Key Observation

The current data memory implementation synthesizes into:

67,732 cells

Reason:

The RTL memory array is implemented as flip-flops rather than SRAM macros.

Implication:

Strong motivation for future:

* Scratchpad memory
* DMA subsystem
* SRAM-oriented architecture

Expected benefits:

* Lower area
* Better scalability
* Improved accelerator throughput

---

## Research-Relevant Metrics Collected

Current baseline established:

* Functional CPU execution
* Functional accelerator execution
* Open-source synthesis flow
* Cell count statistics
* Memory implementation overhead

These results will serve as the reference point for:

1. Hazard Detection Unit
2. Forwarding Network
3. ISA Extensions
4. Scratchpad Memory
5. DMA Controller
6. OpenSTA Timing Analysis
7. OpenROAD Physical Design

---

## Phase 0A Status

Completed.

Next Phase:

Phase 0B – SystemVerilog Migration


## Phase 0A Baseline Synthesis Metrics

### Toolchain

Operating System:

* Ubuntu 22.04.5 LTS (WSL)

Simulation:

* Icarus Verilog 11.0
* GTKWave

Synthesis:

* Yosys 0.64+351

Verification:

* Verilator 5.049

Flow:

* OSS CAD Suite

---

### Design Statistics

Total Cells:

* 87,867

Total Wires:

* 10,393

Total Wire Bits:

* 90,478

Public Wires:

* 1,282

Ports:

* 109

Port Bits:

* 1,537

Submodules:

* 9

---

### Sequential Elements

DFFE_PP0N:

* 30

DFFE_PP0P:

* 3,184

DFFE_PP:

* 32,768

DFF_PP0:

* 231

Total Flip-Flops:

* 36,213

---

### Combinational Logic

MUX:

* 39,704

AND:

* 6,637

OR:

* 4,835

NOT:

* 273

XOR:

* 150

---

### Module Breakdown

riscv_pipeline:

* 607 cells

mmul_mem:

* 13,327 cells

register_file:

* 5,393 cells

data_memory:

* 67,732 cells

if_id:

* 196 cells

id_ex:

* 310 cells

ex_mem:

* 73 cells

mem_wb:

* 72 cells

immediate_gen:

* 157 cells

---

### Runtime Statistics

Yosys Runtime:

* ~6.63 seconds

Peak Memory:

* ~278.8 MB

---

### Key Observation

The dominant contributor to area is:

data_memory = 67,732 cells

This is significantly larger than:

mmul_mem = 13,327 cells

and larger than the complete CPU datapath.

This indicates that the current memory architecture is implemented as synthesized flip-flops rather than SRAM-style storage.

This observation motivates the future implementation of:

* Scratchpad memory
* DMA controller
* SRAM-oriented accelerator memory hierarchy

Expected benefits:

* Reduced area
* Improved scalability
* Better ASIC suitability
* Higher accelerator efficiency


## Open-Source Migration Issues Encountered

### Issue 1: Unsupported Simulation File Operations

File:

* data_memory.v

Error:

* $fopen unsupported during synthesis

Root Cause:

* Simulation-only system task used in synthesizable RTL.

Resolution:

* Removed file existence check and retained synthesis-compatible memory initialization strategy.

Status:

* Resolved

---

### Issue 2: Memory Initialization File Path

Files:

* instr_mem.v
* data_memory.v

Error:

* Cannot open instruction_memory.mem
* Cannot open data_memory.mem

Root Cause:

* Synthesis executed from a different working directory.

Resolution:

* Wrapped simulation-only initialization sections for synthesis compatibility.

Status:

* Resolved

---

### Issue 3: Legacy Toolchain Limitation

Original Toolchain:

* Yosys 0.9
* Verilator 4.038

Issue:

* Poor support for current RTL style and diagnostics.

Resolution:

* Migrated to OSS CAD Suite.

New Toolchain:

* Yosys 0.64+351
* Verilator 5.049

Status:

* Resolved

---

### Issue 4: Pipeline Register Synthesis Failure

File:

* id_ex.v

Error:

* Multiple edge sensitive events found for this signal

Root Cause:

* Reset and flush logic combined in the same conditional path:

if (rst || flush)

inside:

always @(posedge clk or posedge rst)

Resolution:

* Separated reset and flush handling:

if (rst)
else if (flush)
else

Status:

* Resolved

Impact:

* Full design synthesis completed successfully.


# Phase 1 – Hazard Detection and Forwarding Network

## Objective

Improve pipeline correctness and performance by adding:

* Data forwarding
* Hazard detection
* Stall generation
* Future branch flush support

The existing pipeline executes instructions correctly in simple cases but does not resolve RAW (Read After Write) hazards.

---

## Initial Datapath Analysis

Pipeline stages:

IF → ID → EX → MEM → WB

Existing pipeline registers:

* IF/ID
* ID/EX
* EX/MEM
* MEM/WB

Observation:

The design already contains a stall mechanism used by the MMUL accelerator:

cpu_stall = dbg_accel_busy

This can later be extended to support load-use hazard stalls.

---

## Forwarding Requirements Identified

Forwarding requires comparison between:

Current instruction source registers:

* rs1
* rs2

and older instruction destination registers:

* rd in EX/MEM
* rd in MEM/WB

Observation:

The destination register identifiers already existed:

* idex_rd
* exmem_rd
* memwb_rd

However, source register identifiers were discarded after the ID stage.

---

## Datapath Modification

Added preservation of source register addresses across the ID/EX pipeline register.

New signals:

* idex_rs1_addr
* idex_rs2_addr

Changes:

Previously:

.rs1_addr_out()
.rs2_addr_out()

Updated:

.rs1_addr_out(idex_rs1_addr)
.rs2_addr_out(idex_rs2_addr)

Purpose:

Allow forwarding and hazard detection units to compare register identifiers rather than register values.

---

## Verification of Datapath Modification

Simulation:

PASS

Synthesis:

PASS

Observation:

No functional behavior changed.

Only visibility of source register identifiers was added.

---

## Forwarding Unit Design

Created:

src/forwarding_unit.sv

Inputs:

* idex_rs1
* idex_rs2
* exmem_rd
* exmem_reg_write
* memwb_rd
* memwb_reg_write

Outputs:

* forward_a[1:0]
* forward_b[1:0]

Encoding:

00 = Normal register file path

01 = Forward from MEM/WB

10 = Forward from EX/MEM

---

## Forwarding Priority Decision

EX/MEM forwarding receives higher priority than MEM/WB forwarding.

Reason:

EX/MEM contains newer instruction results.

Example:

addi x1,x0,5
addi x1,x1,1
addi x2,x1,1

At execution of instruction 3:

MEM/WB contains old x1 value

EX/MEM contains newer x1 value

Forwarding must select EX/MEM.

---

## Verification Infrastructure Updates

Simulation scripts updated to compile:

src/*.v
src/*.sv

Reason:

Forwarding unit implemented in SystemVerilog.

Toolchain:

Icarus Verilog (SystemVerilog enabled via -g2012)

---

## Integration Status

Forwarding unit instantiated within riscv_pipeline.

Current status:

Control signals generated:

* forward_a
* forward_b

Forwarding muxes not yet connected.

CPU functional behavior remains unchanged.

Simulation:

PASS

Synthesis:

PASS

---

## Lessons Learned

Issue encountered:

Yosys synthesis initially reported:

Module forwarding_unit is not part of the design

Root cause:

SystemVerilog source file was not being read by synthesis flow.

Resolution:

Updated synthesis flow to include SystemVerilog sources.

Result:

Successful synthesis with forwarding unit present in hierarchy.

---

## Next Tasks

1. Connect forwarding muxes to ALU inputs
2. Verify EX/MEM forwarding
3. Verify MEM/WB forwarding
4. Implement load-use hazard detection
5. Extend existing stall logic
6. Add branch flush support
7. Create directed forwarding test programs

### Forwarding Unit Integration

Forwarding control unit successfully integrated into riscv_pipeline.

Signals added:

* forward_a[1:0]
* forward_b[1:0]

Location:

Forwarding unit instantiated after MEM/WB stage signal declarations and before module termination.

Verification:

Simulation PASS

Synthesis PASS

Forwarding unit appears in synthesized hierarchy.

Current state:

Forwarding control signals are generated but not yet connected to ALU operand selection muxes.

This provides a safe intermediate verification checkpoint before modifying datapath functionality.

Engineering rationale:

Separating control generation verification from datapath modification reduces debugging complexity and allows isolation of integration issues.


## Forwarding Datapath Integration

Objective:
Connect forwarding control signals to ALU operand selection.

Changes:

Added:
- forwarded_rs1
- forwarded_rs2

Forwarding sources:

EX/MEM:
- exmem_alu

MEM/WB:
- wb_data

Selection logic:

forward_a:
00 -> idex_rs1
01 -> wb_data
10 -> exmem_alu

forward_b:
00 -> idex_rs2
01 -> wb_data
10 -> exmem_alu

ALU updates:

Previous:

ALU_A = idex_rs1
ALU_B = idex_rs2 or immediate

Updated:

ALU_A = forwarded_rs1
ALU_B = forwarded_rs2 or immediate

Verification:

Simulation PASS
Synthesis PASS

Result:

Forwarding datapath successfully integrated into execution stage.

## Forwarding Verification Plan

Observation:

Existing instruction memory program exercises:
- LUI
- ADDI
- Store
- MMUL trigger

It does not generate RAW hazards.

Therefore a dedicated forwarding validation program is required.

Proposed sequence:

addi x1,x0,5
addi x2,x1,1
addi x3,x2,1
addi x4,x3,1

Expected final register values:

x1 = 5
x2 = 6
x3 = 7
x4 = 8

Purpose:

Validate EX/MEM and MEM/WB forwarding paths using back-to-back dependent instructions.

### Verification Infrastructure Improvement

Observation:

Current CPU testbench displays:

* PC
* Instruction
* ALU result
* x1
* x2
* Accelerator busy flag

Limitation:

Forwarding verification requires visibility of additional architectural registers.

Planned enhancement:

Expose and display:

* x3
* x4

This enables direct observation of chained RAW dependency execution during forwarding validation.

### Verification Visibility Enhancement

Objective:

Improve observability for forwarding verification.

Changes:

Exposed additional architectural registers:

* x3 (dbg_r3)
* x4 (dbg_r4)

Path:

register_file → riscv_pipeline → testbench

Reason:

Forwarding verification requires monitoring multiple dependent instructions:

addi x1,x0,5
addi x2,x1,1
addi x3,x2,1
addi x4,x3,1

Expected:

x1=5
x2=6
x3=7
x4=8

Result:

Testbench now provides sufficient visibility to validate forwarding behavior directly from simulation output.


## Forwarding Network Validation

Objective:

Verify correct resolution of RAW (Read After Write) hazards using forwarding.

Test Program:

addi x1,x0,5
addi x2,x1,1
addi x3,x2,1
addi x4,x3,1

Expected:

x1 = 5
x2 = 6
x3 = 7
x4 = 8

Simulation Results:

ALU outputs:

5
6
7
8

Final register values:

x1 = 5
x2 = 6
x3 = 7
x4 = 8

Observation:

Dependent instructions executed correctly without waiting for register writeback.

Conclusion:

Forwarding network successfully resolves consecutive RAW hazards.

Status:

PASS
Forwarding network validated.

## Hazard Detection Unit Design

Purpose:

Detect load-use hazards that cannot be resolved through forwarding.

Inputs:

- ifid_rs1
- ifid_rs2
- idex_rd
- idex_mem_read

Outputs:

- pc_write
- ifid_write
- idex_flush

Hazard condition:

ID/EX instruction is a load
AND
IF/ID instruction requires the loaded register

Response:

Freeze PC
Freeze IF/ID
Insert bubble into ID/EX

Status:

RTL Created
Not Yet Integrated

Load-Use Hazard Validation

Program:
lw  x1,0(x0)
add x2,x1,x0

Memory[0] = 25

Observed:
Cycle 3-4: pipeline stall detected
Cycle 6: x1 = 25
Cycle 8: x2 = 25

Result:
Single-cycle bubble inserted.
Dependent instruction delayed by one cycle.
Correct result obtained.

Conclusion:
Load-use hazard detection and stall mechanism validated.

Phase 3A

Extended immediate generator to support B-type branch immediates.

Added opcode:
1100011

Purpose:
Enable future implementation of BEQ and branch target computation.

Status:
Implemented
Validated by simulation and synthesis
Branch execution not yet integrated.

Observation:

BEQ instructions immediately following arithmetic instructions
may compare stale register values.

Experiment:

Inserted two NOPs before BEQ.

Result:

Branch behavior became correct.

Conclusion:

Branch comparator and branch flush logic are functional.
Remaining issue is branch operand RAW hazard handling.

## 2026-06-15 — Branch Hazard Completion

Completed full branch hazard support for the RV32I pipeline.

Implemented:

* Branch decode
* Branch target generation
* IF/ID flush mechanism
* Branch operand forwarding
* MEM-stage load forwarding into branch comparator

Debugging process revealed a load-to-branch RAW hazard.

Initial implementation forwarded:

* EX/MEM ALU results
* MEM/WB values

but branch instructions dependent on loads still failed because the loaded value existed only in the MEM stage when the branch comparator executed.

Added forwarding path:

dmem_rdata → Branch Comparator

This eliminated the need for a second stall cycle and allowed correct branch execution without software-inserted NOPs.

Final validation:

* Branch taken test: PASS
* Branch not taken test: PASS
* Load-to-branch hazard test: PASS

Pipeline hazard handling phase considered functionally complete for current CPU architecture.

## 2026-06-15 — Accelerator Structural Hazard Validation

Performed first directed accelerator hazard test.

Objective:

Determine whether multiple MMUL launch requests can corrupt an ongoing matrix multiplication operation.

Method:

Issued two consecutive MMUL start requests with minimal instruction spacing.

Observation:

Only one MMUL START event was observed.

Only one MMUL COMPLETE event was observed.

Root Cause:

The MMUL launch condition is protected by:

if (we && !mmul_busy)

which prevents a second operation from starting while the accelerator is active.

Outcome:

Structural Hazard Test #1 PASSED.

The accelerator correctly behaves as a single shared computational resource and rejects concurrent launch attempts.

## 2026-06-18 — Accelerator RAW Hazard Baseline

Performed baseline RAW hazard validation for MMUL accelerator.

Observation:

During MMUL execution the program counter remained fixed and no further instructions executed.

After MMUL completion, the program counter resumed normal operation.

Root Cause:

Global CPU stalling is tied directly to the MMUL busy signal.

wire cpu_stall = dbg_accel_busy;

Result:

Accelerator RAW hazards are currently avoided through complete processor stalling.

This serves as the baseline reference before introducing non-blocking execution and fine-grained accelerator hazard detection.

# Engineering Journal Entry

**Date:** 18 June 2026

## Project

RV32I Pipelined Processor with Memory-Mapped Matrix Multiplication (MMUL) Accelerator

---

## Objective

Extend the MMUL accelerator interface from a write-only peripheral into a software-visible accelerator capable of:

1. Reporting computation status through MMIO registers.
2. Providing result availability information.
3. Supporting future non-blocking CPU execution while MMUL computation is in progress.
4. Detecting accelerator Read-After-Write (RAW) hazards before result consumption.

---

## Work Completed

### 1. MMUL Status and Result Interface Verification

The MMIO interface was previously extended with:

| Address | Register | Purpose                  |
| ------- | -------- | ------------------------ |
| 0x1000  | CONTROL  | Start MMUL operation     |
| 0x1004  | STATUS   | busy + result_valid bits |
| 0x1008  | RESULT   | Read accelerator output  |

Verification was performed using directed software tests.

#### STATUS Register Test

Program:

```assembly
lui x1,0x1
lw  x3,4(x1)
jal x0,0
```

Observed:

```text
REGFILE WRITE: we_addr=3 we_data=00000000
```

Result:

```text
PASS
STATUS register correctly returned 0
```

---

#### RESULT Register Test

The RESULT register was temporarily forced to:

```verilog
rdata = 32'hDEADBEEF;
```

Program:

```assembly
lui x1,0x1
lw  x3,8(x1)
jal x0,0
```

Observed:

```text
R3 = DEADBEEF
```

Result:

```text
PASS
RESULT register read path verified
```

---

### 2. Accelerator RAW Hazard Detection

A new hazard detection mechanism was introduced to identify software attempts to read MMUL results before they become available.

Initial implementation:

```verilog
assign mmul_read_addr =
    rf_rs1_data + id_imm;
```

The detector failed to trigger.

---

## Root Cause Investigation

A directed test was executed:

```assembly
lui  x1,0x1
addi x2,x0,1
sw   x2,0(x1)
lw   x3,8(x1)
jal  x0,0
```

Expected:

```text
Accelerator RAW hazard detection
```

Observed:

```text
No detection
```

Analysis showed:

```text
rf_rs1_data contained stale data
```

because the LUI instruction had not yet written x1 back into the register file when the LW instruction entered Decode.

Therefore:

```text
rf_rs1_data = 0
id_imm      = 8
address     = 0x00000008
```

instead of:

```text
0x00001008
```

---

## Solution

The hazard detector was modified to reuse the already verified branch forwarding network.

Old implementation:

```verilog
assign mmul_read_addr =
    rf_rs1_data + id_imm;
```

New implementation:

```verilog
assign mmul_read_addr =
    branch_rs1_val + id_imm;
```

where:

```verilog
branch_rs1_val
```

contains forwarded values from:

* EX/MEM stage
* MEM/WB stage
* Register file

---

## Verification Results

After applying forwarding:

Simulation output:

```text
ACCEL RAW HAZARD DETECTED
```

Observed immediately before:

```assembly
lw x3,8(x1)
```

entered execution.

Result:

```text
PASS
Accelerator RAW hazard correctly detected.
```

---

## Key Technical Insight

The MMUL hazard detector experienced the same class of issue previously observed during branch implementation.

Both systems required:

```text
Decode-stage forwarding
```

because decisions are made before register writeback occurs.

This demonstrates that hazard detection logic must operate on the most recent architectural value, not necessarily the value currently stored inside the register file.

---

## Architecture Status

### Verified Features

✓ Load-use hazard detection

✓ Branch forwarding

✓ Branch hazard resolution

✓ MMIO CONTROL register

✓ MMIO STATUS register

✓ MMIO RESULT register

✓ MMUL result_valid flag

✓ Decode-stage accelerator RAW detection

✓ Decode-stage forwarding reuse

---

## Current Accelerator Behaviour

Current implementation:

```text
Start MMUL
↓
CPU globally stalls
↓
MMUL computes
↓
CPU resumes
```

Controlled by:

```verilog
wire cpu_stall = dbg_accel_busy;
```

---

## Next Development Objective

Replace global accelerator stalling with targeted RAW hazard stalling.

Target behaviour:

```text
Start MMUL
↓
CPU continues executing
↓
MMUL computes in parallel
↓
CPU stalls ONLY if software attempts
to read RESULT while result_valid = 0
```

Hazard condition:

```verilog
reading_mmul_result &&
!mmul_result_valid
```

Planned stall actions:

```verilog
pc_write   = 0;
ifid_write = 0;
idex_flush = 1;
```

This will convert the MMUL from a blocking coprocessor into a non-blocking memory-mapped accelerator.

---

## Lessons Learned

1. Accelerator hazards are architecturally identical to CPU RAW hazards.
2. Decode-stage decisions frequently require forwarding paths.
3. MMIO accelerators must expose CONTROL, STATUS, and RESULT interfaces to support software-driven synchronization.
4. Data readiness (`result_valid`) is a more useful architectural signal than accelerator activity (`busy`) when determining whether a result may be consumed.
5. Directed tests remain the fastest method for isolating pipeline and accelerator integration bugs.

## Journal Status

Milestone Achieved:

**Successful implementation and verification of decode-stage MMUL RAW hazard detection using forwarded register values.**

# Engineering Journal Entry

## 19 June 2026

### Objective

Finalize MMIO accelerator verification.

---

### Test 008A – Busy Protection

Objective:

Verify that MMUL ignores additional start requests while busy.

Result:

PASS

Observation:

```verilog
if (we && !mmul_busy)
```

correctly prevented re-entry into the accelerator.

---

### Test 008B – Polling Restart Investigation

Objective:

Verify restart capability using status register polling.

Result:

INCONCLUSIVE

Investigation:

Status register correctly returned:

```text
0
```

and was successfully written into x3.

Branch debug revealed:

```text
PC     = 0x10
IMM    = 0x08
TARGET = 0x18
```

The branch target skipped the polling loop.

Root Cause:

Incorrect hand-encoded BEQ immediate.

MMUL hardware functionality was not implicated.

---

### Conclusion

MMIO accelerator verification completed.

Verified Features:

* MMUL Start
* MMUL Completion
* Result Register
* Status Register
* CPU/MMUL Concurrency
* Accelerator RAW Hazard Detection
* Automatic Stall Release
* Busy Protection

Project Status:

MMIO Architecture Frozen

Next Phase:

Custom ISA Extensions
(FMAC + ReLU)


Date: <today>

Objective:
Complete custom accelerator ISA integration.

Work Completed:

1. Implemented FMAC_START instruction.
2. Implemented FMAC_READ instruction.
3. Added direct accelerator result interface.
4. Integrated FMAC_READ into EX/MEM/WB path.
5. Extended accelerator RAW hazard logic to support ISA instructions.
6. Verified automatic synchronization behavior.
7. Verified register writeback using non-zero accelerator result (12 decimal).

Results:

FMAC_START:
PASS

FMAC_READ:
PASS

FMAC_READ RAW Hazard:
PASS

CPU/MMUL Concurrency:
PASS

Outcome:

Phase 2 Custom Accelerator ISA completed successfully.

Next Phase:

Performance characterization and ISA-vs-MMIO comparison.