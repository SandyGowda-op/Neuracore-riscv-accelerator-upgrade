# Dataset C1 – Yosys Synthesis Characterization

## Objective

Quantify the hardware overhead introduced by the custom ISA extension relative to the MMIO-based accelerator interface.

---

## Synthesis Flow

Tool:

Yosys

Top Module:

riscv_pipeline

Command:

```bash
yosys -p "
read_verilog -sv src/*.v src/*.sv
hierarchy -check -top riscv_pipeline
synth
stat
"
```

---

## MMIO Architecture

### Top-Level Statistics

| Metric           | Value |
| ---------------- | ----- |
| Wires            | 1406  |
| Wire Bits        | 2665  |
| Public Wires     | 84    |
| Public Wire Bits | 1281  |
| Ports            | 18    |
| Port Bits        | 421   |
| Cells            | 1655  |

### Cell Breakdown

| Cell Type | Count |
| --------- | ----: |
| AND       |   352 |
| NAND      |   442 |
| MUX       |   357 |
| OR        |   164 |
| XNOR      |    57 |
| XOR       |   101 |
| DFFE      |    32 |

### Submodules

* register_file
* mmul_mem
* hazard_detection_unit
* forwarding_unit
* data_memory
* instr_mem
* if_id
* id_ex
* ex_mem
* mem_wb
* immediate_gen

---

## ISA Architecture

### Top-Level Statistics

| Metric           | Value |
| ---------------- | ----- |
| Wires            | 1708  |
| Wire Bits        | 2940  |
| Public Wires     | 94    |
| Public Wire Bits | 1326  |
| Ports            | 18    |
| Port Bits        | 421   |
| Cells            | 1891  |

### Cell Breakdown

| Cell Type | Count |
| --------- | ----: |
| AND       |   451 |
| NAND      |   534 |
| MUX       |   350 |
| OR        |   223 |
| XNOR      |    70 |
| XOR       |    91 |
| DFFE      |    32 |

### Additional Submodule

* relu_unit

---

## RELU Synthesis Cost

| Metric | Value |
| ------ | ----- |
| Cells  | 31    |
| Wires  | 2     |
| Ports  | 2     |

Observation:

The RELU unit contributes only a small amount of additional hardware and represents a low-cost ISA extension.

---

## Comparative Analysis

| Metric       | MMIO |  ISA | Delta |
| ------------ | ---: | ---: | ----: |
| Cells        | 1655 | 1891 |  +236 |
| Wires        | 1406 | 1708 |  +302 |
| Public Wires |   84 |   94 |   +10 |
| DFFE         |   32 |   32 |     0 |

### Relative Cell Increase

236 additional cells

Approximate increase:

14.3%

---

## Architectural Interpretation

The custom ISA extension introduces additional combinational control logic while maintaining the same amount of architectural state.

The increase is primarily attributed to:

* FMAC_START decoding
* FMAC_READ decoding
* RELU decoding
* Accelerator RAW hazard detection
* Pipeline control integration

The DFF count remains unchanged, indicating that the ISA extension does not introduce significant new storage structures.

---

## Key Insight

The ISA extension increases control complexity without increasing architectural state.

This suggests that the added functionality is achieved primarily through combinational logic rather than additional registers or memory structures.

Dataset Status:

VERIFIED


## Dataset C1 Summary

MMIO Top-Level Cells: 1655

ISA Top-Level Cells: 1891

Delta: +236 cells (+14.3%)

Observations:
- ISA extension primarily increased combinational logic.
- DFF count remained unchanged.
- RELU synthesized to only 31 cells.
- Area increase attributed mainly to decode and accelerator hazard control logic.
- No additional architectural state introduced.