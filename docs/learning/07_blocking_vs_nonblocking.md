# Chapter 07 - Blocking (=) vs Non-Blocking (<=) Assignments

Version: 1.0

Project:
RV32I AI Accelerator Upgrade

Prerequisites

06 - always_ff vs always_comb

Related Chapters

14 - FSM Fundamentals

Modules Using This Concept

Scratchpad

Descriptor Fetch Unit

DMA Controller

Scheduler

MMUL

---

# Learning Objectives

After completing this chapter you should be able to

✓ Explain blocking assignments.

✓ Explain non-blocking assignments.

✓ Know when each should be used.

✓ Understand why sequential logic uses <=.

✓ Avoid common RTL bugs.

---

# 1. Introduction

One of the most common mistakes among beginners is confusing

=

and

<=

Although both assign values, they behave very differently during simulation.

Choosing the wrong assignment operator can create simulation bugs that do not
match real hardware.

---

# 2. Blocking Assignment (=)

Blocking assignments execute immediately.

Each statement completes before the next statement begins.

Example

```systemverilog
always_comb begin

    a = b;

    b = c;

end
```

Execution

Step 1

a receives b

↓

Step 2

b receives c

Each statement blocks the next one until it finishes.

This is similar to software programming.

---

# 3. Non-Blocking Assignment (<=)

Non-blocking assignments schedule updates.

All assignments occur together at the end of the current simulation time step.

Example

```systemverilog
always_ff @(posedge clk) begin

    a <= b;

    b <= c;

end
```

Execution

At the clock edge

↓

Both assignments are scheduled

↓

Both registers update simultaneously

This models how real flip-flops work.

---

# 4. Why Sequential Logic Uses <=

Real hardware registers all sample their inputs at the same clock edge.

Therefore

```systemverilog
always_ff @(posedge clk)

begin

state <= next_state;

end
```

accurately models hardware.

Using

=

inside sequential logic may create simulation ordering problems.

---

# 5. Why Combinational Logic Uses =

Combinational logic represents calculations.

Example

```systemverilog
always_comb begin

result = A + B;

end
```

The calculation is immediate.

No storage exists.

Blocking assignments naturally model this behavior.

---

# 6. Example

Suppose

Before clock

a = 1

b = 2

c = 3

Using

```systemverilog
always_ff @(posedge clk) begin

a <= b;

b <= c;

end
```

After clock

a = 2

b = 3

Notice

a received the OLD value of b.

This matches real hardware.

---

# 7. Incorrect Example

```systemverilog
always_ff @(posedge clk) begin

a = b;

b = c;

end
```

Simulation

Step 1

a becomes 2

Step 2

b becomes 3

Although some synthesizers still infer registers, this coding style is strongly
discouraged because it does not accurately describe simultaneous register
updates and can lead to confusing simulation behavior.

---

# 8. Golden Rule

always_ff

↓

Use

<=

----------------------------

always_comb

↓

Use

=

Following this rule eliminates most beginner mistakes.

---

# 9. How We Used This

Scratchpad

Write Logic

↓

always_ff

↓

Uses <=

----------------------------

Descriptor Fetch Unit

State Register

↓

always_ff

↓

Uses <=

----------------------------

Address Generation

↓

always_comb

↓

Uses =

----------------------------

Next-State Logic

↓

always_comb

↓

Uses =

---

# 10. Common Beginner Mistakes

Mistake

Using = inside always_ff.

--------------------------------

Mistake

Using <= inside always_comb.

--------------------------------

Mistake

Choosing the assignment operator before deciding the hardware.

Correct approach

First determine

Storage

or

Combinational

Then choose

always_ff

or

always_comb

Finally select

<=

or

=

---

# 11. Engineering Mindset

A common misunderstanding is

"I choose always_ff because I used <=."

The correct thought process is

Question

Does this hardware store information?

YES

↓

always_ff

↓

Use <=

NO

↓

always_comb

↓

Use =

The hardware determines the assignment operator—not the other way around.

---

# 12. FPGA Perspective

Both assignment styles synthesize correctly when used appropriately.

Using the recommended coding style improves simulation consistency and makes RTL
easier to understand.

---

# 13. ASIC Perspective

ASIC companies follow strict coding guidelines.

Using

<=

for sequential logic

and

=

for combinational logic

is considered industry best practice.

Many lint tools automatically check these rules.

---

# 14. Analogy

Blocking (=)

Imagine washing dishes.

Wash Plate

↓

Keep Plate

↓

Wash Spoon

↓

Keep Spoon

Everything happens one after another.

--------------------------------

Non-Blocking (<=)

Imagine a class photo.

The photographer says

"Smile!"

Everyone changes position at the same instant.

This is exactly how flip-flops update on a clock edge.

---

# Interview Questions

1. Difference between = and <= ?

2. Why does sequential logic use <= ?

3. Why does combinational logic use = ?

4. What happens if = is used inside always_ff?

5. Which assignment operator models real flip-flops?

6. Explain the dishwashing analogy.

7. Explain the class photo analogy.

---

# Key Takeaways

✓ = executes immediately.

✓ <= schedules updates.

✓ always_ff uses <=.

✓ always_comb uses =.

✓ Think about hardware before syntax.

✓ Flip-flops update simultaneously.

---

# Revision Checklist

□ I know the difference between = and <=.

□ I know why always_ff uses <=.

□ I know why always_comb uses =.

□ I understand simultaneous register updates.

□ I can identify common mistakes.

---

# Personal Lesson From This Project

Initially, it was tempting to decide between always_ff and always_comb by
looking at whether '=' or '<=' was being used.

The better engineering approach is to first determine the type of hardware being
described.

If the hardware stores information, it belongs in always_ff.

If it only performs calculations, it belongs in always_comb.

Once that decision is made, the correct assignment operator follows naturally.