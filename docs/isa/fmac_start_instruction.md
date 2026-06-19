# FMAC_START Custom Instruction

## Overview

FMAC_START is the first accelerator-control instruction implemented in the ISA extension branch.

The instruction initiates matrix multiplication directly from the processor pipeline without requiring MMIO register access.

---

# Opcode Assignment

Opcode:

0001011

Funct3:

000

Instruction Format:

31:25 funct7
24:20 rs2
19:15 rs1
14:12 funct3
11:7  rd
6:0   opcode

---

# Assembly Syntax

fmac rd, rs1, rs2

Current Implementation:

The operands are reserved for future use and are ignored during accelerator dispatch.

The instruction currently behaves as:

Start MMUL Accelerator

---

# Example Encoding

Instruction:

fmac x5, x1, x2

Fields:

funct7 = 0000000
rs2    = 00010
rs1    = 00001
funct3 = 000
rd     = 00101
opcode = 0001011

Hex:

0x0020828B

---

# RTL Integration

FMAC detection:

assign idex_is_fmac =
(idex_opcode == 7'b0001011) &&
(idex_funct3 == 3'b000);

Accelerator dispatch:

assign mmul_start_fmac =
idex_is_fmac;

assign mmul_we =
mmul_start_mmio |
mmul_start_fmac;

---

# Verification

Test Program:

fmac x5,x1,x2
jal x0,0

Observed Output:

FMAC_START EXECUTING
=== MMUL 8x8 START ===

...
MATRIX MULTIPLICATION COMPLETE

Verification Status:

PASS

---

# Architectural Significance

This instruction represents the first direct coupling between the custom ISA and the matrix multiplication accelerator.

The processor can now initiate accelerator execution without MMIO software overhead.

Status:

COMPLETE
