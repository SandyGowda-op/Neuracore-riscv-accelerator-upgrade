# Verification Plan
## AI Accelerator Integrated with a 5-Stage RISC-V Processor

**Document ID:** VP-001

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Scope
3. Verification Objectives
4. Design Under Test
5. Verification Strategy
6. Verification Levels
7. Verification Environment
8. Verification Flow
9. Verification Features
10. Test Categories
11. Functional Coverage Goals
12. Code Coverage Goals
13. Regression Strategy
14. Entry Criteria
15. Exit Criteria
16. Risks
17. Assumptions
18. Deliverables
19. Traceability Matrix
20. Review Checklist

---

# 1. Purpose

This document defines the complete verification strategy for the RISC-V AI Accelerator.

It establishes:

- what functionality must be verified,
- how verification will be performed,
- verification responsibilities,
- pass/fail criteria,
- coverage expectations,
- regression methodology.

The objective is to ensure that the RTL implementation is functionally correct before FPGA implementation and future ASIC migration.

---

# 2. Scope

The verification plan covers every RTL block developed as part of the accelerator.

Included modules are:

- RISC-V Pipeline Interface
- MMIO Interface
- Descriptor Fetch Unit (DFU)
- Scheduler
- DMA Engine
- Scratchpad Memory
- Matrix Engine (Systolic Array)
- Activation Unit (ReLU)
- Status Registers
- Top-Level Accelerator Integration

The following are outside the scope of this document:

- Operating System software
- Linux drivers
- Physical implementation
- Timing closure
- FPGA board validation
- ASIC signoff verification

These topics are documented separately.

---

# 3. Verification Objectives

The primary verification objectives are:

## Functional Correctness

Verify that every module performs its intended function.

---

## Interface Compliance

Verify correct communication between modules.

Examples include:

- MMIO transactions
- DMA handshakes
- Scheduler commands
- Memory interfaces

---

## Protocol Compliance

Verify that all interfaces obey defined protocols.

Examples:

- Ready/Valid
- Busy/Done
- Reset behavior

---

## Error Handling

Verify graceful handling of:

- invalid descriptors
- illegal addresses
- unsupported commands
- invalid MMIO accesses

---

## Integration Correctness

Verify that individually correct modules continue functioning correctly after integration.

---

## Regression Stability

Ensure that future RTL modifications do not introduce new failures.

---

# 4. Design Under Test (DUT)

The DUT consists of the complete AI accelerator subsystem integrated with the RISC-V processor.

Top-level hierarchy:

```text
CPU

↓

MMIO Interface

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

DMA Write-back
```

Verification targets both individual modules and complete system behavior.

---

# 5. Verification Strategy

Verification follows a layered methodology.

```text
Unit Verification

↓

Subsystem Verification

↓

Integration Verification

↓

System Verification

↓

Regression Testing
```

Each stage must successfully complete before progressing to the next.

Failures discovered at lower levels should be resolved before higher-level verification begins.

---

# 6. Verification Levels

## Level 1 — Unit Verification

Each RTL module is verified independently.

Modules include:

- Scheduler
- DMA
- Matrix Engine
- Activation Unit
- Scratchpad
- DFU

Goal:

Verify functional correctness in isolation.

---

## Level 2 — Subsystem Verification

Related modules are combined.

Examples:

```text
Scheduler

↓

DMA
```

or

```text
DMA

↓

Scratchpad

↓

Matrix Engine
```

Goal:

Verify interface correctness.

---

## Level 3 — Accelerator Verification

Entire accelerator operates as one subsystem.

Goal:

Verify descriptor execution.

---

## Level 4 — CPU Integration

Accelerator integrated with the RISC-V processor.

Goal:

Verify MMIO control and software interaction.

---

## Level 5 — End-to-End Verification

Complete workload execution.

Example:

Descriptor →

DMA →

Compute →

ReLU →

Write-back

↓

Compare against golden model.

Goal:

System-level correctness.

---

# 7. Verification Environment

Verification will use a combination of simulation tools and software models.

Primary components:

```text
RTL

↓

Simulator

↓

Testbench

↓

Scoreboard

↓

Coverage

↓

Regression
```

Simulation environments include:

- Icarus Verilog
- ModelSim (optional)
- Vivado Simulator (optional)

Python-based verification is implemented using:

- cocotb
- NumPy
- Golden reference models

---

# 8. Verification Flow

The verification flow is summarized below.

```text
Write RTL

↓

Compile RTL

↓

Run Unit Tests

↓

Subsystem Tests

↓

Integration Tests

↓

Random Tests

↓

Coverage Analysis

↓

Regression

↓

Verification Signoff
```

Each phase produces measurable outputs before progressing to the next stage.

---

# 9. Verification Features

The following features shall be verified.

