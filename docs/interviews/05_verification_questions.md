# Verification Interview Questions
## Verification Methodology for the RISC-V AI Accelerator

**Document ID:** INT-VER-001

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Interview Preparation Strategy
3. Beginner Questions
4. Intermediate Questions
5. Advanced Questions
6. Project-Specific Questions
7. Debugging Questions
8. Verification Methodology Questions
9. Whiteboard Questions
10. Common Mistakes
11. Rapid Revision Sheet

---

# 1. Purpose

This document contains interview questions related to verification of the AI Accelerator.

The questions are based on the verification environment developed for this project using:

- Cocotb
- Python Golden Model
- Scoreboard
- Assertions
- Functional Coverage
- Regression Testing

These topics are frequently asked in Design Verification (DV), RTL Design, FPGA Design, and ASIC Front-End interviews.

---

# 2. Interview Preparation Strategy

Whenever discussing verification:

1. Explain why verification is important.
2. Explain your verification flow.
3. Explain the tools used.
4. Explain how correctness is checked.
5. Discuss coverage and regression.

Interviewers are often more interested in *how* you verified the design than in the RTL itself.

---

# 3. Beginner Questions

---

## Q1. What is hardware verification?

### Answer

Hardware verification is the process of ensuring that a digital design behaves according to its specification.

The goal is to identify functional bugs before fabrication or deployment.

Verification includes:

- Simulation
- Assertions
- Coverage analysis
- Regression testing
- Scoreboard comparisons

---

## Q2. Why is verification important?

### Answer

Fixing hardware bugs after fabrication is extremely expensive.

Verification helps ensure:

- Functional correctness
- Reliable operation
- Protocol compliance
- Robustness under corner cases

In modern ASIC projects, verification typically consumes more effort than RTL development.

---

## Q3. What is a testbench?

### Answer

A testbench is an environment that stimulates the Design Under Test (DUT) and checks its responses.

A typical testbench contains:

- Clock generator
- Reset generator
- Driver
- Monitor
- Scoreboard
- Reference Model

The DUT itself is never modified by the testbench.

---

## Q4. What is Cocotb?

### Answer

Cocotb (Coroutine-based Co-simulation TestBench) is a Python-based verification framework.

It allows engineers to write testbenches in Python while interacting with Verilog/SystemVerilog RTL.

Advantages include:

- Python ecosystem support
- Easy random test generation
- Faster development
- Integration with scientific libraries

---

## Q5. Why use Python instead of Verilog for verification?

### Answer

Python provides:

- Better readability
- Extensive libraries
- Easier automation
- Rapid development
- Simple mathematical modeling

RTL remains in Verilog/SystemVerilog, while Python simplifies verification infrastructure.

---

# 4. Intermediate Questions

---

## Q6. What is a Golden Model?

### Answer

A Golden Model is a trusted reference implementation used to compute expected outputs.

For this project, a Python model performs matrix multiplication and activation operations.

RTL outputs are compared against this model to verify correctness.

---

## Q7. What is a Scoreboard?

### Answer

A Scoreboard compares expected outputs from the Golden Model with actual outputs produced by the DUT.

If all outputs match:

```
PASS
```

Otherwise:

```
FAIL
```

It automates functional checking across many testcases.

---

## Q8. What is a Monitor?

### Answer

A Monitor observes DUT signals without modifying them.

Its responsibilities include:

- Capturing transactions
- Recording outputs
- Sending observed data to the Scoreboard

Monitors are passive components.

---

## Q9. What is a Driver?

### Answer

The Driver converts test stimuli into DUT input signals.

Responsibilities include:

- Driving MMIO transactions
- Supplying descriptors
- Initiating DMA transfers
- Applying reset sequences

The Driver actively interacts with the DUT.

---

## Q10. What is a directed test?

### Answer

A directed test verifies a specific feature using carefully chosen inputs.

Examples:

- Identity matrix multiplication
- Zero matrix multiplication
- Single DMA transfer
- Reset behavior

Directed tests are deterministic and useful for debugging.

---

# 5. Advanced Questions

---

## Q11. What is constrained random testing?

### Answer

Constrained random testing generates randomized inputs while enforcing legal constraints.

Advantages:

- Better corner-case coverage
- Increased bug discovery
- Reduced manual testcase creation

Randomization must still produce valid transactions.

---

## Q12. What is functional coverage?

### Answer

Functional coverage measures whether all intended design features have been exercised.

Examples include:

- DMA modes
- Matrix sizes
- Activation types
- MMIO registers
- Descriptor formats

Coverage measures *what* has been tested rather than whether the design is correct.

---

## Q13. What is code coverage?

### Answer

Code coverage measures which parts of the RTL were executed during simulation.

Common metrics include:

