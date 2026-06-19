# FMAC_READ RAW Hazard Detection

## Problem

The instruction:

fmac x0,x0,x0
fmacrd x5

creates a Read-After-Write dependency.

FMAC_READ attempts to access accelerator results before MMUL execution has completed.

---

## Hazard Condition

reading_fmac_result =
id_is_fmac_read;

accel_raw_hazard =
(reading_mmul_result ||
reading_fmac_result)
&&
!mmul_result_valid;

---

## Stall Behavior

When hazard detected:

final_pc_write = 0

final_ifid_write = 0

final_idex_flush = 1

---

## Verification

Test Program:

fmac x0,x0,x0
fmacrd x5
jal x0,0

Observed:

ACCEL RAW HAZARD DETECTED

PC frozen

MMUL continued execution

Hazard cleared automatically

FMAC_READ executed

Result written to x5

Verification Status:

PASS

---

## Architectural Impact

Software no longer requires explicit polling.

Previous MMIO approach:

sw start
loop:
lw status
beq busy, loop
lw result

Current ISA approach:

fmac
fmacrd

Synchronization handled automatically by hardware.

Status:

COMPLETE
