const std = @import("std");
const builtin = @import("builtin");

pub const c = @import("c");

pub const Font = @import("font.zig");
const forbearBuiltin = @import("builtin.zig");
pub const FpsCounter = forbearBuiltin.FpsCounter;
pub const useScrolling = forbearBuiltin.useScrolling;
pub const ScrollBar = forbearBuiltin.ScrollBar;
pub const Graphics = @import("graphics.zig");
const ImageType = @import("graphics.zig").Image;
const layouting = @import("layouting.zig");
pub const layout = layouting.layout;
const nodeImport = @import("node.zig");
pub const Node = nodeImport.Node;
pub const TextWrapping = nodeImport.TextWrapping;
pub const NodeTree = nodeImport.NodeTree;
pub const Direction = nodeImport.Direction;
pub const LayoutGlyph = nodeImport.LayoutGlyph;
pub const Glyphs = nodeImport.Glyphs;
pub const BaseStyle = nodeImport.BaseStyle;
pub const Alignment = nodeImport.Alignment;
pub const Padding = nodeImport.Padding;
pub const Margin = nodeImport.Margin;
pub const BorderWidth = nodeImport.BorderWidth;
pub const Shadow = nodeImport.Shadow;
pub const Offset = nodeImport.Shadow.Offset;
pub const CompleteStyle = nodeImport.CompleteStyle;
pub const Style = nodeImport.Style;
pub const Element = nodeImport.Element;
pub const GradientStop = nodeImport.GradientStop;
pub const Window = @import("window/root.zig").Window;
pub const Cursor = @import("window/root.zig").Cursor;

pub var traceWriter: ?*std.Io.Writer = null;
pub fn setTraceWriter(writer: *std.Io.Writer) void {
    traceWriter = writer;
}
const Vec2 = @Vector(2, f32);
const Vec3 = @Vector(3, f32);
const Vec4 = @Vector(4, f32);

const Context = @This();
var context: ?@This() = null;
pub fn getContext() *@This() {
    return &context.?;
}

const Scope = struct { key: u64, arenaAllocator: std.heap.ArenaAllocator };

const ComponentChildrenSlotState = struct {
    savedSlotParentStack: []usize,
    savedPreEndParentStack: []usize,
    slotPredecessor: ?usize,
    afterChainStart: ?usize,
    afterChainEnd: ?usize,
    parentIndex: usize,
};

pub const Event = enum {
    mouseEnter,
    mouseLeave,
    mouseDown,
    mouseUp,
    mouseMove,
    click,
    scroll,
};

pub const FrameMeta = struct {
    arena: std.mem.Allocator,

    viewportSize: Vec2,
    baseStyle: BaseStyle,

    err: ?anyerror = null,

    touchedScopes: std.ArrayList(u64) = .empty,
    touchedStates: std.ArrayList(u64) = .empty,
    /// stack of keys for scopes
    scopeStack: std.ArrayList(u64) = .empty,
    /// indices into the NodeTree
    nodeStack: std.ArrayList(usize) = .empty,

    previousPushedNodeIndex: ?usize = null,
    componentChildrenSlotStates: std.ArrayList(ComponentChildrenSlotState) = .empty,
};

allocator: std.mem.Allocator,
io: std.Io,

mousePosition: Vec2,
mouseButtonPressed: bool,
/// Accumulated wheel/trackpad delta from window events. Snapshotted
/// into `scrollDelta` at frame start, then reset.
scrollDeltaAccumulator: Vec2,
/// Stable snapshot of scroll delta for the current frame.
scrollDelta: Vec2,
previousFrameNodeMeasurements: std.AutoHashMap(u64, Node.Measurement),

renderer: *Graphics.Renderer,
window: ?*Window,

/// Seconds
startTime: f64,
/// Seconds
deltaTime: ?f64,
/// Seconds. Same as `deltaTime` but clamped to `maxCappedDeltaTime` so that
/// spring integrators and animation progress stay stable during frame stutters.
cappedDeltaTime: ?f64,
/// Seconds
lastUpdateTime: ?f64,
viewportSize: Vec2,

scopes: std.ArrayList(Scope) = .empty,
states: std.AutoHashMap(u64, *anyopaque),

nodeTree: NodeTree,
frameMeta: ?FrameMeta,

images: std.StringHashMap(ImageType),
fonts: std.StringHashMap(Font),

