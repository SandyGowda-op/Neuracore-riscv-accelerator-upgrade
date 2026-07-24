# Chapter 14: SystemVerilog Assertions (SVA)

> **Document:** Learning Series
>
> **Chapter:** 14
>
> **Topic:** SystemVerilog Assertions
>
> **Prerequisites:**
>
> - Basic Verilog/SystemVerilog
> - Sequential Logic
> - Finite State Machines
> - Clocked Design
> - Descriptor Fetch Unit

---

# Table of Contents

1. Introduction
2. Why Assertions are Needed
3. What is an Assertion?
4. Assertions vs Testbenches
5. Assertion-Based Verification (ABV)
6. Immediate Assertions
7. Concurrent Assertions
8. Sequences
9. Properties
10. Assertion Directives
11. Clocking Events
12. disable iff
13. Implication Operators
14. Assertion Workflow
15. Assertions in Our DFU
16. Best Practices
17. Common Mistakes
18. Interview Questions
19. Summary

---

# 1. Introduction

As digital systems become larger and more complex, verifying their correctness becomes increasingly difficult.

Traditional verification relies heavily on writing testbenches and manually inspecting waveforms. While this approach works for simple designs, it becomes inefficient for modern RTL containing thousands of signals and numerous interacting modules.

To address this challenge, **SystemVerilog Assertions (SVA)** provide a formal way to describe expected hardware behavior.

Instead of asking:

> "Did the hardware behave correctly?"

Assertions continuously monitor the design and automatically report when an expected property is violated.

In other words, assertions act as **automatic design checkers** embedded alongside the RTL.

---

# 2. Why Assertions are Needed

Imagine verifying a simple finite state machine.

Without assertions, you would:

- Run a simulation.
- Open the waveform viewer.
- Zoom into a particular clock cycle.
- Observe the current state.
- Compare signals manually.
- Repeat this process for every test.

This becomes impractical as designs grow.

Assertions automate these checks.

For example, instead of visually checking that the DFU eventually returns to the IDLE state after completing a fetch, we can write an assertion that verifies this behavior automatically.

Whenever the rule is violated, the simulator immediately reports an error.

---

# 3. What is an Assertion?

An assertion is a statement that describes a condition which **must always be true** during simulation.

If the condition evaluates to true, simulation continues normally.

If the condition evaluates to false, the simulator reports an assertion failure.

Conceptually:

```text
Expected Behaviour

↓

Assertion

↓

Simulation

↓

PASS or FAIL
```

Assertions are therefore executable specifications of hardware behavior.

---

# 4. Assertions vs Testbenches

Although both are used for verification, they serve different purposes.

## Testbench

A testbench **stimulates** the Design Under Test (DUT).

It generates:

- clocks
- resets
- input transactions
- descriptor requests
- random values

The testbench asks:

> "What happens if I apply these inputs?"

---

## Assertion

An assertion **observes** the DUT.

It never drives signals.

Instead, it continuously checks whether the DUT behaves according to specification.

Assertions ask:

> "Did the DUT behave correctly?"

---

### Comparison

| Testbench | Assertion |
|-----------|-----------|
| Generates stimulus | Observes behavior |
| Drives DUT | Never drives DUT |
| Controls simulation | Checks correctness |
| May miss corner cases | Continuously monitors properties |

Both are essential components of a complete verification environment.

---

# 5. Assertion-Based Verification (ABV)

Assertion-Based Verification (ABV) is a methodology in which assertions are treated as first-class verification components rather than optional debugging aids.

Instead of relying solely on waveform inspection, engineers define behavioral rules as assertions.

Examples:

- Busy must never remain high forever.
- The FSM must never enter an illegal state.
- Done must only assert after a successful descriptor capture.
- Memory reads must occur only during the ISSUE_READ state.

During simulation, these rules are evaluated automatically on every relevant clock edge.

ABV significantly improves verification quality because every simulation run checks the same set of properties consistently.

---

# 6. Immediate Assertions

Immediate assertions behave similarly to software assertions.

They are executed immediately when the simulator reaches them.

Example:

```systemverilog
assert (descriptor_valid)
else
    $error("Descriptor is invalid");
```

Characteristics:

- Executed instantly.
- Used inside procedural blocks.
- Useful for simple combinational checks.
- Do not reason about behavior across multiple clock cycles.

Immediate assertions are commonly used for parameter validation and sanity checks.

---

# 7. Concurrent Assertions

Concurrent assertions describe relationships that evolve over time.

Unlike immediate assertions, they observe behavior across multiple clock cycles.

For example:

> If a fetch request occurs today, the descriptor must eventually be captured.

