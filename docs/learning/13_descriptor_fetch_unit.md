# Chapter 13: Descriptor Fetch Unit (DFU)

> **Document:** Learning Series
>
> **Chapter:** 13
>
> **Module:** Descriptor Fetch Unit (DFU)
>
> **Prerequisites:**
>
> - 01 Memory Design
> - 02 Packed vs Unpacked Arrays
> - 03 SystemVerilog Packages
> - 04 Structs
> - 05 Enums
> - 06 always_ff vs always_comb
> - 07 Blocking vs Non-Blocking Assignments
> - 08 Dual-Port BRAM
> - 09 Three Process FSM
> - 10 Controller Datapath
> - 11 Descriptor Based Architecture
> - 12 Memory Mapped IO

---

# Table of Contents

1. Introduction
2. What is the Descriptor Fetch Unit?
3. Why the DFU Exists
4. Position of the DFU in the Accelerator
5. Overall Data Flow
6. DFU Inputs and Outputs
7. Internal Building Blocks
8. Control Path
9. Datapath
10. Descriptor Fetch Sequence
11. Descriptor Memory Interface
12. Descriptor Capture
13. Busy and Done Signals
14. State Machine
15. Hardware Timing
16. Our RTL Implementation
17. Design Decisions
18. Verification Strategy
19. Common Design Mistakes
20. Industry Perspective
21. Interview Questions
22. Summary

---

# 1. Introduction

Every modern accelerator requires a mechanism to obtain work from software.

The software world and the hardware world operate at very different speeds. Software executes instructions one after another, while hardware executes operations concurrently. A bridge is therefore required between them.

That bridge is the **Descriptor Fetch Unit (DFU).**

The DFU is responsible for retrieving descriptors from memory and presenting them to the rest of the accelerator in a clean, synchronized, and deterministic manner.

Without a DFU, every downstream hardware block would need to understand:

- Memory protocols
- Descriptor formats
- Address generation
- Read timing
- Synchronization
- Error handling

This would unnecessarily duplicate logic across multiple hardware blocks.

Instead, the DFU centralizes all descriptor handling.

---

# 2. What is the Descriptor Fetch Unit?

The Descriptor Fetch Unit is a dedicated hardware controller responsible for reading descriptor information from memory.

Conceptually, it performs only one task:

> **Fetch one descriptor from memory and make it available to the accelerator.**

Although this sounds simple, internally the DFU performs several coordinated operations:

- Accepts a fetch request
- Generates the descriptor memory address
- Initiates a memory read
- Waits for valid memory data
- Captures the descriptor
- Signals completion
- Returns to an idle state

The DFU therefore behaves as a specialized controller dedicated to descriptor retrieval.

---

# 3. Why the DFU Exists

Imagine an accelerator without a Descriptor Fetch Unit.

The Scheduler would need to:

- Generate memory addresses
- Interface with memory
- Wait for read latency
- Capture descriptor data
- Decode descriptor fields

The DMA engine would require similar logic.

Future compute engines would require similar logic.

The result would be:

- duplicated RTL
- larger area
- more verification effort
- inconsistent behavior

Instead, one dedicated module performs descriptor fetching for everyone.

Advantages include:

- modularity
- easier verification
- cleaner interfaces
- simplified downstream hardware
- improved scalability

This follows a fundamental engineering principle:

> **One module should perform one responsibility exceptionally well.**

---

# 4. Position of the DFU in Our Accelerator

The Descriptor Fetch Unit is the first active hardware block after descriptor memory.

Overall architecture:

```text
                    SOFTWARE

                       │

                       ▼

              Creates Descriptor

                       │

                       ▼

             Descriptor Memory

                       │

                       ▼

         Descriptor Fetch Unit (DFU)

                       │

                       ▼

               Future Scheduler

                       │

                       ▼

                Future DMA Engine

                       │

                       ▼

             Future Compute Engine

                       │

                       ▼

                Completion Status
```

The DFU does not execute commands.

The DFU does not move data.

The DFU does not perform matrix multiplication.

Its only responsibility is obtaining descriptors from memory.

---

# 5. Overall Data Flow

The descriptor fetch process begins with software.

Step 1

Software constructs a descriptor.

Example:

