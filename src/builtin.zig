const std = @import("std");
const builtin = @import("builtin");
const forbear = @import("root.zig");

const Vec2 = @Vector(2, f32);
const Vec4 = @Vector(4, f32);

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

const ScrollingState = struct {
    offset: Vec2,
    effectiveOffset: Vec2,
    animate: bool,
};

pub fn useScrolling() *ScrollingState {
    const node = forbear.getParentNode() orelse {
        std.log.err("useScrolling must be used within a node, that's within component", .{});
        forbear.handleFrameError(error.NoParentForScrollingHook);
        return @constCast(&std.mem.zeroes(ScrollingState));
    };
    const identity: Vec2 = @splat(0.0);

    const state = forbear.useState(ScrollingState, .{
        .offset = identity,
        .effectiveOffset = identity,
        .animate = if (builtin.os.tag == .macos) false else true,
    });

    if (forbear.on(.scroll)) |delta| {
        state.offset += delta;
    }

    state.offset = @min(
        @max(state.offset, identity),
        @max(
            if (forbear.useNodeMeasurement()) |measurement|
                measurement.contentSize - measurement.size
            else
                identity,
            identity,
        ),
    );

    const spring = forbear.SpringConfig{
        .stiffness = 320.0,
        .damping = 32.0,
        .mass = 1.0,
    };
    var animated = Vec2{
        forbear.useSpringTransition(state.offset[0], spring),
        forbear.useSpringTransition(state.offset[1], spring),
    };
    animated = @min(
        @max(state.effectiveOffset, identity),
        @max(
            if (forbear.useNodeMeasurement()) |measurement|
                measurement.contentSize - measurement.size
            else
                identity,
            identity,
        ),
    );
    if (state.animate) {
        state.effectiveOffset = animated;
    } else {
        state.effectiveOffset = state.offset;
    }

    node.childrenOffset = -state.effectiveOffset;
    return state;
}

pub fn ScrollBar(state: *ScrollingState) void {
    if (forbear.useNodeMeasurement()) |parentMeasurement| {
        if (parentMeasurement.contentSize[1] > parentMeasurement.size[1]) {
            forbear.component(.{ .sourceLocation = @src() })({
                const expanded = forbear.useState(bool, false);

                const scrollbarWidth = forbear.useTransition(
                    f32,
                    if (expanded.*) 11.0 else 7.0,
                    0.15,
                    forbear.easeOut,
                );

                // track
                forbear.element(.{
                    .style = .{
                        .placement = .{ .relative = .{ parentMeasurement.size[0] - scrollbarWidth, 0.0 } },
                        .width = .{ .fixed = scrollbarWidth },
                        .height = .{ .fixed = parentMeasurement.size[1] },
                    },
                })({
                    if (forbear.on(.mouseEnter)) {
                        expanded.* = true;
                    }
                    if (forbear.on(.mouseLeave)) {
                        expanded.* = false;
                    }

                    // thumb
                    forbear.element(.{
                        .style = .{
                            .width = .{ .grow = 1.0 },
                            .height = .{ .fixed = parentMeasurement.size[1] * parentMeasurement.size[1] / parentMeasurement.contentSize[1] },
                            .placement = .{
                                .relative = Vec2{
                                    0,
                                    if (scrollingOffset[1] == 0)
                                        0.0
                                    else
                                        parentMeasurement.size[1] * (scrollingOffset[1] / parentMeasurement.contentSize[1]),
                                },
                            },
                            .borderRadius = 6.0,
                            .background = .{
                                .color = forbear.useTransition(
                                    Vec4,
                                    if (expanded.*) forbear.hex("#D0D0D0") else forbear.hex("#8D8D8D"),
                                    0.15,
                                    forbear.easeOut,
                                ),
                            },
                        },
                    })({
                        if (forbear.on(.mouseMove)) |delta| {
                            scrollingOffset[1] += delta[1] * parentMeasurement.contentSize[1] / parentMeasurement.size[1];
                        }
                    });
                });
            });
        }
    }
}
