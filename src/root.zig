const std = @import("std");
const builtin = @import("builtin");

pub const c = @import("c.zig").c;
pub const Font = @import("font.zig");
pub const Graphics = @import("graphics.zig");
pub const Image = @import("graphics.zig").Image;
const layouting = @import("layouting.zig");
pub const layout = layouting.layout;
pub const LayoutBox = layouting.LayoutBox;
const nodeImport = @import("node.zig");
pub const Node = nodeImport.Node;
pub const Component = nodeImport.Component;
pub const component = nodeImport.component;
pub const ComponentProps = nodeImport.ComponentProps;
pub const Element = nodeImport.Element;
pub const ElementProps = nodeImport.DivProps;
pub const div = nodeImport.div;
pub const children = nodeImport.children;
pub const eventHandler = nodeImport.eventHandler;
pub const EventHandler = nodeImport.EventHandler;
pub const Window = @import("window/root.zig").Window;

const Vec2 = @Vector(2, f32);

const Context = @This();

var context: ?@This() = null;

const ComponentResolutionState = struct {
    arenaAllocator: std.mem.Allocator,
    stateByteCursor: usize,
    key: u64,
};

allocator: std.mem.Allocator,
mousePosition: Vec2,
hoveredElementKeys: std.ArrayList(u64),

/// Seconds
startTime: f64,
/// Seconds
deltaTime: ?f64,
/// Seconds
lastUpdateTime: ?f64,

// TODO: The alignment here is probably messed up, we should find a way to fix
// it later
/// A literal string of bytes that have the size of some state, and the
componentStates: std.AutoHashMap(u64, []align(@alignOf(usize)) u8),
componentResolutionState: ?ComponentResolutionState,

pub fn init(allocator: std.mem.Allocator) !void {
    if (context != null) {
        return error.AlreadyInitialized;
    }

    context = @This(){
        .mousePosition = .{ 0.0, 0.0 },
        .hoveredElementKeys = try std.ArrayList(u64).initCapacity(allocator, 1),
        .allocator = allocator,
        .componentStates = .init(allocator),
        .componentResolutionState = null,

        .startTime = timestampSeconds(),
        .deltaTime = null,
        .lastUpdateTime = null,
    };
}

/// TODO: inherit all properties from Node, and add the key and differnet
/// children, as well as removing the component variant
pub const TreeNode = struct {
    key: u64,
    node: Node,
    children: ?[]TreeNode,
};

const Resolver = struct {
    path: std.ArrayList(usize),
    arenaAllocator: std.mem.Allocator,

    fn init(arenaAllocator: std.mem.Allocator) !@This() {
        return .{
            .arenaAllocator = arenaAllocator,
            .path = try std.ArrayList(usize).initCapacity(arenaAllocator, 0),
        };
    }

    fn resolve(self: *@This(), node: Node) !TreeNode {
        const forbear = getContext();

        var hasher = std.hash.Wyhash.init(0);
        hasher.update(std.mem.sliceAsBytes(self.path.items));
        switch (node) {
            .component => |comp| {
                hasher.update(std.mem.asBytes(&comp.id));
                const key = hasher.final();

                // TODO(up next): find a way to free the state data once the component instance is gone
                const previousComponentResolutionState = forbear.componentResolutionState;
                forbear.componentResolutionState = .{
                    .key = key,
                    .arenaAllocator = self.arenaAllocator,
                    .stateByteCursor = 0,
                };
                const componentNode = try comp.function(comp.props);
                if (!forbear.componentStates.contains(key) or forbear.componentResolutionState.?.stateByteCursor != forbear.componentStates.get(key).?.len) {
                    return error.RulesOfHooksViolated;
                }
                forbear.componentResolutionState = previousComponentResolutionState;
                // TODO: investigate if should we reuse the same key as above?
                // Is it a problem that it creates a new key here?
                return self.resolve(componentNode);
            },
            .element => {
                if (node.element.children != null) {
                    var treeChildren = try self.arenaAllocator.alloc(TreeNode, node.element.children.?.len);
                    for (node.element.children.?, 0..) |child, i| {
                        try self.path.append(self.arenaAllocator, i);
                        defer _ = self.path.pop();
                        treeChildren[i] = try self.resolve(child);
                    }
                    return .{
                        .key = hasher.final(),
                        .node = node,
                        .children = treeChildren,
                    };
                } else {
                    return .{
                        .key = hasher.final(),
                        .node = node,
                        .children = null,
                    };
                }
            },
            .text => |text| {
                hasher.update(text);
                return .{
                    .key = hasher.final(),
                    .node = node,
                    .children = null,
                };
            },
        }
    }
};