```text
Descriptor

Source Address

Destination Address

Operation

Length

Flags
```

Step 2

Software writes the descriptor into descriptor memory.

Step 3

Software requests the DFU to fetch a descriptor.

Step 4

The DFU calculates the memory address.

Step 5

The descriptor memory returns descriptor data.

Step 6

The DFU stores the descriptor internally.

Step 7

The descriptor becomes available to downstream hardware.

---

# 6. DFU Inputs

Although implementations vary, our DFU receives several important inputs.

## Clock

The DFU operates synchronously with the system clock.

Every state transition occurs on the active clock edge.

---

## Reset

Reset initializes every internal register.

During reset:

- FSM returns to IDLE
- busy becomes zero
- done becomes zero
- descriptor registers clear
- read requests deassert

This guarantees deterministic startup.

---

## Fetch Request

This signal instructs the DFU to begin fetching a descriptor.

Without this signal, the DFU remains idle.

---

## Descriptor Address

Indicates which descriptor should be fetched.

Future versions may use:

- Descriptor Index
- Queue Pointer
- Ring Pointer

Current implementation uses a single descriptor address.

---

## Memory Data

The descriptor memory returns descriptor information through the memory data bus.

The DFU captures this value during the CAPTURE state.

---

# 7. DFU Outputs

The DFU produces several outputs.

## Busy

Indicates that the DFU is actively fetching a descriptor.

Busy becomes high immediately after a fetch request.

Busy returns low after completion.

---

## Done

Done indicates that a descriptor has been successfully captured.

Downstream hardware uses this signal to begin processing.

---

## Descriptor Output

The fetched descriptor is presented to downstream hardware.

Instead of reading memory again, later modules simply read this descriptor output.

---

## Memory Read Enable

The DFU asserts a read request to descriptor memory.

This causes descriptor memory to place descriptor data onto the data bus.

---

## Memory Address

The DFU drives the descriptor address onto the memory address bus.

This identifies which descriptor should be returned.

---

# 8. Internal Building Blocks

Although the DFU appears simple externally, internally it consists of several coordinated hardware components.

```text
                +----------------------+
                |      Controller      |
                |      (FSM)           |
                +----------+-----------+
                           |
                           |
                           ▼
                +----------------------+
                |      Datapath        |
                +----------+-----------+
                           |
                           ▼
                Descriptor Registers
                           |
                           ▼
                Descriptor Output
```

The controller determines **when** actions occur.

The datapath determines **what** data moves.

Separating these two responsibilities improves readability, maintainability, and verification.

---

# 9. Controller Responsibilities

The controller performs:

- state transitions
- memory read requests
- busy generation
- done generation
- descriptor capture enable

Notice that the controller does **not** store descriptor data.

Its responsibility is purely decision making.

This follows the Controller-Datapath design methodology introduced in Chapter 10.

---

# 10. Datapath Responsibilities

The datapath is responsible for storing and moving descriptor information.

Unlike the controller, the datapath contains the registers that actually hold descriptor fields.

Typical datapath components include:

- Descriptor Register
- Address Register
- Internal Buffers
- Output Register
- Multiplexers

Conceptually,

```text
Memory

↓

Descriptor Bus

↓

Descriptor Register

↓

Output Interface
```

The datapath never decides **when** information should be stored.

Instead, it waits for enable signals generated by the controller.

This separation significantly simplifies verification because the controller and datapath can be analyzed independently.

---

# 11. Descriptor Fetch Sequence

The Descriptor Fetch Unit follows a deterministic sequence every time a descriptor is requested.

The sequence is illustrated below.

```text
Fetch Request

↓

Generate Address

↓

Issue Memory Read

↓

Wait for Memory

↓

Capture Descriptor

↓

Assert Done

↓

Return to Idle
```

Each step corresponds to one or more finite state machine states.

A deterministic fetch sequence ensures that every descriptor is processed identically, making the hardware easier to verify.

---

# 12. State-by-State Operation

## State 1 — IDLE

The DFU remains inactive while waiting for a fetch request.

Characteristics:

- Busy = 0
- Done = 0
- No memory transaction
- Descriptor registers unchanged

The DFU consumes minimal logic activity in this state.

---

