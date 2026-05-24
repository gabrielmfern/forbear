const std = @import("std");
const builtin = @import("builtin");

pub const c = @import("c");

pub const Cursor = @import("window.zig").Cursor;
pub const Font = @import("font.zig");
const forbearBuiltin = @import("builtin.zig");
pub const ProfilingMetrics = forbearBuiltin.ProfilingMetrics;
pub const useScrolling = forbearBuiltin.useScrolling;
pub const ScrollBar = forbearBuiltin.ScrollBar;
pub const FocusContext = forbearBuiltin.FocusContext;
pub const Focus = forbearBuiltin.Focus;
pub const FocusConsumes = forbearBuiltin.FocusConsumes;
pub const EventPayload = forbearBuiltin.EventPayload;
pub const Graphics = @import("graphics.zig");
const ImageType = @import("graphics.zig").Image;
pub const Keys = @import("window.zig").Keys;
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
pub const TextStyle = nodeImport.TextStyle;
pub const CompleteTextStyle = nodeImport.CompleteTextStyle;
pub const Element = nodeImport.Element;
pub const GradientStop = nodeImport.GradientStop;
pub const Window = @import("window.zig").Window;

pub var traceWriter: ?*std.Io.Writer = null;
pub fn setTraceWriter(writer: *std.Io.Writer) void {
    traceWriter = writer;
}
const Vec2 = @Vector(2, f32);
const Vec3 = @Vector(3, f32);
const Vec4 = @Vector(4, f32);

const Forbear = @This();
var forbear: ?@This() = null;
pub fn getForbear() *@This() {
    return &forbear.?;
}

const Scope = struct {
    arenaAllocator: std.heap.ArenaAllocator,
    lastFrame: u32,
    /// Per-scope state map. Key is the `@returnAddress()` of the `useState`
    /// call site (unique per source location); value is the live state
    /// entry. The map's backing storage and its `*T` values both live in
    /// `arenaAllocator`, so nothing extra needs freeing when the scope
    /// dies — `arenaAllocator.deinit()` releases everything in one shot.
    states: std.HashMapUnmanaged(
        usize,
        struct { ptr: *anyopaque, lastFrame: u32 },
        ReturnAddressKeyContext,
        std.hash_map.default_max_load_percentage,
    ) = .empty,
};

/// SplitMix64 finalizer. Mixes both high and low bits well, so
/// downstream hashmap slot indexing (low bits) and fingerprinting
/// (high bits) both behave even when inputs are clustered (e.g. code
/// addresses from `@returnAddress()` or sequential `nodeStack` depths).
/// Three multiplies + a few shifts — much cheaper than `Wyhash.init +
/// update + final` that this replaces in element / component / text /
/// hook key derivation.
inline fn mixU64(state: u64, value: u64) u64 {
    var z = state ^ value;
    z = (z ^ (z >> 30)) *% 0xbf58476d1ce4e5b9;
    z = (z ^ (z >> 27)) *% 0x94d049bb133111eb;
    z = z ^ (z >> 31);
    return z;
}

const NoopKeyConext = struct {
    pub fn hash(_: NoopKeyConext, k: u64) u64 {
        return k;
    }
    pub fn eql(_: NoopKeyConext, a: u64, b: u64) bool {
        return a == b;
    }
};

const ReturnAddressKeyContext = struct {
    pub fn hash(_: ReturnAddressKeyContext, k: usize) u64 {
        var z: u64 = @as(u64, k);
        z = (z ^ (z >> 30)) *% 0xbf58476d1ce4e5b9;
        z = (z ^ (z >> 27)) *% 0x94d049bb133111eb;
        z = z ^ (z >> 31);
        return z;
    }
    pub fn eql(_: ReturnAddressKeyContext, a: usize, b: usize) bool {
        return a == b;
    }
};

const ContextStackEntry = struct { valueKey: u64, contextKey: u64 };

const ComponentChildrenSlotState = struct {
    savedSlotParentStack: []usize,
    savedPreEndParentStack: []usize,
    savedSlotScopeStack: []u64,
    savedPreEndScopeStack: []u64,
    savedSlotContextStack: []ContextStackEntry,
    savedPreEndContextStack: []ContextStackEntry,
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
    /// Keys that transitioned to "down" since the previous frame's sample.
    /// Returned as a `Keys` set: `if (forbear.on(.keyDown).tab) ...`.
    /// Each press fires exactly once — held keys do *not* re-appear here.
    keyDown,
    /// Keys that transitioned to "up" since the previous frame's sample.
    keyUp,
};

const TextRun = struct {
    content: []const u8,
    style: CompleteTextStyle,
};

const TextBuilder = struct {
    runs: std.ArrayList(TextRun) = .empty,
    styleStack: std.ArrayList(CompleteTextStyle) = .empty,
    base: CompleteTextStyle,
};

pub const FrameMeta = struct {
    arena: std.mem.Allocator,

    viewportSize: Vec2,
    baseStyle: BaseStyle,

    err: ?anyerror = null,

    previousPushedNodeIndex: ?usize = null,
    componentChildrenSlotStates: std.ArrayList(ComponentChildrenSlotState) = .empty,
    /// Non-null only between `composeText` and its end function. `composeText`
    /// does not nest, so a single slot suffices.
    textBuilder: ?TextBuilder = null,
};

