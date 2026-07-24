# Chapter 16: Scheduler

> **Document:** Learning Series
>
> **Chapter:** 16
>
> **Topic:** Hardware Scheduler
>
> **Prerequisites:**
>
> - 11 Descriptor-Based Architecture
> - 12 Memory-Mapped I/O (MMIO)
> - 13 Descriptor Fetch Unit
> - 15 Assertion-Based Verification
> - Finite State Machines
> - Digital System Design

---

# Table of Contents

1. Introduction
2. Why a Scheduler is Needed
3. What is a Hardware Scheduler?
4. Responsibilities of the Scheduler
5. Scheduler Position in the AI Accelerator
6. Scheduler Inputs
7. Scheduler Outputs
8. Internal Building Blocks
9. Scheduler Operation
10. Scheduling Policies
11. Scheduler FSM
12. Interaction with Other Modules
13. Design Considerations
14. Future Extensions
15. Best Practices
16. Common Mistakes
17. Interview Questions
18. Summary

---

# 1. Introduction

The Descriptor Fetch Unit retrieves work from memory.

However, simply fetching descriptors is not enough.

A modern AI accelerator requires a hardware block that decides:

- when a descriptor should execute,
- which compute engine should receive it,
- whether the required resources are available,
- and when execution is complete.

This decision-making hardware is called the **Scheduler**.

The scheduler acts as the **traffic controller** of the accelerator.

Without it, descriptors would either execute out of order, contend for shared resources, or overwrite one another.

---

# 2. Why a Scheduler is Needed

Imagine an airport.

Passengers arrive continuously.

Runways are limited.

Air traffic control determines:

- which aircraft lands first,
- which waits,
- which runway is available,
- and when takeoff may begin.

The scheduler performs the same role inside an accelerator.

Descriptors arrive from the DFU.

Execution engines have limited availability.

The scheduler ensures that work is issued only when resources are ready.

Without scheduling,

multiple descriptors could attempt to use the Matrix Engine simultaneously, leading to conflicts and undefined behaviour.

---

# 3. What is a Hardware Scheduler?

A hardware scheduler is a control module that manages the execution of work items inside a digital system.

Its primary purpose is to coordinate hardware resources efficiently.

Unlike software schedulers running on CPUs, a hardware scheduler operates synchronously with the system clock.

It makes decisions every clock cycle based on the current state of the accelerator.

Conceptually,

```text
Descriptor

↓

Scheduler

↓

Execution Decision

↓

Compute Engine
```

The scheduler does not perform computation itself.

Instead, it decides **who computes, when they compute, and under what conditions**.

---

# 4. Responsibilities of the Scheduler

The scheduler performs several critical tasks.

These include:

- receiving descriptors from the Descriptor Fetch Unit,
- validating descriptor information,
- determining resource availability,
- issuing execution requests,
- tracking ongoing operations,
- monitoring completion,
- preparing the system for the next descriptor.

The scheduler therefore becomes the central coordination point of the accelerator.

---

# 5. Scheduler Position in the AI Accelerator

Within the overall accelerator architecture, the scheduler sits between descriptor management and execution hardware.

```text
CPU

↓

MMIO

↓

Descriptor Memory

↓

Descriptor Fetch Unit

↓

Scheduler

↓

DMA Engine

↓

Matrix Engine

↓

Activation Unit

↓

Completion
```

Every descriptor passes through the scheduler before reaching the compute pipeline.

This separation keeps descriptor management independent from execution logic.

---

# 6. Scheduler Inputs

The scheduler receives information from several modules.

Typical inputs include:

### Descriptor Information

Provided by the Descriptor Fetch Unit.

Contains:

- operation type,
- source addresses,
- destination addresses,
- matrix dimensions,
- execution parameters.

---

### Busy Signals

Execution engines report whether they are currently occupied.

Example:

```text
Matrix Engine Busy

DMA Busy

Activation Busy
```

The scheduler uses these signals to avoid issuing conflicting commands.