## State 2 — ISSUE_READ

Once a fetch request arrives:

The controller

- drives the descriptor address
- asserts memory read enable
- starts the descriptor read transaction

Outputs during this state:

```text
Memory Read Enable = 1

Busy = 1

Done = 0
```

---

## State 3 — CAPTURE

After descriptor memory returns valid data,

the controller enables the datapath register.

The datapath performs

```text
Descriptor Register

<=

Memory Data
```

This is the only state in which descriptor registers change.

---

## State 4 — COMPLETE

The descriptor is now available.

Controller actions:

- Busy ← 0
- Done ← 1

Downstream modules detect the done signal and begin processing.

After one clock cycle,

the FSM returns to IDLE.

---

# 13. Descriptor Memory Interface

The DFU communicates with descriptor memory through a simple interface.

Typical signals include:

Inputs

```text
memory_data

memory_ready

clock

reset
```

Outputs

```text
memory_address

memory_read_enable
```

A read transaction proceeds as follows:

```text
DFU

↓

Address

↓

Memory

↓

Descriptor Data

↓

DFU Register
```

Because the memory interface is isolated inside the DFU, downstream hardware never interacts directly with descriptor memory.

---

# 14. Descriptor Capture

Capturing a descriptor is one of the most critical operations performed by the DFU.

The descriptor must only be stored when:

- memory output is valid
- correct address has been accessed
- FSM reaches CAPTURE

Capturing too early results in invalid data.

Capturing too late introduces unnecessary latency.

Therefore, the capture enable signal is generated exclusively by the controller.

Conceptually,

```systemverilog
if(capture_enable)

descriptor_reg <= memory_data;
```

Although the implementation details may vary, this principle remains universal.

---

# 15. Busy Signal

Busy indicates whether the DFU is currently servicing a descriptor request.

Typical behavior:

```text
Fetch Request

↓

Busy = 1

↓

Memory Read

↓

Capture

↓

Busy = 0
```

Busy prevents additional requests from entering the DFU before the current descriptor has completed.

Without Busy,

multiple descriptor requests could overlap unexpectedly, leading to race conditions.

---

# 16. Done Signal

Done indicates successful completion of descriptor retrieval.

Unlike Busy,

Done is usually asserted briefly.

Typical timing:

```text
IDLE

↓

ISSUE_READ

↓

CAPTURE

↓

Done = 1

↓

IDLE
```

Downstream hardware often detects Done using rising-edge logic.

---

# 17. Hardware Timing

The following simplified timing diagram illustrates DFU operation.

```text
Clock

_|‾|_|‾|_|‾|_|‾|_

Fetch

_____|‾‾‾|

Busy

_____|‾‾‾‾‾‾|

Memory Read

_______|‾|

Memory Data

___________VALID____

Capture

_____________|‾|

Done

_________________|‾|
```

Notice that Busy remains asserted throughout the fetch process, while Done appears only after the descriptor has been successfully captured.

---

# 18. Finite State Machine

Our implementation uses a Four-State Finite State Machine.

```text
            +---------+
            |  IDLE   |
            +----+----+
                 |
                 |
                 ▼
        +----------------+
        | ISSUE_READ     |
        +--------+-------+
                 |
                 ▼
        +----------------+
        |   CAPTURE      |
        +--------+-------+
                 |
                 ▼
        +----------------+
        |  COMPLETE      |
        +--------+-------+
                 |
                 ▼
            +---------+
            |  IDLE   |
            +---------+
```

Every descriptor passes through these states in exactly the same order.

This deterministic behavior greatly simplifies simulation and assertion-based verification.

---

# 19. Why We Used a Four-State FSM

A common question is:

Why not combine multiple operations into fewer states?

The answer is timing.

Separating memory read, capture, and completion provides:

- cleaner RTL
- easier debugging
- easier assertions
- predictable timing
- better scalability

As future features such as wait states or descriptor chaining are introduced, additional states can be inserted without redesigning the entire controller.

---

# 20. Design Philosophy

The DFU follows several important hardware design principles:

- One module performs one responsibility.
- Separate control from datapath.
- Keep interfaces simple.
- Use synchronous logic.
- Avoid unnecessary combinational dependencies.
- Design for future expansion.

