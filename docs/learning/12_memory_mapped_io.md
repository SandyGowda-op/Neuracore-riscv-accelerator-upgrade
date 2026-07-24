# Chapter 12: Memory-Mapped Input/Output (MMIO)

> **Document:** Learning Series  
> **Chapter:** 12  
> **Prerequisites:**
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
> - 11 Descriptor-Based Architecture

---

# Table of Contents

1. Introduction
2. What is Memory-Mapped I/O?
3. Why MMIO Exists
4. Memory Space Organization
5. Memory-Mapped I/O vs Port-Mapped I/O
6. MMIO Read Operation
7. MMIO Write Operation
8. Address Decoding
9. MMIO Registers
10. MMIO in SoC Design
11. MMIO in Our Project
12. Hardware Implementation
13. Design Considerations
14. Common Mistakes
15. Industry Perspective
16. Interview Questions
17. Summary

---

# 1. Introduction

Modern processors communicate with hardware peripherals through a mechanism known as **Memory-Mapped Input/Output (MMIO)**.

Instead of using dedicated communication instructions, peripherals are assigned addresses within the processor's memory map. From the processor's perspective, communicating with hardware is no different from reading or writing memory.

For example, writing to an LED controller may simply involve writing a value to address:

```text
0x40000000
```

Similarly, reading the status of a DMA engine may involve reading from:

```text
0x40000020
```

This unified view simplifies both processor design and software development.

---

# 2. What is Memory-Mapped I/O?

Memory-Mapped I/O is a technique where hardware peripherals occupy locations within the processor's address space.

The CPU accesses these peripherals using ordinary load and store instructions.

Instead of accessing RAM, the processor accesses hardware registers.

Example:

```text
Address         Device

0x00000000      Instruction Memory

0x10000000      Data Memory

0x20000000      Descriptor Memory

0x30000000      DMA Registers

0x40000000      Accelerator Registers
```

Each address corresponds to a different hardware module.

---

# 3. Why MMIO Exists

Imagine a processor that had a completely different instruction for every peripheral.

```text
WRITE_UART

WRITE_TIMER

WRITE_DMA

WRITE_ACCELERATOR

WRITE_GPIO

WRITE_SPI
```

As the number of peripherals increased, the instruction set would become unnecessarily large.

Instead, MMIO allows the processor to reuse existing instructions.

Example:

```assembly
SW x5, 0(x10)
LW x6, 4(x10)
```

These same instructions can access:

- RAM
- ROM
- Registers
- DMA
- Timers
- AI Accelerators

Only the address changes.

---

# 4. Memory Space Organization

A processor typically divides its address space into regions.

Example:

```text
+------------------------------+
| Boot ROM                     |
+------------------------------+
| Instruction Memory           |
+------------------------------+
| Data Memory                  |
+------------------------------+
| Stack                        |
+------------------------------+
| Heap                         |
+------------------------------+
| MMIO Region                  |
|  UART                        |
|  GPIO                        |
|  DMA                         |
|  Accelerator                 |
+------------------------------+
```

The processor does not know whether an address corresponds to RAM or hardware.

The address decoder determines the destination.

---

# 5. Memory-Mapped I/O vs Port-Mapped I/O

## Memory-Mapped I/O

Characteristics:

- Uses normal load/store instructions.
- Shares the processor's address space.
- Simpler compiler support.
- Widely used in ARM, RISC-V, MIPS, and PowerPC.

---

## Port-Mapped I/O

Characteristics:

- Uses dedicated IN/OUT instructions.
- Separate address space.
- Primarily used in legacy x86 systems.

---

### Comparison

| Feature | MMIO | Port-Mapped I/O |
|----------|------|-----------------|
| Uses Load/Store | Yes | No |
| Separate Instructions | No | Yes |
| Shared Address Space | Yes | No |
| Simpler Software | Yes | No |
| Common in Modern SoCs | Yes | Rare |

Modern RISC-V systems exclusively use MMIO.

---

# 6. MMIO Read Operation

When software reads an MMIO register:

```assembly
LW x5, STATUS_REGISTER
```

The processor performs the following steps:

```text
CPU

↓

Address Generation

↓

Address Decoder

↓

Peripheral Selected

↓

Peripheral Places Data

↓

CPU Receives Data
```

Unlike RAM, the data originates from hardware logic.

---

# 7. MMIO Write Operation

Writing to hardware is similar.

Example:

```assembly
SW x5, CONTROL_REGISTER
```

Sequence:

```text
CPU

↓

Address Bus

↓

Address Decoder

↓

Target Peripheral

↓

Register Updated

↓

Hardware Responds
```

