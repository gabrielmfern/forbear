const std = @import("std");
const builtin = @import("builtin");

pub const c = @import("c.zig").c;
pub const Font = @import("font.zig");
pub const Graphics = @import("graphics.zig");
pub const Image = @import("graphics.zig").Image;
const layouting = @import("layouting.zig");
pub const layout = layouting.layout;
pub var traceWriter: ?*std.io.Writer = null;
pub fn setTraceWriter(writer: *std.io.Writer) void {
    traceWriter = writer;
}
const nodeImport = @import("node.zig");
pub const Node = nodeImport.Node;
pub const NodeTree = nodeImport.NodeTree;
pub const Direction = nodeImport.Direction;
pub const LayoutGlyph = nodeImport.LayoutGlyph;
pub const Glyphs = nodeImport.Glyphs;
pub const BaseStyle = nodeImport.BaseStyle;
pub const Alignment = nodeImport.Alignment;
pub const Padding = nodeImport.Padding;
pub const Margin = nodeImport.Margin;
pub const BorderWidth = nodeImport.BorderWidth;
pub const Offset = nodeImport.Shadow.Offset;
pub const IncompleteStyle = nodeImport.IncompleteStyle;
pub const Style = nodeImport.Style;
pub const Element = nodeImport.Element;
pub const Window = @import("window/root.zig").Window;
pub const WindowCursor = @import("window/root.zig").Cursor;
pub const components = @import("components.zig");
pub const FpsCounter = components.FpsCounter;

const Vec2 = @Vector(2, f32);

const Context = @This();

var context: ?@This() = null;

const ComponentResolutionState = struct {
    useStateCursor: usize,
    key: u64,
};

const ComponentChildrenSlotState = struct {
    savedSlotParentStack: []usize,
    savedPreEndParentStack: []usize,
    slotPredecessor: ?usize,
    afterChainStart: ?usize,
    afterChainEnd: ?usize,
    slotParentIndex: usize,
};

pub const Event = union(enum) {
    mouseOver,
    mouseOut,
    mouseDown,
    mouseUp,
    click,
};

const ElementEventQueue = std.AutoHashMap(u64, std.ArrayList(Event));

pub const FrameMeta = struct {
    arena: std.mem.Allocator,

    viewportSize: Vec2,
    dpi: Vec2,
    baseStyle: BaseStyle,

    // TODO: find a way to include this data as part of the frame, but without
    // hinthering the intellisense for the fields and adding nose to the ones
    // that user actually has to fill out.
    err: ?anyerror = null,

    componentResolutionState: std.ArrayList(ComponentResolutionState) = .empty,
    /// An index counting the amount of components behind the current one. This
    /// helps differentiate the same components being used sequentially, since
    /// they're not included in the node tree at all
    componentIndex: usize = 0,

    previousPushedNodeIndex: ?usize = null,
    nodeParentStack: std.ArrayList(usize) = .empty,
    componentChildrenSlotStates: std.ArrayList(ComponentChildrenSlotState) = .empty,
};

allocator: std.mem.Allocator,

mousePosition: Vec2,
mouseButtonPressed: bool,
mouseButtonJustPressed: bool,
mouseButtonJustReleased: bool,
hoveredElementKeys: std.ArrayList(u64),
mouseDownElementKeys: std.ArrayList(u64),
/// The eased in value of `effectiveScrollPosition`
scrollPosition: Vec2,
/// The final value of the scrolling, without considering any animations, snaps
/// exactly into place.
effectiveScrollPosition: Vec2,

renderer: *Graphics.Renderer,
window: ?*Window,

/// Seconds
startTime: f64,
/// Seconds
deltaTime: ?f64,
/// Seconds
lastUpdateTime: ?f64,
viewportSize: Vec2,

componentStates: std.AutoHashMap(u64, std.ArrayList([]align(@alignOf(usize)) u8)),

nodeTree: NodeTree,
frameMeta: ?FrameMeta,
pendingEventQueue: std.AutoHashMap(u64, std.ArrayList(Event)),

images: std.StringHashMap(Image),
fonts: std.StringHashMap(Font),

