# Why We Chose a Dedicated Scheduler

**Document ID:** WHY-007

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Problem Statement
3. Possible Design Approaches
4. Chosen Solution
5. Why a Dedicated Scheduler Was Selected
6. Alternatives Considered
7. Trade-offs
8. Scalability
9. Industry Perspective
10. Future Improvements
11. Key Takeaways

---

# 1. Purpose

This document explains the architectural reasoning behind introducing a dedicated **Scheduler** into the AI Accelerator.

The scheduler coordinates the execution of all accelerator subsystems by determining when each module should begin its operation and ensuring that data dependencies are respected.

Rather than allowing individual modules to operate independently, the scheduler serves as the central orchestration unit responsible for sequencing accelerator execution.

---

# 2. Problem Statement

The AI Accelerator consists of several independent hardware modules, including:

- Descriptor Fetch Unit
- DMA Engine
- Scratchpad Memory
- Matrix Engine
- Activation Unit
- Write-back Logic

Each module depends on the successful completion of previous stages.

For example:

- Matrix multiplication cannot begin until the DMA has loaded operands.
- ReLU cannot execute until matrix multiplication has completed.
- Results cannot be written back until activation processing finishes.

Without proper coordination, modules could begin execution prematurely, leading to incorrect computation, invalid memory accesses, or resource conflicts.

---

# 3. Possible Design Approaches

Several scheduling strategies were evaluated.

---

## Option 1 – CPU-Controlled Scheduling

The CPU explicitly starts every hardware module.

```text
CPU

↓

Start DMA

↓

Wait

↓

Start Matrix Engine

↓

Wait

↓

Start ReLU

↓

Wait

↓

Start Write-back
```

---

## Option 2 – Fully Distributed Control

Each hardware module determines when to start based on signals received from neighboring modules.

```text
DMA

↓

Matrix Engine

↓

ReLU

↓

Write-back
```

---

## Option 3 – Dedicated Hardware Scheduler

A centralized scheduler monitors module status and issues start signals when dependencies have been satisfied.

```text
Scheduler

↓

DMA

↓

Matrix Engine

↓

ReLU

↓

Write-back
```

---

# 4. Chosen Solution

The accelerator uses a **Dedicated Hardware Scheduler**.

The scheduler:

- Receives execution requests.
- Tracks module completion.
- Starts each stage only when prerequisites are satisfied.
- Coordinates overall execution flow.
- Reports accelerator completion to the CPU.

The CPU starts only the scheduler, while the scheduler manages the remaining hardware execution.

---

# 5. Why a Dedicated Scheduler Was Selected

Several architectural reasons motivated this decision.

---

## Centralized Control

Instead of distributing control logic across multiple modules, a single scheduler manages execution sequencing.

Benefits include:

- Clear execution order
- Reduced duplicated logic
- Easier debugging
- Simpler verification

---

## Reduced CPU Involvement

The CPU initiates accelerator execution once.

The scheduler manages:

- DMA start
- Matrix computation
- Activation
- Write-back
- Completion notification

This allows the processor to perform other tasks while the accelerator operates.

---

## Improved Synchronization

The scheduler ensures that:

- DMA finishes before computation begins.
- Matrix Engine completes before activation.
- Activation completes before write-back.

This prevents invalid execution sequences and simplifies subsystem interaction.

---

## Better Fault Handling

Centralized scheduling provides a natural location for:

- Timeout detection
- Error reporting
- Invalid descriptor handling
- Module failure recovery

These capabilities are easier to implement in one control unit than across multiple independent modules.

---

## Modular Design

Each accelerator module focuses on its primary function.

The scheduler focuses exclusively on execution control.

This separation improves maintainability and simplifies future expansion.

---

# 6. Alternatives Considered

## CPU-Controlled Scheduling

Advantages:

- Simple hardware
- Minimal scheduler logic

Reasons not selected:

- High CPU workload
- Frequent MMIO transactions
- Poor scalability
- Processor becomes tightly coupled to accelerator timing

---

## Fully Distributed Control

Advantages:

- No centralized controller
- Potentially lower control overhead

Reasons not selected:

- More complex inter-module communication
- Difficult debugging
- Complicated verification
- Harder to extend with new modules

---

# 7. Trade-offs

### Advantages

- Centralized execution management
- Reduced CPU overhead
- Easier debugging
- Simplified verification
- Clear module sequencing
- Better scalability

---

### Limitations

- Additional controller logic
- Scheduler becomes a critical control component
- Poor scheduler design could become a performance bottleneck
- Requires careful finite state machine (FSM) design

Despite these costs, the scheduler significantly improves overall system organization and maintainability.

---

# 8. Scalability

The scheduler architecture supports future enhancements.

Possible additions include:

- Multiple execution queues
- Task prioritization
- Concurrent accelerator jobs
- Descriptor chaining
- Dynamic resource allocation
- Multi-core accelerator coordination
- Interrupt-driven execution
- Power-aware scheduling

The scheduler can evolve independently while preserving module interfaces.

---

# 9. Industry Perspective

Dedicated scheduling hardware is common in modern computing systems.

Examples include:

- GPU command processors
- AI accelerator controllers
- DMA schedulers
- Network packet schedulers
- Storage controllers

The common philosophy is:

```text
CPU

↓

Submit Work

↓

Scheduler

↓

Hardware Execution

↓

Completion Notification
```

By separating task management from computation, modern hardware achieves higher efficiency and better scalability.

Our project adopts the same architectural principle.

---

# 10. Future Improvements

Potential future enhancements include:

- Out-of-order task scheduling
- Hardware work queues
- Priority-based execution
- Dynamic load balancing
- Performance-aware scheduling
- Runtime dependency analysis
- Support for multiple Matrix Engines
- AI workload profiling

These improvements would increase throughput while maintaining the existing programming model.

---

# 11. Key Takeaways

- The scheduler coordinates all accelerator modules.
- Centralized control simplifies execution sequencing.
- CPU involvement is minimized after task submission.
- The scheduler improves synchronization, debugging, and scalability.
- The architecture reflects scheduling strategies used in commercial AI accelerators and heterogeneous computing systems.

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Documented the rationale for selecting a dedicated hardware scheduler to orchestrate accelerator execution. |

---

**END OF FILE**