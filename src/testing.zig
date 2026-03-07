const BaseStyle = @import("node.zig").BaseStyle;
const forbear = @import("root.zig");

pub fn createTestingBaseStyle() !BaseStyle {
    try forbear.registerFont("Inter", @embedFile("./Inter.ttf"));
    return BaseStyle{
        .font = try forbear.useFont("Inter"),
        .color = .{ 0.0, 0.0, 0.0, 1.0 },
        .fontSize = 16,
        .fontWeight = 400,
        .lineHeight = 1.0,
        .textWrapping = .none,
        .blendMode = .normal,
        .cursor = .default,
    };
}
