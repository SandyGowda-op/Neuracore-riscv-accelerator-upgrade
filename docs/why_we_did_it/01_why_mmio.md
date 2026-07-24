# Why We Chose Memory-Mapped I/O (MMIO)

**Document ID:** WHY-001

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Problem Statement
3. Possible Design Approaches
4. Chosen Solution
5. Why MMIO Was Selected
6. Alternatives Considered
7. Trade-offs
8. Scalability
9. Industry Perspective
10. Future Improvements
11. Key Takeaways

---

# 1. Purpose

This document explains the architectural reasoning behind integrating the AI Accelerator using Memory-Mapped I/O (MMIO) rather than alternative communication mechanisms.

The goal is to capture the design rationale so that future developers understand not only *what* was implemented, but *why* this approach was chosen.

---

# 2. Problem Statement

The processor requires a mechanism to communicate with the AI Accelerator.

This communication must allow software to:

- Configure accelerator operation
- Provide execution parameters
- Start computation
- Monitor execution status
- Detect errors
- Retrieve results

The chosen interface should be simple, scalable, and compatible with the existing processor architecture.

---

# 3. Possible Design Approaches

Several integration methods were considered.

### Option 1 – Memory-Mapped I/O (MMIO)

The accelerator appears as a peripheral within the processor's address space.

The CPU interacts with accelerator registers using standard load and store instructions.

---

### Option 2 – Custom ISA Instructions

Introduce new RISC-V instructions dedicated to accelerator operations.

This would require modifications to:

- Instruction decoder
- Control unit
- Compiler or assembler support
- Software toolchain

---

### Option 3 – Coprocessor Interface

Implement a tightly coupled coprocessor connected directly to the CPU pipeline.

This provides lower communication latency but significantly increases processor complexity.

---

### Option 4 – Bus-Based Peripheral

Attach the accelerator as a peripheral on a shared system bus.

While scalable for larger SoCs, this introduces additional arbitration and protocol overhead beyond the needs of this project.

---

# 4. Chosen Solution

The project uses **Memory-Mapped I/O (MMIO)**.

The accelerator exposes a small set of registers within the processor's memory map.

Typical registers include:

- Control Register
- Status Register
- Descriptor Address Register
- Error Register

The CPU accesses these registers using ordinary load and store instructions.

---

# 5. Why MMIO Was Selected

Several factors influenced this decision.

### Simplicity

No changes were required to the RV32I instruction set or decode logic.

The existing processor architecture remained intact.

---

### Software Compatibility

Programs interact with the accelerator using familiar memory operations.

No custom compiler, assembler, or toolchain modifications are required.

---

### Modular Design

The accelerator behaves as an independent hardware peripheral.

Its internal implementation can evolve without changing the processor interface.

---

### Easier Verification

MMIO transactions are deterministic and straightforward to verify.

Standard read/write testcases, assertions, and scoreboards can validate the interface.

---

### Scalability

Additional accelerator registers or capabilities can be introduced by extending the MMIO address map rather than redesigning the CPU.

---

# 6. Alternatives Considered

## Custom Instructions

Advantages:

- Potentially lower software overhead
- Fewer instructions to initiate computation

Reasons not selected:

- Requires ISA extensions
- More complex decoder
- Additional verification effort
- Reduced portability

---

## Coprocessor Interface

Advantages:

- Lower latency
- Tighter CPU integration

Reasons not selected:

- Increased processor complexity
- Stronger coupling between CPU and accelerator
- More difficult debugging
- Larger verification scope

---

## Bus-Based Peripheral

Advantages:

- Standard SoC integration
- Multiple peripherals supported

Reasons not selected:

- Additional protocol complexity
- Arbitration overhead
- Beyond the scope of the current educational/research project

---

# 7. Trade-offs

Benefits:

- Simple implementation
- Easy software programming
- Standard interface
- Modular architecture
- Straightforward verification

Limitations:

- Software requires multiple register accesses to configure the accelerator.
- Communication latency is slightly higher than tightly coupled interfaces.
- Polling-based control may consume CPU cycles unless interrupts are introduced.

These trade-offs were considered acceptable for the project goals.

---

# 8. Scalability

The MMIO approach supports future expansion.

Examples include:

- Additional control registers
- Interrupt enable registers
- Performance counters
- Multiple accelerator instances
- Debug and diagnostic registers

The processor interface remains unchanged while functionality grows.

---

# 9. Industry Perspective

Memory-Mapped I/O is widely used in embedded processors and SoCs.

Many commercial systems expose hardware accelerators, DMA engines, timers, and communication peripherals through MMIO because it provides:

- Standard software access
- Good modularity
- Clear separation between computation and control

This project follows the same architectural philosophy.

---

# 10. Future Improvements

Potential enhancements include:

- Interrupt-driven completion instead of polling
- Memory protection for accelerator registers
- Register versioning for backward compatibility
- Integration with standard bus protocols such as AXI-Lite

These additions improve robustness while preserving the MMIO programming model.

---

# 11. Key Takeaways

- MMIO integrates the accelerator without modifying the RV32I ISA.
- It simplifies hardware, software, and verification.
- The interface is modular and easy to extend.
- The chosen approach balances implementation complexity with functionality.
- The design reflects common practices used in commercial embedded and accelerator-based systems.

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Documented the rationale for selecting Memory-Mapped I/O as the CPU–accelerator interface. |

---

**END OF FILE**