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

    const graphics = try forbear.Graphics.init(
        "forbear playground",
        allocator,
    );
    defer graphics.deinit();
}
