# Custom ISA Opcode Map

## Opcode Space

Custom-0

opcode = 7'b0001011

---

## FMAC

Mnemonic:

fmac rd, rs1, rs2

Encoding:

opcode = 0001011
funct3 = 000

Purpose:

Dispatch matrix multiplication accelerator.

---

## RELU

Mnemonic:

relu rd, rs1

Encoding:

opcode = 0001011
funct3 = 001

Purpose:

rd = max(0, rs1)

---

## Reserved

funct3 = 010
funct3 = 011
funct3 = 100
funct3 = 101
funct3 = 110
funct3 = 111

# Instruction Encoding Breakdown

## Instruction Format

Custom instructions currently use the standard R-type format.

```text
31:25  funct7
24:20  rs2
19:15  rs1
14:12  funct3
11:7   rd
6:0    opcode
```

Opcode Space:

```text
custom-0
opcode = 0001011
```

---

# FMAC

Assembly:

```assembly
fmac x5, x1, x2
```

Field Breakdown:

```text
funct7 = 0000000
rs2    = 00010   (x2)
rs1    = 00001   (x1)
funct3 = 000
rd     = 00101   (x5)
opcode = 0001011
```

Binary:

```text
0000000 00010 00001 000 00101 0001011
```

Hex:

```text
0x0020828B
```

Verification Status:

PASS

Decoder successfully recognizes FMAC instructions.

---

# RELU

Assembly:

```assembly
relu x6, x5
```

Field Breakdown:

```text
funct7 = 0000000
rs2    = 00000
rs1    = 00101   (x5)
funct3 = 001
rd     = 00110   (x6)
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

Verification Status:

PASS

Decoder successfully recognizes RELU instructions.

---

# Decoder Signals

```verilog
assign id_is_fmac =
    (id_opcode == 7'b0001011) &&
    (id_funct3 == 3'b000);

assign id_is_relu =
    (id_opcode == 7'b0001011) &&
    (id_funct3 == 3'b001);
```

Observed Simulation Output:

```text
CUSTOM ISA: FMAC DETECTED
CUSTOM ISA: RELU DETECTED
```

This confirms successful custom instruction decoding within the RV32I pipeline.

## Current ISA Extension Map

| Funct3 | Instruction | Status      |
| ------ | ----------- | ----------- |
| 000    | FMAC_START  | Planned     |
| 001    | RELU        | Implemented |
| 010    | FMAC_READ   | Planned     |
| 011    | Reserved    | -           |
| 100    | Reserved    | -           |
| 101    | Reserved    | -           |
| 110    | Reserved    | -           |
| 111    | Reserved    | -           |

---

## Implementation Progress

### Phase 2A

Custom Decode Infrastructure

Status:

PASS

Verified:

* FMAC decode
* RELU decode

---

### Phase 2B

RELU Execute Path

Status:

PASS

Verified:

* Decode
* ID/EX propagation
* Execute stage
* Writeback stage
* Register file update
