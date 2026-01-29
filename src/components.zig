const std = @import("std");
const forbear = @import("root.zig");

const Vec4 = @Vector(4, f32);

pub fn FpsCounter() !forbear.Node {
    const arena = try forbear.useArena();

    const deltaTime = forbear.useDeltaTime();
    const fps = if (deltaTime == 0) 0 else 1.0 / deltaTime;

    return forbear.div(.{ .style = .{
        .placement = .{ .manual = .{ 10, 10 } },
        .zIndex = 10,
        .background = .{ .color = .{ 0.0, 0.0, 0.0, 0.5 } },
        .fontSize = 12,
        .paddingBlock = .{ 4, 4 },
        .paddingInline = .{ 4, 4 },
        .borderRadius = 2,
        .color = .{ 1.0, 1.0, 0.0, 1.0 },
        .direction = .topToBottom,
    }, .children = try forbear.children(arena, .{
        forbear.div(.{ .children = try forbear.children(arena, .{
            std.fmt.allocPrint(arena, "FPS: {d:.1}", .{fps}),
        }) }),
        forbear.div(.{ .children = try forbear.children(arena, .{
            std.fmt.allocPrint(arena, "delta time: {d:.1}ms", .{deltaTime * 1000.0}),
        }) }),
    }) });
}
