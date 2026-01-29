const forbear = @import("root.zig");

const Vec4 = @Vector(4, f32);

pub fn FpsCounter() !forbear.Node {
    const arena = try forbear.useArena();

    const deltaTime = forbear.useDeltaTime();
    const fps = 1.0 / deltaTime;

    return forbear.div(.{ .style = .{
        .placement = .{ .manual = .{ 10, 10 } },
        .zIndex = 10,
        .background = .{ .color = .{ 0.0, 0.0, 0.0, 0.5 } },
        .fontSize = 10,
        .color = .{ 0.5, 0.5, 0.0, 1.0 },
        .direction = .topToBottom,
    }, .children = try forbear.children(arena, .{
        forbear.div(.{ .children = try forbear.children(arena, .{
            "FPS: ",
            fps,
        }) }),
        forbear.div(.{ .children = try forbear.children(arena, .{
            "delta time: ",
            deltaTime * 1000.0,
            "ms"
        }) }),
    }) });
}
