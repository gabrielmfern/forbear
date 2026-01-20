const std = @import("std");

pub const c = @import("c.zig").c;
pub const Font = @import("font.zig");
pub const Graphics = @import("graphics.zig");
pub const Image = @import("graphics.zig").Image;
const layouting = @import("layouting.zig");
pub const layout = layouting.layout;
pub const LayoutBox = layouting.LayoutBox;
const node = @import("node.zig");
pub const Node = node.Node;
pub const Element = node.Element;
pub const ElementProps = node.DivProps;
pub const div = node.div;
pub const children = node.children;
pub const Window = @import("window/root.zig").Window;

const Vec2 = @Vector(2, f32);

const Context = @This();

var context: ?@This() = null;

mousePosition: Vec2,
hoveredElementKey: ?u64,

pub fn init() !@This() {
    if (context != null) {
        return error.AlreadyInitialized;
    }

    context = @This(){
        .mousePosition = .{ 0.0, 0.0 },
        .hoveredElementKey = null,
    };
    return context.?;
}

pub fn update(self: *@This(), root: *const LayoutBox, arena: std.mem.Allocator) !void {
    var iterator = try layouting.LayoutTreeIterator.init(arena, root);
    var previouslyHoveredLayoutBox: ?*const LayoutBox = null;

    var highestHoveredLayoutBox: ?*const LayoutBox = null;
    while (try iterator.next()) |layoutBox| {
        if (layoutBox.position[0] <= self.mousePosition[0] and layoutBox.position[1] <= self.mousePosition[1] and layoutBox.position[0] + layoutBox.size[0] >= self.mousePosition[0] and layoutBox.position[1] + layoutBox.size[1] >= self.mousePosition[1]) {
            if (highestHoveredLayoutBox) |hoveredBox| {
                if (layoutBox.z > hoveredBox.z) {
                    highestHoveredLayoutBox = layoutBox;
                }
            } else {
                highestHoveredLayoutBox = layoutBox;
            }
        }
        if (layoutBox.key == self.hoveredElementKey) {
            previouslyHoveredLayoutBox = layoutBox;
        }
    }
    if (highestHoveredLayoutBox) |hoveredBox| {
        if (hoveredBox.key != self.hoveredElementKey) {
            if (previouslyHoveredLayoutBox) |prevBox| {
                if (prevBox.handlers.onMouseOut) |onMouseOut| {
                    try onMouseOut.handler(self.mousePosition, onMouseOut.data);
                }
            }
        }
        if (hoveredBox.handlers.onMouseOver) |onMouseOver| {
            try onMouseOver.handler(self.mousePosition, onMouseOver.data);
            self.hoveredElementKey = hoveredBox.key;
        }
    } else if (previouslyHoveredLayoutBox) |prevBox| {
        if (prevBox.handlers.onMouseOut) |onMouseOut| {
            try onMouseOut.handler(self.mousePosition, onMouseOut.data);
            self.hoveredElementKey = null;
        }
    }
}

pub fn setHandlers(self: *@This(), window: *Window) void {
    window.setPointerMotion(
        &(struct {
            fn handler(_: *Window, time: u32, x: i32, y: i32, data: *anyopaque) void {
                _ = time;
                const ctx: *Context = @ptrCast(@alignCast(data));
                ctx.mousePosition = .{ @floatFromInt(x), @floatFromInt(y) };
            }
        }).handler,
        @ptrCast(@alignCast(self)),
    );
}

pub fn deinit(self: @This()) void {
    _ = self;
    context = null;
}

pub fn getContext() *@This() {
    return context;
}
