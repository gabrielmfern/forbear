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
pub const Alignment = nodeImport.Alignment;
pub const Padding = nodeImport.Padding;
pub const Margin = nodeImport.Margin;
pub const BorderWidth = nodeImport.BorderWidth;
pub const Offset = nodeImport.Shadow.Offset;
pub const IncompleteStyle = nodeImport.IncompleteStyle;
pub const Style = nodeImport.Style;
pub const Component = nodeImport.Component;
pub const Element = nodeImport.Element;
pub const Window = @import("window/root.zig").Window;
pub const components = @import("components.zig");
pub const FpsCounter = components.FpsCounter;

const Vec2 = @Vector(2, f32);

const Context = @This();

var context: ?@This() = null;

const ComponentResolutionState = struct {
    arenaAllocator: std.mem.Allocator,
    useStateCursor: usize,
    key: u64,
};

const Event = union(enum) {
    mouseOver,
    mouseOut,
};

const ElementEventQueue = std.AutoHashMap(u64, std.ArrayList(Event));

allocator: std.mem.Allocator,

mousePosition: Vec2,
hoveredElementKeys: std.ArrayList(u64),
/// The eased in value of `effectiveScrollPosition`
scrollPosition: Vec2,
/// The final value of the scrolling, without considering any animations, snaps
/// exactly into place.
effectiveScrollPosition: Vec2,

renderer: *Graphics.Renderer,

/// Seconds
startTime: f64,
/// Seconds
deltaTime: ?f64,
/// Seconds
lastUpdateTime: ?f64,
viewportSize: Vec2,

componentStates: std.AutoHashMap(u64, std.ArrayList([]align(@alignOf(usize)) u8)),
// images: std.StringHashMap(Image),
componentResolutionState: ?ComponentResolutionState,

frameEventQueue: std.AutoHashMap(u64, std.ArrayList(Event)),

rootFrameNode: ?Node,
frameNodeParentStack: std.ArrayList(*Node),
frameNodePath: std.ArrayList(usize),
previousPushedNode: ?*const Node,

images: std.StringHashMap(Image),
fonts: std.StringHashMap(Font),

pub fn init(allocator: std.mem.Allocator, renderer: *Graphics.Renderer) !void {
    if (context != null) {
        return error.AlreadyInitialized;
    }

    context = @This(){
        .allocator = allocator,

        .mousePosition = @splat(0.0),
        .hoveredElementKeys = try std.ArrayList(u64).initCapacity(allocator, 1),
        .scrollPosition = @splat(0.0),
        .effectiveScrollPosition = @splat(0.0),

        .renderer = renderer,

        .startTime = timestampSeconds(),
        .deltaTime = null,
        .lastUpdateTime = null,
        .viewportSize = @splat(0.0),

        .componentStates = .init(allocator),
        .componentResolutionState = null,

        .frameEventQueue = .init(allocator),

        .rootFrameNode = null,
        .frameNodeParentStack = .empty,
        .frameNodePath = .empty,
        .previousPushedNode = null,

        .images = std.StringHashMap(Image).init(allocator),
        .fonts = std.StringHashMap(Font).init(allocator),
    };
}

test "Element tree stack stability" {
    try init(std.testing.allocator, undefined);
    defer deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = getContext();

    (try element(arenaAllocator, .{}))({
        try std.testing.expectEqual(1, self.frameNodeParentStack.items.len);
        try std.testing.expectEqual(1, self.frameNodePath.items.len);
        try component(arenaAllocator, FpsCounter, null);
        try std.testing.expectEqual(1, self.frameNodeParentStack.items.len);
        try std.testing.expectEqual(1, self.frameNodePath.items.len);
        (try element(arenaAllocator, .{}))({
            try std.testing.expectEqual(2, self.frameNodeParentStack.items.len);
            try std.testing.expectEqual(2, self.frameNodePath.items.len);

            try text(arenaAllocator, "Hello, world!");
            try std.testing.expectEqualDeep("Hello, world!", self.previousPushedNode.?.content.text);

            try std.testing.expectEqual(2, self.frameNodeParentStack.items.len);
            try std.testing.expectEqual(2, self.frameNodePath.items.len);

            (try element(arenaAllocator, .{}))({
                try std.testing.expectEqual(3, self.frameNodeParentStack.items.len);
                try std.testing.expectEqual(3, self.frameNodePath.items.len);

                try text(arenaAllocator, "Nested element");
                try std.testing.expectEqualDeep("Nested element", self.previousPushedNode.?.content.text);

                try std.testing.expectEqual(3, self.frameNodeParentStack.items.len);
                try std.testing.expectEqual(3, self.frameNodePath.items.len);
            });

            try std.testing.expectEqual(2, self.frameNodeParentStack.items.len);
            try std.testing.expectEqual(2, self.frameNodePath.items.len);
        });
        try std.testing.expectEqual(1, self.frameNodeParentStack.items.len);
    });
    try std.testing.expectEqual(0, self.frameNodeParentStack.items.len);
    try std.testing.expectEqual(0, self.frameNodePath.items.len);
    try std.testing.expect(self.rootFrameNode != null);

    // This acts like the end of a frame here
    resetNodeTree();
    _ = arena.reset(.retain_capacity);

    (try element(arenaAllocator, .{}))({
        try std.testing.expectEqual(1, self.frameNodeParentStack.items.len);
        try std.testing.expectEqual(1, self.frameNodePath.items.len);
        try component(arenaAllocator, FpsCounter, null);
        try std.testing.expectEqual(1, self.frameNodeParentStack.items.len);
        try std.testing.expectEqual(1, self.frameNodePath.items.len);
        (try element(arenaAllocator, .{}))({
            try std.testing.expectEqual(2, self.frameNodeParentStack.items.len);
            try std.testing.expectEqual(2, self.frameNodePath.items.len);

            try text(arenaAllocator, "Hello, world!");
            try std.testing.expectEqualDeep("Hello, world!", self.previousPushedNode.?.content.text);

            try std.testing.expectEqual(2, self.frameNodeParentStack.items.len);
            try std.testing.expectEqual(2, self.frameNodePath.items.len);

            (try element(arenaAllocator, .{}))({
                try std.testing.expectEqual(3, self.frameNodeParentStack.items.len);
                try std.testing.expectEqual(3, self.frameNodePath.items.len);

                try text(arenaAllocator, "Nested element");
                try std.testing.expectEqualDeep("Nested element", self.previousPushedNode.?.content.text);

                try std.testing.expectEqual(3, self.frameNodeParentStack.items.len);
                try std.testing.expectEqual(3, self.frameNodePath.items.len);
            });

            try std.testing.expectEqual(2, self.frameNodeParentStack.items.len);
            try std.testing.expectEqual(2, self.frameNodePath.items.len);
        });
        try std.testing.expectEqual(1, self.frameNodeParentStack.items.len);
    });
    try std.testing.expectEqual(0, self.frameNodeParentStack.items.len);
    try std.testing.expectEqual(0, self.frameNodePath.items.len);
    try std.testing.expect(self.rootFrameNode != null);
}

