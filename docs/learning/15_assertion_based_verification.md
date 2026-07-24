# Chapter 15: Assertion-Based Verification (ABV)

> **Document:** Learning Series
>
> **Chapter:** 15
>
> **Topic:** Assertion-Based Verification (ABV)
>
> **Prerequisites:**
>
> - 13 Descriptor Fetch Unit
> - 14 SystemVerilog Assertions
> - Finite State Machines
> - Testbench Design

---

# Table of Contents

1. Introduction
2. What is Verification?
3. Evolution of Verification Methodologies
4. What is Assertion-Based Verification?
5. Why Assertion-Based Verification?
6. ABV Components
7. Assertions vs Directed Testing
8. Assertions vs Functional Coverage
9. Assertions vs Formal Verification
10. Verification Flow
11. ABV Applied to Our DFU
12. Verification Metrics
13. Best Practices
14. Common Mistakes
15. Industry Perspective
16. Interview Questions
17. Summary

---

# 1. Introduction

Designing digital hardware is only half of an engineer's responsibility.

The second half—and arguably the more difficult half—is proving that the hardware works correctly under every expected operating condition.

A hardware design that compiles successfully is **not necessarily correct**.

Likewise, a design that passes a few simulations is **not necessarily verified**.

Verification is therefore the process of building confidence that a hardware design behaves according to its specification.

One of the most powerful methodologies developed for this purpose is **Assertion-Based Verification (ABV).**

Rather than manually checking waveforms after every simulation, ABV embeds executable design rules directly into the verification environment.

These rules continuously monitor hardware behaviour and immediately report any protocol violations.

---

# 2. What is Verification?

Verification answers one simple question:

> **"Did we build the design correctly?"**

It is important to distinguish verification from validation.

| Verification | Validation |
|--------------|------------|
| Did we implement the specification correctly? | Did we build the correct product? |
| RTL focused | System focused |
| Engineers | Customers/System Architects |

In this project, our focus is **verification**.

Examples include:

- Is the DFU entering the correct FSM states?
- Is the Busy signal asserted correctly?
- Is the descriptor captured at the right clock cycle?
- Does the Done signal occur only after successful completion?

Verification attempts to answer all these questions objectively.

---

# 3. Evolution of Verification Methodologies

Verification methodologies have evolved significantly over the past several decades.

---

## Stage 1 — Manual Waveform Inspection

Early digital systems were verified almost entirely through waveform analysis.

The engineer would:

```text
Run Simulation

↓

Open Waveforms

↓

Observe Signals

↓

Search For Bugs
```

Advantages:

- Simple

Disadvantages:

- Extremely time consuming
- Human error
- Difficult to scale

---

## Stage 2 — Directed Testing

Testbenches were introduced to automate stimulus generation.

Instead of manually toggling inputs, engineers wrote directed tests.

Example:

```text
Reset

↓

Fetch Descriptor

↓

Check Busy

↓

Check Done
```

This improved productivity but still required engineers to inspect waveforms.

---

## Stage 3 — Assertion-Based Verification

Assertions transformed verification from passive observation into active checking.

Now,

```text
Simulation

↓

Assertions Monitor DUT

↓

Automatic PASS / FAIL
```

Waveform inspection became necessary only after an assertion failure.

---

## Stage 4 — Modern Verification

Today's verification environments combine multiple techniques.

These include:

- Directed Tests
- Random Testing
- Assertions
- Functional Coverage
- Code Coverage
- Formal Verification
- UVM

Together, these techniques provide high confidence in RTL correctness.

---

# 4. What is Assertion-Based Verification?

Assertion-Based Verification is a methodology in which assertions are used to verify that a hardware design continuously satisfies its specification.

Instead of describing **inputs**, assertions describe **expected behaviour**.

For example,

rather than saying

> "Apply a fetch request."

ABV says

> "Whenever a fetch request occurs, Busy must eventually become high."

The simulator automatically checks this rule throughout execution.

If the property is violated,

verification immediately reports an error.

---

# 5. Why Assertion-Based Verification?

ABV provides several significant advantages.

## Continuous Checking

Assertions monitor the design during the entire simulation.

No manual inspection is required.

---

## Early Bug Detection

Protocol violations are detected immediately.

This significantly reduces debugging time.

---

## Design Documentation

Assertions describe expected hardware behaviour.

Future engineers can understand the design simply by reading the assertions.

---

## Regression Protection

Assertions remain active across future design revisions.

If new code breaks an existing protocol,

the assertion immediately reports the problem.

---

## Improved Confidence

Passing assertions increase confidence that the hardware behaves according to specification.

Although passing assertions do not prove correctness, they substantially improve verification quality.

---

# 6. Components of Assertion-Based Verification

A complete ABV environment consists of several interacting components.

```text
Specification

↓

Assertions

↓

RTL Design

↓

Testbench

↓

Simulation

↓

Assertion Results

↓

Debug
```

Each component serves a distinct role.

---

## Specification

