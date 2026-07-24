# Test Plan
## AI Accelerator Integrated with a 5-Stage RISC-V Processor

**Document ID:** TP-001

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Scope
3. Test Objectives
4. Test Environment
5. Test Methodology
6. Unit Test Plan
7. Integration Test Plan
8. System Test Plan
9. Directed Test Cases
10. Random Test Cases
11. Corner Case Testing
12. Error Handling Tests
13. Stress Testing
14. Pass/Fail Criteria
15. Test Execution Flow
16. Test Deliverables
17. Traceability Matrix
18. Review Checklist

---

# 1. Purpose

The purpose of this document is to define the testing strategy for the AI Accelerator.

This document specifies:

- which testcases will be executed,
- expected DUT behavior,
- success criteria,
- execution order,
- regression participation.

The goal is to ensure every implemented feature is validated before project signoff.

---

# 2. Scope

This document covers testing of the following modules.

- MMIO Interface
- Descriptor Fetch Unit
- Scheduler
- DMA Engine
- Scratchpad Memory
- Matrix Engine
- Activation Unit
- Accelerator Status Registers
- Complete Accelerator Pipeline

The following are outside the scope of this document.

- FPGA timing validation
- ASIC timing signoff
- Software driver validation
- Physical implementation verification

---

# 3. Test Objectives

Testing shall verify:

- Correct functionality
- Correct interface behavior
- Correct reset operation
- Correct error handling
- Protocol compliance
- End-to-end execution
- Corner-case robustness
- Long-duration stability

---

# 4. Test Environment

Testing shall be performed using:

## RTL

- SystemVerilog RTL

---

## Simulators

- Icarus Verilog
- ModelSim (optional)
- Vivado Simulator (optional)

---

## Verification Frameworks

- cocotb
- Python
- NumPy

---

## Reference Model

Python Golden Model

Used for:

- Matrix multiplication
- ReLU verification
- Descriptor execution comparison

---

# 5. Test Methodology

Testing follows the sequence below.

```text
Compile RTL

↓

Unit Tests

↓

Integration Tests

↓

Directed Tests

↓

Random Tests

↓

Corner Cases

↓

Stress Tests

↓

Regression

↓

Coverage Review

↓

Verification Signoff
```

Each phase must complete successfully before the next begins.

---

# 6. Unit Test Plan

Each module shall first be verified independently.

## Descriptor Fetch Unit

Verify:

- Descriptor read
- Address increment
- Invalid descriptor detection
- Reset behavior

---

## Scheduler

Verify:

- Start command
- Busy generation
- Done generation
- State transitions

---

## DMA Engine

Verify:

- Read transfers
- Write transfers
- Burst operation
- Address generation

---

## Scratchpad

Verify:

- Read
- Write
- Address decoding
- Simultaneous accesses

---

## Matrix Engine

Verify:

- Matrix multiplication
- Busy protocol
- Done protocol
- Output correctness

---

## Activation Unit

Verify:

- ReLU
- Zero input
- Positive values
- Negative values

---

# 7. Integration Test Plan

Subsystem testing combines multiple modules.

Example combinations include:

## Scheduler + DMA

Verify scheduling correctly initiates transfers.

---

## DMA + Scratchpad

Verify operands are stored correctly.

---

## Scratchpad + Matrix Engine

Verify correct operand delivery.

---

## Matrix Engine + Activation Unit

Verify computation followed by activation.

---

## Complete Accelerator

Verify uninterrupted descriptor execution.

---

# 8. System Test Plan

Entire execution pipeline shall be tested.

Execution path:

```text
CPU

↓

MMIO

↓

Descriptor Fetch

↓

Scheduler

↓

DMA

↓

Scratchpad

↓

Matrix Engine

↓

Activation Unit

↓

DMA Write-back
```

Expected outcome:

Correct final output matching the golden reference model.

---

# 9. Directed Test Cases

Directed tests verify specific known functionality.

Examples include:

