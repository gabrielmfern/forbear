# Forbear API Reference Examples

This file gives concrete, repo-native examples to pair with `SKILL.md`.

## End-To-End Frame Loop

The canonical runtime flow is the one used in `playground.zig`:

```zig
while (window.running) {
    defer _ = arenaAllocator.reset(.retain_capacity);

    try forbear.frame(.{
        .arena = arena,
        .viewportSize = renderer.viewportSize(),
        .baseStyle = .{
            .blendMode = .normal,
            .font = try forbear.useFont("Inter"),
            .color = .{ 1.0, 1.0, 1.0, 1.0 },
            .textWrapping = .character,
            .fontSize = 32,
            .fontWeight = 400,
            .lineHeight = 1.0,
            .cursor = .default,
        },
        .dpi = .{ @floatFromInt(window.dpi[0]), @floatFromInt(window.dpi[1]) },
    })({
        try App();

        const rootNode = try forbear.layout();
        try renderer.drawFrame(
            arena,
            rootNode,
            .{ 1.0, 1.0, 1.0, 1.0 },
            window.dpi,
            window.targetFrameTimeNs(),
        );

        try forbear.update();
    });
}
```

Use this as the baseline when designing new runtime-facing APIs.

## Stateful Component Pattern

Use a component scope for stateful hooks:

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

Keep the key and hook order stable across frames.

## Built-In Component Shape

Small reusable components should still be plain functions:

```zig
pub fn FpsCounter() !void {
    forbear.component("forbear-native-fps-counter")({
        const arena = try forbear.useArena();
        const deltaTime = forbear.useDeltaTime();
        const fps = if (deltaTime == 0) 0 else 1.0 / deltaTime;

        forbear.element(.{
            .placement = .{ .manual = .{ 10, 10 } },
            .zIndex = 10,
        })({
            forbear.text(try std.fmt.allocPrint(arena, "FPS: {d:.1}", .{fps}));
        });
    });
}
```

Prefer a plain function plus existing primitives over a larger abstraction.

## Resource Registration Pattern

Follow the current split between registration and lookup:

```zig
try forbear.registerFont("Inter", @embedFile("Inter.ttf"));
try forbear.registerImage(
    "logo",
    @embedFile("logo.png"),
    .png,
);

const font = try forbear.useFont("Inter");
const image = try forbear.useImage("logo");
```

`registerX` owns or initializes the persistent resource. `useX` reads it back during frame work.

## Layout Test Pattern

The current shared helper lives in `src/tests/utilities.zig`:

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

Use `utilities.frameMeta()` unless the test specifically needs a custom frame setup.

## File Selection Guide

- Public API, hooks, resources, update flow: `src/root.zig`
- Style model and sizing enums: `src/node.zig`
- Grow/shrink/wrap/layout traversal: `src/layouting.zig`
- Rendering pipeline: `src/graphics.zig`
- Platform event/windowing: `src/window/*.zig`, `src/windows/win32.zig`
- Tests: `src/tests/*.test.zig`
