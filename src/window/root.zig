//! Exports the Window struct fit for the target OS being built for.
//!
//! Currently, what is actually used from the Window is:
//!
//! ```zig
//! width: u32
//! height: u32
//! running: bool
//! scale: u32
//! dpi: [2]u32
//!
//! fn init(width: u32, height: u32, title: [:0]const u8, app_id: [:0]const u8, allocator: std.mem.Allocator) void
//!
//! fn setResizeHandler(
//!     self: *@This(),
//!     handler: *const fn (
//!         window: *@This(),
//!         new_width: u32,
//!         new_height: u32,
//!         new_scale: u32,
//!         new_dpi: [2]u32,
//!         data: *anyopaque
//!     ),
//!     data: *anyopaque
//! ) void
//!
//! fn handleEvents(self: *@This()) !void
//!
//! fn deinit(self: *@This()) void
//! ```
//!
//! So making this cross platform, is still quite easy.
const builtin = @import("builtin");

pub const Window = if (builtin.os.tag == .macos)
    @import("macos.zig")
else if (builtin.os.tag == .linux)
    @import("linux.zig")
else
    @compileError("Unsupported OS");
