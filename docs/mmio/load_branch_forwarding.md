# Load-To-Branch Hazard Investigation

Date:
2026-06-15

Phase:
Hazard Handling Completion

---

## Objective

Validate correct execution of branch instructions that depend on values loaded from memory.

---

## Problem Statement

Test Program:

lw   x1,0(x0)
beq  x1,x0,target

addi x3,x0,99

target:
addi x4,x0,7

Expected:

R1 = 25
R3 = 99
R4 = 7

Observed:

R1 = 25
R3 = 0
R4 = 7

The branch was incorrectly taken.

---

## Investigation

Hazard detector correctly reported:

mem_read = 1

idex_rd = 1

ifid_rs1 = 1

stall = 1

A one-cycle stall was inserted.

However, branch evaluation still observed:

rs1 = 0

rs2 = 0

which produced:

branch_taken = 1

despite the loaded value being 25.

---

## Root Cause

The branch forwarding network supported:

* EX/MEM ALU results
* MEM/WB writeback values

but did not support:

* Memory read data directly from MEM stage

The branch comparator therefore evaluated stale register file contents before writeback completed.

---

## Solution

Added MEM-stage forwarding path:

dmem_rdata
↓
Branch Comparator

Forwarding priority:

1. MEM-stage load data
2. EX/MEM ALU result
3. MEM/WB writeback value
4. Register file value

---

## Validation

Debug Observation:

Before Fix

BRANCH:
rs1 = 00000000

rs2 = 00000000

taken = 1

After Fix

BRANCH:
rs1 = 00000019

rs2 = 00000000

taken = 0

Final Register State

R1 = 25

R3 = 99

R4 = 7

Status

PASS

---

## Learning Outcome

Load instructions produce their final data in the MEM stage rather than the EX stage.

Forwarding only ALU results is insufficient for complete RAW hazard resolution.

Memory data must also participate in the forwarding network to correctly support dependent branch instructions.
