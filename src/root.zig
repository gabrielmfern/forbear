const std = @import("std");

pub const c = @import("c.zig").c;
pub const Font = @import("font.zig");
pub const Graphics = @import("graphics.zig");
pub const Image = @import("graphics.zig").Image;
const layouting = @import("layouting.zig");
pub const layout = layouting.layout;
pub const Layoutbox = layouting.LayoutBox;
const node = @import("node.zig");
pub const Node = node.Node;
pub const Element = node.Element;
pub const ElementProps = node.DivProps;
pub const div = node.div;
pub const children = node.children;
pub const Window = @import("window/root.zig").Window;

// var context: ?@This() = null;
//
// pub fn init() !@This() {
//     if (context) {
//         return error.AlreadyInitialized;
//     }
//
//     context = @This(){};
//     return context.?;
// }
//
// pub fn deinit(self: @This()) void {
//     _ = self;
// }
//
// pub fn getContext() *@This() {
//     return context;
// }
