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

pub const Cursor = enum {
    default,
    text,
    pointer,
};

/// Cross-platform key identity. Backends translate their native key code
/// (XKB keysym on Linux, virtual-key code on Windows, etc.) into one of
/// these. Layout-dependent keys (letters/digits) reflect the *typed*
/// character — on AZERTY the physical Q key reports `.a`.
///
/// Any key a backend can't classify reports `.unknown`. Extend this enum
/// when adding support for new keys; never invent a new variant in a
/// single backend.
pub const Key = enum {
    unknown,

    // Letters
    a, b, c, d, e, f, g, h, i, j, k, l, m,
    n, o, p, q, r, s, t, u, v, w, x, y, z,

    // Top-row digits
    digit_0, digit_1, digit_2, digit_3, digit_4,
    digit_5, digit_6, digit_7, digit_8, digit_9,

    // Function keys
    f1,  f2,  f3,  f4,  f5,  f6,
    f7,  f8,  f9,  f10, f11, f12,

    // Modifiers
    shift_left,   shift_right,
    control_left, control_right,
    alt_left,     alt_right,
    super_left,   super_right,
    caps_lock,

    // Navigation
    arrow_left, arrow_right, arrow_up, arrow_down,
    home, end, page_up, page_down,

    // Editing & misc
    tab, escape, enter, space,
    backspace, delete, insert,
};

pub const KeyboardKey = struct {
    /// Platform-native event timestamp. Semantics vary by backend (ms since
    /// compositor epoch on Wayland, etc.); use it only for relative timing.
    /// 0 for synthetic repeats.
    time: u32,
    /// Cross-platform key identity. `.unknown` if the backend reported a
    /// key this enum doesn't cover yet.
    key: Key,
    /// UTF-8 of the character this key produced under the current layout and
    /// modifier state. Empty when the key has no textual interpretation
    /// (Shift, F1, arrows, ...). For Tab it's `"\t"`, Enter is `"\r"`, etc.
    /// Slice is valid only for the duration of the handler call — copy if
    /// you need to keep it.
    text: []const u8 = "",
    /// True only for `keydown` events synthesized while the key is held.
    /// Always false for `keypress` and `keyup`.
    is_repeat: bool,
};

pub const Window = switch (builtin.os.tag) {
    .linux => @import("linux.zig"),
    .windows => @import("windows.zig"),
    .macos => @import("macos.zig"),
    else => @compileError("Unsupported OS"),
};