This temporal relationship cannot be expressed using an immediate assertion.

Concurrent assertions solve this problem by allowing engineers to describe sequences of events over time.

Most hardware protocol verification relies on concurrent assertions.

---

# 8. Sequences

A sequence describes an ordered series of events.

Example concept:

```text
Fetch Request

↓

Memory Read

↓

Descriptor Capture

↓

Done
```

Each event must occur in the correct order.

Sequences are reusable building blocks that can later be referenced inside properties.

Typical applications include:

- bus transactions
- handshake protocols
- state transitions
- descriptor fetch operations

---

# 9. Properties

A property combines one or more sequences into a rule that must always hold.

For example:

> Whenever a fetch request occurs, a descriptor must eventually be captured.

Properties describe **expected behavior**, not implementation.

This distinction is important.

Good properties remain valid even if the RTL implementation changes.

---

# 10. Assertion Directives

SystemVerilog provides several directives for using properties.

## assert property

Checks that a property always holds.

Failure indicates an error.

---

## assume property

Primarily used in formal verification.

Assumptions constrain the verification environment.

---

## cover property

Records whether a particular event ever occurred.

Unlike assertions, cover properties do not report failures.

Instead, they answer questions such as:

- Was every FSM state reached?
- Was every descriptor type exercised?
- Did the DONE state occur?

Cover properties are extremely useful for measuring verification completeness.

---
# 11. Clocking Events

Concurrent assertions are evaluated with respect to a clock.

Without a clock, the simulator cannot determine **when** a property should be checked.

A clocking event specifies exactly when the assertion is sampled.

Typical example:

```systemverilog
@(posedge clk)
```

This tells the simulator:

> Evaluate the property on every positive edge of the clock.

Using clocked assertions ensures that the verification model aligns with the synchronous nature of digital hardware.

---

# 12. Sampling Semantics

One of the most misunderstood concepts in SystemVerilog Assertions is signal sampling.

Assertions do **not** continuously monitor changing signals like an oscilloscope.

Instead, they sample signals at the specified clock edge.

Example timeline:

```text
Clock

_|‾|_|‾|_|‾|_|‾|_

Signal

____----_________
```

If the assertion is triggered on `posedge clk`, only the signal value at each rising edge is observed.

Transient glitches between clock edges are ignored unless specifically modeled.

This behavior matches how synchronous hardware itself operates.

---

# 13. The `disable iff` Construct

Many assertions should be ignored during reset.

Consider the following situation:

During reset,

- Busy = 0
- Done = 0
- FSM resets to IDLE

Without disabling assertions during reset, many properties would fail even though the hardware is behaving correctly.

SystemVerilog provides:

```systemverilog
disable iff(reset)
```

Example:

```systemverilog
assert property (
    @(posedge clk)
    disable iff(reset)
    property_name
);
```

Meaning:

If reset is active,

ignore this assertion.

As soon as reset is deasserted,

the assertion becomes active again.

This is one of the most commonly used constructs in assertion-based verification.

---

# 14. Implication Operators

Assertions frequently describe cause-and-effect relationships.

SystemVerilog provides implication operators for this purpose.

Two forms are commonly used.

---

## Overlapped Implication

```systemverilog
|=>
```

Meaning:

The consequence begins in the **same clock cycle** as the condition.

Example concept:

```text
Request

↓

Response begins immediately
```

---

## Non-Overlapped Implication

```systemverilog
|=>
```

*(Note: In actual SVA syntax, non-overlapped implication is written as `|=>`, while overlapped implication uses `|->`. Ensure you use the correct operator in RTL code.)*

Meaning:

The consequence begins on the **next clock cycle**.

Example:

```text
Cycle 1

Fetch Request

↓

Cycle 2

Memory Read
```

Most finite-state-machine properties use non-overlapped implication because state transitions occur on clock boundaries.

---

# 15. Temporal Relationships

One of the greatest strengths of SVA is the ability to verify behavior over time.

Examples include:

- A request must eventually receive a response.
- Busy must eventually deassert.
- Done must never occur before Capture.
- Memory must respond within N cycles.
- Illegal states must never occur.

These temporal properties are extremely difficult to verify reliably through waveform inspection alone.

---

# 16. Assertions Used in Our DFU

During the development of the Descriptor Fetch Unit, assertions were written to monitor several critical behaviors.

Examples include:

## Reset Behavior

Verify that the FSM enters IDLE after reset.

---

## Busy Protocol

Verify that Busy becomes high after a fetch request.

---

## Completion Protocol

Verify that Done only asserts after descriptor capture.

---

