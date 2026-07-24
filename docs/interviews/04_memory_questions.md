# Memory System Interview Questions
## Scratchpad Memory and Memory Subsystem of the RISC-V AI Accelerator

**Document ID:** INT-MEM-001

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
7. Debugging Questions
8. Design Questions
9. Optimization Questions
10. Whiteboard Questions
11. Common Mistakes
12. Rapid Revision Sheet

---

# 1. Purpose

This document contains interview questions related to the memory subsystem used in the AI Accelerator.

The memory subsystem is responsible for supplying data to the compute engine with minimal latency and maximum bandwidth.

Topics include:

- Memory hierarchy
- Scratchpad memory
- SRAM
- BRAM
- Memory bandwidth
- Dual-port memories
- Data reuse
- Memory organization
- Performance optimization

These questions are common in RTL Design, FPGA Design, ASIC Design, Computer Architecture, and AI Hardware interviews.

---

# 2. Interview Preparation Strategy

When discussing memory systems:

1. Explain the memory hierarchy.
2. Explain why local memory is required.
3. Explain your scratchpad implementation.
4. Explain its interaction with DMA and the Matrix Engine.
5. Discuss performance trade-offs.

Interviewers are interested in understanding both architectural decisions and practical implementation.

---

# 3. Beginner Questions

---

## Q1. What is a memory hierarchy?

### Answer

A memory hierarchy organizes storage based on speed, capacity, and cost.

Typical hierarchy:

```text
Registers

↓

Caches

↓

Scratchpad / Local Memory

↓

Main Memory

↓

Secondary Storage
```

Smaller memories are faster but more expensive per bit, while larger memories provide greater capacity with higher access latency.

---

## Q2. What is SRAM?

### Answer

SRAM (Static Random Access Memory) stores data using bistable circuits.

Characteristics:

- Fast access
- No refresh required
- Low latency
- Larger area than DRAM
- Higher power per bit

SRAM is commonly used for caches and scratchpad memories.

---

## Q3. What is DRAM?

### Answer

DRAM (Dynamic Random Access Memory) stores data using capacitors.

Characteristics:

- High density
- Lower cost
- Larger capacity
- Higher latency
- Requires periodic refresh

System memory is generally implemented using DRAM.

---

## Q4. What is Scratchpad Memory?

### Answer

Scratchpad memory is an explicitly managed on-chip memory.

Unlike caches, it is controlled by software or hardware logic rather than automatic replacement policies.

Advantages:

- Predictable latency
- High bandwidth
- Efficient data reuse
- Low access latency

Scratchpads are widely used in AI accelerators and DSP systems.

---

## Q5. Why use scratchpad instead of directly accessing DRAM?

### Answer

Direct DRAM accesses introduce high latency and consume significant bandwidth.

Using scratchpad memory:

```text
DRAM

↓

DMA

↓

Scratchpad

↓

Matrix Engine
```

allows frequently reused data to remain on-chip, reducing memory traffic and improving performance.

---

# 4. Intermediate Questions

---

## Q6. What is dual-port memory?

### Answer

Dual-port memory supports two independent accesses simultaneously.

Benefits include:

- Concurrent read and write operations
- Higher throughput
- Improved parallelism
- Reduced resource contention

Dual-port BRAMs are commonly used in FPGA implementations.

---

## Q7. Why is memory bandwidth important?

### Answer

Memory bandwidth determines how quickly data can be delivered to the compute engine.

If bandwidth is insufficient, Processing Elements become idle even if computational resources are available.

High memory bandwidth is essential for sustaining accelerator throughput.

---

## Q8. What is memory latency?

### Answer

Memory latency is the delay between issuing a memory request and receiving the requested data.

Latency affects:

- Pipeline efficiency
- Accelerator utilization
- Overall execution time

Reducing latency improves responsiveness, while increasing bandwidth improves sustained throughput.

---

## Q9. What is data locality?

### Answer

Data locality refers to accessing data that is close in time or memory location.

Types:

- Temporal locality
- Spatial locality

Scratchpad memories exploit locality by keeping frequently used operands close to the compute engine.

---

## Q10. What is bank conflict?

### Answer

A bank conflict occurs when multiple accesses target the same memory bank simultaneously.

Consequences include:

- Stalls
- Increased latency
- Reduced throughput

Memory banking is designed to minimize these conflicts.

---

# 5. Advanced Questions

---

## Q11. Why not simply increase scratchpad size?

### Answer

A larger scratchpad offers more storage but introduces trade-offs:

- Increased silicon area
- Higher power consumption
- Longer routing distances
- Potential timing challenges

The scratchpad should be sized according to workload requirements and hardware constraints.

---

## Q12. How would you support larger neural network models?

### Answer

Possible approaches include:

- Tiling
- Double buffering
- Descriptor chaining
- Multi-level memory hierarchy
- Larger external memory

These techniques allow processing of datasets larger than on-chip memory capacity.

---

## Q13. Explain memory tiling.

### Answer

Memory tiling divides large matrices into smaller blocks that fit within the scratchpad.