// Hot fields kept at the front of the struct so they sit at low,
// stable offsets and don't get pushed across cache lines as the
// trailing fields evolve. `frameMeta` and `nodeTree` are read on every
// `forbear.layout()` pass and every `element` / `component` / `text` /
// `useState` call; `scopes`, `scopeStack`, and `frameCounter` are read
// on every `useState` and `pushScope`.
frameMeta: ?FrameMeta,
nodeTree: NodeTree,
scopes: std.HashMapUnmanaged(
    u64,
    Scope,
    NoopKeyConext,
    std.hash_map.default_max_load_percentage,
) = .empty,
contextValues: std.HashMapUnmanaged(
    u64,
    struct {
        contents: *anyopaque,
        arenaAllocator: std.heap.ArenaAllocator,
        lastFrame: u32,
    },
    NoopKeyConext,
    std.hash_map.default_max_load_percentage,
) = .empty,
contextStack: std.ArrayList(ContextStackEntry) = .empty,
scopeStack: std.ArrayList(u64) = .empty,
nodeStack: std.ArrayList(usize) = .empty,
/// Monotonically incremented at the start of every `frame()`. Used as
/// the "this scope/state was touched this frame" marker on each Scope
/// and StateEntry, in lieu of an auxiliary sorted touched-keys list.
/// A `u32` gives ~136 years of 60fps frames before wrapping; on wrap
/// any entry whose `lastFrame` happens to coincide will be retained
/// for one extra frame, which is harmless.
frameCounter: u32 = 0,

arena: std.heap.ArenaAllocator,
allocator: std.mem.Allocator,
io: std.Io,

mousePosition: Vec2,
mouseButtonPressed: bool,
/// Accumulated wheel/trackpad delta from window events. Snapshotted
/// into `scrollDelta` at frame start, then reset.
scrollDeltaAccumulator: Vec2,
/// Stable snapshot of scroll delta for the current frame.
scrollDelta: Vec2,
/// Currently-held keys, sampled at frame start. Read via `keysHeld()` or
/// `isKeyDown(key)`. Updated inside `frame()` by polling the window.
keysHeldSnapshot: Keys = .{},
/// Keys that transitioned to down between the previous frame and this one.
/// Returned by `on(.keyDown)`.
keysPressedThisFrame: Keys = .{},
/// Keys that transitioned to up between the previous frame and this one.
keysReleasedThisFrame: Keys = .{},
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

images: std.StringHashMap(ImageType),
fonts: std.StringHashMap(Font),

pub fn init(allocator: std.mem.Allocator, io: std.Io, renderer: *Graphics.Renderer) !void {
    if (forbear != null) {
        return error.AlreadyInitialized;
    }

    forbear = @This(){
        .arena = std.heap.ArenaAllocator.init(allocator),
        .allocator = undefined,
        .io = io,

        .mousePosition = @splat(0.0),
        .mouseButtonPressed = false,
        .scrollDeltaAccumulator = @splat(0.0),
        .scrollDelta = @splat(0.0),
        .keysHeldSnapshot = .{},
        .keysPressedThisFrame = .{},
        .keysReleasedThisFrame = .{},
        .previousFrameNodeMeasurements = undefined,

        .renderer = renderer,
        .window = null,

        .startTime = timestampSeconds(io),
        .deltaTime = null,
        .cappedDeltaTime = null,
        .lastUpdateTime = null,
        .viewportSize = @splat(0.0),

        .scopes = .empty,
        .frameCounter = 0,

        .scopeStack = .empty,
        .nodeStack = .empty,

        .frameMeta = null,
        .nodeTree = .empty,

        .images = undefined,
        .fonts = undefined,
    };
    forbear.?.allocator = forbear.?.arena.allocator();
    forbear.?.previousFrameNodeMeasurements = std.AutoHashMap(
        u64,
        Node.Measurement,
    ).init(forbear.?.allocator);
    forbear.?.images = std.StringHashMap(ImageType).init(forbear.?.allocator);
    forbear.?.fonts = std.StringHashMap(Font).init(forbear.?.allocator);
}

/// Registers a font from the given embedded byte contents. The font is associated with
/// `uniqueIdentifier` and only deinits when the forbear context is deinited.
pub fn registerFont(uniqueIdentifier: []const u8, comptime contents: []const u8) !void {
    const self = getForbear();
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
    const self = getForbear();
    return self.fonts.getPtr(uniqueIdentifier) orelse {
        std.log.err("Could not find font by the unique identifier {s}", .{uniqueIdentifier});
        return error.FontNotFound;
    };
}

/// Embeds an image from the given path. Only deinits when the forbear context is deinited.
pub fn registerImage(uniqueIdentifier: []const u8, comptime contents: []const u8, format: Graphics.Image.Format) !void {
    const self = getForbear();
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
    const self = getForbear();
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

    const self = getForbear();
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

    const self = getForbear();
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
    const self = getForbear();
    return self.mousePosition;
}

pub fn useViewportSize() Vec2 {
    const self = getForbear();
    return self.viewportSize;
}

pub fn useDeltaTime() f64 {
    const self = getForbear();
    return self.deltaTime orelse 0.0;
}

pub fn useLastUpdateTime() f64 {
    const self = getForbear();
    return self.lastUpdateTime orelse self.startTime;
}

pub fn getParentNode() ?*Node {
    const self = getForbear();
    std.debug.assert(self.frameMeta != null);
    const index = self.nodeStack.getLastOrNull() orelse return null;
    return self.nodeTree.at(index);
}

pub fn getPreviousNode() ?*Node {
    const self = getForbear();
    std.debug.assert(self.frameMeta != null);
    const index = self.frameMeta.?.previousPushedNodeIndex orelse return null;
    return self.nodeTree.at(index);
}

pub fn useArena() std.mem.Allocator {
    const self = getForbear();
    std.debug.assert(self.frameMeta != null);
    return self.frameMeta.?.arena;
}

/// Returns the arena allocator owned by the current scope (the topmost
/// component / element / hook scope on the stack). Allocations live as
/// long as the scope keeps re-rendering; the arena is released wholesale
/// once the scope is missed for a frame.
///
/// Use this for state that must outlive the frame but die with the scope
/// — context value backing storage, long-lived `ArrayList`s owned by a
/// hook, anything you'd otherwise stash in a `useState`-allocated pointer
/// and never free by hand.
///
/// Can, conceptually, completely replace useState and be more performant with
/// the same exact result and more clearer design.
pub fn useScopeArena() std.mem.Allocator {
    const self = getForbear();
    const scopeKey = self.scopeStack.getLastOrNull() orelse {
        if (!builtin.is_test) {
            std.log.err(
                "useScopeArena called outside of a component / element / hook scope",
                .{},
            );
        }
        @panic("Invalid hook usage");
    };
    const scope = self.scopes.getPtr(scopeKey) orelse unreachable;
    return scope.arenaAllocator.allocator();
}

