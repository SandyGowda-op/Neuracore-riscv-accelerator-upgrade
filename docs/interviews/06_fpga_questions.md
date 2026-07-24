# FPGA Interview Questions
## FPGA Implementation of the RISC-V AI Accelerator

**Document ID:** INT-FPGA-001

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Interview Preparation Strategy
3. Beginner Questions
4. Intermediate Questions
5. Advanced Questions
6. Project-Specific Questions
7. Timing Analysis Questions
8. FPGA Debugging Questions
9. Design Optimization Questions
10. Whiteboard Questions
11. Common Mistakes
12. Rapid Revision Sheet

---

# 1. Purpose

This document prepares engineers for FPGA implementation interviews using the AI Accelerator project as the primary example.

Topics include:

- FPGA architecture
- RTL synthesis
- Timing analysis
- BRAM
- DSP slices
- LUTs
- Flip-Flops
- Routing
- Timing Closure
- Resource utilization
- Hardware debugging

The questions are representative of those asked for FPGA Design, RTL Design, ASIC Front-End, Computer Architecture, and AI Hardware positions.

---

# 2. Interview Preparation Strategy

When discussing FPGA implementation:

1. Explain the FPGA concept.
2. Explain why FPGAs are useful.
3. Explain your implementation flow.
4. Explain synthesis and implementation.
5. Discuss optimization and timing closure.

Always relate the discussion back to your project implementation.

---

# 3. Beginner Questions

---

## Q1. What is an FPGA?

### Answer

An FPGA (Field Programmable Gate Array) is a programmable integrated circuit that can be configured after manufacturing.

Unlike ASICs, FPGA hardware can be reprogrammed multiple times.

Typical FPGA resources include:

- LUTs
- Flip-Flops
- Block RAM (BRAM)
- DSP slices
- Clock management blocks
- Routing resources
- I/O blocks

---

## Q2. Why use an FPGA?

### Answer

Advantages include:

- Rapid prototyping
- Reprogrammability
- Lower development cost
- Shorter design cycle
- Hardware debugging
- Suitable for research and education

FPGAs are commonly used to validate hardware before ASIC fabrication.

---

## Q3. What is RTL?

### Answer

RTL (Register Transfer Level) describes digital hardware behavior in terms of registers, combinational logic, and clocked data movement.

Languages commonly used include:

- Verilog
- SystemVerilog
- VHDL

RTL is synthesizable into physical hardware.

---

## Q4. What is synthesis?

### Answer

Synthesis converts RTL into a gate-level implementation that can be realized on FPGA hardware.

The synthesis tool maps RTL constructs onto FPGA resources such as:

- LUTs
- Flip-Flops
- BRAMs
- DSP slices

---

## Q5. What is implementation?

### Answer

Implementation follows synthesis and consists of:

- Optimization
- Placement
- Routing
- Timing analysis

The implementation stage determines the physical arrangement of logic within the FPGA.

---

# 4. Intermediate Questions

---

## Q6. What are LUTs?

### Answer

LUT (Look-Up Table) is the basic combinational logic element inside an FPGA.

It implements Boolean functions by storing truth tables.

Most combinational logic is mapped to LUTs during synthesis.

---

## Q7. What are Flip-Flops?

### Answer

Flip-Flops store sequential state.

Uses include:

- Registers
- Pipeline stages
- FSM state storage
- Counters

Every synchronous digital design uses flip-flops extensively.

---

## Q8. What are DSP slices?

### Answer

DSP slices are dedicated arithmetic hardware blocks optimized for:

- Multiplication
- Multiply-Accumulate (MAC)
- Addition
- Signal processing

AI accelerators heavily utilize DSP slices for matrix multiplication.

---

## Q9. What is BRAM?

### Answer

Block RAM (BRAM) is dedicated on-chip memory within an FPGA.

Typical applications include:

- Scratchpad memory
- FIFOs
- Buffers
- Lookup tables
- Instruction memory
- Data memory

BRAM offers low-latency, high-bandwidth storage.

---

## Q10. Why not implement memory using Flip-Flops?

### Answer

Using Flip-Flops for large memories is inefficient because they consume significantly more logic resources than dedicated BRAM.

BRAM provides:

- Higher density
- Lower area
- Better timing
- Lower power

---

# 5. Advanced Questions

---

## Q11. Explain the FPGA implementation flow.

### Answer

Typical flow:

```text
RTL

↓

Simulation

↓

Synthesis

↓

Implementation

↓

Timing Analysis

↓

Bitstream Generation

↓

FPGA Programming

↓

Hardware Validation
```

Each stage verifies a different aspect of the design before deployment.

---

## Q12. What is timing closure?

### Answer

Timing closure is the process of ensuring that all timing constraints are satisfied.

This includes:

- Setup timing
- Hold timing
- Clock uncertainty
- Routing delays

A design cannot reliably operate at its target frequency until timing is closed.

---

## Q13. What is setup time?

### Answer

