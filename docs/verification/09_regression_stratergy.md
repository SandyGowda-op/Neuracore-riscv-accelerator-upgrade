# Regression Strategy
## AI Accelerator Integrated with a 5-Stage RISC-V Processor

**Document ID:** RS-001

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Scope
3. Objectives
4. Regression Philosophy
5. Regression Levels
6. Test Selection Strategy
7. Regression Execution Flow
8. Automation Strategy
9. Failure Classification
10. Bug Management
11. Regression Reports
12. Regression Entry Criteria
13. Regression Exit Criteria
14. Continuous Integration Considerations
15. Best Practices
16. Review Checklist

---

# 1. Purpose

Regression testing ensures that modifications to the RTL do not introduce unintended functional changes.

Every design update shall be validated by executing a predefined collection of testcases that exercise previously verified functionality in addition to any newly implemented features.

Regression testing provides confidence that the accelerator remains functionally stable throughout development.

---

# 2. Scope

This regression strategy applies to the complete accelerator verification environment.

Modules included are:

- MMIO Interface
- Descriptor Fetch Unit
- Scheduler
- DMA Engine
- Scratchpad Memory
- Matrix Engine
- Activation Unit
- Accelerator Controller
- Top-Level Integration

Regression includes:

- Directed tests
- Random tests
- System tests
- Assertions
- Golden Model comparison
- Coverage collection

---

# 3. Objectives

Regression testing aims to:

- Detect newly introduced bugs
- Prevent recurrence of previously fixed defects
- Verify design stability
- Validate feature interactions
- Support continuous development
- Maintain verification quality

Regression should provide repeatable and deterministic results.

---

# 4. Regression Philosophy

Every RTL modification carries the risk of affecting unrelated functionality.

Accordingly:

- Every bug fix requires regression.
- Every new feature requires regression.
- Every interface modification requires regression.
- Every architectural change requires full regression.

Regression is considered mandatory before any design milestone or release.

---

# 5. Regression Levels

Regression testing is organized into three levels.

---

## Level 1 – Smoke Regression

Purpose:

Verify that the design is fundamentally operational.

Typical tests include:

- Reset
- MMIO read/write
- Descriptor Fetch
- Scheduler startup
- DMA read
- Matrix multiplication
- ReLU operation

Execution Time:

Less than five minutes.

Frequency:

After every RTL modification.

---

## Level 2 – Daily Regression

Purpose:

Verify the correctness of all implemented features.

Includes:

- All unit tests
- Integration tests
- Selected system tests
- Assertion execution
- Golden Model comparison

Execution Frequency:

Once per development day or after a significant set of RTL changes.

---

## Level 3 – Full Regression

Purpose:

Complete verification prior to project milestones and releases.

Includes:

- Every testcase
- Long-duration simulations
- Random testing
- Stress testing
- Coverage collection
- Assertion checking
- End-to-end workload execution

Execution Frequency:

Before project releases, demonstrations, FPGA implementation, or major design reviews.

---

# 6. Test Selection Strategy

Regression suites shall include tests from all verification categories.

| Category | Included |
|----------|----------|
| Unit Tests | ✔ |
| Integration Tests | ✔ |
| System Tests | ✔ |
| Error Handling | ✔ |
| Boundary Conditions | ✔ |
| Stress Tests | ✔ |
| Random Tests | ✔ |

Each regression level contains an appropriate subset of these categories.

---

# 7. Regression Execution Flow

The standard regression flow is:

```text
RTL Updated

↓

Compile RTL

↓

Execute Regression Suite

↓

Run Assertions

↓

Execute Golden Model

↓

Scoreboard Comparison

↓

Collect Coverage

↓

Generate Reports

↓

PASS / FAIL
```

If failures occur, regression terminates for analysis before signoff.

---

# 8. Automation Strategy

Regression execution should be fully automated.

Automation responsibilities include:

- RTL compilation
- Test scheduling
- Simulator execution
- Log generation
- Coverage collection
- Report generation
- Failure summary

Automation minimizes manual effort and ensures consistent execution.

---

# 9. Failure Classification

Regression failures shall be categorized to simplify debugging.

## Functional Failure

The DUT produces incorrect results.

Examples:

- Incorrect matrix multiplication
- Incorrect activation output

---

## Assertion Failure

A SystemVerilog Assertion detects a protocol or design violation.

Examples:

- Illegal FSM transition
- Busy/Done protocol violation

---

## Simulation Failure

Simulation terminates unexpectedly.

Examples:

- Compilation error
- Runtime error
- Simulator crash

---

## Infrastructure Failure

The verification environment itself fails.

Examples:

- Missing input files
- Python environment issues
- Cocotb configuration errors

Infrastructure failures should be resolved before analyzing DUT functionality.

---

# 10. Bug Management

Every regression failure shall result in a documented bug report.

A bug report should include:

- Bug identifier
- Date discovered
- Regression level
- Testcase name
- Simulation log
- Expected behavior
- Observed behavior
- Root cause
- Resolution status

After the bug is fixed:

- A dedicated testcase should be added (if one does not already exist).
- The full regression suite shall be executed again.

---

# 11. Regression Reports

Each regression run shall generate a report summarizing execution.

Typical report contents:

```text
===================================

Regression Summary

===================================

Tests Executed : 128

Passed : 128

Failed : 0

Assertions Failed : 0

Coverage : 97.6%

Execution Time : 42 minutes

Status : PASS

===================================
```

Reports shall be archived to support verification traceability.

---

# 12. Regression Entry Criteria

Regression may begin when:

- RTL compiles successfully.
- Testbench compiles successfully.
- Required test data is available.
- Reference Model is operational.
- Scoreboard is operational.
- No blocking infrastructure issues remain.

---

# 13. Regression Exit Criteria

Regression is considered complete when:

- All scheduled tests execute.
- No unexpected failures remain.
- Assertion failures are resolved.
- Coverage goals are achieved or justified.
- Regression reports are generated.
- Outstanding issues are reviewed.

Only after these criteria are satisfied may the design proceed to verification signoff.

---

# 14. Continuous Integration Considerations

The regression framework should support integration with automated build systems.

Typical CI workflow:

```text
Developer Commit

↓

Automatic Build

↓

Compile RTL

↓

Smoke Regression

↓

Generate Reports

↓

Notify Developer
```

Future enhancements may include:

- Nightly full regression
- Coverage trend monitoring
- Automatic bug creation
- Dashboard integration

---

# 15. Best Practices

Recommended practices include:

- Keep regression suites deterministic.
- Maintain independent testcases.
- Add a regression testcase for every bug fixed.
- Archive reports for future reference.
- Monitor regression execution time.
- Remove obsolete tests only after review.
- Regularly review coverage gaps.
- Automate as much of the workflow as possible.

A healthy regression suite should grow alongside the design rather than remain static.

---

# 16. Review Checklist

Before approving the regression strategy, verify:

- [ ] Regression levels defined
- [ ] Test selection strategy documented
- [ ] Automation approach established
- [ ] Failure classification defined
- [ ] Bug management process documented
- [ ] Reporting requirements established
- [ ] Entry criteria documented
- [ ] Exit criteria documented
- [ ] CI considerations included
- [ ] Best practices documented

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Initial regression strategy for the AI Accelerator verification environment. |

---

**END OF FILE**