pub fn useIo() std.Io {
    const self = getForbear();
    return self.io;
}

fn pushScope(key: u64) error{OutOfMemory}!void {
    const self = getForbear();
    const result = try self.scopes.getOrPut(self.allocator, key);
    if (result.found_existing) {
        result.value_ptr.lastFrame = self.frameCounter;
    } else {
        result.value_ptr.* = Scope{
            .arenaAllocator = std.heap.ArenaAllocator.init(self.allocator),
            .lastFrame = self.frameCounter,
        };
    }
    try self.scopeStack.append(self.allocator, key);
}

fn popScope() void {
    const self = getForbear();
    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) {
        return;
    }
    _ = self.scopeStack.pop();
}

pub noinline fn useState(comptime T: type, initialValue: T) *T {
    const self = getForbear();
    std.debug.assert(self.frameMeta != null);

    if (self.frameMeta.?.err != null) {
        // Return a pointer to valid (but dummy) storage to avoid crashes
        // when error handling continues to evaluate the rest of the frame
        const Static = struct {
            var dummy: T = std.mem.zeroes(T);
        };
        return &Static.dummy;
    }

    if (self.scopeStack.getLastOrNull()) |scopeKey| {
        const scope: *Scope = self.scopes.getPtr(scopeKey) orelse unreachable;

        const arena = scope.arenaAllocator.allocator();
        const state = scope.states.getOrPut(arena, @returnAddress()) catch |err| {
            std.log.err("Failed to track that state was touched: {}", .{err});
            @panic("Out of memory when tracking touched state for useState");
        };
        if (!state.found_existing) {
            const value = arena.create(T) catch |err| {
                std.log.err("Failed to allocate state for useState: {}", .{err});
                @panic("Out of memory when allocating state for useState");
            };
            value.* = initialValue;
            state.value_ptr.* = .{ .ptr = @ptrCast(@alignCast(value)), .lastFrame = self.frameCounter };
        } else {
            state.value_ptr.lastFrame = self.frameCounter;
        }

        return @ptrCast(@alignCast(state.value_ptr.ptr));
    } else {
        if (!builtin.is_test) {
            std.log.err("You might be calling a hook (useState) outside of a component or element scope, and forbear cannot track things outside of one.", .{});
        }
        @panic("Invalid hook usage");
    }
}

