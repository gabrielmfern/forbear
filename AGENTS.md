# AGENTS.md - Forbear Codebase Guide

This document provides guidelines for AI agents working in the Forbear codebase.
Forbear is a Zig-based UI framework with Vulkan graphics backend, supporting Linux (Wayland) and macOS.

## Project Overview

- **Language**: Zig (minimum version 0.15.2)
- **Graphics**: Vulkan with GLSL shaders (compiled via glslangValidator)
- **Platforms**: Linux (Wayland), macOS (Metal surface via MoltenVK), Windows
- **Dependencies**: FreeType (font rendering), kb_text_shape (text shaping), zmath (math), stb_image

## Build Commands

```bash
# Build the project
zig build

# Build and run the playground example
zig build run

# Run all tests
zig build test

# Build all examples and playground (verifies everything compiles)
zig build check

# Build with release optimizations
zig build --release=fast

# Build with specific target
zig build -Dtarget=x86_64-linux-gnu
```

### Running a Single Test

Zig's build system runs all tests together. To run specific tests, use test filters:

```bash
# Run tests with filter (matches test name substring)
zig build test -- --test-filter="test_name_pattern"

# Example: run tests containing "layout" in their name
zig build test -- --test-filter="layout"
```

### Shader Compilation

Shaders are automatically compiled during build using `glslangValidator`. Manual compilation:

```bash
glslangValidator -V -o output.spv shaders/element/vertex.vert
glslangValidator -V -o output.spv shaders/element/fragment.frag
```

## Code Style Guidelines

### File Organization

1. **Imports** - Group in this order, separated by blank lines:
   - Standard library (`const std = @import("std");`)
   - Built-in (`const builtin = @import("builtin");`)
   - External dependencies (`const zmath = @import("zmath");`)
   - Internal modules (`const Font = @import("font.zig");`)

2. **Type Definitions** - Define after imports:
   - Vector types: `const Vec4 = @Vector(4, f32);`
   - Error sets
   - Structs and enums

3. **Module Structure** - For files that define a primary type:
   - Use `@This()` pattern for self-referential types
   - Public fields and functions first
   - Private/helper functions after

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Types/Structs | PascalCase | `LayoutBox`, `DeviceInformation` |
| Functions | camelCase | `initRenderer`, `findMemoryType` |
| Variables | camelCase | `vulkanInstance`, `physicalDevice` |
| Constants | camelCase | `maxFramesInFlight`, `maxImages` |
| Files | snake_case.zig | `graphics.zig`, `font.zig` |
| C interop | Match C naming | `c.VkInstance`, `c.FT_Face` |

### Type Patterns

```zig
// Use @This() for self-referential struct methods
pub fn init(...) @This() {
    return @This(){ ... };
}

// Use extern struct for C-compatible layouts
pub const Vertex = extern struct {
    position: @Vector(3, f32),
};

// Tagged unions for variant types
pub const Node = union(enum) {
    element: Element,
    text: []const u8,
};

// Optional fields with defaults
pub const Style = struct {
    minWidth: ?f32 = null,
    preferredWidth: Sizing,
};
```

### Closures (Pseudo-Closures)

**Zig does not support closures.** Inner functions cannot access surrounding variable context - everything must be passed down as parameters. The only way to "simulate" a closure is by explicitly passing values as parameters through a struct pattern:

```zig
const myValue: usize = 10;
const pseudoClosure = (struct {
    fn closure(value: usize) void {
        // Use the passed value here
        _ = value;
    }
}).closure(myValue);
```

**Important:** The inner parameter name cannot shadow the outer variable name. You cannot use the same name in both the outer scope and the inner function parameter:

```zig
// WRONG - won't compile
const myValue: usize = 10;
const pseudoClosure = (struct {
    fn closure(myValue: usize) void {  // Error: shadows outer myValue
        // ...
    }
}).closure(myValue);

// CORRECT - different parameter name
const myValue: usize = 10;
const pseudoClosure = (struct {
    fn closure(value: usize) void {  // OK: different name
        // ...
    }
}).closure(myValue);
```

In practice, use regular functions and pass all context explicitly.

