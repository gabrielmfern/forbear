# Forbear UI Authoring Reference

This file collects copyable patterns for writing UI *with* Forbear.

## Canonical Frame Loop

Use the same high-level order as `playground.zig`:

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

## Stateful Component

Use `component("stable-key")` plus hooks:

```zig
pub fn Button(props: ButtonProps) !void {
    forbear.component("button")({
        const isHovering = try forbear.useState(bool, false);

        forbear.element(.{
            .cursor = .pointer,
            .translate = .{
                0.0,
                try forbear.useTransition(
                    if (isHovering.*) -4.5 else 0.0,
                    0.1,
                    forbear.easeInOut,
                ),
            },
        })({
            forbear.text(props.text);
        });

        while (forbear.useNextEvent()) |event| {
            switch (event) {
                .mouseOver => isHovering.* = true,
                .mouseOut => isHovering.* = false,
            }
        }
    });
}
```

## Resources

Register once, use later:

```zig
try forbear.registerFont("SpaceGrotesk", @embedFile("SpaceGrotesk.ttf"));
try forbear.registerImage("hero", @embedFile("static/hero.png"), .png);

const font = try forbear.useFont("SpaceGrotesk");
const hero = try forbear.useImage("hero");
```

## Tree Composition

Prefer nested `element` blocks over inventing a custom builder:

```zig
forbear.element(.{
    .width = .grow,
    .direction = .topToBottom,
    .alignment = .topCenter,
})({
    forbear.element(.{
        .fontSize = 46,
        .lineHeight = 0.75,
    })({
        forbear.text("You're the boss, why are you still fixing tech issues?");
    });

    forbear.image(.{
        .width = .grow,
        .maxWidth = 369,
        .blendMode = .multiply,
    }, try forbear.useImage("hero"));
});
```
