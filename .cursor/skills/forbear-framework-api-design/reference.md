# Forbear Framework API Design Reference

This file collects concrete patterns for working *inside* the Forbear framework.

## Resource API Split

Keep persistent registration separate from frame-time lookup:

```zig
pub fn registerFont(uniqueIdentifier: []const u8, comptime contents: []const u8) !void {
    const self = getContext();
    const result = try self.fonts.getOrPut(uniqueIdentifier);
    if (!result.found_existing) {
        result.value_ptr.* = try Font.init(self.allocator, uniqueIdentifier, contents);
    }
}

pub fn useFont(uniqueIdentifier: []const u8) !*Font {
    const self = getContext();
    return self.fonts.getPtr(uniqueIdentifier) orelse {
        std.log.err("Could not find font by the unique identifier {s}", .{uniqueIdentifier});
        return error.FontNotFound;
    };
}
```

Use this pattern when the framework owns a long-lived resource but consumers read it during frame work.

## Lifecycle-Bound Hook Shape

Make hook context requirements explicit:

```zig
pub fn useArena() !std.mem.Allocator {
    const self = getContext();
    if (self.frameMeta) |meta| {
        return meta.arena;
    } else {
        return error.NoFrame;
    }
}

pub fn useState(T: type, initialValue: T) !*T {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);
    if (currentComponentResolutionState()) |state| {
        // ...
        return @ptrCast(@alignCast(stateResult.value_ptr.*.items[state.useStateCursor]));
    } else {
        return error.NoComponentContext;
    }
}
```

## Split Partial Input From Resolved State

Keep the current `IncompleteStyle` -> `Style` pattern when runtime resolution adds responsibility:

```zig
const baseStyle = if (result.parent) |parent|
    BaseStyle.from(parent.style)
else
    self.frameMeta.?.baseStyle;
var style = incompleteStyle.completeWith(baseStyle);
```

Do not collapse these into one type unless the responsibilities truly converge.

## Layout Test Setup

Use the existing helper for realistic frame setup:

```zig
var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
defer arenaAllocator.deinit();

try forbear.frame(try utilities.frameMeta(arenaAllocator.allocator()))({
    forbear.element(.{
        .width = .{ .fixed = 400 },
        .height = .{ .fixed = 200 },
        .direction = .leftToRight,
    })({
        forbear.element(.{ .width = .grow, .height = .grow })({});
        forbear.element(.{ .width = .{ .fixed = 100 }, .height = .grow })({});
    });

    const root = try forbear.layout();
    try std.testing.expectEqual(@as(f32, 400), root.size[0]);
});
```

## File Selection Guide

- Hooks, frame lifecycle, events, public exports: `src/root.zig`
- Style model, sizing, node data: `src/node.zig`
- Grow/shrink/wrap/layout traversal: `src/layouting.zig`
- Rendering boundary and draw pipeline: `src/graphics.zig`
- Platform backends: `src/window/*.zig`, `src/windows/win32.zig`