pub fn init(allocator: std.mem.Allocator, io: std.Io, renderer: *Graphics.Renderer) !void {
    if (context != null) {
        return error.AlreadyInitialized;
    }

    context = @This(){
        .allocator = allocator,
        .io = io,

        .mousePosition = @splat(0.0),
        .mouseButtonPressed = false,
        .scrollDeltaAccumulator = @splat(0.0),
        .scrollDelta = @splat(0.0),
        .previousFrameNodeMeasurements = std.AutoHashMap(u64, Node.Measurement).init(allocator),

        .renderer = renderer,
        .window = null,

        .startTime = timestampSeconds(io),
        .deltaTime = null,
        .cappedDeltaTime = null,
        .lastUpdateTime = null,
        .viewportSize = @splat(0.0),

        .scopes = try .initCapacity(allocator, 256),
        .states = .init(allocator),

        .frameMeta = null,
        .nodeTree = .empty,

        .images = std.StringHashMap(ImageType).init(allocator),
        .fonts = std.StringHashMap(Font).init(allocator),
    };
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
pub fn useImage(uniqueIdentifier: []const u8) !*ImageType {
    const self = getContext();
    return self.images.getPtr(uniqueIdentifier) orelse {
        std.log.err("Could not find image by the unique identifier {s}", .{uniqueIdentifier});
        // TODO: return null, and then allow for null in forbear.image where it
        // instead would render a placeholder background color
        return error.ImageNotFound;
    };
}

pub const AnimationState = struct {
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

pub fn useTransition(comptime T: type, value: T, duration: f32, easing: fn (f32) f32) T {
    hook();
    defer hookEnd();

    if (T != f32 and T != Vec2 and T != Vec3 and T != Vec4) {
        @compileError("useTransition only supports f32, @Vector(2, f32), @Vector(3, f32), and @Vector(4, f32) types for now. If you want to see support for more types please open an issue.");
    }
    const isVector = T == Vec2 or T == Vec3 or T == Vec4;

    const startValue = useState(T, value);
    const currentValue = useState(T, value);
    const targetValue = useState(T, value);
    const animation = useAnimation(duration);
    const epsilon: f32 = 0.0001;

    const targetDiffersFromCurrent = if (isVector)
        @reduce(.Or, targetValue.* != currentValue.*)
    else
        targetValue.* != currentValue.*;

    if (targetDiffersFromCurrent) {
        if (animation.progress()) |progress| {
            if (progress < 1.0) {
                currentValue.* = startValue.* + (targetValue.* - startValue.*) * if (isVector)
                    @as(T, @splat(easing(progress)))
                else
                    easing(progress);
            } else {
                currentValue.* = targetValue.*;
                startValue.* = targetValue.*;
                animation.reset();
            }
        }
    }

    const valueDiffersFromTarget = if (isVector)
        @reduce(.Or, @abs(value - targetValue.*) > @as(T, @splat(epsilon)))
    else
        @abs(value - targetValue.*) > epsilon;

    if (valueDiffersFromTarget) {
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

pub fn useSpringTransition(target: f32, config: SpringConfig) f32 {
    hook();
    defer hookEnd();

    const self = getContext();
    const value = useState(f32, target);
    const velocity = useState(f32, 0.0);

    const dt: f32 = @floatCast(self.cappedDeltaTime orelse 0.0);
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

pub fn useAnimation(duration: f32) Animation {
    hook();
    defer hookEnd();

    const self = getContext();
    const state = useState(?AnimationState, null);

    if (state.* != null) {
        if (state.*.?.progress < 1.0) {
            state.*.?.timeSinceStart += @floatCast(self.cappedDeltaTime orelse 0.0);
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

/// Equivalent to CSS's ease-in-out timing function
pub fn easeInOut(progress: f32) f32 {
    return cubicBezier(0.42, 0.0, 0.58, 1.0, progress);
}

/// Equivalent to CSS's ease-out timing function
pub fn easeOut(progress: f32) f32 {
    return cubicBezier(0.0, 0.0, 0.58, 1.0, progress);
}

/// Equivalent to CSS's ease timing function
pub fn ease(progress: f32) f32 {
    return cubicBezier(0.25, 0.1, 0.25, 1.0, progress);
}

pub const red = hex("#ff0000");
pub const white = hex("#ffffff");
pub const black = hex("#000000");
pub const transparent = hex("#00000000");
// TODO: add all CSS named colors here

pub fn rgba(r: f32, g: f32, b: f32, a: f32) Vec4 {
    return .{
        r / 255.0,
        g / 255.0,
        b / 255.0,
        a,
    };
}

pub fn rgb(r: f32, g: f32, b: f32) Vec4 {
    return .{
        r / 255.0,
        g / 255.0,
        b / 255.0,
        1.0,
    };
}

pub fn hex(comptime value: []const u8) Vec4 {
    return comptime blk: {
        const digits = if (value.len > 0 and value[0] == '#') value[1..] else value;
        const r = @as(f32, std.fmt.parseInt(
            u8,
            digits[0..2],
            16,
        ) catch @compileError("can't parse red channel")) / 255.0;
        const g = @as(f32, std.fmt.parseInt(
            u8,
            digits[2..4],
            16,
        ) catch @compileError("can't parse green channel")) / 255.0;
        const b = @as(f32, std.fmt.parseInt(
            u8,
            digits[4..6],
            16,
        ) catch @compileError("can't parse blue channel")) / 255.0;
        const a = if (digits.len >= 8)
            @as(f32, std.fmt.parseInt(
                u8,
                digits[6..8],
                16,
            ) catch @compileError("can't parse alpha channel")) / 255.0
        else
            1.0;
        break :blk Vec4{ r, g, b, a };
    };
}

pub fn useMousePosition() Vec2 {
    const self = getContext();
    return self.mousePosition;
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

pub fn getParentNode() ?*Node {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);
    const index = self.frameMeta.?.nodeStack.getLastOrNull() orelse return null;
    return self.nodeTree.at(index);
}

pub fn getPreviousNode() ?*Node {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);
    const index = self.frameMeta.?.previousPushedNodeIndex orelse return null;
    return self.nodeTree.at(index);
}

pub fn useArena() std.mem.Allocator {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);
    return self.frameMeta.?.arena;
}

fn pushScope(key: u64) error{OutOfMemory}!void {
    const self = getContext();
    for (self.scopes.items) |scope| {
        if (scope.key == key) {
            try self.frameMeta.?.scopeStack.append(self.frameMeta.?.arena, key);
            try self.frameMeta.?.touchedScopes.append(self.frameMeta.?.arena, key);
            return;
        }
    }

    try self.scopes.append(self.allocator, Scope{
        .arenaAllocator = std.heap.ArenaAllocator.init(self.allocator),
        .key = key,
    });
    try self.frameMeta.?.scopeStack.append(self.frameMeta.?.arena, key);
    try self.frameMeta.?.touchedScopes.append(self.frameMeta.?.arena, key);
}

fn popScope() void {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) {
        return;
    }
    _ = self.frameMeta.?.scopeStack.pop();
}

pub noinline fn useState(comptime T: type, initialValue: T) *T {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);

    if (self.frameMeta.?.err != null) {
        // Return a pointer to valid (but dummy) storage to avoid crashes
        // when error handling continues to evaluate the rest of the frame
        const Static = struct {
            var dummy: T = std.mem.zeroes(T);
        };
        return &Static.dummy;
    }

    if (self.frameMeta.?.scopeStack.getLastOrNull()) |scopeKey| {
        var hasher = std.hash.Wyhash.init(0);
        hasher.update(std.mem.asBytes(&scopeKey));
        hasher.update(std.mem.asBytes(&@returnAddress()));

        const scope: *Scope = blk: {
            for (self.scopes.items) |*s| {
                if (s.key == scopeKey) {
                    break :blk s;
                }
            }
            unreachable;
        };
        const stateKey = hasher.final();

        self.frameMeta.?.touchedStates.append(self.frameMeta.?.arena, stateKey) catch |err| {
            std.log.err("Failed to track that state was touched: {}", .{err});
            @panic("Out of memory when tracking touched state for useState");
        };

        const state = self.states.getOrPut(stateKey) catch |err| {
            std.log.err("Failed to track that state was touched: {}", .{err});
            @panic("Out of memory when tracking touched state for useState");
        };
        if (!state.found_existing) {
            const value = scope.arenaAllocator.allocator().create(T) catch |err| {
                std.log.err("Failed to allocate state for useState: {}", .{err});
                @panic("Out of memory when allocating state for useState");
            };
            value.* = initialValue;
            state.value_ptr.* = @ptrCast(@alignCast(value));
        }

        return @ptrCast(@alignCast(state.value_ptr.*));
    } else {
        if (!builtin.is_test) {
            std.log.err("You might be calling a hook (useState) outside of a component or element scope, and forbear cannot track things outside of one.", .{});
        }
        @panic("Invalid hook usage");
    }
}

fn endNoop(block: void) void {
    _ = block;
}

/// A thin wrapper around `element` that includes some aspect ratio handling
/// definition logic in a way that feels more intuitve
pub fn Image(style: Style, img: *ImageType) void {
    component(.{})({
        var complementedStyle = style;
        const imageWidth: f32 = @floatFromInt(img.width);
        const imageHeight: f32 = @floatFromInt(img.height);
        const width = complementedStyle.width orelse .fit;
        const height = complementedStyle.height orelse .fit;
        switch (width) {
            .fit => {
                switch (height) {
                    .fit => {
                        complementedStyle.width = .{ .fixed = imageWidth };
                        complementedStyle.height = .{ .ratio = imageHeight / imageWidth };
                        complementedStyle.minWidth = 0;
                        complementedStyle.minHeight = 0;
                    },
                    .grow, .fixed => {
                        complementedStyle.width = .{ .ratio = imageWidth / imageHeight };
                    },
                    .ratio => {},
                }
            },
            .fixed => {
                switch (height) {
                    .fit, .grow => {
                        complementedStyle.height = .{ .ratio = imageHeight / imageWidth };
                    },
                    .fixed, .ratio => {},
                }
            },
            .grow => {
                switch (height) {
                    .grow, .fit => {
                        complementedStyle.height = .{ .ratio = imageHeight / imageWidth };
                    },
                    .fixed => {
                        complementedStyle.width = .{ .ratio = imageWidth / imageHeight };
                    },
                    .ratio => {},
                }
            },
            .ratio => {},
        }
        complementedStyle.background = .{ .image = img };

        element(.{ .style = complementedStyle })({});
    });
}

fn frameEnd(block: void) anyerror!void {
    _ = block;
    const self = getContext();

    std.debug.assert(self.frameMeta != null);
    const frameMeta = self.frameMeta.?;
    defer self.frameMeta = null;
    if (frameMeta.err) |err| return err;

    var i: usize = self.scopes.items.len;
    while (i > 0) {
        i -= 1;
        var touched = false;
        for (frameMeta.touchedScopes.items) |key| {
            if (self.scopes.items[i].key == key) {
                touched = true;
                break;
            }
        }
        if (!touched) {
            const scope = self.scopes.orderedRemove(i);
            scope.arenaAllocator.deinit();
        }
    }

    // TODO: we're removing the state here, but we're not freeing it. We're
    // also not removing state when freeing state at the point a scope is
    // removed
    var staleStateKeys: std.ArrayList(u64) = .empty;
    defer staleStateKeys.deinit(frameMeta.arena);
    var existingStateKeys = self.states.keyIterator();
    while (existingStateKeys.next()) |stateKey| {
        var touched = false;
        for (frameMeta.touchedStates.items) |touchedKey| {
            if (stateKey.* == touchedKey) {
                touched = true;
                break;
            }
        }
        if (!touched) {
            try staleStateKeys.append(frameMeta.arena, stateKey.*);
        }
    }
    for (staleStateKeys.items) |staleKey| {
        _ = self.states.remove(staleKey);
    }

    var staleFrameNodeMeasurements: std.ArrayList(u64) = .empty;
    defer staleFrameNodeMeasurements.deinit(frameMeta.arena);
    var iterator = self.previousFrameNodeMeasurements.iterator();
    while (iterator.next()) |entry| {
        if (self.nodeTree.list.items.len < entry.value_ptr.index + 1) {
            try staleFrameNodeMeasurements.append(frameMeta.arena, entry.key_ptr.*);
            continue;
        }
        const node = self.nodeTree.at(entry.value_ptr.index);
        if (node.key != entry.key_ptr.*) {
            try staleFrameNodeMeasurements.append(frameMeta.arena, entry.key_ptr.*);
            continue;
        }
        entry.value_ptr.* = .{
            .index = entry.value_ptr.index,
            .done = true,

            .size = node.size,
            .position = node.position,
            .maxSize = node.maxSize,
            .minSize = node.minSize,
            .contentSize = node.contentSize,
            .z = node.z,
        };
    }
    for (staleFrameNodeMeasurements.items) |staleKey| {
        _ = self.previousFrameNodeMeasurements.remove(staleKey);
    }

    self.nodeTree.clearRetainingCapacity();
}

pub fn frame(meta: FrameMeta) *const fn (void) anyerror!void {
    const self = getContext();

    self.scrollDelta = self.scrollDeltaAccumulator;
    self.scrollDeltaAccumulator = @splat(0.0);

    self.frameMeta = meta;
    return &frameEnd;
}

/// TODO: share the github of the person I got the trick of using an end
/// function as return value
fn elementEnd(block: void) void {
    _ = block;
    const self = getContext();
    std.debug.assert(self.frameMeta != null);
    std.debug.assert(self.frameMeta.?.nodeStack.items.len > 0);

    popScope();

    self.frameMeta.?.previousPushedNodeIndex = self.frameMeta.?.nodeStack.pop();

    const previousNodeIndex = self.frameMeta.?.previousPushedNodeIndex.?;
    const node = self.nodeTree.at(previousNodeIndex);

    if (node.style.width == .ratio) {
        node.size[0] = node.style.width.ratio * node.size[1];
    }
    if (node.style.height == .ratio) {
        node.size[1] = node.style.height.ratio * node.size[0];
    }
    node.size[0] = @min(@max(node.size[0], node.minSize[0]), node.maxSize[0]);
    node.size[1] = @min(@max(node.size[1], node.minSize[1]), node.maxSize[1]);
}

pub const ElementProps = struct {
    style: Style = .{},
    key: ?[]const u8 = null,
};

pub noinline fn element(props: ElementProps) *const fn (void) void {
    const self = getContext();

    std.debug.assert(self.frameMeta != null);

    if (self.frameMeta.?.err != null) return &endNoop;

    const parentIndexOptional = self.frameMeta.?.nodeStack.getLastOrNull();

    const result = self.nodeTree.putNode(self.allocator, parentIndexOptional) catch |err| {
        handleFrameError(err);
        return &endNoop;
    };

    const parentOptional = if (parentIndexOptional) |parentIndex|
        self.nodeTree.at(parentIndex)
    else
        null;

    const incompleteStyle = props.style;
    const baseStyle = if (parentOptional) |parent|
        BaseStyle.from(parent.style)
    else
        self.frameMeta.?.baseStyle;
    const style = incompleteStyle.completeWith(baseStyle);

    const parentZ = if (parentOptional) |parent|
        parent.z
    else
        0;

    var hasher = std.hash.Wyhash.init(0);
    if (self.frameMeta.?.scopeStack.getLastOrNull()) |lastScopeKey| {
        hasher.update(std.mem.asBytes(&lastScopeKey));
    }
    hasher.update(std.mem.asBytes(&self.frameMeta.?.nodeStack.items.len));
    if (props.key) |key| {
        hasher.update(key);
    } else {
        hasher.update(std.mem.asBytes(&@returnAddress()));
    }

    result.ptr.key = hasher.final();
    result.ptr.style = style;
    result.ptr.z = if (incompleteStyle.zIndex) |zIndex|
        zIndex
    else if (parentZ < std.math.maxInt(u16))
        parentZ + 1
    else
        parentZ;
    result.ptr.position = switch (style.placement) {
        .fixed => |v| v,
        .absolute => |v| v,
        .relative => |v| v,
        .flow => @splat(0.0),
    };
    result.ptr.size = .{
        switch (style.width) {
            .fixed => |width| width,
            .ratio => |ratio| if (style.height == .fixed)
                style.height.fixed * ratio
            else
                0.0,
            .fit, .grow => 0.0,
        },
        switch (style.height) {
            .fixed => |height| height,
            .ratio => |ratio| if (style.width == .fixed)
                style.width.fixed * ratio
            else
                0.0,
            .fit, .grow => 0.0,
        },
    };
    result.ptr.minSize = .{
        if (style.minWidth) |minWidth|
            minWidth
        else if (style.width == .fixed)
            style.width.fixed
        else
            0.0,
        if (style.minHeight) |minHeight|
            minHeight
        else if (style.height == .fixed)
            style.height.fixed
        else
            0.0,
    };
    result.ptr.maxSize = .{
        if (style.maxWidth) |maxWidth|
            maxWidth
        else if (style.width == .fixed)
            style.width.fixed
        else
            std.math.inf(f32),
        if (style.maxHeight) |maxHeight|
            maxHeight
        else if (style.height == .fixed)
            style.height.fixed
        else
            std.math.inf(f32),
    };

    // Clamp initial size to [minSize, maxSize] so that fitChild sees correct
    // values (e.g. image elements with fixed width and ratio height that
    // exceed their maxWidth/maxHeight constraints).
    result.ptr.size[0] = @min(@max(result.ptr.size[0], result.ptr.minSize[0]), result.ptr.maxSize[0]);
    result.ptr.size[1] = @min(@max(result.ptr.size[1], result.ptr.minSize[1]), result.ptr.maxSize[1]);

    self.frameMeta.?.nodeStack.append(self.frameMeta.?.arena, result.index) catch |err| {
        handleFrameError(err);
        return &endNoop;
    };

    pushScope(result.ptr.key) catch |err| {
        handleFrameError(err);
        return &endNoop;
    };

    inline for (Direction.array) |fitDirection| {
        if (result.ptr.style.getPreferredSize(fitDirection) == .fit) {
            result.ptr.setSize(fitDirection, result.ptr.fittingBase(fitDirection));
        }
        if (result.ptr.shouldFitMin(fitDirection)) {
            result.ptr.setMinSize(fitDirection, result.ptr.fittingBase(fitDirection));
        }
    }

    self.frameMeta.?.previousPushedNodeIndex = result.index;

    if (on(.mouseEnter)) {
        setCursor(style.cursor);
    }
    if (on(.mouseLeave)) {
        setCursor(baseStyle.cursor);
    }

    return &elementEnd;
}

pub fn printText(comptime fmt: []const u8, args: anytype) void {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);

    const arena = self.frameMeta.?.arena;

    component(.{})({
        text(std.fmt.allocPrint(arena, fmt, args) catch |err| blk: {
            handleFrameError(err);
            break :blk "N/A";
        });
    });
}

pub fn BreakLine() void {
    component(.{})({
        text("\n");
    });
}

pub noinline fn text(content: []const u8) void {
    if (content.len == 0) {
        return;
    }

    const self = getContext();
    std.debug.assert(self.frameMeta != null);

    if (self.frameMeta.?.err != null) return;

    const parentIndexOptional = self.frameMeta.?.nodeStack.getLastOrNull();

    const arena = self.frameMeta.?.arena;
    const result = self.nodeTree.putNode(self.allocator, parentIndexOptional) catch |err| {
        handleFrameError(err);
        return;
    };

    const parentOptional = if (parentIndexOptional) |parentIndex|
        self.nodeTree.at(parentIndex)
    else
        null;

    const baseStyle = if (parentOptional) |parent|
        BaseStyle.from(parent.style)
    else
        self.frameMeta.?.baseStyle;

    const style = (Style{
        .cursor = if (baseStyle.cursor == .default)
            .text
        else
            baseStyle.cursor,
        .xJustification = if (parentOptional) |parent| parent.style.xJustification else null,
        .yJustification = .start,
    }).completeWith(baseStyle);

    const unitsPerEm: f32 = @floatFromInt(style.font.unitsPerEm());
    const unitsPerEmVec2: Vec2 = @splat(unitsPerEm);
    const lineHeight = style.font.lineHeight() * style.lineHeight / unitsPerEm * style.fontSize;

    var effectiveContent = content;
    // converts \r\n, and \n\r, or just \r to \n for simplicity later on
    if (std.mem.containsAtLeast(u8, content, 1, "\r")) {
        var ownedContent = arena.alloc(u8, content.len) catch |err| {
            handleFrameError(err);
            return;
        };
        var i: usize = 0;
        while (i < content.len) {
            const character = content[i];
            if (character == '\r') {
                if (i + 1 < content.len and content[i + 1] == '\n') {
                    ownedContent[i] = '\n';
                    i += 1;
                } else {
                    ownedContent[i] = '\n';
                }
            } else if (character == '\n') {
                if (i + 1 < content.len and content[i + 1] == '\r') {
                    ownedContent[i] = '\n';
                    i += 1;
                } else {
                    ownedContent[i] = '\n';
                }
            } else {
                ownedContent[i] = character;
            }
            i += 1;
        }
        effectiveContent = ownedContent;
    }

    const shapedGlyphs = style.font.shape(effectiveContent) catch |err| {
        handleFrameError(err);
        return;
    };
    var layoutGlyphs = arena.alloc(LayoutGlyph, shapedGlyphs.len) catch |err| {
        handleFrameError(err);
        return;
    };
    errdefer arena.free(layoutGlyphs);
    var cursor: Vec2 = @splat(0.0);

    var minSize: Vec2 = .{ 0.0, lineHeight };
    var maxSize: Vec2 = .{ 0.0, lineHeight };

    var linebreakCount: usize = 0;
    var preBreakIndices: std.ArrayList(usize) = .empty;

    var wordAdvance: Vec2 = @splat(0.0);
    var glyphIndex: usize = 0;
    while (glyphIndex < shapedGlyphs.len) {
        defer glyphIndex += 1;
        const shapedGlyph = shapedGlyphs[glyphIndex];
        var advance = shapedGlyph.advance / unitsPerEmVec2 * @as(Vec2, @splat(style.fontSize));
        const offset = shapedGlyph.offset / unitsPerEmVec2 * @as(Vec2, @splat(style.fontSize));
        const isLinebreak = std.mem.startsWith(u8, &shapedGlyph.utf8.Encoded, "\n");
        if (isLinebreak) {
            advance[0] = -cursor[0];
            advance[1] += lineHeight;
            preBreakIndices.append(arena, glyphIndex - linebreakCount) catch |err| {
                handleFrameError(err);
                return;
            };
            linebreakCount += 1;
        } else {
            layoutGlyphs[glyphIndex - linebreakCount] = LayoutGlyph{
                .index = @intCast(shapedGlyph.index),
                .position = cursor + offset,

                .textBuf = shapedGlyph.utf8.Encoded,

                .advance = advance,
                .offset = offset,
            };
        }

        cursor += advance;
        maxSize[0] = @max(maxSize[0], cursor[0]);
        if (style.textWrapping == .word) {
            if (std.mem.startsWith(u8, &shapedGlyph.utf8.Encoded, " ") or isLinebreak) {
                wordAdvance = @splat(0.0);
                maxSize[1] += lineHeight;
            } else {
                wordAdvance += advance;
            }
            minSize[0] = @max(minSize[0], wordAdvance[0]);
        } else if (style.textWrapping == .character) {
            minSize[0] = @max(minSize[0], advance[0]);
            maxSize[1] += lineHeight;
        } else if (style.textWrapping == .none) {
            minSize[0] = @max(minSize[0], cursor[0]);
        }
    }
    minSize[1] = cursor[1] + lineHeight;

    const parentZ = if (parentOptional) |parent|
        parent.z
    else
        0;

    var hasher = std.hash.Wyhash.init(0);
    if (self.frameMeta.?.scopeStack.getLastOrNull()) |lastScopeKey| {
        hasher.update(std.mem.asBytes(&lastScopeKey));
    }
    hasher.update(std.mem.asBytes(&self.frameMeta.?.nodeStack.items.len));
    // We don't hash the text content here because text selection would be nice
    // to work even with text changing
    //
    // hasher.update(effectiveContent);
    hasher.update(std.mem.asBytes(&@returnAddress()));

    result.ptr.key = hasher.final();
    result.ptr.position = @splat(0.0);
    result.ptr.z = if (parentZ < std.math.maxInt(u16))
        parentZ + 1
    else
        parentZ;
    result.ptr.size = .{ maxSize[0], minSize[1] };
    result.ptr.minSize = minSize;
    result.ptr.maxSize = maxSize;
    result.ptr.glyphs = Glyphs{
        .slice = layoutGlyphs[0 .. layoutGlyphs.len - linebreakCount],
        .lineHeight = lineHeight,
        .preBreakIndices = preBreakIndices.items,
    };
    result.ptr.style = style;

    self.frameMeta.?.previousPushedNodeIndex = result.index;

    if (parentOptional) |parent| {
        parent.fitChild(result.ptr);
    }

    // Push self onto the parent stack so `on(.mouseOver)` resolves the
    // text node's own measurement, then pop. The text node itself is not
    // a scope and has no children, so this is purely for hit-testing.
    self.frameMeta.?.nodeStack.append(self.frameMeta.?.arena, result.index) catch |err| {
        handleFrameError(err);
        return;
    };
    defer _ = self.frameMeta.?.nodeStack.pop();

    pushScope(result.ptr.key) catch |err| {
        handleFrameError(err);
        return;
    };
    defer popScope();

    if (on(.mouseEnter)) {
        setCursor(style.cursor);
    }
    if (on(.mouseLeave)) {
        setCursor(baseStyle.cursor);
    }
}

/// Sets the OS-level mouse cursor for the current frame. Called per-frame
/// (typically from a `forbear.on(.mouseOver)` branch) — the last call wins,
/// so deeper/later mounted elements take precedence.
pub fn setCursor(cursor: Cursor) void {
    const self = getContext();
    if (self.window) |window| {
        window.setCursor(cursor, 0) catch |err| {
            std.log.err("Failed to set cursor: {}", .{err});
        };
    }
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

pub fn handleFrameError(err: anyerror) void {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);

    self.frameMeta.?.err = err;

    if (builtin.is_test) return;

    std.debug.print("There was an error during frame's UI mounting stage:\n", .{});
    std.debug.dumpCurrentStackTrace(.{ .first_address = @returnAddress() });
}

fn componentEnd(block: void) void {
    _ = block;
    const self = getContext();

    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) {
        return;
    }

    popScope();
}

pub inline fn hook() void {
    const self = getContext();

    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) {
        return;
    }
    var hasher = std.hash.Wyhash.init(0);
    if (self.frameMeta.?.scopeStack.getLastOrNull()) |lastScopeKey| {
        hasher.update(std.mem.asBytes(&lastScopeKey));
    }
    hasher.update(std.mem.asBytes(&@returnAddress()));
    pushScope(hasher.final()) catch |err| {
        handleFrameError(err);
        return;
    };
}

pub fn hookEnd() void {
    popScope();
}

pub const ComponentProps = struct {
    key: ?[]const u8 = null,
};

pub inline fn component(props: ComponentProps) *const fn (void) void {
    const self = getContext();

    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) {
        return &endNoop;
    }

    var hasher = std.hash.Wyhash.init(0);
    // the component keys wrapping this component and the amount of parents in
    // the node tree up to this point are what differentiate this instance from
    // other instances of the same component
    if (self.frameMeta.?.scopeStack.getLastOrNull()) |lastScopeKey| {
        hasher.update(std.mem.asBytes(&lastScopeKey));
    }
    hasher.update(std.mem.asBytes(&self.frameMeta.?.nodeStack.items.len));
    if (props.key) |key| {
        hasher.update(key);
    } else {
        hasher.update(std.mem.asBytes(&@returnAddress()));
    }

    const componentKey = hasher.final();
    pushScope(componentKey) catch |err| {
        handleFrameError(err);
        return endNoop;
    };

    return &componentEnd;
}