---

### Completion Signals

Execution engines notify the scheduler when operations finish.

Examples:

- DMA Done
- Matrix Done
- Activation Done

These signals allow the scheduler to safely dispatch new work.

---

### System Reset

Reset initializes the scheduler.

Typical reset actions include:

- return to IDLE,
- clear pending requests,
- reset internal status registers.

---

# 7. Scheduler Outputs

The scheduler generates control signals for downstream hardware.

Typical outputs include:

### DMA Start

Initiates data movement.

---

### Matrix Start

Starts matrix multiplication.

---

### Activation Start

Starts activation processing (such as ReLU).

---

### Descriptor Complete

Indicates successful execution of the current descriptor.

---

### Scheduler Busy

Reports whether the scheduler is actively processing work.

---

# 8. Internal Building Blocks

A modular scheduler can be divided into several logical components.

```text
Scheduler
│
├── State Machine
├── Descriptor Register
├── Resource Checker
├── Issue Logic
├── Completion Monitor
└── Status Generator
```

Each block has a clearly defined responsibility.

This modular organization improves readability, verification, and future scalability.

---

# 9. Descriptor Register

Once a descriptor is received from the Descriptor Fetch Unit, it is stored locally inside the scheduler.

The descriptor register provides:

- stable inputs,
- synchronization,
- reduced memory traffic,
- deterministic execution.

Instead of repeatedly requesting descriptor information from memory, the scheduler works from this locally stored copy throughout execution.

---

# 10. Resource Checker

Before issuing any command, the scheduler determines whether the required execution resources are available.

For example,

if a descriptor requests matrix multiplication,

the scheduler checks:

- Is the DMA engine idle?
- Is the Matrix Engine idle?
- Are required buffers available?

Only after all required resources become available does scheduling continue.

This prevents hardware contention and improves reliability.

---

# 11. Issue Logic

The Issue Logic is responsible for launching work.

Once all scheduling conditions are satisfied, it generates the appropriate start signals.

For example:

```text
Descriptor Ready

↓

Resources Available

↓

Issue Logic

↓

DMA Start
```

The Issue Logic never performs computation.

Its only responsibility is to initiate execution.

---

# 12. Scheduler Operation

The scheduler operates continuously while the accelerator is enabled.

Its primary execution flow can be summarized as follows:

```text
Wait for Descriptor

↓

Receive Descriptor

↓

Validate Descriptor

↓

Check Resource Availability

↓

Issue Commands

↓

Monitor Execution

↓

Receive Completion

↓

Mark Descriptor Complete

↓

Return to IDLE
```

Each descriptor follows this lifecycle exactly once.

The scheduler ensures that no new descriptor is issued until all required conditions have been satisfied.

---

# 13. Scheduler State Machine

Like the Descriptor Fetch Unit, the scheduler is naturally implemented as a finite state machine (FSM).

A simple scheduler may contain the following states:

```text
IDLE

↓

LOAD_DESCRIPTOR

↓

CHECK_RESOURCES

↓

ISSUE_COMMANDS

↓

WAIT_FOR_COMPLETION

↓

COMPLETE

↓

IDLE
```

Each state performs one clearly defined task.

This keeps the controller deterministic and simplifies debugging.

---

## IDLE

The scheduler waits for a valid descriptor from the Descriptor Fetch Unit.

During this state:

- Scheduler Busy = 0
- No execution engines are active
- No descriptor is being processed

The scheduler remains here until a descriptor becomes available.

---

## LOAD_DESCRIPTOR

The descriptor is copied into the scheduler's internal descriptor register.

Typical actions include:

- Latch descriptor fields
- Validate descriptor format
- Clear previous status flags

No execution commands are generated in this state.

---

## CHECK_RESOURCES

Before launching execution, the scheduler verifies that all required hardware resources are available.

Typical checks include:

- DMA Busy == 0
- Matrix Engine Busy == 0
- Activation Unit Busy == 0
- Internal buffers available