## FSM Transitions

Verify that illegal state transitions never occur.

---

## Descriptor Capture

Verify that descriptor registers only update during the CAPTURE state.

---

These assertions continuously monitored the DFU throughout simulation.

Whenever an unexpected condition occurred, the simulator would immediately report an assertion failure.

---

# 17. Assertions vs Waveform Debugging

Without assertions:

Engineer

↓

Run Simulation

↓

Open Waveforms

↓

Zoom

↓

Search Signals

↓

Guess Root Cause

↓

Repeat

---

With assertions:

Simulation

↓

Assertion Failure

↓

Immediate Error Message

↓

Locate Bug

↓

Fix RTL

Assertions dramatically reduce debugging time because they identify **what** failed and often indicate **when** it failed.

---

# 18. Assertion Coverage

Passing assertions does **not** necessarily mean they were exercised.

Consider:

A property may never fail simply because the corresponding scenario never occurred.

For example,

an assertion checking the COMPLETE state is useless if the simulation never reaches COMPLETE.

This is why **coverage** is important.

Coverage answers questions such as:

- Was every assertion activated?
- Were all FSM states exercised?
- Were all transitions observed?

In future project milestones, assertion coverage will be expanded to include DMA and Scheduler modules.

---

# 19. Best Practices

Professional RTL engineers generally follow several important guidelines.

### Keep Assertions Close to the Design

Assertions should verify module behavior where it occurs.

---

### Verify Interfaces

Protocol violations are easier to detect at module boundaries.

---

### Keep Properties Small

Small assertions are easier to debug than one extremely complicated property.

---

### Name Assertions Clearly

Good names improve readability.

Example:

```text
p_busy_after_fetch

a_done_after_capture

p_idle_after_reset
```

---

### Use `disable iff(reset)`

Avoid false failures during reset.

---

### Verify Both Positive and Negative Cases

Check that:

- Correct behavior occurs.
- Incorrect behavior never occurs.

---

# 20. Common Mistakes

New engineers often make the following mistakes:

- Forgetting clocking events.
- Omitting `disable iff(reset)`.
- Writing assertions that depend on implementation rather than behavior.
- Combining too many checks into one property.
- Ignoring assertion failures.
- Assuming passing assertions imply complete verification.

Assertions complement testbenches—they do not replace them.

---

# 21. Industry Perspective

SystemVerilog Assertions are widely used across the semiconductor industry.

Major companies including:

- NVIDIA
- AMD
- Intel
- Apple
- Qualcomm
- Broadcom
- Synopsys
- Cadence

incorporate SVA into their RTL verification environments.

Assertions are particularly valuable because they:

- improve simulation quality
- simplify debugging
- enable formal verification
- document design intent
- prevent regression bugs

In large projects, assertions often remain with the RTL throughout the product lifecycle.

---

# 22. Interview Questions

## Basic

1. What is an assertion?
2. What is the difference between immediate and concurrent assertions?
3. Why are assertions useful?

---

## Intermediate

1. Explain Assertion-Based Verification (ABV).
2. What is the purpose of `disable iff`?
3. What are sequences and properties?
4. Why are clocking events required?

---

## Advanced

1. How would you verify an FSM using assertions?
2. How would you verify a handshake protocol?
3. Explain overlapped and non-overlapped implication.
4. How would you structure assertions for a DMA controller?
5. What are the advantages of embedding assertions within RTL?

---

# 23. Key Takeaways

- Assertions provide an automatic mechanism for verifying hardware behavior.
- Immediate assertions check conditions instantly.
- Concurrent assertions verify behavior over multiple clock cycles.
- Sequences describe ordered events.
- Properties describe expected hardware behavior.
- Assertions improve debugging efficiency and verification quality.
- `disable iff(reset)` prevents false failures during reset.
- Assertions were successfully used to verify the Descriptor Fetch Unit in this project.

---

# Chapter Summary

SystemVerilog Assertions provide a powerful framework for describing and verifying expected hardware behavior. Rather than relying solely on manual waveform inspection, assertions continuously monitor the design and report protocol violations automatically.

In this chapter, we explored the motivation behind Assertion-Based Verification, the difference between immediate and concurrent assertions, the concepts of sequences and properties, and important language features such as clocking events and `disable iff`. We also examined how assertions were applied to the Descriptor Fetch Unit to verify reset behavior, state transitions, descriptor capture, and status signal generation.

The next chapter builds upon these concepts by exploring **Assertion-Based Verification (ABV)** as a complete verification methodology, showing how assertions, directed tests, and coverage work together to produce high-confidence RTL verification.

---

**END OF FILE**