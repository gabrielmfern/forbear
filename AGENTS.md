# AGENTS.md - Forbear Codebase Guide

This document gives AI agents the shortest path to the real shape of the Forbear codebase.
Forbear is a Zig UI framework with a Vulkan renderer, an immediate-style mounting API, a retained component state model, and platform-specific window backends.

## Project Overview

- **Language**: Zig (minimum version 0.15.2)
- **Graphics**: Vulkan with GLSL shaders compiled during the build
- **Platforms**: Linux (Wayland), macOS (MoltenVK + Metal surface), Windows
- **Dependencies**: FreeType, kb_text_shape, zmath, stb_image

## Architecture At A Glance

Forbear's runtime flow is:

1. Initialize graphics/window/context.
2. Register long-lived resources such as fonts and images.
3. Start a frame with `forbear.frame(meta)`.
4. Mount UI by calling `component()`, `element()`, `text()`, and `image()`.
5. Resolve geometry with `forbear.layout()`.
6. Render the laid out node tree with `renderer.drawFrame(...)`.
7. Advance events, hover state, scrolling, and animations with `forbear.update()`.

The core mental model is "build a node tree each frame, but keep component state across frames by key." `component("key")` creates a stable hook scope for `useState`, `useTransition`, `useAnimation`, and related helpers. `element`, `text`, and `image` append `Node` values into the current frame tree stored in `FrameMeta`. The layout stage resolves sizes and positions, then the renderer iterates that resolved tree to issue Vulkan draw calls.

## How The Core Files Connect

- `src/root.zig`: public API, global runtime context, frame lifecycle, hooks, resource registration, event/update flow.
- `src/node.zig`: the UI data model: `Node`, `Style`, `IncompleteStyle`, sizing enums, alignment, padding, text wrapping, shadows.
- `src/layouting.zig`: layout resolution, grow/shrink distribution, wrapping, absolute positioning, tree iteration, and `layout()`.
- `src/graphics.zig`: Vulkan initialization plus turning the laid out tree into render passes and draw calls.
- `src/components.zig`: reusable built-in components such as `FpsCounter`.
- `src/font.zig`: font loading, shaping, and glyph data.
- `src/window/*.zig`: platform-specific window/event backends.
- `src/windows/win32.zig`: lower-level Windows helpers used by the windowing/graphics code.
- `playground.zig`: the best end-to-end example of the frame -> layout -> draw -> update loop.

## Build Commands

```bash
# Build the project
zig build

# Build and run the playground example
zig build run

# Run all tests
zig build test

# Build the playground and examples without running tests
zig build check

# Build with release optimizations
zig build --release=fast

# Build with a specific target
zig build -Dtarget=x86_64-linux-gnu
```

### Running Focused Tests

Zig's build step runs the module test binary, but test filters still work:

```bash
# Run tests whose names contain a substring
zig build test -- --test-filter="layout"

# Example: run the layout pipeline tests
zig build test -- --test-filter="layout pipeline"
```

### Shader Compilation

Shaders are compiled automatically during `zig build`. Manual examples:

```bash
glslangValidator -V -o output.spv shaders/element/vertex.vert
glslangValidator -V -o output.spv shaders/element/fragment.frag
glslangValidator -V -o output.spv shaders/shadow/vertex.vert
glslangValidator -V -o output.spv shaders/text/fragment.frag
```

## Project Structure

```text
forbear/
├── AGENTS.md
├── TODO.md
├── build.zig
├── build.zig.zon
├── playground.zig
├── test_runner.zig
├── examples/
│   └── uhoh.com/           # Real example app using the framework
├── notes/                  # Design notes, plans, and open questions
├── shaders/
│   ├── element/
│   ├── shadow/
│   └── text/
├── src/
│   ├── c.zig
│   ├── components.zig
│   ├── font.zig
│   ├── graphics.zig
│   ├── layouting.zig
│   ├── node.zig
│   ├── root.zig
│   ├── tests/
│   │   ├── font.test.zig
│   │   ├── layouting.test.zig
│   │   ├── root.test.zig
│   │   └── utilities.zig
│   ├── window/
│   │   ├── linux.zig
│   │   ├── macos.zig
│   │   ├── root.zig
│   │   └── windows.zig
│   └── windows/
│       └── win32.zig
└── dependencies/
```

## Component, Hook, And Resource Patterns

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

### Closures (pseudo-closures)

Zig does not support closures. Inner functions cannot capture outer locals, so pass everything explicitly:

```zig
const myValue: usize = 10;
const pseudoClosure = (struct {
    fn closure(value: usize) void {
        _ = value;
    }
}).closure(myValue);
```

Do not shadow the outer variable name in the inner function parameter:

```zig
// WRONG
const myValue: usize = 10;
const pseudoClosure = (struct {
    fn closure(myValue: usize) void {}
}).closure(myValue);

// CORRECT
const myValue: usize = 10;
const pseudoClosure = (struct {
    fn closure(value: usize) void {}
}).closure(myValue);
```

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

### Custom test runner

The build uses `test_runner.zig` via:

```zig
.test_runner = .{ .path = b.path("test_runner.zig"), .mode = .simple },
```

Useful environment variables: `TEST_VERBOSE`, `TEST_FAIL_FIRST`, `TEST_FILTER`.

## Common Pitfalls

- `forbear.frame`, `forbear.element`, and `forbear.component` return end functions. Always invoke them with the `({ ... })` pattern so stacks unwind correctly.
- Hooks must run inside the correct context:
  - `useArena` requires a frame.
  - `useState` and related stateful hooks require a component scope.
- `zig build check` is compile coverage, not test coverage.
- Fonts and images must be registered before `useFont` / `useImage`.
- `.placement = .manual` keeps a child out of standard flow; do not debug those nodes as if grow/shrink logic applies to them.
- Stable hook ordering matters. Do not call `useState` conditionally unless the condition is structurally stable across every frame.

## Zig 0.15 Notes

The common gotchas worth remembering in normal work:

- `std.fs.File.writer()` in Zig 0.15 takes a buffer parameter.
- There is no old-style `std.io.bufferedWriter()` helper to reach for.
- `std.fs.File` methods are the safe cross-platform default for read/write/seek/close.

For the deeper platform-specific notes used by the Windows/test-runner work, read `notes/zig-015-platform-notes.md`.
