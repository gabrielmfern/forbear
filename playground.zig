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

    const graphics = try forbear.Graphics.init(
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

    const renderer = try graphics.initWaylandRenderer(
        window.wlDisplay,
        window.wlSurface,
        window.width,
        window.height,
        triangleVertexShader,
        triangleFragmentShader,
        allocator,
    );
    defer renderer.deinit();

    while (window.running) {
        try window.handleEvents();
        try renderer.drawFrame();
    }
}
