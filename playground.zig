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

    var renderer = try graphics.initRenderer(
        window,
        triangleVertexShader,
        triangleFragmentShader,
    );
    defer renderer.deinit();
    renderer.setupResizingHandler(window);

    const triangleModel = try forbear.Graphics.Model.init(
        &.{
            .{ .position = .{ 0.0, -0.5, 0.0 }, .color = .{ 1.0, 0.0, 0.0 } },
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = .{ 0.0, 1.0, 0.0 } },
            .{ .position = .{ -0.5, 0.5, 0.0 }, .color = .{ 0.0, 0.0, 1.0 } },
        },
        &renderer,
    );
    defer triangleModel.deinit(&renderer);

    while (window.running) {
        try window.handleEvents();
        try renderer.drawFrame(&.{triangleModel});
    }
}