- Statement coverage
- Branch coverage
- Toggle coverage
- FSM coverage

High code coverage does not guarantee functional correctness.

---

## Q14. What is Assertion-Based Verification (ABV)?

### Answer

Assertions continuously monitor expected design behavior during simulation.

Examples include:

- Busy must eventually deassert.
- Done cannot assert before Start.
- Illegal FSM transitions are prohibited.

Assertions help detect protocol violations early.

---

# 6. Project-Specific Questions

---

## Q15. Explain your verification flow.

### Answer

The verification flow used in this project is:

```
RTL

↓

Compile

↓

Cocotb Testbench

↓

Driver

↓

DUT

↓

Monitor

↓

Scoreboard

↓

Golden Model Comparison

↓

Coverage Collection

↓

Regression Testing
```

This flow provides automated functional verification and regression capability.

---

## Q16. How did you verify matrix multiplication?

### Answer

Matrix multiplication results were verified by:

1. Generating input matrices.
2. Computing expected results using the Python Golden Model.
3. Running the RTL simulation.
4. Comparing RTL outputs with the expected outputs using the Scoreboard.

Each output element was checked for correctness.

---

## Q17. How did you verify DMA?

### Answer

DMA verification included:

- Source address verification
- Destination address verification
- Transfer length checking
- Busy/Done protocol verification
- Boundary conditions
- Random transfers

Memory contents before and after transfers were compared.

---

## Q18. How did you verify MMIO?

### Answer

MMIO verification involved:

- Register read/write tests
- Invalid address accesses
- Control register behavior
- Status register updates
- Reset values

The objective was to ensure correct communication between the CPU and accelerator.

---

# 7. Debugging Questions

---

## Q19. The Scoreboard reports mismatches. What would you do?

### Expected Answer

Possible causes include:

- RTL bug
- Golden Model bug
- Driver error
- Monitor error
- Timing mismatch

Debugging process:

1. Reproduce the failure.
2. Compare expected and actual outputs.
3. Inspect waveforms.
4. Verify monitor captures.
5. Confirm Golden Model correctness.
6. Isolate the faulty component.

---

## Q20. Assertions fail during simulation. What does that indicate?

### Answer

Assertion failures indicate that the DUT violated an expected property.

Possible reasons:

- RTL bug
- Protocol violation
- Incorrect test stimulus
- Reset sequencing error

Assertions help detect problems at the exact cycle they occur.

---

# 8. Verification Methodology Questions

---

## Q21. What is regression testing?

### Answer

Regression testing reruns previously passing testcases after RTL modifications.

Purpose:

- Detect newly introduced bugs
- Ensure existing functionality remains intact
- Validate bug fixes

Regression is essential throughout the development cycle.

---

## Q22. What is a smoke regression?

### Answer

A smoke regression is a small set of essential tests executed after each RTL change.

Its purpose is to quickly verify that fundamental functionality still works before running longer regression suites.

---

## Q23. What is the difference between simulation and synthesis?

### Answer

Simulation verifies functional correctness using a simulator.

Synthesis converts RTL into a gate-level hardware implementation.

Simulation answers:

*"Does it work?"*

Synthesis answers:

*"Can it be implemented?"*

---

## Q24. What verification metrics did your project use?

### Answer

The project used:

- Directed tests
- Random tests
- Scoreboard comparison
- Golden Model verification
- Assertions
- Functional coverage
- Code coverage
- Regression testing

Together, these provide confidence in design correctness.

---

# 9. Whiteboard Questions

Typical interview exercises include:

- Draw a verification environment.
- Explain Driver-Monitor-Scoreboard interaction.
- Draw a regression flow.
- Explain functional coverage.
- Show a Golden Model comparison.
- Draw Cocotb architecture.
- Explain assertion checking.
- Sketch a DMA verification flow.

---

# 10. Common Mistakes

Avoid:

❌ Assuming simulation alone guarantees correctness.

❌ Confusing code coverage with functional coverage.

❌ Ignoring regression testing.

❌ Believing assertions replace testcases.

❌ Forgetting to verify corner cases.

Instead:

- Explain multiple verification techniques.
- Discuss automation.
- Emphasize coverage.
- Relate methodology to your project.

---

# 11. Rapid Revision Sheet

Review these topics before interviews:

- Verification flow
- Cocotb
- Python Golden Model
- Driver
- Monitor
- Scoreboard
- Directed testing
- Random testing
- Assertions
- Functional coverage
- Code coverage
- Regression testing
- Debugging methodology
- Waveform analysis
- Design verification trade-offs

A strong understanding of verification demonstrates that you can not only build hardware but also prove that it functions correctly under a wide range of operating conditions.

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Initial Verification interview guide for the RISC-V AI Accelerator project. |

---

**END OF FILE**