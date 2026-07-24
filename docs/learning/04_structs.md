# Chapter 04 - SystemVerilog Structs

Version: 1.0

Project:
RV32I AI Accelerator Upgrade

Prerequisites

01 - Memory Design

02 - Packed vs Unpacked

03 - Packages

Related Chapters

05 - Enums

11 - Descriptor Architecture

Modules Using This Concept

Descriptor Package

Descriptor Fetch Unit

DMA Controller

---

# Learning Objectives

After completing this chapter you should be able to

✓ Explain why structs exist.

✓ Understand packed structs.

✓ Create your own structs.

✓ Know why structs improve RTL quality.

✓ Understand how we use descriptor_t.

---

# 1. Introduction

As RTL projects become larger, the number of related signals also increases.

Example

Instead of

srcA

srcB

dst

rows

cols

k

strideA

strideB

datatype

flags

status

Managing each signal individually quickly becomes difficult.

SystemVerilog introduces Structs to group related data together.

---

# 2. What is a Struct?

A Struct is a user-defined datatype that groups multiple variables into a
single object.

Instead of

logic [31:0] srcA;

logic [31:0] srcB;

logic [31:0] dst;

We can write

descriptor_t descriptor;

Now the descriptor contains every field.

---

# 3. Why Structs Were Introduced

Without structs

Large modules contain dozens of independent signals.

Problems

Poor readability

Large port lists

Higher maintenance

Greater chance of mistakes

Structs solve these problems.

---

# 4. Basic Example

```systemverilog
typedef struct packed {

    logic [31:0] x;

    logic [31:0] y;

} point_t;
```

Creating a variable

```systemverilog
point_t point;
```

Accessing fields

```systemverilog
point.x = 10;

point.y = 20;
```

---

# 5. Packed Struct

Most RTL designs use

packed structs.

Example

```systemverilog
typedef struct packed {

logic [31:0] srcA;

logic [31:0] srcB;

logic [31:0] dst;

} descriptor_t;
```

Packed means

The compiler treats the entire structure as one continuous vector.

Example

□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□

96 bits

This makes the structure compatible with buses and memories.

---

# 6. Why Packed Structs?

Packed structs provide

✓ Better readability

✓ Bus compatibility

✓ Easy copying

✓ Cleaner RTL

Example

Instead of

descriptor[95:64]

we write

descriptor.srcA

This is much easier to understand.

---

# 7. Why We Used Structs

Our descriptor contains

Source Address

Destination Address

Matrix Size

Stride

Datatype

Flags

Status

These are all logically related.

Grouping them into one object makes the design much cleaner.

---

# 8. Descriptor Structure

Our project defines

descriptor_t

inside

descriptor_pkg.sv

Every module uses

descriptor_t

instead of defining dozens of individual signals.

This keeps every module consistent.

---

# 9. Advantages

Readability

Instead of

logic [31:0] srcA;

logic [31:0] srcB;

logic [31:0] dst;

We simply use

descriptor_t current_desc;

---------------------------------

Maintainability

Adding a new field requires changing only the struct.

---------------------------------

Reusability

The same datatype is used across multiple modules.

---------------------------------

Verification

Assertions become easier to write.

Example

current_desc.rows

instead of

descriptor[143:128]

---

# 10. How We Used Structs

Descriptor Fetch Unit

Working Descriptor

↓

Descriptor Output

DMA Controller

↓

Reads descriptor fields

No module needs to know the internal bit positions.

Only field names.

---

# 11. Common Beginner Mistakes

Mistake

Using individual signals for everything.

---------------------------------

Mistake

Using bit positions directly.

Example

descriptor[127:96]

instead of

descriptor.dst

---------------------------------

Mistake

Thinking structs create hardware.

Structs disappear during compilation.

Only the signals remain.

---

# 12. FPGA Perspective

Packed structs synthesize exactly like ordinary vectors.

They do not increase area.

They simply improve readability.

---

# 13. ASIC Perspective

ASIC designers also use packed structs extensively.

They simplify RTL reviews and reduce maintenance effort.

---

# 14. How We Applied This

We intentionally designed

descriptor_t

to become the common language used between

Descriptor Memory

Descriptor Fetch Unit

DMA Controller

Future Scheduler

Every module understands the same descriptor format.

---

# Interview Questions

1. Why were structs introduced?

2. Difference between struct and packed struct?

3. Do structs create hardware?

4. Why are packed structs preferred in RTL?

5. Why are structs useful for verification?

6. How do structs improve maintainability?

---

# Key Takeaways

✓ Structs group related signals.

✓ Packed structs become one continuous vector.

✓ Structs improve readability.

✓ Structs reduce duplicated code.

✓ Structs are compile-time constructs.

✓ Structs do not generate hardware.

---

# Revision Checklist

□ I understand why structs exist.

□ I know what packed means.

□ I can create my own struct.

□ I understand descriptor_t.

□ I know why structs improve RTL quality.

---

# Personal Lesson From This Project

One of the biggest improvements in our architecture occurred when we replaced
individual descriptor signals with descriptor_t.

Instead of thinking about

"ten independent words"

we began thinking about

"one descriptor."

This change made the architecture significantly cleaner and easier to reason
about.