fn noopEnd(block: void) void {
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
    const self = getForbear();

    std.debug.assert(self.frameMeta != null);
    const frameMeta = self.frameMeta.?;
    defer self.frameMeta = null;
    if (frameMeta.err) |err| return err;

    // Reap unmounted scopes (and prune stale states from the survivors)
    // in a single pass. Collect-then-remove so we don't mutate either
    // map mid-iteration. Scope keys are u64; state keys are usize.
    var staleScopeKeys: std.ArrayList(u64) = .empty;
    defer staleScopeKeys.deinit(frameMeta.arena);
    var staleStateKeys: std.ArrayList(usize) = .empty;
    defer staleStateKeys.deinit(frameMeta.arena);

    var scopeEntries = self.scopes.iterator();
    while (scopeEntries.next()) |scopeEntry| {
        const scope = scopeEntry.value_ptr;
        if (scope.lastFrame != self.frameCounter) {
            try staleScopeKeys.append(frameMeta.arena, scopeEntry.key_ptr.*);
            continue;
        }
        // Surviving scope: drop state entries whose call site wasn't
        // visited this frame. The underlying `*T` storage stays in the
        // scope's arena until the whole scope is unmounted — same
        // lifetime model as before.
        staleStateKeys.clearRetainingCapacity();
        var stateEntries = scope.states.iterator();
        while (stateEntries.next()) |stateEntry| {
            if (stateEntry.value_ptr.lastFrame != self.frameCounter) {
                try staleStateKeys.append(frameMeta.arena, stateEntry.key_ptr.*);
            }
        }
        for (staleStateKeys.items) |staleKey| {
            _ = scope.states.remove(staleKey);
        }
    }
    for (staleScopeKeys.items) |staleKey| {
        if (self.scopes.getPtr(staleKey)) |scope| {
            scope.arenaAllocator.deinit();
        }
        _ = self.scopes.remove(staleKey);
    }

    var staleContextValueKeys: std.ArrayList(u64) = .empty;
    defer staleContextValueKeys.deinit(frameMeta.arena);
    var contextEntries = self.contextValues.iterator();
    while (contextEntries.next()) |contextEntry| {
        if (contextEntry.value_ptr.lastFrame != self.frameCounter) {
            try staleContextValueKeys.append(frameMeta.arena, contextEntry.key_ptr.*);
        }
    }
    for (staleContextValueKeys.items) |staleKey| {
        if (self.contextValues.getPtr(staleKey)) |valueEntry| {
            valueEntry.arenaAllocator.deinit();
        }
        _ = self.contextValues.remove(staleKey);
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
    self.nodeStack.clearRetainingCapacity();
    self.scopeStack.clearRetainingCapacity();
}

pub fn frame(meta: FrameMeta) *const fn (void) anyerror!void {
    const self = getForbear();

    self.scrollDelta = self.scrollDeltaAccumulator;
    self.scrollDeltaAccumulator = @splat(0.0);

    self.snapshotKeyboard();

    self.frameCounter +%= 1;
    self.frameMeta = meta;
    return &frameEnd;
}

/// Pull the window's keyboard snapshot for this frame: the held set + the
/// per-frame edge sets. All three are `Keys` values (packed u128) — no
/// allocations, no iteration; consumers read individual keys as fields.
fn snapshotKeyboard(self: *Forbear) void {
    self.keysHeldSnapshot = .{};
    self.keysPressedThisFrame = .{};
    self.keysReleasedThisFrame = .{};

    const window = self.window orelse return;
    const snap = window.snapshotKeyboard();
    self.keysHeldSnapshot = snap.held;
    self.keysPressedThisFrame = snap.pressed;
    self.keysReleasedThisFrame = snap.released;
}

/// TODO: share the github of the person I got the trick of using an end
/// function as return value
fn elementEnd(block: void) void {
    _ = block;
    const self = getForbear();
    std.debug.assert(self.frameMeta != null);
    std.debug.assert(self.nodeStack.items.len > 0);

    popScope();

    self.frameMeta.?.previousPushedNodeIndex = self.nodeStack.pop();

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
    const self = getForbear();

    std.debug.assert(self.frameMeta != null);

    if (self.frameMeta.?.err != null) return &noopEnd;

    if (self.frameMeta.?.textBuilder != null) {
        std.log.err("forbear.element, or forbear.text cannot be called from inside forbear.composeText. You can only use forbear.textStyle and forbear.write.", .{});
        handleFrameError(error.ElementInsideTextCompose);
        return &noopEnd;
    }

    const parentIndexOptional = self.nodeStack.getLastOrNull();

    const result = self.nodeTree.putNode(self.allocator, parentIndexOptional) catch |err| {
        handleFrameError(err);
        return &noopEnd;
    };

    const parentOptional = if (parentIndexOptional) |parentIndex|
        self.nodeTree.at(parentIndex)
    else
        null;

    const baseStyle = if (parentOptional) |parent|
        BaseStyle.from(parent.style)
    else
        self.frameMeta.?.baseStyle;
    props.style.completeWith(baseStyle, &result.ptr.style);

    const parentZ = if (parentOptional) |parent|
        parent.z
    else
        0;

    var k: u64 = 0;
    if (self.scopeStack.getLastOrNull()) |lastScopeKey| {
        k = mixU64(k, lastScopeKey);
    }
    k = mixU64(k, @as(u64, self.nodeStack.items.len));
    if (props.key) |key| {
        k = mixU64(k, std.hash.Wyhash.hash(0, key));
    } else {
        k = mixU64(k, @returnAddress());
    }

    result.ptr.key = k;
    result.ptr.z = if (props.style.zIndex) |zIndex|
        zIndex
    else if (parentZ < std.math.maxInt(u16))
        parentZ + 1
    else
        parentZ;
    result.ptr.position = switch (result.ptr.style.placement) {
        .fixed => |v| v,
        .absolute => |v| v,
        .relative => |v| v,
        .flow => @splat(0.0),
    };
    result.ptr.size = .{
        switch (result.ptr.style.width) {
            .fixed => |width| width,
            .ratio => |ratio| if (result.ptr.style.height == .fixed)
                result.ptr.style.height.fixed * ratio
            else
                0.0,
            .fit, .grow => 0.0,
        },
        switch (result.ptr.style.height) {
            .fixed => |height| height,
            .ratio => |ratio| if (result.ptr.style.width == .fixed)
                result.ptr.style.width.fixed * ratio
            else
                0.0,
            .fit, .grow => 0.0,
        },
    };
    result.ptr.minSize = .{
        if (result.ptr.style.minWidth) |minWidth|
            minWidth
        else if (result.ptr.style.width == .fixed)
            result.ptr.style.width.fixed
        else
            0.0,
        if (result.ptr.style.minHeight) |minHeight|
            minHeight
        else if (result.ptr.style.height == .fixed)
            result.ptr.style.height.fixed
        else
            0.0,
    };
    result.ptr.maxSize = .{
        if (result.ptr.style.maxWidth) |maxWidth|
            maxWidth
        else if (result.ptr.style.width == .fixed)
            result.ptr.style.width.fixed
        else
            std.math.inf(f32),
        if (result.ptr.style.maxHeight) |maxHeight|
            maxHeight
        else if (result.ptr.style.height == .fixed)
            result.ptr.style.height.fixed
        else
            std.math.inf(f32),
    };

    // Clamp initial size to [minSize, maxSize] so that fitChild sees correct
    // values (e.g. image elements with fixed width and ratio height that
    // exceed their maxWidth/maxHeight constraints).
    result.ptr.size[0] = @min(@max(result.ptr.size[0], result.ptr.minSize[0]), result.ptr.maxSize[0]);
    result.ptr.size[1] = @min(@max(result.ptr.size[1], result.ptr.minSize[1]), result.ptr.maxSize[1]);

    self.nodeStack.append(self.allocator, result.index) catch |err| {
        handleFrameError(err);
        return &noopEnd;
    };

    pushScope(result.ptr.key) catch |err| {
        handleFrameError(err);
        return &noopEnd;
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

    // TODO: this does not seem to work with when I have two elements one
    // beside the other, both have the cursor setup to something other than the
    // one in the baseStyle here, then, I hover one of them, and move my mouse
    // over to the other one. If the element I hovered is later on the tree,
    // its mouseLeave will happen at the end, meaning the cursor will be set to
    // the baseStyle cursor instead of the former element's cursor.
    if (on(.mouseEnter)) {
        setCursor(result.ptr.style.cursor);
    }
    if (on(.mouseLeave)) {
        setCursor(baseStyle.cursor);
    }

    return &elementEnd;
}

pub fn printText(comptime fmt: []const u8, args: anytype) void {
    const self = getForbear();
    std.debug.assert(self.frameMeta != null);

    const arena = self.frameMeta.?.arena;

    component(.{})({
        text(std.fmt.allocPrint(arena, fmt, args) catch |err| blk: {
            handleFrameError(err);
            break :blk "N/A";
        });
    });
}

pub inline fn createContext(
    /// Generally just an `opaque`
    comptime Tag: type,
    comptime T: type,
) type {
    var hasher = std.hash.Wyhash.init(0);
    hasher.update(@typeName(Tag));
    hasher.update(@typeName(T));
    const contextKey = hasher.final();

    return struct {
        pub const key: u64 = contextKey;
        pub const ValueType = T;

        pub noinline fn Provider(initialValue: T) *const fn (void) void {
            const self = getForbear();

            var valueKey: u64 = 0;
            if (self.scopeStack.getLastOrNull()) |lastScopeKey| {
                valueKey = mixU64(valueKey, lastScopeKey);
            }
            valueKey = mixU64(valueKey, @as(u64, self.nodeStack.items.len));
            valueKey = mixU64(valueKey, contextKey);
            valueKey = mixU64(valueKey, @as(u64, @returnAddress()));

            if (self.contextValues.getPtr(valueKey)) |existing| {
                existing.lastFrame = self.frameCounter;
            } else {
                var arena = std.heap.ArenaAllocator.init(self.allocator);
                const value = arena.allocator().create(T) catch |err| {
                    handleFrameError(err);
                    return &noopEnd;
                };
                value.* = initialValue;
                self.contextValues.put(self.allocator, valueKey, .{
                    .arenaAllocator = arena,
                    .contents = @ptrCast(@alignCast(value)),
                    .lastFrame = self.frameCounter,
                }) catch |err| {
                    handleFrameError(err);
                    return &noopEnd;
                };
            }
            self.contextStack.append(self.allocator, .{
                .contextKey = contextKey,
                .valueKey = valueKey,
            }) catch |err| {
                handleFrameError(err);
                return &noopEnd;
            };

            return &contextEnd;
        }
    };
}

fn contextEnd(block: void) void {
    _ = block;
    const self = getForbear();
    _ = self.contextStack.pop();
}

pub fn useContext(
    comptime Context: type,
) ?*Context.ValueType {
    const self = getForbear();
    var i = self.contextStack.items.len;
    while (i > 0) {
        i -= 1;
        const contextEntry = self.contextStack.items[i];
        if (contextEntry.contextKey == Context.key) {
            const valueEntry = self.contextValues.getPtr(contextEntry.valueKey) orelse unreachable;
            return @ptrCast(@alignCast(valueEntry.contents));
        }
    }
    return null;
}

pub fn BreakLine() void {
    component(.{})({
        text("\n");
    });
}

pub noinline fn composeText(style: TextStyle) *const fn (void) void {
    const self = getForbear();
    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) return &noopEnd;

    if (self.frameMeta.?.textBuilder != null) {
        std.log.err("Found multiple instances of composeText being used. You only need one, and then you can nest forbear.textStyle alongside forbear.text.", .{});
        handleFrameError(error.NestedComposeText);
        return &noopEnd;
    }

    const parentIndexOptional = self.nodeStack.getLastOrNull();
    const baseStyle = if (parentIndexOptional) |parentIndex|
        BaseStyle.from(self.nodeTree.at(parentIndex).style)
    else
        self.frameMeta.?.baseStyle;
    const base = style.complete(CompleteTextStyle.from(baseStyle));

    const arena = self.frameMeta.?.arena;
    var builder = TextBuilder{ .base = base };
    builder.styleStack.append(arena, base) catch |err| {
        handleFrameError(err);
        return &noopEnd;
    };
    self.frameMeta.?.textBuilder = builder;

    return &composeTextEnd;
}

/// Appends a run inside a `composeText` block, styled by the innermost
/// enclosing `textStyle` (or the block's base style if there is none).
///
/// Assumed that memory content refers to is going to live in memory until the
/// end of composeText
pub fn write(content: []const u8) void {
    const self = getForbear();
    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) return;
    if (self.frameMeta.?.textBuilder == null) {
        std.log.err("forbear.write can only be used inside of forbear.composeText", .{});
        handleFrameError(error.NestedComposeText);
        return;
    }
    if (content.len == 0) return;

    const builder = &self.frameMeta.?.textBuilder.?;
    builder.runs.append(self.frameMeta.?.arena, .{
        .content = content,
        .style = builder.styleStack.getLast(),
    }) catch |err| {
        handleFrameError(err);
    };
}

