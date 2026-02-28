const std = @import("std");

const forbear = @import("root.zig");
const Font = @import("font.zig");
const Graphics = @import("graphics.zig");
const LayoutBox = @import("layouting.zig").LayoutBox;
const Cursor = @import("window/root.zig").Cursor;

const Vec4 = @Vector(4, f32);
const Vec2 = @Vector(2, f32);

pub const Direction = enum {
    leftToRight,
    topToBottom,

    pub fn perpendicular(self: @This()) @This() {
        return switch (self) {
            .leftToRight => .topToBottom,
            .topToBottom => .leftToRight,
        };
    }
};

pub const Sizing = union(enum) {
    fit,
    fixed: f32,
    /// A ratio with respect to the parent axis (e.g. 0.5 = 50% of parent width/height).
    percentage: f32,
    /// A ratio with respect to the opposite axis.
    ratio: f32,
    grow,
};

pub const Shadow = struct {
    pub const Offset = Padding;

    offset: Offset,
    blurRadius: f32,
    spread: f32,
    color: Vec4,
};

pub const Alignment = struct {
    const Value = enum {
        start,
        center,
        end,
    };

    x: Value,
    y: Value,

    pub const topLeft = @This(){
        .x = .start,
        .y = .start,
    };

    pub const topCenter = @This(){
        .x = .center,
        .y = .start,
    };

    pub const topRight = @This(){
        .x = .end,
        .y = .start,
    };

    pub const centerLeft = @This(){
        .x = .start,
        .y = .center,
    };

    /// Centered across all axis
    pub const center = @This(){
        .x = .center,
        .y = .center,
    };

    pub const centerRight = @This(){
        .x = .end,
        .y = .center,
    };

    pub const bottomLeft = @This(){
        .x = .start,
        .y = .end,
    };

    pub const bottomCenter = @This(){
        .x = .center,
        .y = .end,
    };

    pub const bottomRight = @This(){
        .x = .end,
        .y = .end,
    };
};

/// Will modify the min size of layout boxes that wrap text accordingly
/// character => largest character
/// word => largest word
/// none => all in one line
pub const TextWrapping = enum {
    character,
    /// Uses a simple greedy algorithm to break on word boundaries
    word,
    none,
};

pub const Padding = struct {
    x: Vec2,
    y: Vec2,

    pub fn get(self: @This(), direction: Direction) Vec2 {
        return switch (direction) {
            .leftToRight => self.x,
            .topToBottom => self.y,
        };
    }

    pub inline fn all(value: f32) @This() {
        return .{
            .x = @splat(value),
            .y = @splat(value),
        };
    }

    /// `inLine` because `inline` is a reserved keyword in Zig
    pub inline fn inLine(value: f32) @This() {
        return .{
            .x = @splat(value),
            .y = @splat(0.0),
        };
    }

    pub fn withInLine(self: @This(), value: f32) @This() {
        return .{
            .x = @splat(value),
            .y = self.y,
        };
    }

    pub inline fn block(value: f32) @This() {
        return .{
            .x = @splat(0.0),
            .y = @splat(value),
        };
    }

    pub fn withBlock(self: @This(), value: f32) @This() {
        return .{
            .x = self.x,
            .y = @splat(value),
        };
    }

    pub inline fn left(value: f32) @This() {
        return .{
            .x = .{ value, 0.0 },
            .y = @splat(0.0),
        };
    }

    pub fn withLeft(self: @This(), value: f32) @This() {
        return .{
            .x = .{ value, self.x[1] },
            .y = self.y,
        };
    }

    pub inline fn right(value: f32) @This() {
        return .{
            .x = .{ 0.0, value },
            .y = @splat(0.0),
        };
    }

    pub fn withRight(self: @This(), value: f32) @This() {
        return .{
            .x = .{ self.x[0], value },
            .y = self.y,
        };
    }

    pub inline fn top(value: f32) @This() {
        return .{
            .x = @splat(0.0),
            .y = .{ value, 0.0 },
        };
    }

    pub fn withTop(self: @This(), value: f32) @This() {
        return .{
            .x = self.x,
            .y = .{ value, self.y[1] },
        };
    }

    pub inline fn bottom(value: f32) @This() {
        return .{
            .x = @splat(0.0),
            .y = .{ 0.0, value },
        };
    }

    pub fn withBottom(self: @This(), value: f32) @This() {
        return .{
            .x = self.x,
            .y = .{ self.y[0], value },
        };
    }
};

pub const Margin = Padding;

pub const BorderWidth = Padding;

pub const BlendMode = enum(u32) {
    normal = 0,
    multiply = 1,
};

