const std = @import("std");
const builtin = @import("builtin");

pub const c = @import("c.zig").c;
pub const Font = @import("font.zig");
pub const Graphics = @import("graphics.zig");
pub const Image = @import("graphics.zig").Image;
const layouting = @import("layouting.zig");
pub const layout = layouting.layout;
const nodeImport = @import("node.zig");
pub const Node = nodeImport.Node;
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

pub const Event = union(enum) {
    mouseOver,
    mouseOut,
};

const ElementEventQueue = std.AutoHashMap(u64, std.ArrayList(Event));

pub const FrameMeta = struct {
    arena: std.mem.Allocator,

    viewportSize: Vec2,
    dpi: Vec2,
    baseStyle: BaseStyle,

    err: ?anyerror = null,

    componentResolutionState: std.ArrayList(ComponentResolutionState) = .empty,

    rootNode: ?Node = null,
    previousPushedNode: ?*const Node = null,

    nodeParentStack: std.ArrayList(*Node) = .empty,
    nodePath: std.ArrayList(usize) = .empty,
};

allocator: std.mem.Allocator,

mousePosition: Vec2,
hoveredElementKeys: std.ArrayList(u64),
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
// images: std.StringHashMap(Image),

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
        .hoveredElementKeys = try std.ArrayList(u64).initCapacity(allocator, 1),
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
    if (self.frameMeta) |meta| {
        return meta.arena;
    } else {
        if (!builtin.is_test) {
            std.log.err("You might be calling a hook (useArena) outside of a frame, and forbear cannot track things outside of one.", .{});
        }
        return error.NoFrame;
    }
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

// TODO: in debug mode, we should be adding some guard rail here to make sure
// of warning the user if they called the hook in an unexpected order, as it
// can cause undefined behavior as is right now
pub fn useState(T: type, initialValue: T) !*T {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);
    if (currentComponentResolutionState()) |state| {
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

fn endNoop(block: void) void {
    _ = block;
}

fn putNode(arena: std.mem.Allocator) !struct { ptr: *Node, parent: ?*Node, index: usize } {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.nodeParentStack.getLastOrNull()) |parent| {
        std.debug.assert(self.frameMeta.?.rootNode != null);
        std.debug.assert(parent.children == .nodes);
        // How can we make sure that these asserts aren't really necessary? HOw
        // can we make sure that the compiler will ensure that the parent here
        // always allows for children?
        if (parent.children.nodes.items.len > 0) {
            return .{
                .ptr = try parent.children.nodes.addOne(arena),
                .parent = parent,
                .index = parent.children.nodes.items.len - 1,
            };
        } else {
            var children = try std.ArrayList(Node).initCapacity(arena, 1);
            defer parent.children = .{ .nodes = children };
            return .{
                .ptr = children.addOneAssumeCapacity(),
                .parent = parent,
                .index = children.items.len - 1,
            };
        }
    } else {
        if (self.frameMeta.?.rootNode != null) {
            return error.MultipleRootNodesNotSupported;
        }
        self.frameMeta.?.rootNode = Node{
            .key = undefined,

            .position = undefined,
            .z = undefined,
            .size = undefined,
            .maxSize = undefined,
            .minSize = undefined,
            .children = undefined,

            .style = undefined,
        };
        return .{
            .ptr = &self.frameMeta.?.rootNode.?,
            .parent = null,
            .index = 0,
        };
    }
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

    self.frameMeta.?.previousPushedNode = self.frameMeta.?.nodeParentStack.pop();
    _ = self.frameMeta.?.nodePath.pop();

    const node = self.frameMeta.?.previousPushedNode.?;
    if (self.frameMeta.?.nodeParentStack.getLastOrNull()) |parent| {
        parent.fitChild(node);
    }
}