pub fn componentChildrenSlot() void {
    const self = getContext();

    std.debug.assert(self.frameMeta != null);
    const fm = &self.frameMeta.?;
    if (fm.err != null) return;

    const parentIndex = fm.nodeStack.getLastOrNull() orelse {
        handleFrameError(error.NoParentForSlot);
        return;
    };

    const savedStack = fm.arena.dupe(usize, fm.nodeStack.items) catch |err| {
        handleFrameError(err);
        return;
    };

    fm.componentChildrenSlotStates.append(fm.arena, .{
        .savedSlotParentStack = savedStack,
        .savedPreEndParentStack = &.{},
        .slotPredecessor = self.nodeTree.at(parentIndex).lastChild,
        .afterChainStart = null,
        .afterChainEnd = null,
        .parentIndex = parentIndex,
    }) catch |err| {
        handleFrameError(err);
    };
}

fn componentChildrenSlotEndFn(block: void) void {
    _ = block;
    const self = getContext();

    std.debug.assert(self.frameMeta != null);
    const fm = &self.frameMeta.?;
    if (fm.err != null) return;

    const slotState = fm.componentChildrenSlotStates.pop() orelse return;
    const parent = self.nodeTree.at(slotState.parentIndex);

    // Reattach the after-chain
    if (slotState.afterChainStart) |afterStart| {
        const currentLast = parent.lastChild;
        if (currentLast) |last| {
            self.nodeTree.at(last).nextSibling = afterStart;
            self.nodeTree.at(afterStart).previousSibling = last;
        } else {
            parent.firstChild = afterStart;
            self.nodeTree.at(afterStart).previousSibling = null;
        }
        parent.lastChild = slotState.afterChainEnd;
    }

    // Restore parent stack to pre-slotEnd state
    fm.nodeStack.clearRetainingCapacity();
    fm.nodeStack.appendSlice(fm.arena, slotState.savedPreEndParentStack) catch |err| {
        handleFrameError(err);
    };
}

