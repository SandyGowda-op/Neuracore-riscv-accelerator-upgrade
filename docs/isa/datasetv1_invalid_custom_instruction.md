# Dataset V1 – Invalid Custom Instruction Verification

## Test ID

ISA-NEG-001

## Objective

Verify that an instruction using the custom accelerator opcode with an undefined funct3 field does not activate any accelerator functionality.

---

## Decoder Specification

Valid accelerator encodings:

| Opcode  | funct3 | Operation  |
| ------- | ------ | ---------- |
| 0001011 | 000    | FMAC_START |
| 0001011 | 001    | FMAC_READ  |
| 0001011 | 010    | RELU       |

Undefined encodings:

| Opcode  | funct3 |
| ------- | ------ |
| 0001011 | 011    |
| 0001011 | 100    |
| 0001011 | 101    |
| 0001011 | 110    |
| 0001011 | 111    |

Expected behavior:

Undefined encodings shall behave as NOP operations and shall not activate accelerator functionality.

---

## Test Program

Assembly:

```assembly
addi x5,x0,5

.word 0x0000300B

addi x6,x0,6

jal x0,0
```

Encoding under test:

```text
opcode = 0001011
funct3 = 011
```

---

## Expected Results

* No MMUL start
* No accelerator RAW hazard
* No accelerator register writeback
* Normal pipeline execution
* x5 = 5
* x6 = 6

---

## Observed Results

MMUL START count:

```text
0
```

ACCEL RAW HAZARD count:

```text
0
```

Register writes:

```text
R5 = 00000005
R6 = 00000006
```

No writes observed to R3.

---

## Result

PASS

---

## Verification Significance

This test demonstrates that accelerator activation requires both:

* Correct custom opcode
* Correct funct3 decode

The accelerator cannot be accidentally activated by arbitrary instructions sharing the custom opcode space.

This validates decoder robustness and provides negative verification coverage for the custom ISA extension.
