//! Exports the Window struct fit for the target OS being built for.
//!
//! Currently, what is actually used from the Window is:
//!
//! ```zig
//! width: u32
//! height: u32
//! running: bool
//! dpi: [2]u32
//!
//! fn init(allocator: std.mem.Allocator, width: u32, height: u32, title: [:0]const u8, app_id: [:0]const u8) void
//!
//! fn targetFrameTimeNs() u64;
//!
//! const Cursor = enum {
//!     default,
//!     text,
//!     pointer,
//! };
//!
//! fn setCursor(self: *@This(), cursor: Cursor, serial: u32) !void
//!
//! fn setResizeHandler(
//!     self: *@This(),
//!     handler: *const fn (
//!         window: *@This(),
//!         newWidth: u32,
//!         newHeight: u32,
//!         newDpi: [2]u32,
//!         data: *anyopaque,
//!     ) void,
//!     data: *anyopaque,
//! ) void
//!
//! fn handleEvents(self: *@This()) !void
//!
//! fn deinit(self: *@This()) void
//! ```
//!
//! So making this cross platform, is still quite easy.
const builtin = @import("builtin");

pub const Cursor = @import("cursor.zig").Cursor;

pub const Window = switch (builtin.os.tag) {
    .linux => @import("linux.zig"),
    .windows => @import("windows.zig"),
    .macos => @import("macos.zig"),
    else => @compileError("Unsupported OS"),
};
