# RISC-V AI Accelerator Upgrade Architecture Specification For Memory (Phase 1)

## Project Objective

Upgrade the existing RV32I pipelined processor with a scalable AI accelerator architecture supporting:

* Descriptor-driven execution
* Shared scratchpad memory
* DMA compatibility
* Formal verification
* Future backend replacement without ISA modifications

The architecture must allow replacement of the current MMUL engine with a systolic array implementation while preserving software compatibility.

---

# 1. ISA Extension Specification

Custom opcode:

0001011

| funct3  | Operation  |
| ------- | ---------- |
| 000     | FMAC_START |
| 001     | RELU       |
| 010     | FMAC_READ  |
| 011-111 | Reserved   |

Invalid funct3 values must not trigger accelerator execution.

---

# 2. Accelerator Launch Model

Instruction:

fmac_start rs1

Behavior:

* rs1 contains descriptor address.
* CPU passes descriptor pointer to accelerator controller.
* Accelerator becomes responsible for descriptor fetching.
* CPU is not involved in descriptor interpretation.

Example:

li x5, descriptor_addr
fmac_start x5

---

# 3. Descriptor Architecture

Descriptor Size:

32 Bytes

Structure:

struct mmul_desc
{
uint32_t A_ptr;
uint32_t B_ptr;
uint32_t C_ptr;

```
uint32_t rows;
uint32_t cols;
uint32_t k;

uint32_t control;
uint32_t next_desc_ptr;
```

};

---

# 4. Descriptor Control Register

Word 6

Bit Allocation:

Bit 0 : START_VALID

Bit 1 : CHAIN_ENABLE

Bit 2 : INTERRUPT_ENABLE (reserved)

Bit 3 : RELU_ENABLE

Bits 5:4 : DATA_TYPE

Bits 31:6 : Reserved

DATA_TYPE:

00 = INT8

01 = INT16 (future)

10 = INT32 (future)

11 = Reserved

---

# 5. Memory Architecture

## MMIO Region

0x1000 MMUL_CTRL

0x1004 MMUL_STATUS

0x1008 MMUL_RESULT

## Scratchpad Region

0x2000 - 0x2FFF

Size:

4 KB

Implementation:

True Dual-Port BRAM

Used For:

* Matrix storage
* Tile storage
* DMA buffers

## Descriptor Region

0x3000 - 0x3FFF

Size:

4 KB

Supports:

128 descriptors

Purpose:

* Descriptor queue
* Chained execution
* Future scheduling

Descriptors remain physically separated from matrix data.

---

# 6. Scratchpad Design Decisions

Architecture:

Unified scratchpad

No fixed A/B/C partitions

Allocation controlled entirely by software.

Reasons:

* Flexible matrix sizes
* DMA compatibility
* Future tiling support
* Descriptor portability

---

# 7. Data Types

Inputs:

INT8

Accumulator:

INT32

Outputs:

INT32

Motivation:

* Reduced BRAM usage
* Reduced LUT usage
* Higher operating frequency
* Closer to modern AI accelerator practice

---

# 8. MMUL Dataflow

Descriptor
↓
Descriptor Fetch
↓
Scratchpad
↓
Tile Buffer A

Scratchpad
↓
Tile Buffer B

Tile Buffers
↓
MMUL Engine
↓
Tile Buffer C

Tile Buffer C
↓
Scratchpad

No direct compute-to-memory path during execution.

---

# 9. MMUL Controller FSM

States:

IDLE

FETCH_DESC

VALIDATE_DESC

LOAD_TILE_A

LOAD_TILE_B

COMPUTE

STORE_RESULT

DONE

ERROR

---

IDLE

Waiting for FMAC_START.

---

FETCH_DESC

Fetch descriptor from descriptor memory.

---

VALIDATE_DESC

Checks:

* Pointer validity
* Dimension validity
* Control validity

Failure transitions to ERROR.

---

LOAD_TILE_A

Loads matrix A tile into Tile Buffer A.

---

LOAD_TILE_B

Loads matrix B tile into Tile Buffer B.

---

COMPUTE

Performs matrix multiplication.

INT8 × INT8 → INT32

---

STORE_RESULT

Stores results back to scratchpad.

---

DONE

Asserts:

mmul_done

mmul_result_valid

Returns to IDLE.

---

ERROR

Sets:

PTR_ERROR

DIM_ERROR

DESC_ERROR

Waits for software recovery.

---

# 10. Status Register

Address:

0x1004

Bit Allocation:

Bit 0 : BUSY

Bit 1 : RESULT_VALID

Bit 2 : DONE

Bit 3 : DESC_ERROR

Bit 4 : DIM_ERROR

Bit 5 : PTR_ERROR

Bits 31:6 : Reserved

---

# 11. Hazard Handling

Accelerator RAW Hazard:

(reading_mmul_result || reading_fmac_result)
&&
!mmul_result_valid

Behavior:

* Stall pipeline
* Prevent premature result consumption
* Protect both MMIO and ISA result paths

Verified through simulation.

---

# 12. Future DMA Integration

DMA Engine Responsibilities:

* Matrix loading
* Tile loading
* Scratchpad management

DMA shall operate independently of CPU execution.

DMA shall never modify descriptor memory.

---

# 13. Descriptor Chaining (Future)

Reserved Field:

next_desc_ptr

Reserved Control Bit:

CHAIN_ENABLE

Future behavior:

Descriptor A
↓
Descriptor B
↓
Descriptor C

without CPU intervention.

---

# 14. Formal Verification Plan

SymbiYosys Verification Targets

ISA Layer

* FMAC_START correctness
* FMAC_READ correctness
* RELU correctness
* Invalid funct3 protection

Hazard Layer

* No stale result reads
* RAW hazard protection

Scratchpad Layer

* Address safety
* No illegal accesses

Descriptor Layer

* Descriptor validation correctness
* Error-state reachability

FSM Layer

* Deadlock freedom
* Legal state transitions
* Eventual completion

DMA Layer

* No descriptor corruption
* Correct transfer completion

System Layer

* Result-valid protocol correctness
* Busy/done mutual consistency

---

# Long-Term Vision

The accelerator backend shall remain replaceable.

Current MMUL Engine
↓
Future Systolic Array

without requiring modification to:

* ISA
* Descriptor format
* DMA interface
* Scratchpad architecture
* Software stack
* Verification framework
