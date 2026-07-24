# Why We Chose a Systolic Array

**Document ID:** WHY-005

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Problem Statement
3. Possible Design Approaches
4. Chosen Solution
5. Why a Systolic Array Was Selected
6. Alternatives Considered
7. Trade-offs
8. Scalability
9. Industry Perspective
10. Future Improvements
11. Key Takeaways

---

# 1. Purpose

This document explains the architectural reasoning behind selecting a **systolic array** as the primary compute engine for the AI Accelerator.

The Matrix Engine is responsible for executing matrix multiplication, which is the computational backbone of modern machine learning workloads. This document explains why a systolic array was chosen instead of other hardware architectures.

---

# 2. Problem Statement

Neural network inference is dominated by repeated matrix multiplication operations.

A compute engine must therefore provide:

- High computational throughput
- Efficient data reuse
- Low memory bandwidth requirements
- Regular hardware structure
- Good scalability
- Efficient FPGA implementation

The challenge is selecting a hardware architecture capable of meeting these requirements while remaining practical to implement and verify.

---

# 3. Possible Design Approaches

Several architectures were considered.

---

## Option 1 – Sequential ALU-Based Computation

A single arithmetic unit performs one multiplication and accumulation at a time.

```text
Load Operand

↓

Multiply

↓

Accumulate

↓

Store Result

↓

Repeat
```

---

## Option 2 – Multiple Independent Multipliers

Several multipliers operate in parallel.

Each multiplier independently reads operands from memory.

```text
Memory

↓

Multiplier 1

Multiplier 2

Multiplier 3

...
```

---

## Option 3 – Systolic Array

A two-dimensional grid of Processing Elements performs Multiply-Accumulate (MAC) operations while forwarding data only to neighboring Processing Elements.

```text
A →

PE → PE → PE

↓

↓

↓

PE → PE → PE

↓

↓

↓

PE → PE → PE

↑

B
```

---

# 4. Chosen Solution

The project implements the Matrix Engine as a **systolic array** composed of multiple Processing Elements (PEs).

Each PE performs:

- Operand reception
- Multiplication
- Accumulation
- Data forwarding

Operands stream through the array while partial sums remain local until computation completes.

---

# 5. Why a Systolic Array Was Selected

Several architectural considerations motivated this decision.

---

## Massive Parallelism

Instead of performing one multiplication at a time, many Processing Elements operate simultaneously.

This allows multiple MAC operations to occur every clock cycle.

As matrix sizes increase, throughput scales with the number of available Processing Elements.

---

## Efficient Data Reuse

One of the biggest advantages of a systolic array is operand reuse.

Each matrix element is reused by several neighboring Processing Elements as it propagates through the array.

Benefits include:

- Fewer external memory accesses
- Lower bandwidth requirements
- Higher computational efficiency

---

## Local Communication

Each Processing Element communicates only with its immediate neighbors.

Advantages include:

- Simpler routing
- Lower wire delays
- Reduced congestion
- Better timing closure
- Improved scalability

This regular communication pattern makes systolic arrays particularly attractive for FPGA implementation.

---

## High Compute Utilization

The Matrix Engine receives operands from the scratchpad continuously.

Once the pipeline is filled, Processing Elements remain active throughout computation.

This maximizes hardware utilization and minimizes idle cycles.

---

## Regular Hardware Structure

Every Processing Element has nearly identical functionality.

Advantages include:

- Easier RTL development
- Simpler verification
- Straightforward parameterization
- Predictable timing
- Efficient synthesis

Regular structures are generally easier to scale than irregular compute architectures.

---

# 6. Alternatives Considered

## Sequential ALU

Advantages:

- Minimal hardware resources
- Simple controller
- Easy implementation

Reasons not selected:

- Extremely low throughput
- Poor AI performance
- Long execution times
- Limited scalability

---

## Multiple Independent Multipliers

Advantages:

- Parallel computation
- Simpler than a systolic array

Reasons not selected:

- High memory bandwidth requirements
- Poor operand reuse
- More complex memory system
- Lower overall efficiency

---

# 7. Trade-offs

### Advantages

- High throughput
- Excellent operand reuse
- Local communication
- High PE utilization
- Modular architecture
- Efficient FPGA mapping

---

### Limitations

- Pipeline fill and drain latency
- Performance depends on steady data supply
- Larger arrays consume more FPGA resources
- Matrix dimensions may require tiling
- Controller complexity increases with array size

These trade-offs are acceptable because the sustained throughput significantly exceeds that of simpler architectures.

---

# 8. Scalability

The systolic array architecture naturally supports future expansion.

Potential enhancements include:

- Larger array dimensions
- Parameterizable Processing Elements
- INT8, BF16, or FP16 arithmetic support
- Sparse matrix acceleration
- Multiple Matrix Engines
- Hierarchical compute clusters
- Network-on-Chip (NoC) integration

The regular structure allows compute capability to increase without fundamentally changing the architecture.

---

# 9. Industry Perspective

Systolic arrays are widely used in commercial AI hardware.

Examples include:

- Google's Tensor Processing Unit (TPU)
- Neural Processing Units (NPUs)
- AI inference accelerators
- Machine learning ASICs
- FPGA-based deep learning accelerators

The underlying design philosophy is:

```text
Move Data Through Compute

Instead of

Moving Compute To Data
```

This minimizes memory traffic and maximizes arithmetic efficiency.

Our project follows the same architectural principle.

---

# 10. Future Improvements

Potential future enhancements include:

- Configurable array dimensions
- Dynamic workload scheduling
- Multiple precision support
- Sparse computation support
- Runtime PE power gating
- Adaptive clock gating
- Performance monitoring counters
- Multiple concurrent compute engines

These features would increase flexibility and improve performance for more diverse AI workloads.

---

# 11. Key Takeaways

- Matrix multiplication dominates AI inference workloads.
- A systolic array provides high throughput through massive parallelism.
- Local communication enables efficient routing and scalability.
- Operand reuse significantly reduces external memory bandwidth requirements.
- The architecture aligns with approaches used in modern commercial AI accelerators.
- The regular structure simplifies RTL design, verification, and future expansion.

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Documented the rationale for selecting a systolic array as the Matrix Engine architecture. |

---

**END OF FILE**