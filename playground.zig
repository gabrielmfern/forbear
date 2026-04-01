const std = @import("std");
const forbear = @import("forbear");

fn CounterExample() void {
    forbear.component("counter-example")({
        const count = forbear.useState(u32, 0);

        forbear.element(.{
            .direction = .vertical,
            .padding = .all(16.0),
            .background = .{ .color = .{ 0.12, 0.12, 0.12, 1.0 } },
            .borderRadius = 12.0,
        })({
            forbear.printText("Count: {d}", .{count.*});

            forbear.element(.{
                .margin = .top(12.0),
                .padding = forbear.Padding.block(10.0).withInLine(16.0),
                .background = .{ .color = .{ 0.0, 0.0, 0.0, 1.0 } },
                .borderRadius = 8.0,
                .cursor = .pointer,
            })({
                if (forbear.on(.click)) |_| {
                    count.* += 1;
                }

                forbear.text("Increment");
            });
        });
    });
}

fn App() void {
    forbear.component("app")({
        const isHovering = forbear.useState(bool, false);

        forbear.element(.{
            .width = .grow,
            .direction = .vertical,
            .background = .{ .color = .{ 0.2, 0.2, 0.2, 1.0 } },
            .padding = .all(10),
        })({
            forbear.FpsCounter();

            forbear.text("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]]{{}}|;':\",.<>/?`~");
            forbear.element(.{
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
            })({
                if (forbear.on(.mouseOver)) |_| {
                    isHovering.* = true;
                }
                if (forbear.on(.mouseOut)) |_| {
                    isHovering.* = false;
                }
            });

            CounterExample();
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
                .cursor = .default,
            },
            .dpi = .{ @floatFromInt(window.dpi[0]), @floatFromInt(window.dpi[1]) },
        })({
            App();

            const rootTree = try forbear.layout();
            try renderer.drawFrame(
                arena,
                rootTree,
                .{ 1.0, 1.0, 1.0, 1.0 },
                window.dpi,
                window.targetFrameTimeNs(),
            );

            try forbear.update();
        });
    }
    try renderer.waitIdle();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() == .leak) {
            std.log.err("Memory was leaked", .{});
        }
    }

    const allocator = gpa.allocator();

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

    try forbear.init(allocator, &renderer);
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
