const std = @import("std");
const builtin = @import("builtin");
const forbear = @import("root.zig");

const Vec2 = @Vector(2, f32);

pub fn FpsCounter() void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
        const deltaTime = forbear.useDeltaTime();
        const fps = if (deltaTime == 0) 0 else 1.0 / deltaTime;

        forbear.element(.{
            .style = .{
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
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                },
            })({
                forbear.text("FPS:");
                forbear.element(.{
                    .style = .{ .width = .{ .grow = 1.0 } },
                })({});
                forbear.printText("{d:.1}", .{fps});
            });
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                },
            })({
                forbear.text("delta time:");
                forbear.element(.{
                    .style = .{ .width = .{ .grow = 1.0 } },
                })({});
                forbear.printText("{d:.1}ms", .{deltaTime * 1000.0});
            });
        });
    });
}

pub fn useScrolling() Vec2 {
    const node = forbear.getParentNode() orelse {
        std.log.err("useScrolling must be used within a node, that's within component", .{});
        forbear.handleFrameError(error.NoParentForScrollingHook);
        return @splat(0.0);
    };
    const identity: Vec2 = @splat(0.0);
    const scrollOffset = forbear.useState(Vec2, identity);

    if (forbear.on(.scroll)) |delta| {
        scrollOffset.* += delta;
    }

    scrollOffset.* = @min(
        @max(scrollOffset.*, identity),
        @max(
            if (forbear.useNodeMeasurement()) |measurement|
                measurement.contentSize - measurement.size
            else
                identity,
            identity,
        ),
    );

    if (builtin.os.tag == .macos) {
        node.childrenOffset = -scrollOffset.*;
        return scrollOffset.*;
    } else {
        const spring = forbear.SpringConfig{
            .stiffness = 320.0,
            .damping = 32.0,
            .mass = 1.0,
        };
        var aniamtedOffset = Vec2{
            forbear.useSpringTransition(scrollOffset.*[0], spring),
            forbear.useSpringTransition(scrollOffset.*[1], spring),
        };
        aniamtedOffset = @min(
            @max(aniamtedOffset, identity),
            @max(
                if (forbear.useNodeMeasurement()) |measurement|
                    measurement.contentSize - measurement.size
                else
                    identity,
                identity,
            ),
        );
        node.childrenOffset = -aniamtedOffset;
        return aniamtedOffset;
    }
}
