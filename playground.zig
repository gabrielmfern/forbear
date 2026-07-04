const std = @import("std");
const forbear = @import("forbear");

fn CounterExample() void {
    forbear.component(.{})({
        const count = forbear.useState(u32, 0);

        forbear.element(.{
            .style = .{
                .direction = .vertical,
                .padding = .all(16.0),
                .background = .{ .color = .{ 0.12, 0.12, 0.12, 1.0 } },
                .borderRadius = 12.0,
            },
        })({
            forbear.printText("Count: {d}", .{count.*});

            if (Button("Increment")) {
                count.* += 1;
            }
        });
    });
}

fn Strong() *const fn (void) void {
    return forbear.textStyle(.{ .fontWeight = 700 });
}

fn Accent() *const fn (void) void {
    return forbear.textStyle(.{ .color = forbear.hex("#7dd3fc") });
}

fn RichTextExample() void {
    forbear.element(.{
        .style = .{
            .margin = .top(12.0),
            .width = .{ .fixed = 420 },
            .textWrapping = .word,
        },
    })({
        forbear.composeText(.{})({
            forbear.write("Wayland is a ");
            Strong()({
                forbear.write("display server protocol");
            });
            forbear.write(", successor to ");
            Accent()({
                forbear.write("X.Org");
            });
            forbear.write(", and forbear can ");
            Strong()({
                Accent()({
                    forbear.write("mix styles");
                });
            });
            forbear.write(" inside one wrapped paragraph.");
        });
    });
}

fn timingFunction(progress: f32) f32 {
    return forbear.cubicBezier(0.4, 0, 0.2, 1, progress);
}

fn Button(text: []const u8) bool {
    var activated = false;
    forbear.component(.{})({
        const isHovering = forbear.useState(bool, false);
        const isPressed = forbear.useState(bool, false);

        forbear.element(.{
            .style = .{
                .height = .{ .fixed = 32.0 },
                .padding = .inLine(10.0),
                .background = .{
                    .color = forbear.useTransition(
                        @Vector(4, f32),
                        if (isHovering.*) forbear.hex("#1C1C1C") else forbear.hex("#151515"),
                        0.15,
                        timingFunction,
                    ),
                },
                .color = forbear.hex("#fafafa"),
                .translate = .{
                    0.0,
                    forbear.useTransition(f32, if (isPressed.*) 1.0 else 0.0, 0.15, timingFunction),
                },
                .cursor = .default,
                .borderRadius = 10.0,
                .borderWidth = .all(2.0),
                .fontSize = 14.0,
                .fontWeight = 500,
                .textWrapping = .none,
                .xJustification = .center,
                .yJustification = .center,
                .direction = .vertical,
            },
        })({
            const focusContext = forbear.FocusContext.use();
            focusContext.register(&(struct {
                fn consume(payload: forbear.EventPayload) ?forbear.EventPayload {
                    return switch (payload) {
                        .keyDown => |keys| .{ .keyDown = .{ .enter = keys.enter, .space = keys.space } },
                        else => null,
                    };
                }
            }).consume);

            const parentNode = forbear.getParentNode().?;
            parentNode.style.shadow = .{
                .color = forbear.hex("#3F3F3F"),
                .offset = .all(0.0),
                .blurRadius = 0.0,
                .spread = forbear.useTransition(
                    f32,
                    if (focusContext.hasFocus()) 3.0 else 0.0,
                    0.15,
                    timingFunction,
                ),
            };
            parentNode.style.borderColor = forbear.useTransition(
                forbear.Color,
                if (focusContext.hasFocus()) forbear.hex("#3F3F3F") else forbear.hex("#2F2F2F"),
                0.15,
                timingFunction,
            );

            if (forbear.onMouseEnter()) {
                isHovering.* = true;
            }
            if (forbear.onMouseLeave()) {
                isHovering.* = false;
                isPressed.* = false;
            }
            if (forbear.onMouseDown()) {
                isPressed.* = true;
            }
            if (forbear.onMouseUp()) {
                isPressed.* = false;
            }

            const keysDown = forbear.onKeyDown();
            if (focusContext.hasFocus() and (keysDown.space or keysDown.enter)) {
                activated = true;
            }
            if (forbear.onClick()) {
                activated = true;
            }

            forbear.text(text);
        });
    });

    return activated;
}

