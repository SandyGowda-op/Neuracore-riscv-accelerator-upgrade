# NeuroCore — Descriptor-Driven RISC-V AI Accelerator

> **Research platform** investigating the architectural trade-offs between
> dense and sparse matrix computation on a RISC-V-integrated AI accelerator.
> Studying the CPU–accelerator interface, descriptor-based execution, tile
> scheduling, data movement, scratchpad organisation, and compute datapath
> design.
>
> **Status:** Active development — dense and sparse schedulers, tile
> generators, transfer engine, and scratchpad subsystem complete and verified.
> Compute controller and end-to-end execution in progress.

---

## Research Question

> *How should a RISC-V CPU expose and control an accelerator capable of
> executing both dense and sparse matrix workloads — and what are the
> measurable architectural consequences of each execution mode in terms of
> computation, memory traffic, data movement, scheduling overhead, and
> scratchpad utilisation?*

This question is motivated by a real design decision in production AI
accelerators: **where in the hardware stack should sparsity awareness live?**
At the ISA level, at the descriptor level, or transparent to software entirely?
Each choice carries different costs in decode complexity, programmer model
expressiveness, and measured execution efficiency. This project builds the
hardware to measure those costs directly rather than estimate them analytically.

---

## Architectural Evolution

The accelerator architecture evolved through three deliberate phases, each
motivated by a concrete limitation in the previous design.

### Phase 1 — MMIO Accelerator

The initial implementation used memory-mapped control registers to initiate
accelerator operations from the RISC-V processor. This provided a functional
CPU-to-accelerator integration baseline but required all accelerator
configuration to be expressed through explicit register writes — producing
high instruction counts and exposing configuration detail directly to software.

### Phase 2 — RISC-V ISA Extension

The architecture was extended with a custom RISC-V instruction in the
`custom-0` opcode space (`opcode = 0001011`) to provide a processor-level
interface for accelerator dispatch:

| Instruction | funct3 | Format | Operand semantics |
|-------------|--------|--------|-------------------|
| `FMAC` | `000` | R-type | `rs1` = matrix A tile address, `rs2` = matrix B tile address, `rd` = result write address |
| `RELU` | `001` | R-type | `rs1` = input address, `rd` = output address |

**Format rationale:** both instructions require two independent
register-held addresses. R-type was chosen over I-type because I-type
provides only one register field plus an immediate — insufficient for
two-operand address-passing semantics. The use of `rd` as a result
*address* rather than a result *value* is a deliberate departure from
standard R-type convention, documented here to distinguish intent from
implementation error.

### Phase 3 — Descriptor-Driven Execution

As accelerator configuration grew more complex, the architecture was
restructured around a descriptor model. The accelerator instruction now
acts as an execution entry point — a lightweight CPU-visible reference —
while a memory-resident descriptor carries the full execution configuration:

- Source matrix addresses (A and B tile base pointers)
- Destination address (result write pointer)
- Sparse metadata address
- Matrix dimensions (M, N, K)
- Memory strides
- Element size and data type
- Execution mode flags (dense / sparse)

This separation decouples the software-visible accelerator command from the
internal hardware execution configuration, allowing the accelerator
microarchitecture to evolve independently of the ISA.

---

## System Architecture

```
RISC-V CPU
    │
    │  Accelerator instruction (FMAC / RELU)
    ▼
Descriptor Subsystem
    │
    ▼
Scheduler Engine
    │
    ├─────────────────────┐
    ▼                     ▼
Dense Scheduler      Sparse Scheduler
    │                     │
    ▼                     ▼
Dense Tile           Sparse Tile
Generator            Generator
    │                     │
    └──────────┬──────────┘
               ▼
        Transfer Engine
               │
               ▼
          Scratchpad
               │
               ▼
      Compute Controller
               │
               ▼
              MAC
```

---

## Execution Paths

### Dense Path

The dense scheduler controls tile traversal and produces tile requests
containing matrix addresses, tile dimensions, scratchpad bank assignments,
and transfer metadata. The transfer engine moves the required tile data into
the scratchpad. The compute controller then consumes the operands and
issues multiply-accumulate operations over the full tile.

### Sparse Path

The sparse path extends the tile-based architecture with compressed values
and metadata. The sparse tile generator produces:

- Compressed value addresses (2:4 format — 2 nonzero values per 4-element group)
- Metadata addresses (2-bit column indices per nonzero value)
- Destination addresses
- Tile dimensions and scratchpad bank assignments

