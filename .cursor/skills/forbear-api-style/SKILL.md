---
name: forbear-api-style
description: Writes Zig to match Forbear's style: small composable APIs, explicit ownership, visible cost, direct control flow, lifecycle-aware helpers, strong invariants, and repo-native naming and module structure. Use when adding or refactoring Forbear code, especially public API, style/state modeling, layout logic, frame hooks, resource registration, tests, or C/platform wrappers.
---

# Forbear Code Style

## Use This Skill When

- Working in `forbear` on any non-trivial Zig change
- Adding or revising hook-style helpers such as `useX`
- Designing style/config data like `IncompleteStyle`, `Style`, or tagged unions
- Changing layout, rendering, resource registration, tests, or foreign API wrappers
- Reviewing whether a new abstraction actually fits the existing codebase

## Design Priorities

Optimize in this order:

1. Correctness and clear invariants
2. Performance-aware design
3. Developer experience through plain, legible code

This is inspired by stricter systems styles, but adapted to Forbear's actual codebase rather than copied literally.

## Quick Workflow

1. Read the nearest precedent before inventing a new pattern.
   - Start with `src/root.zig`, `src/node.zig`, and `src/layouting.zig`.
   - Check `src/font.zig` or `src/window/*.zig` when the change crosses a C or platform boundary.
2. State the invariant or design intent before settling on an implementation.
3. Keep the public surface smaller than the internal machinery.
4. Make ownership, allocation, and hot-path cost visible in the API shape.
5. Prefer the plain, established naming pattern over a novel abstraction.
6. Validate with formatting and at least one relevant build or test command before finishing.

## Default Design Rules

- Re-export user-facing API from `src/root.zig` when that makes the surface clearer.
- Prefer a small struct or tagged union over a long positional parameter list.
- Split partial user input from resolved runtime state when they have different responsibilities.
- Keep one authoritative copy of state. If duplication exists for performance, document which copy is derived.
- Use short nouns for types and short verbs or verb phrases for functions.
- Keep `useX` helpers narrow and lifecycle-aware. They should fail clearly outside their valid context.
- Use `registerX` for persistent resource registration and plain verbs for direct operations.
- Keep control flow direct: early assertions, early returns, and local `if`/`switch` logic beat indirection.
- Prefer explicit bounds, explicit error handling, and explicit state transitions over hidden behavior.
- Use assertions for programmer errors and invariants when they make the code safer and easier to reason about.
- Comments should explain a non-obvious rule, lifecycle constraint, or implementation choice, not narrate obvious code.

## Conventions To Follow

- Follow the repo's actual naming style: `camelCase` for functions and variables, PascalCase for types, `snake_case.zig` for files.
- Pass allocators explicitly when ownership is real.
- Use stable defaults in struct fields instead of scattering them through control flow.
- Prefer local variables with tight scope. Introduce values close to where they are used.
- Keep hot loops and per-frame work easy to see and cheap to reason about.

## Patterns To Prefer

- Central re-exports for the public surface
- Defaults in struct fields when they are stable
- Small methods that clarify a type, such as `completeWith`, `from`, `get`, `withInLine`, or `withBlock`
- Explicit error translation at foreign boundaries
- Assertions or sanity checks around surprising invariants
- Tests that assert invariants and lifecycle behavior with minimal fixtures

## Anti-Patterns

- Giant manager-style APIs with unrelated responsibilities
- Deep namespace layering for common operations
- Convenience APIs that hide allocation, copying, traversal, or caching on the hot path
- Multiple mutable sources of truth for the same concept
- Builder patterns for values that are already readable as struct literals
- Clever abstractions that blur lifecycle boundaries
- Importing external style rules wholesale when they conflict with existing Forbear code

## Output Expectations

When using this skill to propose or write code:

1. Briefly state the design in one short paragraph.
2. Show compact, realistic code.
3. Mention the key invariant, ownership choice, or performance constraint when it matters to the design.
4. Include a realistic usage example for public API changes.
5. If borrowing an idea from a stricter systems style, adapt it to Forbear instead of enforcing it blindly.

## Validation

- Run `zig fmt` on touched Zig files.
- Run `zig build check` when the change affects public API, examples, or broad compilation behavior.
- Run `zig build test -- --test-filter="..."` when changing tests or layout/state behavior and a focused filter is practical.

## Additional Reference

- See `reference.md` for repo-specific examples and more detailed guidance.
