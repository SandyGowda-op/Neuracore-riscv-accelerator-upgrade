# ISA Extension vs MMIO Accelerator Comparison

## Experimental Setup

Base Design:
- RV32I 5-stage pipeline

Dataset C1:
- MMIO-based accelerator interface

Dataset C3:
- Custom ISA interface
- Hazard protection enabled
- FMAC_START
- FMAC_READ
- RELU

---

## Yosys Synthesis Results

### MMIO Design

Top Module: riscv_pipeline

Cells: 1655

MUX: 357

AND: 352

DFF: 32

Submodules: 11

---

### ISA Design

Top Module: riscv_pipeline

Cells: 1891

MUX: 350

AND: 451

DFF: 32

Submodules: 12

---

## Area Impact

Total Cells

1655 → 1891

Increase:

236 cells

Percentage:

14.26%

---

## Sequential Logic

DFF Count

32 → 32

No increase.

Observation:

Area increase originates primarily from additional combinational control logic.

---

## Combinational Logic Growth

AND Gates

352 → 451

Increase:

99 gates

Observation:

Additional instruction decoding and hazard checking logic.

---

## MUX Count

357 → 350

Observation:

No significant datapath growth.

Control logic dominates area increase.

---

## Functional Improvements

Added Instructions

- FMAC_START
- FMAC_READ
- RELU

Added Features

- Accelerator RAW hazard detection
- Pipeline stall support
- Invalid funct3 protection

---

## Architectural Conclusion

The ISA extension introduces modest area overhead while maintaining register usage and enabling significantly cleaner software control of the accelerator.