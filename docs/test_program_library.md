# RISC-V Accelerator Upgrade – Test Program Library

## Purpose

This document stores all instruction memory programs used during CPU, pipeline, forwarding, hazard detection, branch, memory, and accelerator verification.

Usage:

1. Copy the required program.

2. Paste it into:

   mem files/instruction_memory.mem

3. Run:

   ./scripts/run_cpu_tb.sh

---

# Test 1 – MMUL Accelerator Trigger Test

## Purpose

Verify:

* LUI instruction execution
* ADDI instruction execution
* Store operation
* MMUL memory-mapped trigger
* CPU stall during MMUL operation

## Program

```text
000010B7

00000013
00000013

00100113

00000013
00000013

0020A023

00000013
00000013
00000013
00000013
00000013

0000006F
```

## Expected Behaviour

* x1 = 0x00001000
* x2 = 0x00000001
* Store to MMUL address space
* MMUL begins operation
* CPU stalls while MMUL is busy

---

# Test 2 – Forwarding Verification

# Forwarding Verification Procedure

## Setup

Backup the current MMUL program if required.

Copy the forwarding test program into:

mem files/instruction_memory.mem

Program:

00500093
00108113
00110193
00118213
0000006F

Run:

./scripts/run_cpu_tb.sh

---

## Expected Architectural State

| Register | Expected Value |
| -------- | -------------- |
| x1       | 5              |
| x2       | 6              |
| x3       | 7              |
| x4       | 8              |

---

## Hazard Chain

Instruction 1:

addi x1,x0,5

Instruction 2:

addi x2,x1,1

RAW Dependency:

x2 depends on x1

Expected Forwarding:

EX/MEM → EX

---

Instruction 3:

addi x3,x2,1

RAW Dependency:

x3 depends on x2

Expected Forwarding:

EX/MEM or MEM/WB → EX

---

Instruction 4:

addi x4,x3,1

RAW Dependency:

x4 depends on x3

Expected Forwarding:

EX/MEM or MEM/WB → EX

---

## Pass Criteria

PASS if:

x1 = 5
x2 = 6
x3 = 7
x4 = 8

and no unexpected values appear during execution.

---

## Failure Indicators

Potential forwarding failure:

x1 = 5
x2 = 1
x3 = 1
x4 = 1

or any incorrect dependent register value.

Such behavior indicates stale register-file reads and missing forwarding paths.


# Test 3 – Load-Use Hazard Detection

Purpose:

Verify that the hazard detection unit correctly inserts a single bubble when a load-use dependency occurs.

Memory Initialization:

Address 0:

00000019

(Decimal 25)

Instruction Memory:

00002083

00008133

0000006F

Decoded Program:

lw  x1,0(x0)

add x2,x1,x0

jal x0,0

Expected Behavior:

Without Hazard Detection:

* ADD reaches EX stage before load data becomes available
* x2 receives incorrect value

With Hazard Detection:

* Hazard detector identifies dependency
* One bubble inserted
* Load completes successfully
* Forwarding supplies correct value to ADD
* x2 receives correct value

Expected Final Register Values:

x1 = 25

x2 = 25

Observed Result:

PASS

Key Observation:

Pipeline stalled for one cycle while the load instruction continued progressing through the pipeline.

Learning Outcome:

Forwarding alone cannot resolve load-use hazards because the memory value is not available early enough. Hazard detection and bubble insertion are required.


# Test 4 – Branch Tests


## Branch Taken Test

Assembly

addi x1,x0,5
addi x2,x0,5
beq  x1,x2,target
addi x3,x0,99
target:
addi x4,x0,7
jal x0,0

Machine Code

00500093
00500113
00208463
06300193
00700213
0000006F

Expected

R1 = 5
R2 = 5
R3 = 0
R4 = 7

Purpose

Verify branch comparator, target generation and pipeline flush logic.

---

## Branch Not Taken Test

Assembly

addi x1,x0,5
addi x2,x0,6
beq  x1,x2,target
addi x3,x0,99
target:
addi x4,x0,7
jal x0,0

Machine Code

00500093
00600113
00208463
06300193
00700213
0000006F

Expected

R1 = 5
R2 = 6
R3 = 99
R4 = 7

Purpose

Verify branch forwarding and correct comparator operation.

---

## Load-To-Branch Hazard Test

Assembly

lw   x1,0(x0)
beq  x1,x0,target
addi x3,x0,99
target:
addi x4,x0,7
jal x0,0

Machine Code

00002083
00008463
06300193
00700213
0000006F

Data Memory

Address 0:
00000019

Expected

R1 = 25
R3 = 99
R4 = 7

Purpose

Verify forwarding of memory data directly into the branch comparator and elimination of load-to-branch RAW hazards.

# Test 5 – Reserved for Data Memory Verification

Status:

Not yet implemented.

---

# Test 6 – Reserved for Full Pipeline Regression

Status:

Not yet implemented.

---

# Change Log

| Date       | Test Added                    | Notes                          |
| ---------- | ----------------------------- | ------------------------------ |
| 2026-06-13 | MMUL Accelerator Trigger Test | Initial accelerator validation |
| 2026-06-13 | Forwarding Verification Test  | First RAW hazard validation    |

```
```