If any required resource is busy, the scheduler simply remains in this state until the resources become free.

---

## ISSUE_COMMANDS

Once resources are available, execution begins.

Depending on the descriptor type, the scheduler may generate:

- DMA Start
- Matrix Start
- Activation Start
- Completion monitor enable

This state generally lasts only one clock cycle.

---

## WAIT_FOR_COMPLETION

Execution hardware now performs the requested computation.

The scheduler waits for completion signals from downstream modules.

Examples include:

- DMA Done
- Matrix Done
- Activation Done

No additional descriptors are issued during this period unless future versions support multiple outstanding operations.

---

## COMPLETE

The scheduler performs final bookkeeping.

Typical operations include:

- Generate Descriptor Complete
- Clear Busy
- Notify CPU (if required)
- Prepare for the next descriptor

After completion, the scheduler returns to the IDLE state.

---

# 14. Interaction with Other Modules

The scheduler is not an isolated component.

It continuously communicates with multiple hardware modules.

```text
Descriptor Fetch Unit

↓

Scheduler

├─────────────┐
│             │
│             │
▼             ▼

DMA Engine   Matrix Engine

│             │

▼             ▼

Activation Unit

↓

Completion Logic
```

Each downstream module reports its status back to the scheduler.

This closed feedback loop allows safe and coordinated execution.

---

# 15. Scheduler and the DMA Engine

For descriptors requiring memory movement, the scheduler first initiates the DMA Engine.

Typical sequence:

```text
Descriptor Ready

↓

Scheduler

↓

DMA Start

↓

DMA Transfers Data

↓

DMA Done

↓

Scheduler Continues
```

The scheduler does not move data itself.

Instead, it delegates data transfer responsibilities to the DMA Engine.

---

# 16. Scheduler and the Matrix Engine

Once input data becomes available, the scheduler starts the Matrix Engine.

Typical flow:

```text
DMA Done

↓

Scheduler

↓

Matrix Start

↓

Matrix Multiplication

↓

Matrix Done
```

This staged execution ensures that computation begins only after all required operands are available.

---

# 17. Scheduler and the Activation Unit

After matrix multiplication completes, certain workloads require activation functions such as ReLU.

The scheduler coordinates this stage as well.

```text
Matrix Done

↓

Scheduler

↓

Activation Start

↓

Activation Done
```

The scheduler therefore orchestrates the complete inference pipeline.

---

# 18. Scheduling Policies

Different hardware systems employ different scheduling algorithms.

The simplest policy is:

## First-In First-Out (FIFO)

Descriptors execute in arrival order.

Advantages:

- Easy to implement
- Deterministic
- Fair

Disadvantages:

- Cannot prioritize urgent tasks.

---

More advanced accelerators may support:

- Static Priority Scheduling
- Dynamic Priority Scheduling
- Round Robin
- Earliest Deadline First
- Weighted Fair Scheduling

For this project, a FIFO scheduler provides an excellent balance between simplicity and scalability.

---

# 19. Descriptor Validation

Before execution begins, descriptors should be validated.

Typical validation checks include:

- Valid opcode
- Proper source address alignment
- Proper destination address alignment
- Supported matrix dimensions
- Legal activation type
- Valid descriptor length

Invalid descriptors should never reach execution hardware.

Instead, the scheduler should reject them and report an error.

---

# 20. Error Handling

Robust schedulers include mechanisms for handling exceptional conditions.

Examples include:

- Invalid descriptor
- Timeout waiting for DMA completion
- Timeout waiting for Matrix completion
- Unsupported opcode
- Resource allocation failure

Possible responses include:

- Abort descriptor
- Generate error interrupt
- Log status register
- Return to IDLE safely

Error handling greatly improves system reliability and debuggability.

---

# 21. Synchronization

The scheduler coordinates multiple hardware blocks that may operate concurrently.

Synchronization mechanisms include:

- Busy signals
- Done signals
- Valid/Ready handshakes
- Status registers
- Internal state tracking

