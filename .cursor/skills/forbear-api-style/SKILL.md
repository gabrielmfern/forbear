---
name: forbear-api-style
description: Writes Zig that matches Forbear's actual API shape: frame-driven UI mounting, stable component keys, lifecycle-aware hooks, explicit ownership, direct control flow, and minimal abstractions. Use when changing `src/**/*.zig`, public API, components/hooks, layout, rendering, resources, tests, or platform wrappers.
---

# Forbear API Style

## Use This Skill When

- Working on any non-trivial Zig change in Forbear
- Adding or changing `component`, `useX`, `registerX`, `element`, `text`, or `image` APIs
- Changing style/state modeling, layout behavior, rendering, tests, or platform code
- Reviewing whether a new abstraction actually fits the current codebase

## Read This First

Before inventing a pattern, read the nearest precedent:

- `AGENTS.md` for architecture, repo layout, tests, and naming/formatting conventions
- `src/root.zig` for frame lifecycle, hooks, resource APIs, and the public surface
- `src/node.zig` for the style/data model
- `src/layouting.zig` for sizing/wrapping/grow-shrink behavior
- `playground.zig` for the end-to-end frame -> layout -> draw -> update loop
- `src/tests/utilities.zig` when writing layout or frame tests

Do not duplicate general conventions from `AGENTS.md`; use this skill for design shape and repo-native API patterns.

## Design Priorities

Optimize in this order:

1. Correctness and explicit invariants
2. Performance-aware design
3. Developer experience through plain, legible code

## Repo-Native API Rules

- Model UI as a frame-mounted tree plus keyed component state, not as an object graph with hidden mutation.
- Keep `component("stable-key")` scopes obvious. Stateful hooks belong inside a component scope.
- Keep `useX` helpers narrow and lifecycle-aware. They should fail clearly outside valid frame/component context.
- Use `registerX` for long-lived resources and `useX` for lookup/use within a frame.
- Prefer struct literals and tagged unions over builder-style setup when the literal is already readable.
- Expose the smallest public API that preserves explicit ownership, allocation, and hot-path cost.
- Re-export user-facing API from `src/root.zig` when it improves discoverability.
- Keep control flow direct. Early returns and local conditionals are preferred over indirection.

## Concrete Patterns To Follow

### Component + hook scope

Use the same block-scoped pattern that `src/root.zig`, `src/components.zig`, and `playground.zig` use:

```zig
fn App() !void {
    forbear.component("app")({
        const isHovering = try forbear.useState(bool, false);

        forbear.element(.{
            .width = .grow,
        })({
            while (forbear.useNextEvent()) |event| {
                switch (event) {
                    .mouseOver => isHovering.* = true,
                    .mouseOut => isHovering.* = false,
                }
            }
        });
    });
}
```

What matters:

- The key must stay stable across frames.
- Hook order must stay stable across frames.
- Hooks should not be callable in "mystery" contexts.

### Resource registration vs use

Match the existing long-lived resource pattern:

```zig
try forbear.registerFont("Inter", @embedFile("Inter.ttf"));

const baseStyle: forbear.BaseStyle = .{
    .font = try forbear.useFont("Inter"),
    .color = .{ 1.0, 1.0, 1.0, 1.0 },
    .fontSize = 32,
    .fontWeight = 400,
    .lineHeight = 1.0,
    .textWrapping = .character,
    .blendMode = .normal,
    .cursor = .default,
};
```

Do not collapse registration and lookup into a "magic" convenience API unless the change clearly improves the existing model.

### Style and data modeling

Prefer the same split Forbear already uses:

- partial user input in `IncompleteStyle`
- resolved runtime state in `Style`
- explicit enums/tagged unions for sizing and other variants

If user input and resolved runtime state have different responsibilities, keep them separate.

### Layout logic

When editing layout behavior:

- preserve the current flexbox-like mental model: parent direction decides the main axis
- make grow/shrink/ratio/percentage behavior explicit
- keep manual-placement nodes out of normal flow
- prefer assertions and focused helper functions over a generic "layout engine" abstraction

### Test shape

When adding layout or frame tests, use the existing helper instead of rebuilding setup by hand:

```zig
var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
defer arenaAllocator.deinit();

try forbear.frame(try utilities.frameMeta(arenaAllocator.allocator()))({
    forbear.element(.{
        .width = .{ .fixed = 100 },
        .height = .{ .fixed = 100 },
    })({});

    const root = try forbear.layout();
    try std.testing.expectEqual(@as(f32, 100), root.size[0]);
});
```

## Anti-Patterns

- Large manager-style APIs with unrelated responsibilities
- Convenience helpers that hide allocation, traversal, caching, or persistent ownership on hot paths
- Multiple mutable sources of truth for the same state
- Builder patterns for values that are already clearer as struct literals
- Clever abstractions that blur frame/component lifecycle boundaries
- Re-stating generic style conventions that already live in `AGENTS.md`

## Output Expectations

When using this skill to propose or write code:

1. State the design in one short paragraph.
2. Mention the key invariant, lifecycle constraint, or ownership choice.
3. Show compact code that matches repo patterns.
4. For public API changes, include a realistic usage example that looks like `playground.zig` or `examples/uhoh.com`.
5. If you borrow an idea from a stricter systems style, adapt it to Forbear instead of forcing it unchanged.

## Validation

- Run `zig fmt` on touched Zig files.
- Run `zig build check` when the change affects public API, examples, or broad compilation behavior.
- Run `zig build test -- --test-filter="..."` when changing tests or layout/state behavior and a focused filter is practical.

## Additional Reference

- See `reference.md` for repo-specific examples and quick copyable patterns.
