# Why We Chose a Modular Hardware Architecture

**Document ID:** WHY-008

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Problem Statement
3. Possible Design Approaches
4. Chosen Solution
5. Why Modular Design Was Selected
6. Alternatives Considered
7. Trade-offs
8. Scalability
9. Industry Perspective
10. Future Improvements
11. Key Takeaways

---

# 1. Purpose

This document explains why the AI Accelerator was designed as a collection of independent hardware modules instead of one large monolithic RTL design.

A modular architecture improves readability, maintainability, verification, and scalability while allowing individual subsystems to evolve independently.

---

# 2. Problem Statement

The accelerator contains multiple functional blocks, including:

- MMIO Interface
- Descriptor Fetch Unit
- Scheduler
- DMA Engine
- Scratchpad Memory
- Matrix Engine
- ReLU Unit
- Write-back Logic

These blocks perform different responsibilities and operate at different stages of execution.

The challenge is determining whether to:

- Implement everything inside one large controller, or
- Divide functionality into independent modules with well-defined interfaces.

---

# 3. Possible Design Approaches

Several architectural styles were considered.

---

## Option 1 – Monolithic Design

All accelerator functionality exists inside one large RTL module.

```text
Accelerator

├── MMIO
├── DMA
├── Matrix Engine
├── Scratchpad
├── Scheduler
├── Activation
└── Write-back
```

All logic shares one large controller.

---

## Option 2 – Modular Architecture

Each subsystem is implemented as an independent RTL module.

```text
Accelerator

├── MMIO
├── Descriptor Fetch Unit
├── Scheduler
├── DMA
├── Scratchpad
├── Matrix Engine
├── ReLU
└── Write-back
```

Each module exposes a clean interface and performs one well-defined responsibility.

---

# 4. Chosen Solution

The project adopts a **Modular Hardware Architecture**.

Each subsystem has:

- Independent RTL
- Clearly defined interfaces
- Separate verification
- Dedicated documentation
- Individual responsibilities

Modules communicate only through defined interfaces rather than shared internal logic.

---

# 5. Why Modular Design Was Selected

Several engineering considerations motivated this decision.

---

## Separation of Responsibilities

Each module performs one primary function.

Examples:

Descriptor Fetch Unit

→ Reads descriptors.

DMA Engine

→ Transfers data.

Scratchpad

→ Stores operands.

Matrix Engine

→ Performs MAC operations.

Scheduler

→ Coordinates execution.

This separation makes the design easier to understand and maintain.

---

## Improved Maintainability

Changes to one module generally do not require changes to unrelated modules.

For example:

Improving the DMA engine does not require modifying the Matrix Engine.

Adding a new activation function does not affect the scheduler.

This reduces development risk.

---

## Easier Verification

Each module can be verified independently.

Benefits include:

- Smaller testbenches
- Faster debugging
- Better functional coverage
- Easier regression testing

System integration occurs only after each module has been validated individually.

---

## Parallel Development

Independent modules enable multiple developers to work simultaneously.

Example:

Engineer A

→ DMA

Engineer B

→ Scheduler

Engineer C

→ Matrix Engine

Engineer D

→ Verification

Clearly defined interfaces reduce integration conflicts.

---

## Better Reusability

Modules can be reused in future projects.

Examples:

- DMA Engine
- Scratchpad Controller
- ReLU Unit
- Descriptor Parser

These components may be integrated into future accelerators with minimal modification.

---

## Easier Documentation

A modular architecture naturally aligns with documentation.

Each subsystem can have:

- Architecture description
- Learning material
- Verification strategy
- Interview preparation
- Design rationale

This improves long-term maintainability.

---

# 6. Alternatives Considered

## Monolithic RTL Design

Advantages:

- Fewer module interfaces
- Simpler hierarchy
- Less top-level wiring

Reasons not selected:

- Difficult debugging
- Large controller complexity
- Poor readability
- Harder verification
- Difficult future expansion

As accelerator complexity grows, monolithic designs become increasingly difficult to maintain.

---

# 7. Trade-offs

### Advantages

- High maintainability
- Excellent readability
- Easier verification
- Better scalability
- Improved reusability
- Parallel development support

---

### Limitations

- Additional interface definitions
- Slight increase in module hierarchy
- More top-level connections
- Integration requires careful interface management

These costs are minor compared to the long-term benefits of a modular architecture.

---

# 8. Scalability

The modular architecture supports future expansion.

Possible additions include:

- Multiple DMA engines
- Additional activation units
- Quantization modules
- Performance counters
- Compression engines
- Security modules
- Debug units
- Multiple Matrix Engines

New functionality can be introduced without redesigning the entire accelerator.

---

# 9. Industry Perspective

Modern semiconductor designs are almost universally modular.

Examples include:

- CPUs
- GPUs
- AI Accelerators
- Network Processors
- Storage Controllers
- Automotive SoCs

Large engineering teams rely on modular design because it enables:

- Independent verification
- IP reuse
- Faster development
- Easier maintenance
- Better scalability

This project follows the same engineering philosophy.

---

# 10. Future Improvements

Potential future enhancements include:

- Standardized interface protocols
- IP-XACT integration
- Plug-and-play hardware modules
- Dynamic module configuration
- Automated interface generation
- Parameterized subsystem templates

These improvements would make the architecture even more reusable and scalable.

---

# 11. Key Takeaways

- Each hardware module performs a single well-defined responsibility.
- Modularity improves readability, verification, and maintainability.
- Independent modules enable parallel development and easier debugging.
- The architecture supports future expansion without major redesign.
- The design philosophy reflects best practices used in commercial semiconductor development.

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Documented the rationale for adopting a modular hardware architecture for the AI Accelerator. |

---

**END OF FILE**