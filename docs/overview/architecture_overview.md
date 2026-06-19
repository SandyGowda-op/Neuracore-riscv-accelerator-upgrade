# MMIO Accelerator Architecture Overview

## Project Summary

This project integrates a memory-mapped Matrix Multiplication (MMUL) accelerator with a 5-stage pipelined RV32I processor.

The design supports:

* Memory-Mapped Accelerator Access
* Pipeline Hazard Detection
* Data Forwarding
* Branch Resolution
* Accelerator RAW Hazard Synchronization
* Concurrent CPU and Accelerator Execution

---

# Processor Architecture

The processor implements a standard 5-stage pipeline:

```text
IF → ID → EX → MEM → WB
```

Components:

* Program Counter
* Instruction Memory
* Register File
* Immediate Generator
* ALU
* Data Memory
* Pipeline Registers

---

# Accelerator Architecture

The MMUL accelerator is memory mapped.

## MMIO Address Map

| Address | Function            |
| ------- | ------------------- |
| 0x1000  | MMUL Start Register |
| 0x1004  | Status Register     |
| 0x1008  | Result Register     |

---

## Status Register

Address:

```text
0x1004
```

Bit Definitions:

| Bit | Function          |
| --- | ----------------- |
| [0] | mmul_busy         |
| [1] | mmul_result_valid |

Status Encoding:

| Value | Meaning             |
| ----- | ------------------- |
| 0     | Idle                |
| 1     | Busy                |
| 2     | Result Ready        |
| 3     | Busy + Result Valid |

---

## Result Register

Address:

```text
0x1008
```

Current Output:

```text
C[0][0]
```

---

# Accelerator Control Flow

```text
CPU Store
↓
MMUL Start
↓
MMUL Busy
↓
Matrix Multiplication
↓
Result Available
↓
mmul_result_valid = 1
```

---

# Hazard Infrastructure

Implemented:

* Load-Use Hazard Detection
* EX/MEM Forwarding
* MEM/WB Forwarding
* Branch Forwarding
* Accelerator RAW Hazard Detection

---

# Verification Status

| Feature                 | Status |
| ----------------------- | ------ |
| MMUL Start              | PASS   |
| MMUL Completion         | PASS   |
| MMUL Result Register    | PASS   |
| MMUL Status Register    | PASS   |
| Accelerator RAW Hazard  | PASS   |
| CPU/MMUL Concurrency    | PASS   |
| Automatic Stall Release | PASS   |
