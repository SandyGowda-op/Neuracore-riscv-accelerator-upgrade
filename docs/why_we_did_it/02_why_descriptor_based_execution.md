# Why We Chose Descriptor-Based Execution

**Document ID:** WHY-002

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Problem Statement
3. Possible Design Approaches
4. Chosen Solution
5. Why Descriptor-Based Execution Was Selected
6. Alternatives Considered
7. Trade-offs
8. Scalability
9. Industry Perspective
10. Future Improvements
11. Key Takeaways

---

# 1. Purpose

This document explains why the AI Accelerator uses **descriptor-based execution** rather than having the CPU manually control every stage of accelerator operation.

Descriptors provide a structured way for software to communicate complete workloads to the hardware, reducing processor involvement and improving scalability.

---

# 2. Problem Statement

Executing an AI workload requires multiple pieces of information, including:

- Source memory addresses
- Destination memory addresses
- Matrix dimensions
- DMA configuration
- Activation function selection
- Control flags

One possible solution is for the CPU to configure every hardware module individually. Another is to package all required information into a descriptor and allow the accelerator to execute autonomously.

The challenge is selecting an approach that balances simplicity, flexibility, and scalability.

---

# 3. Possible Design Approaches

Several approaches were evaluated.

---

## Option 1 – Direct Register Programming

The CPU writes every configuration register individually before each operation.

Example:

```
Write Source Address

↓

Write Destination Address

↓

Write Matrix Size

↓

Configure DMA

↓

Configure Activation

↓

Start Accelerator
```

---

## Option 2 – Descriptor-Based Execution

Software creates a descriptor in memory containing all execution parameters.

The CPU provides only the descriptor address to the accelerator.

The hardware fetches the descriptor and executes the workload independently.

---

## Option 3 – Hardwired Accelerator Configuration

All execution parameters are fixed within the RTL.

Only one type of workload can be executed.

Changing execution behavior requires modifying the hardware.

---

# 4. Chosen Solution

The project uses **Descriptor-Based Execution**.

A descriptor acts as a command packet that fully describes one accelerator task.

A typical descriptor contains:

- Source address
- Destination address
- Matrix dimensions
- DMA parameters
- Activation configuration
- Control information

The CPU writes the descriptor to memory and provides its address through MMIO.

The accelerator performs the remaining steps autonomously.

---

# 5. Why Descriptor-Based Execution Was Selected

Several architectural reasons motivated this decision.

---

## Reduced CPU Overhead

Instead of programming many hardware registers individually, the CPU only needs to:

1. Build a descriptor.
2. Write its address to the MMIO register.
3. Start the accelerator.

The accelerator handles the remaining operations independently.

---

## Better Separation of Responsibilities

The CPU performs:

- Task preparation
- Scheduling decisions
- High-level software control

The accelerator performs:

- Descriptor fetching
- DMA transfers
- Matrix computation
- Activation
- Result write-back

This creates a clean separation between software and hardware.

---

## Improved Modularity

Adding new execution parameters only requires extending the descriptor format.

The CPU programming model remains largely unchanged.

---

## Easier Software Development

Descriptors provide a single data structure representing an entire workload.

This simplifies driver development and improves software maintainability.

---

## Simplified Hardware Control

Each hardware module receives its configuration from a common descriptor rather than multiple independent software writes.

This reduces interface complexity and improves synchronization.

---

# 6. Alternatives Considered

## Direct Register Programming

Advantages:

- Very simple hardware
- Easy to understand

Reasons not selected:

- Many MMIO transactions
- High CPU overhead
- Poor scalability
- Difficult to support complex workloads

---

## Hardwired Configuration

Advantages:

- Minimal control logic
- Lowest hardware complexity

Reasons not selected:

- No flexibility
- Not reusable
- Unsuitable for general AI workloads
- Hardware redesign required for configuration changes

---

# 7. Trade-offs

### Advantages

- Reduced processor involvement
- Better scalability
- Cleaner hardware architecture
- Modular software interface
- Easier workload management

---

### Limitations

- Descriptor fetch introduces a small startup latency.
- Descriptor parser increases RTL complexity.
- Software must correctly populate descriptor fields.
- Incorrect descriptors may lead to execution errors if not validated.

These trade-offs were considered acceptable given the gains in flexibility and maintainability.

---

# 8. Scalability

Descriptor-based execution naturally supports future enhancements.

Potential extensions include:

- Multiple descriptor formats
- Descriptor chaining
- Scatter-Gather DMA
- Priority fields
- Quality-of-Service (QoS) information
- Interrupt configuration
- Performance monitoring options
- Security and permission fields

Existing software can continue using the original descriptor format while newer software benefits from extended capabilities.

---

# 9. Industry Perspective

Descriptor-driven hardware is widely used in commercial systems.

Examples include:

- DMA controllers
- Network Interface Cards (NICs)
- Storage controllers
- Graphics Processing Units (GPUs)
- AI accelerators
- Multimedia engines

Using descriptors allows hardware to process complex workloads with minimal CPU intervention, improving both performance and scalability.

This project follows the same architectural principle.

---

# 10. Future Improvements

Possible enhancements include:

- Descriptor version fields
- Hardware descriptor validation
- Descriptor checksum or CRC
- Linked-list descriptor support
- Multiple outstanding descriptors
- Hardware work queues
- Descriptor caching
- Interrupt-driven completion

These features would allow the accelerator to process larger and more complex workloads efficiently.

---

# 11. Key Takeaways

- Descriptor-based execution minimizes CPU involvement.
- A descriptor represents a complete accelerator workload.
- The approach improves modularity, scalability, and software maintainability.
- Hardware modules receive consistent configuration through a unified interface.
- This design reflects techniques widely used in commercial accelerators and high-performance hardware systems.

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Documented the rationale for selecting descriptor-based execution for workload management. |

---

**END OF FILE**