Proper synchronization prevents race conditions and ensures deterministic execution.

---

# 22. Design Philosophy

Several guiding principles influenced the scheduler architecture used in this project.

### Separation of Responsibilities

The scheduler controls execution.

Execution engines perform computation.

---

### Modular Design

Each hardware block has a single well-defined purpose.

---

### Deterministic Control

Finite State Machines ensure predictable behaviour.

---

### Scalability

Future execution engines can be integrated without redesigning the scheduler from scratch.

---

### Verification-Oriented Design

The architecture is structured to simplify simulation, assertion writing, and future formal verification.

---
# 23. RTL Implementation

The Scheduler in this project is implemented entirely in **SystemVerilog** using a modular RTL design approach.

Rather than placing all scheduling decisions into one large sequential block, the implementation separates the controller and datapath into independent components.

The scheduler consists of the following logical blocks:

```text
Scheduler
│
├── State Register
├── Next-State Logic
├── Descriptor Register
├── Resource Checker
├── Command Generator
├── Completion Monitor
└── Status Generator
```

This organization provides several important benefits:

- Improved readability
- Easier debugging
- Simpler verification
- Better scalability
- Cleaner synthesis reports

Each block performs a single well-defined responsibility.

---

# 24. Controller Responsibilities

The scheduler controller is responsible for sequencing execution.

Typical responsibilities include:

- receiving descriptor valid signals,
- controlling FSM transitions,
- checking resource availability,
- issuing start commands,
- waiting for completion,
- generating completion status.

The controller never performs computation.

Instead, it decides **when** computation should begin.

---

# 25. Datapath Responsibilities

The scheduler datapath stores and forwards execution information.

Typical datapath operations include:

- storing descriptor fields,
- forwarding execution parameters,
- generating command buses,
- buffering status information.

Conceptually,

```text
Descriptor

↓

Scheduler Register

↓

Execution Command Bus
```

The datapath responds only when enabled by the controller.

---

# 26. Verification Strategy

The scheduler was designed to be verified incrementally.

Verification proceeds through several stages.

---

## Stage 1

Compilation

Verify:

- RTL compiles successfully.
- Packages compile.
- Interfaces compile.
- Testbench compiles.

---

## Stage 2

Reset Verification

Verify:

- FSM enters IDLE.
- Busy clears.
- Descriptor register resets.
- Internal status flags clear.

---

## Stage 3

Descriptor Reception

Verify:

- Descriptor received correctly.
- Descriptor stored correctly.
- Invalid descriptors rejected.

---

## Stage 4

Scheduling Logic

Verify:

- Resources checked correctly.
- Commands issued only when resources become available.
- Busy remains asserted while scheduling is active.

---

## Stage 5

Execution Monitoring

Verify:

- Completion signals detected.
- Descriptor Complete generated.
- Scheduler returns to IDLE.

---

## Stage 6

Stress Testing

Multiple descriptors are injected sequentially to ensure that the scheduler:

- processes every descriptor,
- never skips work,
- never issues duplicate commands,
- never deadlocks.

---

# 27. Assertions for the Scheduler

Assertion-Based Verification greatly improves scheduler reliability.

Typical assertions include:

### Reset

Verify that reset always returns the FSM to IDLE.

---

### Busy Protocol

Busy must remain asserted while scheduling is active.

---

### Resource Checking

Commands shall never be issued while required resources are busy.

---

### Completion

Descriptor Complete shall only assert after successful execution.

---

### Illegal Transitions

The scheduler shall never enter undefined FSM states.

---

### Descriptor Stability

Descriptor registers shall remain unchanged while execution is in progress.

---

These assertions automatically detect protocol violations during simulation.

---

# 28. Debugging Strategy

Scheduler bugs generally fall into three categories.

## Control Bugs

Examples:

- Incorrect FSM transition
- Missing state
- Deadlock

---

## Synchronization Bugs

Examples:

- Busy deasserted too early
- Done ignored
- Multiple start commands

---

