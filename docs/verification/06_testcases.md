# Testcase Specification
## AI Accelerator Integrated with a 5-Stage RISC-V Processor

**Document ID:** TC-001

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Scope
3. Test Classification
4. Naming Convention
5. Unit Testcases
6. Integration Testcases
7. System Testcases
8. Error Handling Testcases
9. Boundary Testcases
10. Stress Testcases
11. Regression Classification
12. Test Execution Guidelines
13. Test Status Tracking
14. Future Testcases
15. Review Checklist

---

# 1. Purpose

This document defines all planned verification testcases for the AI Accelerator.

Each testcase specifies:

- Objective
- Modules involved
- Input stimulus
- Expected behavior
- Verification method
- Regression priority

The document ensures complete functional verification while maintaining traceability between project requirements and implemented tests.

---

# 2. Scope

This testcase library covers verification of:

- MMIO Interface
- Descriptor Fetch Unit
- Scheduler
- DMA Engine
- Scratchpad Memory
- Matrix Engine
- Activation Unit
- Accelerator Controller
- Complete Accelerator Pipeline

Every implemented feature shall be exercised by at least one testcase.

---

# 3. Test Classification

Testcases are divided into the following categories.

| Category | Purpose |
|----------|---------|
| Unit | Verify individual RTL modules |
| Integration | Verify interaction between modules |
| System | Verify complete accelerator functionality |
| Error | Verify illegal operations |
| Boundary | Verify edge conditions |
| Stress | Verify long-duration stability |
| Regression | Prevent previously fixed bugs from reappearing |

---

# 4. Naming Convention

Each testcase follows a consistent naming format.

```text
TC-XXX_<module>_<description>
```

Examples:

```text
TC-001_Reset

TC-012_DMA_Read

TC-035_MatrixMultiply

TC-051_EndToEndExecution
```

This naming convention simplifies automation and regression reporting.

---

# 5. Unit Testcases

## Reset Verification

### Test ID

TC-001_Reset

### Objective

Verify that every module initializes correctly after reset.

Modules:

- Scheduler
- DMA
- Scratchpad
- Matrix Engine
- Activation Unit

Expected Result

- Busy = 0
- Done = 0
- FSM returns to Idle
- Registers initialized

---

## MMIO Register Write

### Test ID

TC-002_MMIO_Write

Objective

Verify successful MMIO write operations.

Expected Result

Correct register updated.

---

## MMIO Register Read

### Test ID

TC-003_MMIO_Read

Objective

Verify successful MMIO read operations.

Expected Result

Returned value matches expected register contents.

---

## Descriptor Fetch

### Test ID

TC-004_DescriptorFetch

Objective

Verify descriptor loading.

Expected Result

Descriptor correctly decoded.

---

## Scheduler Start

### Test ID

TC-005_SchedulerStart

Objective

Verify scheduler transitions from Idle to Busy.

Expected Result

Execution begins correctly.

---

## DMA Read

### Test ID

TC-006_DMARead

Objective

Verify DMA correctly reads source memory.

Expected Result

Scratchpad contains expected data.

---

## DMA Write

### Test ID

TC-007_DMAWrite

Objective

Verify DMA correctly writes accelerator output back to memory.

Expected Result

Destination memory matches expected values.

---

## Scratchpad Read

### Test ID

TC-008_ScratchpadRead

Objective

Verify scratchpad read operations.

---

## Scratchpad Write

### Test ID

TC-009_ScratchpadWrite

Objective

Verify scratchpad write operations.

---

## Matrix Multiplication

### Test ID

TC-010_MatrixMultiply

Objective

Verify matrix multiplication.

Expected Result

Matches Golden Model exactly.

---

## ReLU Verification

### Test ID

TC-011_ReLU

Objective

Verify ReLU activation.

Input

```text
[-5 2 -1 8]
```

Expected Output

```text
[0 2 0 8]
```

---

# 6. Integration Testcases

## Scheduler + DMA

### Test ID

TC-020_Scheduler_DMA

Objective

Verify scheduler correctly starts DMA.

Expected Result

DMA begins transfer immediately after scheduling.

---

## DMA + Scratchpad

### Test ID

TC-021_DMA_Scratchpad

Objective

Verify transferred data is stored correctly.

---

## Scratchpad + Matrix Engine

### Test ID

TC-022_Scratchpad_Matrix

Objective

Verify matrix engine receives correct operands.

---

## Matrix Engine + ReLU

### Test ID

TC-023_Matrix_ReLU

Objective

Verify activation immediately follows computation.

---

## Complete Compute Pipeline

### Test ID

TC-024_ComputePipeline

Objective

Verify uninterrupted computation pipeline.

---

# 7. System Testcases

## Single Descriptor Execution

### Test ID

TC-050_SingleDescriptor

