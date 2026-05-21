const std = @import("std");
const builtin = @import("builtin");
const forbear = @import("root.zig");

const Vec2 = @Vector(2, f32);
const Vec4 = @Vector(4, f32);

pub const ProfilingMetricsProps = struct {
    fps: bool = true,
    deltaTime: bool = true,
    memory: bool = true,
};

pub fn ProfilingMetrics(props: ProfilingMetricsProps) void {
    forbear.component(.{})({
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
            if (props.fps) {
                const deltaTime = forbear.useDeltaTime();
                const fps = if (deltaTime == 0) 0 else 1.0 / deltaTime;
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
            }

            if (props.deltaTime) {
                const deltaTime = forbear.useDeltaTime();
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
            }

            if (props.memory) {
                const mib = @as(f32, @floatFromInt(processResidentBytes())) / (1024.0 * 1024.0);
                forbear.element(.{
                    .style = .{
                        .width = .{ .grow = 1.0 },
                    },
                })({
                    forbear.text("memory:");
                    forbear.element(.{
                        .style = .{ .width = .{ .grow = 1.0 } },
                    })({});
                    forbear.printText("{d:.1} MB", .{mib});
                });
            }
        });
    });
}

const MachTimeValue = extern struct {
    seconds: i32,
    microseconds: i32,
};
const MachTaskBasicInfo = extern struct {
    virtual_size: u64,
    resident_size: u64,
    resident_size_max: u64,
    user_time: MachTimeValue,
    system_time: MachTimeValue,
    policy: i32,
    suspend_count: i32,
};
const MACH_TASK_BASIC_INFO: u32 = 20;

extern fn mach_task_self() u32;
extern fn task_info(
    target_task: u32,
    flavor: u32,
    task_info_out: *anyopaque,
    task_info_count: *u32,
) c_int;

fn processResidentBytes() u64 {
    switch (builtin.os.tag) {
        .linux => {
            const io = forbear.useIo();
            const file = std.Io.Dir.openFileAbsolute(io, "/proc/self/statm", .{}) catch |err| {
                forbear.handleFrameError(err);
                return 0;
            };
            var buffer: [64]u8 = undefined;
            const bytesRead = file.readPositionalAll(io, &buffer, 0) catch |err| {
                forbear.handleFrameError(err);
                return 0;
            };
            var it = std.mem.tokenizeScalar(u8, buffer[0..bytesRead], ' ');
            _ = it.next() orelse return 0;
            const rss_pages = std.fmt.parseInt(u64, it.next() orelse return 0, 10) catch return 0;
            return rss_pages * std.heap.pageSize();
        },
        .windows => {
            const win32 = @import("windows/win32.zig");
            var counters: win32.PROCESS_MEMORY_COUNTERS = .{};
            if (win32.GetProcessMemoryInfo(win32.GetCurrentProcess(), &counters, @sizeOf(win32.PROCESS_MEMORY_COUNTERS)) == 0) {
                return 0;
            }
            return counters.WorkingSetSize;
        },
        .macos => {
            var info: MachTaskBasicInfo = undefined;
            var count: u32 = @sizeOf(MachTaskBasicInfo) / @sizeOf(u32);
            if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO, @ptrCast(&info), &count) != 0) {
                return 0;
            }
            return info.resident_size;
        },
        else => @compileError("memory watching is unsupported for " ++ @tagName(builtin.os.tag)),
    }
}

const ScrollingState = struct {
    offset: Vec2,
    effectiveOffset: Vec2,
    animate: bool,
};

pub fn useScrolling() *ScrollingState {
    forbear.hook();
    defer forbear.hookEnd();

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
        @max(animated, identity),
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
                                    forbear.rgba(180, 180, 180, 0.0),
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