The metadata decoder expands compressed weight groups to dense 4-element
vectors before they reach the MAC, allowing the same arithmetic primitive
to be reused for both execution modes. The metadata determines which MAC
operations are meaningful and which represent zero contributions that can
be skipped.

### Shared Compute Primitive

Dense and sparse execution share the same arithmetic datapath:

```
accumulator = accumulator + operand_A × operand_B
```

Dense execution enables the MAC for every valid matrix element.
Sparse execution uses metadata availability to gate individual MAC
operations — skipping zero-weight contributions without changing the
underlying arithmetic unit. This design allows a direct comparison of
dense and sparse execution under identical compute infrastructure.

---

## Module Status

| Module | Status | Description |
|--------|--------|-------------|
| RISC-V pipeline (5-stage) | ✅ Complete | RV32I with forwarding, hazard detection |
| Forwarding unit | ✅ Complete | EX/MEM→EX and MEM/WB→EX paths, x0 guard |
| Hazard detection unit | ✅ Complete | Load-use stall, correct priority ordering |
| Custom ISA decoder | ✅ Complete | FMAC / RELU in custom-0 opcode space |
| Descriptor fetch unit | ✅ Complete | SVA assertions written and verified |
| Dense scheduler | ✅ Complete | Tile traversal, bank assignment |
| Sparse scheduler | ✅ Complete | Compressed tile traversal |
| Dense tile generator | ✅ Complete | Regular tile request generation |
| Sparse tile generator | ✅ Complete | Compressed value + metadata requests |
| Transfer engine | ✅ Complete | Data movement into scratchpad |
| Scratchpad memory subsystem | ✅ Complete | Dual-port SRAM, controller |
| Scratchpad controller | ✅ Complete | Bank arbitration, access control |
| 2:4 metadata decoder | ✅ Complete | Formally verified, CocoTB coverage |
| MAC primitive | ✅ Complete | Shared dense/sparse arithmetic unit |
| Compute controller | 🔄 In progress | Dense and sparse MAC sequencing |
| Dense compute execution | 🔄 In progress | End-to-end dense path integration |
| Sparse metadata-driven execution | 🔄 In progress | Metadata-gated MAC integration |
| End-to-end verification | 🔄 In progress | RTL vs Python golden model |
| CPU-issued descriptor execution | 🔄 In progress | Full pipeline-to-accelerator path |

---

## Verification Strategy

Verification is performed incrementally at module and subsystem level,
using multiple complementary methods rather than relying on a single
technique.

### Directed self-checking tests
Targeted unit tests for specific module behaviors: back-to-back RAW
hazards, load-use stall timing, double-hazard cases (two writers to the
same destination register), ISA opcode boundary conditions (undefined
funct3 must not corrupt pipeline state).

### SVA formal verification — SymbiYosys
Safety properties proven exhaustively on bounded modules:

**Forwarding unit and hazard detection:**
- No RAW hazard escapes the pipeline under any input sequence
- Load-use stall fires if and only if `ID/EX.MemRead = 1`,
  `ID/EX.rd ≠ 0`, and `ID/EX.rd` matches `IF/ID.rs1` or `IF/ID.rs2`
- EX/MEM forwarding takes priority over MEM/WB when both match
  the same destination register

**2:4 metadata decoder (7 properties proven, 6 cover properties):**
- `val_0` placed at `dense_out[idx_0]` when pattern is valid
- `val_1` placed at `dense_out[idx_1]` when pattern is valid
- All non-selected lanes are strictly zero when pattern is valid
- `pattern_valid = (idx_0 < idx_1)` — exhaustively proven
- All 6 valid 2:4 patterns are reachable (cover properties)

**Descriptor fetch unit:**
- SVA assertions written and simulated (EDA Playground)
- SymbiYosys formal proof in progress

### CocoTB coverage-driven random testing
- **2:4 decoder:** 10,000 random input vectors verified against a NumPy
  golden reference — 0 mismatches, 6/6 pattern coverage confirmed
- **Scratchpad subsystem:** scoreboard comparing every read against a
  Python reference model — in progress
- **End-to-end:** RTL output vs Python golden matrix model — planned

### Gate-level simulation (planned)
Post-synthesis netlist simulation against existing CocoTB testbenches,
verifying that Yosys synthesis preserved functional behavior.

---

## Synthesis Results

