---
name: forbear-framework-api-design
description: Designs and evolves Forbear's internal and public framework APIs: hooks, node/style data models, layout behavior, rendering entrypoints, resource registration, and platform abstractions. Use when editing `src/**/*.zig`.
---

# Forbear Framework API Design

## Use This Skill When

- Changing framework code under `src/**/*.zig`
- Adding or revising hooks such as `useX`
- Changing public API exported from `src/root.zig`
- Revising `Node`, `Style`, `IncompleteStyle`, sizing, layout, rendering, or platform boundaries
- Deciding whether a new abstraction fits the framework itself

## Read This First

Before inventing a pattern, read the nearest precedent:

- `AGENTS.md` for architecture, repo layout, tests, and conventions
- `src/root.zig` for frame lifecycle, hooks, resources, and public API shape
- `src/node.zig` for the style/data model
- `src/layouting.zig` for layout invariants and helper structure
- `src/graphics.zig` for rendering boundaries
- `src/tests/utilities.zig` and `src/tests/*.test.zig` for test setup and expectations

## Design Priorities

Optimize in this order:

1. Correctness and explicit invariants
2. Performance-aware design
3. Developer experience through plain, legible code

## Framework Design Rules

- Model UI as a frame-mounted node tree plus retained component state keyed across frames.
- Keep lifecycle boundaries obvious: frame-only helpers should fail outside a frame; component hooks should fail outside a component scope.
- Prefer the smallest public surface that keeps ownership, allocation, and hot-path cost visible.
- Re-export user-facing API from `src/root.zig` when it improves discoverability.
- Keep one authoritative source of truth. If duplication exists for performance, make the derived copy obvious.
- Prefer direct control flow, explicit state transitions, and explicit bounds over hidden behavior.

## Patterns To Follow

### Hooks and component state

- `component("stable-key")` establishes the state scope.
- `useState`-style hooks depend on stable ordering.
- If a helper is lifecycle-bound, make that constraint obvious in the API and in failure behavior.
- Keep `useX` helpers narrow. Do not turn them into general-purpose service locators.

### Public API shape

- Prefer short verbs for operations and `registerX` / `useX` pairs when the code is separating persistent ownership from frame-time lookup.
- Prefer small structs or tagged unions over long positional argument lists.
- If user input and resolved runtime state have different responsibilities, keep a split like `IncompleteStyle` vs `Style`.

### Layout and rendering internals

- Preserve the current flexbox-like mental model unless the task explicitly changes it.
- Keep manual-placement nodes out of standard flow.
- Prefer focused helpers with strong local invariants over a generic "engine" abstraction.
- Avoid convenience layers that hide traversal, allocation, or extra caching on hot paths.

### Tests

- Use `src/tests/utilities.zig` helpers rather than rebuilding frame setup by hand when practical.
- Add tests close to the behavior being changed.
- Assert on concrete geometry/state invariants, not only on "did not error".

## Anti-Patterns

- Large manager-style APIs with unrelated responsibilities
- Hidden allocation or caching on hot paths
- Multiple mutable sources of truth for the same concept
- Builder patterns where a struct literal is already clearer
- Clever abstractions that blur frame/component lifecycle boundaries
- Copying patterns from unrelated frameworks when existing Forbear code already has a better local precedent

## Output Expectations

When using this skill to write or propose code:

1. State the invariant or boundary the API is preserving.
2. Explain the ownership or lifecycle choice when it matters.
3. Show realistic code close to `src/root.zig`, `src/node.zig`, or `src/layouting.zig`.
4. For public API changes, show a small usage example that looks like `playground.zig` or `examples/uhoh.com`.

## Validation

- Run `zig fmt` on touched Zig files.
- Run `zig build check` when the change affects API shape, examples, rendering, or compilation breadth.
- Run a focused `TEST_FILTER="..." zig build test` when changing layout, hooks, or tested state behavior.

## Additional Reference

- See `reference.md` for copyable framework-side patterns.