| Test ID | Description |
|----------|-------------|
| DT-001 | Accelerator Reset |
| DT-002 | Single Descriptor Execution |
| DT-003 | Matrix Multiply |
| DT-004 | ReLU Positive Input |
| DT-005 | ReLU Negative Input |
| DT-006 | DMA Read |
| DT-007 | DMA Write |
| DT-008 | Busy/Done Protocol |

Each directed test has one clearly defined objective.

---

# 10. Random Test Cases

Random testing exercises legal combinations automatically.

Randomized parameters include:

- Matrix dimensions
- Matrix values
- Descriptor addresses
- DMA burst lengths
- MMIO commands
- Activation selection

Random constraints prevent illegal scenarios while maximizing design exploration.

---

# 11. Corner Case Testing

Special attention shall be given to boundary conditions.

Examples include:

- Minimum matrix size
- Maximum matrix size
- Empty descriptor queue
- Consecutive descriptors
- Address boundary conditions
- Maximum DMA burst
- Zero matrices
- Identity matrices
- Overflow scenarios

Corner-case testing helps uncover bugs rarely exercised by standard tests.

---

# 12. Error Handling Tests

The DUT shall correctly detect and respond to invalid conditions.

Test scenarios include:

- Invalid descriptor
- Unsupported opcode
- Invalid MMIO write
- Invalid memory address
- DMA timeout
- Illegal scheduler command
- Invalid activation selection

Expected behavior:

- Error status asserted
- Safe recovery
- No system deadlock

---

# 13. Stress Testing

Stress testing evaluates long-duration operation.

Typical workloads include:

- Thousands of descriptors
- Continuous DMA transfers
- Continuous matrix multiplication
- Long simulation runs
- Random descriptor streams

The objective is to detect:

- Memory leaks
- Counter overflows
- Synchronization failures
- Rare timing issues

---

# 14. Pass/Fail Criteria

A testcase is considered **PASS** when:

- Expected outputs match the golden model.
- Assertions report no failures.
- Protocol timing is correct.
- DUT completes execution.
- No unexpected errors occur.

A testcase is considered **FAIL** if any of the above conditions are violated.

---

# 15. Test Execution Flow

Standard execution flow:

```text
Reset DUT

↓

Initialize Inputs

↓

Start Simulation

↓

Apply Stimulus

↓

Monitor Outputs

↓

Compare With Golden Model

↓

Generate Result

↓

PASS / FAIL
```

Automated execution is preferred for repeatability.

---

# 16. Test Deliverables

Each executed test shall produce:

- Simulation log
- Waveform (if enabled)
- PASS/FAIL report
- cocotb output
- Coverage update
- Assertion report
- Execution timestamp

These artifacts support debugging and regression analysis.

---

# 17. Traceability Matrix

| Feature | Test Type | Status |
|----------|-----------|--------|
| Reset | Directed | Planned |
| MMIO | Directed | Planned |
| Descriptor Fetch | Unit | Planned |
| Scheduler | Unit + Integration | Planned |
| DMA Read | Directed | Planned |
| DMA Write | Directed | Planned |
| Scratchpad Access | Integration | Planned |
| Matrix Multiply | Golden Model | Planned |
| ReLU | Directed | Planned |
| Busy/Done | Assertions | Planned |
| End-to-End Pipeline | System | Planned |
| Error Handling | Directed | Planned |

Every implemented feature shall map to at least one planned test.

---

# 18. Review Checklist

Before approving the test plan, verify:

- [ ] Unit tests defined
- [ ] Integration tests defined
- [ ] System tests defined
- [ ] Directed tests identified
- [ ] Random tests identified
- [ ] Corner cases documented
- [ ] Error scenarios covered
- [ ] Stress tests planned
- [ ] Pass/fail criteria defined
- [ ] Traceability completed
- [ ] Test deliverables identified

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Initial test plan for the AI Accelerator verification environment. |

---

**END OF FILE**