### Error Handling

1. **Error Sets** - Define comprehensive error enums for each subsystem:
   ```zig
   const FreetypeError = error{
       CannotOpenResource,
       UnknownFileFormat,
       // ...
   };
   ```

2. **Error Translation** - Convert C library errors to Zig errors:
   ```zig
   fn ensureNoError(errorCode: c.FT_Error) FreetypeError!void {
       switch (errorCode) {
           c.FT_Err_Cannot_Open_Resource => return error.CannotOpenResource,
           // ...
           else => std.debug.assert(errorCode == c.FT_Err_Ok),
       }
   }
   ```

3. **Resource Cleanup** - Use `errdefer` for cleanup on error paths:
   ```zig
   var image: c.VkImage = undefined;
   try ensureNoError(c.vkCreateImage(...));
   errdefer c.vkDestroyImage(logicalDevice, image, null);
   ```

### Memory Management

1. **Allocator Passing** - Pass allocators explicitly:
   ```zig
   pub fn init(allocator: std.mem.Allocator) !@This() { ... }
   ```

2. **Arena Allocators** - Use for frame-scoped allocations:
   ```zig
   var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
   defer arenaAllocator.deinit();
   const arena = arenaAllocator.allocator();
   ```

3. **Cleanup Pattern** - Match init/deinit pairs:
   ```zig
   pub fn deinit(self: *@This(), logicalDevice: c.VkDevice) void {
       c.vkDestroyImageView(logicalDevice, self.imageView, null);
       // ...
   }
   ```

4. **Allocator as first parameter**:
   ```zig
   pub fn createResource(allocator: std.mem.Allocator, ...) !Resource { ... }
   ```

### C Interop

1. **Single c.zig file** - All C imports centralized:
   ```zig
   pub const c = @cImport({
       @cDefine("VK_USE_PLATFORM_WAYLAND_KHR", "1");
       @cInclude("vulkan/vulkan.h");
   });
   ```

2. **Platform-specific code** - Use `builtin.os.tag`:
   ```zig
   if (builtin.os.tag == .linux) {
       // Wayland-specific code
   } else if (builtin.os.tag == .macos) {
       // macOS-specific code
   }
   ```

### Vulkan Specifics

1. **Image Formats**:
   - Font atlas: `VK_FORMAT_R8_UNORM` (linear grayscale from FreeType)
   - Color images: `VK_FORMAT_R8G8B8A8_UNORM`
   - Swapchain: Platform-dependent sRGB format

2. **Resource Creation Pattern**:
   ```zig
   var resource: c.VkType = undefined;
   try ensureNoError(c.vkCreateType(device, &createInfo, null, &resource));
   errdefer c.vkDestroyType(device, resource, null);
   ```

### Code Formatting

- Use `zig fmt` for automatic formatting
- 4-space indentation (handled by zig fmt)
- Line length: no strict limit, but prefer readable lines
- Trailing commas in multi-line structs/arrays

### Debug vs Release

```zig
if (builtin.mode == .Debug) {
    // Debug-only code (validation layers, logging)
}
```

## Project Structure

```
forbear/
├── build.zig           # Build configuration
├── build.zig.zon       # Package manifest
├── src/
│   ├── root.zig        # Public API exports
│   ├── graphics.zig    # Vulkan rendering
│   ├── font.zig        # FreeType font handling
│   ├── layouting.zig   # Layout algorithm
│   ├── node.zig        # UI node types
│   ├── c.zig           # C imports
│   └── window/
│       ├── root.zig    # Platform abstraction
│       ├── linux.zig   # Wayland implementation
│       └── macos.zig   # macOS implementation
├── shaders/
│   ├── element/        # UI element shaders
│   └── text/           # Text rendering shaders
├── dependencies/       # Local dependencies
└── playground.zig      # Example/test application
```

## Common Tasks

### Verifying All Code Compiles

After making changes, use `zig build check` to verify all examples and the playground compile:

```bash
zig build check
```

This command:
- Builds the playground executable
- Builds all examples in `examples/` directory
- Does not run tests (use `zig build test` for that)
- Useful for CI or before committing changes

### Adding a New Source File

