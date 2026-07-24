# ADR-010

Title

Descriptor Fetch Unit Architecture

Status

Accepted

---

# Context

The accelerator requires a mechanism for converting software-generated
descriptors into hardware-executable commands.

Several architectures were evaluated.

---

# Decision 1

Use Descriptor Memory.

Reason

Separates software from execution.

Allows future queueing.

---

# Decision 2

Use synchronous descriptor memory.

Reason

Portable to FPGA BRAM and ASIC SRAM.

---

# Decision 3

Use a 32-bit descriptor memory.

Reason

Matches RV32 software word size.

Allows software to create descriptors using ordinary stores.

---

# Decision 4

Descriptor Size

10 words

Reason

Provides room for future expansion while remaining compact.

---

# Decision 5

Three-State FSM

IDLE

FETCH

COMPLETE

Reason

Simpler than a four-state design while still supporting pipelined reads.

---

# Decision 6

Pipeline the fetch process.

Original latency

21 clocks

Optimized latency

11 clocks

Reason

Capture one word while requesting the next.

---

# Decision 7

Do not use an intermediate fetch buffer.

Reason

Descriptor format is fixed.

Words can be decoded directly.

Reduces hardware.

---

# Decision 8

Use Working Descriptor.

Reason

Allows atomic descriptor updates.

DMA never observes partially valid descriptors.

---

# Decision 9

Descriptor Output Register

Reason

Provides a stable interface.

Simplifies verification.

---

# Consequences

Reduced latency.

Reduced hardware.

Cleaner verification.

Improved scalability.
