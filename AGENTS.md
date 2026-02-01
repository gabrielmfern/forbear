# AGENTS.md - Forbear Codebase Guide

This document provides guidelines for AI agents working in the Forbear codebase.
Forbear is a Zig-based UI framework with Vulkan graphics backend, supporting Linux (Wayland) and macOS.

## Project Overview

- **Language**: Zig (minimum version 0.15.2)
- **Graphics**: Vulkan with GLSL shaders (compiled via glslangValidator)
- **Platforms**: Linux (Wayland), macOS (Metal surface via MoltenVK)
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
- Shared: Use `builtin.os.tag` switches
