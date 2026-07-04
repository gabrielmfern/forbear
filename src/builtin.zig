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

    // `contentSize` runs from the border-box origin (so it already carries
    // the leading border + padding) to the last flow child's far edge. Add
    // the trailing border + padding so a full scroll rests the content end
    // inside the padding, mirroring how it sits at the start unscrolled.
    const maxOffset: ?Vec2 = if (forbear.useNodeMeasurement()) |measurement|
        @max(
            measurement.contentSize + Vec2{
                node.style.padding.x[1] + node.style.borderWidth.x[1],
                node.style.padding.y[1] + node.style.borderWidth.y[1],
            } - measurement.size,
            identity,
        )
    else
        null;

    // Inside a `ScrollProvider`, the wheel goes to the innermost hovered
    // scrollable with room left in the delta's direction; without one, every
    // hovered scrollable sees the same `onScroll` and they all move together.
    const scrollingContext = ScrollingContext.useOrNull();

    if (forbear.onScroll()) |delta| {
        state.offset += if (scrollingContext) |context| context.consumes(delta) else delta;
    }

    state.offset = if (maxOffset) |max|
        @min(@max(state.offset, identity), max)
    else
        @max(state.offset, identity);

    // Register after the clamp so the next frame's resolution judges room
    // from where this frame actually settled.
    if (scrollingContext) |context| {
        context.register(.{
            .x = .{ state.offset[0] > 0.0, if (maxOffset) |max| state.offset[0] < max[0] else true },
            .y = .{ state.offset[1] > 0.0, if (maxOffset) |max| state.offset[1] < max[1] else true },
        });
    }

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
    animated = if (maxOffset) |max|
        @min(@max(animated, identity), max)
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

/// Whether a scrollable's offset still has room to move: `[0]` toward the
/// start (offset decreasing), `[1]` toward the end, per axis.
pub const ScrollRoom = struct {
    x: [2]bool = .{ true, true },
    y: [2]bool = .{ true, true },
};

pub const Scrollable = struct {
    key: u64,
    hovered: bool,
    room: ScrollRoom,
};

pub const ScrollingContext = forbear.createContext(opaque {}, struct {
    /// The innermost hovered scrollable with room, per axis and direction, as
    /// of the last `resolve()` — the ones `useScrolling` yields the wheel to.
    targets: [2][2]?u64,
    scrollable: std.ArrayList(Scrollable),
    scopeKey: u64,

    pub fn register(self: *@This(), room: ScrollRoom) void {
        const node = forbear.getParentNode() orelse {
            forbear.handleFrameError(error.NoParentForScrollableRegistration);
            return;
        };
        const arena = forbear.getScopeArenaBy(self.scopeKey) orelse unreachable;
        self.scrollable.append(arena, .{
            .key = node.key,
            .hovered = forbear.isMouseInside(),
            .room = room,
        }) catch |err| forbear.handleFrameError(err);
    }

    /// The portion of `delta` this node gets to scroll by, trimmed the same
    /// way `FocusContext.consumes` trims events.
    pub fn consumes(self: *const @This(), delta: Vec2) Vec2 {
        const node = forbear.getParentNode() orelse return identity;
        var consumed: Vec2 = identity;
        inline for (0..2) |axis| {
            if (delta[axis] != 0.0) {
                const direction: usize = if (delta[axis] > 0.0) 1 else 0;
                if (self.targets[axis][direction]) |targetKey| {
                    if (targetKey == node.key) {
                        consumed[axis] = delta[axis];
                    }
                }
            }
        }
        return consumed;
    }

    pub fn resolve(self: *@This()) void {
        defer self.scrollable.clearRetainingCapacity();
        self.targets = .{ .{ null, null }, .{ null, null } };
        // Ancestors mount before their descendants, so the last hovered
        // registration with room in a direction is the innermost scrollable
        // that can still move that way — one that's run out hands the wheel
        // to its nearest scrollable ancestor.
        for (self.scrollable.items) |scrollable| {
            if (!scrollable.hovered) continue;
            for (0..2) |direction| {
                if (scrollable.room.x[direction]) self.targets[0][direction] = scrollable.key;
                if (scrollable.room.y[direction]) self.targets[1][direction] = scrollable.key;
            }
        }
    }
});