pub fn resolve(rootNode: Node, arenaAllocator: std.mem.Allocator) !TreeNode {
    var resolver = try Resolver.init(arenaAllocator);

    return resolver.resolve(rootNode);
}

test "Component resolution" {
    try init(std.testing.allocator);
    defer deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var callCount: u32 = 0;

    const MyComponentProps = struct {
        callCount: *u32,
        value: u32,
        arenaAllocator: std.mem.Allocator,
    };

    const MyComponent = (struct {
        fn component(props: MyComponentProps) !Node {
            props.callCount.* += 1;
            const counter = try useState(u32, props.value);
            try std.testing.expectEqual(props.value, counter.*);
            return div(.{
                .children = try children(.{ "Value: ", counter.* }, props.arenaAllocator),
            });
        }
    }).component;

    const rootNode = div(.{
        .children = try children(.{
            try component(
                MyComponent,
                MyComponentProps{ .callCount = &callCount, .value = 10, .arenaAllocator = arenaAllocator },
                arenaAllocator,
            ),
            try component(
                MyComponent,
                MyComponentProps{ .callCount = &callCount, .value = 20, .arenaAllocator = arenaAllocator },
                arenaAllocator,
            ),
        }, arenaAllocator),
    });

    _ = try resolve(rootNode, arenaAllocator);
    try std.testing.expectEqual(2, callCount);

    _ = try resolve(rootNode, arenaAllocator);
    try std.testing.expectEqual(4, callCount);
}

const AnimationState = struct {
    /// Seconds
    timeSinceStart: f32,
    /// Seconds, equivalent to the duration
    estimatedEnd: f32,

    /// Value ranging from 0.0 to 1.0
    progress: f32,

    reverseReset: bool,

    pub fn start(self: *?@This(), duration: f64) void {
        self.state = .{
            .timeSinceStart = 0.0,
            .estimatedEnd = duration,
            .progress = 0.0,
            .reverseReset = false,
        };
    }
};

pub const Animation = struct {
    state: *?AnimationState,
    duration: f32,

    pub fn start(self: @This()) void {
        self.state.* = .{
            .timeSinceStart = 0.0,
            .estimatedEnd = self.duration,
            .progress = 0.0,
            .reverseReset = false,
        };
    }

    /// Progresses through the animation in reverse, and once it gets to the start,
    /// it is completely reset.
    pub fn reverseReset(self: @This()) void {
        self.state.* = .{
            .timeSinceStart = 0.0,
            .estimatedEnd = self.duration,
            .progress = 1.0,
            .reverseReset = true,
        };
    }

    pub fn reset(self: @This()) void {
        self.state.* = null;
    }

    pub fn isRunning(self: @This()) bool {
        return self.state.* != null;
    }

    /// Does not apply any easing function. To apply one, just call the function in this value.
    pub fn progress(self: @This()) ?f32 {
        if (self.state.*) |state| {
            return state.progress;
        }
        return null;
    }
};

pub fn useTransition(value: f32, duration: f32, easing: fn (f32) f32) !f32 {
    const valueToTransitionFrom = try useState(f32, value);
    const animation = try useAnimation(duration);

    if (value != valueToTransitionFrom.*) {
        if (!animation.isRunning()) {
            animation.start();
        }
        if (animation.progress()) |progress| {
            if (progress == 1.0) {
                valueToTransitionFrom.* = value;
                animation.reset();
                return value;
            }
            return valueToTransitionFrom.* + (value - valueToTransitionFrom.*) * easing(progress);
        } else {
            return value;
        }
    }

    return value;
}