Defines expected behaviour.

Example:

- Busy must remain high during descriptor fetch.
- Done must occur after descriptor capture.

---

## Assertions

Translate behavioural requirements into executable rules.

---

## RTL

Implements the hardware.

---

## Testbench

Provides stimulus.

Without stimulus,

assertions have nothing to monitor.

---

## Simulator

Executes both RTL and assertions simultaneously.

---

## Debug

If an assertion fails,

waveforms and logs are analysed to determine the root cause.

---

# 7. Assertions vs Directed Testing

Although they work together, directed tests and assertions solve different problems.

## Directed Testing

Responsible for generating scenarios.

Example:

```text
Reset

↓

Descriptor Fetch

↓

Observe Outputs
```

---

## Assertions

Responsible for checking correctness.

Example:

```text
If Fetch occurs,

Busy must assert.

If Busy remains high forever,

report an error.
```

Directed tests answer:

> "What should we test?"

Assertions answer:

> "Did it behave correctly?"

Neither replaces the other.

Both are essential for a robust verification environment.

---

# 8. Assertions vs Functional Coverage

Assertions and coverage are often confused.

They serve different purposes.

## Assertions

Answer:

> Did something illegal happen?

Example:

Busy stayed high forever.

Result:

FAIL

---

## Functional Coverage

Answers:

> Did this scenario ever occur?

Example:

Was the COMPLETE state ever reached?

Result:

YES / NO

Coverage does not indicate correctness.

Assertions do not indicate completeness.

Both are required for comprehensive verification.

---

# 9. Assertions vs Formal Verification

Assertion-Based Verification (ABV) and Formal Verification are closely related but are not identical.

Both use assertions to describe expected hardware behaviour, but they use them differently.

---

## Assertion-Based Verification

Assertions are evaluated during simulation.

The simulator checks assertions only for the stimulus generated by the testbench.

Example:

```
Directed Test

↓

RTL Simulation

↓

Assertions Evaluated

↓

PASS / FAIL
```

If a particular scenario is never exercised by the testbench, the assertion will never be evaluated for that scenario.

---

## Formal Verification

Formal verification mathematically proves whether assertions are always true.

Instead of relying on simulation vectors, formal tools explore every possible input combination.

Conceptually,

```
RTL

↓

Assertions

↓

Mathematical Solver

↓

Property Proven
```

Advantages:

- No stimulus required
- Exhaustive verification
- Excellent for protocol checking

Disadvantages:

- Computationally expensive
- Difficult for very large designs
- Requires carefully written properties

---

## Comparison

| Assertion-Based Verification | Formal Verification |
|------------------------------|---------------------|
| Simulation based | Mathematical proof |
| Needs stimulus | No stimulus required |
| Checks executed scenarios | Checks all possible scenarios |
| Faster setup | More rigorous |

In most industrial projects, ABV and Formal Verification complement one another.

---

# 10. Verification Flow

A professional RTL verification flow generally follows a structured sequence.

```
Write Specification

↓

Design RTL

↓

Develop Testbench

↓

Write Assertions

↓

Compile

↓

Run Simulation

↓

Observe Assertion Results

↓

Debug

↓

Fix RTL

↓

Regression Testing
```

Verification is therefore an iterative process.

Very few hardware modules work perfectly on the first attempt.

---

# 11. Assertion Development Process

Writing assertions should follow a systematic methodology.

---

## Step 1

Understand the specification.

Example:

> Busy shall remain asserted while the DFU is fetching a descriptor.

---

## Step 2

Identify observable signals.

Example:

- Busy
- Done
- Current State
- Fetch Request

---

## Step 3

Write behavioural properties.

Instead of describing implementation,

describe expected behaviour.

Example:

> After a fetch request, Busy shall assert.

---

## Step 4

Convert the property into SVA.

---

## Step 5

Run simulation.

---

## Step 6

Debug failures.

---

## Step 7

Keep assertions as permanent regression tests.

---

# 12. Assertion Strategy Used in Our DFU

During development of the Descriptor Fetch Unit, assertions were written to verify each major aspect of the controller.

The strategy focused on behavioural correctness rather than implementation details.

Assertions were grouped into logical categories.

---

## Reset Assertions

Purpose:

Verify correct initialization.

Checks included:

- FSM enters IDLE.
- Busy clears.
- Done clears.

---

## FSM Assertions

Purpose:

Verify legal state transitions.

Checks included:

- IDLE → ISSUE_READ
- ISSUE_READ → CAPTURE
- CAPTURE → COMPLETE
- COMPLETE → IDLE

Illegal transitions were prohibited.

---

## Busy Assertions

Purpose:

Verify Busy protocol.

Checks included:

- Busy asserted during fetch.
- Busy deasserted after completion.

---

## Done Assertions

Purpose:

Verify completion signalling.

Checks included:

- Done occurs only after descriptor capture.
- Done remains asserted only for the intended duration.

---

## Descriptor Assertions

Purpose:

Verify descriptor capture.