/// Children slot that makes nested scrollables take the wheel innermost
/// first, handing it to the parent when the inner one runs out of room.
/// Call `ScrollingContext.use().resolve()` at the end of its children,
/// the same way `FocusProvider` pairs with `FocusContext.use().resolve()`.
pub fn ScrollProvider() *const fn (void) void {
    forbear.component(.{})({
        ScrollingContext.Provider(.{
            .targets = .{ .{ null, null }, .{ null, null } },
            .scrollable = .empty,
            .scopeKey = forbear.useScopeKey(),
        })({
            forbear.componentChildrenSlot();
        });
    });
    return forbear.componentChildrenSlotEnd();
}

const InputState = struct {
    /// The selection is always the span between `anchor` and `cursor`; with
    /// no selection they sit on the same byte. Every operation is "move the
    /// cursor, and collapse the anchor onto it unless extending".
    cursor: usize,
    anchor: usize,
    text: ?std.ArrayList(u8),

    /// Where the caret sits relative to the input's content box, with the
    /// scroll offset already applied; `height` is the text's line height.
    /// Only maintained while the input has focus.
    caret: struct {
        position: Vec2,
        height: f32,
    },

    /// Each stack holds the edits that, applied in pop order, walk the text
    /// back (undo) or forward (redo) through its history. Managed by
    /// `useInput`: `splice` records here, ctrl+z / ctrl+shift+z / ctrl+y
    /// pop one stack and push its inverse onto the other.
    undoStack: std.ArrayList(Edit),
    redoStack: std.ArrayList(Edit),

    /// Byte range of the IME's provisional preedit inside `text`, for
    /// styling it (typically underlined). Managed by `useInput`: replaced
    /// wholesale on every composition update and invisible to undo.
    composition: ?[2]usize,

    pub fn selection(self: *const @This()) [2]usize {
        return .{ @min(self.anchor, self.cursor), @max(self.anchor, self.cursor) };
    }
};

/// Replaces `removed` with `inserted` at `start` and leaves the cursor and
/// anchor at `cursorAfter`/`anchorAfter`. Self-inverting: `apply` returns the
/// edit that puts everything back, so undo and redo are just applying edits
/// popped off a stack.
const Edit = struct {
    start: usize,
    removed: []const u8,
    inserted: []const u8,
    cursorAfter: usize,
    anchorAfter: usize,
};

/// The only place that mutates text. Applies `edit` and returns its inverse,
/// or null when the mutation failed and nothing changed.
fn apply(
    inputState: *InputState,
    text: *std.ArrayList(u8),
    arena: std.mem.Allocator,
    edit: Edit,
) ?Edit {
    const inverse = Edit{
        .start = edit.start,
        .removed = edit.inserted,
        .inserted = edit.removed,
        .cursorAfter = inputState.cursor,
        .anchorAfter = inputState.anchor,
    };
    text.replaceRange(arena, edit.start, edit.removed.len, edit.inserted) catch |err| {
        forbear.handleFrameError(err);
        return null;
    };
    inputState.cursor = edit.cursorAfter;
    inputState.anchor = edit.anchorAfter;
    return inverse;
}

/// Replace `text[start..end]` with `replacement`: the cursor lands after it,
/// the selection collapses there, and the edit is recorded for undo. Every
/// user-visible text edit funnels through here — which is also where IME
/// composition and undo coalescing would plug in.
fn splice(
    inputState: *InputState,
    text: *std.ArrayList(u8),
    arena: std.mem.Allocator,
    start: usize,
    end: usize,
    replacement: []const u8,
) void {
    if (start == end and replacement.len == 0) return;

    const edit = Edit{
        .start = start,
        .removed = arena.dupe(u8, text.items[start..end]) catch |err| {
            return forbear.handleFrameError(err);
        },
        .inserted = arena.dupe(u8, replacement) catch |err| {
            return forbear.handleFrameError(err);
        },
        .cursorAfter = start + replacement.len,
        .anchorAfter = start + replacement.len,
    };
    const inverse = apply(inputState, text, arena, edit) orelse return;
    inputState.undoStack.append(arena, inverse) catch |err| {
        return forbear.handleFrameError(err);
    };
    inputState.redoStack.clearRetainingCapacity();
}

const wordSeparators = [_]u8{ '_', ' ', '-', '/', '`', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '=', '+', '~', '.', ',', '?', '[', ']', '"', '\'', '{', '}', '\\', '|' };

