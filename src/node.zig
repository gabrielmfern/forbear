const std = @import("std");

const forbear = @import("root.zig");
const Font = @import("font.zig");
const Graphics = @import("graphics.zig");
const LayoutBox = @import("layouting.zig").LayoutBox;

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
    grow,
};

pub const Shadow = struct {
    offsetBlock: Vec2,
    offsetInline: Vec2,
    blurRadius: f32,
    spread: f32,
    color: Vec4,
};

pub const Alignment = enum {
    start,
    center,
    end,
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

pub const Style = struct {
    background: Background,
    color: Vec4,
    borderRadius: f32,
    borderColor: Vec4,
    borderBlockWidth: Vec2,
    borderInlineWidth: Vec2,

    shadow: ?Shadow = null,

    font: *Font,
    /// Will do nothing if the font is not a variable font. If you don't have a
    /// variable font, you should use differnet fonts for different weights.
    fontWeight: u32,
    fontSize: u32,
    lineHeight: f32,
    textWrapping: TextWrapping,

    placement: Placement,
    zIndex: ?u16 = null,

    minWidth: ?f32 = null,
    preferredWidth: Sizing,
    minHeight: ?f32 = null,
    preferredHeight: Sizing,

    translate: Vec2,

    paddingInline: Vec2,
    paddingBlock: Vec2,
    marginInline: Vec2,
    marginBlock: Vec2,

    direction: Direction,
    horizontalAlignment: Alignment,
    verticalAlignment: Alignment,

    pub fn getPreferredSize(self: @This(), direction: Direction) Sizing {
        if (direction == .leftToRight) {
            return self.preferredWidth;
        }
        return self.preferredHeight;
    }
};

pub const BaseStyle = struct {
    font: *Font,
    color: Vec4,
    fontSize: u32,
    fontWeight: u32,
    lineHeight: f32,
    textWrapping: TextWrapping,

    pub fn from(style: Style) @This() {
        return @This(){
            .font = style.font,
            .color = style.color,
            .fontSize = style.fontSize,
            .fontWeight = style.fontWeight,
            .lineHeight = style.lineHeight,
            .textWrapping = style.textWrapping,
        };
    }
};

pub const LinearGradient = extern struct {
    pub const Stop = extern struct {
        /// percentage
        start: f32,
        color: Vec4,
        /// used as a flag to ignore the remaining steps
        startIgnoring: i32 = 0,

        pub fn ignore() @This() {
            return .{
                .start = 0.0,
                .color = .{ 0.0, 0.0, 0.0, 0.0 },
                .startIgnoring = 1,
            };
        }
    };

    pub fn none() @This() {
        return .{
            .angle = 0.0,
            .stops = .{Stop.ignore()} ** 16,
        };
    }

    /// Radians for the direction at which the gradient propagates
    angle: f32,
    stops: [16]Stop,
};

pub fn linearGradient(angle: f32, definition: anytype) LinearGradient {
    var stops: [16]LinearGradient.Stop = .{LinearGradient.Stop.ignore()} ** 16;

    const DefType = @TypeOf(definition);
    const type_info = @typeInfo(DefType);

    if (type_info == .@"struct" and type_info.@"struct".is_tuple) {
        const fields = type_info.@"struct".fields;
        if (fields.len > 16) {
            std.log.warn("Gradients can only have 16 steps, this one has {d}, the remaining ones will be ignored", .{fields.len});
        }
        inline for (0..fields.len) |i| {
            if (i < 16) {
                const entry = definition[i];
                stops[i] = .{
                    .start = entry.start,
                    .color = entry.color,
                    .startIgnoring = if (@hasField(@TypeOf(entry), "startIgnoring")) entry.startIgnoring else 0,
                };
            }
        }
    } else {
        if (definition.len > 16) {
            std.log.warn("Gradients can only have 16 steps, this one has {d}, the remaining ones will be ignored", .{definition.len});
        }
        for (0..16) |i| {
            if (i < definition.len) {
                stops[i] = definition[i];
            }
        }
    }

    return .{
        .angle = angle,
        .stops = stops,
    };
}

test "linearGradient" {
    try std.testing.expectEqualDeep(
        LinearGradient{
            .angle = std.math.pi / 2.0,
            .stops = .{
                .{
                    .start = 0.0,
                    .color = .{ 1.0, 0.0, 0.0, 1.0 },
                },
                .{
                    .start = 1 / 3,
                    .color = .{ 0.0, 1.0, 0.0, 1.0 },
                },
                .{
                    .start = 2 / 3,
                    .color = .{ 0.0, 0.0, 1.0, 1.0 },
                },
                .ignore(),
                .ignore(),
                .ignore(),
                .ignore(),
                .ignore(),
                .ignore(),
                .ignore(),
                .ignore(),
                .ignore(),
                .ignore(),
                .ignore(),
                .ignore(),
                .ignore(),
            },
        },
        linearGradient(std.math.pi / 2.0, .{
            .{
                .start = 0.0,
                .color = .{ 1.0, 0.0, 0.0, 1.0 },
            },
            .{
                .start = 1 / 3,
                .color = .{ 0.0, 1.0, 0.0, 1.0 },
            },
            .{
                .start = 2 / 3,
                .color = .{ 0.0, 0.0, 1.0, 1.0 },
            },
        }),
    );
}

pub const Background = union(enum) {
    image: *const Graphics.Image,
    gradient: LinearGradient,
    color: Vec4,
};

pub const Placement = union(enum) {
    /// When defined, explictily overrides layout positioning, taking it
    /// outside of the normal element flow, it won't affect the sizing of its
    /// parent, nor the placement of its siblings. To define width and height,
    /// use preferredWidth and preferredHeight.
    manual: Vec2,
    standard,
};

pub const IncompleteStyle = struct {
    background: ?Background = null,
    color: ?Vec4 = null,
    borderRadius: ?f32 = null,
    borderColor: ?Vec4 = null,
    borderBlockWidth: ?Vec2 = null,
    borderInlineWidth: ?Vec2 = null,

    shadow: ?Shadow = null,

    font: ?*Font = null,
    fontWeight: ?u32 = null,
    fontSize: ?u32 = null,
    lineHeight: ?f32 = null,
    textWrapping: ?TextWrapping = null,

    placement: Placement = .standard,
    zIndex: ?u16 = null,

    minWidth: ?f32 = null,
    preferredWidth: Sizing = .fit,
    minHeight: ?f32 = null,
    preferredHeight: Sizing = .fit,

    translate: ?Vec2 = null,

    paddingInline: ?Vec2 = null,
    paddingBlock: ?Vec2 = null,
    marginInline: ?Vec2 = null,
    marginBlock: ?Vec2 = null,

    horizontalAlignment: ?Alignment = null,
    verticalAlignment: ?Alignment = null,
    direction: ?Direction = null,

    pub fn completeWith(self: @This(), base: BaseStyle) Style {
        return Style{
            .background = self.background orelse .{ .color = Vec4{ 0.0, 0.0, 0.0, 0.0 } },
            .color = self.color orelse base.color,

            .borderRadius = self.borderRadius orelse 0.0,
            .borderColor = self.borderColor orelse Vec4{ 0.0, 0.0, 0.0, 0.0 },
            .borderBlockWidth = self.borderBlockWidth orelse @splat(0.0),
            .borderInlineWidth = self.borderInlineWidth orelse @splat(0.0),

            .shadow = self.shadow,

            .font = self.font orelse base.font,
            .fontWeight = self.fontWeight orelse base.fontWeight,
            .fontSize = self.fontSize orelse base.fontSize,
            .lineHeight = self.lineHeight orelse base.lineHeight,
            .textWrapping = self.textWrapping orelse base.textWrapping,

            .placement = self.placement,
            .zIndex = self.zIndex,

            .minWidth = self.minWidth,
            .preferredWidth = self.preferredWidth,

            .minHeight = self.minHeight,
            .preferredHeight = self.preferredHeight,

            .translate = self.translate orelse @splat(0.0),

            .paddingInline = self.paddingInline orelse @splat(0.0),
            .paddingBlock = self.paddingBlock orelse @splat(0.0),
            .marginInline = self.marginInline orelse @splat(0.0),
            .marginBlock = self.marginBlock orelse @splat(0.0),

            .direction = self.direction orelse .leftToRight,
            .horizontalAlignment = self.horizontalAlignment orelse .start,
            .verticalAlignment = self.verticalAlignment orelse .start,
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
