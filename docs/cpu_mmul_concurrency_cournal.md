# Engineering Journal Entry 04

## CPU and MMUL Concurrent Execution Verification

**Date:** 18 June 2026

### Objective

The original MMUL integration stalled the entire RV32I processor whenever the matrix multiplication accelerator was active. This prevented the processor from executing useful instructions during accelerator computation and effectively converted the MMUL into a blocking peripheral.

The objective of this experiment was to determine whether the CPU pipeline and MMUL accelerator could execute concurrently after removal of the global accelerator stall.

---

# Background

Previous implementation:

```verilog
wire cpu_stall = dbg_accel_busy;
```

Whenever the MMUL accelerator asserted the busy signal:

```text
MMUL busy = 1
```

the following components stopped:

* Program Counter (PC)
* IF/ID Pipeline Register
* MEM/WB Pipeline Register

This caused the entire processor to wait until MMUL computation completed.

---

# Design Modification

For experimental verification, the global stall mechanism was temporarily disabled.

Modified RTL:

```verilog
wire cpu_stall = 1'b0;
```

This allowed normal pipeline execution regardless of MMUL activity.

---

# Test Program

Assembly Program:

```assembly
lui  x1,0x1

addi x2,x0,1

sw   x2,0(x1)

addi x5,x0,5
addi x6,x0,6
addi x7,x0,7
addi x8,x0,8
addi x9,x0,9

jal  x0,0
```

Instruction Memory Contents:

```text
000010B7
00100113
0020A023
00500293
00600313
00700393
00800413
00900493
0000006F
```

---

# Expected Behaviour

The processor should:

1. Start MMUL operation.
2. Continue executing ADDI instructions.
3. Update general-purpose registers while MMUL remains active.
4. Maintain MMUL computation in parallel.

---

# Observations

Simulation output indicated:

```text
BUSY = 1
```

while simultaneously:

```text
R5 = 00000005
R6 = 00000006
R7 = 00000007
R8 = 00000008
R9 = 00000009
```

MMUL debug output also continued:

```text
MAC: C[0][0] += ...
MAC: C[0][1] += ...
MAC: C[0][2] += ...
...
```

throughout execution.

Program Counter advanced normally during MMUL computation.

---

# Result

PASS

The CPU successfully executed independent instructions while MMUL performed matrix multiplication.

The processor and accelerator were therefore proven capable of concurrent execution.

---

# Architectural Significance

Before modification:

```text
CPU
 ↓
Start MMUL
 ↓
Freeze CPU
 ↓
Wait 512 cycles
 ↓
Resume CPU
```

After modification:

```text
CPU
 ↓
Start MMUL
 ↓
Continue Instruction Execution

MMUL
 ↓
Continue Matrix Multiplication
```

This converts the MMUL from a blocking accelerator into a concurrently executing accelerator.

---

# Conclusion

The experiment successfully demonstrated CPU-accelerator parallelism. Independent processor instructions were executed correctly while MMUL remained active, proving that global stalling is not required for accelerator operation.

This milestone establishes the foundation for implementing fine-grained hazard-based synchronization instead of coarse-grained accelerator blocking.