| Feature | Verification Required |
|----------|-----------------------|
| MMIO | ✔ |
| Descriptor Fetch | ✔ |
| Scheduler | ✔ |
| DMA | ✔ |
| Scratchpad | ✔ |
| Matrix Engine | ✔ |
| Activation Unit | ✔ |
| Busy/Done Protocol | ✔ |
| Reset | ✔ |
| Error Handling | ✔ |
| Multi-Descriptor Execution | ✔ |

No implemented feature shall remain unverified.

---

# 10. Test Categories

Testing is divided into multiple categories.

## Directed Tests

Verify known functionality.

Example:

Single descriptor execution.

---

## Boundary Tests

Verify:

- smallest matrices
- largest matrices
- address boundaries
- counter overflows

---

## Error Tests

Verify illegal conditions.

Examples:

- invalid descriptor
- invalid MMIO address
- unsupported operation

---

## Stress Tests

Execute:

- long descriptor chains
- repeated DMA transfers
- continuous accelerator execution

---

## Random Tests

Generate legal randomized workloads.

Used to expose unexpected corner cases.

---

## Regression Tests

Automatically rerun previously passing tests after every RTL modification.

---

# 11. Functional Coverage Goals

Functional coverage targets include:

- Every FSM state
- Every state transition
- Every descriptor type
- Every activation mode
- Every DMA transaction type
- Every MMIO register
- Every reset scenario
- Every error response

Coverage goal:

```text
100% of planned functional coverage points exercised.
```

Coverage closure shall be documented before verification signoff.

---

# 12. Code Coverage Goals

Code coverage targets include:

- Statement Coverage
- Branch Coverage
- Condition Coverage
- Toggle Coverage
- FSM Coverage

Target values:

| Metric | Target |
|---------|--------|
| Statement | ≥95% |
| Branch | ≥90% |
| Toggle | ≥90% |
| FSM | 100% |

Coverage exceptions shall be documented and justified.

---

# 13. Regression Strategy

Regression shall execute automatically whenever:

- RTL changes
- interfaces change
- bug fixes are introduced
- new features are added

Regression suite includes:

- Unit tests
- Integration tests
- End-to-end tests
- cocotb tests
- Assertion checks

Regression failures block verification signoff until resolved.

---

# 14. Entry Criteria

Verification begins when:

- RTL compiles successfully.
- Interfaces are defined.
- Reset behavior is implemented.
- Basic testbench infrastructure exists.
- Module documentation is available.

---

# 15. Exit Criteria

Verification is considered complete when:

- All planned tests pass.
- No critical bugs remain.
- Functional coverage goals are achieved.
- Code coverage targets are achieved or justified.
- Regression suite passes without failures.
- Assertions report no unexpected violations.
- Golden model comparisons pass.
- Verification review is approved.

---

# 16. Risks

Potential verification risks include:

- Incomplete test coverage.
- Incorrect reference model.
- Hidden corner-case failures.
- Interface mismatches.
- Synchronization issues.
- Regression instability.
- Long simulation runtimes.

Each identified risk shall be monitored throughout the project lifecycle.

---

# 17. Assumptions

This verification plan assumes:

- RTL follows the documented architecture.
- Interfaces remain stable during verification.
- Clock and reset are correctly generated.
- Simulation tools operate consistently.
- Golden reference models are validated independently.

---

# 18. Deliverables

Verification deliverables include:

- Testbenches
- cocotb tests
- Scoreboard
- Golden reference models
- Coverage reports
- Regression reports
- Assertion reports
- Bug reports
- Verification signoff checklist

These artifacts collectively provide evidence of verification completeness.

---

# 19. Traceability Matrix

| Requirement | Verification Method | Status |
|-------------|---------------------|--------|
| MMIO Access | Directed Tests | Planned |
| Descriptor Fetch | Unit Test | Planned |
| Scheduler | Unit + Integration | Planned |
| DMA Transfers | cocotb + Directed | Planned |
| Matrix Multiply | Python Golden Model | Planned |
| ReLU Activation | Directed Tests | Planned |
| Scratchpad Access | Integration Tests | Planned |
| Busy/Done Protocol | Assertions | Planned |
| Reset Behavior | Directed Tests | Planned |
| End-to-End Execution | System Test | Planned |

This matrix ensures every major design requirement is linked to one or more verification activities.

---

# 20. Review Checklist

Before verification signoff, confirm the following:

- [ ] All RTL modules compile successfully.
- [ ] Unit verification completed.
- [ ] Integration verification completed.
- [ ] System verification completed.
- [ ] Functional coverage goals achieved.
- [ ] Code coverage goals achieved.
- [ ] Regression suite passes.
- [ ] Golden model comparisons pass.
- [ ] Assertions pass without unexpected failures.
- [ ] Documentation updated.
- [ ] Outstanding issues reviewed and accepted.

Only after every checklist item has been satisfied should the design proceed toward FPGA implementation or ASIC-oriented development.

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Initial verification plan for the RISC-V AI Accelerator project. |

---

**END OF FILE**