# Systolic Array Interview Questions
## Matrix Engine of the RISC-V AI Accelerator

**Document ID:** INT-SA-001

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

This document contains interview questions centered around the Matrix Engine implemented in the AI Accelerator.

The matrix engine is the computational heart of the accelerator and is based on a systolic array architecture.

Topics include:

- Matrix multiplication
- Processing Elements (PEs)
- Dataflow
- MAC operations
- Data reuse
- Parallelism
- Pipeline behavior
- Verification
- Performance optimization

These are common topics in interviews for AI Hardware, RTL Design, FPGA Design, ASIC Design, and Computer Architecture roles.

---

# 2. Interview Preparation Strategy

Whenever discussing a systolic array:

1. Explain the mathematical problem.
2. Explain why CPUs are inefficient.
3. Explain why systolic arrays are efficient.
4. Explain your implementation.
5. Discuss scalability and limitations.

Interviewers usually look for architectural understanding rather than memorized definitions.

---

# 3. Beginner Questions

---

## Q1. What is matrix multiplication?

### Answer

Matrix multiplication computes the dot product of rows from one matrix with columns from another.

For matrices:

```
A (MxK)

×

B (KxN)

↓

C (MxN)
```

Each output element is calculated as:

```
C(i,j)

=

Σ A(i,k) × B(k,j)
```

Matrix multiplication is the dominant operation in many AI and machine learning workloads.

---

## Q2. Why is matrix multiplication important in AI?

### Answer

Most neural network layers involve repeated matrix multiplications.

Examples include:

- Fully Connected Layers
- Convolution (after transformation)
- Attention Mechanisms
- Transformers
- Vision Models

Since matrix multiplication dominates execution time, accelerating it provides significant performance improvements.

---

## Q3. What is a systolic array?

### Answer

A systolic array is a grid of interconnected Processing Elements (PEs) that perform computations while passing data to neighboring PEs.

Instead of moving data back and forth between memory and the processor, data flows rhythmically through the array.

Each PE performs:

- Multiply
- Accumulate
- Forward data

This regular data movement leads to high throughput and efficient hardware utilization.

---

## Q4. What is a Processing Element (PE)?

### Answer

A Processing Element is the basic computational unit of the systolic array.

Each PE performs one Multiply-Accumulate (MAC) operation.

Its responsibilities include:

- Receiving operands
- Multiplying operands
- Accumulating partial sums
- Passing operands to neighboring PEs

The complete matrix engine is built by arranging multiple PEs in a regular grid.

---

## Q5. What is a MAC operation?

### Answer

MAC stands for Multiply-Accumulate.

It performs:

```
Accumulator

=

Accumulator

+

(A × B)
```

MAC operations are fundamental to:

- Neural networks
- DSP
- Image processing
- Matrix multiplication

Modern AI accelerators spend most of their execution time performing MAC operations.

---

# 4. Intermediate Questions

---

## Q6. Why is a systolic array faster than a CPU?

### Answer

A CPU performs matrix multiplication using sequential ALU operations.

A systolic array executes many MAC operations simultaneously.

Advantages include:

- Massive parallelism
- Local communication
- Data reuse
- Reduced memory traffic
- High throughput

The architecture is specifically optimized for dense linear algebra operations.

---

## Q7. Explain data reuse in a systolic array.

### Answer

Each input operand is reused by multiple neighboring PEs.

Instead of repeatedly fetching operands from memory, values propagate through the array.

Benefits:

- Lower memory bandwidth requirements
- Reduced power consumption
- Higher computational efficiency

Data reuse is one of the primary reasons systolic arrays outperform general-purpose processors for matrix workloads.

---

## Q8. How does data move inside the array?

### Answer

Typical data movement is:

- Matrix A values move horizontally.
- Matrix B values move vertically.
- Partial sums remain within each PE until computation completes.

Example:

```
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

Only neighboring PEs communicate, simplifying routing and improving scalability.

---

## Q9. Why is local communication important?

### Answer

Local communication avoids long interconnects.

Advantages:

- Lower routing complexity
- Reduced wire delay
- Lower power consumption
- Higher operating frequency
- Easier physical implementation

This makes systolic arrays highly scalable.

---

## Q10. What is pipeline latency in a systolic array?

### Answer

The array behaves like a pipeline.

Initial outputs require several cycles before appearing because data must propagate through the PEs.

Once the pipeline is full, however, outputs are produced at a steady rate, resulting in high throughput.

---

# 5. Advanced Questions

---

## Q11. Why not connect every PE to every other PE?

### Answer

A fully connected network would dramatically increase:

- Routing complexity
- Area
- Wire length
- Timing difficulty
- Power consumption

A systolic array restricts communication to neighboring PEs, providing a much more scalable architecture.

---

## Q12. What limits systolic array performance?

### Answer

Performance may be limited by:

- Memory bandwidth
- Scratchpad capacity
- Pipeline startup latency
- PE utilization
- Clock frequency
- Data loading overhead

Efficient data movement is just as important as computational capability.

---

## Q13. What determines PE utilization?

### Answer

PE utilization depends on:

- Matrix dimensions
- Scheduling efficiency
- Data availability
- Pipeline occupancy
- Memory bandwidth

Idle PEs reduce the effective throughput of the accelerator.

---

## Q14. How would you scale the array?

### Answer

Scaling options include:

- Increasing the number of PEs
- Larger scratchpad memories
- Hierarchical arrays
- Multiple compute clusters
- Network-on-Chip (NoC) communication

Scaling increases throughput but also raises area and power consumption.

---

# 6. Project-Specific Questions

---

## Q15. Describe your Matrix Engine.

### Answer

The Matrix Engine is implemented as a systolic array composed of Processing Elements.

Input operands are loaded into scratchpad memory by the DMA engine.

The scheduler starts the matrix engine after all operands are available.

Each PE performs multiply-accumulate operations while forwarding data to neighboring PEs.

Once computation completes, the output matrix is passed to the Activation Unit before being written back to memory.

---

## Q16. Why place the Matrix Engine after the scratchpad?

### Answer

The scratchpad provides low-latency local storage.

Without it, every PE would repeatedly access external memory, significantly reducing performance.

Using a scratchpad improves:

- Data reuse
- Throughput
- Bandwidth efficiency

---

## Q17. Why place the Activation Unit after the Matrix Engine?

### Answer

The activation function operates on the computed output matrix.

Execution sequence:

```
DMA

