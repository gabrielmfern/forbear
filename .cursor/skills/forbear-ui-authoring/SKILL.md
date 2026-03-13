---
name: forbear-ui-authoring
description: Writes application UI with Forbear's public API: frame loops, components, hooks, elements, text, images, events, and resource usage. Use when editing `playground.zig` or example app code under `examples/**/src/**`.
---

# Forbear UI Authoring

## Use This Skill When

- Writing app or example code that consumes Forbear
- Editing `playground.zig`
- Editing UI code under `examples/**/src/**/*.zig`
- Building reusable app-level components on top of `forbear.component`, `element`, `text`, `image`, and hooks

## Read This First

Start with:

- `AGENTS.md` for architecture, testing layout, and repo conventions
- `playground.zig` for the canonical frame -> layout -> draw -> update loop
- `examples/uhoh.com/src/main.zig` for a larger real app
- `examples/uhoh.com/src/components/button.zig` for a realistic stateful component
- `src/components.zig` for a small built-in component example

## Mental Model

Forbear app code is written as:

1. register resources up front,
2. start a frame,
3. mount a tree of elements/components/text/images,
4. call `forbear.layout()`,
5. render with `drawFrame(...)`,
6. call `forbear.update()` to advance events, hover state, scrolling, and animations.

You are writing code against the public API, not extending the framework internals. Prefer clear composition of existing primitives over creating a new abstraction.

## Patterns To Follow

### Frame loop

- Register fonts and images before the main loop.
- Reuse an arena allocator per frame and reset it between iterations.
- Keep the frame body ordered as: mount UI -> `layout()` -> `drawFrame(...)` -> `update()`.

### Components and hooks

- Put stateful logic inside `forbear.component("stable-key")({ ... })`.
- Keep hook order stable across frames.
- Use `useState` for local retained state, `useTransition` / `useAnimation` for motion, and `useNextEvent()` to consume events for the current element/component.
- Keep component keys stable and explicit.

### Building UI trees

- Use nested `forbear.element(.{ ... })({ ... })` calls as the default composition pattern.
- Use `forbear.text(...)` for text nodes and `forbear.image(...)` when you want image-aware sizing convenience.
- Prefer struct literals for style configuration.
- Treat `.placement = .manual` as opt-out from normal flow, not as a general layout shortcut.

### Resources

- Use `registerFont` / `registerImage` for startup registration.
- Use `useFont` / `useImage` during frame work.
- Do not add extra caching or ownership layers in app code unless the task clearly needs it.

## Common Pitfalls

- Calling hooks outside a frame or outside a component scope
- Using unstable component keys
- Calling hooks conditionally in a way that changes ordering across frames
- Forgetting that `forbear.frame`, `element`, and `component` all use the `({ ... })` end-function pattern
- Expecting manual-placement children to participate in grow/shrink layout flow

## Output Expectations

When using this skill to write or propose code:

1. Keep examples close to `playground.zig` or `examples/uhoh.com`.
2. Show concrete `forbear.*` calls rather than abstract pseudocode.
3. Mention the relevant lifecycle rule when hooks or events are involved.
4. Prefer a small reusable component over a framework-like abstraction in app code.

## Validation

- Run `zig fmt` on touched Zig files.
- Run `zig build check` when the app/example change affects compilation or public usage shape.
- Run a focused `zig build test -- --test-filter="..."` only when the change also touches shared logic with existing tests.

## Additional Reference

- See `reference.md` for copyable app-side patterns.