pub fn componentChildrenSlotEnd() *const fn (void) void {
    const self = getContext();

    std.debug.assert(self.frameMeta != null);
    const fm = &self.frameMeta.?;
    if (fm.err != null) return &endNoop;

    const states = &fm.componentChildrenSlotStates;
    if (states.items.len == 0) {
        handleFrameError(error.NoMatchingSlotBegin);
        return &endNoop;
    }
    const slotState = &states.items[states.items.len - 1];
    const parent = self.nodeTree.at(slotState.parentIndex);

    // Determine after-chain (nodes added after slot by the component body)
    const afterStart = if (slotState.slotPredecessor) |pred|
        self.nodeTree.at(pred).nextSibling
    else
        parent.firstChild;

    if (afterStart) |start| {
        // Detach the after-chain from the parent
        slotState.afterChainStart = start;
        slotState.afterChainEnd = parent.lastChild;

        if (slotState.slotPredecessor) |pred| {
            self.nodeTree.at(pred).nextSibling = null;
            parent.lastChild = pred;
        } else {
            parent.firstChild = null;
            parent.lastChild = null;
        }
        self.nodeTree.at(start).previousSibling = null;
    }

    // Save current parent stack, then restore to slot-time stack
    slotState.savedPreEndParentStack = fm.arena.dupe(usize, fm.nodeStack.items) catch |err| {
        handleFrameError(err);
        return &endNoop;
    };
    fm.nodeStack.clearRetainingCapacity();
    fm.nodeStack.appendSlice(fm.arena, slotState.savedSlotParentStack) catch |err| {
        handleFrameError(err);
        return &endNoop;
    };

    return &componentChildrenSlotEndFn;
}