pub fn useAnimation(duration: f32) !Animation {
    const self = getContext();
    const state = try useState(?AnimationState, null);

    if (state.* != null and state.*.?.progress == 0.0 and state.*.?.reverseReset == true) {
        // we're going backwards and reached the start, so we can stop the animation
        state.* = null;
    }
    if (state.* != null) {
        if (state.*.?.progress < 1.0 and state.*.?.reverseReset == false) {
            state.*.?.timeSinceStart += @floatCast(self.deltaTime orelse 0.0);
            state.*.?.progress = @min(
                1.0,
                state.*.?.timeSinceStart / state.*.?.estimatedEnd,
            );
        } else if (state.*.?.progress > 0.0 and state.*.?.reverseReset == true) {
            state.*.?.timeSinceStart += @floatCast(self.deltaTime orelse 0.0);
            state.*.?.progress = 1.0 - @min(
                1.0,
                state.*.?.timeSinceStart / state.*.?.estimatedEnd,
            );
        }
    }

    return .{
        .state = state,
        .duration = duration,
    };
}

/// CSS-style cubic bezier timing function.
/// Given control points (x1, y1) and (x2, y2), returns the y-value for a given x-value (time).
/// The curve always starts at (0, 0) and ends at (1, 1).
pub fn cubicBezier(x1: f32, y1: f32, x2: f32, y2: f32, time: f32) f32 {
    // Early returns for edge cases
    if (time <= 0.0) return 0.0;
    if (time >= 1.0) return 1.0;

    // Newton-Raphson method to solve for t given x (time)
    // We need to find t such that bezierX(t) = time
    var t = time; // Initial guess
    const epsilon = 0.0001;
    const maxIterations = 8;

    var i: u32 = 0;
    while (i < maxIterations) : (i += 1) {
        const currentX = bezierX(x1, x2, t);
        const diff = currentX - time;
        if (@abs(diff) < epsilon) break;

        const derivative = bezierXDerivative(x1, x2, t);
        if (@abs(derivative) < epsilon) break;

        t -= diff / derivative;
    }

    // Now that we have t, calculate the corresponding y value
    return bezierY(y1, y2, t);
}

fn bezierX(x1: f32, x2: f32, t: f32) f32 {
    // x(t) = 3*(1-t)^2*t*x1 + 3*(1-t)*t^2*x2 + t^3
    const oneMinusT = 1.0 - t;
    return 3.0 * oneMinusT * oneMinusT * t * x1 +
        3.0 * oneMinusT * t * t * x2 +
        t * t * t;
}

fn bezierY(y1: f32, y2: f32, t: f32) f32 {
    // y(t) = 3*(1-t)^2*t*y1 + 3*(1-t)*t^2*y2 + t^3
    const oneMinusT = 1.0 - t;
    return 3.0 * oneMinusT * oneMinusT * t * y1 +
        3.0 * oneMinusT * t * t * y2 +
        t * t * t;
}

fn bezierXDerivative(x1: f32, x2: f32, t: f32) f32 {
    // dx/dt = 3*(1-t)^2*x1 + 6*(1-t)*t*(x2-x1) + 3*t^2*(1-x2)
    const oneMinusT = 1.0 - t;
    return 3.0 * oneMinusT * oneMinusT * x1 +
        6.0 * oneMinusT * t * (x2 - x1) +
        3.0 * t * t * (1.0 - x2);
}

test "easeInOut" {
    try std.testing.expectEqual(1.0, easeInOut(1.0));
    try std.testing.expectEqual(0.0, easeInOut(0.0));
}

test "ease" {
    try std.testing.expectEqual(1.0, ease(1.0));
    try std.testing.expectEqual(0.0, ease(0.0));
}

