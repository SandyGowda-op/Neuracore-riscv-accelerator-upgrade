# Comparative Study of Pipeline Execution With and Without Forwarding

## Objective

The objective of this study is to evaluate the impact of the forwarding network on the performance and correctness of the 5-stage RISC-V pipeline implemented in the RISC-V Accelerator Upgrade project.

The forwarding network was introduced to resolve Read-After-Write (RAW) data hazards without introducing pipeline stalls.

---

# Test Program

The following instruction sequence was used to validate forwarding:

```assembly
addi x1, x0, 5
addi x2, x1, 1
addi x3, x2, 1
addi x4, x3, 1
```

Machine Code:

```text
00500093
00108113
00110193
00118213
0000006F
```

Expected Register Values:

| Register | Expected Value |
| -------- | -------------- |
| x1       | 5              |
| x2       | 6              |
| x3       | 7              |
| x4       | 8              |

---

# Data Hazard Analysis

The instruction sequence contains consecutive RAW hazards.

Instruction 2 depends on the result of Instruction 1.

```assembly
addi x1,x0,5
addi x2,x1,1
```

Instruction 3 depends on the result of Instruction 2.

```assembly
addi x2,x1,1
addi x3,x2,1
```

Instruction 4 depends on the result of Instruction 3.

```assembly
addi x3,x2,1
addi x4,x3,1
```

These dependencies occur before the producing instructions complete the Write Back (WB) stage.

---

# Pipeline Execution Without Forwarding

## Scenario

Assume no forwarding network exists.

When Instruction 2 reaches the Execute stage, Instruction 1 has not yet written its result into the register file.

Pipeline Timing:

| Cycle | I1  | I2  | I3 | I4 |
| ----- | --- | --- | -- | -- |
| 1     | IF  |     |    |    |
| 2     | ID  | IF  |    |    |
| 3     | EX  | ID  | IF |    |
| 4     | MEM | EX  | ID | IF |
| 5     | WB  | MEM | EX | ID |

At Cycle 4:

Instruction 2 requires x1.

However:

x1 has not yet reached WB.

Register file still contains:

```text
x1 = 0
```

Therefore:

```text
x2 = 0 + 1 = 1
```

Similarly:

```text
x3 = 1
x4 = 1
```

Possible Final Register State:

| Register | Value |
| -------- | ----- |
| x1       | 5     |
| x2       | 1     |
| x3       | 1     |
| x4       | 1     |

Result:

FAIL

The processor executes incorrect computations due to stale register values.

---

# Pipeline Execution With Forwarding

## Forwarding Logic

The forwarding unit compares:

* ID/EX source registers
* EX/MEM destination register
* MEM/WB destination register

and selects the most recent available result.

Forwarding Sources:

| Code | Source        |
| ---- | ------------- |
| 00   | Register File |
| 01   | MEM/WB        |
| 10   | EX/MEM        |

---

# Observed Simulation Results

The following simulation results were obtained from the forwarding-enabled processor.

## Cycle 3

Simulation Time:

```text
T = 35000 ns
```

Instruction:

```assembly
addi x1,x0,5
```

ALU Output:

```text
00000005
```

Result:

```text
x1 = 5
```

---

## Cycle 4

Simulation Time:

```text
T = 45000 ns
```

Instruction:

```assembly
addi x2,x1,1
```

ALU Output:

```text
00000006
```

Observation:

Instruction 2 successfully used the result of Instruction 1 before Write Back occurred.

Forwarding Path Used:

```text
EX/MEM → EX
```

Result:

```text
x2 = 6
```

---

## Cycle 5

Simulation Time:

```text
T = 55000 ns
```

Instruction:

```assembly
addi x3,x2,1
```

ALU Output:

```text
00000007
```

Observation:

Instruction 3 successfully received the forwarded value of x2.

Result:

```text
x3 = 7
```

---

## Cycle 6

Simulation Time:

```text
T = 65000 ns
```

Instruction:

```assembly
addi x4,x3,1
```

ALU Output:

```text
00000008
```

Observation:

Instruction 4 successfully received the forwarded value of x3.

Result:

```text
x4 = 8
```

---

# Register Write Back Results

Observed Register State:

## Cycle 6

```text
R1 = 00000005
```

## Cycle 7

```text
R2 = 00000006
```

## Cycle 8

```text
R3 = 00000007
```

## Cycle 9

```text
R4 = 00000008
```

Final Register State:

| Register | Value |
| -------- | ----- |
| x1       | 5     |
| x2       | 6     |
| x3       | 7     |
| x4       | 8     |

Result:

PASS

---

# Performance Comparison

| Metric                    | Without Forwarding | With Forwarding |
| ------------------------- | ------------------ | --------------- |
| RAW Hazard Handling       | Not Supported      | Supported       |
| Correctness               | Incorrect Results  | Correct Results |
| Pipeline Stalls Required  | Yes                | No              |
| ALU Dependency Resolution | Fails              | Successful      |
| Consecutive Dependencies  | Fail               | Pass            |
| Register Utilization      | Stale Values       | Latest Values   |
| Throughput                | Reduced            | Improved        |

---

# Engineering Significance

The forwarding network eliminates unnecessary waiting for the Write Back stage by supplying results directly from later pipeline stages to the Execute stage.

Benefits observed:

1. Correct execution of dependent instructions.
2. Elimination of unnecessary stalls for ALU-to-ALU dependencies.
3. Improved instruction throughput.
4. Better pipeline utilization.
5. Foundation for implementing advanced hazard management mechanisms.

---

# Conclusion

The forwarding network was successfully integrated and validated.

Simulation results demonstrate that dependent instructions correctly receive the latest operand values before register write back occurs.

The forwarding-enabled pipeline produced:

```text
x1 = 5
x2 = 6
x3 = 7
x4 = 8
```

whereas a non-forwarding pipeline would have produced incorrect results due to stale register reads.

Therefore, the forwarding network significantly improves both correctness and pipeline performance and represents a major architectural enhancement to the RISC-V processor.
