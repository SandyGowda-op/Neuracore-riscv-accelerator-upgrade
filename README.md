# NeuroCore — Descriptor-Driven RISC-V AI Accelerator

## Overview

This project explores the architecture and RTL implementation of a
descriptor-driven AI accelerator integrated with a RISC-V CPU.

The primary research objective is to investigate the architectural
trade-offs between dense and sparse matrix computation while studying
the CPU-to-accelerator interface, descriptor-based execution,
tile scheduling, data movement, scratchpad organization, and compute
datapath design.

The accelerator is being developed as a modular RTL architecture so that
dense and sparse execution can share common infrastructure while
retaining specialized scheduling and data-access behavior.

---

# Research Question

How should a RISC-V CPU expose and control an accelerator capable of
executing both dense and sparse matrix workloads, and what architectural
trade-offs arise between the two execution modes in terms of:

- computation
- memory traffic
- data movement
- scheduling
- scratchpad utilization
- useful MAC operations
- skipped operations
- execution cycles

---

# Architectural Evolution

## Phase 1 — MMIO Accelerator

The initial implementation used memory-mapped control to initiate
accelerator operations from the RISC-V processor.

This provided a simple CPU-to-accelerator integration mechanism but
required accelerator configuration to be exposed through control
registers.

---

## Phase 2 — RISC-V ISA Extension

The architecture was then extended to investigate a processor-level
interface for accelerator operations.

The objective was to allow software to express accelerator operations
through RISC-V instructions rather than treating the accelerator purely
as an external MMIO peripheral.

---

## Phase 3 — Descriptor-Driven Execution

As accelerator configuration became more complex, the architecture
was changed to a descriptor-driven model.

The accelerator instruction acts as an execution entry point/reference,
while the descriptor contains the detailed execution configuration.

A descriptor contains information such as:

- source matrix addresses
- destination address
- sparse metadata address
- matrix dimensions
- K dimension
- memory strides
- element size
- execution flags

This separates the software-visible accelerator command from the
detailed hardware execution configuration.

---

# System Architecture

RISC-V CPU
    |
    | Accelerator instruction
    v
Descriptor Subsystem
    |
    v
Scheduler Engine
    |
    +--------------------+
    |                    |
    v                    v
Dense Scheduler      Sparse Scheduler
    |                    |
    v                    v
Dense Tile           Sparse Tile
Generator            Generator
    |                    |
    +---------+----------+
              |
              v
       Transfer Engine
              |
              v
        Scratchpad
              |
              v
      Compute Controller
              |
              v
             MAC

---

# Dense Execution Path

The dense path generates regular matrix tiles from the descriptor.

The dense scheduler controls tile traversal and produces tile requests
containing matrix addresses, tile dimensions, scratchpad bank information,
and transfer metadata.

The transfer engine moves the required data into the scratchpad.

The compute controller subsequently consumes the operands and performs
the required multiply-accumulate operations.

---

# Sparse Execution Path

The sparse path extends the tile-based architecture with compressed
values and metadata.

The sparse tile generator produces:

- compressed value addresses
- metadata addresses
- destination addresses
- tile dimensions
- scratchpad bank assignments

The metadata is intended to determine which operations are useful and
which can be skipped.

The same MAC primitive is reused for both dense and sparse execution.

---

# Shared Compute Architecture

Dense and sparse execution share the arithmetic datapath.

The MAC performs:

    accumulator = accumulator + operand_A * operand_B

Dense execution enables the MAC for each valid matrix contribution.

Sparse execution uses metadata/operand availability to determine whether
a MAC operation should be performed.

This allows the research to compare dense and sparse execution without
changing the fundamental arithmetic primitive.

---

# CPU–Accelerator Interface

The CPU is intentionally separated from the internal accelerator
microarchitecture.

The CPU provides the accelerator execution command, while the
descriptor subsystem, scheduler, data movement engine, scratchpad,
and compute controller handle execution internally.

This creates a CPU-facing accelerator abstraction while allowing the
accelerator microarchitecture to evolve independently.

---

# Verification Strategy

Verification is being performed incrementally at module and subsystem
levels.

Current verification includes:

- RTL unit testbenches
- scheduler verification
- tile generator verification
- transfer engine verification
- scratchpad controller verification
- scratchpad subsystem verification
- MAC unit verification

A Python-based golden model is being used/planned as the independent
reference for matrix computation rather than using the previous RTL
MMUL implementation as the golden reference.

The objective is to eventually compare complete RTL execution against
an independent mathematical model.

---

# Research Metrics

The dense-vs-sparse study will investigate:

### Computation

- total candidate MAC operations
- useful MAC operations
- skipped operations
- arithmetic utilization

### Memory

- bytes transferred
- compressed versus dense data volume
- metadata overhead
- scratchpad traffic

### Execution

- execution cycles
- scheduling overhead
- data movement overhead
- compute cycles

### Correctness

- RTL result versus Python golden model

---

# Current Status

## Completed / Verified

- RISC-V accelerator integration exploration
- MMIO accelerator control
- ISA-extension exploration
- Descriptor-driven architecture
- Descriptor representation
- Dense tile generation
- Sparse tile generation
- Dense scheduling
- Sparse scheduling
- Transfer engine
- Scratchpad memory subsystem
- Scratchpad controller
- Common MAC primitive
- Incremental RTL verification

## In Progress

- Compute controller
- Dense compute execution
- Sparse metadata-driven execution
- End-to-end dense verification
- End-to-end sparse verification
- CPU-issued descriptor execution
- Dense versus sparse experimental evaluation

---

# Known Limitations

The current architecture is an experimental research platform rather
than a production accelerator.

Current limitations include:

- simplified backpressure handling in some interfaces
- limited DMA functionality
- no complete compute arbitration
- no FIFO-based buffering
- simplified scratchpad architecture
- initial sparse metadata organization
- compute engine still under development
- complete memory-subsystem UVM verification deferred

These limitations are intentionally tracked separately from the
architectural research objective.

---

# Research Direction

The final objective is to establish an experimentally verifiable
dense-versus-sparse accelerator architecture.

The same CPU-facing interface and common compute infrastructure will be
used to execute both workload classes.

The study will measure the architectural consequences of sparsity rather
than only comparing final numerical results.

---

# Future Work

- Complete compute controller
- Integrate dense computation
- Integrate sparse metadata processing
- Develop Python golden model
- End-to-end CPU-to-accelerator execution
- Dense/sparse performance measurements
- Memory traffic analysis
- MAC utilization analysis
- Backpressure and arbitration improvements
- Dedicated memory-subsystem verification
- UVM-based verification
- FPGA synthesis and implementation analysis
