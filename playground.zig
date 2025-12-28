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
        const milli: f64 = @floatFromInt(std.time.milliTimestamp());
        const t = milli / 1000.0;
        try renderer.drawFrame(
            .{
                @floatCast(std.math.cos(t) * 400 + 600),
                @floatCast(std.math.sin(t) * 400 + 600),
                0.0,
            },
            .{ 1.0, 1.0, 1.0, 1.0 },
        );
    }
}