/// Equivalent to CSS's ease timing function
pub fn easeInOut(progress: f32) f32 {
    return cubicBezier(0.42, 0.0, 0.58, 1.0, progress);
}

/// Equivalent to CSS's ease timing function
pub fn ease(progress: f32) f32 {
    return cubicBezier(0.25, 0.1, 0.25, 1.0, progress);
}

pub fn useDeltaTime() f64 {
    const self = getContext();
    return self.deltaTime orelse 0.0;
}

pub fn useLastUpdateTime() f64 {
    const self = getContext();
    return self.lastUpdateTime orelse self.startTime;
}

pub fn useArena() !std.mem.Allocator {
    const self = getContext();
    if (self.componentResolutionState) |state| {
        return state.arenaAllocator;
    } else {
        if (!builtin.is_test) {
            std.log.err("You might be calling a hook (useArena) outside of a component, and forbear cannot track things outside of one.", .{});
        }
        return error.NoComponentContext;
    }
}

const stateAlignment: std.mem.Alignment = .@"8";

// TODO: in debug mode, we should be adding some guard rail here to make sure
// of warning the user if they called the hook in an unexpected order, as it
// can cause undefined behavior as is right now
pub fn useState(T: type, initialValue: T) !*T {
    const self = getContext();
    if (self.componentResolutionState) |*state| {
        const stateResult = try self.componentStates.getOrPut(state.key);
        const alignedCursor = std.mem.alignForward(usize, state.stateByteCursor, @alignOf(T));
        const requiredLen = alignedCursor + @sizeOf(T);
        defer state.stateByteCursor = requiredLen;
        if (stateResult.found_existing) {
            if (alignedCursor < stateResult.value_ptr.*.len) {
                return @ptrCast(@alignCast(stateResult.value_ptr.*[alignedCursor..requiredLen]));
            }
            stateResult.value_ptr.* = try self.allocator.realloc(stateResult.value_ptr.*, requiredLen);
        } else {
            stateResult.value_ptr.* = try self.allocator.alignedAlloc(u8, stateAlignment, requiredLen);
        }
        @memcpy(
            stateResult.value_ptr.*[alignedCursor..requiredLen],
            std.mem.asBytes(&initialValue),
        );
        return @ptrCast(@alignCast(stateResult.value_ptr.*[alignedCursor..requiredLen]));
    } else {
        if (!builtin.is_test) {
            std.log.err("You might be calling a hook (useState) outside of a component, and forbear cannot track things outside of one.", .{});
        }
        return error.NoComponentContext;
    }
}

test "State creation with manual handling" {
    try init(std.testing.allocator);
    defer deinit();
    const self = getContext();
    {
        // First run that should allocate RAM, and still allow reading and writing the values
        self.componentResolutionState = ComponentResolutionState{
            .stateByteCursor = 0,
            .key = 1,
            .arenaAllocator = std.testing.allocator,
        };
        const state1 = try useState(i32, 42);
        try std.testing.expectEqual(@sizeOf(i32), self.componentStates.get(1).?.len);
        const state2 = try useState(f32, 3.14);
        try std.testing.expectEqual(@sizeOf(i32) + @sizeOf(f32), self.componentStates.get(1).?.len);
        try std.testing.expectEqual(42, state1.*);
        try std.testing.expectEqual(3.14, state2.*);
        state1.* = 100;
        state2.* = 6.28;
        try std.testing.expectEqual(100, state1.*);
        try std.testing.expectEqual(6.28, state2.*);
    }
    {
        // Second run that should not allcoate new memory
        self.componentResolutionState = ComponentResolutionState{
            .stateByteCursor = 0,
            .key = 1,
            .arenaAllocator = std.testing.allocator,
        };
        const state1 = try useState(i32, 42);
        try std.testing.expectEqual(@sizeOf(i32) + @sizeOf(f32), self.componentStates.get(1).?.len);
        const state2 = try useState(f32, 3.14);
        try std.testing.expectEqual(@sizeOf(i32) + @sizeOf(f32), self.componentStates.get(1).?.len);
        try std.testing.expectEqual(100, state1.*);
        try std.testing.expectEqual(6.28, state2.*);
    }
    {
        self.componentResolutionState = null;
        try std.testing.expectError(error.NoComponentContext, useState(i32, 42));
    }
}

