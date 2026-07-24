# Chapter 05 - SystemVerilog Enums

Version: 1.0

Project:
RV32I AI Accelerator Upgrade

Prerequisites

01 - Memory Design

03 - Packages

04 - Structs

Related Chapters

06 - always_ff vs always_comb

11 - Descriptor Architecture

Modules Using This Concept

Descriptor Package

Descriptor Fetch Unit

DMA Controller

Future Scheduler

---

# Learning Objectives

After completing this chapter you should be able to

✓ Explain why enums exist.

✓ Create enum datatypes.

✓ Understand type safety.

✓ Use enums in FSMs.

✓ Understand why enums improve readability.

---

# 1. Introduction

As digital systems become larger, engineers begin assigning names to states,
opcodes and configuration values.

Instead of writing

2'b00

2'b01

2'b10

SystemVerilog allows us to write

IDLE

FETCH

COMPLETE

These names are called Enumerations (Enums).

---

# 2. What is an Enum?

An Enum is a user-defined datatype where each value has a meaningful name.

Example

```systemverilog
typedef enum logic [1:0] {

    IDLE,

    FETCH,

    COMPLETE

} state_t;
```

Now we can declare

```systemverilog
state_t current_state;
```

instead of

```systemverilog
logic [1:0] current_state;
```

---

# 3. Why Were Enums Introduced?

Without enums

```systemverilog
if(state == 2'b01)
```

Question

What does 2'b01 mean?

Nobody knows without checking documentation.

With enums

```systemverilog
if(state == FETCH)
```

The code immediately explains itself.

This is called Self-Documenting Code.

---

# 4. Enums Do NOT Create Hardware

Enums are compile-time language constructs.

During synthesis

```systemverilog
FETCH
```

becomes

```text
2'b01
```

(or another encoded value if explicitly specified).

The generated hardware is identical.

---

# 5. Advantages of Enums

Readability

```systemverilog
state = FETCH;
```

is easier to understand than

```systemverilog
state = 2'b01;
```

----------------------------------

Maintainability

If the encoding changes

Only the enum definition changes.

RTL remains unchanged.

----------------------------------

Type Safety

Different enum types cannot be mixed accidentally.

Example

datatype_t

and

state_t

represent different concepts.

Many simulators warn if one is assigned to the other.

----------------------------------

Better Debugging

Waveform viewers often display

FETCH

instead of

2'b01

making simulations much easier to read.

---

# 6. Enum Example

```systemverilog
typedef enum logic [1:0] {

    IDLE,

    FETCH,

    COMPLETE

} state_t;

state_t state;
```

Changing state

```systemverilog
state = FETCH;
```

---

# 7. Enums in Our Project

Current Enums

DFU FSM States

Datatype Definitions

Descriptor Word Numbers

Future Enums

DMA States

Scheduler States

Error Codes

Status Codes

---

# 8. Descriptor Word Enum

Instead of writing

```systemverilog
case(counter)

0:

1:

2:
```

we write

```systemverilog
case(counter)

DESC_SRCA

DESC_SRCB

DESC_DST
```

The code becomes significantly easier to read.

---

# 9. Datatype Enum

Instead of

```systemverilog
datatype = 2'b10;
```

we write

```systemverilog
datatype = DATA_FP16;
```

Immediately the purpose becomes clear.

---

# 10. Type Safety

Suppose we have

```systemverilog
datatype_t datatype;

dfu_state_t state;
```

Assigning

```systemverilog
datatype = state;
```

is likely to produce warnings from simulators or lint tools because the two
variables represent different concepts.

This reduces programming mistakes.

---

# 11. Common Beginner Mistakes

Mistake

Using numbers instead of enum names.

----------------------------------

Mistake

Thinking enums create hardware.

----------------------------------

Mistake

Creating one enum for unrelated concepts.

Separate concepts should have separate enum types.

----------------------------------

Mistake

Not specifying enum width.

Example

logic [1:0]

should match the required number of states.

---

# 12. FPGA Perspective

Enums synthesize exactly like ordinary binary values.

There is no area or timing penalty.

---

# 13. ASIC Perspective

Enums are widely used in industrial RTL because they improve readability,
maintainability and verification.

---

# 14. How We Used Enums

Descriptor Fetch Unit

FSM States

↓

IDLE

FETCH

COMPLETE

Descriptor Package

↓

Datatype Definitions

↓

Descriptor Word Numbers

Every module imports the same enum definitions from descriptor_pkg.sv.

---

# Interview Questions

1. Why were enums introduced?

2. Do enums generate hardware?

3. Difference between enum and parameter?

4. Why are enums preferred for FSMs?

5. What is type safety?

6. Why do enums improve debugging?

7. How are enums used in our accelerator?

---

# Key Takeaways

✓ Enums improve readability.

✓ Enums improve maintainability.

✓ Enums improve debugging.

✓ Enums provide type safety.

✓ Enums are compile-time constructs.

✓ Enums do not create hardware.

---

# Revision Checklist

□ I understand why enums exist.

□ I know enums do not create hardware.

□ I understand type safety.

□ I know why enums improve debugging.

□ I know why enums are used in FSMs.

---

# Personal Lesson From This Project

The biggest realization while designing the Descriptor Fetch Unit was that
hardware should not only work correctly—it should also be understandable by
other engineers.

Replacing binary values such as 2'b01 with meaningful names like FETCH made
the RTL much easier to read, review and debug.

This is one of the reasons modern RTL projects heavily rely on enums.