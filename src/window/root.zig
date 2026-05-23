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
const std = @import("std");
const builtin = @import("builtin");

/// Tiny spin-lock used by Window backends to guard the keyboard
/// snapshot fields between the input thread and Forbear's render thread.
/// Critical sections are sub-microsecond (a few bit ops + a memcpy
/// bounded by `textInputBuf.len`), so spinning beats parking — and
/// Zig 0.16's blocking `std.Io.Mutex` would force us to thread `Io`
/// down into the windowing backends.
pub const SpinLock = struct {
    inner: std.atomic.Mutex = .unlocked,

    pub fn lock(self: *SpinLock) void {
        while (!self.inner.tryLock()) std.atomic.spinLoopHint();
    }

    pub fn unlock(self: *SpinLock) void {
        self.inner.unlock();
    }
};

pub const Cursor = enum {
    default,
    text,
    pointer,
};

/// Cross-platform key identity. Backends translate their native key code
/// (XKB keysym on Linux, virtual-key code on Windows, etc.) into one of
/// these. Layout-dependent keys (letters/digits) reflect the *typed*
/// character — on AZERTY the physical Q key reports `.a`.
pub const Keys = packed struct {
    /// Reserved bit. The backends mappers return a default `.{}` (all
    /// false) for keys not yet covered by this struct, so this field is
    /// never set — kept around so bit 0 of the backing u128 stays unused.
    _unknown: bool = false,

    // Letters
    a: bool = false,
    b: bool = false,
    c: bool = false,
    d: bool = false,
    e: bool = false,
    f: bool = false,
    g: bool = false,
    h: bool = false,
    i: bool = false,
    j: bool = false,
    k: bool = false,
    l: bool = false,
    m: bool = false,
    n: bool = false,
    o: bool = false,
    p: bool = false,
    q: bool = false,
    r: bool = false,
    s: bool = false,
    t: bool = false,
    u: bool = false,
    v: bool = false,
    w: bool = false,
    x: bool = false,
    y: bool = false,
    z: bool = false,

    // Top-row digits
    digit0: bool = false,
    digit1: bool = false,
    digit2: bool = false,
    digit3: bool = false,
    digit4: bool = false,
    digit5: bool = false,
    digit6: bool = false,
    digit7: bool = false,
    digit8: bool = false,
    digit9: bool = false,

    // Function keys
    f1: bool = false,
    f2: bool = false,
    f3: bool = false,
    f4: bool = false,
    f5: bool = false,
    f6: bool = false,
    f7: bool = false,
    f8: bool = false,
    f9: bool = false,
    f10: bool = false,
    f11: bool = false,
    f12: bool = false,

    // Modifiers. These reflect the *effective* modifier state from the
    // platform (xkb_state on Linux, NSEvent.modifierFlags on macOS,
    // VK_*/keymap on Windows) — not just whether a specific physical key
    // is held. So `caps:ctrl_modifier` on Linux makes `control` true
    // while CapsLock is held, even though the keysym is still Caps_Lock.
    // No left/right split: chord hotkeys virtually never care which side.
    shift: bool = false,
    control: bool = false,
    alt: bool = false,
    super: bool = false,
    capsLock: bool = false,

    // Navigation
    arrowLeft: bool = false,
    arrowRight: bool = false,
    arrowUp: bool = false,
    arrowDown: bool = false,
    home: bool = false,
    end: bool = false,
    pageUp: bool = false,
    pageDown: bool = false,

    // Editing & misc
    tab: bool = false,
    escape: bool = false,
    enter: bool = false,
    space: bool = false,
    backspace: bool = false,
    delete: bool = false,
    insert: bool = false,

    /// Integer type wide enough to hold every key bit. Tracks `Keys`
    /// automatically — add a key, and `Backing` widens with it.
    const Backing = @typeInfo(Keys).@"struct".backing_integer.?;

    /// `self | other` — union of two sets.
    pub fn with(self: Keys, other: Keys) Keys {
        return @bitCast(@as(Backing, @bitCast(self)) | @as(Backing, @bitCast(other)));
    }

    /// `self & ~other` — remove `other`'s bits from `self`.
    pub fn without(self: Keys, other: Keys) Keys {
        return @bitCast(@as(Backing, @bitCast(self)) & ~@as(Backing, @bitCast(other)));
    }

    /// True if no bit is set.
    pub fn isEmpty(self: Keys) bool {
        return @as(Backing, @bitCast(self)) == 0;
    }
};

/// Cross-platform per-frame keyboard snapshot. Each backend produces one of
/// these inside `Window.snapshotKeyboard()` so Forbear can sample input
/// state at frame start without going through callbacks or holding the
/// window's lock during mounting.
///
/// All three fields are u128 bitsets where each `Key` variant owns one bit:
/// `@intFromEnum(Key.tab)` is *the bit*, not an index. `.unknown = 0` is
/// the no-op identity for `|`.
pub const KeyboardSnapshot = struct {
    /// Currently-held keys at the moment of sample.
    held: Keys = .{},
    /// Keys that transitioned to down since the previous snapshot.
    pressed: Keys = .{},
    /// Keys that transitioned to up since the previous snapshot.
    released: Keys = .{},
};

pub const Window = switch (builtin.os.tag) {
    .linux => @import("linux.zig"),
    .windows => @import("windows.zig"),
    .macos => @import("macos.zig"),
    else => @compileError("Unsupported OS"),
};