test "Element key stability across frames" {
    try init(std.testing.allocator, undefined);
    defer deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = getContext();

    // Helper to collect keys from the tree
    const collectKeys = struct {
        fn collect(
            allocator: std.mem.Allocator,
            node: *const Node,
            arrayList: *std.ArrayList(u64),
        ) !void {
            try arrayList.append(allocator, node.key);
            if (node.content == .element) {
                for (node.content.element.children.items) |*child| {
                    try collect(allocator, child, arrayList);
                }
            }
        }
    }.collect;

    // Build tree: root > [child1, child2 > [nested1, nested2]]
    (try element(arenaAllocator, .{}))({
        (try element(arenaAllocator, .{}))({});
        (try element(arenaAllocator, .{}))({
            (try element(arenaAllocator, .{}))({});
            (try element(arenaAllocator, .{}))({});
        });
    });

    var firstFrameKeys = try std.ArrayList(u64).initCapacity(std.testing.allocator, 8);
    defer firstFrameKeys.deinit(std.testing.allocator);
    try collectKeys(std.testing.allocator, &self.rootFrameNode.?, &firstFrameKeys);

    // Simulate frame boundary (just resetNodes, no arena reset - arena is reused across frames)
    resetNodeTree();
    _ = arena.reset(.retain_capacity);

    // Build the exact same tree structure
    (try element(arenaAllocator, .{}))({
        (try element(arenaAllocator, .{}))({});
        (try element(arenaAllocator, .{}))({
            (try element(arenaAllocator, .{}))({});
            (try element(arenaAllocator, .{}))({});
        });
    });

    var secondFrameKeys = try std.ArrayList(u64).initCapacity(std.testing.allocator, 8);
    defer secondFrameKeys.deinit(std.testing.allocator);
    try collectKeys(std.testing.allocator, &self.rootFrameNode.?, &secondFrameKeys);

    // Keys should be identical across frames for the same structure
    try std.testing.expectEqual(firstFrameKeys.items.len, secondFrameKeys.items.len);
    try std.testing.expectEqualSlices(u64, firstFrameKeys.items, secondFrameKeys.items);

    // Verify we have the expected number of elements (root + 2 children + 2 nested)
    try std.testing.expectEqual(5, firstFrameKeys.items.len);

    // Verify all keys are unique within a frame
    for (firstFrameKeys.items, 0..) |key, i| {
        for (firstFrameKeys.items[i + 1 ..]) |otherKey| {
            try std.testing.expect(key != otherKey);
        }
    }
}

test "Component resolution" {
    try init(std.testing.allocator, undefined);
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
        fn component(props: MyComponentProps) !void {
            props.callCount.* += 1;
            const counter = try useState(u32, props.value);
            const innerArena = try useArena();
            try std.testing.expectEqual(10, counter.*);
            (try element(innerArena, .{}))({
                try text(innerArena, try std.fmt.allocPrint(innerArena, "Value {d}", .{counter.*}));
            });
        }
    }).component;

    (try element(arenaAllocator, .{}))({
        try component(
            arenaAllocator,
            MyComponent,
            MyComponentProps{ .callCount = &callCount, .value = 10, .arenaAllocator = arenaAllocator },
        );
    });
    try std.testing.expectEqual(1, callCount);

    resetNodeTree();

    (try element(arenaAllocator, .{}))({
        try component(
            arenaAllocator,
            MyComponent,
            MyComponentProps{ .callCount = &callCount, .value = 20, .arenaAllocator = arenaAllocator },
        );
    });
    try std.testing.expectEqual(2, callCount);
}

/// Registers a font from the given embedded byte contents. The font is associated with
/// `uniqueIdentifier` and only deinits when the forbear context is deinited.
pub fn registerFont(uniqueIdentifier: []const u8, comptime contents: []const u8) !void {
    const self = getContext();
    const result = try self.fonts.getOrPut(uniqueIdentifier);
    if (!result.found_existing) {
        result.value_ptr.* = try Font.init(self.allocator, uniqueIdentifier, contents);
    }
}

/// Returns a pointer to the font registered with the given unique identifier.
/// Returns an error if no font was registered with that identifier.
///
/// Before using this, call `registerFont` with the same unique identifier to
/// ensure the font is loaded and available.
pub fn useFont(uniqueIdentifier: []const u8) !*Font {
    const self = getContext();
    return self.fonts.getPtr(uniqueIdentifier) orelse {
        std.log.err("Could not find font by the unique identifier {s}", .{uniqueIdentifier});
        return error.FontNotFound;
    };
}

/// Embeds an image from the given path. Only deinits when the forbear context is deinited.
pub fn registerImage(uniqueIdentifier: []const u8, comptime contents: []const u8, format: Graphics.Image.Format) !void {
    const self = getContext();
    const result = try self.images.getOrPut(uniqueIdentifier);
    if (!result.found_existing) {
        result.value_ptr.* = try Graphics.Image.init(
            contents,
            format,
            self.renderer,
        );
    }
}