pub fn update(root: *const LayoutBox, arena: std.mem.Allocator) !void {
    const self = getContext();

    var iterator = try layouting.LayoutTreeIterator.init(arena, root);

    var missingHoveredKeys = try std.ArrayList(u64).initCapacity(arena, self.hoveredElementKeys.items.len);
    missingHoveredKeys.appendSliceAssumeCapacity(self.hoveredElementKeys.items);

    var highestHoveredLayoutBox: ?*const LayoutBox = null;
    while (try iterator.next()) |layoutBox| {
        const isMouseAfter = layoutBox.position[0] <= self.mousePosition[0] and layoutBox.position[1] <= self.mousePosition[1];
        const isMouseBefore = layoutBox.position[0] + layoutBox.size[0] >= self.mousePosition[0] and layoutBox.position[1] + layoutBox.size[1] >= self.mousePosition[1];
        const isMouseInside = isMouseAfter and isMouseBefore;

        const hoveredElementKeysIndexOpt = std.mem.indexOfScalar(u64, self.hoveredElementKeys.items, layoutBox.key);

        if (std.mem.indexOfScalar(u64, missingHoveredKeys.items, layoutBox.key)) |i| {
            _ = missingHoveredKeys.swapRemove(i);
        }

        if (isMouseInside) {
            if (highestHoveredLayoutBox) |hoveredBox| {
                if (layoutBox.z > hoveredBox.z) {
                    highestHoveredLayoutBox = layoutBox;
                }
            } else {
                highestHoveredLayoutBox = layoutBox;
            }

            if (hoveredElementKeysIndexOpt == null) {
                if (layoutBox.handlers.onMouseOver) |onMouseOver| {
                    try onMouseOver.handler(layoutBox, onMouseOver.data);
                }
                try self.hoveredElementKeys.append(self.allocator, layoutBox.key);
            }
        } else if (hoveredElementKeysIndexOpt) |hoveredElementKeysIndex| {
            if (layoutBox.handlers.onMouseOut) |onMouseOut| {
                try onMouseOut.handler(layoutBox, onMouseOut.data);
            }
            _ = self.hoveredElementKeys.swapRemove(hoveredElementKeysIndex);
        }
    }

    for (missingHoveredKeys.items) |key| {
        if (std.mem.indexOfScalar(u64, self.hoveredElementKeys.items, key)) |i| {
            _ = self.hoveredElementKeys.swapRemove(i);
        }
    }

    const timestamp = timestampSeconds();
    self.deltaTime = timestamp - (self.lastUpdateTime orelse (timestamp - self.startTime));
    self.lastUpdateTime = timestamp;
}

fn timestampSeconds() f64 {
    return @as(f64, @floatFromInt(std.time.nanoTimestamp())) / std.time.ns_per_s;
}

pub fn setWindowHandlers(window: *Window) void {
    const self = getContext();

    window.setPointerMotionHandler(
        &(struct {
            fn handler(_: *Window, time: u32, x: f32, y: f32, data: *anyopaque) void {
                _ = time;
                const ctx: *Context = @ptrCast(@alignCast(data));
                ctx.mousePosition = .{ x, y };
            }
        }).handler,
        @ptrCast(@alignCast(self)),
    );
}

pub fn deinit() void {
    const self = getContext();
    std.debug.assert(self.componentResolutionState == null);
    var nodeStatesIterator = self.componentStates.valueIterator();
    while (nodeStatesIterator.next()) |states| {
        self.allocator.free(states.*);
    }
    self.componentStates.deinit();
    self.hoveredElementKeys.deinit(self.allocator);
    context = null;
}

pub fn getContext() *@This() {
    return &context.?;
}
