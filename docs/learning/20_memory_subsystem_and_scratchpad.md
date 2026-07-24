# Chapter 20: Memory Subsystem and Scratchpad Memory

> **Document:** Learning Series
>
> **Chapter:** 20
>
> **Topic:** Memory Subsystem and Scratchpad Memory
>
> **Prerequisites:**
>
> - 17 DMA Engine
> - 18 Matrix Engine
> - 19 Activation Unit
> - Basic Memory Architecture
> - BRAM Fundamentals

---

# Table of Contents

1. Introduction
2. Why Memory Matters
3. Memory Hierarchy
4. What is Scratchpad Memory?
5. Scratchpad vs Cache
6. Why AI Accelerators Prefer Scratchpads
7. Memory Position in Our Accelerator
8. Types of Memory Used
9. Scratchpad Organization
10. Memory Banking
11. Dual-Port BRAM
12. Address Mapping
13. Data Movement
14. Memory Bandwidth
15. Design Philosophy
16. Summary

---

# 1. Introduction

When discussing AI accelerators, most people immediately think about matrix multiplication hardware.

However, experienced hardware architects often recognize a different reality:

> **The performance of an AI accelerator is frequently limited by memory rather than computation.**

Even the fastest Matrix Engine cannot perform useful work if operands are not available when needed.

For this reason, the memory subsystem is one of the most critical components of any accelerator.

Its responsibilities include:

- storing input tensors,
- storing weight matrices,
- buffering intermediate results,
- supplying operands to compute engines,
- collecting output data,
- coordinating data movement with the DMA Engine.

An efficient memory subsystem keeps compute engines busy and minimizes idle cycles.

---

# 2. Why Memory Matters

Consider a Matrix Engine capable of performing hundreds of multiply-accumulate operations every clock cycle.

If memory supplies only a few operands per cycle,

most Processing Elements remain idle.

Conceptually,

```text
Fast Compute Engine

↓

Waiting For Memory

↓

Idle Hardware
```

This situation is known as being **memory-bound**.

Conversely,

if data is supplied continuously,

the Matrix Engine can sustain peak throughput.

Therefore,

memory architecture is just as important as arithmetic architecture.

---

# 3. Memory Hierarchy

Modern computing systems organize memory into multiple levels.

A typical hierarchy is:

```text
Registers

↓

Scratchpad Memory

↓

On-Chip SRAM / BRAM

↓

Shared Memory

↓

External DRAM

↓

Storage
```

Each level provides a trade-off between:

- speed,
- capacity,
- energy consumption,
- cost.

The closer memory is to the compute hardware,

the faster—but generally smaller—it becomes.

---

# 4. What is Scratchpad Memory?

Scratchpad Memory (SPM) is a small, high-speed on-chip memory managed explicitly by hardware or software.

Unlike caches,

scratchpad memories do not automatically decide what data to store.

Instead,

the Scheduler or DMA Engine explicitly transfers data into and out of the scratchpad.

Conceptually,

```text
External Memory

↓

DMA Engine

↓

Scratchpad Memory

↓

Matrix Engine
```

This explicit control provides deterministic timing, which is highly desirable in hardware accelerators.

---

# 5. Scratchpad vs Cache

Although both are on-chip memories,

they operate very differently.

| Scratchpad Memory | Cache |
|-------------------|-------|
| Explicitly managed | Automatically managed |
| Deterministic timing | Variable latency |
| No cache replacement policy | Requires replacement algorithms |
| Simpler hardware | More complex control logic |
| Preferred for accelerators | Preferred for CPUs |

Because AI accelerators execute predictable workloads,

explicit memory management often provides better performance than cache-based approaches.

---

# 6. Why AI Accelerators Prefer Scratchpads

Scratchpad memories offer several advantages for accelerator workloads.

### Deterministic Access

Access latency is predictable.

---

### Reduced Hardware Complexity

No tag comparison logic.

No replacement policies.

No coherence management.

---

### Lower Power Consumption

Simpler control hardware reduces energy usage.

---

### Better Data Reuse

Operands remain on-chip for multiple computations.

---

### Higher Effective Bandwidth

Repeated accesses occur locally rather than repeatedly fetching data from external memory.

For matrix multiplication,

this dramatically reduces memory traffic.

---

# 7. Memory Position in Our Accelerator

Within our accelerator architecture,

the memory subsystem sits between the DMA Engine and the compute hardware.

```text
CPU

↓

MMIO

↓

Descriptor Fetch Unit

↓

Scheduler

↓

DMA Engine

↓

Scratchpad Memory

↓

Matrix Engine

↓

Activation Unit

↓

Output Buffer

↓

DMA Write-back
```

