# CPU Interview Questions
## RISC-V Processor Integrated with an AI Accelerator

**Document ID:** INT-CPU-001

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Interview Preparation Strategy
3. Beginner Questions
4. Intermediate Questions
5. Advanced Questions
6. Project-Specific Questions
7. Debugging Questions
8. Design Questions
9. Optimization Questions
10. HR + Technical Mix Questions
11. Whiteboard Questions
12. Common Mistakes
13. Revision Sheet

---

# 1. Purpose

This document contains interview questions based on the RISC-V CPU used in this project.

Unlike generic interview questions, these questions are centered around the architecture implemented in this project:

- 5-stage pipelined RV32I processor
- Memory-Mapped AI Accelerator
- MMIO Interface
- Hazard Handling
- Pipeline Control
- FPGA Implementation

These questions are representative of those commonly asked for RTL Design, Design Verification, FPGA Design, and ASIC Front-End roles.

---

# 2. Interview Preparation Strategy

When answering CPU questions, always follow this structure.

**Step 1**

Explain the concept.

**Step 2**

Explain why the concept exists.

**Step 3**

Explain how it is implemented.

**Step 4**

Relate it to your project.

Example:

Question:

"What is forwarding?"

Bad Answer

"It avoids hazards."

Good Answer

"Forwarding is a hardware mechanism used to resolve Read-After-Write (RAW) hazards without introducing pipeline stalls. Instead of waiting until a value is written back to the register file, the ALU result is forwarded directly from later pipeline stages to dependent instructions. In my project, forwarding logic was implemented in the Execute stage to reduce unnecessary stalls while maintaining correct instruction execution."

Interviewers almost always prefer answers connected to your own implementation.

---

# 3. Beginner Questions

---

## Q1. What is RISC-V?

### Answer

RISC-V is an open-standard Reduced Instruction Set Computer (RISC) Instruction Set Architecture (ISA).

It defines:

- instruction formats
- register organization
- memory operations
- control flow instructions

It does **not** define the internal hardware implementation.

Different processors can implement the same ISA while having different pipeline depths, cache organizations, and performance characteristics.

---

### Follow-up

Why is RISC-V becoming popular?

Expected points:

- Open source ISA
- No licensing fees
- Modular extensions
- Research friendly
- Industry adoption
- Easy customization

---

## Q2. What ISA did your processor implement?

### Answer

Our processor implements the RV32I base integer instruction set.

Supported instruction classes include:

- Arithmetic
- Logical
- Load
- Store
- Branch
- Jump
- Immediate operations

The AI accelerator is accessed through Memory-Mapped I/O (MMIO) rather than introducing custom RISC-V instructions.

---

## Q3. Why did you use a pipelined processor?

### Answer

Pipelining increases instruction throughput by overlapping instruction execution.

Instead of completing one instruction before starting the next, multiple instructions execute simultaneously in different stages.

This improves overall performance without significantly increasing clock frequency.

---

### Follow-up

Does pipelining reduce latency?

Answer:

No.

Pipelining primarily improves **throughput**, not the latency of an individual instruction.

---

## Q4. Explain the five pipeline stages.

### Answer

Our processor uses a classic five-stage pipeline.

1. IF (Instruction Fetch)

Fetch instruction from instruction memory.

---

2. ID (Instruction Decode)

Decode opcode.

Read source registers.

Generate control signals.

---

3. EX (Execute)

Perform:

- ALU operations
- Address calculation
- Branch comparison

---

4. MEM (Memory Access)

Read or write data memory.

Access MMIO registers when required.

---

5. WB (Write Back)

Write computation results back to the register file.

---

### Follow-up

Which stage interacts with the AI accelerator?

Answer:

The Memory stage.

The accelerator is memory mapped, so accesses occur through standard load/store operations.

---

## Q5. What is the Program Counter?

### Answer

The Program Counter (PC) stores the address of the next instruction to execute.

Normally:

PC = PC + 4

For branches and jumps:

PC is updated with the target address.

---

## Q6. What is the Register File?

### Answer

The Register File contains the processor's general-purpose registers.

RV32I provides:

- 32 registers
- 32 bits each

Important registers include:

x0

Always zero.

x1

Return address.

x2

Stack pointer.

The register file supports simultaneous reads and writes to sustain pipelined execution.

---

## Q7. Why is x0 always zero?

### Answer

Keeping x0 permanently zero simplifies hardware and instruction encoding.

Common operations such as:

- move
- clear
- comparisons