/// Layers a style override over the runs written inside its block. Nestable,
/// which is what lets reusable helpers compose, e.g. the built-in `Strong`.
pub noinline fn textStyle(style: TextStyle) *const fn (void) void {
    const self = getForbear();
    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) return &noopEnd;
    // `textStyle` is only valid inside a `composeText` block.
    std.debug.assert(self.frameMeta.?.textBuilder != null);

    const builder = &self.frameMeta.?.textBuilder.?;
    const resolved = style.complete(builder.styleStack.getLast());
    builder.styleStack.append(self.frameMeta.?.arena, resolved) catch |err| {
        handleFrameError(err);
        return &noopEnd;
    };
    return &textStyleEnd;
}

fn textStyleEnd(block: void) void {
    _ = block;
    const self = getForbear();
    if (self.frameMeta.?.err != null) return;
    if (self.frameMeta.?.textBuilder) |*builder| {
        _ = builder.styleStack.pop();
    }
}

/// Bold (`fontWeight = 700`) text run, the inline-text analog of HTML's
/// `<strong>`. A thin `textStyle` helper, so it is only valid inside a
/// `composeText` block: `Strong()({ write("important"); });`.
pub fn Strong() *const fn (void) void {
    return textStyle(.{ .fontWeight = 700 });
}

noinline fn composeTextEnd(block: void) void {
    _ = block;
    const returnAddress = @returnAddress();
    const self = getForbear();
    std.debug.assert(self.frameMeta != null);

    const builder = self.frameMeta.?.textBuilder orelse return;
    self.frameMeta.?.textBuilder = null;
    if (self.frameMeta.?.err != null) return;
    if (builder.runs.items.len == 0) return;

    buildText(builder.runs.items, builder.base, returnAddress) catch |err| {
        handleFrameError(err);
    };
}

