const std = @import("std");
const Forbear = @import("forbear");

fn renderingMain(
    renderer: *Forbear.Graphics.Renderer,
    forbearContext: *Forbear,
    window: *const Forbear.Window,
    allocator: std.mem.Allocator,
) !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    const inter = try Forbear.Font.init("Inter-Regular", @embedFile("Inter-Regular.ttf"));

    var time = std.time.nanoTimestamp();
    var fps: ?u32 = null;
    while (window.running) {
        defer _ = arenaAllocator.reset(.retain_capacity);

        const node = Forbear.div(.{
            .style = .{
                .preferredWidth = .grow,
                .background = .{ .color = .{ 0.2, 0.2, 0.2, 1.0 } },
                .paddingInline = .{ 10, 10 },
            },
            .children = try Forbear.children(.{
                "fps:",
                fps,
                " ",
                "This is some text introducing things",
                Forbear.div(.{
                    .style = .{
                        .preferredWidth = .{ .fixed = 100 },
                        .preferredHeight = .{ .fixed = 100 },
                        .background = .{ .color = .{ 1.0, 0.0, 0.0, 1.0 } },
                        .borderRadius = 20,
                    },
                }),
            }, arena),
        });
        const layoutBox = try Forbear.layout(
            node,
            .{ .font = inter, .color = .{ 1.0, 1.0, 1.0, 1.0 }, .fontSize = 32, .lineHeight = 1.0 },
            .{ @floatFromInt(window.width), @floatFromInt(window.height) },
            .{ @floatFromInt(window.dpi[0]), @floatFromInt(window.dpi[1]) },
            arena,
        );
        try renderer.drawFrame(&layoutBox, .{ 1.0, 1.0, 1.0, 1.0 }, window.dpi, window.targetFrameTimeNs());

        try forbearContext.update(&layoutBox, arena);

        const newCurrentTime = std.time.nanoTimestamp();
        const deltaTime = newCurrentTime - time;
        time = newCurrentTime;
        fps = @intFromFloat(@round(@as(f64, @floatFromInt(std.time.ns_per_s)) / @as(f64, @floatFromInt(deltaTime))));
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

    var graphics = try Forbear.Graphics.init(
        "forbear playground",
        allocator,
    );
    defer graphics.deinit();

    const window = try Forbear.Window.init(
        800,
        600,
        "forbear playground",
        "forbear.playground",
        allocator,
    );
    defer window.deinit();

    var forbearContext = try Forbear.init();
    defer forbearContext.deinit();
    forbearContext.setHandlers(window);

    var renderer = try graphics.initRenderer(window);
    defer renderer.deinit();
    window.setResizeHandler(
        &handleResize,
        @ptrCast(@alignCast(&renderer)),
    );

    const renderingThread = try std.Thread.spawn(
        .{ .allocator = allocator },
        renderingMain,
        .{
            &renderer,
            &forbearContext,
            window,
            allocator,
        },
    );
    defer renderingThread.join();

    try window.handleEvents();
}

fn handleResize(window: *Forbear.Window, width: u32, height: u32, dpi: [2]u32, data: *anyopaque) void {
    _ = window;
    _ = dpi;
    const renderer: *Forbear.Graphics.Renderer = @ptrCast(@alignCast(data));
    renderer.handleResize(width, height) catch |err| {
        std.log.err("Renderer could not handle window resize {}", .{err});
    };
}