These principles are commonly followed in industrial RTL design because they improve readability, verification, and long-term maintainability.

---

# 21. RTL Implementation in Our Project

The Descriptor Fetch Unit developed for this project was written entirely in **SystemVerilog** using a clean RTL design methodology.

Instead of writing one large sequential block containing all logic, the DFU follows the **three-process FSM architecture**, separating the controller and datapath responsibilities.

The implementation consists of the following logical components:

```
Descriptor Fetch Unit
│
├── State Register
├── Next-State Logic
├── Output Logic
├── Descriptor Register
├── Memory Interface
└── Status Generation
```

This separation provides several advantages:

- Easier debugging
- Easier verification
- Better code readability
- Cleaner synthesis reports
- Simpler timing analysis

Each block has a single well-defined responsibility.

---

# 22. Controller Implementation

The controller is implemented as a finite state machine.

Its responsibilities include:

- accepting fetch requests
- issuing memory reads
- generating descriptor capture signals
- controlling Busy
- controlling Done
- determining the next state

The controller **never stores descriptor data**.

Instead, it only generates enable signals for the datapath.

This significantly reduces coupling between logic blocks.

---

# 23. Datapath Implementation

The datapath performs all data movement.

Typical datapath operations include:

- receiving descriptor data
- storing descriptor fields
- forwarding descriptor outputs
- buffering memory reads

Conceptually,

```
Memory

↓

Descriptor Bus

↓

Descriptor Register

↓

Output Interface
```

Only the controller decides **when** these registers update.

The datapath never changes state independently.

---

# 24. Descriptor Register

One of the most important registers inside the DFU is the descriptor register.

Its responsibilities are:

- hold the fetched descriptor
- isolate memory timing from downstream logic
- provide stable outputs
- prevent unnecessary memory accesses

Without this register,

downstream hardware would need to continuously monitor descriptor memory.

Instead,

the descriptor becomes locally available after one successful fetch.

---

# 25. Why Descriptor Registers are Necessary

Suppose descriptor memory changes immediately after a read.

Without an internal register,

the scheduler would observe inconsistent data.

Instead,

the descriptor is captured once.

```
Memory

↓

Register

↓

Scheduler
```

The register provides:

- stability
- synchronization
- deterministic timing

---

# 26. Reset Behaviour

Reset is extremely important in synchronous digital systems.

During reset,

the DFU initializes:

- current_state
- busy
- done
- descriptor register
- read enable
- internal control signals

This guarantees that every simulation begins from a known state.

It also guarantees deterministic FPGA configuration.

Good RTL should never rely on unknown ('X') values after reset.

---

# 27. Verification Strategy

A hardware module is only complete after verification.

The DFU verification strategy consisted of several stages.

---

## Stage 1

Compile Verification

Objectives:

- RTL compiles successfully.
- Packages compile.
- Assertions compile.
- Testbench compiles.

---

## Stage 2

Reset Verification

Verify:

- FSM enters IDLE.
- Busy clears.
- Done clears.
- Registers reset correctly.

---

## Stage 3

Descriptor Memory Verification

Verify:

- Descriptor writes succeed.
- Descriptor reads succeed.
- Correct descriptor returned.

---

## Stage 4

DFU Functional Verification

Verify:

- Fetch request accepted.
- Memory read initiated.
- Descriptor captured.
- Done asserted.
- Busy deasserted.

---

## Stage 5

FSM Verification

Every state transition was observed during simulation.

```
IDLE

↓

ISSUE_READ

↓

CAPTURE

↓

COMPLETE

↓

IDLE
```

This confirmed the correctness of the controller implementation.

---

# 28. Assertion-Based Verification

The DFU also includes SystemVerilog Assertions (SVA).

Assertions verify properties that should always remain true.

Examples include:

- illegal state transitions
- busy signal correctness
- done signal correctness
- descriptor capture timing

Instead of manually checking waveforms,

assertions automatically detect protocol violations during simulation.

This greatly improves verification quality.

---

# 29. Debugging History

One of the most important lessons learned during development involved simulation control.

Initially,

the simulator never terminated.

Simulation appeared to hang indefinitely.

Investigation revealed that:

```
always #5 clk = ~clk;
```

