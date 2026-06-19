# Load-Use Hazard Detection Validation Report

## Objective

Validate the ability of the processor to correctly handle load-use data hazards.

---

## Background

Forwarding successfully resolves most Read-After-Write (RAW) hazards between ALU instructions.

Example:

addi x1,x0,5

addi x2,x1,1

The ALU result exists early enough to be forwarded directly from EX/MEM or MEM/WB.

However, forwarding cannot resolve the following case:

lw  x1,0(x0)

add x2,x1,x0

because the memory data is not available when the ADD instruction reaches EX.

---

## Hazard Mechanism

At the moment of hazard detection:

Older Instruction (ID/EX):

lw x1,0(x0)

Younger Instruction (IF/ID):

add x2,x1,x0

Signals:

idex_mem_read = 1

idex_rd = x1

ifid_rs1 = x1

ifid_rs2 = x0

Hazard Condition Evaluates True.

---

## Hazard Response

The hazard detection unit generates:

pc_write = 0

ifid_write = 0

idex_flush = 1

Effects:

1. Program Counter frozen
2. IF/ID pipeline register frozen
3. NOP inserted into ID/EX

Result:

lw

NOP

add

The NOP acts as a bubble between producer and consumer.

---

## Test Configuration

Data Memory:

mem[0] = 25

Instruction Memory:

lw  x1,0(x0)

add x2,x1,x0

jal x0,0

---

## Simulation Results

Observed:

Cycle 3:

Hazard detected

Cycle 4:

Pipeline frozen

Bubble inserted

Cycle 6:

x1 = 25

Cycle 8:

x2 = 25

Result:

Correct execution obtained.

---

## Key Learning

A bubble does not stall the entire pipeline.

Only younger instructions are delayed.

Older instructions continue progressing through the pipeline.

Pipeline During Hazard:

Cycle 3:

ID/EX = lw

IF/ID = add

Cycle 4:

MEM = lw

ID/EX = bubble

IF/ID = add

Cycle 5:

WB = lw

EX = add

The load instruction continues executing while the dependent ADD instruction waits.

---

## Conclusion

The processor now supports:

* Forwarding-based hazard resolution
* Load-use hazard detection
* Bubble insertion
* Pipeline stalling

This completes the standard data hazard handling architecture used in classical 5-stage RISC-V pipelines.
