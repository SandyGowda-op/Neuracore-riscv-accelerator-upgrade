# Engineering Notebook

Topic

Descriptor Fetch Unit

---

# Why does this block exist?

Initially the DMA was expected to directly read descriptor memory.

After analysing the architecture we realised that this tightly coupled DMA
execution with descriptor storage.

Instead, an intermediate Descriptor Fetch Unit was introduced.

This separated

Software

↓

Descriptor Storage

↓

Execution

The resulting architecture became significantly cleaner.

---

# Major Lesson

Never allow software-visible data structures to become tightly coupled with
execution hardware.

Introduce translation layers.

---

# Biggest Design Mistake Avoided

Originally a Fetch Buffer was proposed.

Memory

↓

Fetch Buffer

↓

Descriptor

↓

DMA

After analysis it became clear that the descriptor format is fixed.

Therefore the Fetch Buffer added unnecessary latency and hardware.

It was removed.

Lesson

Good architecture often removes hardware instead of adding it.

---

# Biggest Optimization

Originally

Issue

Capture

Issue

Capture

...

Latency

21 clocks

After analysing synchronous memories we realised that reads could be pipelined.

Capture Word N

+

Issue Word N+1

This reduced latency to approximately 11 clocks.

Lesson

Always search for pipeline opportunities.

---

# Shadow Register Lesson

One of the most important architectural decisions.

Instead of exposing partially fetched descriptors to the DMA Controller,
the DFU maintains an internal Working Descriptor.

Once all fields have been received, the Working Descriptor is copied into
Descriptor Output Register.

The DMA therefore observes only complete descriptors.

This design pattern appears in

CPU pipelines

Cache controllers

DMA engines

Network interfaces

Configuration registers

This is known as

Atomic Commit

or

Shadow Register Architecture.

---

# Personal Reflection

The transition from thinking

"What hardware do I need?"

to

"What hardware can I remove?"

was the first moment I started thinking like a hardware architect rather than
simply an RTL designer.

This lesson should be remembered throughout future accelerator development.
