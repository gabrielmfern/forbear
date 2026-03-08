const std = @import("std");
const forbear = @import("forbear");

fn App() !void {
    forbear.component("app")({
        const isHovering = try forbear.useState(bool, false);

        forbear.element(.{
            .width = .grow,
            .background = .{ .color = .{ 0.2, 0.2, 0.2, 1.0 } },
            .padding = .inLine(10),
        })({
            try forbear.FpsCounter();

            forbear.text("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]]{{}}|;':\",.<>/?`~");
            forbear.element(.{
                .width = .{ .fixed = 100 },
                .height = .{ .fixed = 100 },
                .background = .{
                    .color = .{
                        1.0,
                        try forbear.useTransition(if (isHovering.*) 0.0 else 0.3, 0.1, forbear.linear),
                        0.0,
                        1.0,
                    },
                },
                .borderRadius = 20,
            })({});

            while (forbear.useNextEvent()) |event| {
                switch (event) {
                    .mouseOver => {
                        isHovering.* = true;
                    },
                    .mouseOut => {
                        isHovering.* = false;
                    },
                }
            }
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
