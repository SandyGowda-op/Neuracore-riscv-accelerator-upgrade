# MMUL Baseline Characterization Report

Date: 2026-06-15

Phase: Accelerator Baseline Validation

---

## Accelerator Configuration

Architecture:

* Iterative Matrix Multiply Unit (MMUL)

Matrix Dimensions:

* 8 × 8

Operation:

* Matrix Multiplication

Computation Style:

* One MAC operation per cycle

Total MAC Operations:

8 × 8 × 8 = 512 MACs

---

## Test Environment

CPU:

* RV32I 5-stage pipelined processor

Clock Frequency:

* 100 MHz

Clock Period:

* 10 ns

Simulation:

* Icarus Verilog

Synthesis:

* Yosys

---

## Test Program

Instruction Sequence:

000010B7
00000013
00000013
00100113
00000013
00000013
0020A023
00000013
00000013
00000013
00000013
00000013
0000006F

Purpose:

* Start MMUL operation
* Insert NOPs to accommodate pipeline execution
* Observe accelerator completion
* Verify matrix multiplication correctness

---

## Input Matrices

Matrix A:

Diagonal matrix

0 0 0 0 0 0 0 0
0 1 0 0 0 0 0 0
0 0 2 0 0 0 0 0
0 0 0 3 0 0 0 0
0 0 0 0 4 0 0 0
0 0 0 0 0 5 0 0
0 0 0 0 0 0 6 0
0 0 0 0 0 0 0 7

Matrix B:

Diagonal matrix

0 0 0 0 0 0 0 0
0 1 0 0 0 0 0 0
0 0 2 0 0 0 0 0
0 0 0 3 0 0 0 0
0 0 0 0 4 0 0 0
0 0 0 0 0 5 0 0
0 0 0 0 0 0 6 0
0 0 0 0 0 0 0 7

Expected Output:

Diagonal squares

0² 1² 2² 3² 4² 5² 6² 7²

---

## Output Matrix

0    0    0    0    0    0    0    0

0    1    0    0    0    0    0    0

0    0    4    0    0    0    0    0

0    0    0    9    0    0    0    0

0    0    0    0   16    0    0    0

0    0    0    0    0   25    0    0

0    0    0    0    0    0   36    0

0    0    0    0    0    0    0   49

Verification Status:
PASS

Output exactly matches expected matrix multiplication result.

---

## Performance Measurements

MMUL Start Cycle:
10

MMUL Completion Cycle:
522

Total Computation Cycles:
512

Busy Assert Cycle:
11

Busy Deassert Cycle:
523

Busy Duration:
512 cycles

Execution Time:
5.12 µs

---

## Current Accelerator Interface

Busy Signal:
Available

Done Signal:
Available

Result Valid Signal:
Not Implemented

CPU Behaviour:
Global stall during MMUL execution

Concurrent CPU + MMUL Execution:
Not Supported

DMA:
Not Implemented

---

## Verified Features

PASS:

* MMUL start sequence
* Busy assertion
* Busy deassertion
* Completion pulse
* Matrix multiplication correctness
* CPU integration

Pending:

* Back-to-back MMUL launch validation
* Result-valid interface
* Non-blocking execution
* Accelerator RAW hazard detection
* DMA integration

---

## Baseline Reference

This report serves as the baseline reference point for all future MMUL enhancements.

Future accelerator versions will be compared against:

* Latency
* Cycle count
* Resource utilization
* Throughput
* Hazard handling capability
* CPU concurrency support

## Hardware Resource Snapshot

Synthesis Tool:

* Yosys

Top Module:

* riscv_pipeline

Resource Utilization:

Wires:

* 435

Wire Bits:

* 2044

Public Wires:

* 73

Public Wire Bits:

* 1053

Ports:

* 13

Port Bits:

* 261

Total Cells:

* 1102

Cell Breakdown:

AND Gates:

* 332

MUXes:

* 286

OR Gates:

* 205

XOR Gates:

* 187

NOT Gates:

* 60

Flip-Flops:

* 32

Integrated Submodules:

* register_file
* instr_mem
* data_memory
* if_id
* id_ex
* ex_mem
* mem_wb
* forwarding_unit
* hazard_detection_unit
* immediate_gen
* mmul_mem

Observation:

This synthesis snapshot represents the first complete version of the upgraded processor containing:

* Forwarding network
* Load-use hazard detection
* Branch hazard handling
* Load-to-branch forwarding
* MMUL accelerator integration

This resource report serves as the baseline hardware reference for future accelerator and pipeline enhancements.

## Structural Hazard Test #1

Test Name:
Back-to-Back MMUL Launch Protection

Objective:

Verify that the MMUL accelerator rejects a second launch request while an existing matrix multiplication operation is already in progress.

Test Sequence:

START MMUL

Immediately issue another START MMUL request

Expected Behaviour:

* First launch accepted
* MMUL enters busy state
* Second launch ignored
* Single matrix multiplication operation executes
* Single completion event generated

Observed Behaviour:

Simulation Log:

=== MMUL 8x8 START ===

...

MATRIX MULTIPLICATION COMPLETE

Number of START events:
1

Number of COMPLETE events:
1

Result:

PASS

Conclusion:

The MMUL accelerator correctly prevents concurrent launches through busy-state gating.

The launch condition:

if (we && !mmul_busy)

successfully protects the accelerator from structural hazards caused by multiple simultaneous requests.

## Accelerator RAW Hazard Test #1

Objective

Verify that instructions following MMUL launch cannot execute before accelerator completion.

Method

Launch MMUL operation and immediately place dependent instructions in the instruction stream.

Expected Behaviour

CPU pipeline stalls while accelerator is busy.

Observed Behaviour

- PC remained constant during MMUL execution.
- BUSY signal remained asserted.
- No instructions retired during computation.
- PC resumed incrementing after BUSY deasserted.

Result

PASS

Hazard Resolution

Global CPU stall:

wire cpu_stall = dbg_accel_busy;

Conclusion

Current design prevents accelerator RAW hazards by freezing the entire processor during MMUL execution.

Limitation

No overlap exists between CPU execution and accelerator execution.