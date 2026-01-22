const std = @import("std");
const forbear = @import("forbear");

fn App() !forbear.Node {
    const arena = try forbear.useArena();
    const isHovering = try forbear.useState(bool, false);

    return forbear.div(.{
        .style = .{
            .preferredWidth = .grow,
            .background = .{ .color = .{ 0.2, 0.2, 0.2, 1.0 } },
            .paddingInline = .{ 10, 10 },
        },
        .children = try forbear.children(.{
            // "fps:",
            // fps,
            // " ",
            "This is some text introducing things",
            forbear.div(.{
                .style = .{
                    .preferredWidth = .{ .fixed = 100 },
                    .preferredHeight = .{ .fixed = 100 },
                    .background = .{
                        .color = if (isHovering.*) .{ 1.0, 0.0, 0.0, 1.0 } else .{ 1.0, 0.3, 0.0, 1.0 },
                    },
                    .borderRadius = 20,
                },
                .handlers = .{
                    .onMouseOver = .{
                        .data = @ptrCast(@alignCast(isHovering)),
                        .handler = &(struct {
                            fn handler(_: @Vector(2, f32), data: ?*anyopaque) anyerror!void {
                                const isHoveringData: *bool = @ptrCast(data.?);
                                isHoveringData.* = true;
                            }
                        }).handler,
                    },
                    .onMouseOut = .{
                        .data = @ptrCast(@alignCast(isHovering)),
                        .handler = &(struct {
                            fn handler(_: @Vector(2, f32), data: ?*anyopaque) anyerror!void {
                                const isHoveringData: *bool = @ptrCast(data.?);
                                isHoveringData.* = false;
                            }
                        }).handler,
                    },
                },
            }),
        }, arena),
    });
}

fn renderingMain(
    renderer: *forbear.Graphics.Renderer,
    window: *const forbear.Window,
    allocator: std.mem.Allocator,
) !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    const inter = try forbear.Font.init("Inter-Regular", @embedFile("Inter-Regular.ttf"));

    var time = std.time.nanoTimestamp();
    var fps: ?u32 = null;
    while (window.running) {
        defer _ = arenaAllocator.reset(.retain_capacity);

        const node = try forbear.component(App, null, arena);
        const treeNode = try forbear.resolve(node, arena);
        const layoutBox = try forbear.layout(
            treeNode,
            .{ .font = inter, .color = .{ 1.0, 1.0, 1.0, 1.0 }, .fontSize = 32, .lineHeight = 1.0 },
            .{ @floatFromInt(window.width), @floatFromInt(window.height) },
            .{ @floatFromInt(window.dpi[0]), @floatFromInt(window.dpi[1]) },
            arena,
        );
        try renderer.drawFrame(&layoutBox, .{ 1.0, 1.0, 1.0, 1.0 }, window.dpi, window.targetFrameTimeNs());

        try forbear.update(&layoutBox, arena);

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

    var graphics = try forbear.Graphics.init(
        "forbear playground",
        allocator,
    );
    defer graphics.deinit();

    const window = try forbear.Window.init(
        800,
        600,
        "forbear playground",
        "forbear.playground",
        allocator,
    );
    defer window.deinit();

    try forbear.init(allocator);
    defer forbear.deinit();
    forbear.setHandlers(window);

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
            window,
            allocator,
        },
    );
    defer renderingThread.join();

    try window.handleEvents();
}

fn handleResize(window: *forbear.Window, width: u32, height: u32, dpi: [2]u32, data: *anyopaque) void {
    _ = window;
    _ = dpi;
    const renderer: *forbear.Graphics.Renderer = @ptrCast(@alignCast(data));
    renderer.handleResize(width, height) catch |err| {
        std.log.err("Renderer could not handle window resize {}", .{err});
    };
}
