const std = @import("std");
const forbear = @import("forbear");

fn CounterExample() void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
        const count = forbear.useState(u32, 0);

        forbear.element(.{ .style = .{
            .direction = .vertical,
            .padding = .all(16.0),
            .background = .{ .color = .{ 0.12, 0.12, 0.12, 1.0 } },
            .borderRadius = 12.0,
        } })({
            forbear.printText("Count: {d}", .{count.*});

            forbear.element(.{ .style = .{
                .margin = .top(12.0),
                .padding = forbear.Padding.block(10.0).withInLine(16.0),
                .background = .{ .color = .{ 0.0, 0.0, 0.0, 1.0 } },
                .borderRadius = 8.0,
            } })({
                if (forbear.on(.mouseOver)) {
                    forbear.setCursor(.pointer);
                }
                if (forbear.on(.click)) {
                    count.* += 1;
                }

                forbear.text("Increment");
            });
        });
    });
}

fn App() void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
        const viewportSize = forbear.useViewportSize();
        const isHovering = forbear.useState(bool, false);

        forbear.element(.{ .style = .{
            .width = .{ .fixed = viewportSize[0] },
            .height = .{ .fixed = viewportSize[1] },
        } })({
            _ = forbear.useScrolling();

            forbear.element(.{ .style = .{
                .width = .{ .grow = 1.0 },
                .direction = .vertical,
                .background = .{ .color = .{ 0.2, 0.2, 0.2, 1.0 } },
                .padding = .all(10),
            } })({
                forbear.FpsCounter();

                forbear.text("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]]{{}}|;':\",.<>/?`~");
                forbear.element(.{ .style = .{
                    .margin = forbear.Margin.top(12.0),
                    .width = .{ .fixed = 100 },
                    .height = .{ .fixed = 100 },
                    .background = .{
                        .color = .{
                            1.0,
                            forbear.useTransition(if (isHovering.*) 0.0 else 0.3, 0.1, forbear.linear),
                            0.0,
                            1.0,
                        },
                    },
                    .borderRadius = 20,
                } })({
                    if (forbear.on(.mouseOver)) {
                        isHovering.* = true;
                    }
                    if (forbear.on(.mouseOut)) {
                        isHovering.* = false;
                    }
                });

                CounterExample();

                // Demonstrates `.relative` placement: the badge is offset from
                // the card's top-left corner and does not participate in the
                // card's layout flow, so the card content below is unaffected.
                forbear.element(.{ .style = .{
                    .margin = forbear.Margin.top(24.0),
                    .padding = .all(16.0),
                    .fontSize = 16.0,
                    .background = .{ .color = .{ 0.15, 0.15, 0.25, 1.0 } },
                    .borderRadius = 12.0,
                } })({
                    forbear.text("Card with a relative badge");

                    forbear.element(.{ .style = .{
                        .placement = .{ .relative = .{ 200.0, -10.0 } },
                        .background = .{ .color = .{ 0.9, 0.2, 0.3, 1.0 } },
                        .borderRadius = 12.0,
                        .xJustification = .center,
                        .padding = forbear.Padding.block(2.0).withInLine(4.0),
                        .fontSize = 14,
                    } })({
                        forbear.text("NEW");
                    });
                });

                // Demonstrates `.darken` blend mode: the dark overlay darkens
                // the underlying gradient without affecting lighter areas.
                forbear.element(.{ .style = .{
                    .margin = forbear.Margin.top(24.0),
                    .width = .{ .fixed = 200 },
                    .height = .{ .fixed = 100 },
                    .background = .{
                        .gradient = &.{
                            .{ .color = .{ 0.2, 0.6, 1.0, 1.0 }, .position = 0.0 },
                            .{ .color = .{ 1.0, 0.4, 0.2, 1.0 }, .position = 1.0 },
                        },
                    },
                    .borderRadius = 12.0,
                } })({
                    forbear.element(.{ .style = .{
                        .width = .{ .fixed = 100 },
                        .height = .{ .fixed = 80 },
                        .margin = .all(10),
                        .background = .{ .color = .{ 0.3, 0.3, 0.3, 0.8 } },
                        .blendMode = .darken,
                        .borderRadius = 8.0,
                    } })({});
                });

                // Dashed border example
                forbear.element(.{ .style = .{
                    .margin = forbear.Margin.top(24.0),
                    .width = .{ .fixed = 200 },
                    .height = .{ .fixed = 100 },
                    .background = .{ .color = .{ 0.1, 0.1, 0.1, 1.0 } },
                    .borderWidth = .all(3.0),
                    .borderColor = .{ 0.4, 0.8, 1.0, 1.0 },
                    .borderStyle = .dashed,
                    .borderRadius = 8.0,
                    .xJustification = .center,
                    .yJustification = .center,
                } })({
                    forbear.text("Dashed");
                });

                // Scissor clipping test: fixed height container with overflowing children
                forbear.element(.{ .style = .{
                    .margin = forbear.Margin.top(24.0),
                    .width = .{ .fixed = 200 },
                    .height = .{ .fixed = 100 },
                    .direction = .vertical,
                    .background = .{ .color = .{ 0.1, 0.2, 0.3, 1.0 } },
                    .borderRadius = 8.0,
                    .borderWidth = .all(2.0),
                    .borderColor = .{ 0.3, 0.6, 0.9, 1.0 },
                } })({
                    _ = forbear.useScrolling();

                    forbear.text("Line 1");
                    forbear.text("Line 2");
                    forbear.text("Line 3 - should clip");
                    forbear.text("Line 4 - should clip");
                    forbear.text("Line 5 - should clip");
                });

                // Two scrollable regions in the same component. Each
                // `useScrolling` call binds its offset and spring state to
                // its enclosing element, so the regions scroll independently
                // without needing wrapping components.
                forbear.element(.{ .style = .{
                    .margin = forbear.Margin.top(24.0),
                    .direction = .horizontal,
                } })({
                    forbear.element(.{ .style = .{
                        .width = .{ .fixed = 200 },
                        .height = .{ .fixed = 120 },
                        .direction = .vertical,
                        .background = .{ .color = .{ 0.15, 0.10, 0.20, 1.0 } },
                        .borderRadius = 8.0,
                        .padding = .all(8),
                    } })({
                        _ = forbear.useScrolling();
                        forbear.text("Left A");
                        forbear.text("Left B");
                        forbear.text("Left C");
                        forbear.text("Left D");
                        forbear.text("Left E");
                    });

                    forbear.element(.{ .style = .{
                        .margin = forbear.Margin.left(12.0),
                        .width = .{ .fixed = 200 },
                        .height = .{ .fixed = 120 },
                        .direction = .vertical,
                        .background = .{ .color = .{ 0.10, 0.20, 0.15, 1.0 } },
                        .borderRadius = 8.0,
                        .padding = .all(8),
                    } })({
                        _ = forbear.useScrolling();
                        forbear.text("Right 1");
                        forbear.text("Right 2");
                        forbear.text("Right 3");
                        forbear.text("Right 4");
                        forbear.text("Right 5");
                    });
                });
            });
        });
    });
}