Execution proceeds tile by tile:

```text
Large Matrix

↓

Tile 1

↓

Tile 2

↓

Tile 3
```

This approach reduces external memory accesses and enables efficient data reuse.

---

## Q14. Why is predictable latency important?

### Answer

Predictable latency simplifies scheduling and verification.

Unlike caches, scratchpad memories provide deterministic access times, making hardware behavior easier to analyze and optimize.

---

# 6. Project-Specific Questions

---

## Q15. Describe the memory subsystem used in your project.

### Answer

The memory subsystem consists of:

- External memory
- DMA Engine
- Scratchpad Memory
- Matrix Engine
- Activation Unit

The DMA loads operands into the scratchpad. The Matrix Engine reads operands locally, and after computation and activation, results are transferred back to external memory by the DMA.

---

## Q16. Why place the scratchpad between DMA and Matrix Engine?

### Answer

The scratchpad acts as a buffer between memory transfers and computation.

Benefits include:

- Lower latency
- Operand reuse
- Reduced external memory traffic
- Decoupling computation from memory access timing

---

## Q17. What type of memory would you use on an FPGA?

### Answer

The scratchpad would typically be implemented using Block RAM (BRAM).

Reasons:

- On-chip storage
- High bandwidth
- Dual-port capability
- Efficient FPGA resource utilization

---

## Q18. How does the scheduler interact with memory?

### Answer

The scheduler:

1. Waits for descriptor fetch.
2. Starts DMA transfers.
3. Waits until the scratchpad is populated.
4. Starts matrix computation.
5. Initiates result write-back after computation completes.

This sequencing ensures correct synchronization between data movement and computation.

---

# 7. Debugging Questions

---

## Q19. Matrix outputs are incorrect. Memory appears suspicious. What would you check?

### Expected Answer

Possible issues include:

- Incorrect DMA transfers
- Address calculation errors
- Scratchpad corruption
- Bank conflicts
- Misaligned accesses
- Write-enable errors

Debugging steps:

1. Inspect DMA transactions.
2. Verify scratchpad contents.
3. Check address generation.
4. Compare against the Golden Model.
5. Analyze waveforms.

---

## Q20. How would you verify scratchpad functionality?

### Answer

Verification should include:

- Read/write tests
- Address boundary tests
- Simultaneous access tests
- Dual-port verification
- Random data testing
- Assertion-Based Verification
- Regression testing

The scoreboard should compare expected memory contents with RTL outputs.

---

# 8. Design Questions

---

## Q21. Why not use cache instead of scratchpad?

### Answer

Caches automatically manage data placement and replacement, while scratchpads provide explicit control.

Scratchpads are preferred in AI accelerators because they offer:

- Deterministic behavior
- Lower hardware complexity
- Predictable latency
- Better control over data movement

---

## Q22. How would you improve the memory subsystem?

### Answer

Potential improvements include:

- Multi-bank scratchpads
- Larger BRAM capacity
- Double buffering
- Memory compression
- ECC support
- Multi-level scratchpads
- Wider memory interfaces

---

# 9. Optimization Questions

---

## Q23. How can memory throughput be increased?

### Answer

Possible optimizations:

- Dual-port memories
- Memory banking
- Wider data buses
- Burst DMA transfers
- Double buffering
- Better scheduling
- Reduced bank conflicts

---

## Q24. What is the biggest challenge in AI memory systems?

### Answer

The biggest challenge is feeding data to compute units quickly enough.

Even highly parallel compute engines become inefficient if memory cannot supply operands at the required rate.

Efficient memory architecture is therefore essential for high accelerator performance.

---

# 10. Whiteboard Questions

Typical interview exercises include:

- Draw the memory hierarchy.
- Explain scratchpad organization.
- Draw DMA → Scratchpad → Matrix Engine.
- Explain dual-port BRAM.
- Illustrate memory tiling.
- Explain bank conflicts.
- Sketch a memory controller.
- Show data reuse inside the scratchpad.

---

# 11. Common Mistakes

Avoid:

❌ Confusing scratchpad memory with cache.

❌ Assuming larger memory always improves performance.

❌ Ignoring memory bandwidth.

❌ Forgetting synchronization between DMA and compute units.

❌ Discussing only storage capacity without considering latency or throughput.

Instead:

- Explain the architectural role of memory.
- Discuss implementation details.
- Explain performance trade-offs.
- Relate decisions to your project.

---

# 12. Rapid Revision Sheet

Review these topics before interviews:

- Memory hierarchy
- SRAM
- DRAM
- Scratchpad memory
- BRAM
- Dual-port memory
- Memory bandwidth
- Memory latency
- Data locality
- Memory tiling
- Bank conflicts
- DMA interaction
- Scheduler interaction
- RTL verification
- Design trade-offs

A solid understanding of the memory subsystem demonstrates the ability to design efficient data movement architectures that keep AI compute engines fully utilized.

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Initial Memory System interview guide for the RISC-V AI Accelerator project. |

---

**END OF FILE**