pub fn element(incompleteStyle: IncompleteStyle) *const fn (void) void {
    const self = getContext();

    std.debug.assert(self.frameMeta != null);

    if (self.frameMeta.?.err != null) return &endNoop;

    const result = putNode(self.frameMeta.?.arena) catch |err| {
        handleFrameError(err);
        return &endNoop;
    };

    const baseStyle = if (result.parent) |parent|
        BaseStyle.from(parent.style)
    else
        self.frameMeta.?.baseStyle;
    var style = incompleteStyle.completeWith(baseStyle);
    const resolutionMultiplier = self.frameMeta.?.dpi / @as(Vec2, @splat(72));
    style.borderWidth.x *= @splat(resolutionMultiplier[0]);
    style.borderWidth.y *= @splat(resolutionMultiplier[1]);
    if (style.shadow) |*shadow| {
        shadow.offset.x *= @splat(resolutionMultiplier[0]);
        shadow.offset.y *= @splat(resolutionMultiplier[1]);
        shadow.blurRadius *= resolutionMultiplier[0];
        shadow.spread *= resolutionMultiplier[0];
    }
    style.padding.x *= @splat(resolutionMultiplier[0]);
    style.padding.y *= @splat(resolutionMultiplier[1]);
    style.margin.x *= @splat(resolutionMultiplier[0]);
    style.margin.y *= @splat(resolutionMultiplier[1]);
    style.borderRadius *= resolutionMultiplier[0];

    const parentZ = if (result.parent) |parent|
        parent.z
    else
        0;

    var hasher = std.hash.Wyhash.init(0);
    hasher.update(std.mem.sliceAsBytes(self.frameMeta.?.nodePath.items));
    hasher.update(std.mem.asBytes(&result.index));
    result.ptr.* = .{
        .key = hasher.final(),
        .style = style,
        .children = .{ .nodes = .empty },
        .z = if (incompleteStyle.zIndex) |zIndex|
            zIndex
        else if (parentZ < std.math.maxInt(u16))
            parentZ + 1
        else
            parentZ,
        .position = if (style.placement == .manual)
            style.placement.manual
        else
            @splat(0.0),
        .size = .{
            switch (style.width) {
                .fixed => |width| width,
                .percentage => 0.0,
                .ratio => |ratio| if (style.height == .fixed)
                    style.height.fixed * ratio
                else
                    0.0,
                .fit, .grow => 0.0,
            },
            switch (style.height) {
                .fixed => |height| height,
                .percentage => 0.0,
                .ratio => |ratio| if (style.width == .fixed)
                    style.width.fixed * ratio
                else
                    0.0,
                .fit, .grow => 0.0,
            },
        },
        .minSize = .{
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
        },
        .maxSize = .{
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
        },
    };
    self.frameMeta.?.nodeParentStack.append(self.frameMeta.?.arena, result.ptr) catch |err| {
        handleFrameError(err);
        return &endNoop;
    };
    self.frameMeta.?.nodePath.append(self.frameMeta.?.arena, result.index) catch |err| {
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

    return &elementEnd;
}

pub fn text(content: []const u8) void {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);

    if (self.frameMeta.?.err != null) return;

    const arena = self.frameMeta.?.arena;
    const result = putNode(arena) catch |err| {
        handleFrameError(err);
        return;
    };

    const resolutionMultiplier = self.frameMeta.?.dpi / @as(Vec2, @splat(72));

    const baseStyle = if (result.parent) |parent|
        BaseStyle.from(parent.style)
    else
        self.frameMeta.?.baseStyle;

    const style = (IncompleteStyle{
        .cursor = if (baseStyle.cursor == .default)
            .text
        else
            baseStyle.cursor,
        .alignment = if (result.parent) |parent| .{
            .x = parent.style.alignment.x,
            .y = .start,
        } else null,
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

    const parentZ = if (result.parent) |parent|
        parent.z
    else
        0;

    var hasher = std.hash.Wyhash.init(0);
    hasher.update(content);
    hasher.update(std.mem.sliceAsBytes(self.frameMeta.?.nodePath.items));
    hasher.update(std.mem.asBytes(&result.index));
    result.ptr.* = Node{
        .key = hasher.final(),
        .position = .{ 0.0, 0.0 },
        .z = if (parentZ < std.math.maxInt(u16))
            parentZ + 1
        else
            parentZ,
        .size = .{ cursor[0], pixelLineHeight },
        .minSize = minSize,
        .maxSize = maxSize,
        .children = .{ .glyphs = Glyphs{ .slice = layoutGlyphs, .lineHeight = pixelLineHeight } },
        .style = style,
    };

    self.frameMeta.?.previousPushedNode = result.ptr;

    if (result.parent) |parent| {
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
    hasher.update(std.mem.sliceAsBytes(self.frameMeta.?.nodePath.items));
    const componentKey = hasher.final();

    self.frameMeta.?.componentResolutionState.append(self.frameMeta.?.arena, .{
        .key = componentKey,
        .useStateCursor = 0,
    }) catch |err| {
        handleFrameError(err);
        return endNoop;
    };

    return &componentEnd;
}

pub fn pushEvent(key: u64, event: Event) !void {
    const self = getContext();
    const result = try self.pendingEventQueue.getOrPut(key);
    if (!result.found_existing) {
        result.value_ptr.* = try std.ArrayList(Event).initCapacity(self.allocator, 1);
    }
    try result.value_ptr.*.append(self.allocator, event);
}

/// Returns the next event in the queue to handle for the current element key.
pub fn useNextEvent() ?Event {
    const self = getContext();
    std.debug.assert(self.frameMeta != null);
    if (self.frameMeta.?.previousPushedNode) |previous| {
        const key = previous.key;
        // std.log.debug("handling events for {}", .{key});
        if (self.pendingEventQueue.getPtr(key)) |eventQueue| {
            return eventQueue.pop();
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

    if (self.frameMeta.?.rootNode) |*root| {
        var queueIterator = self.pendingEventQueue.valueIterator();
        while (queueIterator.next()) |events| {
            events.clearRetainingCapacity();
        }

        var iterator = try layouting.LayoutTreeIterator.init(arena, root);

        var missingHoveredKeys = try std.ArrayList(u64).initCapacity(arena, self.hoveredElementKeys.items.len);
        missingHoveredKeys.appendSliceAssumeCapacity(self.hoveredElementKeys.items);

        var uiEdges: Vec2 = @splat(0.0);
        var hoveredCursor: WindowCursor = .default;
        var topHoveredZ: ?u16 = null;

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
                if (topHoveredZ == null or layoutBox.z > topHoveredZ.?) {
                    topHoveredZ = layoutBox.z;
                    hoveredCursor = layoutBox.style.cursor;
                }

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

        if (self.window) |window| {
            window.setCursor(hoveredCursor, 0) catch |err| {
                std.log.err("Failed to set cursor: {}", .{err});
            };
        }

        self.viewportSize = viewportSize;

        const timestamp = timestampSeconds();
        self.deltaTime = timestamp - (self.lastUpdateTime orelse (timestamp - self.startTime));
        self.lastUpdateTime = timestamp;

        try scroller(uiEdges);
    }
}

fn scroller(uiEdges: Vec2) !void {
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
            self.scrollPosition[0] = try useSpringTransition(self.effectiveScrollPosition[0], spring);
            self.scrollPosition[1] = try useSpringTransition(self.effectiveScrollPosition[1], spring);
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