Objective

Execute one descriptor from start to finish.

Expected Flow

```text
MMIO

↓

Descriptor Fetch

↓

Scheduler

↓

DMA

↓

Matrix Engine

↓

ReLU

↓

Write-back

↓

Done
```

---

## Multiple Descriptor Execution

### Test ID

TC-051_MultipleDescriptors

Objective

Execute multiple descriptors sequentially.

Expected Result

Every descriptor completes successfully.

---

## End-to-End AI Workload

### Test ID

TC-052_EndToEnd

Objective

Execute complete workload.

Verification

Golden Model comparison.

---

# 8. Error Handling Testcases

## Invalid Descriptor

### Test ID

TC-060_InvalidDescriptor

Expected Result

Descriptor rejected.

Error flag asserted.

---

## Illegal MMIO Address

### Test ID

TC-061_InvalidMMIO

Expected Result

Error status generated.

---

## Invalid DMA Address

### Test ID

TC-062_InvalidDMAAddress

Expected Result

Transfer aborted safely.

---

## Invalid Activation Mode

### Test ID

TC-063_InvalidActivation

Expected Result

Error reported.

---

# 9. Boundary Testcases

## Minimum Matrix

### Test ID

TC-070_MinMatrix

Matrix Size

1×1

---

## Maximum Matrix

### Test ID

TC-071_MaxMatrix

Matrix Size

Maximum supported dimensions.

---

## Zero Matrix

### Test ID

TC-072_ZeroMatrix

Expected Result

Zero output matrix.

---

## Identity Matrix

### Test ID

TC-073_IdentityMatrix

Expected Result

Output equals input matrix.

---

## Maximum DMA Burst

### Test ID

TC-074_MaxBurst

Expected Result

Correct burst completion.

---

# 10. Stress Testcases

## Continuous Descriptor Execution

### Test ID

TC-080_LongDescriptorStream

Objective

Execute hundreds of descriptors.

---

## Continuous DMA

### Test ID

TC-081_ContinuousDMA

Objective

Repeated DMA transfers.

---

## Continuous Matrix Operations

### Test ID

TC-082_LongCompute

Objective

Repeated matrix multiplications.

---

## Random Workload

### Test ID

TC-083_RandomExecution

Objective

Execute randomized legal workloads.

Expected Result

No unexpected failures.

---

# 11. Regression Classification

Each testcase belongs to one of three regression groups.

## Smoke Regression

Executed after every RTL modification.

Examples

- Reset
- MMIO
- Descriptor Fetch
- DMA Read
- Matrix Multiply

Execution Time

Less than five minutes.

---

## Daily Regression

Executed once per day.

Includes:

- All unit tests
- Integration tests
- Selected system tests

---

## Full Regression

Executed before releases.

Includes:

- Every testcase
- Random testing
- Stress testing
- Long-duration simulations
- Coverage collection

---

# 12. Test Execution Guidelines

Every testcase should:

- Begin from reset
- Initialize memories
- Configure DUT
- Apply stimulus
- Wait for completion
- Compare against Golden Model
- Generate PASS/FAIL report

Each testcase must remain independent of all others.

---

# 13. Test Status Tracking

Each testcase shall be tracked throughout development.

| Test ID | Description | Status |
|----------|-------------|--------|
| TC-001 | Reset | Planned |
| TC-002 | MMIO Write | Planned |
| TC-003 | MMIO Read | Planned |
| TC-004 | Descriptor Fetch | Planned |
| TC-005 | Scheduler | Planned |
| TC-006 | DMA Read | Planned |
| TC-007 | DMA Write | Planned |
| TC-010 | Matrix Multiply | Planned |
| TC-011 | ReLU | Planned |
| TC-050 | End-to-End | Planned |

Status values may include:

- Planned
- Implemented
- Running
- Passed
- Failed
- Deprecated

---

# 14. Future Testcases

The testcase library is designed to expand alongside the accelerator.

Future additions may include:

- INT8 arithmetic
- BF16 arithmetic
- FP16 support
- FP8 support
- Sparse matrix execution
- Descriptor dependency chains
- Multiple matrix engines
- Multi-channel DMA
- Interrupt handling
- Performance benchmarking

Each new hardware feature should introduce corresponding unit, integration, and system testcases.

---

# 15. Review Checklist

Before approving the testcase specification, verify:

- [ ] Every RTL module has associated testcases
- [ ] Unit tests defined
- [ ] Integration tests defined
- [ ] System tests defined
- [ ] Error scenarios covered
- [ ] Boundary conditions covered
- [ ] Stress tests included
- [ ] Regression groups defined
- [ ] Naming convention followed
- [ ] Status tracking established
- [ ] Documentation reviewed

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Initial testcase specification for the AI Accelerator verification environment. |

---

**END OF FILE**