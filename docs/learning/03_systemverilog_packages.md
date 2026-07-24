# Chapter 03 - SystemVerilog Packages

Version: 1.0

Project:
RV32I AI Accelerator Upgrade

Prerequisites

01 - Memory Design

02 - Packed vs Unpacked

Related Chapters

04 - Structs

05 - Enums

Modules Using This Concept

Descriptor Package

Descriptor Fetch Unit

DMA Controller

Descriptor Memory

---

# Learning Objectives

After completing this chapter you should be able to

✓ Explain why packages exist.

✓ Know what belongs inside packages.

✓ Import packages correctly.

✓ Understand compile order.

✓ Explain why packages do not generate hardware.

---

# 1. Introduction

As RTL projects grow larger, multiple modules begin sharing the same

- Constants
- Data structures
- Enumerations
- Functions

Duplicating these definitions across every file becomes difficult to
maintain.

Packages solve this problem.

---

# 2. What is a Package?

A package is a container that stores common definitions which can be shared
between multiple modules.

Think of it as a shared library for the project.

Packages improve

✓ Readability

✓ Reusability

✓ Maintainability

✓ Consistency

---

# 3. Basic Syntax

Package Definition

```systemverilog
package descriptor_pkg;

    parameter WIDTH = 32;

endpackage
```

Using the Package

```systemverilog
import descriptor_pkg::*;
```

Now every definition inside the package becomes available.

---

# 4. What Can Be Stored Inside Packages?

Packages commonly contain

✓ Parameters

✓ Local Parameters

✓ Structs

✓ Enums

✓ Functions

✓ Tasks

✓ Shared Constants

Packages should NOT contain

✗ always_ff

✗ always_comb

✗ assign statements

✗ Hardware logic

Packages describe the language used by the RTL.

They do not describe hardware.

---

# 5. Packages Do NOT Create Hardware

One of the most important concepts.

Packages exist only during compilation.

Example

parameter WIDTH = 32;

During synthesis

↓

The parameter is replaced with the value 32.

No hardware is created.

Similarly

typedef

enum

struct

all disappear before synthesis.

---

# 6. Compile Order

Packages must always be compiled before the modules that use them.

Correct

descriptor_pkg.sv

↓

descriptor_memory.sv

↓

descriptor_fetch_unit.sv

↓

dma_controller.sv

Incorrect

descriptor_fetch_unit.sv

↓

descriptor_pkg.sv

The compiler will fail because it does not yet know what
descriptor_t means.

---

# 7. Packages in Our Project

Current package

descriptor_pkg.sv

Contains

Parameters

Descriptor Structure

Enums

Datatype Definitions

Future additions

Status Codes

Flag Definitions

Utility Functions

DMA Error Codes

---

# 8. Why We Introduced Packages

Without packages

Every module would redefine

NUM_DESCRIPTORS

WORDS_PER_DESCRIPTOR

descriptor_t

datatype_t

Result

Duplicate code

Higher maintenance

Greater chance of mistakes

Packages eliminate this problem.

---

# 9. Industry Usage

Packages are heavily used in

Intel

AMD

NVIDIA

Apple

Qualcomm

OpenTitan

OpenHW

Most UVM environments begin with

```systemverilog
import uvm_pkg::*;
```

The same concept is applied in our project.

---

# 10. Common Beginner Mistakes

Mistake

Thinking packages create hardware.

Wrong.

Packages only exist during compilation.

----------------------------------

Mistake

Putting always_ff inside packages.

Wrong.

Packages should only contain shared definitions.

----------------------------------

Mistake

Compiling modules before packages.

Results in compiler errors.

----------------------------------

Mistake

Using packages for module-specific signals.

Packages should only contain information shared across modules.

---

# 11. How We Used Packages

We created

descriptor_pkg.sv

Purpose

Store all descriptor-related definitions in one location.

This allows every future module to share the same

Descriptor Format

Enums

Datatypes

Constants

without duplication.

---

# Interview Questions

1. Why were packages introduced?

2. Do packages generate hardware?

3. What can be stored inside packages?

4. Why must packages compile first?

5. Difference between package and module?

6. Why are packages important in large RTL projects?

7. What package is commonly imported in UVM?

---

# Key Takeaways

✓ Packages improve maintainability.

✓ Packages are compile-time constructs.

✓ Packages do not generate hardware.

✓ Packages are shared across modules.

✓ Packages reduce duplicate code.

✓ Packages improve readability.

---

# Revision Checklist

□ I know why packages exist.

□ I know what belongs inside a package.

□ I know packages do not create hardware.

□ I know why compile order matters.

□ I understand how descriptor_pkg.sv is used.