/// Returns a pointer to the image registered with the given unique identifier.
/// Returns an error if no image was registered with that identifier.
///
/// Before using this, call `registerImage` with the same unique identifier to
/// ensure the image is loaded and available.
pub fn useImage(uniqueIdentifier: []const u8) !*Image {
    const self = getContext();
    return self.images.getPtr(uniqueIdentifier) orelse {
        std.log.err("Could not find image by the unique identifier {s}", .{uniqueIdentifier});
        return error.ImageNotFound;
    };
}

const AnimationState = struct {
    /// Seconds
    timeSinceStart: f32,
    /// Seconds, equivalent to the duration
    estimatedEnd: f32,

    /// Value ranging from 0.0 to 1.0
    progress: f32,

    pub fn start(self: *?@This(), duration: f64) void {
        self.state = .{
            .timeSinceStart = 0.0,
            .estimatedEnd = duration,
            .progress = 0.0,
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
    const startValue = try useState(f32, value);
    const currentValue = try useState(f32, value);
    const targetValue = try useState(f32, value);
    const animation = try useAnimation(duration);
    const epsilon: f32 = 0.0001;

    if (targetValue.* != currentValue.*) {
        if (animation.progress()) |progress| {
            if (progress < 1.0) {
                currentValue.* = startValue.* + (targetValue.* - startValue.*) * easing(progress);
            } else {
                currentValue.* = targetValue.*;
                startValue.* = targetValue.*;
                animation.reset();
            }
        }
    }

    if (@abs(value - targetValue.*) > epsilon) {
        targetValue.* = value;
        startValue.* = currentValue.*;
        animation.start();
    }

    return currentValue.*;
}

pub const SpringConfig = struct {
    stiffness: f32,
    damping: f32,
    mass: f32,
};

pub fn useSpringTransition(target: f32, config: SpringConfig) !f32 {
    const self = getContext();
    const value = try useState(f32, target);
    const velocity = try useState(f32, 0.0);

    const dt: f32 = @floatCast(self.deltaTime orelse 0.0);
    if (dt == 0.0) return value.*;

    const displacement = target - value.*;
    const acceleration = (config.stiffness * displacement - config.damping * velocity.*) / config.mass;
    velocity.* += acceleration * dt;
    value.* += velocity.* * dt;

    const epsilon = 0.0001;
    if (@abs(displacement) <= epsilon and @abs(velocity.*) <= epsilon) {
        value.* = target;
        velocity.* = 0.0;
    }

    return value.*;
}

pub fn useAnimation(duration: f32) !Animation {
    const self = getContext();
    const state = try useState(?AnimationState, null);

    if (state.* != null) {
        if (state.*.?.progress < 1.0) {
            state.*.?.timeSinceStart += @floatCast(self.deltaTime orelse 0.0);
            state.*.?.progress = @min(
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

pub fn linear(time: f32) f32 {
    return time;
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

test "useSpringTransition - basic convergence" {
    const renderer: *Graphics.Renderer = undefined;
    try init(std.testing.allocator, renderer);
    defer deinit();
    const self = getContext();

    const config = SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const target = 100.0;
    const dt = 0.016; // ~60fps

    self.componentResolutionState = ComponentResolutionState{
        .useStateCursor = 0,
        .key = 1,
        .arenaAllocator = std.testing.allocator,
    };
    self.deltaTime = dt;

    // First frame: value should start at target when initialized
    var value = try useSpringTransition(target, config);
    try std.testing.expectEqual(target, value);

    // Change target and simulate several frames
    const newTarget = 200.0;
    const initialValue = value;

    // Simulate spring physics over multiple frames
    for (0..100) |_| {
        self.componentResolutionState.?.useStateCursor = 0;
        value = try useSpringTransition(newTarget, config);
    }

    // After 100 frames, should be very close or converged to target
    const epsilon = 0.001;
    try std.testing.expect(@abs(value - newTarget) < epsilon);
    // Value should have changed from initial
    try std.testing.expect(value != initialValue);
}

test "useSpringTransition - zero delta time" {
    const renderer: *Graphics.Renderer = undefined;
    try init(std.testing.allocator, renderer);
    defer deinit();
    const self = getContext();

    const config = SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const target = 50.0;

    self.componentResolutionState = ComponentResolutionState{
        .useStateCursor = 0,
        .key = 1,
        .arenaAllocator = std.testing.allocator,
    };
    self.deltaTime = 0.0;

    // First frame with zero dt
    const value1 = try useSpringTransition(target, config);
    try std.testing.expectEqual(target, value1);

    // Second frame with zero dt - should return current value unchanged
    self.componentResolutionState.?.useStateCursor = 0;
    const value2 = try useSpringTransition(target + 100.0, config);
    try std.testing.expectEqual(target, value2);
}

test "useSpringTransition - null delta time" {
    const renderer: *Graphics.Renderer = undefined;
    try init(std.testing.allocator, renderer);
    defer deinit();
    const self = getContext();

    const config = SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const target = 75.0;

    self.componentResolutionState = ComponentResolutionState{
        .useStateCursor = 0,
        .key = 1,
        .arenaAllocator = std.testing.allocator,
    };
    self.deltaTime = null;

    // With null delta time, should return current value
    const value = try useSpringTransition(target, config);
    try std.testing.expectEqual(target, value);
}

test "useSpringTransition - small delta time" {
    const renderer: *Graphics.Renderer = undefined;
    try init(std.testing.allocator, renderer);
    defer deinit();
    const self = getContext();

    const config = SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const initialTarget = 0.0;
    const newTarget = 100.0;
    const smallDt = 0.001; // 1ms - very small time step

    self.componentResolutionState = ComponentResolutionState{
        .useStateCursor = 0,
        .key = 1,
        .arenaAllocator = std.testing.allocator,
    };
    self.deltaTime = smallDt;

    // Initialize
    var value = try useSpringTransition(initialTarget, config);
    try std.testing.expectEqual(initialTarget, value);

    // Change target with small dt
    self.componentResolutionState.?.useStateCursor = 0;
    value = try useSpringTransition(newTarget, config);

    // Should have moved, but only slightly due to small dt
    try std.testing.expect(value != initialTarget);
    try std.testing.expect(value < newTarget);
    // Movement should be small
    try std.testing.expect(@abs(value - initialTarget) < 10.0);
}

test "useSpringTransition - large delta time" {
    const renderer: *Graphics.Renderer = undefined;
    try init(std.testing.allocator, renderer);
    defer deinit();
    const self = getContext();

    const config = SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const initialTarget = 0.0;
    const newTarget = 100.0;
    const largeDt = 1.0; // 1 second - very large frame time

    self.componentResolutionState = ComponentResolutionState{
        .useStateCursor = 0,
        .key = 1,
        .arenaAllocator = std.testing.allocator,
    };
    self.deltaTime = largeDt;

    // Initialize
    var value = try useSpringTransition(initialTarget, config);
    try std.testing.expectEqual(initialTarget, value);

    // Change target with large dt - spring should handle it gracefully
    self.componentResolutionState.?.useStateCursor = 0;
    value = try useSpringTransition(newTarget, config);

    // Should have moved significantly (physics are stable)
    try std.testing.expect(value != initialTarget);
}

test "useSpringTransition - convergence threshold" {
    const renderer: *Graphics.Renderer = undefined;
    try init(std.testing.allocator, renderer);
    defer deinit();
    const self = getContext();

    const config = SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const initialTarget = 0.0;
    const newTarget = 100.0;
    const dt = 0.016;

    self.componentResolutionState = ComponentResolutionState{
        .useStateCursor = 0,
        .key = 1,
        .arenaAllocator = std.testing.allocator,
    };
    self.deltaTime = dt;

    // Initialize
    var value = try useSpringTransition(initialTarget, config);
    try std.testing.expectEqual(initialTarget, value);

    // Animate towards target
    var converged = false;
    for (0..1000) |_| {
        self.componentResolutionState.?.useStateCursor = 0;
        value = try useSpringTransition(newTarget, config);

        // Check if converged (should snap to exact target within epsilon)
        if (value == newTarget) {
            converged = true;
            break;
        }
    }

    try std.testing.expect(converged);
    try std.testing.expectEqual(newTarget, value);
}

test "useSpringTransition - different spring configurations" {
    const renderer: *Graphics.Renderer = undefined;
    try init(std.testing.allocator, renderer);
    defer deinit();
    const self = getContext();

    const dt = 0.016;
    self.deltaTime = dt;

    // Test stiff spring (high stiffness, high damping)
    {
        self.componentResolutionState = ComponentResolutionState{
            .useStateCursor = 0,
            .key = 1,
            .arenaAllocator = std.testing.allocator,
        };

        const stiffConfig = SpringConfig{
            .stiffness = 400.0,
            .damping = 40.0,
            .mass = 1.0,
        };

        var value = try useSpringTransition(0.0, stiffConfig);
        try std.testing.expectEqual(0.0, value);

        // Should converge quickly
        for (0..50) |_| {
            self.componentResolutionState.?.useStateCursor = 0;
            value = try useSpringTransition(100.0, stiffConfig);
        }

        const epsilon = 0.1;
        try std.testing.expect(@abs(value - 100.0) < epsilon);
    }

    // Test soft spring (low stiffness, low damping)
    {
        self.componentResolutionState = ComponentResolutionState{
            .useStateCursor = 0,
            .key = 2,
            .arenaAllocator = std.testing.allocator,
        };

        const softConfig = SpringConfig{
            .stiffness = 50.0,
            .damping = 5.0,
            .mass = 1.0,
        };

        var value = try useSpringTransition(0.0, softConfig);
        try std.testing.expectEqual(0.0, value);

        // Should move more slowly
        for (0..10) |_| {
            self.componentResolutionState.?.useStateCursor = 0;
            value = try useSpringTransition(100.0, softConfig);
        }

        // After 10 frames, should not be fully converged yet
        try std.testing.expect(@abs(value - 100.0) > 1.0);
    }
}

test "useSpringTransition - heavy mass" {
    const renderer: *Graphics.Renderer = undefined;
    try init(std.testing.allocator, renderer);
    defer deinit();
    const self = getContext();

    const heavyConfig = SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 10.0, // Heavy mass
    };
    const dt = 0.016;

    self.componentResolutionState = ComponentResolutionState{
        .useStateCursor = 0,
        .key = 1,
        .arenaAllocator = std.testing.allocator,
    };
    self.deltaTime = dt;

    var value = try useSpringTransition(0.0, heavyConfig);
    try std.testing.expectEqual(0.0, value);

    // Heavy mass should result in slower acceleration
    self.componentResolutionState.?.useStateCursor = 0;
    value = try useSpringTransition(100.0, heavyConfig);

    // After one frame, movement should be relatively small due to mass
    try std.testing.expect(@abs(value) < 50.0);
}

test "useSpringTransition - target changes during animation" {
    const renderer: *Graphics.Renderer = undefined;
    try init(std.testing.allocator, renderer);
    defer deinit();
    const self = getContext();

    const config = SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const dt = 0.016;

    self.componentResolutionState = ComponentResolutionState{
        .useStateCursor = 0,
        .key = 1,
        .arenaAllocator = std.testing.allocator,
    };
    self.deltaTime = dt;

    // Initialize at 0
    var value = try useSpringTransition(0.0, config);
    try std.testing.expectEqual(0.0, value);

    // Animate towards 100 for a few frames
    for (0..10) |_| {
        self.componentResolutionState.?.useStateCursor = 0;
        value = try useSpringTransition(100.0, config);
    }
    const valueAfter10Frames = value;

    // Suddenly change target to 200
    for (0..20) |_| {
        self.componentResolutionState.?.useStateCursor = 0;
        value = try useSpringTransition(200.0, config);
    }

    // Should have moved past the first target
    try std.testing.expect(value > valueAfter10Frames);
    try std.testing.expect(value > 100.0);
}

test "useSpringTransition - negative values" {
    const renderer: *Graphics.Renderer = undefined;
    try init(std.testing.allocator, renderer);
    defer deinit();
    const self = getContext();

    const config = SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const dt = 0.016;

    self.componentResolutionState = ComponentResolutionState{
        .useStateCursor = 0,
        .key = 1,
        .arenaAllocator = std.testing.allocator,
    };
    self.deltaTime = dt;

    // Initialize at positive value
    var value = try useSpringTransition(100.0, config);
    try std.testing.expectEqual(100.0, value);

    // Transition to negative target
    for (0..100) |_| {
        self.componentResolutionState.?.useStateCursor = 0;
        value = try useSpringTransition(-50.0, config);
    }

    // Should converge to negative target
    const epsilon = 0.1;
    try std.testing.expect(@abs(value - (-50.0)) < epsilon);
}

test "useSpringTransition - state persistence across frames" {
    const renderer: *Graphics.Renderer = undefined;
    try init(std.testing.allocator, renderer);
    defer deinit();
    const self = getContext();

    const config = SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const dt = 0.016;
    self.deltaTime = dt;

    // Frame 1
    self.componentResolutionState = ComponentResolutionState{
        .useStateCursor = 0,
        .key = 1,
        .arenaAllocator = std.testing.allocator,
    };
    const value1 = try useSpringTransition(0.0, config);
    try std.testing.expectEqual(0.0, value1);

    // Frame 2 - change target
    self.componentResolutionState = ComponentResolutionState{
        .useStateCursor = 0,
        .key = 1,
        .arenaAllocator = std.testing.allocator,
    };
    const value2 = try useSpringTransition(100.0, config);

    // Frame 3 - should continue from where it left off
    self.componentResolutionState = ComponentResolutionState{
        .useStateCursor = 0,
        .key = 1,
        .arenaAllocator = std.testing.allocator,
    };
    const value3 = try useSpringTransition(100.0, config);

    // Value should continue progressing
    try std.testing.expect(value3 >= value2 or @abs(value3 - 100.0) < 0.0001);
}

/// Equivalent to CSS's ease timing function
pub fn easeInOut(progress: f32) f32 {
    return cubicBezier(0.42, 0.0, 0.58, 1.0, progress);
}

/// Equivalent to CSS's ease timing function
pub fn ease(progress: f32) f32 {
    return cubicBezier(0.25, 0.1, 0.25, 1.0, progress);
}

pub fn useViewportSize() Vec2 {
    const self = getContext();
    return self.viewportSize;
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
        defer state.useStateCursor += 1;
        if (stateResult.found_existing) {
            if (stateResult.value_ptr.items.len > state.useStateCursor) {
                return @ptrCast(@alignCast(stateResult.value_ptr.*.items[state.useStateCursor]));
            }
        } else {
            stateResult.value_ptr.* = .empty;
        }
        try stateResult.value_ptr.*.append(
            self.allocator,
            try self.allocator.alignedAlloc(u8, stateAlignment, @sizeOf(T)),
        );
        @memcpy(
            stateResult.value_ptr.*.items[state.useStateCursor],
            std.mem.asBytes(&initialValue),
        );
        return @ptrCast(@alignCast(stateResult.value_ptr.*.items[state.useStateCursor]));
    } else {
        if (!builtin.is_test) {
            std.log.err("You might be calling a hook (useState) outside of a component, and forbear cannot track things outside of one.", .{});
        }
        return error.NoComponentContext;
    }
}

test "State creation with manual handling" {
    const renderer: *Graphics.Renderer = undefined;
    try init(std.testing.allocator, renderer);
    defer deinit();
    const self = getContext();
    {
        // First run that should allocate RAM, and still allow reading and writing the values
        self.componentResolutionState = ComponentResolutionState{
            .useStateCursor = 0,
            .key = 1,
            .arenaAllocator = std.testing.allocator,
        };
        const state1 = try useState(i32, 42);
        try std.testing.expectEqual(1, self.componentStates.get(1).?.items.len);
        try std.testing.expectEqual(@sizeOf(i32), self.componentStates.get(1).?.items[0].len);
        try std.testing.expectEqual(42, state1.*);

        const state2 = try useState(f32, 3.14);
        try std.testing.expectEqual(2, self.componentStates.get(1).?.items.len);
        try std.testing.expectEqual(@sizeOf(f32), self.componentStates.get(1).?.items[1].len);
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
            .useStateCursor = 0,
            .key = 1,
            .arenaAllocator = std.testing.allocator,
        };
        const state1 = try useState(i32, 42);
        try std.testing.expectEqual(2, self.componentStates.get(1).?.items.len);
        try std.testing.expectEqual(@sizeOf(i32), self.componentStates.get(1).?.items[0].len);
        const state2 = try useState(f32, 3.14);
        try std.testing.expectEqual(2, self.componentStates.get(1).?.items.len);
        try std.testing.expectEqual(@sizeOf(f32), self.componentStates.get(1).?.items[1].len);

        try std.testing.expectEqual(100, state1.*);
        try std.testing.expectEqual(6.28, state2.*);
    }
    {
        self.componentResolutionState = null;
        try std.testing.expectError(error.NoComponentContext, useState(i32, 42));
    }
}

test "Multiple useState pointers remain valid after realloc (useTransition pattern)" {
    // This test reproduces the useTransition scenario: three sequential useState
    // calls in the same component on the first frame. If realloc moves the buffer,
    // earlier pointers would be invalidated causing a segfault.
    const renderer: *Graphics.Renderer = undefined;
    try init(std.testing.allocator, renderer);
    defer deinit();
    const self = getContext();

    {
        // First frame: all three useState calls allocate/grow the buffer
        self.componentResolutionState = ComponentResolutionState{
            .useStateCursor = 0,
            .key = 99,
            .arenaAllocator = std.testing.allocator,
        };
        defer self.componentResolutionState = null;

        // Mimics useTransition's calls:
        //   const valueToTransitionFrom = try useState(f32, value);
        //   const valueToTransitionTo = try useState(f32, value);
        //   const animation = try useAnimation(duration);  -> useState(?AnimationState, null)
        const valueToTransitionFrom = try useState(f32, 1.0);
        try std.testing.expectEqual(1.0, valueToTransitionFrom.*);
        const valueToTransitionTo = try useState(f32, 1.0);
        try std.testing.expectEqual(1.0, valueToTransitionTo.*);
        const animationState = try useState(?AnimationState, null);
        try std.testing.expectEqual(null, animationState.*);

        // These dereferences should not segfault — if realloc moved the buffer,
        // earlier pointers would be dangling and this would crash or read garbage.
        try std.testing.expectEqual(1.0, valueToTransitionFrom.*);
        try std.testing.expectEqual(1.0, valueToTransitionTo.*);
        try std.testing.expectEqual(null, animationState.*);

        // Simulate the comparison from useTransition line 419:
        //   if (value != valueToTransitionTo.*) { ... }
        const value: f32 = 2.0;
        if (value != valueToTransitionTo.*) {
            valueToTransitionTo.* = value;
        }
        try std.testing.expectEqual(2.0, valueToTransitionTo.*);
        // The first pointer should still be valid and unchanged
        try std.testing.expectEqual(1.0, valueToTransitionFrom.*);
    }

    {
        // Second frame: buffer already exists at full size, no realloc needed
        self.componentResolutionState = ComponentResolutionState{
            .useStateCursor = 0,
            .key = 99,
            .arenaAllocator = std.testing.allocator,
        };
        defer self.componentResolutionState = null;

        const valueToTransitionFrom = try useState(f32, 1.0);
        const valueToTransitionTo = try useState(f32, 1.0);
        const animationState = try useState(?AnimationState, null);

        // Second frame should preserve mutated state from first frame
        try std.testing.expectEqual(1.0, valueToTransitionFrom.*);
        try std.testing.expectEqual(2.0, valueToTransitionTo.*);
        try std.testing.expectEqual(null, animationState.*);
    }
}

test "Event queue dispatches events to correct elements" {
    try init(std.testing.allocator, undefined);
    defer deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = getContext();

    (try element(arenaAllocator, .{}))({
        (try element(arenaAllocator, .{}))({});
        const firstChildKey = self.previousPushedNode.?.key;

        (try element(arenaAllocator, .{}))({});
        const secondChildKey = self.previousPushedNode.?.key;

        try std.testing.expect(firstChildKey != secondChildKey);

        try pushEvent(firstChildKey, .mouseOver);
        try pushEvent(firstChildKey, .mouseOut);
        try pushEvent(secondChildKey, .mouseOver);
    });

    resetNodeTree();
    _ = arena.reset(.retain_capacity);

    (try element(arenaAllocator, .{}))({
        (try element(arenaAllocator, .{}))({});

        try std.testing.expectEqual(Event.mouseOut, useNextEvent().?);
        try std.testing.expectEqual(Event.mouseOver, useNextEvent().?);
        try std.testing.expectEqual(null, useNextEvent());

        (try element(arenaAllocator, .{}))({});

        try std.testing.expectEqual(Event.mouseOver, useNextEvent().?);
        try std.testing.expectEqual(null, useNextEvent());
    });
}

/// This is meant to be returned as a function that will only run once the
/// "block" is executed. It's a really smart trick from someone doing an
/// immediate mode UI library in Zig as well from teh Zig Discord server.
///
/// TODO: share the github of the person I got this trick from
fn popParentStack(block: void) void {
    _ = block;
    const self = getContext();
    std.debug.assert(self.frameNodeParentStack.items.len > 0);
    self.previousPushedNode = self.frameNodeParentStack.pop();
    _ = self.frameNodePath.pop();
}

fn putNode(arena: std.mem.Allocator) !struct { ptr: *Node, index: usize } {
    const self = getContext();
    if (self.frameNodeParentStack.getLastOrNull()) |parent| {
        std.debug.assert(self.rootFrameNode != null);
        // How can we make sure that these asserts aren't really necessary? HOw
        // can we make sure that the compiler will ensure that the parent here
        // always allows for children?
        std.debug.assert(parent.content == .element);
        return .{
            .ptr = try parent.content.element.children.addOne(arena),
            .index = parent.content.element.children.items.len - 1,
        };
    } else {
        if (self.rootFrameNode != null) {
            return error.MultipleRootNodesNotSupported;
        }
        self.rootFrameNode = .{
            .content = undefined,
            .key = undefined,
        };
        return .{ .ptr = &self.rootFrameNode.?, .index = 0 };
    }
}

pub fn image(arena: std.mem.Allocator, style: IncompleteStyle, img: *Image) !void {
    const self = getContext();

    const result = try putNode(arena);

    var hasher = std.hash.Wyhash.init(0);
    hasher.update(std.mem.sliceAsBytes(self.frameNodePath.items));
    hasher.update(std.mem.asBytes(&result.index));

    var complementedStyle = style;
    const imageWidth: f32 = @floatFromInt(img.width);
    const imageHeight: f32 = @floatFromInt(img.height);
    switch (complementedStyle.width) {
        .fit => {
            switch (complementedStyle.height) {
                .fit => {
                    complementedStyle.width = .{ .fixed = imageWidth };
                    complementedStyle.height = .{ .ratio = imageHeight / imageWidth };
                    complementedStyle.minWidth = 0;
                    complementedStyle.minHeight = 0;
                },
                .grow, .fixed, .percentage => {
                    complementedStyle.width = .{ .ratio = imageWidth / imageHeight };
                },
                .ratio => {},
            }
        },
        .fixed, .percentage => {
            switch (complementedStyle.height) {
                .fit, .grow => {
                    complementedStyle.height = .{ .ratio = imageHeight / imageWidth };
                },
                .fixed, .percentage, .ratio => {},
            }
        },
        .grow => {
            switch (complementedStyle.height) {
                .grow, .fit => {
                    complementedStyle.height = .{ .ratio = imageHeight / imageWidth };
                },
                .fixed, .percentage => {
                    complementedStyle.width = .{ .ratio = imageWidth / imageHeight };
                },
                .ratio => {},
            }
        },
        .ratio => {},
    }
    complementedStyle.background = .{ .image = img };

    result.ptr.* = Node{
        .key = hasher.final(),
        .content = .{
            .element = .{
                .style = complementedStyle,
                .children = .empty,
            },
        },
    };
    self.previousPushedNode = result.ptr;
}

pub fn element(arena: std.mem.Allocator, style: IncompleteStyle) !*const fn (void) void {
    const self = getContext();

    const result = try putNode(arena);

    var hasher = std.hash.Wyhash.init(0);
    hasher.update(std.mem.sliceAsBytes(self.frameNodePath.items));
    hasher.update(std.mem.asBytes(&result.index));

    result.ptr.* = Node{
        .key = hasher.final(),
        .content = .{
            .element = .{
                .style = style,
                .children = .empty,
            },
        },
    };
    try self.frameNodeParentStack.append(self.allocator, result.ptr);
    try self.frameNodePath.append(self.allocator, result.index);
    return &popParentStack;
}

pub fn text(arena: std.mem.Allocator, content: []const u8) !void {
    const result = try putNode(arena);

    const self = getContext();
    var hasher = std.hash.Wyhash.init(0);
    hasher.update(content);
    hasher.update(std.mem.sliceAsBytes(self.frameNodePath.items));
    hasher.update(std.mem.asBytes(&result.index));

    result.ptr.* = Node{
        .key = hasher.final(),
        .content = .{
            .text = content,
        },
    };
    self.previousPushedNode = result.ptr;
}

inline fn ReturnType(comptime function: anytype) type {
    const Function = @TypeOf(function);
    const functionTypeInfo = @typeInfo(Function);
    if (functionTypeInfo != .@"fn") {
        @compileError("expected function to be a `fn`, but found " ++ @typeName(Function));
    }
    if (functionTypeInfo.@"fn".return_type) |ReturnTypeT| {
        const returnTypeInfo = @typeInfo(ReturnTypeT);
        if (returnTypeInfo == .error_union) {
            return returnTypeInfo.error_union.payload;
        } else {
            return ReturnTypeT;
        }
    }
    return void;
}

pub inline fn PropsOf(comptime function: anytype) type {
    const Function = @TypeOf(function);
    const functionTypeInfo = @typeInfo(Function);
    if (functionTypeInfo != .@"fn") {
        @compileError("expected function to be a `fn`, but found " ++ @typeName(Function));
    }
    if (functionTypeInfo.@"fn".params.len == 0) {
        return @TypeOf(null);
    } else if (functionTypeInfo.@"fn".params.len == 1) {
        return functionTypeInfo.@"fn".params[0].type orelse void;
    } else {
        @compileError(
            "function components can only have one parameter `props: struct`, found " ++ std.fmt.comptimePrint("{d}", .{functionTypeInfo.@"fn".params.len}),
        );
    }
}

pub inline fn component(arena: std.mem.Allocator, comptime function: anytype, props: PropsOf(function)) !ReturnType(function) {
    const Function = @TypeOf(function);
    const functionTypeInfo = @typeInfo(Function);
    if (functionTypeInfo != .@"fn") {
        @compileError("expected function to be a `fn`, but found " ++ @typeName(function));
    }

    if (functionTypeInfo.@"fn".params.len > 1) {
        @compileError(
            "function components can only have one parameter `props: struct`, found " ++ std.fmt.comptimePrint("{d}", .{functionTypeInfo.@"fn".params.len}),
        );
    }

    const hasProps = functionTypeInfo.@"fn".params.len == 1;

    if (hasProps and functionTypeInfo.@"fn".params[0].type != @TypeOf(props)) {
        @compileError("expected props to be of type " ++ @typeName(functionTypeInfo.@"fn".params[0].type orelse void) ++ ", but found " ++ @typeName(@TypeOf(props)));
    }

    const self = getContext();
    var hasher = std.hash.Wyhash.init(0);
    hasher.update(std.mem.asBytes(&@intFromPtr(&function)));
    hasher.update(std.mem.sliceAsBytes(self.frameNodePath.items));
    const componentKey = hasher.final();

    const previousComponentResolutionState = self.componentResolutionState;
    self.componentResolutionState = .{
        .key = componentKey,
        .arenaAllocator = arena,
        .useStateCursor = 0,
    };
    const returnValue = if (hasProps)
        try function(props)
    else
        try function();
    if (self.componentStates.contains(componentKey) and self.componentResolutionState.?.useStateCursor != self.componentStates.get(componentKey).?.items.len) {
        return error.RulesOfHooksViolated;
    }
    self.componentResolutionState = previousComponentResolutionState;
    return returnValue;
}

fn pushEvent(key: u64, event: Event) !void {
    const self = getContext();
    const result = try self.frameEventQueue.getOrPut(key);
    if (!result.found_existing) {
        result.value_ptr.* = try std.ArrayList(Event).initCapacity(self.allocator, 1);
    }
    try result.value_ptr.*.append(self.allocator, event);
}

/// Returns the next event in the queue to handle for the current element key.
pub fn useNextEvent() ?Event {
    const self = getContext();
    if (self.previousPushedNode) |previous| {
        const key = previous.key;
        // std.log.debug("handling events for {}", .{key});
        if (self.frameEventQueue.getPtr(key)) |eventQueue| {
            return eventQueue.pop();
        }
    }
    return null;
}

pub fn update(arena: std.mem.Allocator, root: *const LayoutBox, viewportSize: Vec2) !void {
    const self = getContext();

    var queueIterator = self.frameEventQueue.valueIterator();
    while (queueIterator.next()) |events| {
        events.clearRetainingCapacity();
    }

    var iterator = try layouting.LayoutTreeIterator.init(arena, root);

    var missingHoveredKeys = try std.ArrayList(u64).initCapacity(arena, self.hoveredElementKeys.items.len);
    missingHoveredKeys.appendSliceAssumeCapacity(self.hoveredElementKeys.items);

    var uiEdges: Vec2 = @splat(0.0);

    while (try iterator.next()) |layoutBox| {
        if (layoutBox.style.placement == .standard) {
            // this +scrollPosition term feels hacky to do, it's only required
            // because layouting adds in the scroll position
            uiEdges = @max(uiEdges, layoutBox.position + self.scrollPosition + layoutBox.size);
        }
        const isMouseAfter = layoutBox.position[0] <= self.mousePosition[0] and layoutBox.position[1] <= self.mousePosition[1];
        const isMouseBefore = layoutBox.position[0] + layoutBox.size[0] >= self.mousePosition[0] and layoutBox.position[1] + layoutBox.size[1] >= self.mousePosition[1];
        const isMouseInside = isMouseAfter and isMouseBefore;

        const hoveredElementKeysIndexOpt = std.mem.indexOfScalar(u64, self.hoveredElementKeys.items, layoutBox.key);

        if (std.mem.indexOfScalar(u64, missingHoveredKeys.items, layoutBox.key)) |i| {
            _ = missingHoveredKeys.swapRemove(i);
        }

        if (isMouseInside) {
            if (hoveredElementKeysIndexOpt == null) {
                try pushEvent(layoutBox.key, .mouseOver);

                try self.hoveredElementKeys.append(self.allocator, layoutBox.key);
            }
        } else if (hoveredElementKeysIndexOpt) |hoveredElementKeysIndex| {
            try pushEvent(layoutBox.key, .mouseOut);

            _ = self.hoveredElementKeys.swapRemove(hoveredElementKeysIndex);
        }
    }

    for (missingHoveredKeys.items) |key| {
        if (std.mem.indexOfScalar(u64, self.hoveredElementKeys.items, key)) |i| {
            _ = self.hoveredElementKeys.swapRemove(i);
        }
    }

    self.viewportSize = viewportSize;

    const timestamp = timestampSeconds();
    self.deltaTime = timestamp - (self.lastUpdateTime orelse (timestamp - self.startTime));
    self.lastUpdateTime = timestamp;

    try component(arena, Scrolling, .{ .uiEdges = uiEdges });
}

fn Scrolling(props: struct { uiEdges: Vec2 }) !void {
    const self = getContext();
    const viewportSize = useViewportSize();

    const identity: Vec2 = @splat(0.0);
    self.effectiveScrollPosition = @min(
        @max(self.effectiveScrollPosition, identity),
        @max(props.uiEdges - viewportSize, identity),
    );

    if (builtin.os.tag == .macos) {
        self.scrollPosition = self.effectiveScrollPosition;
    } else {
        const spring = SpringConfig{
            .stiffness = 320.0,
            .damping = 32.0,
            .mass = 1.0,
        };
        self.scrollPosition[0] = try useSpringTransition(self.effectiveScrollPosition[0], spring);
        self.scrollPosition[1] = try useSpringTransition(self.effectiveScrollPosition[1], spring);
    }
}

/// Resets the UI state, clearing the root frame node - and consequently - everything else.
pub fn resetNodeTree() void {
    const self = getContext();
    self.rootFrameNode = null;
    self.frameNodeParentStack.clearRetainingCapacity();
    self.frameNodePath.clearRetainingCapacity();
}

fn timestampSeconds() f64 {
    return @as(f64, @floatFromInt(std.time.nanoTimestamp())) / std.time.ns_per_s;
}

pub fn setWindowHandlers(window: *Window) void {
    const self = getContext();

    window.handlers.resize = .{
        .function = &(struct {
            fn handler(_: *Window, width: u32, height: u32, dpi: [2]u32, data: *anyopaque) void {
                _ = dpi;
                const ctx: *Context = @ptrCast(@alignCast(data));
                ctx.renderer.handleResize(width, height) catch |err| {
                    std.log.err("Renderer failed to handle resize: {}", .{err});
                };
            }
        }).handler,
        .data = @ptrCast(@alignCast(self)),
    };
    window.handlers.scroll = .{
        .function = &(struct {
            fn handler(wnd: *Window, axis: Window.ScrollAxis, nativeOffset: f32, data: *anyopaque) void {
                const ctx: *Context = @ptrCast(@alignCast(data));
                // On macOS, scrollingDeltaX/Y already provides properly scaled pixel
                // values from the trackpad/mouse, so we use them directly.
                // On other platforms, the native offset is a raw axis value where
                // only the direction matters, so we use a fixed step size.
                const offset = if (builtin.os.tag == .macos)
                    nativeOffset
                else
                    100.0 * std.math.sign(nativeOffset);

                // Browser-like behavior: Shift + vertical scroll = horizontal scroll
                const shiftAccordingAxis = if (wnd.isHoldingShift() and axis == .vertical)
                    .horizontal
                else if (wnd.isHoldingShift() and axis == .horizontal)
                    .vertical
                else
                    axis;

                switch (shiftAccordingAxis) {
                    .horizontal => ctx.effectiveScrollPosition[0] += offset,
                    .vertical => ctx.effectiveScrollPosition[1] += offset,
                }
            }
        }).handler,
        .data = @ptrCast(@alignCast(self)),
    };
    window.handlers.pointerMotion = .{
        .function = &(struct {
            fn handler(_: *Window, x: f32, y: f32, data: *anyopaque) void {
                const ctx: *Context = @ptrCast(@alignCast(data));
                ctx.mousePosition = .{ x, y };
            }
        }).handler,
        .data = @ptrCast(@alignCast(self)),
    };
}

pub fn deinit() void {
    const self = getContext();

    self.hoveredElementKeys.deinit(self.allocator);

    var componentStatesIterator = self.componentStates.valueIterator();
    while (componentStatesIterator.next()) |states| {
        for (states.items) |state| {
            self.allocator.free(state);
        }
        states.deinit(self.allocator);
    }
    self.componentStates.deinit();

    var eventQueueIterator = self.frameEventQueue.valueIterator();
    while (eventQueueIterator.next()) |events| {
        events.deinit(self.allocator);
    }
    self.frameEventQueue.deinit();

    self.frameNodeParentStack.deinit(self.allocator);
    self.frameNodePath.deinit(self.allocator);

    var fontsIterator = self.fonts.valueIterator();
    while (fontsIterator.next()) |font| {
        font.deinit();
    }
    self.fonts.deinit();
    var imagesIterator = self.images.valueIterator();
    while (imagesIterator.next()) |img| {
        img.deinit();
    }
    self.images.deinit();

    context = null;
}

pub fn getContext() *@This() {
    return &context.?;
}

test {
    _ = std.testing.refAllDecls(@This());
}
