# Accelerator RAW Hazard Detection and Decode-Stage Forwarding Fix

**Date:** 18 June 2026

### Objective

Implement a hardware mechanism capable of detecting attempts by the CPU to read MMUL results before the accelerator has completed computation.

The goal was to identify and later stall only those instructions that consume accelerator-generated data while allowing all unrelated instructions to continue executing.

---

# Problem Statement

The MMUL accelerator exposes its result through a memory-mapped register:

```text
0x1008 -> MMUL Result Register
```

Software may attempt to execute:

```assembly
lw x3,8(x1)
```

before the matrix multiplication operation has completed.

In this scenario:

```text
MMUL = Producer
LW   = Consumer
```

The processor must detect the dependency and prevent the load from consuming invalid data.

---

# Initial Hazard Detection Logic

Initial implementation:

```verilog
assign mmul_read_addr =
    rf_rs1_data + id_imm;

assign reading_mmul_result =
    id_mem_read &&
    (mmul_read_addr == 32'h00001008);

assign accel_raw_hazard =
    reading_mmul_result &&
    !mmul_result_valid;
```

Expected behaviour:

```text
Load accesses 0x1008
↓
result_valid = 0
↓
Hazard detected
```

Observed behaviour:

```text
No hazard detected
```

---

# Directed Test Program

Assembly Program:

```assembly
lui  x1,0x1
addi x2,x0,1
sw   x2,0(x1)
lw   x3,8(x1)
jal  x0,0
```

Instruction Memory Contents:

```text
000010B7
00100113
0020A023
0080A183
0000006F
```

---

# Investigation

Additional debug instrumentation was inserted.

Observed:

```text
rf_rs1_data = 0
id_imm      = 8
```

Therefore:

```text
mmul_read_addr = 0x00000008
```

instead of:

```text
0x00001008
```

The detector therefore failed to recognize the MMUL result access.

---

# Root Cause Analysis

The source register x1 was produced by:

```assembly
lui x1,0x1
```

However, when the load instruction entered Decode:

```text
LUI had not yet reached Writeback
```

Consequently:

```text
Register File Value = stale
```

even though architecturally:

```text
x1 = 0x1000
```

should already be visible.

The detector was operating on stale register-file data.

---

# Architectural Insight

This failure was identical to the branch hazard previously encountered during branch implementation.

Both situations required:

```text
Decode-stage forwarding
```

rather than direct register-file access.

---

# Solution

The detector was modified to reuse the existing branch forwarding network.

Original implementation:

```verilog
assign mmul_read_addr =
    rf_rs1_data + id_imm;
```

Updated implementation:

```verilog
assign mmul_read_addr =
    branch_rs1_val + id_imm;
```

where:

```verilog
branch_rs1_val
```

contains forwarded values from:

* EX/MEM
* MEM/WB
* Register File

---

# Verification

After modification:

Simulation produced:

```text
ACCEL RAW HAZARD DETECTED
```

during execution of:

```assembly
lw x3,8(x1)
```

The detector correctly recognized:

```text
Address = 0x1008
```

while:

```text
mmul_result_valid = 0
```

---

# Results

PASS

The accelerator RAW detector successfully identified attempts to consume MMUL results before computation completed.

---

# Architectural Significance

The experiment demonstrated that:

```text
Accelerator hazards
```

and

```text
Pipeline RAW hazards
```

are fundamentally the same problem.

Both require access to the most recent architectural value rather than the value currently stored in the register file.

The forwarding infrastructure originally developed for branch resolution was successfully reused for accelerator hazard detection.

---

# Conclusion

The accelerator RAW hazard detector was successfully implemented and verified.

A decode-stage forwarding bug was identified, analyzed, and corrected.

This milestone established the foundation for accelerator-aware pipeline synchronization and enabled the subsequent implementation of targeted result-consumption stalls.