fn isMouseInsideMeasurement(self: *@This(), measurement: Node.Measurement) bool {
    const pos = measurement.position;
    const size = measurement.size;
    return self.mousePosition[0] >= pos[0] and
        self.mousePosition[1] >= pos[1] and
        self.mousePosition[0] <= pos[0] + size[0] and
        self.mousePosition[1] <= pos[1] + size[1];
}

pub fn OnResult(comptime eventTag: Event) type {
    return if (eventTag == .scroll or eventTag == .mouseMove) ?Vec2 else bool;
}

/// Inline hit test against previous-frame measurement. No event queue —
/// every caller sees the same raw input state each frame.
pub fn on(comptime eventTag: Event) OnResult(eventTag) {
    hook();
    defer hookEnd();
    const self = getContext();
    std.debug.assert(self.frameMeta != null);

    if (comptime eventTag == .click) {
        // This is not exactly the same as mouseUp, since mouseUp doesn't
        // require that the mouse was down inside of the element before, while
        // click does.
        const wasMouseDown = useState(bool, false);
        if (on(.mouseDown)) {
            wasMouseDown.* = true;
        }
        if (on(.mouseLeave)) {
            wasMouseDown.* = false;
        }
        if (on(.mouseUp)) {
            if (wasMouseDown.*) {
                wasMouseDown.* = false;
                return true;
            }
        }
        return false;
    }

    // Reserve hook slots before the measurement guard so that slot indices
    // are stable across frames — on the first frame there's no measurement,
    // and a conditional useState would shift every later slot once the
    // measurement starts existing.
    const slot: ?*bool = switch (eventTag) {
        .mouseEnter, .mouseLeave, .mouseDown, .mouseUp => useState(bool, false),
        .scroll, .mouseMove => null,
        .click => unreachable,
    };
    const lastMousePositionSlot: ?*Vec2 = if (eventTag == .mouseMove)
        useState(Vec2, self.mousePosition)
    else
        null;

    const measurement = useNodeMeasurement() orelse {
        if (comptime eventTag == .scroll or eventTag == .mouseMove) return null;
        return false;
    };

    const inside = self.isMouseInsideMeasurement(measurement);

    switch (eventTag) {
        .mouseEnter, .mouseLeave => {
            const wasMouseInside = slot.?;
            defer wasMouseInside.* = inside;

            switch (eventTag) {
                .mouseEnter => return inside and !wasMouseInside.*,
                .mouseLeave => return !inside and wasMouseInside.*,
                else => unreachable,
            }
            unreachable;
        },
        .mouseDown => {
            const wasPressedLastFrame = slot.?;
            defer wasPressedLastFrame.* = self.mouseButtonPressed;
            return self.mouseButtonPressed and !wasPressedLastFrame.* and inside;
        },
        .mouseUp => {
            const wasPressedLastFrame = slot.?;
            defer wasPressedLastFrame.* = self.mouseButtonPressed;
            return !self.mouseButtonPressed and wasPressedLastFrame.* and inside;
        },
        .click => unreachable,
        .scroll => {
            if (!inside) return null;
            if (self.scrollDelta[0] != 0.0 or self.scrollDelta[1] != 0.0)
                return self.scrollDelta;
            return null;
        },
        .mouseMove => {
            const lastMousePosition = lastMousePositionSlot.?;
            defer lastMousePosition.* = self.mousePosition;
            if (!inside) return null;
            const delta = self.mousePosition - lastMousePosition.*;
            if (delta[0] != 0.0 or delta[1] != 0.0) return delta;
            return null;
        },
    }
}

