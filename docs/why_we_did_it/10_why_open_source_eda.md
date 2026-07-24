# Why We Chose an Open-Source EDA Flow

**Document ID:** WHY-010

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Problem Statement
3. Possible Design Approaches
4. Chosen Solution
5. Why an Open-Source EDA Flow Was Selected
6. Alternatives Considered
7. Trade-offs
8. Scalability
9. Industry Perspective
10. Future Improvements
11. Key Takeaways

---

# 1. Purpose

This document explains the reasoning behind adopting an **open-source Electronic Design Automation (EDA) flow** alongside traditional FPGA development tools for the AI Accelerator project.

While FPGA vendor tools remain essential for implementation on physical hardware, modern open-source EDA tools provide an accessible, transparent, and reproducible environment for RTL development, synthesis, simulation, and verification.

The objective is to create a workflow that encourages learning, portability, and engineering best practices.

---

# 2. Problem Statement

Developing a hardware accelerator requires several design stages, including:

- RTL development
- Functional simulation
- Synthesis
- Timing analysis
- Verification
- FPGA implementation

One option is to rely entirely on proprietary vendor software. Another is to use open-source tools wherever practical while reserving vendor tools only for FPGA-specific implementation.

The challenge is selecting a workflow that balances accessibility, flexibility, and real-world relevance.

---

# 3. Possible Design Approaches

Several development workflows were evaluated.

---

## Option 1 – Vendor-Only Toolchain

All development is performed using FPGA vendor software.

Typical flow:

```text
RTL

↓

Vendor Simulator

↓

Vendor Synthesizer

↓

Implementation

↓

Bitstream
```

---

## Option 2 – Open-Source Development Flow

Development uses open-source tools for design, simulation, synthesis, and verification.

Vendor tools are used only when FPGA implementation is required.

Typical flow:

```text
RTL

↓

Icarus Verilog / Verilator

↓

Cocotb

↓

Yosys

↓

OpenSTA

↓

Vendor Implementation
```

---

## Option 3 – Hybrid Development Flow

Use the strengths of both ecosystems.

Open-source tools support rapid development and verification.

Vendor software performs device-specific synthesis, placement, routing, and bitstream generation.

---

# 4. Chosen Solution

The project adopts a **Hybrid Open-Source EDA Flow**.

Development primarily relies on:

- Icarus Verilog
- Verilator
- Cocotb
- Yosys
- OpenSTA
- Git
- Visual Studio Code

Vendor FPGA tools are reserved for:

- Device synthesis
- Placement
- Routing
- Timing verification
- Bitstream generation
- FPGA programming

This combines portability with hardware deployment capability.

---

# 5. Why an Open-Source EDA Flow Was Selected

Several engineering considerations motivated this decision.

---

## Accessibility

Open-source tools are freely available.

Developers can:

- Install the complete toolchain on personal systems.
- Experiment without license restrictions.
- Collaborate more easily.
- Share projects with the community.

This makes the project easier to reproduce and maintain.

---

## Faster Development Cycle

Simulation and verification often iterate much faster using lightweight open-source simulators.

Advantages include:

- Faster compile times
- Quick debugging
- Automated scripting
- Efficient regression testing

This shortens the edit–compile–test cycle.

---

## Better Automation

Open-source tools integrate naturally with scripting and automation.

Examples include:

- Makefiles
- Python scripts
- Shell scripts
- Continuous Integration (CI)

This enables reproducible verification and regression workflows.

---

## Transparency

Many open-source EDA tools expose internal synthesis reports and optimization passes.

This allows developers to better understand:

- RTL transformations
- Logic optimization
- Resource mapping
- Timing behavior

The educational value is significantly higher than relying solely on proprietary tools.

---

## Portability

An open-source workflow is not tied to a single FPGA vendor.

Most RTL, verification scripts, and synthesis flows can be reused across multiple FPGA families with minimal changes.

---

## Strong Open-Source Ecosystem

The RISC-V ecosystem is built around openness.

Using open-source development tools complements this philosophy and encourages:

- Collaboration
- Community contributions
- Reproducible research
- Long-term maintainability

---

# 6. Alternatives Considered

## Vendor-Only Flow

Advantages:

- Official device support
- Mature implementation tools
- Integrated environment

Reasons not selected:

- Vendor lock-in
- Limited automation flexibility
- License restrictions
- Reduced portability
- Less transparent synthesis process

---

## Fully Open-Source Flow

Advantages:

- Maximum portability
- Completely reproducible
- Fully scriptable

Reasons not selected:

- FPGA implementation still requires vendor-specific support for many devices.
- Device programming and implementation tools are generally proprietary.
- Vendor timing reports remain important for final hardware validation.

A hybrid approach therefore provides the best balance.

---

# 7. Trade-offs

### Advantages

- Portable development environment
- Faster verification iterations
- Better automation
- Lower development cost
- Improved educational value
- Easier collaboration

---

### Limitations

- Multiple tools must be maintained.
- Workflow setup is more involved than using a single IDE.
- Tool outputs may differ slightly between synthesis engines.
- Final FPGA implementation still depends on vendor software.

These trade-offs are outweighed by the flexibility and transparency gained.

---

# 8. Scalability

The development flow supports future enhancements, including:

- Continuous Integration pipelines
- Automated regression testing
- Containerized development environments
- Cloud-based verification
- Automated documentation generation
- Static RTL analysis
- Linting tools
- Formal verification frameworks

The modular workflow allows individual tools to be upgraded without redesigning the overall process.

---

# 9. Industry Perspective

Modern hardware development increasingly combines proprietary and open-source tools.

Open-source EDA tools are widely used for:

- RTL simulation
- Verification
- Continuous Integration
- Academic research
- FPGA prototyping
- RISC-V development

Commercial organizations often integrate these tools into larger proprietary workflows to improve productivity and automation.

This project adopts the same philosophy by using open-source tools during development while leveraging vendor tools for FPGA deployment.

---

# 10. Future Improvements

Potential enhancements include:

- Automated CI/CD pipelines
- Docker-based development environments
- Formal verification integration
- Static lint checking
- Automatic timing regression reports
- Hardware-in-the-loop testing
- Multi-simulator support
- Automated documentation generation

These additions would further improve reproducibility and engineering efficiency.

---

# 11. Key Takeaways

- Open-source EDA tools improve accessibility, portability, and automation.
- Vendor FPGA tools remain essential for implementation on physical hardware.
- A hybrid workflow combines the strengths of both ecosystems.
- The development environment encourages reproducible engineering practices and collaborative development.
- The chosen workflow reflects modern hardware development practices adopted by the growing open-source silicon community.

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Documented the rationale for adopting a hybrid open-source EDA workflow for the AI Accelerator project. |

---

**END OF FILE**