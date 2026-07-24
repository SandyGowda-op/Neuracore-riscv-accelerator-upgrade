# Why did we use a Shadow Register?

Question

Why didn't we expose the descriptor directly to DMA?

Alternatives

Option A

Direct update

Pros

Smaller hardware

Cons

DMA observes partially valid descriptors.

------------------------------------------------

Option B

Working Descriptor

Pros

Atomic updates

Stable interface

Better verification

Chosen

Option B

Reason

Industrial DMA engines typically separate descriptor construction
from descriptor publication.

Lessons

Good hardware is not only fast.

It is predictable.

Interview Question

What is an atomic register update?

Answer

A complete update that becomes visible in one operation instead
of multiple partial updates.