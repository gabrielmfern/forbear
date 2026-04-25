const std = @import("std");
const forbear = @import("root.zig");

const Vec4 = @Vector(4, f32);

pub fn FpsCounter() void {
    forbear.component(.{})({
        const deltaTime = forbear.useDeltaTime();
        const fps = if (deltaTime == 0) 0 else 1.0 / deltaTime;

        forbear.element(.{ .style = .{
            .placement = .{ .fixed = .{ 10, 10 } },
            .zIndex = 10,
            .background = .{ .color = .{ 0.0, 0.0, 0.0, 0.9 } },
            .fontSize = 16,
            .textWrapping = .none,
            .minWidth = 152,
            .padding = .all(4),
            .borderRadius = 4,
            .color = .{ 1.0, 1.0, 0.0, 1.0 },
            .direction = .vertical,
        } })({
            forbear.element(.{ .style = .{
                .width = .{ .grow = 1.0 },
            } })({
                forbear.text("FPS:");
                forbear.element(.{ .style = .{ .width = .{ .grow = 1.0 } } })({});
                forbear.printText("{d:.1}", .{fps});
            });
            forbear.element(.{ .style = .{
                .width = .{ .grow = 1.0 },
            } })({
                forbear.text("delta time:");
                forbear.element(.{ .style = .{ .width = .{ .grow = 1.0 } } })({});
                forbear.printText("{d:.1}ms", .{deltaTime * 1000.0});
            });
        });
    });
}