fn renderingMain(
    allocator: std.mem.Allocator,
    renderer: *forbear.Graphics.Renderer,
    window: *const forbear.Window,
) !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.registerFont("Inter", @embedFile("Inter.ttf"));

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
            },
        })({
            App();

            const rootTree = try forbear.layout();
            try renderer.drawFrame(
                arena,
                rootTree,
                .{ 1.0, 1.0, 1.0, 1.0 },
                window.targetFrameTimeNs(),
            );

            try forbear.update();
        });
    }
    try renderer.waitIdle();
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer {
        if (gpa.deinit() == .leak) {
            std.log.err("Memory was leaked", .{});
        }
    }

    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var graphics = try forbear.Graphics.init(
        allocator,
        "forbear playground",
    );
    defer graphics.deinit();

    const window = try forbear.Window.init(
        allocator,
        800,
        600,
        "forbear playground",
        "forbear.playground",
    );
    defer window.deinit();

    var renderer = try graphics.initRenderer(window);
    defer renderer.deinit();

    try forbear.init(allocator, io, &renderer);
    defer forbear.deinit();
    forbear.setWindowHandlers(window);

    const renderingThread = try std.Thread.spawn(
        .{ .allocator = allocator },
        renderingMain,
        .{
            allocator,
            &renderer,
            window,
        },
    );
    defer renderingThread.join();

    try window.handleEvents();
}