pub noinline fn text(content: []const u8) void {
    if (content.len == 0) return;
    const returnAddress = @returnAddress();

    const self = getForbear();
    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) return;

    if (self.frameMeta.?.textBuilder != null) {
        std.log.err("forbear.text, or forbear.element cannot be called from inside forbear.composeText. You can only use forbear.textStyle and forbear.write.", .{});
        handleFrameError(error.ElementInsideTextCompose);
        return;
    }

    const parentIndexOptional = self.nodeStack.getLastOrNull();
    const baseStyle = if (parentIndexOptional) |parentIndex|
        BaseStyle.from(self.nodeTree.at(parentIndex).style)
    else
        self.frameMeta.?.baseStyle;
    const base = CompleteTextStyle.from(baseStyle);

    buildText(&[_]TextRun{.{ .content = content, .style = base }}, base, returnAddress) catch |err| {
        handleFrameError(err);
    };
}

fn buildText(runs: []const TextRun, base: CompleteTextStyle, returnAddress: usize) !void {
    const self = getForbear();
    const arena = self.frameMeta.?.arena;

    const parentIndexOptional = self.nodeStack.getLastOrNull();
    const result = try self.nodeTree.putNode(self.allocator, parentIndexOptional);

    const parentOptional = if (parentIndexOptional) |parentIndex|
        self.nodeTree.at(parentIndex)
    else
        null;

    const baseStyle = if (parentOptional) |parent|
        BaseStyle.from(parent.style)
    else
        self.frameMeta.?.baseStyle;

    (Style{
        .cursor = if (baseStyle.cursor == .default)
            .text
        else
            baseStyle.cursor,
        .xJustification = if (parentOptional) |parent| parent.style.xJustification else null,
        .yJustification = .start,
        .font = base.font,
        .color = base.color,
        .fontSize = base.fontSize,
        .fontWeight = base.fontWeight,
        .lineHeight = base.lineHeight,
    }).completeWith(baseStyle, &result.ptr.style);

    // Stable per-frame style copies for glyphs to point at; the builder's run
    // list is cleared the moment `composeText` ends.
    const runStyles = try arena.alloc(CompleteTextStyle, runs.len);

    const RunShaping = struct {
        glyphs: []const Font.ShapedGlyph,
        unitsPerEm: f32,
        fontSize: f32,
        styleIndex: usize,
    };
    const shapings = try arena.alloc(RunShaping, runs.len);

    // Pass 1: shape every run and find the shared line metrics. Shaped glyphs
    // are duped because `font.shape` reuses and evicts its cache across calls,
    // so a slice from an earlier run can be clobbered by a later one.
    var lineHeight: f32 = 0.0;
    var ascent: f32 = 0.0;
    var totalGlyphCount: usize = 0;
    for (runs, 0..) |run, runIndex| {
        runStyles[runIndex] = run.style;

        var effectiveContent: []const u8 = run.content;
        if (std.mem.containsAtLeast(u8, run.content, 1, "\r")) {
            const owned = try arena.alloc(u8, run.content.len);
            var readIndex: usize = 0;
            var writeIndex: usize = 0;
            while (readIndex < run.content.len) : (readIndex += 1) {
                const character = run.content[readIndex];
                if (character == '\r') {
                    if (readIndex + 1 < run.content.len and run.content[readIndex + 1] == '\n') {
                        readIndex += 1;
                    }
                    owned[writeIndex] = '\n';
                } else if (character == '\n') {
                    if (readIndex + 1 < run.content.len and run.content[readIndex + 1] == '\r') {
                        readIndex += 1;
                    }
                    owned[writeIndex] = '\n';
                } else {
                    owned[writeIndex] = character;
                }
                writeIndex += 1;
            }
            effectiveContent = owned[0..writeIndex];
        }

        const shaped = try run.style.font.shape(effectiveContent);
        const owned = try arena.dupe(Font.ShapedGlyph, shaped);

        const unitsPerEm: f32 = @floatFromInt(run.style.font.unitsPerEm());
        const runLineHeight = run.style.font.lineHeight() * run.style.lineHeight / unitsPerEm * run.style.fontSize;
        const runAscent = run.style.font.ascent() / unitsPerEm * run.style.fontSize;
        lineHeight = @max(lineHeight, runLineHeight);
        ascent = @max(ascent, runAscent);

        shapings[runIndex] = .{
            .glyphs = owned,
            .unitsPerEm = unitsPerEm,
            .fontSize = run.style.fontSize,
            .styleIndex = runIndex,
        };
        totalGlyphCount += owned.len;
    }

    var layoutGlyphs = try arena.alloc(LayoutGlyph, totalGlyphCount);
    errdefer arena.free(layoutGlyphs);

    var cursor: Vec2 = @splat(0.0);
    var minSize: Vec2 = .{ 0.0, lineHeight };
    var maxSize: Vec2 = .{ 0.0, lineHeight };
    var preBreakIndices: std.ArrayList(usize) = .empty;
    var wordAdvance: Vec2 = @splat(0.0);
    var writeIndex: usize = 0;

    // Pass 2: place glyphs into the one shared line box, using each run's own
    // advances but the block's shared line height.
    for (shapings) |shaping| {
        const unitsPerEmVec2: Vec2 = @splat(shaping.unitsPerEm);
        const fontSizeVec2: Vec2 = @splat(shaping.fontSize);
        for (shaping.glyphs) |shapedGlyph| {
            var advance = shapedGlyph.advance / unitsPerEmVec2 * fontSizeVec2;
            const offset = shapedGlyph.offset / unitsPerEmVec2 * fontSizeVec2;
            const isLinebreak = std.mem.startsWith(u8, &shapedGlyph.utf8.Encoded, "\n");
            if (isLinebreak) {
                advance[0] = -cursor[0];
                advance[1] += lineHeight;
                try preBreakIndices.append(arena, writeIndex);
            } else {
                layoutGlyphs[writeIndex] = LayoutGlyph{
                    .index = @intCast(shapedGlyph.index),
                    .position = cursor + offset,

                    .textBuf = shapedGlyph.utf8.Encoded,

                    .advance = advance,
                    .offset = offset,
                    .style = &runStyles[shaping.styleIndex],
                };
                writeIndex += 1;
            }

            cursor += advance;
            maxSize[0] = @max(maxSize[0], cursor[0]);
            if (result.ptr.style.textWrapping == .word) {
                if (std.mem.startsWith(u8, &shapedGlyph.utf8.Encoded, " ") or isLinebreak) {
                    wordAdvance = @splat(0.0);
                    maxSize[1] += lineHeight;
                } else {
                    wordAdvance += advance;
                }
                minSize[0] = @max(minSize[0], wordAdvance[0]);
            } else if (result.ptr.style.textWrapping == .character) {
                minSize[0] = @max(minSize[0], advance[0]);
                maxSize[1] += lineHeight;
            } else if (result.ptr.style.textWrapping == .none) {
                minSize[0] = @max(minSize[0], cursor[0]);
            }
        }
    }
    minSize[1] = cursor[1] + lineHeight;

    const parentZ = if (parentOptional) |parent|
        parent.z
    else
        0;

    var k: u64 = 0;
    if (self.scopeStack.getLastOrNull()) |lastScopeKey| {
        k = mixU64(k, lastScopeKey);
    }
    k = mixU64(k, @as(u64, self.nodeStack.items.len));
    // We don't mix the text content here because text selection would be nice
    // to work even with text changing
    //
    // k = mixU64(k, std.hash.Wyhash.hash(0, effectiveContent));
    k = mixU64(k, returnAddress);

    result.ptr.key = k;
    result.ptr.position = @splat(0.0);
    result.ptr.z = if (parentZ < std.math.maxInt(u16))
        parentZ + 1
    else
        parentZ;
    result.ptr.size = .{ maxSize[0], minSize[1] };
    result.ptr.minSize = minSize;
    result.ptr.maxSize = maxSize;
    result.ptr.glyphs = Glyphs{
        .slice = layoutGlyphs[0..writeIndex],
        .lineHeight = lineHeight,
        .ascent = ascent,
        .preBreakIndices = preBreakIndices.items,
    };

    self.frameMeta.?.previousPushedNodeIndex = result.index;

    if (parentOptional) |parent| {
        parent.fitChild(result.ptr);
    }

    // Push self onto the parent stack so `on(.mouseOver)` resolves the
    // text node's own measurement, then pop. The text node itself is not
    // a scope and has no children, so this is purely for hit-testing.
    try self.nodeStack.append(self.allocator, result.index);
    defer _ = self.nodeStack.pop();

    try pushScope(result.ptr.key);
    defer popScope();

    if (on(.mouseEnter)) {
        setCursor(result.ptr.style.cursor);
    }
    if (on(.mouseLeave)) {
        setCursor(baseStyle.cursor);
    }
}