## Resource Allocation Bugs

Examples:

- Matrix Engine started while busy.
- DMA started twice.
- Activation skipped.

Assertions and directed simulations help isolate each of these failures rapidly.

---

# 29. Future Enhancements

The scheduler developed in this project serves as a strong educational foundation.

Future versions may support:

### Multiple Outstanding Descriptors

Allow several descriptors to execute concurrently.

---

### Descriptor Queue

Maintain multiple pending descriptors.

---

### Priority Scheduling

Support high-priority AI workloads.

---

### Dynamic Scheduling

Select execution order based on hardware availability.

---

### Dependency Tracking

Delay execution until dependent descriptors complete.

---

### Multi-Core Scheduling

Distribute descriptors across multiple Matrix Engines.

---

### Load Balancing

Automatically allocate work to the least busy execution unit.

---

### Power-Aware Scheduling

Reduce energy consumption by intelligently activating execution engines.

---

### Performance Counters

Record:

- scheduler utilization,
- descriptor latency,
- engine occupancy,
- throughput.

These statistics assist both debugging and architectural optimization.

---

# 30. Industry Perspective

Schedulers are fundamental components of nearly every modern accelerator.

Examples include:

- GPU command processors
- TPU execution controllers
- AI inference accelerators
- Network packet processors
- Storage controllers
- Video encoding engines

Although implementations vary considerably, nearly all hardware schedulers perform the same essential functions:

- receive work,
- allocate resources,
- issue commands,
- monitor execution,
- report completion.

Learning scheduler design therefore provides transferable knowledge across many hardware domains.

---

# 31. Common Design Mistakes

New hardware designers frequently encounter the following issues:

- Mixing controller and datapath logic.
- Ignoring Busy signals.
- Launching computation before DMA completion.
- Forgetting descriptor validation.
- Allowing illegal FSM transitions.
- Holding start signals high for multiple cycles.
- Not resetting internal registers.
- Creating combinational feedback paths.
- Not verifying timeout conditions.

Avoiding these mistakes results in more reliable and maintainable RTL.

---

# 32. Interview Questions

## Basic

1. What is the purpose of a hardware scheduler?
2. Why is scheduling required in an accelerator?
3. What information does the scheduler receive from the DFU?

---

## Intermediate

1. Explain the scheduler FSM.
2. Why are Busy and Done signals important?
3. How does the scheduler coordinate DMA and Matrix Engines?
4. Why should descriptor validation occur before execution?

---

## Advanced

1. How would you redesign the scheduler to support multiple descriptors simultaneously?
2. How would you implement priority scheduling in hardware?
3. How would you prevent starvation in a hardware scheduler?
4. How would you verify scheduler correctness using SystemVerilog Assertions?
5. How would you scale this scheduler for a multi-core AI accelerator?

---

# 33. Key Takeaways

- The scheduler is the central control unit of the AI accelerator.
- It coordinates descriptor execution without performing computation itself.
- Resource availability is verified before issuing commands.
- A finite state machine provides deterministic scheduling behaviour.
- Busy and Done signals synchronize execution across hardware modules.
- Modular controller/datapath separation simplifies RTL development and verification.
- Assertion-Based Verification strengthens scheduler reliability.
- The architecture is intentionally scalable, allowing future support for advanced scheduling policies and multiple execution engines.

---

# Chapter Summary

In this chapter, we examined the complete design of the hardware Scheduler, the central coordination unit of the AI accelerator. Starting from its role in descriptor-driven execution, we explored how it validates descriptors, checks resource availability, issues commands to downstream execution units, and monitors completion.

We studied the scheduler's finite state machine, controller/datapath partitioning, verification strategy, and the use of assertions to validate correct behaviour. We also discussed future enhancements such as priority scheduling, descriptor queues, dependency tracking, and multi-core execution support.

With the Scheduler complete, the next chapter moves to the **DMA Engine**, where we will study how input and output data are efficiently transferred between memory and the compute engines.

---

**END OF FILE**