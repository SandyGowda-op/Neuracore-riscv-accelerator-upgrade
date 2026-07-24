# Chapter 06 - always_ff vs always_comb

Version: 1.0

Project:
RV32I AI Accelerator Upgrade

Prerequisites

01 - Memory Design

03 - Packages

04 - Structs

05 - Enums

Related Chapters

07 - Blocking vs Non-Blocking Assignments

14 - FSM Fundamentals

Modules Using This Concept

Scratchpad

Descriptor Fetch Unit

DMA Controller

Scheduler

MMUL Controller

---

# Learning Objectives

After completing this chapter you should be able to

✓ Understand the difference between sequential and combinational logic.

✓ Know when to use always_ff.

✓ Know when to use always_comb.

✓ Understand why SystemVerilog introduced these constructs.

✓ Structure RTL like professional hardware engineers.

---

# 1. Introduction

Before SystemVerilog, Verilog used only

always @(...)

for every type of hardware.

This caused many bugs because the compiler could not determine whether the
designer intended sequential logic or combinational logic.

SystemVerilog introduced

always_ff

and

always_comb

to remove this ambiguity.

---

# 2. Sequential Logic

Sequential logic remembers previous values.

Examples

Program Counter

Registers

Counters

FSM Current State

Pipeline Registers

Busy Flags

Sequential logic changes only on a clock edge.

Example

```systemverilog
always_ff @(posedge clk) begin
    counter <= counter + 1;
end
```

---

# 3. Combinational Logic

Combinational logic does not remember anything.

Outputs depend only on the current inputs.

Examples

ALU

Comparators

Multiplexers

Address Calculations

Decoders

Example

```systemverilog
always_comb begin
    result = A + B;
end
```

---

# 4. The Golden Rule

Ask yourself one question

"Does this hardware remember information?"

If YES

↓

always_ff

If NO

↓

always_comb

This single question correctly identifies most RTL logic.

---

# 5. What always_ff Means

always_ff tells the compiler

"This block describes flip-flops."

Characteristics

✓ Clocked

✓ Stores state

✓ Uses non-blocking assignments

Example

```systemverilog
always_ff @(posedge clk) begin
    state <= next_state;
end
```

---

# 6. What always_comb Means

always_comb tells the compiler

"This block describes combinational logic."

Characteristics

✓ No storage

✓ Immediate response

✓ Automatic sensitivity list

✓ Uses blocking assignments

Example

```systemverilog
always_comb begin
    next_state = IDLE;
end
```

---

# 7. Why always_comb Is Better Than always @(*)

always_comb automatically

✓ Builds the sensitivity list.

✓ Detects incomplete assignments.

✓ Helps prevent accidental latches.

It is the preferred style for modern RTL.

---

# 8. Real Examples

Program Counter

Stores address

↓

always_ff

--------------------------------

ALU

Computes A + B

↓

always_comb

--------------------------------

FSM Current State

Stores present state

↓

always_ff

--------------------------------

FSM Next State

Computes next transition

↓

always_comb

--------------------------------

Comparator

Compares values

↓

always_comb

--------------------------------

Descriptor Word Counter

Stores count

↓

always_ff

---

# 9. Three-Process FSM

Professional RTL usually separates FSMs into

1.

State Register

always_ff

---------------------

2.

Next-State Logic

always_comb

---------------------

3.

Output Logic

always_comb

This structure improves

✓ Readability

✓ Verification

✓ Debugging

✓ Maintenance

---

# 10. Signals in Our Project

always_ff

Current State

Busy Register

Word Counter

Working Descriptor

Descriptor Output Register

Descriptor Index Register

---------------------------

always_comb

Next State

Memory Read Enable

Address Calculation

Descriptor Decode

Done Logic

---

# 11. Common Beginner Mistakes

Mistake

Putting counters inside always_comb.

Wrong.

Counters remember values.

---------------------------------

Mistake

Using always_ff for ALU logic.

Wrong.

ALUs calculate values.

---------------------------------

Mistake

Thinking outputs should always be registered.

Only outputs that need storage belong in always_ff.

---------------------------------

Mistake

Mixing sequential and combinational logic in one block.

Avoid this unless absolutely necessary.

---

# 12. FPGA Perspective

always_ff and always_comb improve synthesis quality and readability.

Most FPGA vendors recommend using them instead of traditional always blocks.

---

# 13. ASIC Perspective

Large ASIC projects almost exclusively use always_ff and always_comb because
they improve

Code Reviews

Linting

Formal Verification

Simulation

Maintainability

---

# 14. How We Used This

Scratchpad

Write Logic

↓

always_ff

Read Logic

↓

always_comb

Descriptor Fetch Unit

Current State

↓

always_ff

Next State

↓

always_comb

Descriptor Decode

↓

always_comb

Descriptor Storage

↓

always_ff

---

# 15. Professional RTL Structure

A typical RTL module follows this structure

Declarations

↓

always_ff

↓

always_comb

↓

assign statements

↓

Submodule Instantiations

Keeping this order makes RTL easier to review.

---

# Interview Questions

1. Why was always_ff introduced?

2. Difference between always_ff and always_comb?

3. Give examples of sequential logic.

4. Give examples of combinational logic.

5. Why is the Program Counter always_ff?

6. Why is the ALU always_comb?

7. Explain the three-process FSM.

8. Why is always_comb preferred over always @(*)?

---

# Key Takeaways

✓ Sequential logic remembers values.

✓ Combinational logic performs calculations.

✓ always_ff describes storage.

✓ always_comb describes logic.

✓ Modern RTL separates sequential and combinational logic.

✓ Three-process FSMs improve readability.

---

# Revision Checklist

□ I know when to use always_ff.

□ I know when to use always_comb.

□ I can identify sequential logic.

□ I can identify combinational logic.

□ I understand the three-process FSM.

□ I know how our DFU will be structured.

---

# Personal Lesson From This Project

One of the biggest mindset changes during this project was learning to think
about hardware behavior instead of syntax.

Instead of asking

"Should I use = or <= ?"

the better question became

"Does this hardware remember anything?"

The answer to that question naturally determines whether the logic belongs
inside always_ff or always_comb.