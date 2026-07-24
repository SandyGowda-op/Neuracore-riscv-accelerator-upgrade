# Chapter 02 - Packed vs Unpacked Arrays

Version: 1.0

Project:
RV32I AI Accelerator Upgrade

Prerequisites

01 - Memory Design

Related Chapters

03 - SystemVerilog Packages

04 - Structs

Modules Using This Concept

Scratchpad

Descriptor Memory

Descriptor Package

---

# Learning Objectives

After completing this chapter you should be able to

✓ Explain packed arrays.

✓ Explain unpacked arrays.

✓ Differentiate between the two.

✓ Understand how memories are declared.

✓ Read SystemVerilog memory declarations confidently.

---

# 1. Introduction

Packed and unpacked arrays are one of the most confusing topics in
SystemVerilog.

The easiest way to remember them is

Packed

↓

One object.

Unpacked

↓

Collection of objects.

---

# 2. Packed Arrays

Packed arrays describe the size of ONE data item.

Example

logic [31:0] data;

Meaning

One variable

32 bits wide.

Visual

□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□

One continuous vector.

---

# 3. Unpacked Arrays

Unpacked arrays describe how many objects exist.

Example

logic data [0:31];

Meaning

32 independent variables.

Visual

□

□

□

□

...

Each box is independent.

---

# 4. Combining Both

Example

logic [31:0] memory [0:1023];

Packed

↓

[31:0]

Width

32 bits

Unpacked

↓

[0:1023]

Depth

1024 locations

Meaning

1024 words

Each word stores

32 bits.

---

# 5. How We Read Memory Declarations

Example

logic [63:0] mem [0:511];

Width

64 bits

Depth

512

Capacity

512 × 64 bits

---

# 6. Why Packed Comes Before

Packed arrays become a single vector.

Example

logic [15:0] value;

Compiler views this as

□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□

One object.

---

# 7. Why Unpacked Comes After

Unpacked arrays create multiple copies.

Example

logic [31:0] mem [0:7];

Visual

Address0

□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□

Address1

□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□

...

Address7

□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□

---

# 8. Where We Used This

Scratchpad

logic [31:0] memory [0:1023];

Descriptor Memory

logic [31:0] descriptor_mem [0:1279];

Instruction Memory

logic [31:0] instruction_mem [0:255];

---

# 9. Common Beginner Mistakes

Mistake

Thinking

[31:0]

means

32 addresses.

Wrong.

It means

32 bits.

--------------------

Mistake

Thinking

[0:255]

means

256 bits.

Wrong.

It means

256 storage locations.

--------------------

Mistake

Confusing width with depth.

---

# 10. Interview Questions

1. Difference between packed and unpacked arrays?

2. Which dimension represents memory width?

3. Which dimension represents memory depth?

4. Explain

logic [31:0] mem [0:255];

5. Calculate total memory capacity.

---

# Key Takeaways

✓ Packed = Width

✓ Unpacked = Depth

✓ Packed appears before variable name.

✓ Unpacked appears after variable name.

✓ Memories use both together.

---

# Revision Checklist

□ I can identify packed arrays.

□ I can identify unpacked arrays.

□ I can calculate width.

□ I can calculate depth.

□ I can explain memory declarations.