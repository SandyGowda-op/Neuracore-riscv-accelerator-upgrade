# Why We Chose Scratchpad Memory

**Document ID:** WHY-004

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Problem Statement
3. Possible Design Approaches
4. Chosen Solution
5. Why Scratchpad Memory Was Selected
6. Alternatives Considered
7. Trade-offs
8. Scalability
9. Industry Perspective
10. Future Improvements
11. Key Takeaways

---

# 1. Purpose

This document explains the architectural reasoning behind incorporating a dedicated scratchpad memory into the AI Accelerator.

The scratchpad serves as a high-speed local memory between the DMA Engine and the Matrix Engine, enabling efficient data reuse and reducing dependence on external memory.

This document explains why a scratchpad was selected instead of relying solely on external memory or conventional cache-based architectures.

---

# 2. Problem Statement

Matrix multiplication repeatedly accesses the same operands.

If every Processing Element were forced to fetch data directly from external memory, the accelerator would spend much of its execution time waiting for data rather than performing computation.

The challenge is to design a memory architecture capable of:

- Supplying operands with minimal latency
- Providing sufficient bandwidth
- Supporting repeated data reuse
- Preventing the compute engine from becoming memory-bound

---

# 3. Possible Design Approaches

Several memory architectures were evaluated.

---

## Option 1 – Direct External Memory Access

The Matrix Engine reads operands directly from system memory.

```text
External Memory

↓

Matrix Engine
```

---

## Option 2 – Cache-Based Memory

Introduce an automatically managed cache between external memory and the Matrix Engine.

```text
External Memory

↓

Cache

↓

Matrix Engine
```

---

## Option 3 – Scratchpad Memory

Use an explicitly managed local memory filled by the DMA Engine before computation begins.

```text
External Memory

↓

DMA

↓

Scratchpad

↓

Matrix Engine
```

---

# 4. Chosen Solution

The accelerator uses a dedicated **Scratchpad Memory**.

Before computation begins:

- DMA transfers operands from external memory.
- Data is stored inside the scratchpad.
- The Matrix Engine performs all computation using scratchpad data.

Results are later transferred back to external memory through the DMA Engine.

---

# 5. Why Scratchpad Memory Was Selected

Several architectural considerations motivated this decision.

---

## Low Access Latency

Scratchpad memory resides on-chip.

Compared to external memory, it offers:

- Faster access
- Lower latency
- Predictable response time

This allows the Matrix Engine to receive operands every cycle.

---

## High Data Reuse

Matrix multiplication naturally reuses operands many times.

Rather than repeatedly accessing external memory, operands remain inside the scratchpad throughout computation.

Benefits include:

- Reduced memory traffic
- Higher Processing Element utilization
- Improved overall throughput

---

## Predictable Behavior

Unlike caches, scratchpads do not rely on replacement algorithms.

Every memory location is explicitly controlled by the DMA and scheduler.

Advantages include:

- Deterministic timing
- Easier debugging
- Simpler verification
- More predictable performance

---

## Decoupling Memory and Computation

The DMA and Matrix Engine operate independently.

The DMA focuses on:

- Data movement

The Matrix Engine focuses on:

- Arithmetic computation

The scratchpad acts as the interface between the two.

---

## Better Hardware Utilization

Keeping operands locally prevents Processing Elements from waiting on external memory.

As a result:

- Compute units remain active
- Pipeline stalls are reduced
- Overall accelerator efficiency improves

---

# 6. Alternatives Considered

## Direct External Memory Access

Advantages:

- Simpler hardware
- No additional memory blocks

Reasons not selected:

- High latency
- Low bandwidth efficiency
- Repeated memory accesses
- Poor compute utilization

---

## Cache-Based Memory

Advantages:

- Automatic data management
- Transparent software interface

Reasons not selected:

- Cache misses introduce unpredictable latency
- Replacement policies increase hardware complexity
- Less deterministic behavior
- More difficult verification

Scratchpad memory provides explicit control, making it better suited to accelerator workloads.

---

# 7. Trade-offs

### Advantages

- Predictable latency
- High bandwidth
- Excellent operand reuse
- Reduced external memory traffic
- Improved Matrix Engine utilization
- Easier verification

---

### Limitations

- Additional BRAM consumption
- Explicit management required
- Scratchpad size limits problem dimensions
- Larger workloads require tiling or multiple transfers

These limitations are outweighed by the significant performance improvements achieved through local storage.

---

# 8. Scalability

The scratchpad architecture supports future enhancements.

Possible improvements include:

- Larger scratchpad capacity
- Multi-bank organization
- Double buffering
- Hierarchical scratchpads
- ECC protection
- Bank conflict avoidance
- Multiple independent scratchpads

These enhancements improve throughput while preserving the overall architecture.

---

# 9. Industry Perspective

Scratchpad memories are widely used in high-performance computing systems.

Examples include:

- AI accelerators
- Tensor Processing Units (TPUs)
- GPUs
- Digital Signal Processors (DSPs)
- Neural Processing Units (NPUs)

The common philosophy is:

```text
External Memory

↓

DMA

↓

Local Memory

↓

Compute Engine
```

This minimizes memory bottlenecks and enables sustained computational throughput.

Our project follows the same architectural principle.

---

# 10. Future Improvements

Potential future enhancements include:

- Dynamic scratchpad partitioning
- Runtime memory allocation
- Multi-level scratchpad hierarchy
- Compression support
- Sparse data storage
- Adaptive banking
- Intelligent prefetching

These features would further improve memory efficiency for increasingly complex AI workloads.

---

# 11. Key Takeaways

- Scratchpad memory provides fast, predictable on-chip storage.
- It enables efficient operand reuse for matrix multiplication.
- The Matrix Engine remains focused on computation while the DMA manages data movement.
- Scratchpads eliminate many of the unpredictability issues associated with cache-based designs.
- The architecture reflects techniques widely used in commercial AI accelerators and high-performance embedded systems.

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Documented the rationale for selecting scratchpad memory as the accelerator's local storage architecture. |

---

**END OF FILE**