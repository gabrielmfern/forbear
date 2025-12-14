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

    const window = try forbear.Window.init(
        800,
        600,
        "forbear playground",
        "forbear.playground",
        allocator,
    );
    defer window.deinit();

    while (window.running) {
        try window.handle_events();

        try forbear.render(window);

        try window.swap_buffers();
    }
}
