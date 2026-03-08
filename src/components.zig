const std = @import("std");
const forbear = @import("root.zig");

const Vec4 = @Vector(4, f32);

pub fn FpsCounter() void {
    forbear.component("forbear-native-fps-counter")({
        const arena = forbear.useArena() catch |err| {
            forbear.handleFrameError(err);
            return;
        };

        const deltaTime = forbear.useDeltaTime();
        const fps = if (deltaTime == 0) 0 else 1.0 / deltaTime;

        forbear.element(.{
            .placement = .{ .manual = .{ 10, 10 } },
            .zIndex = 10,
            .background = .{ .color = .{ 0.0, 0.0, 0.0, 0.9 } },
            .fontSize = 12,
            .padding = .all(4),
            .borderRadius = 2,
            .color = .{ 1.0, 1.0, 0.0, 1.0 },
            .direction = .topToBottom,
        })({
            forbear.text(std.fmt.allocPrint(arena, "FPS: {d:.1}", .{fps}) catch |err| {
                forbear.handleFrameError(err);
                return;
            });
            forbear.text(std.fmt.allocPrint(arena, "delta time: {d:.1}ms", .{deltaTime * 1000.0}) catch |err| {
                forbear.handleFrameError(err);
                return;
            });
        });
    });
}