creates an infinite clock.

Combined with

```
run -all
```

the simulator waits forever unless explicitly instructed to stop.

The solution was simply:

```
$finish;
```

at the end of the directed test.

After adding `$finish`,

simulation completed successfully.

This debugging experience reinforces an important verification principle:

> A free-running clock requires an explicit simulation termination condition.

---

# 30. Lessons Learned

Developing the DFU reinforced several engineering principles.

## Modular Design

Small modules are easier to verify.

---

## Separation of Control and Datapath

Control logic should never manipulate data directly.

---

## Deterministic FSMs

Simple state machines reduce debugging effort.

---

## Assertions Save Time

Assertions detect protocol violations much earlier than waveform inspection.

---

## Verification is Part of Design

RTL should never be considered complete until thoroughly verified.

---

# 31. Industry Perspective

Commercial hardware rarely fetches a single descriptor at a time.

Instead,

modern accelerators typically include:

- descriptor prefetch
- descriptor FIFOs
- multiple outstanding memory requests
- out-of-order scheduling
- descriptor chaining
- completion queues

Our implementation intentionally begins with a single-descriptor DFU.

Advantages include:

- simplicity
- educational value
- easier verification
- incremental scalability

Future versions of the accelerator can extend this design while preserving the same architectural foundation.

---

# 32. Future Improvements

Possible enhancements include:

- Multiple descriptor fetches
- Descriptor FIFO
- Ring buffer support
- Descriptor chaining
- Error detection
- Timeout monitoring
- Priority scheduling
- Multiple outstanding memory reads
- AXI bus interface
- Cache support

The modular nature of the current DFU makes these extensions straightforward.

---

# 33. Common Design Mistakes

When designing a Descriptor Fetch Unit, beginners commonly make the following mistakes:

- Combining controller and datapath logic.
- Capturing descriptor data before memory is valid.
- Forgetting reset initialization.
- Holding Done high for multiple cycles.
- Ignoring Busy during new fetch requests.
- Using blocking assignments inside sequential logic.
- Creating combinational feedback paths.
- Not verifying every FSM transition.

Avoiding these mistakes leads to more robust RTL.

---

# 34. Interview Questions

## Basic

1. What is the purpose of a Descriptor Fetch Unit?
2. Why is the DFU separated from the scheduler?
3. What signals does the DFU generate?

---

## Intermediate

1. Explain the DFU state machine.
2. Why is Busy required?
3. Why is Done usually asserted for only one cycle?
4. Why is a descriptor register required?

---

## Advanced

1. How would you redesign the DFU to support descriptor chaining?
2. How would you implement descriptor prefetching?
3. How would the DFU change if memory latency were variable?
4. How would you integrate the DFU with an AXI4 bus?
5. How would you verify descriptor ordering?

---

# 35. Key Takeaways

- The Descriptor Fetch Unit is responsible for retrieving descriptors from memory.
- It forms the first active hardware stage in the accelerator pipeline.
- The DFU separates descriptor handling from downstream processing.
- Controller and datapath responsibilities are intentionally separated.
- A four-state FSM provides deterministic operation.
- Busy and Done synchronize descriptor processing.
- Assertion-based verification improves design reliability.
- Proper reset behavior is essential for deterministic hardware.
- Modular RTL simplifies debugging and future expansion.
- The current DFU provides a strong architectural foundation for the Scheduler, DMA Engine, and Matrix Engine.

---

# Chapter Summary

In this chapter, we explored the complete design of the Descriptor Fetch Unit (DFU), from its architectural motivation to its RTL implementation and verification.

We examined why descriptor fetching is isolated into its own hardware block, how the controller and datapath cooperate to retrieve descriptors, and how the finite state machine sequences each fetch operation. We also reviewed the verification methodology used during development, including directed testing, assertion-based verification, and the debugging process that led to a stable simulation environment.

The DFU is intentionally simple but highly modular. As the AI accelerator grows to include schedulers, DMA engines, and compute units, this module will continue to serve as the entry point for all descriptor-driven execution.

The next chapter focuses on **SystemVerilog Assertions (SVA)**, where we will study the theory behind assertions, their syntax, best practices, and how they were applied to verify the DFU.

---

**END OF FILE**