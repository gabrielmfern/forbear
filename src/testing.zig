const std = @import("std");
const BaseStyle = @import("node.zig").BaseStyle;
const forbear = @import("root.zig");

pub fn frameMeta(arena: std.mem.Allocator) !forbear.FrameMeta {
    try forbear.registerFont("Inter", @embedFile("./Inter.ttf"));
    return forbear.FrameMeta{
        .arena = arena,
        .dpi = .{ 72.0, 72.0 },
        .viewportSize = .{ 800, 600 },
        .baseStyle = BaseStyle{
            .font = try forbear.useFont("Inter"),
            .color = .{ 0.0, 0.0, 0.0, 1.0 },
            .fontSize = 16,
            .fontWeight = 400,
            .lineHeight = 1.0,
            .textWrapping = .none,
            .blendMode = .normal,
            .cursor = .default,
        },
    };
}
