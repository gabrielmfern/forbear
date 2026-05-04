const std = @import("std");
const builtin = @import("builtin");
const forbear = @import("root.zig");

const Vec2 = @Vector(2, f32);
const Vec4 = @Vector(4, f32);

pub fn FpsCounter() void {
    forbear.component(.{})({
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
        // `.relative` placement is measured from the parent's content box
        // (inside its border + padding), so subtract those insets from the
        // parent's outer size to get the box the scrollbar must fit into.
        const parentNode = forbear.getParentNode() orelse return;
        const padding = parentNode.style.padding;
        const border = parentNode.style.borderWidth;
        const innerSize = Vec2{
            parentMeasurement.size[0] - padding.x[0] - padding.x[1] - border.x[0] - border.x[1],
            parentMeasurement.size[1] - padding.y[0] - padding.y[1] - border.y[0] - border.y[1],
        };
        // Track spans the parent's full height between its borders, so it
        // doesn't visually shrink with vertical padding.
        const trackHeight = parentMeasurement.size[1] - border.y[0] - border.y[1];
        if (parentMeasurement.contentSize[1] > innerSize[1]) {
            forbear.component(.{})({
                const isHovered = forbear.useState(bool, false);
                const isDragging = forbear.useState(bool, false);

                const scrollbarWidth = forbear.useTransition(
                    f32,
                    if (isHovered.* or isDragging.*) 11.0 else 7.0,
                    0.15,
                    forbear.easeOut,
                );

                // track
                forbear.element(.{
                    .style = .{
                        .background = .{
                            .color = forbear.useTransition(
                                Vec4,
                                if (isHovered.* or isDragging.*)
                                    forbear.rgba(180, 180, 180, 0.31)
                                else
                                    .{ 0.0, 0.0, 0.0, 0.0 },
                                0.15,
                                forbear.easeOut,
                            ),
                        },
                        .borderStyle = .solid,
                        .borderWidth = .left(1.0),
                        .borderColor = forbear.useTransition(
                            Vec4,
                            if (isHovered.* or isDragging.*)
                                forbear.rgba(200, 200, 200, 0.47)
                            else
                                .{ 0.0, 0.0, 0.0, 0.0 },
                            0.15,
                            forbear.easeOut,
                        ),
                        // Anchor against the parent's outer right edge regardless
                        // of padding/border. `.relative` is measured from the
                        // content box, so we step back out by the right
                        // padding+border and then inward by `scrollbarWidth`.
                        .placement = .{ .relative = .{ innerSize[0] + padding.x[1] + border.x[1] - scrollbarWidth, -padding.y[0] } },
                        .width = .{ .fixed = scrollbarWidth },
                        .height = .{ .fixed = trackHeight },
                        .cursor = .default,
                        .zIndex = 10,
                    },
                })({

                    // thumb
                    forbear.element(.{
                        .style = .{
                            .width = .{ .grow = 1.0 },
                            .height = .{
                                .fixed = trackHeight * innerSize[1] / parentMeasurement.contentSize[1],
                            },
                            .placement = .{
                                .relative = Vec2{
                                    0,
                                    if (state.effectiveOffset[1] == 0)
                                        0.0
                                    else
                                        trackHeight * (state.effectiveOffset[1] / parentMeasurement.contentSize[1]),
                                },
                            },
                            .borderRadius = 6.0,
                            .background = .{
                                .color = forbear.useTransition(
                                    Vec4,
                                    if (isHovered.* or isDragging.*) forbear.rgba(60, 60, 60, 0.78) else forbear.rgba(80, 80, 80, 0.55),
                                    0.15,
                                    forbear.easeOut,
                                ),
                            },
                        },
                    })({});

                    if (forbear.on(.mouseEnter)) {
                        isHovered.* = true;
                    }
                    if (forbear.on(.mouseLeave)) {
                        isHovered.* = false;
                    }
                    if (forbear.on(.mouseDown)) {
                        isDragging.* = true;
                    }
                    if (!forbear.isMouseButtonPressed()) {
                        isDragging.* = false;
                        state.animate = if (builtin.os.tag == .macos) false else true;
                    }
                    if (isDragging.*) {
                        const trackTop = parentMeasurement.position[1] + border.y[0];
                        const localY = forbear.useMousePosition()[1] - trackTop;
                        const thumbHeight = trackHeight * innerSize[1] / parentMeasurement.contentSize[1];
                        const target = (localY - thumbHeight / 2.0) * parentMeasurement.contentSize[1] / trackHeight;
                        state.offset[1] = target;
                        state.animate = false;
                    }
                });
            });
        }
    }
}