A write may:

- Start a DMA transfer.
- Enable an interrupt.
- Reset hardware.
- Configure an accelerator.

---

# 8. Address Decoding

Address decoding determines which hardware block should respond to a memory transaction.

Simplified example:

```systemverilog
if(address == 32'h40000000)
    gpio_select = 1;

else if(address == 32'h40000010)
    dma_select = 1;

else if(address == 32'h40000020)
    accelerator_select = 1;
```

Only one peripheral should respond at a time.

---

# 9. MMIO Registers

Hardware modules expose functionality through registers.

Typical register map:

| Offset | Register | Description |
|---------|----------|-------------|
| 0x00 | CONTROL | Starts operation |
| 0x04 | STATUS | Busy and Done bits |
| 0x08 | SOURCE | Source address |
| 0x0C | DESTINATION | Destination address |
| 0x10 | LENGTH | Transfer size |

Software interacts only with these registers.

The internal hardware implementation remains hidden.

---

# 10. MMIO in SoC Design

Nearly every peripheral inside a System-on-Chip is accessed through MMIO.

Examples include:

- UART
- GPIO
- Timers
- SPI
- I²C
- DMA Controllers
- Interrupt Controllers
- AI Accelerators

This common interface simplifies software portability and hardware integration.

---

# 11. MMIO in Our Project

Our accelerator is designed to integrate with a RISC-V processor.

The processor communicates with the accelerator using predefined MMIO addresses.

For example:

```text
CPU

↓

MMIO Address

↓

Address Decoder

↓

Descriptor Fetch Unit

↓

Future DMA

↓

Future Matrix Engine
```

The processor does not directly manipulate internal accelerator signals.

Instead, it performs memory writes to specific addresses, and the hardware interprets these writes as commands.

Future modules such as the DMA engine and scheduler will also expose MMIO registers for configuration and status reporting.

---

# 12. Hardware Implementation

Inside hardware, MMIO requires three major components:

1. Address Decoder
2. Register File
3. Control Logic

Example architecture:

```text
CPU Bus
   │
   ▼
Address Decoder
   │
   ├── Control Register
   ├── Status Register
   ├── Source Register
   ├── Destination Register
   └── Length Register
```

Each register is implemented using flip-flops or memory elements, depending on its size and usage.

---

# 13. Design Considerations

When designing an MMIO interface, engineers should consider:

- Address alignment.
- Register spacing.
- Read-only vs write-only registers.
- Reserved bits for future expansion.
- Atomic access requirements.
- Software compatibility.
- Bus width.
- Error handling for invalid addresses.

Good MMIO design greatly simplifies software development and future hardware revisions.

---

# 14. Common Mistakes

- Assigning overlapping address ranges.
- Forgetting address alignment.
- Not reserving unused bits.
- Allowing multiple peripherals to respond to the same address.
- Mixing combinational and sequential register updates.
- Ignoring reset behavior.

---

# 15. Industry Perspective

Commercial processors and SoCs rely heavily on MMIO because it provides a unified interface between software and hardware.

Examples include:

- ARM Cortex-A and Cortex-M processors.
- RISC-V microcontrollers.
- NVIDIA GPUs (control registers).
- AMD GPUs.
- Intel integrated peripherals.

Although the internal buses may differ (AXI, AHB, APB, TileLink, Wishbone), software still interacts with peripherals through memory-mapped registers.

This consistency makes MMIO one of the most fundamental concepts in computer architecture.

---

# 16. Interview Questions

### Basic

1. What is Memory-Mapped I/O?
2. Why is MMIO preferred in modern processors?
3. How does the CPU access an MMIO register?

### Intermediate

1. Explain the role of an address decoder.
2. What is the difference between MMIO and Port-Mapped I/O?
3. Why are reserved bits included in register maps?

### Advanced

1. Design an MMIO interface for a DMA controller.
2. How would you detect invalid MMIO accesses?
3. How would MMIO be integrated with an AXI or APB bus?
4. What synchronization mechanisms are required when software and hardware share MMIO registers?

---

# 17. Summary

Memory-Mapped I/O provides a simple and scalable method for communication between processors and hardware peripherals.

Key points:

- MMIO maps hardware registers into the processor's address space.
- Standard load and store instructions are used to access peripherals.
- Address decoding determines which hardware block responds to each transaction.
- MMIO is used by virtually every modern SoC.
- Our AI accelerator will expose configuration and status registers through MMIO, allowing seamless integration with the RISC-V processor.

The next chapter explores the **Descriptor Fetch Unit (DFU)**, the first hardware module responsible for reading descriptors from memory and initiating accelerator execution.