fn TextInput(placeholder: []const u8) void {
    forbear.element(.{
        .style = .{
            .width = .{ .fixed = 240.0 },
            .height = .{ .fixed = 32.0 },
            .padding = .inLine(10.0),
            .background = .{ .color = forbear.hex("#151515") },
            .color = forbear.hex("#fafafa"),
            .cursor = .text,
            .borderRadius = 10.0,
            .borderWidth = .all(2.0),
            .fontSize = 14.0,
            .textWrapping = .none,
            .yJustification = .center,
            .direction = .vertical,
        },
    })({
        const scrollingState = forbear.useState(forbear.ScrollingState, .{});
        forbear.useScrolling(scrollingState);
        const inputState = forbear.useInput(.{
            .cursor = 0,
            .selection = .{ 0, 0 },
            .text = "",
        }, scrollingState);
        const focusContext = forbear.FocusContext.use();

        const node = forbear.getParentNode().?;
        node.style.shadow = .{
            .color = forbear.hex("#3F3F3F"),
            .offset = .all(0.0),
            .blurRadius = 0.0,
            .spread = forbear.useTransition(
                f32,
                if (focusContext.hasFocus()) 3.0 else 0.0,
                0.15,
                timingFunction,
            ),
        };
        node.style.borderColor = forbear.useTransition(
            forbear.Color,
            if (focusContext.hasFocus()) forbear.hex("#3F3F3F") else forbear.hex("#2F2F2F"),
            0.15,
            timingFunction,
        );

        const text = inputState.display;
        const showingPlaceholder = text.len == 0;
        node.style.color = if (showingPlaceholder) forbear.hex("#5F5F5F") else forbear.hex("#fafafa");
        forbear.text(if (showingPlaceholder) placeholder else text);

        forbear.InputCaret(.{ .inputState = inputState });
    });
}