fn isWordSeparator(char: u8) bool {
    return std.mem.indexOfScalar(u8, &wordSeparators, char) != null;
}

/// One character left of `from`, snapped to a UTF-8 boundary — deleting or
/// stepping over "é" moves both of its bytes, never leaving the text with a
/// dangling continuation byte (which the shaper hard-crashes on).
fn previousCodepointBoundary(text: []const u8, from: usize) usize {
    var position = from;
    while (position > 0) {
        position -= 1;
        if (text[position] & 0xC0 != 0x80) break;
    }
    return position;
}

fn nextCodepointBoundary(text: []const u8, from: usize) usize {
    var position = @min(from + 1, text.len);
    while (position < text.len and text[position] & 0xC0 == 0x80) position += 1;
    return position;
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

/// A node's content box from its previous-frame measurement: the origin
/// where flowing text starts and the space inside border and padding.
fn innerBox(style: forbear.CompleteStyle, measurement: forbear.Node.Measurement) struct { origin: Vec2, size: Vec2 } {
    const leading = Vec2{
        style.borderWidth.x[0] + style.padding.x[0],
        style.borderWidth.y[0] + style.padding.y[0],
    };
    const trailing = Vec2{
        style.borderWidth.x[1] + style.padding.x[1],
        style.borderWidth.y[1] + style.padding.y[1],
    };
    return .{
        .origin = measurement.position + leading,
        .size = measurement.size - leading - trailing,
    };
}

/// Depends on the font styles of the parent to render. Pass the same
/// `scrollingState` given to the input's `useScrolling` — called before this
/// hook, so the caret reads this frame's scroll — and the cursor is kept in
/// view by moving the scroll offset as it travels.
pub fn useInput(
    initialInputState: struct {
        cursor: usize = 0,
        selection: [2]usize = .{0,0},
        text: []const u8 = &.{},
    },
    scrollingState: *ScrollingState,
) *InputState {
    forbear.hook();
    defer forbear.hookEnd();

    const arena = forbear.useScopeArena();

    const inputState = forbear.useState(InputState, InputState{
        .cursor = initialInputState.cursor,
        .anchor = if (initialInputState.cursor == initialInputState.selection[0])
            initialInputState.selection[1]
        else
            initialInputState.selection[0],
        .text = null,

        .caret = .{
            .height = 0.0,
            .position = @splat(0.0),
        },

        .undoStack = .empty,
        .redoStack = .empty,
        .composition = null,
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

    focusContext.register(&(struct {
        fn consumesFn(payload: EventPayload) ?EventPayload {
            return switch (payload) {
                .keyDown => |keys| .{
                    .keyDown = .{
                        .arrowLeft = keys.arrowLeft,
                        .arrowRight = keys.arrowRight,
                        .home = keys.home,
                        .end = keys.end,
                        .backspace = keys.backspace,
                        .delete = keys.delete,
                        .control = keys.control,
                        .a = keys.a,
                        .c = keys.c,
                        .v = keys.v,
                        .x = keys.x,
                        .y = keys.y,
                        .z = keys.z,
                    },
                },
                .input, .composition => payload,
                else => null,
            };
        }
    }).consumesFn);

    if (inputState.text) |*text| {
        std.debug.assert(inputState.cursor <= text.items.len);
        std.debug.assert(inputState.anchor <= text.items.len);

        // While composing, the preedit sits provisionally in the buffer. Pop
        // it for the frame so everything below edits committed text — the
        // stored range can't go stale against a mouse press or a cancelling
        // backspace — and lay it (or its replacement) back down at the end.
        var poppedPreedit: ?[]const u8 = null;
        if (inputState.composition) |range| {
            poppedPreedit = forbear.useArena().dupe(u8, text.items[range[0]..range[1]]) catch |err| blk: {
                forbear.handleFrameError(err);
                break :blk null;
            };
            text.replaceRangeAssumeCapacity(range[0], range[1] - range[0], &.{});
            inputState.cursor = range[0];
            inputState.anchor = range[0];
            inputState.composition = null;
        }
        // Editing keys stand down mid-composition, like in a browser: the
        // backspace that cancels a dead key eats the pending accent, not a
        // committed character.
        const composing = poppedPreedit != null;

        // A press places the cursor at the nearest character boundary and
        // anchors there; keeping the button held drags a selection out from
        // that anchor, cursor on the moving end.
        if (forbear.getParentNode()) |parent| {
            const dragging = forbear.useState(bool, false);

            if (!forbear.isMouseButtonPressed()) {
                dragging.* = false;
            }

            const pressedInside = forbear.onMouseDown();
            // Called every frame, not just on presses: its double-click
            // timer only ticks when it runs.
            const doublePressed = forbear.onDoubleClick();
            if (pressedInside) {
                focusContext.focus();
            }
            if (pressedInside or dragging.*) mouse: {
                const measurement = forbear.useNodeMeasurement() orelse break :mouse;
                const textStyle = forbear.CompleteTextStyle.from(forbear.BaseStyle.from(parent.style));
                const localX = forbear.useMousePosition()[0] -
                    innerBox(parent.style, measurement).origin[0] +
                    scrollingState._effectiveOffset[0];

                const shaped = forbear.shapeRuns(forbear.useArena(), &.{.{
                    .content = text.items,
                    .style = textStyle,
                }}, .none) catch |err| {
                    forbear.handleFrameError(err);
                    break :mouse;
                };

                // The character boundary nearest to the press: past a glyph's
                // horizontal midpoint rounds to the boundary after it. Byte
                // counting assumes one glyph per codepoint, so the clamp
                // covers ligature/decomposition drift.
                var index: usize = 0;
                var advanceX: f32 = 0.0;
                for (shaped.glyphs) |glyph| {
                    if (localX < advanceX + glyph.advance[0] / 2.0) break;
                    advanceX += glyph.advance[0];
                    index += std.unicode.utf8ByteSequenceLength(glyph.textBuf[0]) catch 1;
                }
                index = @min(index, text.items.len);

                // The cursor follows the point; the anchor stays put while
                // shift is held or a drag is in progress, exactly like
                // shift+arrows. A plain press collapses onto the point, and
                // a double press on a collapsed cursor selects everything.
                if (pressedInside) {
                    const shiftHeld = forbear.getModifiersHeld().shift;
                    const selectAll = doublePressed and !shiftHeld and
                        inputState.anchor == inputState.cursor;
                    if (selectAll) {
                        inputState.anchor = 0;
                        index = text.items.len;
                    } else if (!shiftHeld) {
                        inputState.anchor = index;
                    }
                    dragging.* = !selectAll;
                }
                inputState.cursor = index;
            }
        }

        if (focusContext.hasFocus()) {
            const keysDown = forbear.onKeyDown();
            const modifiersHeld = forbear.getModifiersHeld();

            // Editing keys stand down mid-composition, like in a browser: the
            // backspace that cancels a dead key eats the pending accent, not
            // a committed character.
            if (!composing) {
                // Selections are re-read per operation (not hoisted) because
                // each block can change them for the next within the frame.
                const movedTo: ?usize = if (keysDown.arrowLeft)
                    if (modifiersHeld.control)
                        previousWordBeginning(text.items, inputState.cursor)
                    else if (inputState.anchor != inputState.cursor and !modifiersHeld.shift)
                        inputState.selection()[0]
                    else
                        previousCodepointBoundary(text.items, inputState.cursor)
                else if (keysDown.arrowRight)
                    if (modifiersHeld.control)
                        nextWordBeginning(text.items, inputState.cursor)
                    else if (inputState.anchor != inputState.cursor and !modifiersHeld.shift)
                        inputState.selection()[1]
                    else
                        nextCodepointBoundary(text.items, inputState.cursor)
                else if (keysDown.home)
                    0
                else if (keysDown.end)
                    text.items.len
                else
                    null;

                if (movedTo) |newCursor| {
                    inputState.cursor = newCursor;
                    if (!modifiersHeld.shift) inputState.anchor = newCursor;
                }

                if (keysDown.backspace or keysDown.delete) {
                    const selection = inputState.selection();
                    if (selection[0] != selection[1]) {
                        splice(inputState, text, arena, selection[0], selection[1], "");
                    } else if (keysDown.backspace and inputState.cursor > 0) {
                        const start = if (modifiersHeld.control)
                            previousWordBeginning(text.items, inputState.cursor)
                        else
                            previousCodepointBoundary(text.items, inputState.cursor);
                        splice(inputState, text, arena, start, inputState.cursor, "");
                    } else if (keysDown.delete and inputState.cursor < text.items.len) {
                        const end = if (modifiersHeld.control)
                            nextWordBeginning(text.items, inputState.cursor)
                        else
                            nextCodepointBoundary(text.items, inputState.cursor);
                        splice(inputState, text, arena, inputState.cursor, end, "");
                    }
                }

                if (modifiersHeld.control and keysDown.a) {
                    inputState.anchor = 0;
                    inputState.cursor = text.items.len;
                }

                if (modifiersHeld.control and (keysDown.c or keysDown.x)) {
                    const selection = inputState.selection();
                    if (selection[0] != selection[1]) {
                        forbear.setClipboardText(text.items[selection[0]..selection[1]]);
                        if (keysDown.x) {
                            splice(inputState, text, arena, selection[0], selection[1], "");
                        }
                    }
                }

                if (modifiersHeld.control and keysDown.v) {
                    if (forbear.getClipboardText()) |pasted| {
                        const selection = inputState.selection();
                        splice(inputState, text, arena, selection[0], selection[1], pasted);
                    }
                }

                if (modifiersHeld.control and keysDown.z and !modifiersHeld.shift) {
                    if (inputState.undoStack.pop()) |edit| {
                        if (apply(inputState, text, arena, edit)) |inverse| {
                            inputState.redoStack.append(arena, inverse) catch |err| forbear.handleFrameError(err);
                        }
                    }
                }

                if ((modifiersHeld.control and keysDown.z and modifiersHeld.shift) or (modifiersHeld.control and keysDown.y)) {
                    if (inputState.redoStack.pop()) |edit| {
                        if (apply(inputState, text, arena, edit)) |inverse| {
                            inputState.undoStack.append(arena, inverse) catch |err| forbear.handleFrameError(err);
                        }
                    }
                }
            }

            // An IME batch applies in protocol order around the committed
            // text: the previous preedit is already popped, so apply the
            // batch's deletions of committed text, let the commit land
            // through `onInput` below, then lay down the new preedit.
            const compositionEvent = forbear.onComposition();
            if (compositionEvent) |c| {
                if (c.deleteBefore > 0 or c.deleteAfter > 0) {
                    splice(
                        inputState,
                        text,
                        arena,
                        inputState.cursor -| c.deleteBefore,
                        @min(inputState.cursor + c.deleteAfter, text.items.len),
                        "",
                    );
                }
            }

            // A chorded press is a command, not text entry (ctrl+a must not
            // type an "a"). The exceptions: ctrl+alt, which is how AltGr
            // chords arrive on Windows keymaps and does type characters, and
            // IME commits, which can ride on modifier chords.
            const isCommandChord = (modifiersHeld.control and !modifiersHeld.alt) or modifiersHeld.super;
            if (!isCommandChord or compositionEvent != null) {
                if (forbear.onInput()) |typed| {
                    const selection = inputState.selection();
                    splice(inputState, text, arena, selection[0], selection[1], typed);
                }
            }

            const newPreedit: []const u8 = if (compositionEvent) |c|
                c.preedit
            else
                // No batch this frame: the popped preedit goes back down
                // unchanged at the (possibly moved) cursor.
                poppedPreedit orelse "";
            if (newPreedit.len > 0) preedit: {
                const start = inputState.cursor;
                // Provisional: inserted directly so undo never sees it.
                text.insertSlice(arena, start, newPreedit) catch |err| {
                    forbear.handleFrameError(err);
                    break :preedit;
                };
                inputState.composition = .{ start, start + newPreedit.len };
                const cursorRange: [2]usize = if (compositionEvent) |c|
                    c.cursor
                else
                    .{ newPreedit.len, newPreedit.len };
                inputState.anchor = start + @min(cursorRange[0], newPreedit.len);
                inputState.cursor = start + @min(cursorRange[1], newPreedit.len);
            }

            if (forbear.getParentNode()) |parent| caret: {
                if (parent.style.textWrapping != .none) {
                    std.log.err("useInput requires the input element to have textWrapping = .none, for now.", .{});
                    forbear.handleFrameError(error.TextWrappingNotNone);
                    break :caret;
                }

                const textStyle = forbear.CompleteTextStyle.from(forbear.BaseStyle.from(parent.style));
                const measured = forbear.measureText(&.{.{
                    .content = text.items[0..inputState.cursor],
                    .style = textStyle,
                }}, 0.0, .none);

                const measurement = forbear.useNodeMeasurement();

                // Follow the parent's vertical justification the same way
                // layout justifies the flowing text, from the previous
                // frame's resolved size.
                const yOffset: f32 = if (measurement) |m| switch (parent.style.yJustification) {
                    .start => 0.0,
                    .center => (innerBox(parent.style, m).size[1] - measured.height) / 2.0,
                    .end => innerBox(parent.style, m).size[1] - measured.height,
                } else 0.0;

                // Keep the cursor in view: when a cursor move lands it
                // outside the inner width, pull the scroll offset just far
                // enough that it's back inside. Only on cursor moves, so
                // manual scrolling isn't fought over every frame.
                const lastCursor = forbear.useState(usize, inputState.cursor);
                if (lastCursor.* != inputState.cursor) {
                    lastCursor.* = inputState.cursor;
                    if (measurement) |m| {
                        const innerWidth = innerBox(parent.style, m).size[0];
                        scrollingState.offset[0] = @min(scrollingState.offset[0], measured.width);
                        scrollingState.offset[0] = @max(scrollingState.offset[0], measured.width - innerWidth + 1.0);
                        // Snap so following the cursor doesn't animate.
                        scrollingState._effectiveOffset[0] = scrollingState.offset[0];
                    }
                }

                inputState.caret = .{
                    .position = Vec2{ measured.width, yOffset } - scrollingState._effectiveOffset,
                    .height = measured.height,
                };

                // Declare IME interest while focused: the candidate window
                // docks against the caret. Skipping this on unfocused frames
                // is what disables the IME.
                if (measurement) |m| {
                    const caretOrigin = innerBox(parent.style, m).origin + inputState.caret.position;
                    forbear.useTextInput(.{
                        .caretRectangle = .{
                            caretOrigin[0],
                            caretOrigin[1],
                            1.0,
                            inputState.caret.height,
                        },
                    });
                }
            }
        }
    }

    return inputState;
}

const InputCaretProps = struct {
    inputState: *const InputState,
    style: forbear.Style = .{},
};

pub fn InputCaret(props: InputCaretProps) void {
    forbear.component(.{})({
        const focusContext = FocusContext.use();
        if (forbear.getParentNode()) |parent| {
            if (props.inputState.text) |text| {
                if (focusContext.hasFocus()) {
                    const textStyle = forbear.CompleteTextStyle.from(forbear.BaseStyle.from(parent.style));
                    const selection = props.inputState.selection();
                    const hasSelection = selection[0] != selection[1];

                    // The span between the selection endpoints is independent
                    // of scrolling, and the cursor sits on one of them, so the
                    // scroll-adjusted `caret.position` anchors the whole box.
                    const selectionWidth: f32 = if (hasSelection) blk: {
                        const from = forbear.measureText(&.{.{
                            .content = text.items[0..selection[0]],
                            .style = textStyle,
                        }}, 0.0, .none);
                        const to = forbear.measureText(&.{.{
                            .content = text.items[0..selection[1]],
                            .style = textStyle,
                        }}, 0.0, .none);
                        break :blk to.width - from.width;
                    } else 0.0;

                    const x = if (hasSelection and props.inputState.cursor == selection[1])
                        props.inputState.caret.position[0] - selectionWidth
                    else
                        props.inputState.caret.position[0];

                    forbear.element(.{
                        .style = props.style.overwrite(.{
                            .placement = .{
                                .relative = .{ x, props.inputState.caret.position[1] },
                            },
                            .width = .{ .fixed = if (hasSelection) selectionWidth else 1.0 },
                            .height = .{ .fixed = props.inputState.caret.height },
                            // The selection mounts after the text node, so it
                            // draws over the glyphs and must stay translucent
                            // for them to read through.
                            .background = .{
                                .color = if (hasSelection)
                                    forbear.selectionColor
                                else
                                    textStyle.color,
                            },
                        }),
                    })({});
                }
            }
        }
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
    doubleClick: bool,
    scroll: ?Vec2,
    keyDown: forbear.Keys,
    keyUp: forbear.Keys,
    input: ?[]const u8,
    composition: ?forbear.Composition,
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
            .mouseMove, .scroll, .input, .composition => null,
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
            const shift = forbear.getModifiersHeld().shift;
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