↓

Scratchpad

↓

Matrix Engine

↓

Activation

↓

DMA Write-back
```

Separating computation and activation keeps each hardware block modular and reusable.

---

## Q18. How does the scheduler interact with the Matrix Engine?

### Answer

The scheduler:

- Waits for DMA completion.
- Starts matrix computation.
- Monitors Busy and Done signals.
- Initiates the next stage after computation completes.

The Matrix Engine itself focuses solely on computation.

---

# 7. Debugging Questions

---

## Q19. Matrix output is incorrect. What would you check?

### Expected Answer

Possible causes include:

- Incorrect operand loading
- DMA errors
- Scratchpad corruption
- PE arithmetic errors
- Pipeline synchronization issues
- Incorrect accumulation
- Address mapping errors

Debugging steps:

1. Verify DMA output.
2. Inspect scratchpad contents.
3. Monitor PE inputs.
4. Check accumulation values.
5. Compare against the Golden Model.
6. Analyze waveforms.

---

## Q20. How would you verify the Matrix Engine?

### Answer

Verification methods include:

- Directed tests
- Random matrix generation
- Identity matrices
- Zero matrices
- Boundary cases
- Cocotb testbench
- Python Golden Model
- Assertion-Based Verification
- Regression testing

The scoreboard compares RTL outputs against the Golden Model on an element-by-element basis.

---

# 8. Design Questions

---

## Q21. Why use separate PEs instead of one large multiplier?

### Answer

Using multiple PEs enables parallel execution.

Advantages include:

- Higher throughput
- Better scalability
- Modular design
- Simpler timing closure
- Easier verification

A single multiplier would become a computational bottleneck.

---

## Q22. What would you improve in the next version?

### Answer

Potential enhancements include:

- Larger systolic arrays
- INT8 support
- BF16/FP16 support
- Sparse matrix acceleration
- Dynamic PE allocation
- Double buffering
- Multiple matrix engines
- Performance counters

These features improve flexibility and performance for future AI workloads.

---

# 9. Optimization Questions

---

## Q23. How can Matrix Engine throughput be improved?

### Answer

Possible optimizations:

- Increase PE count
- Improve DMA bandwidth
- Double buffering
- Better scheduling
- Higher clock frequency
- Larger scratchpad
- Operand prefetching

The optimal solution depends on area, power, and memory constraints.

---

## Q24. What is the biggest bottleneck in AI accelerators?

### Answer

In many accelerators, the limiting factor is data movement rather than computation.

Even a highly parallel matrix engine can become underutilized if data cannot be supplied fast enough.

Efficient memory systems and scheduling are therefore essential for achieving high overall performance.

---

# 10. Whiteboard Questions

Typical interview exercises include:

- Draw a 4×4 systolic array.
- Explain data propagation.
- Draw a Processing Element.
- Explain Multiply-Accumulate.
- Show matrix multiplication inside the array.
- Explain pipeline filling and draining.
- Draw DMA → Scratchpad → Matrix Engine flow.
- Explain PE communication.
- Sketch the control signals (Start, Busy, Done).

---

# 11. Common Mistakes

Avoid:

❌ Saying the systolic array "stores" matrices permanently.

❌ Confusing throughput with latency.

❌ Ignoring memory bandwidth.

❌ Assuming every PE communicates with every other PE.

❌ Focusing only on computation while ignoring data movement.

Instead:

- Explain the algorithm.
- Explain the architecture.
- Explain the implementation.
- Discuss limitations and trade-offs.
- Relate the design back to your project.

---

# 12. Rapid Revision Sheet

Review these topics before interviews:

- Matrix multiplication
- Dot product
- Processing Elements
- Multiply-Accumulate (MAC)
- Data reuse
- Dataflow
- Pipeline behavior
- Scratchpad memory
- DMA interaction
- Scheduler interaction
- Throughput vs latency
- Parallelism
- Cocotb verification
- Golden Model comparison
- Design trade-offs
- Scalability

A strong understanding of these concepts demonstrates not only familiarity with AI accelerators but also the architectural reasoning behind their design and integration.

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Initial Systolic Array interview guide for the RISC-V AI Accelerator project. |

---

**END OF FILE**