/// Sets the OS-level mouse cursor for the current frame. Called per-frame
/// (typically from a `forbear.on(.mouseOver)` branch) — the last call wins,
/// so deeper/later mounted elements take precedence.
pub fn setCursor(cursor: Cursor) void {
    const self = getForbear();
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
    const self = getForbear();
    std.debug.assert(self.frameMeta != null);

    self.frameMeta.?.err = err;

    if (builtin.is_test) return;

    std.debug.print("There was an error during frame's UI mounting stage:\n", .{});
    std.debug.dumpCurrentStackTrace(.{ .first_address = @returnAddress() });
}

fn componentEnd(block: void) void {
    _ = block;
    const self = getForbear();

    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) {
        return;
    }

    popScope();
}

pub inline fn hook() void {
    const self = getForbear();

    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) {
        return;
    }
    var k: u64 = 0;
    if (self.scopeStack.getLastOrNull()) |lastScopeKey| {
        k = mixU64(k, lastScopeKey);
    }
    k = mixU64(k, @returnAddress());
    pushScope(k) catch |err| {
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
    const self = getForbear();

    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) {
        return &noopEnd;
    }

    // the component keys wrapping this component and the amount of parents in
    // the node tree up to this point are what differentiate this instance from
    // other instances of the same component
    var k: u64 = 0;
    if (self.scopeStack.getLastOrNull()) |lastScopeKey| {
        k = mixU64(k, lastScopeKey);
    }
    k = mixU64(k, @as(u64, self.nodeStack.items.len));
    if (props.key) |key| {
        k = mixU64(k, std.hash.Wyhash.hash(0, key));
    } else {
        k = mixU64(k, @returnAddress());
    }

    const componentKey = k;
    pushScope(componentKey) catch |err| {
        handleFrameError(err);
        return noopEnd;
    };

    return &componentEnd;
}