can be implemented efficiently without requiring dedicated instructions.

---

## Q8. Explain ALU operations.

### Answer

The Arithmetic Logic Unit performs:

- Addition
- Subtraction
- AND
- OR
- XOR
- Shift operations
- Comparisons

The ALU is active during the Execute stage.

---

# 4. Intermediate Questions

---

## Q9. What are pipeline hazards?

### Answer

Pipeline hazards prevent the next instruction from executing normally.

There are three categories.

---

### Data Hazard

Occurs when an instruction depends on the result of a previous instruction.

Example

```assembly
ADD x5, x1, x2
SUB x6, x5, x3
```

The SUB instruction requires the updated value of x5 before it has been written back.

---

### Control Hazard

Occurs after branch and jump instructions.

The processor may fetch incorrect instructions before the branch outcome is known.

---

### Structural Hazard

Occurs when two instructions require the same hardware resource simultaneously.

Our design minimizes structural hazards by using separate instruction and data memories.

---

## Q10. What is forwarding?

### Answer

Forwarding (also called bypassing) sends computed results directly from later pipeline stages to earlier stages without waiting for write-back.

This reduces stalls caused by RAW hazards and improves throughput.

---

## Q11. When is forwarding insufficient?

### Answer

Forwarding cannot resolve all hazards.

For example:

```assembly
LW x5, 0(x1)
ADD x6, x5, x2
```

The loaded value is not available immediately after the Execute stage.

The dependent ADD instruction must stall until the data becomes available.

---

## Q12. What is stalling?

### Answer

Stalling inserts one or more bubble cycles into the pipeline to preserve correctness when hazards cannot be resolved through forwarding.

---

## Q13. What is flushing?

### Answer

Flushing removes incorrectly fetched instructions from the pipeline.

This commonly occurs after branches or jumps when speculative instructions should not execute.

---

## Q14. What is a bubble?

### Answer

A bubble is an intentionally inserted idle pipeline stage.

It performs no useful work but preserves correct instruction sequencing.

---

## Q15. What is hazard detection?

### Answer

Hazard detection hardware monitors pipeline stages for dependencies.

When a hazard is detected, the control unit decides whether to:

- Forward data
- Stall the pipeline
- Flush instructions

---

# 5. Advanced Questions

---

## Q16. Why did you use MMIO instead of custom instructions?

### Answer

Using MMIO allowed accelerator integration without modifying the RV32I ISA.

Advantages include:

- Standard software interface
- Simpler CPU design
- Easier debugging
- No changes to instruction decoding
- Better portability

The CPU controls the accelerator by reading and writing predefined memory-mapped registers.

---

## Q17. Explain how the CPU starts the AI accelerator.

### Answer

The CPU writes configuration information—such as descriptor addresses or control values—to MMIO registers.

A write to the accelerator's control register initiates execution.

The accelerator performs its operations independently while the CPU monitors status registers for completion.

---

## Q18. How does the CPU know computation is complete?

### Answer

The CPU polls status registers exposed through MMIO.

Typical status bits include:

- Busy
- Done
- Error

When the Done bit is asserted and Busy is cleared, the CPU knows the accelerator has finished execution.

---

## Q19. Why didn't the CPU perform matrix multiplication itself?

### Answer

General-purpose processors execute matrix multiplication sequentially using ALU operations.

The dedicated AI accelerator performs many multiply-accumulate operations in parallel using a systolic array, resulting in significantly higher throughput and better hardware utilization.

---

## Q20. Explain CPU and accelerator interaction.

### Answer

The interaction sequence is:

```text
CPU

↓

Configure MMIO Registers

↓

Start Accelerator

↓

Accelerator Reads Memory (DMA)

↓

Matrix Computation

↓

Activation Function

↓

Write-back

↓

Status Updated

↓

CPU Reads Completion Status
```

The CPU acts as the controller, while the accelerator performs the computationally intensive tasks.

---

# Continued in Part 2...

This document is intentionally split due to its length.

The next section includes:

- Debugging Questions
- Whiteboard Questions
- Design Questions
- Optimization Questions
- Senior-Level Follow-up Questions
- HR + Technical Questions
- Common Interview Mistakes
- Rapid Revision Sheet

---

**END OF PART 1**

# CPU Interview Questions
## RISC-V Processor Integrated with an AI Accelerator

---

# 6. Project-Specific Questions

These are the questions most likely to be asked after you explain your project.

---

## Q21. Tell me about your AI Accelerator project.

