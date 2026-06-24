# Dataset C3 – Structural Hardware Cost Analysis

## Objective

Quantify the hardware overhead introduced by the custom ISA accelerator integration compared to the baseline MMIO accelerator interface using post-synthesis Yosys structural metrics.

---

# Experimental Setup

## MMIO Baseline Branch

Branch:

phase1_hazards

Architecture:

* RV32I 5-stage pipelined processor
* Memory-mapped MMUL accelerator
* Accelerator status polling
* MMIO synchronization

## ISA Extension Branch

Branch:

isa_extensions

Architecture:

* RV32I 5-stage pipelined processor
* Custom FMAC_START instruction
* Custom FMAC_READ instruction
* Custom RELU instruction
* Accelerator-aware hazard detection
* Automatic pipeline synchronization

---

# Synthesis Methodology

Tool:

Yosys Open Synthesis Suite

Technology Library:

Nangate Open Cell Library (Typical Corner)

Metrics Collected:

* Total synthesized cells
* Multiplexer count
* Combinational logic count
* Sequential element count
* Wire count
* Public signal count

---

# Results

## Top-Level Structural Metrics

| Metric       | MMIO | ISA  | Change |
| ------------ | ---- | ---- | ------ |
| Total Cells  | 1655 | 1891 | +236   |
| Wires        | 1406 | 1708 | +302   |
| Wire Bits    | 2665 | 2940 | +275   |
| Public Wires | 84   | 94   | +10    |

### Interpretation

The ISA architecture introduces additional decode logic, control signals, synchronization logic and accelerator-aware hazard handling.

The increase in total cells corresponds to approximately:

236 / 1655 × 100

= 14.3% increase in synthesized hardware.

---

## Multiplexer Count

| Metric    | MMIO | ISA | Change |
| --------- | ---- | --- | ------ |
| MUX Cells | 357  | 350 | -7     |

### Interpretation

The ISA implementation does not significantly increase datapath multiplexing.

Most hardware growth originates from control and decode logic rather than datapath routing structures.

---

## Combinational Logic Analysis

| Metric    | MMIO | ISA | Change |
| --------- | ---- | --- | ------ |
| AND Cells | 352  | 451 | +99    |

Percentage Increase:

99 / 352 × 100

= 28.1%

### Interpretation

The majority of ISA overhead is combinational.

Contributing factors include:

* Custom opcode detection
* funct3 decoding
* FMAC instruction recognition
* RELU instruction recognition
* Accelerator hazard checks
* Pipeline synchronization conditions

This supports the architectural hypothesis that ISA extensions primarily increase control complexity rather than storage requirements.

---

## Sequential Logic Analysis

| Metric     | MMIO | ISA |
| ---------- | ---- | --- |
| DFFE Cells | 32   | 32  |

### Interpretation

No meaningful increase in top-level sequential storage was observed.

The ISA extension modifies control logic rather than introducing additional architectural state.

This is consistent with the implemented design, where custom instructions operate through existing pipeline registers.

---

# Architectural Discussion

The ISA architecture introduces additional hardware cost while providing:

* Reduced software complexity
* Dedicated accelerator instructions
* Automatic accelerator synchronization
* Elimination of explicit MMIO polling
* Cleaner programmer abstraction

Observed tradeoff:

Hardware Cost:
+14.3% synthesized cells

Control Complexity:
+28.1% combinational logic

Programmer Convenience:
Significantly improved through dedicated accelerator instructions.

The results indicate that the custom ISA implementation achieves tighter hardware-software integration at the expense of modest control-path growth.

---

# OpenSTA Investigation

An attempt was made to obtain gate-level timing metrics using OpenSTA.

Outcome:

INCONCLUSIVE

Reason:

The Yosys-generated mapped netlist contains hierarchical module references and concatenation assignments unsupported by the OpenSTA parser version available in the environment.

Example construct:

assign { signal_a[31:3], signal_a[1:0] } =
{ signal_b[31:3], signal_b[1:0] };

Impact:

Timing characterization deferred until FPGA implementation stage.

Future timing metrics will be obtained from Vivado implementation reports after DMA and scratchpad integration.

---

# Dataset C3 Conclusion

The custom ISA accelerator architecture introduces a measurable but moderate hardware overhead.

Key findings:

* 14.3% increase in total synthesized cells
* 28.1% increase in combinational logic
* No meaningful increase in sequential state
* Improved accelerator programmability
* Improved synchronization semantics
* Reduced software-visible MMIO complexity

These results support the viability of ISA-based accelerator integration for tightly-coupled accelerator architectures.