Setup time is the minimum duration before a clock edge during which input data must remain stable to ensure correct capture by a flip-flop.

Violating setup time may result in incorrect data being latched.

---

## Q14. What is hold time?

### Answer

Hold time is the minimum duration after a clock edge during which input data must remain stable.

Hold violations can also lead to incorrect operation.

---

# 6. Project-Specific Questions

---

## Q15. Which FPGA resources did your project use?

### Answer

The AI Accelerator primarily utilized:

- LUTs for combinational logic
- Flip-Flops for pipeline registers and FSMs
- BRAM for instruction, data, and scratchpad memories
- DSP slices for multiply-accumulate operations within the Matrix Engine

---

## Q16. Why is BRAM suitable for the scratchpad?

### Answer

BRAM provides:

- Low latency
- High bandwidth
- Dual-port capability
- Efficient FPGA resource utilization

These characteristics make it ideal for supplying data to the Matrix Engine.

---

## Q17. Why are DSP slices useful for AI accelerators?

### Answer

Matrix multiplication consists of repeated MAC operations.

DSP slices perform these operations much more efficiently than implementing multipliers using LUTs, resulting in:

- Higher performance
- Lower LUT utilization
- Better power efficiency

---

## Q18. How did you validate your FPGA implementation?

### Answer

Validation included:

- RTL simulation
- Cocotb verification
- Golden Model comparison
- Synthesis
- Timing analysis
- FPGA implementation
- Hardware testing on the FPGA platform

This multi-stage flow ensured correctness before deployment.

---

# 7. Timing Analysis Questions

---

## Q19. What is Worst Negative Slack (WNS)?

### Answer

Worst Negative Slack (WNS) indicates the largest setup timing violation in a design.

Interpretation:

- Positive WNS → Timing met
- Zero WNS → Timing exactly met
- Negative WNS → Timing violation

Improving WNS is a primary objective during timing closure.

---

## Q20. How would you improve timing?

### Answer

Possible techniques include:

- Additional pipelining
- Shorter combinational paths
- Register balancing
- Improved floorplanning
- Better placement
- Resource optimization
- Reducing fanout

---

## Q21. What causes timing violations?

### Answer

Common causes include:

- Long combinational paths
- Excessive routing delay
- High fanout
- Deep logic levels
- Poor placement
- High target clock frequency

---

# 8. FPGA Debugging Questions

---

## Q22. The design works in simulation but fails on hardware. Why?

### Expected Answer

Possible causes:

- Timing violations
- Reset synchronization issues
- Clock domain problems
- Uninitialized memories
- Constraint errors
- Hardware interface issues

Simulation verifies functionality, but hardware introduces physical timing effects that must also be considered.

---

## Q23. How would you debug FPGA hardware?

### Answer

Typical debugging process:

1. Verify timing reports.
2. Check synthesis warnings.
3. Confirm pin constraints.
4. Inspect hardware waveforms using logic analyzers or integrated debug cores.
5. Compare hardware behavior with simulation.
6. Isolate the failing module.

---

# 9. Design Optimization Questions

---

## Q24. How would you reduce LUT utilization?

### Answer

Possible approaches:

- Resource sharing
- Simplified combinational logic
- Efficient FSM encoding
- Dedicated DSP usage
- Efficient arithmetic implementation
- Parameterized modules

---

## Q25. How would you improve FPGA performance?

### Answer

Potential optimizations include:

- Additional pipelining
- Better memory architecture
- Wider data paths
- Increased DSP utilization
- Efficient routing
- Balanced resource usage
- Optimized scheduling

Performance improvements should always be balanced against area and power consumption.

---

# 10. Whiteboard Questions

Typical interview exercises include:

- Draw FPGA architecture.
- Explain LUT implementation.
- Sketch a DSP slice.
- Draw BRAM organization.
- Explain synthesis flow.
- Draw timing paths.
- Explain setup and hold timing.
- Show AI Accelerator resource mapping.
- Draw the complete FPGA implementation flow.

---

# 11. Common Mistakes

Avoid:

❌ Saying synthesis guarantees timing closure.

❌ Confusing simulation with hardware validation.

❌ Ignoring timing reports.

❌ Using LUTs for large memories when BRAM is available.

❌ Assuming DSP slices are optional for compute-intensive designs.

Instead:

- Explain implementation flow.
- Discuss timing analysis.
- Mention resource trade-offs.
- Relate FPGA implementation to your project.

---

# 12. Rapid Revision Sheet

Review these topics before interviews:

- FPGA architecture
- RTL
- Synthesis
- Implementation
- LUTs
- Flip-Flops
- BRAM
- DSP slices
- Timing closure
- Setup time
- Hold time
- WNS
- Resource utilization
- Hardware debugging
- FPGA optimization
- AI accelerator mapping

A strong understanding of FPGA implementation demonstrates the ability to move from RTL design to working hardware while meeting performance, area, and timing requirements.

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Initial FPGA interview guide for the RISC-V AI Accelerator project. |

---

**END OF FILE**