Checks included:

- Descriptor register updates only during CAPTURE.
- Descriptor output remains stable afterwards.

---

# 13. Simulation Results

The DFU verification environment successfully completed simulation.

Observed behaviour included:

- Successful compilation.
- Correct reset.
- Descriptor memory writes.
- Descriptor memory reads.
- Descriptor fetch.
- Correct FSM transitions.
- Successful descriptor capture.
- Busy protocol verified.
- Done protocol verified.
- No assertion failures.

Simulation completed successfully after the addition of an explicit `$finish` statement.

This confirmed that both the RTL and the verification environment behaved as intended.

---

# 14. Debugging Experience

One of the most valuable lessons learned during DFU development involved simulation control.

Initially,

simulation appeared to hang indefinitely.

The root cause was not the RTL.

Instead,

the simulation contained:

```
always #5 clk = ~clk;
```

This clock generator runs forever.

The simulator was also instructed to execute:

```
run -all
```

Without an explicit termination condition,

the simulator correctly continued forever.

The solution was simply:

```
$finish;
```

at the end of the directed test.

This debugging exercise demonstrates an important engineering lesson:

A simulation environment is part of the design.

Correct RTL alone does not guarantee a successful verification environment.

---

# 15. Verification Metrics

Successful verification is measured using several metrics.

---

## Functional Correctness

Does the hardware behave according to specification?

Verified using:

- Assertions
- Directed Tests

---

## State Coverage

Were all FSM states exercised?

For the DFU:

- IDLE
- ISSUE_READ
- CAPTURE
- COMPLETE

All were observed during simulation.

---

## Transition Coverage

Were all legal transitions exercised?

Verified through simulation logs.

---

## Assertion Results

Did any assertion fail?

Result:

No.

---

## Regression Stability

Can the design pass repeated simulations?

Result:

Yes.

---

# 16. Best Practices

Professional verification engineers generally follow these principles.

### Verify behaviour rather than implementation.

Assertions should describe what must happen, not how it is implemented.

---

### Keep assertions modular.

One assertion should verify one behaviour.

---

### Keep assertion names meaningful.

Example:

```
p_idle_after_reset

p_busy_after_fetch

p_done_after_capture
```

---

### Use assertions throughout development.

Do not wait until the design is finished.

Assertions are most valuable while the design is evolving.

---

### Maintain assertions with RTL.

Assertions should evolve alongside the hardware.

Removing assertions after debugging defeats their purpose.

---

# 17. Common Mistakes

Common ABV mistakes include:

- Treating assertions as optional.
- Writing assertions only after bugs appear.
- Verifying implementation instead of behaviour.
- Ignoring assertion failures.
- Assuming passing assertions imply complete verification.
- Forgetting to verify reset behaviour.
- Not combining assertions with directed tests.

Effective verification always combines multiple techniques.

---

# 18. Industry Perspective

Modern semiconductor companies place enormous emphasis on verification.

In many commercial projects,

verification engineers outnumber design engineers.

Large organisations frequently dedicate:

- RTL Designers
- Verification Engineers
- Formal Verification Engineers
- UVM Engineers
- Emulation Teams

All working together.

Assertion-Based Verification forms a critical component of these workflows because assertions:

- improve debugging
- reduce regression failures
- document expected behaviour
- integrate naturally with formal verification
- improve long-term maintainability

Learning ABV early provides a strong foundation for professional verification methodologies.

---

# 19. Interview Questions

## Basic

1. What is Assertion-Based Verification?
2. Why are assertions important?
3. How do assertions differ from testbenches?

---

## Intermediate

1. Explain the verification flow.
2. What are the advantages of ABV?
3. Why are assertions considered executable specifications?
4. How does ABV improve debugging?

---

## Advanced

1. Explain the difference between ABV and Formal Verification.
2. How would you verify a DMA controller using assertions?
3. How would you organize assertions in a large SoC project?
4. Why should assertions verify behaviour instead of implementation?

---

# 20. Key Takeaways

- Verification is an essential part of hardware development.
- Assertion-Based Verification continuously monitors RTL behaviour.
- Assertions complement directed tests rather than replacing them.
- ABV improves debugging, regression testing, and documentation.
- Behavioural properties are more robust than implementation-specific checks.
- The DFU developed in this project was verified using directed tests and SystemVerilog Assertions, resulting in a stable and well-understood design.

---

# Chapter Summary

Assertion-Based Verification is one of the most effective methodologies for improving confidence in RTL correctness. By expressing expected behaviour as executable properties, engineers can automatically detect protocol violations during simulation instead of relying solely on manual waveform inspection.

In this project, ABV played a central role in verifying the Descriptor Fetch Unit. Assertions were used to validate reset behaviour, finite state machine transitions, descriptor capture, and status signalling. Combined with directed testing, they formed a structured verification environment that successfully validated the DFU implementation and established a strong foundation for verifying future modules such as the Scheduler and DMA Engine.

---

**END OF FILE**