pub const Style = struct {
    background: Background,
    blendMode: BlendMode,

    color: Vec4,
    borderRadius: f32,
    borderColor: Vec4,
    borderWidth: BorderWidth,

    shadow: ?Shadow = null,

    font: *Font,
    /// Will do nothing if the font is not a variable font. If you don't have a
    /// variable font, you should use different fonts for different weights.
    fontWeight: u32,
    fontSize: f32,
    lineHeight: f32,
    textWrapping: TextWrapping,
    cursor: Cursor,

    placement: Placement,
    zIndex: ?u16 = null,

    minWidth: ?f32 = null,
    maxWidth: ?f32 = null,
    width: Sizing,
    maxHeight: ?f32 = null,
    minHeight: ?f32 = null,
    height: Sizing,

    translate: Vec2,

    padding: Padding,
    margin: Margin,

    direction: Direction,
    alignment: Alignment,

    pub fn getPreferredSize(self: @This(), direction: Direction) Sizing {
        if (direction == .leftToRight) {
            return self.width;
        }
        return self.height;
    }

    pub fn getMinSize(self: @This(), direction: Direction) ?f32 {
        if (direction == .leftToRight) {
            return self.minWidth;
        }
        return self.minHeight;
    }
};

pub const BaseStyle = struct {
    font: *Font,
    color: Vec4,
    fontSize: f32,
    fontWeight: u32,
    lineHeight: f32,
    textWrapping: TextWrapping,
    blendMode: BlendMode,
    cursor: Cursor,

    pub fn from(style: Style) @This() {
        return @This(){
            .font = style.font,
            .color = style.color,
            .fontSize = style.fontSize,
            .fontWeight = style.fontWeight,
            .lineHeight = style.lineHeight,
            .textWrapping = style.textWrapping,
            .blendMode = style.blendMode,
            .cursor = style.cursor,
        };
    }
};

pub const Background = union(enum) {
    image: *Graphics.Image,
    color: Vec4,
};

pub const Placement = union(enum) {
    /// When defined, explictily overrides layout positioning, taking it
    /// outside of the normal element flow, it won't affect the sizing of its
    /// parent, nor the placement of its siblings. To define width and height,
    /// use width and height.
    manual: Vec2,
    standard,
};

pub const IncompleteStyle = struct {
    background: ?Background = null,
    blendMode: ?BlendMode = null,

    color: ?Vec4 = null,
    borderRadius: ?f32 = null,
    borderColor: ?Vec4 = null,
    borderWidth: ?BorderWidth = null,

    shadow: ?Shadow = null,

    font: ?*Font = null,
    fontWeight: ?u32 = null,
    fontSize: ?f32 = null,
    lineHeight: ?f32 = null,
    textWrapping: ?TextWrapping = null,
    cursor: ?Cursor = null,

    placement: Placement = .standard,
    zIndex: ?u16 = null,

    minWidth: ?f32 = null,
    maxWidth: ?f32 = null,
    width: Sizing = .fit,
    minHeight: ?f32 = null,
    maxHeight: ?f32 = null,
    height: Sizing = .fit,

    translate: ?Vec2 = null,

    padding: ?Padding = null,
    margin: ?Margin = null,

    alignment: ?Alignment = null,
    direction: ?Direction = null,

    pub fn completeWith(self: @This(), base: BaseStyle) Style {
        return Style{
            .background = self.background orelse .{ .color = Vec4{ 0.0, 0.0, 0.0, 0.0 } },
            .blendMode = self.blendMode orelse base.blendMode,

            .color = self.color orelse base.color,

            .borderRadius = self.borderRadius orelse 0.0,
            .borderColor = self.borderColor orelse Vec4{ 0.0, 0.0, 0.0, 0.0 },
            .borderWidth = self.borderWidth orelse .all(0.0),

            .shadow = self.shadow,

            .font = self.font orelse base.font,
            .fontWeight = self.fontWeight orelse base.fontWeight,
            .fontSize = self.fontSize orelse base.fontSize,
            .lineHeight = self.lineHeight orelse base.lineHeight,
            .textWrapping = self.textWrapping orelse base.textWrapping,
            .cursor = self.cursor orelse base.cursor,

            .placement = self.placement,
            .zIndex = self.zIndex,

            .minWidth = self.minWidth,
            .maxWidth = self.maxWidth,
            .width = self.width,

            .minHeight = self.minHeight,
            .maxHeight = self.maxHeight,
            .height = self.height,

            .translate = self.translate orelse @splat(0.0),

            .padding = self.padding orelse .all(0.0),
            .margin = self.margin orelse .all(0.0),

            .direction = self.direction orelse .leftToRight,
            .alignment = self.alignment orelse Alignment.topLeft,
        };
    }
};

pub const Node = struct {
    key: u64,
    content: union(enum) {
        element: Element,
        text: []const u8,
    },
};

pub const Component = struct {
    function: *const fn (props: ?*anyopaque) anyerror!Node,
    /// Integer associated with the static pointer to the component's function
    id: usize,
    props: *anyopaque,
};

pub const Element = struct {
    style: IncompleteStyle,
    children: std.ArrayList(Node) = .empty,
};
