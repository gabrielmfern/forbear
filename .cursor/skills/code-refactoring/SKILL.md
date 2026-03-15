# Code Refactoring Principles

When refactoring code, **EXPLICITLY REJECT** traditional "Clean Code" trademarks, "Clean Architecture", and excessive SOLID dogmas. Refactoring is NOT about extracting 5-line functions, creating shallow modules, or hiding everything behind layers of abstraction and indirection. Instead, base refactoring decisions on reducing cognitive load, semantic compression, and acknowledging that duplication is often better than the wrong abstraction.

Follow these core principles when analyzing, writing, and refactoring code:

## 1. Cognitive Load is What Matters
* **Optimize for working memory:** The hardest part of programming is the cognitive load required to understand a system. Avoid creating unnecessary abstractions, complex conditionals, and unique mental models that a reader must hold in their head.
* **Deep Modules over Shallow Modules:** A module/class/function should have a simple interface but a deep implementation. Having 80 tiny, shallow classes with simple implementations but complex inter-dependencies creates massive cognitive load. Hide complexity, don't just shift it into glue code.
* **Early Returns:** Use early returns to reduce nested `if` statements. Keep the happy path at the top level so the reader doesn't have to keep a stack of preconditions in their head.
* **Composition over Inheritance:** Avoid inheritance chains where logic is spread across `BaseController`, `GuestController`, and `AdminController`. It's a cognitive nightmare to trace.
* **Boring is Good:** A standard, boring procedural flow is often much easier to understand than a "clever" framework-heavy or layered architecture with endless indirection.

## 2. Semantic Compression (Casey Muratori)
* **Procedural First:** Code is inherently procedural. Don't start by designing "objects", "UML diagrams", or "responsibilities". Write simple, procedural code that gets the job done inline.
* **Usable before Reusable:** Always make your code usable for the specific case at hand before you try to make it reusable.
* **The "Rule of Two":** Do not abstract or reuse code until you have *at least two* concrete, working instances of it. Premature abstraction leads to incorrect boundaries and wasted time.
* **Bottom-Up Compression:** "Refactoring" should be like dictionary compression. When you see two or more identical patterns of procedural code, "compress" them by extracting shared state (e.g., pulling local variables into a shared struct/stack frame) and shared logic. This ensures your abstractions perfectly fit the real-world usage rather than an imagined architecture.

## 3. The WET Codebase (Dan Abramov) & Duplication vs. Abstraction
* **"Write Everything Twice":** A little copying is better than a little dependency. DRY (Don't Repeat Yourself) is often abused.
* **Avoid the Wrong Abstraction:** If you extract code to avoid duplication, but later find that new use cases require adding boolean flags, special cases, and complex `if` statements inside the abstraction, **stop**. 
* **Inline the Abstraction:** The cure for the wrong abstraction is to inline it (copy-paste it back to the callers). De-duplicate later only when a truer, more stable shared pattern emerges. Duplication is far cheaper and less damaging than a monstrous, heavily parameterized abstraction.

## 4. Write Code That Is Easy To Delete (tef)
* **Disposable over Reusable:** Reusable code is hard to change because every consumer is coupled to its API and quirks. Code that is highly specific to a single task is disposable—it is easy to delete when requirements change.
* **Layer and Isolate:** Build simple-to-use APIs out of simpler pieces. Isolate the parts of the code that are hard to write and likely to change. When deleting code lowers maintenance costs, you are on the right track.

When refactoring, your goal is to make the codebase easier to read top-to-bottom, less coupled, and closer to the raw problem domain. Do not add abstractions for the sake of "architecture"—only add them to compress proven duplication and hide domain complexity.
