# Chapter 01 - Memory Design Fundamentals

Version: 1.0

Project:
RV32I AI Accelerator Upgrade

Author:
Sandy

Status:
Completed

Prerequisites:
None

Related Chapters:
02 - Packed vs Unpacked
08 - Memory Inference
09 - BRAM vs Flip-Flops
10 - Memory Hierarchy

Modules Using This Concept:
- Scratchpad Memory
- Descriptor Memory
- Instruction Memory
- Data Memory

---

# Learning Objectives

After completing this chapter you should be able to

✓ Explain what digital memory is.

✓ Differentiate between memory width and depth.

✓ Calculate total memory capacity.

✓ Understand how memories are represented in RTL.

✓ Explain why memories are essential in accelerators.

✓ Design simple memories in SystemVerilog.

---

# 1. Introduction

Digital systems require the ability to store information.

Unlike combinational logic, which immediately loses its outputs when the inputs
change, memories retain information across clock cycles.

Almost every modern processor consists of more memory than logic.

Examples include

- Register Files
- Instruction Memory
- Data Memory
- Cache
- Scratchpad Memory
- Descriptor Memory
- FIFOs
- BRAM
- SRAM
- DRAM

Without memories, processors cannot execute programs.

---

# 2. What is Memory?

A memory is simply a collection of storage locations.

Each storage location stores a fixed number of bits.

Example

1024 locations

Each stores

32 bits

Visual representation

Address 0

□□□□□□□□ □□□□□□□□ □□□□□□□□ □□□□□□□□

Address 1

□□□□□□□□ □□□□□□□□ □□□□□□□□ □□□□□□□□

Address 2

□□□□□□□□ □□□□□□□□ □□□□□□□□ □□□□□□□□

...

Address 1023

□□□□□□□□ □□□□□□□□ □□□□□□□□ □□□□□□□□

Each row is called a memory word.

---

# 3. Memory Width

Memory width refers to the number of bits stored at a single address.

Example

logic [31:0] memory [0:1023];

Width = 32 bits

Meaning

Every address stores one 32-bit word.

Examples

8-bit memory

□□□□□□□□□□□□□□□□

16-bit memory

□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□

32-bit memory

□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□

64-bit memory

□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□

---

# 4. Memory Depth

Memory depth is the number of storage locations.

Example

logic [31:0] memory [0:1023];

Depth

1024

Addresses

0

↓

1023

Depth tells us

How many words

can be stored.

---

# 5. Total Memory Capacity

Capacity is calculated as

(Number of Addresses)

×

(Bits per Address)

Example

1024 locations

×

32 bits

=

32768 bits

=

4096 Bytes

=

4 KB

General Formula

Capacity(Bytes)

=

Depth × Width / 8

---

# 6. Width vs Depth

Increasing Width

Advantages

✓ Higher bandwidth

✓ Fewer accesses

Disadvantages

✗ Larger buses

✗ More routing

Increasing Depth

Advantages

✓ Store larger datasets

✓ Supports bigger matrices

Disadvantages

✗ Larger memories

✗ More address bits

---

# 7. Address Bits

How many address bits are required?

Formula

Address Bits = log₂(Depth)

Examples

Depth

256

Address Bits

8

-------------------

Depth

1024

Address Bits

10

-------------------

Depth

2048

Address Bits

11

-------------------

Depth

4096

Address Bits

12

---

# 8. Example

Question

Design a memory with

2048 locations

16 bits per location

Answer

Depth

2048

Width

16

Address Bits

11

Total Capacity

2048 × 16

=

32768 bits

=

4096 Bytes

---

# 9. Why RV32I Uses 32-bit Memories

RV32I is a 32-bit architecture.

General-purpose registers

↓

32 bits

ALU

↓

32 bits

Instruction width

↓

32 bits

Therefore

Using a 32-bit memory width simplifies

- Instruction fetch
- Data accesses
- Register transfers

It also matches the processor datapath.

---

# 10. Memory in Our Accelerator

Our accelerator currently contains

Instruction Memory

Stores program instructions.

Data Memory

Stores normal CPU data.

Scratchpad Memory

Stores matrices close to the MMUL accelerator.

Descriptor Memory

Stores DMA descriptors.

Future

Double Buffer

DMA Buffers

Descriptor Queue

---

# 11. Engineering Perspective

When designing memories, engineers rarely ask

"How much memory do I want?"

Instead they ask

"What problem am I trying to solve?"

Examples

Need faster accesses

↓

Increase width

Need larger matrices

↓

Increase depth

Need lower latency

↓

Move memory closer to compute

Need higher bandwidth

↓

Multiple memory banks

---

# 12. Common Beginner Mistakes

Mistake

Confusing width with depth.

------------------------------------

Mistake

Thinking address bits equal memory width.

------------------------------------

Mistake

Ignoring byte conversion.

------------------------------------

Mistake

Choosing memory size without workload analysis.

------------------------------------

Mistake

Assuming larger memories are always better.

---

# 13. FPGA Perspective

FPGAs contain dedicated Block RAMs (BRAMs).

Advantages

✓ Efficient

✓ Low power

✓ Large capacity

✓ Faster than distributed registers

Whenever possible, memories should infer BRAM rather than thousands of flip-flops.

---

# 14. ASIC Perspective

ASICs use SRAM macros.

Characteristics

Higher density

Lower power

Smaller area

Custom designed for the fabrication process.

Unlike FPGA BRAMs, SRAM macros are integrated during physical design.

---

# 15. How We Applied This Knowledge

During this project we designed

✓ Scratchpad Memory

Reason

Keep matrix data close to the MMUL accelerator.

✓ Descriptor Memory

Reason

Separate software-generated descriptors from DMA execution.

Both memories were intentionally designed to resemble hardware memories that can later map to FPGA BRAM or ASIC SRAM.

---

# 16. Key Takeaways

✓ Width determines bits per location.

✓ Depth determines number of locations.

✓ Capacity = Width × Depth.

✓ Memory design begins with workload analysis.

✓ Modern processors are dominated by memories.

✓ Accelerator performance often depends more on memory than arithmetic.

---

# Interview Questions

1. What is the difference between memory width and depth?

2. How do you calculate total memory capacity?

3. Why does RV32I naturally prefer 32-bit memories?

4. Why are scratchpads used instead of caches in accelerators?

5. How many address bits are required for 4096 locations?

6. What is the difference between FPGA BRAM and ASIC SRAM?

7. Why is memory hierarchy important in accelerator design?

---

# Revision Checklist

□ I can calculate memory capacity.

□ I understand width and depth.

□ I can calculate address bits.

□ I know why RV32I uses 32-bit words.

□ I understand why scratchpads improve accelerator performance.

□ I know where memories are used in our project.

---

# Notes

One of the biggest lessons learned during this project was that accelerator
performance is frequently limited by memory movement rather than computation.

A fast MMUL unit without an efficient memory subsystem will spend most of its
time waiting for data.

This realization motivated the introduction of the Scratchpad Memory and later
the Descriptor Memory architecture.
