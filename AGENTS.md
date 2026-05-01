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

The core mental model is "build a node tree each frame, but keep state across frames by key." Both `component(...)` and `element(...)` create stable hook scopes for `useState`, `useTransition`, `useAnimation`, and related helpers; `useState` binds to the **nearest enclosing scope**, whichever is closer. So `useState` (and any hook layered on it, like `useScrolling`) called directly inside an `element({...})({...})` block attaches state to that element — no need to wrap the element in a dedicated component. State for a scope persists as long as that scope is rendered each frame; if it's omitted for a frame, its state is dropped (React-style unmount). `element`, `text`, and `image` append `Node` values into the current frame tree stored in `FrameMeta`. The layout stage resolves sizes and positions, then the renderer iterates that resolved tree to issue Vulkan draw calls.

## How The Core Files Connect

- `src/root.zig`: public API, global runtime context, frame lifecycle, hooks, resource registration, event/update flow.
- `src/node.zig`: the UI data model: `Node`, `Style`, `IncompleteStyle`, sizing enums, alignment, padding, text wrapping, shadows.
- `src/layouting.zig`: layout resolution, grow/shrink distribution, wrapping, absolute positioning, tree iteration, and `layout()`.
- `src/graphics.zig`: Vulkan initialization plus turning the laid out tree into render passes and draw calls.
- `src/builtin.zig`: reusable built-in components and hooks such as `FpsCounter` and `useScrolling`.
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

# Run a specific test
zig build test -Dtest-filter="text .none maxSize[0] tracks longest line when it is not the last"

# Build the playground and examples without running tests
zig build check

# Build with release optimizations
zig build --release=fast

# Build with a specific target
zig build -Dtarget=x86_64-windows
```

## Project Structure

```text
forbear/
├── AGENTS.md               # Main entrypoint for agents
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
│   ├── builtin.zig
│   ├── c.zig
│   ├── font.zig
│   ├── graphics.zig
│   ├── layouting.zig
│   ├── node.zig
│   ├── root.zig
│   ├── tests.zig
│   ├── window/
│   │   ├── linux.zig
│   │   ├── macos.zig
│   │   ├── root.zig
│   │   └── windows.zig
│   └── windows/
│       └── win32.zig
└── dependencies/
```