The DMA Engine loads operands into the scratchpad.

The Matrix Engine reads operands directly from the scratchpad.

The Activation Unit writes results into output buffers before DMA returns them to memory.

---

# 8. Types of Memory Used

Several different memories exist inside the accelerator.

### Descriptor Memory

Stores execution descriptors.

Read primarily by the Descriptor Fetch Unit.

---

### Scratchpad Memory

Stores operands for computation.

Read and written by the DMA Engine and Matrix Engine.

---

### Input Buffer

Temporary storage for incoming operands.

---

### Output Buffer

Temporary storage for completed results.

---

### Register Files

Store control information and configuration parameters.

Each memory serves a specialized purpose.

---

# 9. Scratchpad Organization

Scratchpad memory is typically organized into multiple logical regions.

Example:

```text
Scratchpad
│
├── Matrix A Region
├── Matrix B Region
├── Intermediate Results
├── Output Region
└── Reserved Space
```

Partitioning memory in this manner simplifies address generation and prevents accidental data overwrites.

---

# 10. Memory Banking

Access conflicts occur when multiple hardware units attempt to access the same memory simultaneously.

Memory banking addresses this issue.

Instead of one large memory,

multiple smaller banks operate independently.

Example:

```text
Bank 0

Bank 1

Bank 2

Bank 3
```

Different Processing Elements can access different banks simultaneously,

significantly increasing throughput.

Memory banking is a key optimization in high-performance AI accelerators.

---

# 11. Dual-Port BRAM

Many FPGA implementations use **dual-port Block RAM (BRAM)**.

A dual-port memory allows two independent accesses during the same clock cycle.

Example:

```text
Port A

↓

Read Matrix A

-------------------

Port B

↓

Write Results
```

Benefits include:

- simultaneous read/write,
- improved bandwidth,
- reduced contention,
- higher compute utilization.

Dual-port BRAM is particularly valuable for systolic arrays where reads and writes occur concurrently.

---

# 12. Address Mapping

Each operand stored in scratchpad memory occupies a well-defined address range.

Example:

```text
0x0000 - 0x03FF

Matrix A

-------------------

0x0400 - 0x07FF

Matrix B

-------------------

0x0800 - 0x0BFF

Output Matrix
```

Clear address mapping simplifies DMA programming and hardware debugging.

---

# 13. Data Movement

The complete data movement path is:

```text
External Memory

↓

DMA Read

↓

Scratchpad

↓

Matrix Engine

↓

Activation Unit

↓

Output Buffer

↓

DMA Write

↓

External Memory
```

Notice that data remains on-chip for as much of the computation as possible.

This minimizes expensive external memory accesses.

---

# 14. Memory Bandwidth

Bandwidth determines how quickly operands can reach the compute hardware.

Higher bandwidth enables:

- more active Processing Elements,
- fewer pipeline stalls,
- higher accelerator utilization,
- improved inference throughput.

Bandwidth can be increased through:

- burst DMA,
- memory banking,
- wider buses,
- double buffering,
- parallel memory interfaces.

A balanced design ensures that memory bandwidth scales with compute capability.

---

# 15. Design Philosophy

Several principles guided the memory subsystem architecture.

### Keep Frequently Used Data On-Chip

Reduce external memory traffic whenever possible.

---

### Maximize Data Reuse

Operands should participate in multiple computations before leaving the scratchpad.

---

### Separate Control and Data Movement

The Scheduler decides **what** to execute.

The DMA Engine decides **how** data moves.

The Scratchpad stores **where** data resides.

---

### Modular Organization

Each memory block performs one specialized function.

---

### Scalable Architecture

Additional memory banks and larger scratchpads can be incorporated without redesigning the overall architecture.

---
# 16. Memory Controller

Although the scratchpad memory primarily stores data, a dedicated controller is required to coordinate memory operations.

The Memory Controller acts as the central coordinator between:

- DMA Engine
- Scratchpad Memory
- Matrix Engine
- Activation Unit
- Scheduler

Conceptually,

```text
Scheduler

↓

Memory Controller

↓

Scratchpad Memory
```

The controller ensures that memory accesses occur safely, efficiently, and in the correct order.

---

# 17. Responsibilities of the Memory Controller

The Memory Controller performs several critical tasks.

### Read Control

Generates read enable signals.

Determines which memory bank should be accessed.

---

### Write Control

Generates write enable signals.

Selects destination addresses.

Ensures completed results are stored correctly.

---

### Address Generation

Produces memory addresses for:

- Matrix A
- Matrix B
- Output tensors
- Intermediate buffers

---

### Access Arbitration

