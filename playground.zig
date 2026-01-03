const std = @import("std");
const forbear = @import("forbear");

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

    var renderer = try graphics.initRenderer(window);
    defer renderer.deinit();
    renderer.setupResizingHandler(window);

    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    const inter = try forbear.Font.init("Inter-Regular", @embedFile("Inter-Regular.ttf"));

    while (window.running) {
        defer _ = arenaAllocator.reset(.retain_capacity);

        try window.handleEvents();
        const node = forbear.div(.{
            .style = .{
                .preferredWidth = .grow,
                .backgroundColor = .{ 0.2, 0.2, 0.2, 1.0 },
            },
            .children = try forbear.children(.{
                "This is some text introducing things",
                forbear.div(.{
                    .style = .{
                        .preferredWidth = .{ .fixed = 100 },
                        .preferredHeight = .{ .fixed = 100 },
                        .backgroundColor = .{ 1.0, 0.0, 0.0, 1.0 },
                        .borderRadius = 20,
                    },
                }),
            }, arena),
        });
        const layoutBox = try forbear.layout(
            node,
            .{ .font = inter, .fontSize = 32, .lineHeight = 1.0 },
            renderer.viewportSize(),
            .{ @floatFromInt(window.dpi[0]), @floatFromInt(window.dpi[1]) },
            arena,
        );
        try renderer.drawFrame(&layoutBox);
    }
}
