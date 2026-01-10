const std = @import("std");

const c = @import("../c.zig").c;

pub fn init(
    width: u32,
    height: u32,
    title: [:0]const u8,
    app_id: [:0]const u8,
    allocator: std.mem.Allocator,
) !@This() {
    const windowClass = std.mem.zeroes(c.WNDCLASS);
}
