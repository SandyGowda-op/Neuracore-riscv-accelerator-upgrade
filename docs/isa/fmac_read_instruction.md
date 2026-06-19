# FMAC_READ Custom Instruction

## Overview

FMAC_READ is a custom accelerator instruction that retrieves matrix multiplication results directly from the MMUL accelerator without requiring MMIO load instructions.

This instruction completes the accelerator ISA path by allowing software to start accelerator execution and retrieve results entirely through custom instructions.

---

## Opcode Assignment

Opcode:

0001011

Funct3:

010

Instruction Format:

31:25 funct7
24:20 rs2
19:15 rs1
14:12 funct3
11:7  rd
6:0   opcode

---

## Assembly Syntax

fmacrd rd

Current implementation ignores rs1 and rs2.

The instruction returns:

C[0][0]

from the MMUL result matrix.

---

## Example

Assembly:

fmacrd x5

Encoding:

0x0000228B

---

## RTL Implementation

Decode Stage:

id_is_fmac_read =
(opcode == 7'b0001011) &&
(funct3 == 3'b010);

Execute Stage:

idex_is_fmac_read =
(idex_opcode == 7'b0001011) &&
(idex_funct3 == 3'b010);

Result Selection:

alu_result_ex =
idex_is_fmac_read ?
mmul_result_direct :
normal_alu_result;

---

## Accelerator Interface

MMUL exposes:

assign result_out = C[0][0];

Pipeline connection:

.result_out(mmul_result_direct)

---

## Verification

Test Program:

fmac x0,x0,x0
fmacrd x5
jal x0,0

Observed:

REGFILE WRITE:
we_addr=5
we_data=0000000C

Verification Status:

PASS

---

## Architectural Significance

FMAC_READ removes the requirement for:

lw xN,8(x1)

MMIO result retrieval.

Accelerator results can now be consumed directly through ISA extensions.

Status:

COMPLETE