### Answer

My project involved integrating a dedicated AI Accelerator with a 5-stage pipelined RV32I RISC-V processor.

The accelerator is connected through a Memory-Mapped I/O (MMIO) interface rather than custom instructions. The CPU configures the accelerator by writing control information to MMIO registers. Internally, the accelerator consists of:

- Descriptor Fetch Unit
- Scheduler
- DMA Engine
- Scratchpad Memory
- Matrix Engine (Systolic Array)
- ReLU Activation Unit

The DMA transfers operands from main memory into the scratchpad. The Matrix Engine performs matrix multiplication, the Activation Unit applies ReLU, and the DMA writes the results back to memory. The CPU monitors Busy and Done status through MMIO registers.

This approach offloads computationally intensive matrix operations from the CPU, improving throughput and enabling efficient AI inference.

---

### Follow-up

What was your contribution?

Expected Answer

Mention your actual work, for example:

- Integrated the accelerator with the RISC-V pipeline
- Designed MMIO interface
- Modified pipeline control
- Implemented RTL modules
- Wrote Cocotb verification
- Created Python Golden Model
- Performed FPGA synthesis and implementation
- Debugged pipeline hazards
- Verified functionality using simulations

Always be specific and avoid claiming work you did not perform.

---

## Q22. Why didn't you add a custom RISC-V instruction?

### Answer

Using MMIO provided several advantages:

- No modifications to the instruction decoder.
- Software remains compatible with the standard RV32I ISA.
- Easier debugging using ordinary load/store instructions.
- Simpler compiler and assembler support.
- Better portability.

The accelerator behaves like a hardware peripheral while remaining tightly integrated with the processor.

---

## Q23. Explain the complete execution flow.

### Answer

The execution sequence is:

```text
Software

↓

Write Descriptor Address

↓

Write Control Register

↓

Descriptor Fetch

↓

Scheduler

↓

DMA Read

↓

Scratchpad Memory

↓

Matrix Engine

↓

Activation Unit

↓

DMA Write

↓

Done Interrupt / Status Bit

↓

CPU Reads Result
```

The CPU mainly performs control while computation is delegated to dedicated hardware.

---

## Q24. Why use descriptors?

### Answer

Descriptors separate software from hardware execution details.

Instead of programming every DMA transfer manually, software prepares a descriptor containing:

- Source addresses
- Destination address
- Matrix dimensions
- Activation selection
- Control information

The accelerator autonomously executes the descriptor.

Advantages:

- Reduced CPU overhead
- Better scalability
- Easy batching
- Supports future scheduling enhancements

---

## Q25. Explain your MMIO interface.

### Answer

The MMIO interface exposes accelerator registers inside the processor's address space.

Typical registers include:

- Control Register
- Status Register
- Descriptor Address Register
- Error Register

The CPU interacts with these registers using normal load and store instructions.

---

## Q26. Why use DMA?

### Answer

Without DMA:

```text
Memory

↓

CPU

↓

Accelerator
```

The CPU becomes a bottleneck.

With DMA:

```text
Memory

↓

DMA

↓

Scratchpad
```

The CPU is free to execute other tasks while data movement occurs independently.

DMA significantly reduces processor involvement and improves overall performance.

---

## Q27. Explain your matrix engine.

### Answer

The Matrix Engine is a systolic array composed of multiple Processing Elements (PEs).

Each PE performs:

```text
Multiply

↓

Accumulate

↓

Forward Data
```

Neighboring PEs communicate locally, enabling high-throughput matrix multiplication with efficient data reuse.

---

## Q28. Why is a systolic array suitable for AI?

### Answer

Neural network inference is dominated by matrix multiplication.

A systolic array provides:

- High parallelism
- Local communication
- High MAC utilization
- Efficient operand reuse
- Regular hardware structure
- Excellent scalability

These characteristics make it well suited for deep learning workloads.

---

# 7. Debugging Questions

---

## Q29. Tell me about a difficult bug you encountered.

### Model Answer

During integration, the pipeline occasionally stopped progressing after starting the accelerator.

The debugging process involved:

1. Reproducing the issue consistently.
2. Inspecting simulation waveforms.
3. Checking pipeline control signals.
4. Identifying incorrect control sequencing.
5. Correcting the control logic.
6. Running regression tests to ensure no new issues were introduced.

This reinforced the importance of systematic debugging rather than making isolated code changes.

---

## Q30. How do you debug RTL?

### Expected Answer

A structured debugging approach is:

1. Reproduce the bug.
2. Minimize the failing testcase.
3. Review simulation logs.
4. Inspect waveforms.
5. Verify assertions.
6. Compare against the reference model.
7. Isolate the faulty module.
8. Fix the RTL.
9. Execute regression testing.

---

## Q31. Why are waveforms important?

### Answer

Waveforms provide a cycle-by-cycle view of hardware behavior.

They allow engineers to observe:

- Signal transitions
- FSM states
- Register updates
- Handshake protocols
- Timing relationships
- Pipeline movement

Waveforms are often the primary tool for diagnosing RTL issues.

---

# 8. Design Questions

---

## Q32. Why choose a 5-stage pipeline?

### Answer

A 5-stage pipeline offers a good balance between:

- Performance
- Complexity
- Area
- Verification effort

It is widely used in educational and commercial processors because it provides meaningful throughput improvements without the complexity of deeper pipelines.

---

## Q33. If you redesigned the CPU, what would you improve?

### Good Answer

Possible enhancements include:

- Branch prediction
- Instruction cache
- Data cache
- Out-of-order execution
- Superscalar issue
- Hardware prefetching
- Interrupt support
- Better hazard handling

Then explain that these improvements increase performance but also increase design complexity.

---

## Q34. Why separate instruction and data memory?

### Answer

Using separate instruction and data memories eliminates structural hazards where instruction fetches and data accesses compete for the same memory resource.

This allows simultaneous instruction fetch and data access, improving pipeline efficiency.

---

# 9. Optimization Questions

---

## Q35. What limits CPU performance?

### Answer

Performance may be limited by:

- Pipeline stalls
- Branch penalties
- Memory latency
- Cache misses (if caches are present)
- Data hazards
- Control hazards

Understanding these bottlenecks is essential when designing high-performance processors.

---

## Q36. Why is hardware acceleration faster than software?

### Answer

Dedicated hardware can execute many operations concurrently.

For matrix multiplication, the CPU performs operations sequentially, whereas the accelerator performs numerous multiply-accumulate operations in parallel, greatly increasing throughput.

---

# 10. HR + Technical Mix Questions

---

## Q37. What was the biggest challenge in this project?

### Good Answer

One of the biggest challenges was integrating multiple independently functioning modules into a cohesive system while maintaining correct communication and synchronization. Ensuring that the CPU, DMA engine, scheduler, and accelerator operated together correctly required careful debugging, verification, and regression testing.

---

## Q38. What did this project teach you?

### Expected Points

- RTL Design
- Pipeline Architecture
- Hardware Verification
- FPGA Development
- System Integration
- Debugging Methodology
- Engineering Documentation
- Design Trade-offs

---

# 11. Whiteboard Questions

Typical interview whiteboard exercises include:

### Draw a 5-stage pipeline.

---

### Draw forwarding paths.

---

### Draw a hazard detection unit.

---

### Explain a load-use hazard.

---

### Draw the MMIO interface.

---

### Explain the CPU-to-accelerator data flow.

---

### Draw the DMA architecture.

---

### Explain descriptor execution.

---

### Sketch the systolic array.

Interviewers often focus on your ability to communicate architecture clearly rather than artistic quality.

---

# 12. Common Mistakes

Avoid the following during interviews:

❌ Saying "I memorized this."

❌ Claiming responsibility for work you did not perform.

❌ Giving one-line answers.

❌ Ignoring design trade-offs.

❌ Saying "I don't know" without attempting an informed discussion.

❌ Describing only functionality instead of explaining design decisions.

Instead:

- Explain the concept.
- Explain why it exists.
- Explain your implementation.
- Discuss trade-offs.
- Relate it back to your project.

---

# 13. Rapid Revision Sheet

Review these topics before interviews:

- RV32I ISA
- Five-stage pipeline
- Register file
- ALU
- Program Counter
- Hazard detection
- Forwarding
- Pipeline stalls
- Pipeline flushing
- MMIO
- DMA
- Scratchpad memory
- Descriptor-based execution
- Matrix multiplication
- Systolic arrays
- ReLU activation
- Cocotb verification
- SystemVerilog Assertions
- FPGA implementation
- RTL debugging
- Regression testing
- Design trade-offs

If you can confidently explain each topic, relate it to your project, and discuss why specific architectural decisions were made, you will be well prepared for interviews involving this AI accelerator.

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Initial CPU interview guide for the RISC-V AI Accelerator project. |

---

**END OF FILE**