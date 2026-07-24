# Assertion Plan
## AI Accelerator Integrated with a 5-Stage RISC-V Processor

**Document ID:** AP-001

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Scope
3. Assertion-Based Verification Overview
4. Assertion Objectives
5. Assertion Categories
6. Module-wise Assertion Plan
7. Interface Assertions
8. Protocol Assertions
9. FSM Assertions
10. Data Integrity Assertions
11. Error Detection Assertions
12. Reset Assertions
13. End-to-End Assertions
14. Assertion Severity
15. Regression Strategy
16. Review Checklist

---

# 1. Purpose

This document defines the assertion strategy for the AI Accelerator verification environment.

Assertions continuously monitor RTL behavior during simulation and immediately report protocol violations or illegal design states.

Unlike directed tests, assertions execute automatically whenever their conditions become active.

---

# 2. Scope

Assertions shall be implemented for:

- MMIO Interface
- Descriptor Fetch Unit
- Scheduler
- DMA Engine
- Scratchpad Memory
- Matrix Engine
- Activation Unit
- Accelerator Controller
- Top-Level Integration

Assertions are intended to detect functional bugs as early as possible.

---

# 3. Assertion-Based Verification Overview

Assertion-Based Verification (ABV) embeds executable design properties into the RTL or verification environment.

Typical verification flow:

```text
RTL

↓

Assertions Observe Signals

↓

Property Evaluation

↓

PASS / FAIL

↓

Simulation Continues (or Stops)
```

Assertions verify correctness continuously throughout simulation.

---

# 4. Assertion Objectives

Assertions are used to verify:

- Correct protocol usage
- Legal FSM transitions
- Valid handshakes
- Proper reset behavior
- Correct busy/done sequencing
- Illegal state detection
- Data stability
- Interface timing

Assertions should detect bugs immediately after they occur.

---

# 5. Assertion Categories

The verification environment shall include the following assertion categories.

| Category | Purpose |
|----------|---------|
| Reset | Verify reset behavior |
| Protocol | Verify interface handshakes |
| FSM | Verify state transitions |
| Timing | Verify sequencing requirements |
| Data Integrity | Verify stable data |
| Interface | Verify module communication |
| Error | Detect illegal operations |
| End-to-End | Verify complete execution flow |

---

# 6. Module-wise Assertion Plan

## MMIO Interface

Assertions verify:

- Legal register addresses
- Read/write protocol
- Start bit behavior
- Busy register updates
- Done register updates

---

## Descriptor Fetch Unit

Assertions verify:

- Valid descriptor address
- Descriptor fetch completion
- Descriptor validity
- Proper request/acknowledge sequence

---

## Scheduler

Assertions verify:

- Idle → Busy transition
- Busy → Done transition
- No illegal state transitions
- Single active descriptor

---

## DMA Engine

Assertions verify:

- Valid transfer length
- Address alignment
- Transfer completion
- Read/write ordering

---

## Scratchpad Memory

Assertions verify:

- Valid address range
- No simultaneous conflicting writes
- Correct read-after-write behavior

---

## Matrix Engine

Assertions verify:

- Start signal accepted only when idle
- Busy asserted during computation
- Done asserted only after computation completes
- Output remains stable after completion

---

## Activation Unit

Assertions verify:

- Valid activation mode
- Output validity
- Correct completion indication

---

# 7. Interface Assertions

Every major interface shall include protocol assertions.

Typical interfaces include:

- MMIO
- DMA
- Scheduler
- Matrix Engine
- Activation Unit

Each interface should verify:

- Valid request
- Valid response
- Proper sequencing
- No illegal overlaps

---

## Example Property

When a valid request is accepted, a completion signal shall eventually be generated.

This prevents transactions from remaining permanently active.

---

# 8. Protocol Assertions

Handshake protocols shall satisfy the following rules.

## Busy/Done

Requirements:

- Busy asserted before Done
- Done asserted only once
- Busy deasserted after completion

---

## Ready/Valid

Requirements:

- Valid remains asserted until accepted
- Data remains stable while waiting
- Ready accepted only for valid transactions

---

## MMIO

Requirements:

- One response per request
- No duplicate responses
- Address remains stable during transaction

---

# 9. FSM Assertions

Every FSM shall satisfy:

- Legal reset state
- Only valid transitions
- No unreachable states entered
- No undefined encodings
- Eventual return to Idle

Example:

```text
Idle

↓

Fetch

↓

Execute

↓

Complete

↓

Idle
```

Transitions outside this sequence shall be reported.

---

# 10. Data Integrity Assertions

Assertions shall verify that data remains stable when required.

Examples:

- Descriptor contents
- Scratchpad outputs
- Matrix engine outputs
- DMA data buses

No unexpected data changes should occur during valid transactions.

---

# 11. Error Detection Assertions

Assertions shall detect illegal conditions including:

- Invalid descriptor
- Illegal MMIO access
- Unsupported activation mode
- Invalid DMA length
- Invalid memory address
- Illegal scheduler command

These conditions should immediately generate assertion failures or documented error responses.

---

# 12. Reset Assertions

Every module shall satisfy reset requirements.

Checks include:

- FSM enters Idle
- Busy cleared
- Done cleared
- Registers initialized
- Outstanding operations cancelled

Reset should always place the accelerator into a deterministic state.

---

# 13. End-to-End Assertions

System-level assertions verify complete execution flow.

Typical sequence:

```text
Start

↓

Descriptor Fetch

↓

DMA Read

↓

Matrix Compute

↓

Activation

↓

DMA Write

↓

Done
```

The order shall always remain valid.

---

# 14. Assertion Severity

Assertion failures shall be classified by severity.

| Severity | Description |
|----------|-------------|
| Info | Informational event |
| Warning | Unexpected but recoverable |
| Error | Functional violation |
| Fatal | Simulation should terminate |

Fatal assertions should be reserved for unrecoverable protocol violations.

---

# 15. Regression Strategy

All assertions shall execute during every regression run.

Regression requirements:

- No unexpected assertion failures
- No disabled assertions without justification
- Newly added RTL features require corresponding assertions
- Assertion failures block regression signoff

Assertion reports shall be archived with regression results.

---

# 16. Review Checklist

Before approving the assertion plan, verify:

- [ ] Reset assertions defined
- [ ] Protocol assertions implemented
- [ ] FSM assertions implemented
- [ ] Interface assertions implemented
- [ ] Data integrity assertions included
- [ ] Error detection assertions included
- [ ] End-to-end assertions defined
- [ ] Severity levels documented
- [ ] Regression strategy established
- [ ] Documentation reviewed

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Initial assertion plan for the AI Accelerator verification environment. |

---

**END OF FILE**