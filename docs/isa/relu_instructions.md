# RELU Custom Instruction

## Overview

RELU (Rectified Linear Unit) is the first fully functional custom instruction implemented in the ISA extension branch.

The instruction performs:

```c
if (rs1 < 0)
    rd = 0;
else
    rd = rs1;
```

This operation is commonly used in neural-network inference pipelines.

---

# Instruction Format

The instruction uses the custom-0 opcode space.

Opcode:

```text
0001011
```

Funct3:

```text
001
```

Instruction Format:

```text
31:25  funct7
24:20  rs2
19:15  rs1
14:12  funct3
11:7   rd
6:0    opcode
```

---

# Assembly Syntax

```assembly
relu rd, rs1
```

Example:

```assembly
relu x2, x1
```

Meaning:

```c
x2 = max(0, x1)
```

---

# Encoding Example

Instruction:

```assembly
relu x6, x5
```

Fields:

```text
funct7 = 0000000
rs2    = 00000
rs1    = 00101
funct3 = 001
rd     = 00110
opcode = 0001011
```

Binary:

```text
0000000 00000 00101 001 00110 0001011
```

Hex:

```text
0x0002930B
```

---

# RTL Implementation

RELU is implemented as a dedicated execution unit.

Source File:

```text
src/relu_unit.v
```

Implementation:

```verilog
assign out_data =
    in_data[31] ? 32'd0 : in_data;
```

---

# Pipeline Integration

The instruction flows through:

```text
IF
↓
ID
↓
ID/EX
↓
RELU Execute
↓
EX/MEM
↓
MEM/WB
↓
Register File
```

The funct3 field is propagated through the ID/EX pipeline register to support future custom instructions.

---

# Verification

Test Program:

```assembly
addi x1,x0,-1
relu x2,x1

addi x3,x0,7
relu x4,x3

jal x0,0
```

Observed Results:

```text
R1 = FFFFFFFF
R2 = 00000000

R3 = 00000007
R4 = 00000007
```

Verification Status:

PASS

---

# Significance

This is the first custom ISA instruction successfully implemented and verified in the RV32I pipeline.

It validates:

* Custom opcode decoding
* Pipeline propagation
* Execute-stage custom hardware
* Writeback integration
* Forwarding compatibility

Status:

COMPLETE