When multiple modules request memory simultaneously,

the controller determines access priority.

---

### Status Reporting

Reports:

- Busy
- Ready
- Error
- Access Complete

to the Scheduler.

---

# 18. Memory Access Sequence

A typical execution proceeds as follows.

```text
Scheduler

↓

DMA Reads External Memory

↓

Scratchpad Write

↓

Matrix Engine Reads

↓

Activation Unit Reads

↓

Output Buffer Write

↓

DMA Writes External Memory
```

This sequence ensures that computation occurs only after valid operands are available.

---

# 19. Memory Arbitration

In a modern accelerator,

multiple hardware blocks may require memory access simultaneously.

For example:

- DMA Engine loading Matrix A
- Matrix Engine reading operands
- Activation Unit writing outputs

Without arbitration,

simultaneous requests could corrupt memory contents.

---

## Example Arbitration

```text
DMA Request

↓

Memory Arbiter

↓

Grant

↓

Scratchpad Access
```

Only one conflicting access is granted at a time unless the architecture supports multiple independent banks.

---

# 20. Arbitration Policies

Several arbitration schemes exist.

### Fixed Priority

One requester always has highest priority.

Example:

```text
DMA

↓

Matrix Engine

↓

Activation Unit
```

Advantages:

- Simple implementation
- Low hardware cost

Disadvantages:

- Possible starvation of low-priority modules.

---

### Round-Robin

Access rotates among requesters.

Example:

```text
DMA

↓

Matrix Engine

↓

Activation Unit

↓

DMA
```

Advantages:

- Fair allocation
- Prevents starvation

Disadvantages:

- Slightly more complex control logic.

---

### Dynamic Priority

Priority changes according to system state.

Examples:

- Deadline-based
- Buffer occupancy
- Scheduler commands

Dynamic arbitration provides better utilization but increases controller complexity.

---

# 21. Address Generation Unit (AGU)

The Address Generation Unit computes memory addresses automatically.

Instead of manually incrementing addresses,

hardware generates them.

Example:

```text
Base Address

+

Offset

=

Current Address
```

The AGU supports:

- sequential access,
- strided access,
- tiled matrices,
- burst transfers.

Efficient address generation is essential for high-performance DMA operation.

---

# 22. Double Buffering

One of the most important optimization techniques is **double buffering**.

Instead of using one memory region,

two independent buffers are maintained.

```text
Buffer A

↓

Currently Computing

----------------------

Buffer B

↓

DMA Loading Next Data
```

When computation finishes,

the roles swap.

```text
Buffer B

↓

Currently Computing

----------------------

Buffer A

↓

Loading Next Batch
```

Benefits include:

- Overlapping computation with memory transfers
- Reduced idle time
- Higher throughput
- Improved pipeline utilization

Double buffering is widely used in commercial AI accelerators.

---

# 23. Memory Hazards

Improper memory coordination can create hazards.

Examples include:

### Read Before Write

Reading data before DMA completes the write.

---

### Write After Read

Overwriting operands before computation finishes.

---

### Simultaneous Writes

Multiple modules writing to the same address.

---

### Bank Conflicts

Several requests targeting the same memory bank simultaneously.

These hazards must be prevented through controller logic and arbitration.

---

# 24. RTL Implementation

The memory subsystem is implemented as modular SystemVerilog components.

```text
Memory Subsystem
│
├── Scratchpad BRAM
├── Memory Controller
├── Address Generator
├── Arbiter
├── Bank Decoder
├── Input Buffer
├── Output Buffer
└── Status Generator
```

Each module has a clearly defined responsibility.

This modular approach improves readability, verification, and future scalability.

---

# 25. Verification Strategy

Verification proceeds incrementally.

---

## Stage 1

Compilation

Verify:

- Memory RTL compiles.
- Packages compile.
- Testbench compiles.

---

## Stage 2

Reset Verification

Verify:

- Memory controller enters IDLE.
- Read enables clear.
- Write enables clear.
- Address counters reset.

---

## Stage 3

Read Verification

Verify:

- Correct addresses generated.
- Expected data returned.
- No invalid accesses.

---

## Stage 4

Write Verification

Verify:

- Correct destination addresses.
- Correct write enables.
- Data stored successfully.

---

## Stage 5

Arbitration Verification

Verify:

- Multiple simultaneous requests.
- Correct grant selection.
- No starvation.
- No lost requests.

---

## Stage 6

End-to-End Verification

Verify:

DMA →

Scratchpad →

Matrix Engine →

Activation Unit →

Output Buffer →

DMA Write-back

All data should remain correct throughout the pipeline.

---

# 26. Assertions

Typical SystemVerilog Assertions include:

### Reset

Controller shall always enter IDLE after reset.

---

### Mutual Exclusion

Two write operations shall never target the same memory bank simultaneously.

---

### Read Validity

Read enable shall only assert for valid addresses.

---

### Write Validity

Write enable shall only assert for writable regions.

---

### Busy Protocol

Busy shall remain asserted while transfers are active.

---

### FSM

Illegal controller state transitions shall never occur.

---

### Address Bounds

Generated addresses shall never exceed allocated memory regions.

Assertions help detect protocol violations early during simulation.

---

# 27. Performance Optimization Techniques

Several optimizations improve memory subsystem performance.

### Memory Banking

Increase parallel accesses.

---

### Wider Data Buses

Transfer more operands each cycle.

---

### Burst DMA

Reduce transfer overhead.

---

### Double Buffering

Overlap transfers and computation.

---

### Data Reuse

Retain frequently accessed operands inside the scratchpad.

---

### Intelligent Scheduling

Issue transfers before compute units become idle.

Collectively, these techniques reduce memory bottlenecks and maximize utilization of the Matrix Engine.

---

# 28. Future Enhancements

Future versions of the memory subsystem may include:

- Multi-level scratchpad memories
- Hierarchical memory organization
- ECC (Error Correcting Codes)
- Memory compression
- Sparse data storage
- Dynamic bank allocation
- QoS-aware arbitration
- Runtime memory partitioning
- Hardware prefetch engines
- Multi-channel DMA support

These enhancements improve reliability, scalability, and overall accelerator performance.

---

# 29. Industry Perspective

Efficient memory subsystems are a defining feature of modern AI accelerators.

Commercial designs typically dedicate a significant portion of silicon area to on-chip memory because data movement often consumes more energy than arithmetic operations.

Key architectural trends include:

- Large on-chip SRAM or scratchpad memories
- High-bandwidth memory interfaces
- Banked memory architectures
- Aggressive data reuse strategies
- DMA-driven data movement

Well-designed memory systems enable compute engines to operate near peak utilization.

---

# 30. Common Design Mistakes

Typical implementation mistakes include:

- Insufficient memory bandwidth for the compute engine.
- Poor address mapping leading to inefficient accesses.
- Ignoring bank conflicts.
- Overwriting buffers before computation completes.
- Incorrect arbitration logic causing starvation.
- Failure to synchronize DMA and compute stages.
- Mixing controller and datapath responsibilities.
- Lack of bounds checking on generated addresses.

Careful architectural planning and thorough verification help avoid these issues.

---

# 31. Interview Questions

## Basic

1. What is scratchpad memory?
2. Why do AI accelerators prefer scratchpads over caches?
3. What is memory banking?

---

## Intermediate

1. Explain double buffering and its benefits.
2. What is the role of the Memory Controller?
3. How does arbitration prevent memory conflicts?
4. Why is dual-port BRAM useful in FPGA-based accelerators?

---

## Advanced

1. How would you design a scalable scratchpad memory for a 16×16 systolic array?
2. How would you reduce bank conflicts in a heavily parallel accelerator?
3. What trade-offs exist between scratchpad memories and caches?
4. How would you verify a memory arbiter using SystemVerilog Assertions?
5. How would you optimize memory bandwidth without significantly increasing silicon area?

---

# 32. Key Takeaways

- The memory subsystem is often the performance-limiting component of an AI accelerator.
- Scratchpad memory provides deterministic, low-latency storage under explicit hardware/software control.
- Memory banking and dual-port BRAM increase effective bandwidth and reduce contention.
- Double buffering allows computation and data transfers to overlap, improving throughput.
- A dedicated Memory Controller coordinates reads, writes, arbitration, and address generation.
- Robust verification and assertions are essential for ensuring safe and correct memory operation.
- Efficient data movement is just as important as efficient computation in high-performance accelerator design.

---

# Chapter Summary

In this chapter, we explored the architecture of the memory subsystem, focusing on scratchpad memory, memory controllers, arbitration, and data movement. We examined why memory bandwidth is often the primary bottleneck in AI accelerators and how techniques such as memory banking, dual-port BRAM, and double buffering help maintain high utilization of the compute engine.

We also discussed RTL organization, verification strategies, assertion-based validation, and future enhancements that make the memory subsystem scalable and efficient. Together with the DMA Engine, Matrix Engine, and Activation Unit, the memory subsystem forms the foundation for high-throughput, low-latency AI computation.

The next chapter introduces the **Performance Optimization and Pipelining Techniques** used to maximize throughput across the entire accelerator by overlapping computation, memory transfers, and control operations.

---

**END OF FILE**