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

    while (window.running) {
        try window.handleEvents();
        try renderer.drawFrame(&.{
            .{
                .position = .{
                    100,
                    100,
                    0.0,
                },
                .scale = .{ 100, 100, 1 },
                .backgroundColor = .{ 1.0, 1.0, 1.0, 1.0 },
                .borderRadius = 10.0,
            },
            .{
                .position = .{
                    200,
                    100,
                    0.0,
                },
                .scale = .{ 100, 100, 1 },
                .backgroundColor = .{ 1.0, 0.0, 1.0, 1.0 },
                .borderRadius = 50.0,
            },
        });
    }
}
