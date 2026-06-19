# Branch Hazard Investigation Report

Date:

2026-06-15

Phase:

Phase 3 – Control Hazard Development

---

## Objective

Validate the correctness of the newly implemented BEQ branch logic and investigate unexpected branch behavior observed during simulation.

---

## Branch Infrastructure Implemented

The following branch-related functionality was added to the processor:

### B-Type Immediate Support

The immediate generator was extended to support RISC-V B-type branch immediates.

Supported branch opcode:

1100011

---

### Branch Decode

Added branch detection logic:

```verilog
wire id_branch = (id_opcode == 7'b1100011);
```

---

### Branch Comparator

Added equality comparison between source operands:

```verilog
wire branch_taken =
    id_branch &&
    (rf_rs1_data == rf_rs2_data);
```

---

### Branch Target Generation

Implemented branch target address calculation:

```verilog
wire [31:0] branch_target =
    ifid_pc_out + id_imm;
```

---

### Pipeline Flush

Connected branch decisions to IF/ID flush logic:

```verilog
assign ifid_flush = branch_taken;
```

---

### PC Redirection

Program counter updated to redirect execution when a branch is taken.

---

## Test 1 – Branch Taken

### Program

```assembly
addi x1,x0,5
addi x2,x0,5

beq  x1,x2,target

addi x3,x0,99

target:
addi x4,x0,7

jal x0,0
```

### Expected Result

x1 = 5

x2 = 5

x3 = 0

x4 = 7

### Observed Result

x1 = 5

x2 = 5

x3 = 0

x4 = 7

### Status

PASS

---

## Test 2 – Branch Not Taken

### Program

```assembly
addi x1,x0,5
addi x2,x0,6

beq  x1,x2,target

addi x3,x0,99

target:
addi x4,x0,7

jal x0,0
```

### Expected Result

x1 = 5

x2 = 6

x3 = 99

x4 = 7

### Observed Result

x1 = 5

x2 = 6

x3 = 0

x4 = 7

### Status

FAIL

---

## Initial Observation

The processor behaved as if the branch was taken even though:

x1 = 5

x2 = 6

and therefore:

5 != 6

The IF/ID flush signal was observed to assert during execution.

---

## Hypothesis

The branch comparator was evaluating stale register values.

The branch instruction entered the ID stage before the ADDI instructions had completed writeback.

As a result:

Register file contents:

x1 = 0

x2 = 0

Comparator evaluation:

0 == 0

Result:

branch_taken = 1

This incorrectly triggered a branch flush.

---

## Verification Experiment

Two NOP instructions were inserted before the branch.

### Modified Program

```assembly
addi x1,x0,5
addi x2,x0,6

nop
nop

beq x1,x2,target

addi x3,x0,99

target:
addi x4,x0,7

jal x0,0
```

---

## Experimental Results

Observed:

x1 = 5

x2 = 6

x3 = 99

x4 = 7

Result:

PASS

---

## Conclusion

The branch comparator and branch flush mechanism are functioning correctly.

The failure is caused by a branch operand RAW hazard.

The branch instruction is reading source operands before preceding instructions have completed writeback.

This is not a control-hazard bug.

This is a data hazard affecting branch operands.

---

## Learning Outcome

A branch instruction can introduce data dependencies just like ALU instructions.

Example:

```assembly
addi x1,x0,5
addi x2,x0,6
beq  x1,x2,target
```

The branch consumes x1 and x2 before they have reached the register file.

Therefore, branch instructions require:

* Branch operand forwarding

or

* Branch operand stalling

to guarantee correct execution.

---

## Next Development Task

Implement branch operand hazard handling.

Possible approaches:

1. Branch forwarding from EX/MEM and MEM/WB stages.
2. Branch stall detection and bubble insertion.

Recommended approach:

Branch forwarding.

Reason:

Existing forwarding infrastructure can be extended with minimal architectural changes while maintaining performance.