pub fn update() !void {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err) |err| return err;

    const viewportSize = self.frameMeta.?.viewportSize;

    self.viewportSize = viewportSize;

    const maxCappedDeltaTime: f64 = 1.0 / 30.0;
    const timestamp = timestampSeconds(self.io);
    const rawDelta = timestamp - (self.lastUpdateTime orelse self.startTime);
    self.deltaTime = rawDelta;
    self.cappedDeltaTime = @min(rawDelta, maxCappedDeltaTime);
    self.lastUpdateTime = timestamp;
}

pub fn isMouseButtonPressed() bool {
    const self = getContext();
    return self.mouseButtonPressed;
}

/// Returns some layouting values of the current node from the last frame
pub fn useNodeMeasurement() ?Node.Measurement {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);
    const parentNodeIndex = self.frameMeta.?.nodeStack.getLastOrNull() orelse return null;
    const parentNode = self.nodeTree.at(parentNodeIndex);
    const entry = self.previousFrameNodeMeasurements.getOrPut(parentNode.key) catch |err| {
        std.log.err("Failed to get or put previous frame node measurement: {}", .{err});
        handleFrameError(err);
        return null;
    };
    if (!entry.found_existing) {
        entry.value_ptr.* = .{
            .index = parentNodeIndex,
            .done = false,
            .size = parentNode.size,
            .position = parentNode.position,
            .maxSize = parentNode.maxSize,
            .minSize = parentNode.minSize,
            .contentSize = parentNode.contentSize,
            .z = parentNode.z,
        };
    } else {
        // Index can shift between frames as the tree is rebuilt, so refresh it.
        entry.value_ptr.index = parentNodeIndex;
    }
    if (entry.value_ptr.done == false) {
        return null;
    } else {
        return entry.value_ptr.*;
    }
}