pub fn componentChildrenSlot() void {
    const self = getForbear();

    std.debug.assert(self.frameMeta != null);
    const fm = &self.frameMeta.?;
    if (fm.err != null) return;

    const parentIndex = self.nodeStack.getLastOrNull() orelse {
        handleFrameError(error.NoParentForSlot);
        return;
    };

    const savedStack = fm.arena.dupe(usize, self.nodeStack.items) catch |err| {
        handleFrameError(err);
        return;
    };
    const savedScopeStack = fm.arena.dupe(u64, self.scopeStack.items) catch |err| {
        handleFrameError(err);
        return;
    };
    const savedContextStack = fm.arena.dupe(ContextStackEntry, self.contextStack.items) catch |err| {
        handleFrameError(err);
        return;
    };

    fm.componentChildrenSlotStates.append(fm.arena, .{
        .savedSlotParentStack = savedStack,
        .savedPreEndParentStack = &.{},
        .savedSlotScopeStack = savedScopeStack,
        .savedPreEndScopeStack = &.{},
        .savedSlotContextStack = savedContextStack,
        .savedPreEndContextStack = &.{},
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
    const self = getForbear();

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

    // Restore parent stack and scope stack to pre-slotEnd state
    self.nodeStack.clearRetainingCapacity();
    self.nodeStack.appendSlice(self.allocator, slotState.savedPreEndParentStack) catch |err| {
        handleFrameError(err);
    };
    self.scopeStack.clearRetainingCapacity();
    self.scopeStack.appendSlice(self.allocator, slotState.savedPreEndScopeStack) catch |err| {
        handleFrameError(err);
    };
    self.contextStack.clearRetainingCapacity();
    self.contextStack.appendSlice(self.allocator, slotState.savedPreEndContextStack) catch |err| {
        handleFrameError(err);
    };
}

pub fn componentChildrenSlotEnd() *const fn (void) void {
    const self = getForbear();

    std.debug.assert(self.frameMeta != null);
    const fm = &self.frameMeta.?;
    if (fm.err != null) return &noopEnd;

    const states = &fm.componentChildrenSlotStates;
    if (states.items.len == 0) {
        handleFrameError(error.NoMatchingSlotBegin);
        return &noopEnd;
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

    // Save current parent and scope stacks, then restore to slot-time state so
    // the children block runs as if it were inside the slot's owner.
    slotState.savedPreEndParentStack = fm.arena.dupe(usize, self.nodeStack.items) catch |err| {
        handleFrameError(err);
        return &noopEnd;
    };
    slotState.savedPreEndScopeStack = fm.arena.dupe(u64, self.scopeStack.items) catch |err| {
        handleFrameError(err);
        return &noopEnd;
    };
    slotState.savedPreEndContextStack = fm.arena.dupe(ContextStackEntry, self.contextStack.items) catch |err| {
        handleFrameError(err);
        return &noopEnd;
    };
    self.nodeStack.clearRetainingCapacity();
    self.nodeStack.appendSlice(self.allocator, slotState.savedSlotParentStack) catch |err| {
        handleFrameError(err);
        return &noopEnd;
    };
    self.scopeStack.clearRetainingCapacity();
    self.scopeStack.appendSlice(self.allocator, slotState.savedSlotScopeStack) catch |err| {
        handleFrameError(err);
        return &noopEnd;
    };
    self.contextStack.clearRetainingCapacity();
    self.contextStack.appendSlice(self.allocator, slotState.savedSlotContextStack) catch |err| {
        handleFrameError(err);
        return &noopEnd;
    };

    return &componentChildrenSlotEndFn;
}

pub fn OnResult(comptime eventTag: Event) type {
    return switch (eventTag) {
        .scroll, .mouseMove => ?Vec2,
        .keyDown, .keyUp => Keys,
        else => bool,
    };
}

/// Inline hit test against previous-frame measurement. No event queue —
/// every caller sees the same raw input state each frame.
///
/// Keyboard events (`.keyDown` / `.keyUp`) are **global** for now: every
/// caller sees every key edge that occurred since the last frame,
/// regardless of which element invoked `on()`. Focus scoping is a
/// separate concern layered on top.
pub fn on(comptime eventTag: Event) OnResult(eventTag) {
    if (comptime eventTag == .keyDown or eventTag == .keyUp) {
        const self = getForbear();
        return switch (eventTag) {
            .keyDown => self.keysPressedThisFrame,
            .keyUp => self.keysReleasedThisFrame,
            else => unreachable,
        };
    }

    hook();
    defer hookEnd();
    const self = getForbear();
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
        // Keyboard tags + `.click` returned earlier.
        .click, .keyDown, .keyUp => unreachable,
    };
    const lastMousePositionSlot: ?*Vec2 = if (eventTag == .mouseMove)
        useState(Vec2, self.mousePosition)
    else
        null;

    const measurement = useNodeMeasurement() orelse {
        if (comptime eventTag == .scroll or eventTag == .mouseMove) return null;
        return false;
    };

    const pos = measurement.position;
    const size = measurement.size;
    const inside = self.mousePosition[0] >= pos[0] and
        self.mousePosition[1] >= pos[1] and
        self.mousePosition[0] <= pos[0] + size[0] and
        self.mousePosition[1] <= pos[1] + size[1];

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
        .click, .keyDown, .keyUp => unreachable,
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
    const self = getForbear();
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
    const self = getForbear();
    return self.mouseButtonPressed;
}

/// Returns some layouting values of the current node from the last frame
pub fn useNodeMeasurement() ?Node.Measurement {
    const self = getForbear();
    std.debug.assert(self.frameMeta != null);
    const parentNodeIndex = self.nodeStack.getLastOrNull() orelse return null;
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
    const self = getForbear();
    self.window = window;

    window.handlers.resize = .{
        .function = &(struct {
            fn handler(_: *Window, width: u32, height: u32, dpi: [2]u32, data: *anyopaque) void {
                _ = dpi;
                const ctx: *Forbear = @ptrCast(@alignCast(data));
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
                const ctx: *Forbear = @ptrCast(@alignCast(data));
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
                const ctx: *Forbear = @ptrCast(@alignCast(data));
                ctx.mousePosition = .{ x, y };
            }
        }).handler,
        .data = @ptrCast(@alignCast(self)),
    };
    window.handlers.pointerButton = .{
        .function = &(struct {
            fn handler(_: *Window, _: u32, _: u32, button: u32, state: u32, data: *anyopaque) void {
                const ctx: *Forbear = @ptrCast(@alignCast(data));
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
    // Keyboard state is owned by the Window backend (atomic bitsets +
    // text buffer behind a SpinLock) and sampled by `snapshotKeyboard`
    // every frame. No handler registration needed.
}

/// All keys currently held, sampled at frame start. Stable for the
/// duration of the frame. Read individual keys as fields:
///   const held = forbear.keysHeld();
///   if (held.controlLeft and forbear.on(.keyDown).z) undo();
///   if (held.shiftLeft or held.shiftRight) doShifty();
pub fn keysHeld() Keys {
    return getForbear().keysHeldSnapshot;
}

pub fn deinit() void {
    const self = getForbear();
    var fontsIterator = self.fonts.valueIterator();
    while (fontsIterator.next()) |font| {
        font.deinit();
    }
    var imagesIterator = self.images.valueIterator();
    while (imagesIterator.next()) |img| {
        img.deinit();
    }
    self.arena.deinit();
    forbear = null;
}

test {
    _ = std.testing.refAllDecls(@import("tests.zig"));
}
