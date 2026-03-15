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
TEST_FILTER="layout" zig build test

# Example: run the layout pipeline tests
TEST_FILTER="layout pipeline" zig build test
```

## Cursor Cloud specific instructions

- Cloud agents use `.cursor/environment.json` to install Vulkan, Wayland, and software-rendering dependencies.
- The checked-in environment expects Linux rendering to work through Wayland.
- On startup, `.cursor/environment.json` captures the output of `scripts/cursor_cloud_wayland_start.sh` and `eval`s the resulting `export` statements so the chosen `XDG_RUNTIME_DIR` and `WAYLAND_DISPLAY` are available to later agent commands in the startup shell.
- `scripts/cursor_cloud_wayland_start.sh` first tries to reuse an already-running Wayland compositor from `/run/user/*/wayland-*`.
- If no compositor is available, the script creates a fresh `mktemp` runtime directory and starts `weston` there instead, so fallback Wayland state is unique to that cloud environment.
- When `DISPLAY` is available, the fallback compositor uses Weston on the X11 backend so GUI inspection can work in a visible nested window. Otherwise it uses Weston on the headless backend for terminal-driven agent runs.
- The startup script only reuses actual socket files under `/run/user/*/wayland-*`, writes the chosen `XDG_RUNTIME_DIR` and `WAYLAND_DISPLAY` into shell startup files for bash and fish, and fails fast if Weston never creates the requested socket.
- The environment also forces Vulkan onto Mesa's CPU renderer (`lavapipe`/`llvmpipe`) through `VK_DRIVER_FILES`, `VK_ICD_FILENAMES`, `GALLIUM_DRIVER`, and `LIBGL_ALWAYS_SOFTWARE`.
- Quick cloud sanity checks:
  - `vulkaninfo --summary` should report `PHYSICAL_DEVICE_TYPE_CPU` and `DRIVER_ID_MESA_LLVMPIPE`.
  - `zig build check` should compile the repo.
  - `timeout 10s zig build run` should keep running until timeout rather than failing at Wayland/Vulkan startup.
- If a cloud run reports missing Wayland display access, inspect `echo $XDG_RUNTIME_DIR $WAYLAND_DISPLAY` and `/tmp/weston.log` before assuming the renderer is broken.

### Shader Compilation

Shaders are compiled automatically during `zig build`. Manual examples:

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

## Learned User Preferences

- Prefer unified code paths over duplicated branches for related behaviors (e.g., wrap vs non-wrap placement should share one path with only the policy predicate differing)
- Prefer design analysis explaining WHY something should or shouldn't be done, rather than immediately implementing whatever is asked
- Prefer single-pass solutions folded into existing tree walks over adding separate traversal passes with extra allocations
- When a helper like `utilities.frameMeta()` exists, use it consistently everywhere rather than hand-constructing equivalent literals
- Always verify that file edits were actually applied before reporting completion
- Source-location-based identity for UI nodes is preferred over positional/index-based identity, but the API should hide complexity rather than forcing users to pass `@src()` at every call site

## Learned Workspace Facts

- Node structs constructed in tests require `parent: null` for root nodes; omitting the field causes compilation errors
- Tests do not require Vulkan or a GPU; `undefined` is passed as the renderer parameter, and `update()` is fully testable without graphics
- The `uhoh.com` example app reproduces a real website; comparing the live site's CSS (especially flex-wrap) against the example output is a valid way to find missing layout features
- `Node.fitChild()` in `node.zig` is the single source of truth for fit-size accumulation; layout code should delegate to it rather than duplicating the logic
- `Node.fit()` is a local-only operation that fits a single node from its current children; it should not recurse into the subtree
- Fitting flows bottom-up (children report size to parents) and can happen during element creation; growing flows top-down (parents distribute space to children) and requires the full tree plus viewport anchoring
- For word-wrapped text, `src/root.zig` computes `minSize` width as the longest word; if a fit parent fails to pick up the text child's full size, the shrink pass can squeeze the text node to that minimum, causing each word to stack in a narrow column

