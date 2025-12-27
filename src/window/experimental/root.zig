const std = @import("std");
const posix = std.posix;
const os = std.os;
const builtin = @import("builtin");

const WaylandWindow = @import("wayland.zig");
const MacosWinodw = @import("macos.zig");

const Self = @This();

const NativeWindow = switch (builtin.os.tag) {
    .linux => WaylandWindow,
    .macos => MacosWinodw,
    else => @compileError("Unsupported OS"),
};

// Window state
width: *const u32,
height: *const u32,
running: *const bool,
title: *const [:0]const u8,
app_id: *const [:0]const u8,
allocator: std.mem.Allocator,

handle: *NativeWindow,

pub fn init(
    width: u32,
    height: u32,
    title: [:0]const u8,
    app_id: [:0]const u8,
    allocator: std.mem.Allocator,
) !*Self {
    const window = try allocator.create(Self);
    errdefer allocator.destroy(window);

    window.allocator = allocator;

    window.handle = try NativeWindow.init(width, height, title, app_id, allocator);

    window.width = &window.handle.width;
    window.height = &window.handle.height;
    window.running = &window.handle.running;
    window.title = &window.handle.title;
    if (builtin.os.tag == .linux) {
        window.app_id = &window.handle.app_id;
    }

    return window;
}

pub const Cursor = enum {
    default,
    text,
    pointer,
};

pub fn setResizeHandler(
    self: *Self,
    handler: *const fn (window: *NativeWindow, new_width: u32, new_height: u32, data: *anyopaque) void,
    data: *anyopaque,
) void {
    self.handle.setResizeHandler(handler, data);
}

pub fn setCursor(self: *Self, cursor: Cursor, serial: u32) !void {
    return self.handle.setCursor(cursor, serial);
}

pub fn handleEvents(self: *Self) !void {
    return self.handle.handleEvents();
}

pub fn deinit(self: *Self) void {
    self.handle.deinit();
    self.allocator.destroy(self);
}
