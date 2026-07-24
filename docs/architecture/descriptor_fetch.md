# Descriptor Fetch Unit (DFU)

Version: 1.0

Status:
Architecture Approved

Author:
Sandy

---

# 1. Purpose

The Descriptor Fetch Unit (DFU) is responsible for retrieving a descriptor from
Descriptor Memory and reconstructing it into a structured format that can be
consumed by the DMA Controller.

The DFU acts as the bridge between software-generated descriptors and hardware
execution.

Software creates descriptors.

Descriptor Memory stores them.

The DFU reconstructs them.

The DMA executes them.

This separation allows software and hardware to remain loosely coupled.

---

# 2. Responsibilities

The DFU SHALL

✓ Receive a descriptor index.

✓ Read descriptor memory.

✓ Fetch all descriptor words.

✓ Decode descriptor fields.

✓ Assemble a complete descriptor.

✓ Atomically publish the descriptor.

✓ Notify the DMA Controller.

The DFU SHALL NOT

✗ Execute DMA transfers.

✗ Read matrix data.

✗ Control MMUL.

✗ Write Scratchpad.

✗ Perform address calculations.

Those responsibilities belong to later pipeline stages.

---

# 3. Descriptor Fetch Pipeline

CPU

↓

Descriptor Memory

↓

Descriptor Fetch Unit

↓

DMA Controller

↓

Scratchpad

↓

MMUL

↓

Writeback

---

# 4. Descriptor Format

Each descriptor contains

Word 0
Source A Address

Word 1
Source B Address

Word 2
Destination Address

Word 3
Rows + Columns

Word 4
K + Stride A

Word 5
Stride B + Stride C

Word 6
Datatype

Word 7
Flags

Word 8
Status

Word 9
Reserved

Total Size

10 words

320 bits

---

# 5. Internal Registers

The DFU contains

Current FSM State

Descriptor Index Register

Word Counter

Working Descriptor

Descriptor Output Register

Busy Register

Every register above stores information across clock cycles and therefore is
implemented using always_ff.

---

# 6. Working Descriptor

A temporary descriptor is filled one word at a time while data is fetched from
Descriptor Memory.

The DMA Controller cannot observe this descriptor.

Purpose

Prevent partially updated descriptors.

Improve verification.

Allow atomic descriptor publication.

---

# 7. Descriptor Output Register

Once the final descriptor word has been received, the Working Descriptor is
copied into Descriptor Output Register.

The DMA Controller only sees this register.

This guarantees descriptor consistency.

---

# 8. Memory Interface

Descriptor Memory

Width

32 bits

Latency

1 clock cycle

Read Style

Synchronous

Reason

Matches FPGA BRAM and ASIC SRAM.

---

# 9. Fetch Strategy

The DFU uses a pipelined fetch strategy.

Cycle 0

Issue Read Word0

Cycle 1

Capture Word0
Issue Read Word1

Cycle 2

Capture Word1
Issue Read Word2

...

Cycle 10

Capture Word9

Cycle 11

Descriptor Commit

Latency

11 clocks

---

# 10. Finite State Machine

States

IDLE

FETCH

COMPLETE

Purpose

IDLE

Wait for start signal.

FETCH

Capture current descriptor word while issuing the next read.

COMPLETE

Commit descriptor and notify DMA.

---

# 11. Interfaces

Inputs

clk

rst

start

descriptor_index

mem_rdata

Outputs

mem_re

mem_addr

busy

done

descriptor_out

---

# 12. Verification Plan

Directed Tests

Descriptor Fetch

Descriptor Commit

Last Word

Invalid Descriptor Index

Random Tests

Random descriptor values

Assertions

No partial descriptor publication

Busy protocol

Done protocol

Formal Verification

State reachability

Counter bounds

No illegal transitions

Atomic commit

---

# 13. Future Improvements

Burst Fetch

Descriptor Cache

Scatter-Gather DMA

Multiple Outstanding Descriptors

Prefetch Queue

Multi-channel DMA