fn timestampSeconds(io: std.Io) f64 {
    const ts = std.Io.Clock.awake.now(io);
    return @as(f64, @floatFromInt(ts.toNanoseconds())) / std.time.ns_per_s;
}

pub fn setWindowHandlers(window: *Window) void {
    const self = getContext();
    self.window = window;

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
                    100.0 * @as(f32, @floatFromInt(std.math.sign(nativeOffset)));

                // Browser-like behavior: Shift + vertical scroll = horizontal scroll
                const shiftAccordingAxis = if (wnd.isHoldingShift() and axis == .vertical)
                    .horizontal
                else if (wnd.isHoldingShift() and axis == .horizontal)
                    .vertical
                else
                    axis;

                switch (shiftAccordingAxis) {
                    .horizontal => {
                        ctx.scrollDeltaAccumulator[0] += offset;
                    },
                    .vertical => {
                        ctx.scrollDeltaAccumulator[1] += offset;
                    },
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
    window.handlers.pointerButton = .{
        .function = &(struct {
            fn handler(_: *Window, _: u32, _: u32, button: u32, state: u32, data: *anyopaque) void {
                const ctx: *Context = @ptrCast(@alignCast(data));
                // 272 (0x110) = BTN_LEFT on Linux/Wayland; state 1 = pressed, 0 = released
                if (button == 272) {
                    if (state == 1) {
                        ctx.mouseButtonPressed = true;
                    } else {
                        ctx.mouseButtonPressed = false;
                    }
                }
            }
        }).handler,
        .data = @ptrCast(@alignCast(self)),
    };
}

pub fn deinit() void {
    const self = getContext();

    self.previousFrameNodeMeasurements.deinit();

    for (self.scopes.items) |scope| {
        scope.arenaAllocator.deinit();
    }
    self.states.deinit();
    self.scopes.deinit(self.allocator);

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

    self.nodeTree.deinit(self.allocator);

    context = null;
}

test {
    _ = std.testing.refAllDecls(@import("tests.zig"));
}