1. Create file in `src/` directory
2. Import in `src/root.zig` if public API
3. Use existing patterns for error handling and memory

### Modifying Shaders

1. Edit `.vert` or `.frag` files in `shaders/`
2. Build system auto-compiles to SPIR-V
3. Embedded via `@embedFile` in graphics.zig

### Platform-Specific Changes

- Linux: `src/window/linux.zig` (Wayland)
- macOS: `src/window/macos.zig`
- Windows: `src/window/windows.zig`
- Shared: Use `builtin.os.tag` switches

### Custom Test Runner

Tests use a custom runner at `test_runner.zig`, wired in `build.zig` via:
```zig
.test_runner = .{ .path = b.path("test_runner.zig"), .mode = .simple },
```

Environment variables: `TEST_VERBOSE` (default true), `TEST_FAIL_FIRST`, `TEST_FILTER`.

## Zig 0.15 Standard Library Notes

Key API details for Zig 0.15.2 that differ from earlier versions or have platform-specific behavior:

### Cross-Platform File I/O

Use `std.fs.File` for cross-platform file operations — it wraps POSIX `fd_t` (integer) on Unix and Windows `HANDLE` on Windows behind a unified type. The methods `read()`, `write()`, `seekTo()`, `close()` all work on every platform.

```zig
const File = std.fs.File;
const stderr = File.stderr();  // cross-platform
_ = try stderr.write("hello");
```

`std.fs.File.writer()` in 0.15 takes a buffer parameter:
```zig
var buf: [256]u8 = undefined;
const w = file.writer(&buf);
```
There is no free-standing `std.io.bufferedWriter()` — it was removed/restructured in 0.15.

### POSIX APIs That Do NOT Work on Windows

These `std.posix` functions only compile on POSIX systems (Linux, macOS):

- `std.posix.dup()`, `std.posix.dup2()` — no Windows implementation
- `std.posix.STDERR_FILENO` — not defined on Windows
- `std.posix.memfd_create()` — Linux only
- `std.posix.openZ()`, `std.posix.unlinkZ()` — POSIX only
- `std.posix.getpid()` — Linux/Plan9 only

These `std.posix` functions DO work on Windows (they dispatch to Windows APIs internally):

- `std.posix.exit()` — calls `kernel32.ExitProcess` on Windows
- `std.posix.lseek_SET()` — calls `SetFilePointerEx` on Windows
- `std.posix.read()` / `std.posix.write()` / `std.posix.close()` — dispatch to Windows equivalents

When writing cross-platform code, prefer `std.fs.File` methods over raw `std.posix` calls.

### Windows Handle Duplication

Windows equivalent of `dup()` is `kernel32.DuplicateHandle()`:
```zig
const windows = std.os.windows;
var duplicated: windows.HANDLE = undefined;
const proc = windows.GetCurrentProcess();
const DUPLICATE_SAME_ACCESS = 0x00000002;
_ = windows.kernel32.DuplicateHandle(proc, handle, proc, &duplicated, 0, windows.FALSE, DUPLICATE_SAME_ACCESS);
```

### Windows Stderr Redirection

`std.debug.print` reads `peb().ProcessParameters.hStdError` on each call (the PEB field is `HANDLE`, not optional). To redirect stderr on Windows, overwrite this field directly:
```zig
windows.peb().ProcessParameters.hStdError = new_handle;
```
On POSIX, use `dup2(new_fd, STDERR_FILENO)` instead.

### Temporary Files

- **Linux**: `std.posix.memfd_create("name", 0)` creates an anonymous in-memory file (no filesystem path needed).
- **Cross-platform**: Use `std.fs.Dir.createFile()` on a temp directory. The `.zig-cache/tmp/` directory is conventional for build-time temp files. Generate unique names via `std.crypto.random.bytes()` + `std.fs.base64_encoder.encode()`.

### PEB Struct Fields

`RTL_USER_PROCESS_PARAMETERS.hStdError` is `HANDLE` (non-optional). The similar-looking `STARTUPINFOW.hStdError` is `?HANDLE` (optional). Don't confuse them — the PEB version doesn't need `orelse`.