| Module | Tool | Cells / LUTs | Critical path | Notes |
|--------|------|-------------|---------------|-------|
| 2:4 metadata decoder | Yosys | — | — | Pending |
| Forwarding unit | Yosys | — | — | Pending |
| Full pipeline + ISA ext. | Yosys | 6,846-line report | — | See `yosys_report_isa.txt` |
| FPGA implementation | Vivado (Artix-7) | — | — | Pending |

> **Note on OpenSTA:** Static timing analysis via OpenSTA was attempted but
> could not complete due to deep AST recursion in the matrix multiply unit
> (`mmul_mem.v`). This is a known synthesis-unfriendly coding pattern in the
> legacy module. OpenSTA will be re-run after the mmul unit is refactored.
> Raw Yosys synthesis output is available in `yosys_report_isa.txt`.

---

## Research Metrics

The dense-versus-sparse study will measure the following across identical
workloads on the same hardware infrastructure:

**Computation:**
- Total candidate MAC operations
- Useful MAC operations (non-zero contributions)
- Skipped MAC operations (zero-weight, metadata-gated)
- Arithmetic utilisation (useful MACs / total cycles)

**Memory:**
- Bytes transferred per tile (dense vs compressed)
- Metadata overhead as a fraction of total data volume
- Scratchpad read and write traffic per matmul

**Execution:**
- Total execution cycles (dense vs sparse path)
- Scheduling overhead cycles
- Data movement cycles
- Compute cycles

**Correctness:**
- RTL output vs Python golden model, element-by-element

---

## Known Limitations

This is an experimental research platform, not a production accelerator.
The following limitations are tracked explicitly and are separate from the
architectural research objective:

| Limitation | Impact |
|------------|--------|
| Simplified backpressure handling in some interfaces | Potential stalls under back-to-back transfers |
| No FIFO-based buffering between pipeline stages | Limits throughput under high-frequency dispatch |
| No complete compute arbitration | Single outstanding operation assumed |
| Simplified scratchpad architecture | No multi-bank conflict resolution yet |
| Compute engine still under development | End-to-end results not yet available |
| UVM-based memory subsystem verification deferred | Current coverage is CocoTB + formal only |
| OpenSTA timing analysis blocked on mmul refactor | Timing numbers pending |

---

## Project Organisation

```
riscv_accelerator_upgrade/
├── src/              # RTL source — SystemVerilog (.sv) and Verilog (.v)
│   ├── *.sv          # New modules — forwarding, hazard, ISA decoder,
│   │                 #   descriptor fetch, scratchpad, sparse decoder
│   └── *.v           # Legacy modules — pipeline stages, mmul
├── tb/               # Testbenches — CocoTB Python + SystemVerilog
├── build/            # Yosys synthesis scripts, simulation makefiles
├── constraints/      # Vivado XDC constraint files (Artix-7)
├── docs/             # Architecture notes, ISA encoding specification
├── results/          # Synthesis logs, coverage reports, timing output
├── scripts/          # Automation scripts
├── mem files/        # Instruction memory initialisation files
└── yosys_report_isa.txt  # Full Yosys synthesis log — ISA extension branch
```

### Branch Structure

| Branch | Description |
|--------|-------------|
| `main` | Stable baseline — MMIO accelerator |
| `scratchpad_dma` | Active development — custom ISA, descriptor system, sparse path |

---

## Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Yosys | — | RTL synthesis, gate-level netlist generation |
| OpenSTA | — | Static timing analysis (pending mmul refactor) |
| SymbiYosys | — | Formal verification — bounded model checking |
| CocoTB | — | Python-based RTL simulation and testbenches |
| Vivado | 2023.2 | FPGA implementation, power estimation (Artix-7) |
| GTKWave | — | Waveform debug |
| EDA Playground | — | SVA assertion simulation |

---

## Background

Design decisions in this project were informed by:

- Jouppi et al. — *In-Datacenter Performance Analysis of a Tensor Processing Unit* (ISCA 2017)
- NVIDIA A100 Architecture Whitepaper — 2:4 structured sparsity
- RISC-V ISA Specification — custom-0 / custom-1 opcode space
- CARRV 2022 — custom extension encoding trade-offs
- Williams, Waterman, Patterson — Roofline: An Insightful Visual Performance Model

---

*Sandesh R Gowda — Final year Electronics Engineering, BMS College of Engineering, Bengaluru*  
*Research interests: computer architecture · AI accelerator design · hardware–software co-design · design verification*  
*GitHub: [SandyGowda-op](https://github.com/SandyGowda-op)*
