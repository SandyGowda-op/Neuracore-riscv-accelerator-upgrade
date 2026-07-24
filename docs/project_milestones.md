# RISC-V Accelerator Upgrade – Project Milestones

## Overview

This document tracks major architectural milestones, validation checkpoints, tags, and commit history throughout the development of the RISC-V Accelerator Upgrade project.

---

# Baseline FPGA Design

Date: 2026-06-09

Commit:

1aa3d7f

Tag:

baseline_fpga

Description:

Initial FPGA implementation before upgrade work began.

Status:

PASS

---

# Phase 0A – Open Source Toolchain Validation

Date:

2026-06-09

Commit:

fac0d81

Tag:

phase0a_baseline

Description:

Validated the complete open-source development flow.

Achievements:

* OSS CAD Suite setup
* Yosys synthesis validation
* Icarus Verilog simulation validation
* Automated script infrastructure
* Documentation framework

Status:

PASS

---

# Phase 1 – Hazard Infrastructure Preparation

Date:

2026-06-12

Commit:

79348c0

Description:

Exposed source register addresses through the ID/EX pipeline register.

Purpose:

Enable forwarding and future hazard detection logic.

Signals Added:

* idex_rs1_addr
* idex_rs2_addr

Status:

PASS

---

# Phase 1A – Forwarding Unit Infrastructure

Date:

2026-06-12

Commit:

6b18fae

Description:

Added forwarding unit module.

Capabilities:

* RAW hazard comparison logic
* EX/MEM hazard detection
* MEM/WB hazard detection
* Forwarding priority resolution

Outputs:

* forward_a
* forward_b

Status:

PASS

---

# Phase 1B – Forwarding Control Integration

Date:

2026-06-13

Commit:

1023fc8

Description:

Integrated forwarding control unit into the pipeline.

Achievements:

* Forwarding unit instantiated
* Forwarding signals connected
* Control path validated

Status:

PASS

---

# Phase 1C – Forwarding Datapath Integration

Date:

2026-06-13

Commit:

e2d962a

Description:

Connected forwarding muxes into the Execute stage.

Added:

* forwarded_rs1
* forwarded_rs2

Forwarding Sources:

* EX/MEM
* MEM/WB

Status:

PASS

---

# Phase 1D – Verification Infrastructure

Date:

2026-06-13

Commit:

a7f956b

Description:

Added instruction memory test library and forwarding verification programs.

Added:

* test_program_library.md
* forwarding validation programs

Status:

PASS

---

# Phase 1E – Forwarding Network Validation

Date:

2026-06-13

Commit:

3d8f91c

Description:

Validated forwarding network using chained RAW hazards.

Test Program:

addi x1,x0,5
addi x2,x1,1
addi x3,x2,1
addi x4,x3,1

Observed Results:

Cycle 3:

ALU = 5

Cycle 4:

ALU = 6

Cycle 5:

ALU = 7

Cycle 6:

ALU = 8

Final Register State:

x1 = 5

x2 = 6

x3 = 7

x4 = 8

Conclusion:

Forwarding network successfully resolves consecutive RAW hazards.

Status:

PASS

---

# Phase 1F – Repository Cleanup

Date:

2026-06-13

Commit:

27475dc

Tag:

v0.3-forwarding-complete

Description:

Added repository hygiene improvements.

Changes:

* Added .gitignore
* Removed generated artifacts from version control workflow
* Established forwarding-complete release checkpoint

Status:

PASS

---

# Release Timeline

| Version                  | Commit  | Date       | Status               |
| ------------------------ | ------- | ---------- | -------------------- |
| baseline_fpga            | 1aa3d7f | 2026-06-09 | FPGA Baseline        |
| phase0a_baseline         | fac0d81 | 2026-06-09 | Toolchain Validation |
| v0.3-forwarding-complete | 27475dc | 2026-06-13 | Forwarding Complete  |

---

# Upcoming Milestones

## v0.4

Load-Use Hazard Detection

Planned Features:

* Hazard Detection Unit
* Pipeline Stall Generation
* Bubble Injection
* Load-use verification suite

---

## v0.5

Branch Hazard Handling

Planned Features:

* Branch flushing
* Pipeline recovery
* Control hazard validation

---

## v0.6

Performance Evaluation

Planned Features:

* CPI measurement
* Hazard statistics
* Pipeline efficiency analysis

---

## v0.7

Static Timing Analysis

Planned Features:

* OpenSTA flow
* Critical path identification
* Timing closure

---

## v0.8

Physical Design

Planned Features:

* OpenROAD flow
* Floorplanning
* Placement and routing

---

## v1.0

Research Release

Planned Deliverables:

* Complete RISC-V + Accelerator platform
* Documentation
* Benchmark results
* Conference/publication material

# Phase 2 – Load-Use Hazard Detection Validation

Date:

2026-06-13

Description:

Implemented and validated a hazard detection unit capable of identifying load-use data hazards that cannot be resolved through forwarding alone.

Motivation:

Forwarding successfully resolves ALU-to-ALU RAW dependencies but cannot resolve dependencies where a load instruction has not yet completed its memory access.

Example Hazard:

lw  x1,0(x0)

add x2,x1,x0

Problem:

The ADD instruction requires x1 in its EX stage before the load instruction has completed its MEM stage.

Implementation:

Hazard Detection Unit Inputs:

* ifid_rs1
* ifid_rs2
* idex_rd
* idex_mem_read

Hazard Condition:

idex_mem_read &&
(idex_rd != 0) &&
((idex_rd == ifid_rs1) ||
(idex_rd == ifid_rs2))

Control Actions:

* pc_write = 0
* ifid_write = 0
* idex_flush = 1

Effect:

* Freeze Program Counter
* Freeze IF/ID pipeline register
* Insert NOP into ID/EX pipeline register

Observed Results:

Test Memory:

mem[0] = 25

Test Program:

lw  x1,0(x0)

add x2,x1,x0

Observed Behavior:

* Pipeline stall observed between Cycle 3 and Cycle 4
* One bubble inserted
* x1 updated to 25 at Cycle 6
* x2 updated to 25 at Cycle 8

Conclusion:

Load-use hazards are now correctly detected and resolved through a combination of pipeline stalling and forwarding.

Status:

PASS

# Project Milestones

## Baseline FPGA CPU

Status: Complete

Features:

* RV32I pipeline operational
* Instruction memory operational
* Data memory operational
* UART/MMIO framework prepared

Git Tag:

* baseline_fpga

---

## Phase 0A: Open Source Flow Validation

Status: Complete

Features:

* Yosys synthesis validated
* Icarus simulation validated
* Open-source development flow established

Git Tag:

* phase0a_baseline

---

## Phase 1: Hazard Handling

Status: Complete

Features:

* Forwarding unit implemented
* EX/MEM forwarding
* MEM/WB forwarding
* Load-use hazard detection
* Pipeline stall insertion
* Branch decode
* Branch target generation
* Branch flush logic
* Branch operand forwarding
* Load-to-branch forwarding via MEM-stage data path

Validated Through:

* Forwarding tests
* Load-use hazard tests
* Branch taken tests
* Branch not taken tests
* Load-to-branch hazard tests

Git Tag:

* v0.3-forwarding-complete

Outcome:
Pipeline now resolves major RAW hazards without software-inserted NOPs.

Phase 2A Complete
-----------------
Custom ISA decode infrastructure implemented.

Features:
- custom-0 opcode reserved
- funct3-based instruction differentiation
- FMAC decode verified
- RELU decode verified

Status:
PASS

Next:
Phase 2B - RELU Execution Unit

## Phase 2B Complete – RELU Custom Instruction

Date:
19 June 2026

Objective:

Implement the first fully functional custom ISA instruction.

Instruction:

```assembly
relu rd, rs1
```

Architecture Changes:

* Added funct3 propagation through ID/EX pipeline register.
* Added dedicated RELU execution unit.
* Added custom instruction execution selection logic.
* Integrated RELU result into existing writeback path.

Verification:

Input:

```assembly
addi x1,x0,-1
relu x2,x1
```

Output:

```text
x2 = 0
```

Input:

```assembly
addi x3,x0,7
relu x4,x3
```

Output:

```text
x4 = 7
```

Result:

PASS

Project Status:

Phase 2B Complete

Next Milestone:

Phase 2C – FMAC_START Instruction

## Milestone M8 — Custom Accelerator ISA Complete

Date: <today>

Completed:

- FMAC_START custom instruction
- RELU custom instruction
- FMAC_READ custom instruction
- FMAC_READ RAW hazard detection
- Accelerator result register interface
- Direct accelerator result retrieval

Verification:

PASS

Impact:

Accelerator functionality can now be accessed entirely through ISA extensions without MMIO software sequences.

Status:

COMPLETE

## Descriptor Fetch Unit

✓ RTL Skeleton Completed

Features

- Parameterized module
- Package-based architecture
- Clean port interface
- Shadow register architecture
- Three-process FSM framework
- Compiles successfully using Icarus Verilog