pub fn init(allocator: std.mem.Allocator, renderer: *Graphics.Renderer) !void {
    if (context != null) {
        return error.AlreadyInitialized;
    }

    context = @This(){
        .allocator = allocator,

        .mousePosition = @splat(0.0),
        .mouseButtonPressed = false,
        .mouseButtonJustPressed = false,
        .mouseButtonJustReleased = false,
        .hoveredElementKeys = try std.ArrayList(u64).initCapacity(allocator, 1),
        .mouseDownElementKeys = try std.ArrayList(u64).initCapacity(allocator, 1),
        .scrollPosition = @splat(0.0),
        .effectiveScrollPosition = @splat(0.0),

        .renderer = renderer,
        .window = null,

        .startTime = timestampSeconds(),
        .deltaTime = null,
        .lastUpdateTime = null,
        .viewportSize = @splat(0.0),

        .componentStates = .init(allocator),

        .frameMeta = null,
        .nodeTree = .empty,
        .pendingEventQueue = .init(allocator),

        .images = std.StringHashMap(Image).init(allocator),
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
pub fn useImage(uniqueIdentifier: []const u8) !*Image {
    const self = getContext();
    return self.images.getPtr(uniqueIdentifier) orelse {
        std.log.err("Could not find image by the unique identifier {s}", .{uniqueIdentifier});
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

pub fn useAnimation(duration: f32) Animation {
    const self = getContext();
    const state = useState(?AnimationState, null);

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

pub fn getNode(index: usize) ?*Node {
    return getContext().nodeTree.at(index);
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

fn currentComponentResolutionState() ?*ComponentResolutionState {
    const self = getContext();
    if (self.frameMeta.?.componentResolutionState.items.len > 0) {
        return &self.frameMeta.?.componentResolutionState.items[self.frameMeta.?.componentResolutionState.items.len - 1];
    } else {
        return null;
    }
}

/// TODO: in debug mode, we should be adding some guard rail here to make sure
// of warning the user if they called the hook in an unexpected order, as it
// can cause undefined behavior as is right now
pub fn useState(T: type, initialValue: T) *T {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);

    if (self.frameMeta.?.err != null) {
        return undefined;
    }

    if (currentComponentResolutionState()) |state| {
        const stateResult = self.componentStates.getOrPut(state.key) catch |err| {
            std.log.err("Failed to get or put a new component state {}", .{err});
            @panic("Failed to get or put a new component state");
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
            std.log.err("You might be calling a hook (useState) outside of a component, and forbear cannot track things outside of one.", .{});
        }
        @panic("No component resolution state found, you must be calling useState outside of a component, otherwise this is a bug.");
    }
}

fn endNoop(block: void) void {
    _ = block;
}

/// A thin wrapper around `element` that includes some aspect ratio handling
/// definition logic in a way that feels more intuitve
pub fn image(style: IncompleteStyle, img: *Image) void {
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

    element(complementedStyle)({});
}

fn frameEnd(block: void) anyerror!void {
    _ = block;
    const self = getContext();

    std.debug.assert(self.frameMeta != null);
    const frameMeta = self.frameMeta.?;
    self.frameMeta = null;
    if (frameMeta.err) |err| return err;
}

pub fn frame(meta: FrameMeta) *const fn (void) anyerror!void {
    const self = getContext();

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

    if (self.frameMeta.?.nodeParentStack.getLastOrNull()) |parentIndex| {
        const parent = self.nodeTree.at(parentIndex);

        if (parent.firstChild == previousNodeIndex) {
            inline for (Direction.array) |fitDirection| {
                if (parent.style.getPreferredSize(fitDirection) == .fit) {
                    parent.setSize(fitDirection, parent.fittingBase(fitDirection));
                }
                if (parent.shouldFitMin(fitDirection)) {
                    parent.setMinSize(fitDirection, parent.fittingBase(fitDirection));
                }
            }
        }

        parent.fitChild(node);
    }
    var childIndexOption = node.firstChild;
    while (childIndexOption) |childIndex| {
        const child = self.nodeTree.at(childIndex);
        if (child.style.width == .percentage) {
            child.size[0] = child.style.width.percentage * node.size[0];
        }
        if (child.style.height == .percentage) {
            child.size[1] = child.style.height.percentage * node.size[1];
        }
        childIndexOption = child.nextSibling;
    }
}

pub fn element(incompleteStyle: IncompleteStyle) *const fn (void) void {
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

    const baseStyle = if (parentOptional) |parent|
        BaseStyle.from(parent.style)
    else
        self.frameMeta.?.baseStyle;
    const style = incompleteStyle.completeWith(baseStyle);
    // const resolutionMultiplier = self.frameMeta.?.dpi / @as(Vec2, @splat(72));
    // style.borderWidth.x *= @splat(resolutionMultiplier[0]);
    // style.borderWidth.y *= @splat(resolutionMultiplier[1]);
    // if (style.shadow) |*shadow| {
    //     shadow.offset.x *= @splat(resolutionMultiplier[0]);
    //     shadow.offset.y *= @splat(resolutionMultiplier[1]);
    //     shadow.blurRadius *= resolutionMultiplier[0];
    //     shadow.spread *= resolutionMultiplier[0];
    // }
    // style.padding.x *= @splat(resolutionMultiplier[0]);
    // style.padding.y *= @splat(resolutionMultiplier[1]);
    // style.margin.x *= @splat(resolutionMultiplier[0]);
    // style.margin.y *= @splat(resolutionMultiplier[1]);
    // style.borderRadius *= resolutionMultiplier[0];

    const parentZ = if (parentOptional) |parent|
        parent.z
    else
        0;

    var hasher = std.hash.Wyhash.init(0);
    hasher.update(std.mem.asBytes(&result.index));
    // TODO: as is, it doesn't really work making a list of elements that might
    // lose one or gain one in the midst of other ones, becasue it will
    // invalidate the keys for all subsequent nodes, therefore also freeing
    // state that it shouldn't
    result.ptr.key = hasher.final();
    result.ptr.style = style;
    result.ptr.z = if (incompleteStyle.zIndex) |zIndex|
        zIndex
    else if (parentZ < std.math.maxInt(u16))
        parentZ + 1
    else
        parentZ;
    result.ptr.position = if (style.placement == .manual)
        style.placement.manual
    else
        result.ptr.position;
    result.ptr.size = .{
        switch (style.width) {
            .fixed => |width| width,
            .ratio => |ratio| if (style.height == .fixed)
                style.height.fixed * ratio
            else
                result.ptr.size[0],
            .fit, .grow, .percentage => result.ptr.size[0],
        },
        switch (style.height) {
            .fixed => |height| height,
            .ratio => |ratio| if (style.width == .fixed)
                style.width.fixed * ratio
            else
                result.ptr.size[1],
            .fit, .grow, .percentage => result.ptr.size[1],
        },
    };
    result.ptr.minSize = .{
        if (style.minWidth) |minWidth|
            minWidth
        else if (style.width == .fixed)
            style.width.fixed
        else
            result.ptr.minSize[0],
        if (style.minHeight) |minHeight|
            minHeight
        else if (style.height == .fixed)
            style.height.fixed
        else
            result.ptr.minSize[1],
    };
    result.ptr.maxSize = .{
        if (style.maxWidth) |maxWidth|
            maxWidth
        else if (style.width == .fixed)
            style.width.fixed
        else
            result.ptr.maxSize[0],
        if (style.maxHeight) |maxHeight|
            maxHeight
        else if (style.height == .fixed)
            style.height.fixed
        else
            result.ptr.maxSize[1],
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

    self.frameMeta.?.previousPushedNodeIndex = result.index;

    return &elementEnd;
}

pub fn printText(comptime fmt: []const u8, args: anytype) void {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);

    const arena = self.frameMeta.?.arena;

    text(std.fmt.allocPrint(arena, fmt, args) catch |err| blk: {
        handleFrameError(err);
        break :blk "N/A";
    });
}

pub fn text(content: []const u8) void {
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

    const resolutionMultiplier = self.frameMeta.?.dpi / @as(Vec2, @splat(72));

    const baseStyle = if (parentOptional) |parent|
        BaseStyle.from(parent.style)
    else
        self.frameMeta.?.baseStyle;

    const style = (IncompleteStyle{
        .cursor = if (baseStyle.cursor == .default)
            .text
        else
            baseStyle.cursor,
        .xJustification = if (parentOptional) |parent| parent.style.xJustification else null,
        .yJustification = .start,
    }).completeWith(baseStyle);

    const unitsPerEm: f32 = @floatFromInt(style.font.unitsPerEm());
    const unitsPerEmVec2: Vec2 = @splat(unitsPerEm);
    const pixelSizeVec2: Vec2 = @as(Vec2, @splat(style.fontSize)) * resolutionMultiplier;
    const pixelLineHeight = style.font.lineHeight() * style.lineHeight / unitsPerEm * pixelSizeVec2[1];

    const shapedGlyphs = style.font.shape(content) catch |err| {
        handleFrameError(err);
        return;
    };
    var layoutGlyphs = arena.alloc(LayoutGlyph, shapedGlyphs.len) catch |err| {
        handleFrameError(err);
        return;
    };
    errdefer arena.free(layoutGlyphs);
    var cursor: Vec2 = @splat(0.0);

    var minSize: Vec2 = .{ 0.0, pixelLineHeight };
    var maxSize: Vec2 = .{ 0.0, pixelLineHeight };

    var wordStart: usize = 0;
    var wordAdvance: Vec2 = @splat(0.0);
    for (shapedGlyphs, 0..) |shapedGlyph, i| {
        const advance = shapedGlyph.advance / unitsPerEmVec2 * pixelSizeVec2;
        const offset = shapedGlyph.offset / unitsPerEmVec2 * pixelSizeVec2;
        const glyphText = arena.dupe(u8, shapedGlyph.utf8.Encoded[0..@intCast(shapedGlyph.utf8.EncodedLength)]) catch |err| {
            handleFrameError(err);
            return;
        };
        layoutGlyphs[i] = LayoutGlyph{
            .index = @intCast(shapedGlyph.index),
            .position = cursor + offset,

            .text = glyphText,

            .advance = advance,
            .offset = offset,
        };

        cursor += advance;
        if (style.textWrapping == .word) {
            if (std.mem.eql(u8, glyphText, " ")) {
                wordStart = i;
                wordAdvance = @splat(0.0);
            } else {
                wordAdvance += advance;
            }
            minSize = @max(minSize, wordAdvance);
            maxSize[1] += pixelLineHeight;
        } else if (style.textWrapping == .character) {
            minSize = @max(minSize, advance);
            maxSize[1] += pixelLineHeight;
        } else if (style.textWrapping == .none) {
            minSize = cursor;
        }
    }
    maxSize[0] = cursor[0];

    const parentZ = if (parentOptional) |parent|
        parent.z
    else
        0;

    var hasher = std.hash.Wyhash.init(0);
    hasher.update(content);
    hasher.update(std.mem.asBytes(&result.index));
    result.ptr.key = hasher.final();
    result.ptr.position = @splat(0.0);
    result.ptr.z = if (parentZ < std.math.maxInt(u16))
        parentZ + 1
    else
        parentZ;
    result.ptr.size = .{ cursor[0], pixelLineHeight };
    result.ptr.minSize = minSize;
    result.ptr.maxSize = maxSize;
    result.ptr.glyphs = Glyphs{ .slice = layoutGlyphs, .lineHeight = pixelLineHeight };
    result.ptr.style = style;

    self.frameMeta.?.previousPushedNodeIndex = result.index;

    if (parentOptional) |parent| {
        if (parent.firstChild == result.index) {
            inline for (Direction.array) |fitDirection| {
                if (parent.style.getPreferredSize(fitDirection) == .fit) {
                    parent.setSize(fitDirection, parent.fittingBase(fitDirection));
                }
                if (parent.shouldFitMin(fitDirection)) {
                    parent.setMinSize(fitDirection, parent.fittingBase(fitDirection));
                }
            }
        }
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

    var stackTrace: std.builtin.StackTrace = undefined;
    std.debug.captureStackTrace(@returnAddress(), &stackTrace);
    std.debug.print("There was an error during frame's UI mounting stage: ", .{});
    std.debug.dumpStackTrace(stackTrace);
}

fn componentEnd(block: void) void {
    _ = block;
    const self = getContext();

    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) {
        return;
    }

    if (self.frameMeta.?.componentResolutionState.pop()) |endedResolutionState| {
        const componentKey = endedResolutionState.key;
        if (self.componentStates.get(componentKey)) |componentStates| {
            if (endedResolutionState.useStateCursor != componentStates.items.len) {
                handleFrameError(error.RulesOfHooksViolated);
            }
        }
    }
}

pub fn component(key: []const u8) *const fn (void) void {
    const self = getContext();

    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err != null) {
        return &endNoop;
    }

    var hasher = std.hash.Wyhash.init(0);
    hasher.update(key);
    if (self.frameMeta.?.previousPushedNodeIndex) |previousPushedNodeIndex| {
        hasher.update(std.mem.asBytes(&previousPushedNodeIndex));
    }
    hasher.update(std.mem.asBytes(&self.frameMeta.?.componentIndex));
    const componentKey = hasher.final();

    self.frameMeta.?.componentIndex += 1;

    self.frameMeta.?.componentResolutionState.append(self.frameMeta.?.arena, .{
        .key = componentKey,
        .useStateCursor = 0,
    }) catch |err| {
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

    layouting.refitAncetors(parent, &self.nodeTree);

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

pub fn pushEvent(key: u64, event: Event) !void {
    const self = getContext();
    const result = try self.pendingEventQueue.getOrPut(key);
    if (!result.found_existing) {
        result.value_ptr.* = try std.ArrayList(Event).initCapacity(self.allocator, 1);
    }
    try result.value_ptr.*.append(self.allocator, event);
}

pub fn useScrolling() Vec2 {
    const self = getContext();
    return self.scrollPosition;
}

/// Returns the next event in the queue to handle for the current element key.
pub fn useNextEvent() ?Event {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.previousPushedNodeIndex) |previousPushedNodeIndex| {
        const previousPushedNode = self.nodeTree.at(previousPushedNodeIndex);
        const key = previousPushedNode.key;
        // std.log.debug("handling events for {}", .{key});
        if (self.pendingEventQueue.getPtr(key)) |eventQueue| {
            return eventQueue.pop();
        }
    }
    return null;
}

/// Returns and consumes a matching event from the current element's pending
/// event queue. Must be called inside an element body block.
pub fn on(comptime eventTag: std.meta.Tag(Event)) ?Event {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);

    const currentNodeIndex = self.frameMeta.?.nodeParentStack.getLastOrNull() orelse return null;
    const currentNode = self.nodeTree.at(currentNodeIndex);
    const key = currentNode.key;

    const eventQueue = self.pendingEventQueue.getPtr(key) orelse return null;

    for (eventQueue.items, 0..) |event, i| {
        if (std.meta.activeTag(event) == eventTag) {
            return eventQueue.orderedRemove(i);
        }
    }

    return null;
}

pub fn update() !void {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.err) |err| return err;

    const viewportSize = self.frameMeta.?.viewportSize;
    const arena = self.frameMeta.?.arena;

    var queueIterator = self.pendingEventQueue.valueIterator();
    while (queueIterator.next()) |events| {
        events.clearRetainingCapacity();
    }

    const justPressed = self.mouseButtonJustPressed;
    const justReleased = self.mouseButtonJustReleased;
    self.mouseButtonJustPressed = false;
    self.mouseButtonJustReleased = false;

    var missingHoveredKeys = try std.ArrayList(u64).initCapacity(arena, self.hoveredElementKeys.items.len);
    missingHoveredKeys.appendSliceAssumeCapacity(self.hoveredElementKeys.items);

    var uiEdges: Vec2 = @splat(0.0);
    var hoveredCursor: WindowCursor = .default;
    var topHoveredZ: ?u16 = null;

    var iterator = self.nodeTree.walk();
    while (iterator.next()) |node| {
        if (node.style.placement == .standard) {
            uiEdges = @max(uiEdges, node.position + node.size);
        }
        const mouseInContent = self.mousePosition + self.scrollPosition;
        const isMouseAfter = node.position[0] <= mouseInContent[0] and node.position[1] <= mouseInContent[1];
        const isMouseBefore = node.position[0] + node.size[0] >= mouseInContent[0] and node.position[1] + node.size[1] >= mouseInContent[1];
        const isMouseInside = isMouseAfter and isMouseBefore;

        const hoveredElementKeysIndexOpt = std.mem.indexOfScalar(u64, self.hoveredElementKeys.items, node.key);

        if (std.mem.indexOfScalar(u64, missingHoveredKeys.items, node.key)) |i| {
            _ = missingHoveredKeys.swapRemove(i);
        }

        if (isMouseInside) {
            if (topHoveredZ == null or node.z > topHoveredZ.?) {
                topHoveredZ = node.z;
                hoveredCursor = node.style.cursor;
            }

            if (hoveredElementKeysIndexOpt == null) {
                try pushEvent(node.key, .mouseOver);

                try self.hoveredElementKeys.append(self.allocator, node.key);
            }

            if (justPressed) {
                try pushEvent(node.key, .mouseDown);
                try self.mouseDownElementKeys.append(self.allocator, node.key);
            }
            if (justReleased) {
                try pushEvent(node.key, .mouseUp);
                if (std.mem.indexOfScalar(u64, self.mouseDownElementKeys.items, node.key) != null) {
                    try pushEvent(node.key, .click);
                }
            }
        } else if (hoveredElementKeysIndexOpt) |hoveredElementKeysIndex| {
            try pushEvent(node.key, .mouseOut);

            _ = self.hoveredElementKeys.swapRemove(hoveredElementKeysIndex);
        }
    }

    if (justReleased) {
        self.mouseDownElementKeys.clearRetainingCapacity();
    }

    for (missingHoveredKeys.items) |key| {
        if (std.mem.indexOfScalar(u64, self.hoveredElementKeys.items, key)) |i| {
            _ = self.hoveredElementKeys.swapRemove(i);
        }
    }

    if (self.window) |window| {
        window.setCursor(hoveredCursor, 0) catch |err| {
            std.log.err("Failed to set cursor: {}", .{err});
        };
    }

    self.viewportSize = viewportSize;

    const timestamp = timestampSeconds();
    self.deltaTime = timestamp - (self.lastUpdateTime orelse (timestamp - self.startTime));
    self.lastUpdateTime = timestamp;

    scroller(uiEdges);
}

fn scroller(uiEdges: Vec2) void {
    const self = getContext();
    // This is fine since we're not really inserting any node, so it won't clash
    // with the current root node. The only purpose of this is to use the same
    // logic here as is already implmented for actual UI code.
    component("forbear-native-scroller")({
        const viewportSize = useViewportSize();

        const identity: Vec2 = @splat(0.0);
        self.effectiveScrollPosition = @min(
            @max(self.effectiveScrollPosition, identity),
            @max(uiEdges - viewportSize, identity),
        );

        if (builtin.os.tag == .macos) {
            self.scrollPosition = self.effectiveScrollPosition;
        } else {
            const spring = SpringConfig{
                .stiffness = 320.0,
                .damping = 32.0,
                .mass = 1.0,
            };
            self.scrollPosition[0] = useSpringTransition(self.effectiveScrollPosition[0], spring);
            self.scrollPosition[1] = useSpringTransition(self.effectiveScrollPosition[1], spring);
        }
    });
}

fn timestampSeconds() f64 {
    return @as(f64, @floatFromInt(std.time.nanoTimestamp())) / std.time.ns_per_s;
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
    window.handlers.pointerButton = .{
        .function = &(struct {
            fn handler(_: *Window, _: u32, _: u32, button: u32, state: u32, data: *anyopaque) void {
                const ctx: *Context = @ptrCast(@alignCast(data));
                // 272 (0x110) = BTN_LEFT on Linux/Wayland; state 1 = pressed, 0 = released
                if (button == 272) {
                    if (state == 1) {
                        ctx.mouseButtonJustPressed = true;
                        ctx.mouseButtonPressed = true;
                    } else {
                        ctx.mouseButtonJustReleased = true;
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

    self.hoveredElementKeys.deinit(self.allocator);
    self.mouseDownElementKeys.deinit(self.allocator);

    var componentStatesIterator = self.componentStates.valueIterator();
    while (componentStatesIterator.next()) |states| {
        for (states.items) |state| {
            self.allocator.free(state);
        }
        states.deinit(self.allocator);
    }
    self.componentStates.deinit();

    var eventQueueIterator = self.pendingEventQueue.valueIterator();
    while (eventQueueIterator.next()) |events| {
        events.deinit(self.allocator);
    }
    self.pendingEventQueue.deinit();

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
    _ = std.testing.refAllDecls(@import("tests/font.test.zig"));
    _ = std.testing.refAllDecls(@import("tests/layouting.test.zig"));
    _ = std.testing.refAllDecls(@import("tests/root.test.zig"));
}
