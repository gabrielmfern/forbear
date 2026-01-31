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
        .children = try forbear.children(arena, .{
            forbear.component(forbear.FpsCounter, null, arena),
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;':\",.<>/?`~",
            forbear.div(.{
                .style = .{
                    .preferredWidth = .{ .fixed = 100 },
                    .preferredHeight = .{ .fixed = 100 },
                    .background = .{
                        .color = .{
                            1.0,
                            try forbear.useTransition(if (isHovering.*) 0.0 else 0.3, 0.1, forbear.linear),
                            0.0,
                            1.0,
                        },
                    },
                    .borderRadius = 20,
                },
                .handlers = .{
                    .onMouseOver = .{
                        .data = @ptrCast(@alignCast(isHovering)),
                        .handler = &(struct {
                            fn handler(_: *const forbear.LayoutBox, data: ?*anyopaque) anyerror!void {
                                const isHoveringData: *bool = @ptrCast(data.?);
                                isHoveringData.* = true;
                            }
                        }).handler,
                    },
                    .onMouseOut = .{
                        .data = @ptrCast(@alignCast(isHovering)),
                        .handler = &(struct {
                            fn handler(_: *const forbear.LayoutBox, data: ?*anyopaque) anyerror!void {
                                const isHoveringData: *bool = @ptrCast(data.?);
                                isHoveringData.* = false;
                            }
                        }).handler,
                    },
                },
            }),
        }),
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

    while (window.running) {
        defer _ = arenaAllocator.reset(.retain_capacity);

        const node = try forbear.component(App, null, arena);
        const treeNode = try forbear.resolve(node, arena);
        const viewportSize = renderer.viewportSize();
        const layoutBox = try forbear.layout(
            arena,
            treeNode,
            .{
                .font = try forbear.useFont("Inter", @embedFile("Inter.ttf")),
                .color = .{ 1.0, 1.0, 1.0, 1.0 },
                .textWrapping = .character,
                .fontSize = 32,
                .fontWeight = 400,
                .lineHeight = 1.0,
            },
            viewportSize,
            .{ @floatFromInt(window.dpi[0]), @floatFromInt(window.dpi[1]) },
        );
        try renderer.drawFrame(&layoutBox, .{ 1.0, 1.0, 1.0, 1.0 }, window.dpi, window.targetFrameTimeNs());

        try forbear.update(&layoutBox, viewportSize, arena);
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


