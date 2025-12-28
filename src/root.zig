const std = @import("std");
pub const Graphics = @import("graphics.zig");
pub const Window = @import("window/root.zig");

pub const c = @import("c.zig").c;

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
