---
name: forbear-internals
description: Guidelines for developing the Forbear framework internals. Use when editing core UI nodes, layout code (`layouting.zig`), rendering (`graphics.zig`), shaders, window backends, and writing framework tests under `src/tests/`.
---

# Forbear Internals Guidelines

## Component, Hook, And Resource Patterns (Internal)

### Frame lifecycle

- `forbear.frame(meta)` installs per-frame context such as the arena allocator, viewport size, DPI, and base style.
- `FrameMeta.rootNode` starts as `null` and is filled by `element`/`text`.
- `forbear.layout()` and `forbear.update()` are expected to run inside the frame body after mounting finishes.

### Components and hooks

- Wrap stateful UI in `forbear.component("stable-key")({ ... })`.
- Hooks such as `useState`, `useArena`, `useAnimation`, `useTransition`, and `useNextEvent` depend on frame/component context.
- Hook ordering matters. `componentEnd` checks that the number of `useState` calls stays stable across frames and raises `error.RulesOfHooksViolated` otherwise.
- Component state is keyed by both the explicit component key and the current node path, so stable structure matters.

### Node construction

- `forbear.element(style)({ ... })` pushes an element node and establishes a parent for child nodes.
- `forbear.text("...")` shapes text and inserts a glyph-backed node.
- `forbear.image(style, img)` is a convenience wrapper over `element` that fills in aspect-ratio-aware sizing and background image state.
- Standard-placement children participate in layout flow; `.placement = .manual` children stay out of that flow.

### Resources

- `registerFont` / `registerImage` are for long-lived resource registration.
- `useFont` / `useImage` assume registration already happened and return errors if the identifier is missing.
- In tests, helpers usually register the `Inter` font once and then build `FrameMeta` around it.

## Testing Structure

Tests are not stored in a top-level `tests/` directory. The current pattern is:

- `src/root.zig` contains a final `test { ... }` block that imports the test modules under `src/tests/`.
- Individual test cases live in `src/tests/*.test.zig`.
- Shared test helpers live in `src/tests/utilities.zig`.

The most important helper is `utilities.frameMeta(arena)`, which:

- registers the embedded `Inter` font,
- builds a realistic `forbear.FrameMeta`,
- sets default DPI, viewport size, and base style,
- gives layout tests a ready-made frame context.

For layout tests, the usual pattern is:

1. Create an arena allocator.
2. Call `forbear.frame(try utilities.frameMeta(arena))({ ... })`.
3. Mount nodes with `element`, `text`, or `component`.
4. Call `try forbear.layout()`.
5. Assert on node size/position or wrapped glyph output.

`zig build check` only verifies compilation. It does **not** run tests.

### Running Focused Tests

Zig's build step runs the module test binary, but test filters still work:

```bash
# Run tests whose names contain a substring
TEST_FILTER="layout" zig build test

# Example: run the layout pipeline tests
TEST_FILTER="layout pipeline" zig build test
```

## Code Style Guidelines

### Imports

Group imports in this order with blank lines between groups:

1. Standard library: `const std = @import("std");`
2. Built-ins: `const builtin = @import("builtin");`
3. External dependencies: `const zmath = @import("zmath");`
4. Internal modules: `const Font = @import("font.zig");`

### Naming

| Element | Convention | Example |
|---------|------------|---------|
| Types/Structs | PascalCase | `LayoutBox`, `DeviceInformation` |
| Functions | camelCase | `initRenderer`, `findMemoryType` |
| Variables | camelCase | `vulkanInstance`, `physicalDevice` |
| Constants | camelCase | `maxFramesInFlight`, `maxImages` |
| Files | snake_case.zig | `graphics.zig`, `font.zig` |
| C interop | Match C naming | `c.VkInstance`, `c.FT_Face` |

### Type and module patterns

- Use `@This()` for self-referential struct methods.
- Define vector aliases, error sets, and core types near the top of the file.
- Keep public fields and public functions before private helpers when the file centers on one primary type.
- Prefer tagged unions or small structs over long positional parameter lists.

### Error handling and cleanup

- Define explicit subsystem error sets where the boundary matters.
- Translate foreign-library errors at the boundary.
- Use `errdefer` aggressively for Vulkan/FreeType/resource cleanup.
- Keep `init` / `deinit` pairs obvious and symmetrical.

### Memory management

- Pass allocators explicitly when ownership is real.
- Use arena allocation for frame-scoped work.
- Put allocator parameters first.
- Keep long-lived allocations visible; do not hide persistent allocation behind "convenience" APIs.

### C interop and platform code

- Keep C imports centralized in `src/c.zig`.
- Use `builtin.os.tag` for platform branching.
- Prefer `std.fs.File` for cross-platform file I/O over raw `std.posix` calls.

### Formatting

- Use `zig fmt` on touched Zig files.
- 4-space indentation is handled by `zig fmt`.
- Prefer readable lines over golfed code.
- Use trailing commas in multiline literals.

## Common Tasks

### Verifying all relevant code compiles

Use `zig build check` when a change affects public API, examples, shaders, or broad compilation behavior.

### Adding a new public source file

1. Create the file under `src/`.
2. Export or re-export it from `src/root.zig` if it belongs in the public surface.
3. Follow existing ownership/error patterns instead of inventing a new API style.

### Modifying shaders

Shaders are compiled automatically during `zig build`.

1. Edit the `.vert` or `.frag` file under `shaders/`.
2. Make sure `build.zig` wires it into `addShaderImport` if it is a new shader.
3. Rebuild with `zig build check` or a narrower relevant command.

### Platform-specific changes

- Linux: `src/window/linux.zig`
- macOS: `src/window/macos.zig`
- Windows window backend: `src/window/windows.zig`
- Windows helpers: `src/windows/win32.zig`
- Shared behavior: branch on `builtin.os.tag`

### Notes and TODOs

- Read `TODO.md` to understand the current roadmap and rough edges.
- Read `notes/` when the task touches an area with open design questions or known tradeoffs.