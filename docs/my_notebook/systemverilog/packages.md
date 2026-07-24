# SystemVerilog Masterclass 01

# Packages

---

## Why were packages invented?

Large RTL projects contain hundreds or thousands of files.

Without packages:

- Constants are duplicated.
- Data types are duplicated.
- Enumerations become inconsistent.
- Bugs become difficult to track.

Packages solve this by creating a single location for shared
definitions.

---

## Compile-Time Concept

Packages DO NOT become hardware.

They disappear after compilation.

They only help the compiler understand the design.

---

## What belongs inside a package?

✓ Parameters

✓ Local parameters

✓ Typedefs

✓ Structures

✓ Enumerations

✓ Functions

✓ Tasks

✓ Shared constants

---

## Example

```systemverilog
package descriptor_pkg;

parameter NUM_DESCRIPTORS = 128;

endpackage
```