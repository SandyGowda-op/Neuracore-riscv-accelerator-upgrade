# Accelerator Synchronization Design

## Problem Statement

The CPU was capable of reading the MMUL result register before the matrix multiplication operation had completed.

Example:

```assembly
lw x3,8(x1)
```

The load instruction could consume invalid accelerator data.

---

# Solution

A dedicated accelerator RAW hazard detector was introduced.

Signals:

```verilog
reading_mmul_result
accel_raw_hazard
```

---

# Hazard Detection Logic

The detector identifies:

1. A load instruction.
2. Accessing MMUL result register.
3. Result not yet available.

Condition:

```verilog
reading_mmul_result &&
!mmul_result_valid
```

---

# Pipeline Stall Mechanism

When a hazard is detected:

```text
pc_write   = 0
ifid_write = 0
idex_flush = 1
```

Effects:

```text
Freeze Program Counter
Freeze IF/ID Register
Insert Bubble into EX Stage
```

---

# Stall Release Mechanism

The pipeline resumes when:

```verilog
mmul_result_valid == 1
```

This guarantees:

```text
Result Available
↓
Load Allowed
```

---

# Why mmul_busy Was Not Used

mmul_busy indicates accelerator activity.

It does not guarantee result availability.

Example:

```text
mmul_busy = 0
```

can mean:

1. Accelerator never started.
2. Accelerator completed.

Therefore:

```text
mmul_busy
```

is not a reliable synchronization signal.

Instead:

```text
mmul_result_valid
```

directly indicates data availability.

---

# Verification Results

Verified:

* Hazard Detection
* Pipeline Stall
* Pipeline Resume
* Correct Data Consumption

Status:

PASS