fn App() void {
    forbear.component(.{})({
        const viewportSize = forbear.useViewportSize();

        forbear.element(.{
            .style = .{
                .width = .{ .fixed = viewportSize[0] },
                .height = .{ .fixed = viewportSize[1] },
            },
        })({
            forbear.FocusProvider()({
                forbear.ScrollProvider()({
                    const scrolling = forbear.useState(forbear.ScrollingState, .{});
                    forbear.useScrolling(scrolling);
                    forbear.ScrollBar(scrolling);

                    forbear.element(.{
                        .style = .{
                            .width = .{ .grow = 1.0 },
                            .direction = .vertical,
                            .background = .{ .color = .{ 0.2, 0.2, 0.2, 1.0 } },
                            .padding = .all(10),
                        },
                    })({
                        const isHovering = forbear.useState(bool, false);

                        forbear.ProfilingMetrics(.{});

                        forbear.text("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]]{{}}|;':\",.<>/?`~");

                        RichTextExample();

                        forbear.element(.{
                            .style = .{
                                .margin = forbear.Margin.top(12.0),
                                .width = .{ .fixed = 100 },
                                .height = .{ .fixed = 100 },
                                .background = .{
                                    .color = .{
                                        1.0,
                                        forbear.useTransition(f32, if (isHovering.*) 0.0 else 0.3, 0.1, forbear.linear),
                                        0.0,
                                        1.0,
                                    },
                                },
                                .borderRadius = 20,
                            },
                        })({
                            if (forbear.onMouseEnter()) {
                                isHovering.* = true;
                            }
                            if (forbear.onMouseLeave()) {
                                isHovering.* = false;
                            }
                        });

                        CounterExample();

                        forbear.element(.{
                            .style = .{ .margin = .top(12.0) },
                        })({
                            TextInput("Type something...");
                        });

                        forbear.element(.{
                            .style = .{},
                        })({
                            forbear.text("keys ");
                            // Modifiers read as held state so they stay visible
                            // while down; every other key pulses on press and
                            // again on each OS auto-repeat. We walk the struct's
                            // bool fields via reflection just to render each key
                            // as text.
                            const keys = forbear.onKeyDown();
                            inline for (@typeInfo(forbear.Keys).@"struct".fields) |field| {
                                if (@field(keys, field.name)) {
                                    forbear.text(" ");
                                    forbear.text(field.name);
                                }
                            }
                        });

                        // Demonstrates `.relative` placement: the badge is offset from
                        // the card's top-left corner and does not participate in the
                        // card's layout flow, so the card content below is unaffected.
                        forbear.element(.{
                            .style = .{
                                .margin = forbear.Margin.top(24.0),
                                .padding = .all(16.0),
                                .fontSize = 16.0,
                                .background = .{ .color = .{ 0.15, 0.15, 0.25, 1.0 } },
                                .borderRadius = 12.0,
                            },
                        })({
                            forbear.text("Card with a relative badge");

                            forbear.element(.{
                                .style = .{
                                    .placement = .{ .relative = .{ 200.0, -10.0 } },
                                    .background = .{ .color = .{ 0.9, 0.2, 0.3, 1.0 } },
                                    .borderRadius = 12.0,
                                    .xJustification = .center,
                                    .padding = forbear.Padding.block(2.0).withInLine(4.0),
                                    .fontSize = 14,
                                },
                            })({
                                forbear.text("NEW");
                            });
                        });

                        // Demonstrates `.darken` blend mode: the dark overlay darkens
                        // the underlying gradient without affecting lighter areas.
                        forbear.element(.{
                            .style = .{
                                .margin = forbear.Margin.top(24.0),
                                .width = .{ .fixed = 200 },
                                .height = .{ .fixed = 100 },
                                .background = .{
                                    .gradient = .{
                                        .direction = .toBottomRight,
                                        .stops = &.{
                                            .{ .color = .{ 0.2, 0.6, 1.0, 1.0 }, .position = 0.0 },
                                            .{ .color = .{ 1.0, 0.4, 0.2, 1.0 }, .position = 1.0 },
                                        },
                                    },
                                },
                                .borderRadius = 12.0,
                            },
                        })({
                            forbear.element(.{
                                .style = .{
                                    .width = .{ .fixed = 100 },
                                    .height = .{ .fixed = 80 },
                                    .margin = .all(10),
                                    .background = .{ .color = .{ 0.3, 0.3, 0.3, 0.8 } },
                                    .blendMode = .darken,
                                    .borderRadius = 8.0,
                                },
                            })({});
                        });

                        // Dashed border example
                        forbear.element(.{
                            .style = .{
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
                            },
                        })({
                            forbear.text("Dashed");
                        });

                        // Scissor clipping test: fixed height container with overflowing children
                        forbear.element(.{
                            .style = .{
                                .margin = forbear.Margin.top(24.0),
                                .width = .{ .fixed = 200 },
                                .height = .{ .fixed = 100 },
                                .direction = .vertical,
                                .background = .{ .color = .{ 0.1, 0.2, 0.3, 1.0 } },
                                .borderRadius = 8.0,
                                .borderWidth = .all(2.0),
                                .borderColor = .{ 0.3, 0.6, 0.9, 1.0 },
                            },
                        })({
                            const clipScrolling = forbear.useState(forbear.ScrollingState, .{});
                            forbear.useScrolling(clipScrolling);
                            forbear.ScrollBar(clipScrolling);

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
                        forbear.element(.{
                            .style = .{
                                .margin = forbear.Margin.top(24.0),
                                .direction = .horizontal,
                            },
                        })({
                            forbear.element(.{
                                .style = .{
                                    .width = .{ .fixed = 200 },
                                    .height = .{ .fixed = 120 },
                                    .direction = .vertical,
                                    .background = .{ .color = .{ 0.15, 0.10, 0.20, 1.0 } },
                                    .borderRadius = 8.0,
                                    .padding = .all(8),
                                },
                            })({
                                const leftScrolling = forbear.useState(forbear.ScrollingState, .{});
                                forbear.useScrolling(leftScrolling);
                                forbear.ScrollBar(leftScrolling);
                                forbear.text("Left A");
                                forbear.text("Left B");
                                forbear.text("Left C");
                                forbear.text("Left D");
                                forbear.text("Left E");
                            });

                            forbear.element(.{
                                .style = .{
                                    .margin = forbear.Margin.left(12.0),
                                    .width = .{ .fixed = 200 },
                                    .height = .{ .fixed = 120 },
                                    .direction = .vertical,
                                    .background = .{ .color = .{ 0.10, 0.20, 0.15, 1.0 } },
                                    .borderRadius = 8.0,
                                    .padding = .all(8),
                                },
                            })({
                                const rightScrolling = forbear.useState(forbear.ScrollingState, .{});
                                forbear.useScrolling(rightScrolling);
                                forbear.ScrollBar(rightScrolling);
                                forbear.text("Right 1");
                                forbear.text("Right 2");
                                forbear.text("Right 3");
                                forbear.text("Right 4");
                                forbear.text("Right 5");
                            });
                        });
                    });

                    forbear.FocusContext.use().resolve();
                    forbear.ScrollingContext.use().resolve();
                });
            });
        });
    });
}

fn renderingMain(
    allocator: std.mem.Allocator,
    renderer: *forbear.Graphics.Renderer,
    io: std.Io,
    window: *forbear.Window,
) !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    defer arenaAllocator.deinit();
    errdefer window.running = false;

    const arena = arenaAllocator.allocator();

    try forbear.registerFont("Inter", @embedFile("Inter.ttf"));

    _ = io;
    // var traceFile = try std.Io.Dir.cwd().createFile(io, "layouting.log", .{});
    // defer traceFile.close(io);
    // var traceBuffer: [4096]u8 = undefined;
    // var traceWriter = traceFile.writer(io, &traceBuffer);

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
        })({
            App();

            const rootTree = try forbear.layout();
            // try rootTree.dump(&traceWriter.interface);
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

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    var graphics = try forbear.Graphics.init(
        allocator,
        "forbear playground",
    );
    defer graphics.deinit();

    const window = try forbear.Window.init(
        allocator,
        init.io,
        800,
        600,
        "forbear playground",
        "forbear.playground",
    );
    defer window.deinit();

    var renderer = try graphics.initRenderer(window);
    defer renderer.deinit();

    try forbear.init(allocator, init.io, window, &renderer);
    defer forbear.deinit();

    const renderingThread = try std.Thread.spawn(
        .{ .allocator = allocator },
        renderingMain,
        .{
            allocator,
            &renderer,
            init.io,
            window,
        },
    );
    defer renderingThread.join();

    try window.handleEvents();
}
