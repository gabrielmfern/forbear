const std = @import("std");
const builtin = @import("builtin");

pub const c = @import("c");

const forbearBuiltin = @import("builtin.zig");
pub const FpsCounter = forbearBuiltin.FpsCounter;
pub const useScrolling = forbearBuiltin.useScrolling;
pub const Font = @import("font.zig");
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
pub const WindowCursor = @import("window/root.zig").Cursor;

pub var traceWriter: ?*std.Io.Writer = null;
pub fn setTraceWriter(writer: *std.Io.Writer) void {
    traceWriter = writer;
}
const Vec2 = @Vector(2, f32);
const Vec4 = @Vector(4, f32);

const Context = @This();

var context: ?@This() = null;

const ScopeKind = enum { component, element };

const ScopeFrame = struct {
    kind: ScopeKind,
    key: u64,
    useStateCursor: usize,
};

const ComponentChildrenSlotState = struct {
    savedSlotParentStack: []usize,
    savedPreEndParentStack: []usize,
    slotPredecessor: ?usize,
    afterChainStart: ?usize,
    afterChainEnd: ?usize,
    slotParentIndex: usize,
};

pub const Event = enum {
    mouseOver,
    mouseOut,
    mouseDown,
    mouseUp,
    click,
    scroll,
};

pub const FrameMeta = struct {
    arena: std.mem.Allocator,

    viewportSize: Vec2,
    baseStyle: BaseStyle,

    // TODO: find a way to include this data as part of the frame, but without
    // hinthering the intellisense for the fields and adding nose to the ones
    // that user actually has to fill out.
    err: ?anyerror = null,

    /// Unified scope stack tracking both component and element scopes in
    /// lexical order. `useState` binds to the topmost frame regardless of
    /// kind; element-key hashing walks back to the nearest `.component`
    /// frame to keep per-component element-key namespacing stable.
    scopeStack: std.ArrayList(ScopeFrame) = .empty,

    /// Set of scope keys that were entered during this frame. At frame end,
    /// any entry in `scopeStates` whose key is missing here is pruned —
    /// matching React-style unmount semantics.
    touchedScopeKeys: std.AutoHashMapUnmanaged(u64, void) = .empty,

    previousPushedNodeIndex: ?usize = null,
    nodeParentStack: std.ArrayList(usize) = .empty,
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
// scrollPosition: Vec2,
// effectiveScrollPosition: Vec2,

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

/// Persistent state storage keyed by scope key. A scope is either a
/// component or an element — `useState` resolves to the nearest enclosing
/// scope, so an entry here may belong to either kind.
scopeStates: std.AutoHashMap(u64, std.ArrayList([]align(@alignOf(usize)) u8)),

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

        .scopeStates = .init(allocator),

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

pub fn useTransition(value: f32, duration: f32, easing: fn (f32) f32) f32 {
    const startValue = useState(f32, value);
    const currentValue = useState(f32, value);
    const targetValue = useState(f32, value);
    const animation = useAnimation(duration);
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

pub fn useSpringTransition(target: f32, config: SpringConfig) f32 {
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

/// Equivalent to CSS's ease timing function
pub fn easeInOut(progress: f32) f32 {
    return cubicBezier(0.42, 0.0, 0.58, 1.0, progress);
}

/// Equivalent to CSS's ease timing function
pub fn ease(progress: f32) f32 {
    return cubicBezier(0.25, 0.1, 0.25, 1.0, progress);
}

pub const red = hex("#ff0000");
pub const white = hex("#ffffff");
pub const black = hex("#000000");
// TODO: add all CSS named colors here

pub fn hex(comptime value: []const u8) Vec4 {
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
    return .{ r, g, b, a };
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
    const index = self.frameMeta.?.nodeParentStack.getLastOrNull() orelse return null;
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

const stateAlignment: std.mem.Alignment = .@"8";

fn currentScope() ?*ScopeFrame {
    const self = getContext();
    if (self.frameMeta.?.scopeStack.items.len > 0) {
        return &self.frameMeta.?.scopeStack.items[self.frameMeta.?.scopeStack.items.len - 1];
    } else {
        return null;
    }
}

/// Walks the scope stack from the top down to find the nearest enclosing
/// component scope. Used by element-key and component-key hashing to keep
/// element identities namespaced per-component; intervening element
/// scopes intentionally do not contribute to that hashing because
/// `nodeParentStack.items.len` already differentiates by depth.
fn nearestComponentScopeKey() ?u64 {
    const self = getContext();
    const items = self.frameMeta.?.scopeStack.items;
    var i = items.len;
    while (i > 0) {
        i -= 1;
        if (items[i].kind == .component) return items[i].key;
    }
    return null;
}

/// TODO: in debug mode, we should be adding some guard rail here to make sure
// of warning the user if they called the hook in an unexpected order, as it
// can cause undefined behavior as is right now
pub fn useState(T: type, initialValue: T) *T {
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

    if (currentScope()) |state| {
        const stateResult = self.scopeStates.getOrPut(state.key) catch |err| {
            std.log.err("Failed to get or put a new scope state {}", .{err});
            @panic("Failed to get or put a new scope state");
        };
        self.frameMeta.?.touchedScopeKeys.put(self.frameMeta.?.arena, state.key, {}) catch |err| {
            handleFrameError(err);
        };
        defer state.useStateCursor += 1;
        if (stateResult.found_existing) {
            if (stateResult.value_ptr.items.len > state.useStateCursor) {
                return @ptrCast(@alignCast(stateResult.value_ptr.*.items[state.useStateCursor]));
            }
        } else {
            stateResult.value_ptr.* = .empty;
        }
        const buffer = self.allocator.alignedAlloc(u8, stateAlignment, @sizeOf(T)) catch |err| {
            std.log.err("Failed to allocate new state {}", .{err});
            @panic("Failed to allocate new state");
        };
        stateResult.value_ptr.*.append(self.allocator, buffer) catch |err| {
            handleFrameError(err);
            return @ptrCast(@alignCast(buffer));
        };
        @memcpy(
            stateResult.value_ptr.*.items[state.useStateCursor],
            std.mem.asBytes(&initialValue),
        );
        return @ptrCast(@alignCast(stateResult.value_ptr.*.items[state.useStateCursor]));
    } else {
        if (!builtin.is_test) {
            std.log.err("You might be calling a hook (useState) outside of a component or element scope, and forbear cannot track things outside of one.", .{});
        }
        @panic("No scope found, you must be calling useState outside of a component or element, otherwise this is a bug.");
    }
}

fn endNoop(block: void) void {
    _ = block;
}

/// A thin wrapper around `element` that includes some aspect ratio handling
/// definition logic in a way that feels more intuitve
pub fn Image(style: Style, img: *ImageType) void {
    component(.{
        .sourceLocation = @src(),
    })({
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
    self.frameMeta = null;
    if (frameMeta.err) |err| return err;

    // Drop state for scopes that weren't entered this frame. Mirrors React
    // unmount semantics: omit a component or element this frame and its
    // state goes away. Element identities churn far more than component
    // identities, so without this every transient element would leak its
    // useState storage.
    var staleScopeKeys: std.ArrayList(u64) = .empty;
    defer staleScopeKeys.deinit(frameMeta.arena);
    var scopeStateKeysIterator = self.scopeStates.keyIterator();
    while (scopeStateKeysIterator.next()) |keyPtr| {
        if (!frameMeta.touchedScopeKeys.contains(keyPtr.*)) {
            staleScopeKeys.append(frameMeta.arena, keyPtr.*) catch |err| {
                std.log.err("Failed to record stale scope key for cleanup: {}", .{err});
                break;
            };
        }
    }
    for (staleScopeKeys.items) |staleKey| {
        if (self.scopeStates.fetchRemove(staleKey)) |entry| {
            var states = entry.value;
            for (states.items) |buffer| self.allocator.free(buffer);
            states.deinit(self.allocator);
        }
    }

    var staleFrameNodeMeasurements: std.ArrayList(u64) = .empty;
    defer staleFrameNodeMeasurements.deinit(frameMeta.arena);

    var iterator = self.previousFrameNodeMeasurements.iterator();
    while (iterator.next()) |entry| {
        if (self.nodeTree.list.items.len - 1 < entry.value_ptr.index) {
            try staleFrameNodeMeasurements.append(frameMeta.arena, entry.key_ptr.*);
            continue;
        }
        const node = self.nodeTree.at(entry.value_ptr.index);
        if (node.key != entry.key_ptr.*) {
            try staleFrameNodeMeasurements.append(frameMeta.arena, entry.key_ptr.*);
            continue;
        }
        entry.value_ptr.size = node.size;
        entry.value_ptr.position = node.position;
        entry.value_ptr.maxSize = node.maxSize;
        entry.value_ptr.minSize = node.minSize;
        entry.value_ptr.contentSize = node.contentSize;
        entry.value_ptr.z = node.z;
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
    std.debug.assert(self.frameMeta.?.nodeParentStack.items.len > 0);

    if (self.frameMeta.?.scopeStack.pop()) |endedScope| {
        std.debug.assert(endedScope.kind == .element);
        if (self.scopeStates.get(endedScope.key)) |scopeState| {
            if (endedScope.useStateCursor != scopeState.items.len) {
                handleFrameError(error.RulesOfHooksViolated);
            }
        }
    }

    self.frameMeta.?.previousPushedNodeIndex = self.frameMeta.?.nodeParentStack.pop();

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

    const parentIndexOptional = self.frameMeta.?.nodeParentStack.getLastOrNull();

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
    if (nearestComponentScopeKey()) |componentKey| {
        hasher.update(std.mem.asBytes(&componentKey));
    }
    hasher.update(std.mem.asBytes(&self.frameMeta.?.nodeParentStack.items.len));
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

    self.frameMeta.?.nodeParentStack.append(self.frameMeta.?.arena, result.index) catch |err| {
        handleFrameError(err);
        return &endNoop;
    };

    self.frameMeta.?.scopeStack.append(self.frameMeta.?.arena, .{
        .kind = .element,
        .key = result.ptr.key,
        .useStateCursor = 0,
    }) catch |err| {
        handleFrameError(err);
        return &endNoop;
    };
    self.frameMeta.?.touchedScopeKeys.put(self.frameMeta.?.arena, result.ptr.key, {}) catch |err| {
        handleFrameError(err);
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

    return &elementEnd;
}

pub fn printText(comptime fmt: []const u8, args: anytype) void {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);

    const arena = self.frameMeta.?.arena;

    component(.{
        .sourceLocation = @src(),
    })({
        text(std.fmt.allocPrint(arena, fmt, args) catch |err| blk: {
            handleFrameError(err);
            break :blk "N/A";
        });
    });
}

pub fn BreakLine() void {
    component(.{
        .sourceLocation = @src(),
    })({
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

    const parentIndexOptional = self.frameMeta.?.nodeParentStack.getLastOrNull();

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
        var ownedContent = std.ArrayList(u8).fromOwnedSlice(arena.dupe(u8, content) catch |err| {
            handleFrameError(err);
            return;
        });
        var i: usize = 0;
        while (i < ownedContent.items.len) {
            const character = ownedContent.items[i];
            if (character == '\r') {
                if (i + 1 < ownedContent.items.len and ownedContent.items[i + 1] == '\n') {
                    _ = ownedContent.orderedRemove(i);
                    i += 1; // skip past the \n now at index i
                } else {
                    ownedContent.items[i] = '\n';
                    i += 1;
                }
            } else if (character == '\n' and i + 1 < ownedContent.items.len and ownedContent.items[i + 1] == '\r') {
                _ = ownedContent.orderedRemove(i + 1);
                i += 1;
            } else {
                i += 1;
            }
        }
        effectiveContent = ownedContent.items;
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
        const glyphText = arena.dupe(u8, shapedGlyph.utf8.Encoded[0..@intCast(shapedGlyph.utf8.EncodedLength)]) catch |err| {
            handleFrameError(err);
            return;
        };
        if (std.mem.eql(u8, glyphText, "\n")) {
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

                .text = glyphText,

                .advance = advance,
                .offset = offset,
            };
        }

        cursor += advance;
        maxSize[0] = @max(maxSize[0], cursor[0]);
        if (style.textWrapping == .word) {
            if (std.mem.eql(u8, glyphText, " ") or std.mem.eql(u8, glyphText, "\n")) {
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
    if (nearestComponentScopeKey()) |componentKey| {
        hasher.update(std.mem.asBytes(&componentKey));
    }
    hasher.update(std.mem.asBytes(&self.frameMeta.?.nodeParentStack.items.len));
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

    if (self.frameMeta.?.scopeStack.pop()) |endedScope| {
        std.debug.assert(endedScope.kind == .component);
        if (self.scopeStates.get(endedScope.key)) |scopeState| {
            if (endedScope.useStateCursor != scopeState.items.len) {
                handleFrameError(error.RulesOfHooksViolated);
            }
        }
    }
}

const ComponentKey = union(enum) {
    text: []const u8,
    sourceLocation: std.builtin.SourceLocation,
};

pub fn component(key: ComponentKey) *const fn (void) void {
    const self = getContext();

    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) {
        return &endNoop;
    }

    var hasher = std.hash.Wyhash.init(0);
    // the component keys wrapping this component and the amount of parents in
    // the node tree up to this point are what differentiate this instance from
    // other instances of the same component
    if (nearestComponentScopeKey()) |parentComponentKey| {
        hasher.update(std.mem.asBytes(&parentComponentKey));
    }
    hasher.update(std.mem.asBytes(&self.frameMeta.?.nodeParentStack.items.len));
    switch (key) {
        .text => hasher.update(key.text),
        .sourceLocation => hasher.update(std.mem.asBytes(&key.sourceLocation)),
    }

    const componentKey = hasher.final();
    self.frameMeta.?.scopeStack.append(self.frameMeta.?.arena, .{
        .kind = .component,
        .key = componentKey,
        .useStateCursor = 0,
    }) catch |err| {
        handleFrameError(err);
        return endNoop;
    };
    self.frameMeta.?.touchedScopeKeys.put(self.frameMeta.?.arena, componentKey, {}) catch |err| {
        handleFrameError(err);
    };

    return &componentEnd;
}

pub fn componentChildrenSlot() void {
    const self = getContext();

    std.debug.assert(self.frameMeta != null);
    const fm = &self.frameMeta.?;
    if (fm.err != null) return;

    const parentIndex = fm.nodeParentStack.getLastOrNull() orelse {
        handleFrameError(error.NoParentForSlot);
        return;
    };

    const savedStack = fm.arena.dupe(usize, fm.nodeParentStack.items) catch |err| {
        handleFrameError(err);
        return;
    };

    fm.componentChildrenSlotStates.append(fm.arena, .{
        .savedSlotParentStack = savedStack,
        .savedPreEndParentStack = &.{},
        .slotPredecessor = self.nodeTree.at(parentIndex).lastChild,
        .afterChainStart = null,
        .afterChainEnd = null,
        .slotParentIndex = parentIndex,
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
    const parent = self.nodeTree.at(slotState.slotParentIndex);

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
    fm.nodeParentStack.clearRetainingCapacity();
    fm.nodeParentStack.appendSlice(fm.arena, slotState.savedPreEndParentStack) catch |err| {
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
    const parent = self.nodeTree.at(slotState.slotParentIndex);

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
    slotState.savedPreEndParentStack = fm.arena.dupe(usize, fm.nodeParentStack.items) catch |err| {
        handleFrameError(err);
        return &endNoop;
    };
    fm.nodeParentStack.clearRetainingCapacity();
    fm.nodeParentStack.appendSlice(fm.arena, slotState.savedSlotParentStack) catch |err| {
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
    return if (eventTag == .scroll) ?Vec2 else bool;
}

/// Inline hit test against previous-frame measurement. No event queue —
/// every caller sees the same raw input state each frame.
pub fn on(comptime eventTag: Event) OnResult(eventTag) {
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
        if (on(.mouseOut)) {
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

    const measurement = useNodeMeasurement() orelse {
        if (comptime eventTag == .scroll) return null;
        return false;
    };

    const inside = self.isMouseInsideMeasurement(measurement);

    switch (eventTag) {
        .mouseOver => return inside,
        .mouseOut => return !inside,
        .mouseDown => {
            const wasPressedLastFrame = useState(bool, false);
            defer wasPressedLastFrame.* = self.mouseButtonPressed;
            return self.mouseButtonPressed and !wasPressedLastFrame.* and inside;
        },
        .mouseUp => {
            const wasPressedLastFrame = useState(bool, false);
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

/// Returns some layouting values of the current node from the last frame
pub fn useNodeMeasurement() ?Node.Measurement {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);
    const parentNodeIndex = self.frameMeta.?.nodeParentStack.getLastOrNull() orelse return null;
    const parentNode = self.nodeTree.at(parentNodeIndex);
    const measurement = self.previousFrameNodeMeasurements.getOrPut(parentNode.key) catch |err| {
        std.log.err("Failed to get or put previous frame node measurement: {}", .{err});
        handleFrameError(err);
        return null;
    };

    // the index in the tree might've changed, and it's important this stays
    // updated so that, at the frame end, we can update the measurements
    // without having to look up the node by the key through the entire tree
    measurement.value_ptr.index = parentNodeIndex;
    if (measurement.found_existing) {
        return measurement.value_ptr.*;
    }

    return null;
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

    var scopeStatesIterator = self.scopeStates.valueIterator();
    while (scopeStatesIterator.next()) |states| {
        for (states.items) |state| {
            self.allocator.free(state);
        }
        states.deinit(self.allocator);
    }
    self.scopeStates.deinit();

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

pub fn getContext() *@This() {
    return &context.?;
}

test {
    _ = std.testing.refAllDecls(@import("tests.zig"));
}
