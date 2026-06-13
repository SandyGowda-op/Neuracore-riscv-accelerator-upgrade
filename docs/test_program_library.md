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

## Purpose

Verify:

* EX/MEM forwarding
* Consecutive RAW hazard handling
* MEM/WB forwarding path

Assembly:

```assembly
addi x1,x0,5
addi x2,x1,1
addi x3,x2,1
addi x4,x3,1
jal  x0,0
```

Program:

```text
00500093
00108113
00110193
00118213
0000006F
```

## Expected Register Values

| Register | Value |
| -------- | ----- |
| x1       | 5     |
| x2       | 6     |
| x3       | 7     |
| x4       | 8     |

Expected Result:

PASS if all values are correct.

---

# Test 3 – Reserved for Load-Use Hazard Verification

Status:

Not yet implemented.

---

# Test 4 – Reserved for Branch Flush Verification

Status:

Not yet implemented.

---

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
