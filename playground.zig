const std = @import("std");
const forbear = @import("forbear");

const triangleVertexShader: []const u32 = @ptrCast(@alignCast(@embedFile("triangle_vertex_shader")));
const triangleFragmentShader: []const u32 = @ptrCast(@alignCast(@embedFile("triangle_fragment_shader")));

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

    const graphics = try forbear.Graphics.init(
        "forbear playground",
        window,
        triangleVertexShader,
        triangleFragmentShader,
        allocator,
    );
    defer graphics.deinit();

    while (window.running) {
        try window.handleEvents();
        try graphics.drawFrame();
    }
}
