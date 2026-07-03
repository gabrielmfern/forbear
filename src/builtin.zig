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
    virtualSize: u64,
    resident_size: u64,
    residentSizeMax: u64,
    userTime: MachTimeValue,
    systemTime: MachTimeValue,
    policy: i32,
    suspendCount: i32,
};
const MACH_TASK_BASIC_INFO: u32 = 20;

fn processResidentBytes() u64 {
    switch (builtin.os.tag) {
        .linux => {
            const io = forbear.useIo();
            const file = std.Io.Dir.openFileAbsolute(io, "/proc/self/statm", .{}) catch |err| {
                forbear.handleFrameError(err);
                return 0;
            };
            defer file.close(io);

            var buffer: [64]u8 = undefined;
            const bytesRead = file.readPositionalAll(io, &buffer, 0) catch |err| {
                forbear.handleFrameError(err);
                return 0;
            };
            var it = std.mem.tokenizeScalar(u8, buffer[0..bytesRead], ' ');
            _ = it.next() orelse return 0;
            const rssPages = std.fmt.parseInt(u64, it.next() orelse return 0, 10) catch return 0;
            return rssPages * std.heap.pageSize();
        },
        .windows => {
            var counters: PROCESS_MEMORY_COUNTERS = .{};
            if (GetProcessMemoryInfo(GetCurrentProcess(), &counters, @sizeOf(PROCESS_MEMORY_COUNTERS)) == 0) {
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

// win32 internals required to get memory information
extern fn mach_task_self() u32;
extern fn task_info(
    targetTask: u32,
    flavor: u32,
    taskInfoOut: *anyopaque,
    taskInfoCount: *u32,
) c_int;

const DWORD = u32;
const SIZE_T = usize;
const HANDLE = *anyopaque;
const BOOL = c_int;

const PROCESS_MEMORY_COUNTERS = extern struct {
    cb: DWORD = @sizeOf(PROCESS_MEMORY_COUNTERS),
    PageFaultCount: DWORD = 0,
    PeakWorkingSetSize: SIZE_T = 0,
    WorkingSetSize: SIZE_T = 0,
    QuotaPeakPagedPoolUsage: SIZE_T = 0,
    QuotaPagedPoolUsage: SIZE_T = 0,
    QuotaPeakNonPagedPoolUsage: SIZE_T = 0,
    QuotaNonPagedPoolUsage: SIZE_T = 0,
    PagefileUsage: SIZE_T = 0,
    PeakPagefileUsage: SIZE_T = 0,
};

extern "user32" fn GetCurrentProcess() callconv(.c) HANDLE;

extern "psapi" fn GetProcessMemoryInfo(
    Process: HANDLE,
    ppsmemCounters: *PROCESS_MEMORY_COUNTERS,
    cb: DWORD,
) callconv(.c) BOOL;

const identity: Vec2 = @splat(0.0);
pub const ScrollingState = struct {
    offset: Vec2 = identity,
    /// The animated offset, if no animation, the same as offset.
    ///
    /// It should not be manipulated directly.
    _effectiveOffset: Vec2 = identity,
    animate: bool = if (builtin.os.tag == .macos) false else true,
};

pub fn useScrolling(state: *ScrollingState) void {
    forbear.hook();
    defer forbear.hookEnd();

    const node = forbear.getParentNode() orelse {
        std.log.err("useScrolling must be used within a node, that's within component", .{});
        forbear.handleFrameError(error.NoParentForScrollingHook);
        return;
    };

    if (forbear.onScroll()) |delta| {
        state.offset += delta;
    }

    state.offset =
        if (forbear.useNodeMeasurement()) |measurement|
            @min(
                @max(state.offset, identity),
                @max(
                    measurement.contentSize - measurement.size,
                    identity,
                ),
            )
        else
            @max(state.offset, identity);

    var animated = Vec2{
        forbear.useSpringTransition(
            state.offset[0],
            forbear.SpringConfig{
                .stiffness = 320.0,
                .damping = 32.0,
                .mass = 1.0,
                .current = &state._effectiveOffset[0],
            },
        ),
        forbear.useSpringTransition(
            state.offset[1],
            forbear.SpringConfig{
                .stiffness = 320.0,
                .damping = 32.0,
                .mass = 1.0,
                .current = &state._effectiveOffset[1],
            },
        ),
    };
    animated =
        if (forbear.useNodeMeasurement()) |measurement|
            @min(
                @max(animated, identity),
                @max(
                    measurement.contentSize - measurement.size,
                    identity,
                ),
            )
        else
            @max(animated, identity);
    if (state.animate) {
        state._effectiveOffset = animated;
    } else {
        state._effectiveOffset = state.offset;
    }

    node.childrenOffset = -state._effectiveOffset;
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
                                    if (state._effectiveOffset[1] == 0)
                                        0.0
                                    else
                                        trackHeight * (state._effectiveOffset[1] / parentMeasurement.contentSize[1]),
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

                    if (forbear.onMouseEnter()) {
                        isHovered.* = true;
                    }
                    if (forbear.onMouseLeave()) {
                        isHovered.* = false;
                    }
                    if (forbear.onMouseDown()) {
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

const InputState = struct {
    cursor: usize,
    selection: [2]usize,
    text: ?std.ArrayList(u8),
};

const wordSeparators = [_]u8{ '_', ' ', '-', '/', '`', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '=', '+', '~', '.', ',', '?', '[', ']', '"', '\'', '{', '}', '\\', '|' };

fn isWordSeparator(char: u8) bool {
    return std.mem.indexOfScalar(u8, &wordSeparators, char) != null;
}

fn previousWordBeginning(text: []const u8, from: usize) usize {
    var position = from;
    while (position > 0 and isWordSeparator(text[position - 1])) position -= 1;
    while (position > 0 and !isWordSeparator(text[position - 1])) position -= 1;
    return position;
}

fn nextWordBeginning(text: []const u8, from: usize) usize {
    var position = from;
    while (position < text.len and !isWordSeparator(text[position])) position += 1;
    while (position < text.len and isWordSeparator(text[position])) position += 1;
    return position;
}

/// Depends on the font styles of the parent to render.
pub fn useInput(initialInputState: struct {
    cursor: usize,
    selection: [2]usize,
    text: []const u8,
}) *InputState {
    forbear.hook();
    defer forbear.hookEnd();

    const arena = forbear.useScopeArena();

    const inputState = forbear.useState(InputState, InputState{
        .cursor = initialInputState.cursor,
        .selection = initialInputState.selection,
        .text = null,
    });
    if (inputState.text == null) create: {
        var textArray = std.ArrayList(u8).initCapacity(arena, initialInputState.text.len) catch |err| {
            forbear.handleFrameError(err);
            break :create;
        };
        textArray.appendSliceAssumeCapacity(initialInputState.text);
        inputState.text = textArray;
    }

    const focusContext = FocusContext.use();

    if (forbear.getParentNode()) |_| {
        if (focusContext.hasFocus()) {
            if (inputState.text) |*text| {
                std.debug.assert(inputState.cursor <= text.items.len);
                std.debug.assert(inputState.selection[0] <= inputState.selection[1]);
                std.debug.assert(inputState.selection[0] <= text.items.len);
                std.debug.assert(inputState.selection[1] <= text.items.len);

                const keysDown = forbear.onKeyDown();
                const hasSelection = inputState.selection[0] != inputState.selection[1];
                // The selection endpoint the cursor is not on. With no selection
                // both endpoints sit on the cursor, so the anchor is the cursor.
                const anchor = if (inputState.cursor == inputState.selection[0])
                    inputState.selection[1]
                else
                    inputState.selection[0];

                const movedTo: ?usize = if (keysDown.arrowLeft)
                    if (keysDown.control)
                        previousWordBeginning(text.items, inputState.cursor)
                    else if (hasSelection and !keysDown.shift)
                        inputState.selection[0]
                    else
                        inputState.cursor -| 1
                else if (keysDown.arrowRight)
                    if (keysDown.control)
                        nextWordBeginning(text.items, inputState.cursor)
                    else if (hasSelection and !keysDown.shift)
                        inputState.selection[1]
                    else
                        @min(inputState.cursor + 1, text.items.len)
                else if (keysDown.home)
                    0
                else if (keysDown.end)
                    text.items.len
                else
                    null;

                if (movedTo) |newCursor| {
                    inputState.cursor = newCursor;
                    inputState.selection = if (keysDown.shift)
                        .{ @min(anchor, newCursor), @max(anchor, newCursor) }
                    else
                        .{ newCursor, newCursor };
                }

                if (keysDown.backspace or keysDown.delete) {
                    if (inputState.selection[0] != inputState.selection[1]) {
                        text.replaceRangeAssumeCapacity(
                            inputState.selection[0],
                            inputState.selection[1] - inputState.selection[0],
                            &.{},
                        );
                        inputState.cursor = inputState.selection[0];
                    } else if (keysDown.backspace and inputState.cursor > 0) {
                        const start = if (keysDown.control)
                            previousWordBeginning(text.items, inputState.cursor)
                        else
                            inputState.cursor - 1;
                        text.replaceRangeAssumeCapacity(start, inputState.cursor - start, &.{});
                        inputState.cursor = start;
                    } else if (keysDown.delete and inputState.cursor < text.items.len) {
                        const end = if (keysDown.control)
                            nextWordBeginning(text.items, inputState.cursor)
                        else
                            inputState.cursor + 1;
                        text.replaceRangeAssumeCapacity(inputState.cursor, end - inputState.cursor, &.{});
                    }
                    inputState.selection = .{ inputState.cursor, inputState.cursor };
                }

                if (forbear.onInput()) |typed| insert: {
                    if (inputState.selection[0] != inputState.selection[1]) {
                        text.replaceRangeAssumeCapacity(
                            inputState.selection[0],
                            inputState.selection[1] - inputState.selection[0],
                            &.{},
                        );
                        inputState.cursor = inputState.selection[0];
                        inputState.selection = .{ inputState.cursor, inputState.cursor };
                    }
                    text.insertSlice(arena, inputState.cursor, typed) catch |err| {
                        forbear.handleFrameError(err);
                        break :insert;
                    };
                    inputState.cursor += typed.len;
                    inputState.selection = .{ inputState.cursor, inputState.cursor };
                }
            }
        }
    }

    return inputState;
}

pub fn InputCaret(inputState: *const InputState) void {
    _ = inputState;
    forbear.component(.{})({
        // we need the width of the text until the cursor here
        // what are the text styles?
    });
}

/// Runtime-tagged form of an event + its result. Mirrors `forbear.Event`
/// one-for-one, with each variant carrying the payload type that
/// `forbear.OnResult(tag)` returns for the matching event.
pub const EventPayload = union(forbear.Event) {
    mouseEnter: bool,
    mouseLeave: bool,
    mouseDown: bool,
    mouseDownOutside: bool,
    mouseUp: bool,
    mouseMove: ?Vec2,
    click: bool,
    scroll: ?Vec2,
    keyDown: forbear.Keys,
    keyUp: forbear.Keys,
    input: ?[]const u8,
};

/// Reports what part of `payload` the element consumes: `null` for none of
/// it, or the same event tag trimmed down to just what it acts on — e.g. an
/// input returns only the caret-movement/editing bits of a `keyDown`, leaving
/// the rest for everyone else.
pub const FocusConsumes = *const fn (payload: EventPayload) ?EventPayload;

pub const Focus = struct {
    key: u64,
    consumes: ?FocusConsumes,
};

pub const FocusContext = forbear.createContext(opaque {}, struct {
    focused: ?Focus,
    focusable: std.ArrayList(Focus),
    scopeKey: u64,

    pub fn register(self: *@This(), consumesFn: ?FocusConsumes) void {
        const node = forbear.getParentNode() orelse {
            forbear.handleFrameError(error.NoParentForFocusRegistration);
            return;
        };
        const arena = forbear.getScopeArenaBy(self.scopeKey) orelse unreachable;
        self.focusable.append(arena, .{
            .key = node.key,
            .consumes = consumesFn,
        }) catch |err| forbear.handleFrameError(err);
        if (self.focused != null and self.focused.?.key == node.key and forbear.isMouseButtonPressed() and !forbear.isMouseInside()) {
            self.focused = null;
        }
    }

    pub fn focus(self: *@This()) void {
        const node = forbear.getParentNode() orelse return;
        for (self.focusable.items) |f| {
            if (f.key == node.key) {
                self.focused = f;
                return;
            }
        }
    }

    pub fn hasFocus(self: *const @This()) bool {
        // TODO(footgun): I can't call this inside of a style definition,
        // because the parent node is not yet defined. it's only defined after
        // the body of element function runs, which is after the style paramter
        // "runs"
        const node = forbear.getParentNode() orelse return false;
        const f = self.focused orelse return false;
        return f.key == node.key;
    }

    /// The portion of `result` the focused element consumes, so callers can
    /// trim it away, e.g. `keys.without(ctx.consumes(.keyDown, keys))`.
    pub fn consumes(
        self: *const @This(),
        comptime eventTag: forbear.Event,
        result: forbear.OnResult(eventTag),
    ) forbear.OnResult(eventTag) {
        const none: forbear.OnResult(eventTag) = switch (eventTag) {
            .keyDown, .keyUp => .{},
            .mouseMove, .scroll, .input => null,
            else => false,
        };
        const f = self.focused orelse return none;
        const func = f.consumes orelse return none;
        const payload = @unionInit(EventPayload, @tagName(eventTag), result);
        const consumed = func(payload) orelse return none;
        return @field(consumed, @tagName(eventTag));
    }

    pub fn resolve(self: *@This()) void {
        defer self.focusable.clearRetainingCapacity();

        if (self.focused) |f| validate: {
            for (self.focusable.items) |item| {
                if (item.key == f.key) {
                    break :validate;
                }
            }
            self.focused = null;
        }

        const pressed = forbear.onKeyDown();
        const items = self.focusable.items;
        if (pressed.tab and items.len > 0) {
            const shift = pressed.shift;
            if (self.focused) |current| {
                var idx: usize = 0;
                for (items, 0..) |item, i| {
                    if (item.key == current.key) {
                        idx = i;
                        break;
                    }
                }
                const newIdx = if (shift)
                    (idx + items.len - 1) % items.len
                else
                    (idx + 1) % items.len;
                self.focused = items[newIdx];
            } else {
                self.focused = items[0];
            }
        }
        if (pressed.escape) {
            self.focused = null;
        }
    }
});

pub fn FocusProvider() *const fn (void) void {
    forbear.component(.{})({
        FocusContext.Provider(.{
            .focused = null,
            .focusable = .empty,
            .scopeKey = forbear.useScopeKey(),
        })({
            forbear.componentChildrenSlot();
        });
    });
    return forbear.componentChildrenSlotEnd();
}
