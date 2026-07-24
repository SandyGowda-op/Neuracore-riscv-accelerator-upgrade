# ENGINEER'S NOTEBOOK

Author: Sandy

Project:
Descriptor Driven RISC-V Matrix Accelerator

---

## Purpose

This notebook records every important lesson, design decision,
bug, trade-off, and architectural insight encountered while
developing the accelerator.

Unlike formal documentation, this notebook captures the reasoning
behind decisions so they can be revisited later during debugging,
future revisions, or interviews.

---

# Entry Format

Date:

Module:

Topic:

Problem:

Possible Solutions:

Chosen Solution:

Reason:

Lessons Learned:

Future Improvements:

Interview Notes:

---

# Entry 001

Topic:
Scratchpad Memory

Lesson:

Dual-port scratchpad memory allows simultaneous CPU and MMUL
access without arbitration.

Trade-off:

Consumes slightly more FPGA resources but greatly improves
parallelism and bandwidth.

Future:

Investigate memory banking for multiple compute engines.

---

# Entry 002

Topic:
Descriptor Driven DMA

Lesson:

Separating software instructions from execution data through
descriptors creates a scalable programming model.

Reason:

Allows future queueing, scheduling and autonomous execution.

---

# Entry 003

Topic:
Synchronous Memory

Lesson:

Choosing synchronous reads increases latency by one cycle but
matches FPGA BRAM and ASIC SRAM behaviour.

Reason:

Improves portability and timing realism.

---

(Add new entries throughout development.)