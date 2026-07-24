# Why We Chose ReLU as the Activation Function

**Document ID:** WHY-006

**Version:** 1.0

**Status:** Active

**Project:** RISC-V AI Accelerator

---

# Table of Contents

1. Purpose
2. Problem Statement
3. Possible Design Approaches
4. Chosen Solution
5. Why ReLU Was Selected
6. Alternatives Considered
7. Trade-offs
8. Scalability
9. Industry Perspective
10. Future Improvements
11. Key Takeaways

---

# 1. Purpose

This document explains the architectural reasoning behind selecting the **Rectified Linear Unit (ReLU)** as the activation function implemented in the AI Accelerator.

While matrix multiplication forms the computational core of neural network inference, activation functions introduce the non-linearity required for neural networks to model complex relationships.

This document explains why ReLU was selected instead of other commonly used activation functions.

---

# 2. Problem Statement

After matrix multiplication, the resulting values must pass through an activation function before being used by subsequent neural network layers.

The chosen activation function should:

- Be computationally efficient
- Require minimal hardware resources
- Support high throughput
- Introduce non-linearity
- Be easily pipelined
- Scale to larger workloads

The challenge is balancing hardware complexity with machine learning effectiveness.

---

# 3. Possible Design Approaches

Several activation functions were considered.

---

## Option 1 – No Activation

The accelerator outputs the raw matrix multiplication results.

```
Matrix Engine

↓

Output
```

---

## Option 2 – Sigmoid

Applies the sigmoid function.

```
Output

=

1

────────────

1 + e^(-x)
```

---

## Option 3 – Hyperbolic Tangent (Tanh)

Produces outputs between -1 and +1.

```
Output

=

tanh(x)
```

---

## Option 4 – Rectified Linear Unit (ReLU)

Outputs the input if it is positive.

Otherwise outputs zero.

```
Output

=

max(0, x)
```

---

# 4. Chosen Solution

The accelerator implements the **Rectified Linear Unit (ReLU)**.

The activation operation is performed immediately after matrix multiplication and before the DMA writes results back to memory.

Execution flow:

```text
DMA

↓

Scratchpad

↓

Matrix Engine

↓

ReLU

↓

DMA Write-back
```

---

# 5. Why ReLU Was Selected

Several engineering considerations motivated this decision.

---

## Extremely Simple Hardware

ReLU requires only a comparison operation.

Hardware implementation:

```text
if (x < 0)

output = 0;

else

output = x;
```

Unlike many activation functions, ReLU does not require:

- Division
- Exponentiation
- Floating-point arithmetic
- Lookup tables
- Polynomial approximations

This makes it ideal for FPGA implementation.

---

## High Throughput

The comparison operation completes quickly.

The ReLU stage can be fully pipelined, allowing one activation result to be produced every clock cycle after pipeline fill.

---

## Minimal FPGA Resource Usage

Compared to more complex activation functions, ReLU requires:

- Few LUTs
- Very few registers
- No DSP slices
- No BRAM

This leaves FPGA resources available for the Matrix Engine.

---

## Easy Verification

Expected outputs are straightforward to compute.

Examples:

```
Input =  25

Output = 25
```

```
Input = -17

Output = 0
```

This simplicity makes:

- Directed testing
- Golden Model comparison
- Assertion-Based Verification

much easier.

---

## Natural Pipeline Integration

The ReLU stage fits naturally after matrix multiplication.

The Matrix Engine generates output values.

Each value immediately enters the ReLU stage.

Results are then forwarded for write-back.

This keeps data moving continuously through the accelerator pipeline.

---

# 6. Alternatives Considered

## No Activation

Advantages:

- Simplest hardware
- Zero additional latency

Reasons not selected:

- Neural networks require non-linear activation functions.
- Linear operations alone cannot represent many practical machine learning models.

---

## Sigmoid

Advantages:

- Widely used historically
- Produces bounded outputs

Reasons not selected:

- Requires exponential computation
- High hardware complexity
- Increased latency
- Larger area
- Difficult FPGA implementation

---

## Tanh

Advantages:

- Zero-centered output
- Common in recurrent neural networks

Reasons not selected:

- Complex arithmetic
- Larger hardware footprint
- Higher verification complexity
- Increased power consumption

---

# 7. Trade-offs

### Advantages

- Extremely simple RTL
- Low latency
- High throughput
- Minimal FPGA resource utilization
- Easy verification
- Excellent pipeline compatibility

---

### Limitations

- Outputs are always non-negative.
- Less suitable for some neural network architectures.
- Does not address issues such as dead neurons.
- More advanced models may require different activation functions.

For the goals of this project, these limitations were acceptable.

---

# 8. Scalability

The activation stage is intentionally modular.

Future versions may support:

- Leaky ReLU
- Parametric ReLU (PReLU)
- GELU
- Sigmoid
- Tanh
- ReLU6
- Softmax (implemented separately)

Activation selection could be controlled through descriptor fields or MMIO configuration registers without modifying the Matrix Engine.

---

# 9. Industry Perspective

ReLU is one of the most widely implemented activation functions in AI hardware.

Commercial AI accelerators often include dedicated activation units because:

- They reduce CPU involvement.
- They maintain continuous dataflow.
- They minimize additional hardware cost.
- They improve overall inference throughput.

Many modern AI processors support ReLU directly in hardware while offering optional support for additional activation functions.

Our project follows the same philosophy by separating computation from activation.

---

# 10. Future Improvements

Potential enhancements include:

- Configurable activation selection
- Multiple activation pipelines
- Parameterized activation modules
- Approximate activation functions
- Quantized activation support
- Runtime activation configuration
- Hardware support for mixed-precision activations

These additions would broaden the accelerator's applicability while preserving the modular architecture.

---

# 11. Key Takeaways

- ReLU introduces the non-linearity required for neural network inference.
- It is extremely simple to implement in hardware.
- The activation stage integrates naturally into the accelerator pipeline.
- ReLU minimizes FPGA resource utilization while maintaining high throughput.
- The modular design allows future activation functions to be added without redesigning the Matrix Engine.

---

# Revision History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Initial | Documented the rationale for selecting ReLU as the activation function for the AI Accelerator. |

---

**END OF FILE**