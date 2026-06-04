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
const c = @import("c");

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

    pub fn has(self: Keys, other: Keys) bool {
        return @as(Backing, @bitCast(self)) & @as(Backing, @bitCast(other)) == @as(Backing, @bitCast(other));
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
    input: []const u8 = &.{},
    /// Currently-held keys at the moment of sample.
    held: Keys = .{},
    /// Keys that transitioned to down since the previous snapshot.
    pressed: Keys = .{},
    /// Keys that transitioned to up since the previous snapshot.
    released: Keys = .{},
};

pub const Window = switch (builtin.os.tag) {
    .linux => struct {
        const posix = std.posix;
        const os = std.os;

        const Self = @This();

        pub const ScrollAxis = enum(u32) {
            vertical = 0,
            horizontal = 1,
        };

        pub const Handlers = struct {
            pointerEnter: ?struct {
                data: *anyopaque,
                function: *const fn (window: *Self, serial: u32, x: i32, y: i32, data: *anyopaque) void,
            } = null,
            pointerLeave: ?struct {
                data: *anyopaque,
                function: *const fn (window: *Self, serial: u32, data: *anyopaque) void,
            } = null,
            pointerMotion: ?struct {
                data: *anyopaque,
                function: *const fn (window: *Self, x: f32, y: f32, data: *anyopaque) void,
            } = null,
            pointerButton: ?struct {
                data: *anyopaque,
                function: *const fn (window: *Self, serial: u32, time: u32, button: u32, state: u32, data: *anyopaque) void,
            } = null,
            scroll: ?struct {
                data: *anyopaque,
                function: *const fn (window: *Self, axis: ScrollAxis, offset: f32, data: *anyopaque) void,
            } = null,
            resize: ?struct {
                data: *anyopaque,
                function: *const fn (
                    window: *Self,
                    newWidth: u32,
                    newHeight: u32,
                    newDpi: [2]u32,
                    data: *anyopaque,
                ) void,
            } = null,
        };

        // Everything native that is contextual
        wlDisplay: *c.wl_display,
        wlRegistry: *c.wl_registry,
        wlCompositor: *c.wl_compositor,
        wlShm: *c.wl_shm,
        wlSeat: *c.wl_seat,
        xdgWmBase: *c.xdg_wm_base,
        wpFractionalScaleManager: ?*c.wp_fractional_scale_manager_v1 = null,
        wpViewporter: ?*c.wp_viewporter = null,

        // Keyboard
        xkbContext: *c.xkb_context,
        xkbKeymap: ?*c.xkb_keymap,
        xkbState: ?*c.xkb_state,
        repeatInfo: struct {
            /// the rate of repeating keys in characters per second
            rate: i32,
            /// delay in milliseconds since key down until repeating starts
            delay: i32,
        },
        wlKeyboard: *c.wl_keyboard,

        /// Keyboard state. The Wayland event thread writes; Forbear's render
        /// thread drains via `snapshotKeyboard()` at frame start.
        keyboardMutex: SpinLock = .{},
        keysDown: Keys = .{},
        pendingPressed: Keys = .{},
        pendingReleased: Keys = .{},

        // this fits into a single struct together
        keyHeldInput: [7]u8 = undefined,
        inputKey: Keys = .{},
        inputLength: usize = 0,
        inputSink: std.ArrayList(u8) = .empty,
        repeatsEmitted: usize = 0,
        inputStartTime: std.Io.Timestamp,

        // cursor
        wlPointer: *c.wl_pointer,
        pointerSerial: ?u32,
        wlCursorTheme: *c.wl_cursor_theme,
        cursorWlSurface: *c.wl_surface,
        defaultWlCursor: *c.wl_cursor,
        pointerWlCursor: *c.wl_cursor,
        textWlCursor: *c.wl_cursor,

        // Everything native related to the window itself
        wlSurface: *c.wl_surface,
        wlOutput: *c.wl_output,
        xdgSurface: *c.xdg_surface,
        xdgToplevel: *c.xdg_toplevel,
        wpFractionalScale: ?*c.wp_fractional_scale_v1 = null,
        wpViewport: ?*c.wp_viewport = null,
        xdgDecorationManager: ?*c.zxdg_decoration_manager_v1 = null,
        xdgToplevelDecoration: ?*c.zxdg_toplevel_decoration_v1 = null,

        // Window state
        width: u32,
        height: u32,
        title: [:0]const u8,
        app_id: [:0]const u8,
        running: bool,
        dpi: [2]u32,

        scale: f32 = 1.0,
        physicalWidthMilimeters: i32 = 0,
        physicalHeightMilimeters: i32 = 0,
        monitorWidth: i32 = 0,
        monitorHeight: i32 = 0,
        refreshRate: u32 = 60000, // in millihertz (mHz), default 60Hz

        allocator: std.mem.Allocator,
        io: std.Io,

        handlers: Handlers,

        fn BindingInfo(T: type) type {
            return struct {
                interface: *const c.wl_interface,
                version: u32,

                fn new(interface: *const c.wl_interface, version: u32) @This() {
                    return .{
                        .interface = interface,
                        .version = version,
                    };
                }

                fn is(self: @This(), interfaceName: []const u8) bool {
                    const selfName = self.interface.name[0..std.mem.len(self.interface.name)];
                    return std.mem.eql(u8, interfaceName, selfName);
                }

                fn bind(self: @This(), registry: ?*c.wl_registry, name: u32, advertisedVersion: u32) *T {
                    return @ptrCast(@alignCast(
                        c.wl_registry_bind(
                            registry,
                            name,
                            self.interface,
                            @min(self.version, advertisedVersion),
                        ) orelse @panic("could not bind global from registry - it was a null pointer"),
                    ));
                }
            };
        }

        fn handleMonitorGeometry(
            data: ?*anyopaque,
            wlOutput: ?*c.wl_output,
            x: i32,
            y: i32,
            physicalWidth: i32,
            physicalHeight: i32,
            subpixel: i32,
            make: [*c]const u8,
            model: [*c]const u8,
            transform: i32,
        ) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data));
            _ = wlOutput;
            _ = x;
            _ = y;
            window.physicalWidthMilimeters = physicalWidth;
            window.physicalHeightMilimeters = physicalHeight;
            _ = subpixel;
            _ = make;
            _ = model;
            _ = transform;
        }

        fn handleMonitorMode(
            data: ?*anyopaque,
            wlOutput: ?*c.wl_output,
            flags: u32,
            width: i32,
            height: i32,
            refresh: i32,
        ) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data));
            _ = wlOutput;
            if (flags & c.WL_OUTPUT_MODE_CURRENT != 0) {
                window.monitorWidth = width;
                window.monitorHeight = height;
                if (refresh > 0) {
                    window.refreshRate = @intCast(refresh);
                }
            }
        }

        fn handleMonitorDone(
            data: ?*anyopaque,
            wlOutput: ?*c.wl_output,
        ) callconv(.c) void {
            _ = wlOutput;
            const window: *Self = @ptrCast(@alignCast(data));
            window.updateDpi();
            std.log.debug(
                "monitor done, physical width {d}mm, physical height {d}mm, width {d}px, height {d}px, DPI {d}x{d}, refresh rate {d}",
                .{
                    window.physicalWidthMilimeters,
                    window.physicalHeightMilimeters,
                    window.monitorWidth,
                    window.monitorHeight,
                    window.dpi[0],
                    window.dpi[1],
                    window.refreshRate,
                },
            );
        }

        fn handleMonitorScale(
            data: ?*anyopaque,
            wlOutput: ?*c.wl_output,
            scale: i32,
        ) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data));
            _ = wlOutput;
            if (window.wpFractionalScale != null) return;
            window.scale = @floatFromInt(scale);
            window.updateDpi();
            if (window.handlers.resize) |handler| {
                handler.function(window, window.width, window.height, window.dpi, handler.data);
            }
            std.log.debug("Monitor scale changed to: {}", .{scale});
        }

        fn handleMonitorName(
            data: ?*anyopaque,
            wlOutput: ?*c.wl_output,
            name: [*c]const u8,
        ) callconv(.c) void {
            _ = data;
            _ = wlOutput;
            _ = name;
        }

        fn handleMonitorDescription(
            data: ?*anyopaque,
            wlOutput: ?*c.wl_output,
            description: [*c]const u8,
        ) callconv(.c) void {
            _ = data;
            _ = wlOutput;
            _ = description;
        }

        const outputListener: c.wl_output_listener = .{
            .geometry = handleMonitorGeometry,
            .mode = handleMonitorMode,
            .done = handleMonitorDone,
            .scale = handleMonitorScale,
            .description = handleMonitorDescription,
            .name = handleMonitorName,
        };

        fn handleFractionalScale(
            data: ?*anyopaque,
            wpFractionalScale: ?*c.wp_fractional_scale_v1,
            scale: u32,
        ) callconv(.c) void {
            _ = wpFractionalScale;

            const window: *Self = @ptrCast(@alignCast(data));
            window.scale = @as(f32, @floatFromInt(scale)) / 120.0;
            window.updateDpi();
            if (window.handlers.resize) |handler| {
                handler.function(window, window.width, window.height, window.dpi, handler.data);
            }
            std.log.debug("Fractional scale changed to: {d}", .{@as(f32, @floatFromInt(scale)) / 120.0});
        }

        const fractionalScaleListener: c.wp_fractional_scale_v1_listener = .{
            .preferred_scale = handleFractionalScale,
        };

        fn global(
            data: ?*anyopaque,
            registry: ?*c.wl_registry,
            name: u32,
            interfacePtr: [*c]const u8,
            version: u32,
        ) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data.?));

            const compositor = BindingInfo(c.wl_compositor).new(
                &c.wl_compositor_interface,
                6,
            );
            const output = BindingInfo(c.wl_output).new(
                &c.wl_output_interface,
                4,
            );
            const shm = BindingInfo(c.wl_shm).new(
                &c.wl_shm_interface,
                2,
            );
            const xdgWmBase = BindingInfo(c.xdg_wm_base).new(
                &c.xdg_wm_base_interface,
                6,
            );
            const seat = BindingInfo(c.wl_seat).new(
                &c.wl_seat_interface,
                9,
            );
            const fractionalScaleManager = BindingInfo(c.wp_fractional_scale_manager_v1).new(
                &c.wp_fractional_scale_manager_v1_interface,
                1,
            );
            const viewporter = BindingInfo(c.wp_viewporter).new(
                &c.wp_viewporter_interface,
                1,
            );
            const decorationManager = BindingInfo(c.zxdg_decoration_manager_v1).new(
                &c.zxdg_decoration_manager_v1_interface,
                1,
            );

            const interfaceName: []const u8 = interfacePtr[0..std.mem.len(interfacePtr)];

            if (compositor.is(interfaceName)) {
                window.wlCompositor = compositor.bind(registry, name, version);
            } else if (shm.is(interfaceName)) {
                window.wlShm = shm.bind(registry, name, version);
            } else if (xdgWmBase.is(interfaceName)) {
                window.xdgWmBase = xdgWmBase.bind(registry, name, version);
                _ = c.xdg_wm_base_add_listener(
                    window.xdgWmBase,
                    &xdgWmBaseListener,
                    data,
                );
            } else if (seat.is(interfaceName)) {
                window.wlSeat = seat.bind(registry, name, version);

                window.wlPointer = c.wl_seat_get_pointer(window.wlSeat) orelse @panic("could not get wl_pointer from wl_seat");
                _ = c.wl_pointer_add_listener(window.wlPointer, &wlPointerListener, data);

                window.wlKeyboard = c.wl_seat_get_keyboard(window.wlSeat) orelse @panic("could not get wl_keyboard from wl_seat");
                _ = c.wl_keyboard_add_listener(window.wlKeyboard, &wlKeyboardListener, data);
            } else if (output.is(interfaceName)) {
                window.wlOutput = output.bind(registry, name, version);

                _ = c.wl_output_add_listener(window.wlOutput, &outputListener, data);
            } else if (fractionalScaleManager.is(interfaceName)) {
                window.wpFractionalScaleManager = fractionalScaleManager.bind(registry, name, version);
            } else if (viewporter.is(interfaceName)) {
                window.wpViewporter = viewporter.bind(registry, name, version);
            } else if (decorationManager.is(interfaceName)) {
                window.xdgDecorationManager = decorationManager.bind(registry, name, version);
            }
        }

        fn global_remove(
            _: ?*anyopaque,
            _: ?*c.wl_registry,
            _: u32,
        ) callconv(.c) void {}

        fn xdg_wm_base_ping(_: ?*anyopaque, xdgWmBase: ?*c.xdg_wm_base, serial: u32) callconv(.c) void {
            c.xdg_wm_base_pong(xdgWmBase, serial);
        }

        const xdgWmBaseListener: c.xdg_wm_base_listener = .{
            .ping = xdg_wm_base_ping,
        };

        fn xdg_surface_configure(data: ?*anyopaque, xdgSurface: ?*c.xdg_surface, serial: u32) callconv(.c) void {
            std.log.debug("xdg surface configuration", .{});
            const window: *Self = @ptrCast(@alignCast(data));
            c.xdg_surface_ack_configure(
                xdgSurface,
                serial,
            );
            c.wl_surface_commit(window.wlSurface);
        }

        const xdgSurfaceListener: c.xdg_surface_listener = .{
            .configure = xdg_surface_configure,
        };

        fn xdgToplevelConfigure(
            data: ?*anyopaque,
            xdgToplevel: ?*c.xdg_toplevel,
            width: i32,
            height: i32,
            states: [*c]c.wl_array,
        ) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data));
            _ = xdgToplevel;
            _ = states;

            if (width > 0 and height > 0) {
                window.width = @intCast(width);
                window.height = @intCast(height);
                if (window.wpViewport) |viewport| {
                    c.wp_viewport_set_destination(viewport, @intCast(window.width), @intCast(window.height));
                }
                if (window.handlers.resize) |handler| {
                    handler.function(window, window.width, window.height, window.dpi, handler.data);
                }
            }
        }

        fn xdgToplevelClose(data: ?*anyopaque, xdgToplevel: ?*c.xdg_toplevel) callconv(.c) void {
            _ = xdgToplevel;
            const window: *Self = @ptrCast(@alignCast(data));
            window.running = false;
        }

        fn xdgToplevelConfigureBounds(
            data: ?*anyopaque,
            xdgToplevel: ?*c.xdg_toplevel,
            width: i32,
            height: i32,
        ) callconv(.c) void {
            _ = data;
            _ = xdgToplevel;
            std.log.debug("xdg toplevel configure bounds: {}x{}", .{ width, height });
        }

        fn xdgToplevelWmCapabilities(
            data: ?*anyopaque,
            xdgToplevel: ?*c.xdg_toplevel,
            capabilities: [*c]c.wl_array,
        ) callconv(.c) void {
            _ = data;
            _ = xdgToplevel;
            _ = capabilities;
        }

        const xdgToplevelListener: c.xdg_toplevel_listener = .{
            .configure = xdgToplevelConfigure,
            .close = xdgToplevelClose,
            .configure_bounds = xdgToplevelConfigureBounds,
            .wm_capabilities = xdgToplevelWmCapabilities,
        };

        fn xdgToplevelDecorationConfigure(
            data: ?*anyopaque,
            decoration: ?*c.zxdg_toplevel_decoration_v1,
            mode: u32,
        ) callconv(.c) void {
            _ = data;
            _ = decoration;
            if (mode == c.ZXDG_TOPLEVEL_DECORATION_V1_MODE_CLIENT_SIDE) {
                std.log.warn("compositor fell back to client-side decorations", .{});
            } else {
                std.log.debug("using server-side decorations", .{});
            }
        }

        const xdgToplevelDecorationListener: c.zxdg_toplevel_decoration_v1_listener = .{
            .configure = xdgToplevelDecorationConfigure,
        };

        fn pointerHandleEnter(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            serial: u32,
            surface: ?*c.wl_surface,
            surfaceX: c.wl_fixed_t,
            surfaceY: c.wl_fixed_t,
        ) callconv(.c) void {
            _ = wlPointer;
            _ = surface;
            const window: *Self = @ptrCast(@alignCast(data));
            window.pointerSerial = serial;
            window.setCursor(.default, serial) catch |err| {
                std.log.err("failed to set cursor: {}", .{err});
            };
            if (window.handlers.pointerEnter) |handler| {
                handler.function(window, serial, surfaceX, surfaceY, handler.data);
            }
        }

        fn pointerHandleLeave(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            serial: u32,
            surface: ?*c.wl_surface,
        ) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data));
            window.pointerSerial = null;
            if (window.handlers.pointerLeave) |handler| {
                handler.function(window, serial, handler.data);
            }
            _ = wlPointer;
            _ = surface;
        }

        fn pointerHandleMotion(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            time: u32,
            surfaceX: c.wl_fixed_t,
            surfaceY: c.wl_fixed_t,
        ) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data));
            if (window.handlers.pointerMotion) |handler| {
                handler.function(
                    window,
                    @floatCast(c.wl_fixed_to_double(surfaceX)),
                    @floatCast(c.wl_fixed_to_double(surfaceY)),
                    handler.data,
                );
            }
            _ = time;
            _ = wlPointer;
        }

        fn pointerHandleButton(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            serial: u32,
            time: u32,
            button: u32,
            state: u32,
        ) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data));
            if (window.handlers.pointerButton) |handler| {
                handler.function(window, serial, time, button, state, handler.data);
            }
            _ = wlPointer;
        }

        fn pointerHandleAxis(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            time: u32,
            axis: u32,
            value: c.wl_fixed_t,
        ) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data));
            if (window.handlers.scroll) |handler| {
                handler.function(
                    window,
                    @enumFromInt(axis),
                    @floatCast(c.wl_fixed_to_double(value)),
                    handler.data,
                );
            }
            _ = time;
            _ = wlPointer;
        }

        fn pointerHandleFrame(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
        ) callconv(.c) void {
            _ = data;
            _ = wlPointer;
        }

        fn pointerHandleAxisSource(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            axisSource: u32,
        ) callconv(.c) void {
            _ = data;
            _ = wlPointer;
            _ = axisSource;
        }

        fn pointerHandleAxisStop(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            time: u32,
            axis: u32,
        ) callconv(.c) void {
            _ = data;
            _ = wlPointer;
            _ = time;
            _ = axis;
        }

        fn pointerHandleAxisDiscrete(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            axis: u32,
            discrete: i32,
        ) callconv(.c) void {
            _ = data;
            _ = wlPointer;
            _ = axis;
            _ = discrete;
        }

        fn pointerHandleAxisValue120(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            axis: u32,
            value120: i32,
        ) callconv(.c) void {
            _ = data;
            _ = wlPointer;
            _ = axis;
            _ = value120;
        }

        fn pointerHandleAxisRelativeDirection(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            axis: u32,
            direction: u32,
        ) callconv(.c) void {
            _ = data;
            _ = wlPointer;
            _ = axis;
            _ = direction;
        }

        const wlPointerListener: c.wl_pointer_listener = .{
            .enter = pointerHandleEnter,
            .leave = pointerHandleLeave,
            .motion = pointerHandleMotion,
            .button = pointerHandleButton,
            .axis = pointerHandleAxis,
            .frame = pointerHandleFrame,
            .axis_source = pointerHandleAxisSource,
            .axis_stop = pointerHandleAxisStop,
            .axis_discrete = pointerHandleAxisDiscrete,
            .axis_value120 = pointerHandleAxisValue120,
            .axis_relative_direction = pointerHandleAxisRelativeDirection,
        };

        /// Look up the *unmodified* keysym for an xkb keycode under the current
        /// layout — i.e. what the key "is", not what it would type given the
        /// current Shift/AltGr state. This is what we want as a stable key
        /// identifier for `Keys.digit1`, `Keys.a`, etc.
        ///
        /// Returns 0 if the keycode produces no symbols at level 0.
        fn baseKeysymForKeycode(window: *Self, xkbKeycode: u32) u32 {
            const km = window.xkbKeymap orelse return 0;
            const xs = window.xkbState orelse return 0;
            const layout = c.xkb_state_key_get_layout(xs, xkbKeycode);
            var syms: [*c]const c.xkb_keysym_t = undefined;
            const n = c.xkb_keymap_key_get_syms_by_level(km, xkbKeycode, layout, 0, &syms);
            if (n <= 0) return 0;
            return syms[0];
        }

        /// Translate an XKB keysym into a single-key `Keys` set.
        /// Returns an empty set for keys not yet covered.
        fn keysymToKeys(sym: u32) Keys {
            return switch (sym) {
                c.XKB_KEY_Tab, c.XKB_KEY_ISO_Left_Tab => .{ .tab = true },
                c.XKB_KEY_Escape => .{ .escape = true },
                c.XKB_KEY_Return, c.XKB_KEY_KP_Enter => .{ .enter = true },
                c.XKB_KEY_space => .{ .space = true },
                c.XKB_KEY_BackSpace => .{ .backspace = true },
                c.XKB_KEY_Delete => .{ .delete = true },
                c.XKB_KEY_Insert => .{ .insert = true },
                c.XKB_KEY_Home => .{ .home = true },
                c.XKB_KEY_End => .{ .end = true },
                c.XKB_KEY_Page_Up => .{ .pageUp = true },
                c.XKB_KEY_Page_Down => .{ .pageDown = true },
                c.XKB_KEY_Left => .{ .arrowLeft = true },
                c.XKB_KEY_Right => .{ .arrowRight = true },
                c.XKB_KEY_Up => .{ .arrowUp = true },
                c.XKB_KEY_Down => .{ .arrowDown = true },
                // Plain modifier keysyms are intentionally not mapped here —
                // shift/control/alt/super come from xkb_state's *effective*
                // modifier mask in `keyboardHandleModifiers`. That path also
                // catches XKB remaps like `caps:ctrl_modifier`, where pressing
                // CapsLock makes Control active even though the keysym stays
                // `Caps_Lock`.
                c.XKB_KEY_Caps_Lock => .{ .capsLock = true },
                c.XKB_KEY_F1 => .{ .f1 = true },
                c.XKB_KEY_F2 => .{ .f2 = true },
                c.XKB_KEY_F3 => .{ .f3 = true },
                c.XKB_KEY_F4 => .{ .f4 = true },
                c.XKB_KEY_F5 => .{ .f5 = true },
                c.XKB_KEY_F6 => .{ .f6 = true },
                c.XKB_KEY_F7 => .{ .f7 = true },
                c.XKB_KEY_F8 => .{ .f8 = true },
                c.XKB_KEY_F9 => .{ .f9 = true },
                c.XKB_KEY_F10 => .{ .f10 = true },
                c.XKB_KEY_F11 => .{ .f11 = true },
                c.XKB_KEY_F12 => .{ .f12 = true },
                c.XKB_KEY_a, c.XKB_KEY_A => .{ .a = true },
                c.XKB_KEY_b, c.XKB_KEY_B => .{ .b = true },
                c.XKB_KEY_c, c.XKB_KEY_C => .{ .c = true },
                c.XKB_KEY_d, c.XKB_KEY_D => .{ .d = true },
                c.XKB_KEY_e, c.XKB_KEY_E => .{ .e = true },
                c.XKB_KEY_f, c.XKB_KEY_F => .{ .f = true },
                c.XKB_KEY_g, c.XKB_KEY_G => .{ .g = true },
                c.XKB_KEY_h, c.XKB_KEY_H => .{ .h = true },
                c.XKB_KEY_i, c.XKB_KEY_I => .{ .i = true },
                c.XKB_KEY_j, c.XKB_KEY_J => .{ .j = true },
                c.XKB_KEY_k, c.XKB_KEY_K => .{ .k = true },
                c.XKB_KEY_l, c.XKB_KEY_L => .{ .l = true },
                c.XKB_KEY_m, c.XKB_KEY_M => .{ .m = true },
                c.XKB_KEY_n, c.XKB_KEY_N => .{ .n = true },
                c.XKB_KEY_o, c.XKB_KEY_O => .{ .o = true },
                c.XKB_KEY_p, c.XKB_KEY_P => .{ .p = true },
                c.XKB_KEY_q, c.XKB_KEY_Q => .{ .q = true },
                c.XKB_KEY_r, c.XKB_KEY_R => .{ .r = true },
                c.XKB_KEY_s, c.XKB_KEY_S => .{ .s = true },
                c.XKB_KEY_t, c.XKB_KEY_T => .{ .t = true },
                c.XKB_KEY_u, c.XKB_KEY_U => .{ .u = true },
                c.XKB_KEY_v, c.XKB_KEY_V => .{ .v = true },
                c.XKB_KEY_w, c.XKB_KEY_W => .{ .w = true },
                c.XKB_KEY_x, c.XKB_KEY_X => .{ .x = true },
                c.XKB_KEY_y, c.XKB_KEY_Y => .{ .y = true },
                c.XKB_KEY_z, c.XKB_KEY_Z => .{ .z = true },
                c.XKB_KEY_0 => .{ .digit0 = true },
                c.XKB_KEY_1 => .{ .digit1 = true },
                c.XKB_KEY_2 => .{ .digit2 = true },
                c.XKB_KEY_3 => .{ .digit3 = true },
                c.XKB_KEY_4 => .{ .digit4 = true },
                c.XKB_KEY_5 => .{ .digit5 = true },
                c.XKB_KEY_6 => .{ .digit6 = true },
                c.XKB_KEY_7 => .{ .digit7 = true },
                c.XKB_KEY_8 => .{ .digit8 = true },
                c.XKB_KEY_9 => .{ .digit9 = true },
                else => .{},
            };
        }

        fn keyboardHandleKeymap(
            data: ?*anyopaque,
            wlKeyboard: ?*c.wl_keyboard,
            format: u32,
            fd: i32,
            size: u32,
        ) callconv(.c) void {
            std.debug.assert(format == c.WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1);
            const window: *Self = @ptrCast(@alignCast(data));

            const mapSharedMemory = std.posix.mmap(
                null,
                @intCast(size),
                .{ .READ = true },
                std.os.linux.MAP{ .TYPE = .PRIVATE },
                fd,
                0,
            ) catch |err| {
                std.log.err("failed to mmap keymap shared memory: {}", .{err});
                @panic("Could not mmap keymap shared memory");
            };
            defer std.posix.munmap(mapSharedMemory);
            defer _ = std.os.linux.close(fd);

            if (window.xkbKeymap) |previousKeymap| {
                c.xkb_keymap_unref(previousKeymap);
            }
            window.xkbKeymap = c.xkb_keymap_new_from_string(
                window.xkbContext,
                mapSharedMemory.ptr,
                c.XKB_KEYMAP_FORMAT_TEXT_V1,
                c.XKB_KEYMAP_COMPILE_NO_FLAGS,
            ) orelse @panic("failed to create xkb keymap from string");

            if (window.xkbState) |previousState| {
                c.xkb_state_unref(previousState);
            }
            window.xkbState = c.xkb_state_new(window.xkbKeymap) orelse @panic("failed to create xkb state from keymap");

            _ = wlKeyboard;
        }

        fn keyboardHandleEnter(
            data: ?*anyopaque,
            wlKeyboard: ?*c.wl_keyboard,
            serial: u32,
            surface: ?*c.wl_surface,
            keys: [*c]c.wl_array,
        ) callconv(.c) void {
            _ = wlKeyboard;
            _ = surface;
            const window: *Self = @ptrCast(@alignCast(data));
            _ = window;
            _ = keys;
            _ = serial;
        }

        fn keyboardHandleLeave(
            data: ?*anyopaque,
            wlKeyboard: ?*c.wl_keyboard,
            serial: u32,
            surface: ?*c.wl_surface,
        ) callconv(.c) void {
            _ = wlKeyboard;
            _ = surface;
            _ = serial;
            const window: *Self = @ptrCast(@alignCast(data));

            // Focus is gone: mark every held key as released this frame so edge
            // consumers see the transition, then clear the held set.
            window.keyboardMutex.lock();
            window.pendingReleased = window.pendingReleased.with(window.keysDown);
            window.keysDown = .{};
            window.keyboardMutex.unlock();
        }

        fn keyboardHandleKey(
            data: ?*anyopaque,
            wlKeyboard: ?*c.wl_keyboard,
            serial: u32,
            time: u32,
            key: u32,
            state: u32,
        ) callconv(.c) void {
            _ = wlKeyboard;
            _ = serial;
            _ = time;
            const window: *Self = @ptrCast(@alignCast(data));

            // wl_keyboard reports evdev keycodes; xkb keycodes are evdev + 8.
            const xkbKeycode: u32 = key + 8;
            // We want the *base* (level-0) keysym so the key's identity is stable
            // across modifier state. `xkb_state_key_get_one_sym` would return e.g.
            // `XKB_KEY_exclam` when Shift+1 is pressed, and we'd lose the
            // `digit1` mapping. Looking up level 0 of the current layout gives
            // `XKB_KEY_1` regardless of held modifiers, while still respecting
            // the user's active keyboard layout.
            const keysym: u32 = baseKeysymForKeycode(window, xkbKeycode);
            const mapped: Keys = keysymToKeys(keysym);

            window.keyboardMutex.lock();
            if (state == c.WL_KEYBOARD_KEY_STATE_PRESSED) {
                std.debug.assert(window.xkbState != null);
                window.inputKey = mapped;
                window.inputLength = @intCast(c.xkb_state_key_get_utf8(
                    window.xkbState,
                    xkbKeycode,
                    &window.keyHeldInput[0],
                    window.keyHeldInput.len,
                ));
                window.inputSink.appendSlice(window.allocator, window.keyHeldInput[0..window.inputLength]) catch {
                    @panic("could not append initial values to input sink");
                };
                window.inputStartTime = std.Io.Clock.now(.awake, window.io);
                window.repeatsEmitted = 0;
                std.debug.assert(window.inputLength <= window.keyHeldInput.len);

                window.pendingPressed = window.pendingPressed.with(mapped);
                window.keysDown = window.keysDown.with(mapped);
            } else if (state == c.WL_KEYBOARD_KEY_STATE_RELEASED) {
                if (window.inputKey.has(mapped)) {
                    window.inputKey = .{};
                    window.repeatsEmitted = 0;
                    window.inputLength = 0;
                }

                window.pendingReleased = window.pendingReleased.with(mapped);
                window.keysDown = window.keysDown.without(mapped);
            }
            window.keyboardMutex.unlock();
        }

        fn keyboardHandleModifiers(
            data: ?*anyopaque,
            wl_keyboard: ?*c.wl_keyboard,
            serial: u32,
            modsDepressed: u32,
            modsLatched: u32,
            modsLocked: u32,
            group: u32,
        ) callconv(.c) void {
            _ = wl_keyboard;
            _ = serial;

            const window: *Self = @ptrCast(@alignCast(data));

            const xkbState = window.xkbState orelse return;
            _ = c.xkb_state_update_mask(xkbState, modsDepressed, modsLatched, modsLocked, 0, 0, group);

            // Translate the effective xkb modifier mask into our `Keys` modifier
            // bits. This is the path that picks up remaps like `caps:ctrl_modifier`
            // — pressing CapsLock makes `Control` active here even though the
            // keysym in `keyboardHandleKey` is still `Caps_Lock`.
            const effective: c_int = c.XKB_STATE_MODS_EFFECTIVE;
            var newMods: Keys = .{};
            newMods.shift = c.xkb_state_mod_name_is_active(xkbState, c.XKB_MOD_NAME_SHIFT, effective) > 0;
            newMods.control = c.xkb_state_mod_name_is_active(xkbState, c.XKB_MOD_NAME_CTRL, effective) > 0;
            newMods.alt = c.xkb_state_mod_name_is_active(xkbState, c.XKB_MOD_NAME_ALT, effective) > 0;
            newMods.super = c.xkb_state_mod_name_is_active(xkbState, c.XKB_MOD_NAME_LOGO, effective) > 0;

            window.keyboardMutex.lock();
            defer window.keyboardMutex.unlock();

            var oldMods: Keys = .{};
            oldMods.shift = window.keysDown.shift;
            oldMods.control = window.keysDown.control;
            oldMods.alt = window.keysDown.alt;
            oldMods.super = window.keysDown.super;

            // Edge events for modifiers that flipped this notification.
            window.pendingPressed = window.pendingPressed.with(newMods.without(oldMods));
            window.pendingReleased = window.pendingReleased.with(oldMods.without(newMods));

            window.keysDown.shift = newMods.shift;
            window.keysDown.control = newMods.control;
            window.keysDown.alt = newMods.alt;
            window.keysDown.super = newMods.super;
        }

        fn keyboardHandleRepeatInfo(
            data: ?*anyopaque,
            _: ?*c.wl_keyboard,
            // the rate of repeating keys in characters per second
            rate: i32,
            // delay in milliseconds since key down until repeating starts
            delay: i32,
        ) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data));

            window.repeatInfo = .{
                .rate = rate,
                .delay = delay,
            };
        }

        const wlKeyboardListener: c.wl_keyboard_listener = .{
            .keymap = keyboardHandleKeymap,
            // TODO: should we be tracking some state based on enter and leave here?
            // Does not doing this introduce some kind of bug?
            .enter = keyboardHandleEnter,
            .leave = keyboardHandleLeave,
            .key = keyboardHandleKey,
            .modifiers = keyboardHandleModifiers,
            .repeat_info = keyboardHandleRepeatInfo,
        };

        pub fn updateDpi(self: *Self) void {
            const millimetersPerInch = 25.4;

            if (self.monitorWidth <= 0 or self.monitorHeight <= 0 or self.physicalWidthMilimeters <= 0 or self.physicalHeightMilimeters <= 0) {
                const fallbackDpi = @max(
                    @as(u32, 1),
                    @as(u32, @intFromFloat(@round(96.0 * self.scale))),
                );
                self.dpi = .{ fallbackDpi, fallbackDpi };
                return;
            }

            const monitorWidth: f32 = @floatFromInt(self.monitorWidth);
            const monitorHeight: f32 = @floatFromInt(self.monitorHeight);
            const physicalWidth: f32 = @floatFromInt(self.physicalWidthMilimeters);
            const physicalHeight: f32 = @floatFromInt(self.physicalHeightMilimeters);
            self.dpi = .{
                @intFromFloat(@round(monitorWidth / (physicalWidth / millimetersPerInch) * self.scale)),
                @intFromFloat(@round(monitorHeight / (physicalHeight / millimetersPerInch) * self.scale)),
            };
        }

        pub fn init(
            allocator: std.mem.Allocator,
            io: std.Io,
            width: u32,
            height: u32,
            title: [:0]const u8,
            app_id: [:0]const u8,
        ) !*Self {
            // I really dislike that we need to keep this in the heap, I feel like this
            // is an artifact from libwayland and might not really be a problem if we
            // implemented our own wayland client from scratch
            const window = try allocator.create(Self);
            errdefer allocator.destroy(window);
            window.allocator = allocator;
            window.io = io;

            window.width = width;
            window.height = height;
            window.scale = 1.0;
            window.dpi = .{ 96, 96 };
            window.title = title;
            window.app_id = app_id;
            window.running = true;

            window.handlers = .{};

            window.xkbContext = c.xkb_context_new(c.XKB_CONTEXT_NO_FLAGS) orelse return error.FailedToCreateXkbContext;
            errdefer c.xkb_context_unref(window.xkbContext);
            window.xkbKeymap = null;
            window.xkbState = null;

            window.keyboardMutex = .{};
            window.keysDown = .{};
            window.pendingPressed = .{};
            window.pendingReleased = .{};
            window.inputKey = .{};
            window.inputLength = 0;
            window.repeatsEmitted = 0;
            window.inputSink = .empty;
            window.inputStartTime = undefined; // only read after a press sets it; guarded by inputLength
            // Some setups never emit repeat_info; default to typical X11 values.
            window.repeatInfo = .{ .rate = 25, .delay = 600 };

            // Initialize optional fields to null before the registry roundtrip,
            // since allocator.create does not zero-initialize memory.
            window.pointerSerial = null;
            window.wpFractionalScaleManager = null;
            window.wpViewporter = null;
            window.xdgDecorationManager = null;
            window.xdgToplevelDecoration = null;
            window.wpFractionalScale = null;
            window.wpViewport = null;

            window.wlDisplay = c.wl_display_connect(
                null,
            ) orelse return error.UnableToConnectToWaylandDisplay;
            errdefer c.wl_display_disconnect(window.wlDisplay);

            window.wlRegistry = c.wl_display_get_registry(window.wlDisplay) orelse return error.UnableToGetRegistry;
            errdefer c.wl_registry_destroy(window.wlRegistry);
            _ = c.wl_registry_add_listener(
                window.wlRegistry,
                &.{ .global = global, .global_remove = global_remove },
                @ptrCast(@alignCast(window)),
            );
            _ = c.wl_display_roundtrip(window.wlDisplay);

            window.wlSurface = c.wl_compositor_create_surface(window.wlCompositor) orelse return error.UnableToCreateSurface;
            errdefer c.wl_surface_destroy(window.wlSurface);

            window.xdgSurface = c.xdg_wm_base_get_xdg_surface(
                window.xdgWmBase,
                window.wlSurface,
            ) orelse return error.UnableToCreateXdgSurface;
            errdefer c.xdg_surface_destroy(window.xdgSurface);
            _ = c.xdg_surface_add_listener(
                window.xdgSurface,
                &xdgSurfaceListener,
                @ptrCast(@alignCast(window)),
            );

            window.xdgToplevel = c.xdg_surface_get_toplevel(
                window.xdgSurface,
            ) orelse return error.UnableToGetTopLevelXdg;
            errdefer c.xdg_toplevel_destroy(window.xdgToplevel);
            _ = c.xdg_toplevel_add_listener(
                window.xdgToplevel,
                &xdgToplevelListener,
                @ptrCast(@alignCast(window)),
            );
            c.xdg_toplevel_set_title(window.xdgToplevel, title.ptr);
            c.xdg_toplevel_set_app_id(window.xdgToplevel, app_id.ptr);

            if (window.xdgDecorationManager) |manager| {
                window.xdgToplevelDecoration = c.zxdg_decoration_manager_v1_get_toplevel_decoration(manager, window.xdgToplevel);
                if (window.xdgToplevelDecoration) |decoration| {
                    c.zxdg_toplevel_decoration_v1_set_mode(decoration, c.ZXDG_TOPLEVEL_DECORATION_V1_MODE_SERVER_SIDE);
                    _ = c.zxdg_toplevel_decoration_v1_add_listener(decoration, &xdgToplevelDecorationListener, @ptrCast(@alignCast(window)));
                }
            }

            if (window.wpFractionalScaleManager) |manager| {
                window.wpFractionalScale = c.wp_fractional_scale_manager_v1_get_fractional_scale(manager, window.wlSurface);
                _ = c.wp_fractional_scale_v1_add_listener(window.wpFractionalScale, &fractionalScaleListener, @ptrCast(@alignCast(window)));
            }

            if (window.wpViewporter) |viewporter| {
                window.wpViewport = c.wp_viewporter_get_viewport(viewporter, window.wlSurface);
                c.wp_viewport_set_destination(window.wpViewport, @intCast(window.width), @intCast(window.height));
            }

            c.wl_surface_commit(window.wlSurface);
            _ = c.wl_display_roundtrip(window.wlDisplay);

            try window.setupCursor();

            return window;
        }

        fn setupCursor(self: *Self) !void {
            self.wlCursorTheme = c.wl_cursor_theme_load(null, 24, self.wlShm) orelse return error.FailedGettingCursorTheme;
            self.defaultWlCursor = c.wl_cursor_theme_get_cursor(self.wlCursorTheme, "default");
            self.pointerWlCursor = c.wl_cursor_theme_get_cursor(self.wlCursorTheme, "pointer");
            self.textWlCursor = c.wl_cursor_theme_get_cursor(self.wlCursorTheme, "text");

            self.cursorWlSurface = c.wl_compositor_create_surface(self.wlCompositor) orelse return error.FailedCreatingCursorSurface;
        }

        pub fn setPointerMotionHandler(
            self: *Self,
            handler: *const fn (window: *Self, time: u32, x: f32, y: f32, data: *anyopaque) void,
            data: *anyopaque,
        ) void {
            self.handlers.pointerMotion = .{
                .data = data,
                .function = handler,
            };
        }

        pub fn setResizeHandler(
            self: *Self,
            handler: *const fn (window: *Self, newWidth: u32, newHeight: u32, newDpi: [2]u32, data: *anyopaque) void,
            data: *anyopaque,
        ) void {
            self.handlers.resize = .{
                .data = data,
                .function = handler,
            };
        }

        /// Drain the keyboard state for the current frame. Holds the keys mutex
        /// just long enough to copy the bitsets and reset the pending fields.
        pub fn snapshotKeyboard(self: *Self, arena: std.mem.Allocator) !KeyboardSnapshot {
            self.keyboardMutex.lock();
            defer self.keyboardMutex.unlock();

            if (self.inputLength > 0) {
                const elapsedMilliseconds: f64 = @floatFromInt(self.inputStartTime.untilNow(self.io, .awake).toMilliseconds());
                const delay: f64 = @floatFromInt(self.repeatInfo.delay);
                const rate: f64 = @floatFromInt(self.repeatInfo.rate);
                if (elapsedMilliseconds >= delay) {
                    const due: usize = @trunc((elapsedMilliseconds - delay) * rate / 1000);
                    const newlyRepeatedCount = due - self.repeatsEmitted;
                    self.repeatsEmitted += newlyRepeatedCount;

                    try self.inputSink.ensureUnusedCapacity(self.allocator, self.inputLength * newlyRepeatedCount);
                    for (0..newlyRepeatedCount) |_| {
                        self.inputSink.appendSliceAssumeCapacity(self.keyHeldInput[0..self.inputLength]);
                    }
                }
            }

            const snap: KeyboardSnapshot = .{
                .input = try arena.dupe(u8, self.inputSink.items),
                .held = self.keysDown,
                .pressed = self.pendingPressed,
                .released = self.pendingReleased,
            };
            self.pendingPressed = .{};
            self.pendingReleased = .{};
            self.inputSink.clearRetainingCapacity();
            return snap;
        }

        pub fn setCursor(self: *Self, cursor: Cursor, serial: u32) !void {
            const effectiveSerial = if (serial != 0)
                serial
            else
                self.pointerSerial orelse return;

            const wlCursorImage = switch (cursor) {
                .default => self.defaultWlCursor.images[0],
                .pointer => self.pointerWlCursor.images[0],
                .text => self.textWlCursor.images[0],
            };
            const wlBuffer = c.wl_cursor_image_get_buffer(wlCursorImage) orelse return error.FailedGettingCursorBuffer;
            c.wl_surface_attach(self.cursorWlSurface, wlBuffer, 0, 0);
            c.wl_surface_damage(self.cursorWlSurface, 0, 0, @intCast(wlCursorImage.*.width), @intCast(wlCursorImage.*.height));
            c.wl_surface_commit(self.cursorWlSurface);
            c.wl_pointer_set_cursor(
                self.wlPointer,
                effectiveSerial,
                self.cursorWlSurface,
                @intCast(wlCursorImage.*.hotspot_x),
                @intCast(wlCursorImage.*.hotspot_y),
            );
        }

        pub fn handleEvents(self: *Self) !void {
            while (self.running) {
                if (c.wl_display_dispatch(self.wlDisplay) == -1) {
                    return error.WaylandDispatchFailed;
                }
            }
        }

        pub fn isHoldingShift(self: *const Self) bool {
            if (self.xkbState) |xkbState| {
                return c.xkb_state_mod_name_is_active(xkbState, c.XKB_MOD_NAME_SHIFT, c.XKB_STATE_MODS_EFFECTIVE) != 0;
            }
            return false;
        }

        /// Returns the target frame time in nanoseconds based on the monitor's refresh rate.
        /// For example, 60Hz returns ~16,666,666 ns.
        pub fn targetFrameTimeNs(self: *const Self) u64 {
            // refreshRate is in millihertz (mHz), e.g., 60000 for 60Hz
            // frame_time_ns = 1_000_000_000_000 / refreshRate
            return @divFloor(@as(u64, 1_000_000_000_000), @as(u64, self.refreshRate));
        }

        // pub fn swapBuffers(self: *Self) !void {
        //     if (c.eglSwapBuffers(
        //         self.egl_display,
        //         self.egl_surface,
        //     ) == c.EGL_FALSE) {
        //         return error.FailedToSwapBuffers;
        //     }
        // }

        pub fn deinit(self: *Self) void {
            if (self.xdgToplevelDecoration) |decoration| c.zxdg_toplevel_decoration_v1_destroy(decoration);
            if (self.wpFractionalScale) |fs| c.wp_fractional_scale_v1_destroy(fs);
            if (self.wpViewport) |vp| c.wp_viewport_destroy(vp);

            c.xdg_toplevel_destroy(self.xdgToplevel);
            c.xdg_surface_destroy(self.xdgSurface);

            c.wl_cursor_theme_destroy(self.wlCursorTheme);
            c.wl_pointer_destroy(self.wlPointer);
            c.wl_keyboard_destroy(self.wlKeyboard);
            if (self.xdgDecorationManager) |dm| c.zxdg_decoration_manager_v1_destroy(dm);
            if (self.wpFractionalScaleManager) |fsm| c.wp_fractional_scale_manager_v1_destroy(fsm);
            if (self.wpViewporter) |vp| c.wp_viewporter_destroy(vp);
            c.wl_shm_destroy(self.wlShm);
            c.wl_compositor_destroy(self.wlCompositor);

            c.xdg_wm_base_destroy(self.xdgWmBase);

            c.wl_surface_destroy(self.wlSurface);
            c.wl_registry_destroy(self.wlRegistry);

            c.wl_display_disconnect(self.wlDisplay);

            if (self.xkbState) |xkbState| {
                c.xkb_state_unref(xkbState);
            }
            if (self.xkbKeymap) |xkbKeymap| {
                c.xkb_keymap_unref(xkbKeymap);
            }
            c.xkb_context_unref(self.xkbContext);

            self.allocator.destroy(self);
        }
    },
    .windows => struct {
        const linuxLeftMouseButton: u32 = 272; // BTN_LEFT, to match the shared pointerButton convention
        const buttonPressed: u32 = 1;
        const buttonReleased: u32 = 0;

        handle: HWND,
        hInstance: HINSTANCE,

        width: u32,
        height: u32,
        title: [:0]const u16,
        className: [:0]const u16,
        running: bool,
        dpi: [2]u32,

        /// Keyboard state. The wndProc thread writes; Forbear's render thread drains
        /// via `snapshotKeyboard()`. Held bitset + edge bitsets, all `Key`-typed.
        keysMutex: SpinLock = .{},
        keysDown: Keys = .{},
        pendingPressed: Keys = .{},
        pendingReleased: Keys = .{},

        handlers: Handlers,

        allocator: std.mem.Allocator,

        const Self = @This();

        pub const ScrollAxis = enum {
            vertical,
            horizontal,
        };

        pub const Handlers = struct {
            pointerMotion: ?struct {
                data: *anyopaque,
                function: *const fn (window: *Self, x: f32, y: f32, data: *anyopaque) void,
            } = null,
            pointerButton: ?struct {
                data: *anyopaque,
                function: *const fn (window: *Self, serial: u32, time: u32, button: u32, state: u32, data: *anyopaque) void,
            } = null,
            scroll: ?struct {
                data: *anyopaque,
                function: *const fn (window: *Self, axis: ScrollAxis, offset: f32, data: *anyopaque) void,
            } = null,
            resize: ?struct {
                data: *anyopaque,
                function: *const fn (
                    window: *Self,
                    newWidth: u32,
                    newHeight: u32,
                    newDpi: [2]u32,
                    data: *anyopaque,
                ) void,
            } = null,
        };

        fn virtualKeyToKeys(vk: WPARAM) Keys {
            return switch (vk) {
                0x08 => .{ .backspace = true },
                0x09 => .{ .tab = true },
                0x0D => .{ .enter = true },
                0x14 => .{ .capsLock = true },
                0x1B => .{ .escape = true },
                0x20 => .{ .space = true },
                0x21 => .{ .pageUp = true },
                0x22 => .{ .pageDown = true },
                0x23 => .{ .end = true },
                0x24 => .{ .home = true },
                0x25 => .{ .arrowLeft = true },
                0x26 => .{ .arrowUp = true },
                0x27 => .{ .arrowRight = true },
                0x28 => .{ .arrowDown = true },
                0x2D => .{ .insert = true },
                0x2E => .{ .delete = true },
                '0' => .{ .digit0 = true },
                '1' => .{ .digit1 = true },
                '2' => .{ .digit2 = true },
                '3' => .{ .digit3 = true },
                '4' => .{ .digit4 = true },
                '5' => .{ .digit5 = true },
                '6' => .{ .digit6 = true },
                '7' => .{ .digit7 = true },
                '8' => .{ .digit8 = true },
                '9' => .{ .digit9 = true },
                'A' => .{ .a = true },
                'B' => .{ .b = true },
                'C' => .{ .c = true },
                'D' => .{ .d = true },
                'E' => .{ .e = true },
                'F' => .{ .f = true },
                'G' => .{ .g = true },
                'H' => .{ .h = true },
                'I' => .{ .i = true },
                'J' => .{ .j = true },
                'K' => .{ .k = true },
                'L' => .{ .l = true },
                'M' => .{ .m = true },
                'N' => .{ .n = true },
                'O' => .{ .o = true },
                'P' => .{ .p = true },
                'Q' => .{ .q = true },
                'R' => .{ .r = true },
                'S' => .{ .s = true },
                'T' => .{ .t = true },
                'U' => .{ .u = true },
                'V' => .{ .v = true },
                'W' => .{ .w = true },
                'X' => .{ .x = true },
                'Y' => .{ .y = true },
                'Z' => .{ .z = true },
                0x5B, 0x5C => .{ .super = true },
                0x70 => .{ .f1 = true },
                0x71 => .{ .f2 = true },
                0x72 => .{ .f3 = true },
                0x73 => .{ .f4 = true },
                0x74 => .{ .f5 = true },
                0x75 => .{ .f6 = true },
                0x76 => .{ .f7 = true },
                0x77 => .{ .f8 = true },
                0x78 => .{ .f9 = true },
                0x79 => .{ .f10 = true },
                0x7A => .{ .f11 = true },
                0x7B => .{ .f12 = true },
                // Modifier VKs (`VK_*SHIFT/CONTROL/MENU/LWIN/RWIN`) are
                // intentionally not mapped here — `refreshModifiersFromOS`
                // samples the OS's combined state on every key event so the
                // collapsed `.shift/.control/.alt/.super` flags stay correct
                // when one side is released while the other is still held.
                else => .{},
            };
        }

        /// Sample the OS's effective modifier state via `GetKeyState` and reconcile
        /// it with `self.keysDown`'s modifier bits. Whatever bits flipped this call
        /// also get appended to `pendingPressed` / `pendingReleased` so consumers
        /// of `on(.keyDown)` / `on(.keyUp)` see modifier edges as expected.
        ///
        /// Caller holds `keysMutex`.
        fn refreshModifiersFromOS(self: *Self) void {
            const down = struct {
                fn f(vk: c_int) bool {
                    return (GetKeyState(vk) & @as(i16, @bitCast(@as(u16, 0x8000)))) != 0;
                }
            }.f;

            var current: Keys = .{};
            // `VK_SHIFT/CONTROL/MENU` themselves report the OR of L/R state.
            current.shift = down(VK_SHIFT);
            current.control = down(VK_CONTROL);
            current.alt = down(VK_MENU);
            // No combined "Windows key" VK — OR the two sides explicitly.
            current.super = down(VK_LWIN) or down(VK_RWIN);

            var oldMods: Keys = .{};
            oldMods.shift = self.keysDown.shift;
            oldMods.control = self.keysDown.control;
            oldMods.alt = self.keysDown.alt;
            oldMods.super = self.keysDown.super;

            self.pendingPressed = self.pendingPressed.with(current.without(oldMods));
            self.pendingReleased = self.pendingReleased.with(oldMods.without(current));

            self.keysDown.shift = current.shift;
            self.keysDown.control = current.control;
            self.keysDown.alt = current.alt;
            self.keysDown.super = current.super;
        }

        pub fn init(
            allocator: std.mem.Allocator,
            width: u32,
            height: u32,
            title: [:0]const u8,
            app_id: [:0]const u8,
        ) !*@This() {
            const window = try allocator.create(@This());
            errdefer allocator.destroy(window);

            window.width = width;
            window.height = height;
            window.title = try std.unicode.utf8ToUtf16LeAllocZ(allocator, title);
            errdefer allocator.free(window.title);
            window.className = try std.unicode.utf8ToUtf16LeAllocZ(allocator, app_id);
            errdefer allocator.free(window.className);
            window.running = true;

            window.keysMutex = .{};
            window.keysDown = .{};
            window.pendingPressed = .{};
            window.pendingReleased = .{};
            window.handlers = .{};

            window.allocator = allocator;

            window.hInstance = GetModuleHandleW(null);
            if (window.hInstance == null) {
                return error.CouldNotFindHInstance;
            }

            const windowClass = WNDCLASSEXW{
                .hInstance = window.hInstance,
                .style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC,
                .lpfnWndProc = wndProc,
                .hCursor = LoadCursorW(null, IDC_ARROW),
                .lpszClassName = window.className.ptr,
            };

            if (RegisterClassExW(&windowClass) == 0) {
                return error.FailedToRegisterWindowClass;
            }

            _ = SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
            _ = SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

            var rect = RECT{ .left = 0, .top = 0, .right = @intCast(width), .bottom = @intCast(height) };
            const style = WS_OVERLAPPEDWINDOW | WS_VISIBLE;
            _ = AdjustWindowRectEx(&rect, style, 0, 0);

            window.handle = CreateWindowExW(
                0,
                window.className.ptr,
                window.title.ptr,
                style,
                CW_USEDEFAULT,
                CW_USEDEFAULT,
                rect.right - rect.left,
                rect.bottom - rect.top,
                null,
                null,
                window.hInstance,
                window,
            ) orelse return error.FailedToCreateWindow;

            window.updateDpi();
            window.updateClientSize();

            return window;
        }

        fn updateDpi(self: *@This()) void {
            const dpi = GetDpiForWindow(self.handle);
            self.dpi = .{ dpi, dpi };
        }

        fn updateClientSize(self: *@This()) void {
            var rect: RECT = undefined;
            if (GetClientRect(self.handle, &rect) == 0) {
                std.log.err("failed to query window client size", .{});
                return;
            }
            self.width = @intCast(rect.right - rect.left);
            self.height = @intCast(rect.bottom - rect.top);
        }

        fn emitResizeIfNeeded(self: *@This(), hwnd: HWND, force: bool) void {
            var rect: RECT = undefined;
            if (GetClientRect(hwnd, &rect) == 0) {
                std.log.err("failed to get new window size, ignoring event", .{});
                return;
            }

            const newWidth: u32 = @intCast(rect.right - rect.left);
            const newHeight: u32 = @intCast(rect.bottom - rect.top);

            if (force or self.width != newWidth or self.height != newHeight) {
                self.width = newWidth;
                self.height = newHeight;
                if (self.handlers.resize) |handler| {
                    handler.function(self, self.width, self.height, self.dpi, handler.data);
                }
            }
        }

        pub fn deinit(self: *@This()) void {
            _ = DestroyWindow(self.handle);
            _ = UnregisterClassW(self.className.ptr, self.hInstance);
            self.allocator.free(self.className);
            self.allocator.free(self.title);
            self.allocator.destroy(self);
        }

        fn wndProc(hwnd: HWND, message: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.c) LRESULT {
            // Handle WM_NCCREATE to store the window pointer
            if (message == WM_NCCREATE) {
                const createStruct: *CREATESTRUCTW = @ptrFromInt(@as(usize, @bitCast(lParam)));
                const window: *@This() = @ptrCast(@alignCast(createStruct.lpCreateParams));
                _ = SetWindowLongPtrW(hwnd, GWLP_USERDATA, @bitCast(@intFromPtr(window)));
                return DefWindowProcW(hwnd, message, wParam, lParam);
            }

            // Retrieve the window pointer for all other messages
            const window: ?*@This() = blk: {
                const ptr = GetWindowLongPtrW(hwnd, GWLP_USERDATA);
                break :blk if (ptr == 0) null else @ptrFromInt(@as(usize, @bitCast(ptr)));
            };

            switch (message) {
                WM_WINDOWPOSCHANGED => {
                    if (window) |self| {
                        const windowpos: *WINDOWPOS = @ptrFromInt(@as(usize, @intCast(lParam)));
                        if ((windowpos.flags & SWP_NOSIZE) == 0) {
                            self.emitResizeIfNeeded(hwnd, false);
                        }
                    }
                },
                WM_MOUSEMOVE => {
                    if (window) |self| {
                        const mouseX: u16 = @truncate(@as(u32, @intCast(lParam)));
                        const mouseY: u16 = @truncate(@as(u32, @intCast(lParam)) >> 16);
                        if (self.handlers.pointerMotion) |handler| {
                            handler.function(self, @floatFromInt(mouseX), @floatFromInt(mouseY), handler.data);
                        }
                    }
                },
                WM_LBUTTONDOWN => {
                    if (window) |self| {
                        if (self.handlers.pointerButton) |handler| {
                            handler.function(self, 0, 0, linuxLeftMouseButton, buttonPressed, handler.data);
                        }
                    }
                },
                WM_LBUTTONUP => {
                    if (window) |self| {
                        if (self.handlers.pointerButton) |handler| {
                            handler.function(self, 0, 0, linuxLeftMouseButton, buttonReleased, handler.data);
                        }
                    }
                },
                WM_MOUSEWHEEL => {
                    if (window) |self| {
                        // this value is positive when going up and negative going down
                        // see https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-mousewheel
                        const offset: i16 = @bitCast(@as(u16, @truncate(wParam >> 16)));
                        if (self.handlers.scroll) |handler| {
                            handler.function(self, .vertical, @floatFromInt(-1 * offset), handler.data);
                        }
                    }
                },
                WM_KEYDOWN => {
                    if (window) |self| {
                        // lParam bit 30 is "previous key state": 1 = OS repeat,
                        // 0 = fresh press. Only fresh presses flip the edge bit.
                        // Coalesce count (bits 0..15) and scan code (bits 16..23)
                        // are intentionally ignored.
                        const lp: u32 = @truncate(@as(u64, @bitCast(lParam)));
                        const wasAlreadyDown: bool = (lp & (1 << 30)) != 0;
                        const key = virtualKeyToKeys(wParam);

                        self.keysMutex.lock();
                        if (!wasAlreadyDown) {
                            self.pendingPressed = self.pendingPressed.with(key);
                            self.keysDown = self.keysDown.with(key);
                        }
                        refreshModifiersFromOS(self);
                        self.keysMutex.unlock();
                    }
                },
                WM_KEYUP => {
                    if (window) |self| {
                        const key = virtualKeyToKeys(wParam);
                        self.keysMutex.lock();
                        self.pendingReleased = self.pendingReleased.with(key);
                        self.keysDown = self.keysDown.without(key);
                        refreshModifiersFromOS(self);
                        self.keysMutex.unlock();
                    }
                },
                WM_DPICHANGED => {
                    if (window) |self| {
                        const previousDpi = self.dpi;
                        const wParam32: u32 = @truncate(wParam);
                        const dpiX: u16 = @truncate(wParam32);
                        const dpiY: u16 = @truncate(wParam32 >> 16);
                        self.dpi = .{ @intCast(dpiX), @intCast(dpiY) };

                        const suggestedRect: *const RECT = @ptrFromInt(@as(usize, @bitCast(lParam)));
                        _ = SetWindowPos(
                            hwnd,
                            null,
                            @intCast(suggestedRect.left),
                            @intCast(suggestedRect.top),
                            @intCast(suggestedRect.right - suggestedRect.left),
                            @intCast(suggestedRect.bottom - suggestedRect.top),
                            SWP_NOZORDER | SWP_NOACTIVATE,
                        );

                        const dpiChanged = self.dpi[0] != previousDpi[0] or self.dpi[1] != previousDpi[1];
                        self.emitResizeIfNeeded(hwnd, dpiChanged);
                    }
                },
                WM_DESTROY => {
                    if (window) |self| {
                        self.running = false;
                    }
                },
                WM_CLOSE => {
                    if (window) |self| {
                        self.running = false;
                    }
                },
                WM_ACTIVATEAPP => {
                    std.log.debug("activate app", .{});
                },
                else => {
                    return DefWindowProcW(hwnd, message, wParam, lParam);
                },
            }

            return 0;
        }

        pub fn targetFrameTimeNs(self: *const @This()) u64 {
            const fallback60hz: u64 = 16_666_667; // ~60 Hz in nanoseconds

            // Get the monitor that contains most of this window
            const monitor = MonitorFromWindow(self.handle, MONITOR_DEFAULTTONEAREST);
            if (monitor == null) {
                return fallback60hz;
            }

            // Get monitor info to retrieve the device name
            var monitorInfo: MONITORINFOEXW = .{};
            if (GetMonitorInfoW(monitor, &monitorInfo) == 0) {
                return fallback60hz;
            }

            // Get current display settings for this monitor
            var devMode: DEVMODEW = .{};
            if (EnumDisplaySettingsW(@ptrCast(&monitorInfo.szDevice), ENUM_CURRENT_SETTINGS, &devMode) == 0) {
                return fallback60hz;
            }

            const refreshRate = devMode.dmDisplayFrequency;
            if (refreshRate == 0 or refreshRate == 1) {
                // 0 or 1 means default/unknown
                return fallback60hz;
            }

            return @divTrunc(1_000_000_000, @as(u64, refreshRate));
        }

        pub fn isHoldingShift(self: *Self) bool {
            self.keysMutex.lock();
            defer self.keysMutex.unlock();
            return self.keysDown.shift;
        }

        /// Drain the keyboard state for the current frame. Holds `keysMutex` just
        /// long enough to copy the bitsets and reset the pending fields.
        pub fn snapshotKeyboard(self: *Self) KeyboardSnapshot {
            self.keysMutex.lock();
            defer self.keysMutex.unlock();

            const snap: KeyboardSnapshot = .{
                .held = self.keysDown,
                .pressed = self.pendingPressed,
                .released = self.pendingReleased,
            };
            self.pendingPressed = .{};
            self.pendingReleased = .{};
            return snap;
        }

        pub fn setCursor(self: *Self, cursor: Cursor, serial: u32) !void {
            _ = self;
            _ = serial;

            const nativeCursor = switch (cursor) {
                .default => LoadCursorW(null, IDC_ARROW),
                .text => LoadCursorW(null, IDC_IBEAM),
                .pointer => LoadCursorW(null, IDC_HAND),
            } orelse return error.FailedToLoadCursor;

            _ = SetCursor(nativeCursor);
        }

        pub fn handleEvents(self: *@This()) !void {
            while (self.running) {
                var message: MSG = undefined;
                if (GetMessageW(&message, self.handle, 0, 0) != 0) {
                    _ = TranslateMessage(&message);
                    _ = DispatchMessageW(&message);
                } else {
                    self.running = false;
                }
            }
        }

        // Manual Windows API declarations to avoid @cImport macro translation issues
        // This provides clean Zig bindings for the Windows APIs needed for windowing
        // Basic Windows types
        const BOOL = c_int;
        const WORD = u16;
        const DWORD = u32;
        const UINT = c_uint;
        const INT = c_int;
        const LONG = c_long;
        const LONG_PTR = isize;
        const UINT_PTR = usize;
        const SIZE_T = usize;
        const ATOM = WORD;

        const LPVOID = ?*anyopaque;
        const LPCVOID = ?*const anyopaque;
        const LPWSTR = [*:0]u16;
        const LPCWSTR = [*:0]const u16;

        const HANDLE = *anyopaque;
        const HWND = ?HANDLE;
        const HINSTANCE = ?HANDLE;
        const HMODULE = ?HANDLE;
        const HICON = ?HANDLE;
        const HCURSOR = ?HANDLE;
        const HBRUSH = ?HANDLE;
        const HMENU = ?HANDLE;
        const HDC = ?HANDLE;

        const WPARAM = UINT_PTR;
        const LPARAM = LONG_PTR;
        const LRESULT = LONG_PTR;

        // Window procedure callback type
        const WNDPROC = *const fn (hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.c) LRESULT;

        // WNDCLASSEXW structure
        const WNDCLASSEXW = extern struct {
            cbSize: UINT = @sizeOf(WNDCLASSEXW),
            style: UINT = 0,
            lpfnWndProc: WNDPROC,
            cbClsExtra: INT = 0,
            cbWndExtra: INT = 0,
            hInstance: HINSTANCE = null,
            hIcon: HICON = null,
            hCursor: HCURSOR = null,
            hbrBackground: HBRUSH = null,
            lpszMenuName: ?LPCWSTR = null,
            lpszClassName: LPCWSTR,
            hIconSm: HICON = null,
        };

        const WINDOWPOS = extern struct {
            hwnd: HWND = null,
            hwndInsertAfter: HWND = null,
            x: INT = 0,
            y: INT = 0,
            cx: INT = 0,
            cy: INT = 0,
            flags: UINT = 0,
        };

        // RECT structure
        const RECT = extern struct {
            left: LONG = 0,
            top: LONG = 0,
            right: LONG = 0,
            bottom: LONG = 0,
        };

        // POINT structure
        const POINT = extern struct {
            x: LONG = 0,
            y: LONG = 0,
        };

        // MSG structure
        const MSG = extern struct {
            hwnd: HWND = null,
            message: UINT = 0,
            wParam: WPARAM = 0,
            lParam: LPARAM = 0,
            time: DWORD = 0,
            pt: POINT = .{},
        };

        // Window styles
        const WS_OVERLAPPED: DWORD = 0x00000000;
        const WS_POPUP: DWORD = 0x80000000;
        const WS_CHILD: DWORD = 0x40000000;
        const WS_MINIMIZE: DWORD = 0x20000000;
        const WS_VISIBLE: DWORD = 0x10000000;
        const WS_DISABLED: DWORD = 0x08000000;
        const WS_CLIPSIBLINGS: DWORD = 0x04000000;
        const WS_CLIPCHILDREN: DWORD = 0x02000000;
        const WS_MAXIMIZE: DWORD = 0x01000000;
        const WS_CAPTION: DWORD = 0x00C00000;
        const WS_BORDER: DWORD = 0x00800000;
        const WS_DLGFRAME: DWORD = 0x00400000;
        const WS_VSCROLL: DWORD = 0x00200000;
        const WS_HSCROLL: DWORD = 0x00100000;
        const WS_SYSMENU: DWORD = 0x00080000;
        const WS_THICKFRAME: DWORD = 0x00040000;
        const WS_GROUP: DWORD = 0x00020000;
        const WS_TABSTOP: DWORD = 0x00010000;
        const WS_MINIMIZEBOX: DWORD = 0x00020000;
        const WS_MAXIMIZEBOX: DWORD = 0x00010000;
        const WS_OVERLAPPEDWINDOW: DWORD = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;

        // Class styles
        const CS_VREDRAW: UINT = 0x0001;
        const CS_HREDRAW: UINT = 0x0002;
        const CS_DBLCLKS: UINT = 0x0008;
        const CS_OWNDC: UINT = 0x0020;
        const CS_CLASSDC: UINT = 0x0040;
        const CS_PARENTDC: UINT = 0x0080;
        const CS_NOCLOSE: UINT = 0x0200;
        const CS_SAVEBITS: UINT = 0x0800;
        const CS_BYTEALIGNCLIENT: UINT = 0x1000;
        const CS_BYTEALIGNWINDOW: UINT = 0x2000;
        const CS_GLOBALCLASS: UINT = 0x4000;

        // Window messages
        const WM_NULL: UINT = 0x0000;
        const WM_NCCREATE: UINT = 0x0081;
        const WM_CREATE: UINT = 0x0001;
        const WM_DESTROY: UINT = 0x0002;
        const WM_DPICHANGED: UINT = 0x02E0;
        const WM_WINDOWPOSCHANGED: UINT = 0x0047;
        const WM_MOVE: UINT = 0x0003;
        const WM_SIZE: UINT = 0x0005;
        const WM_EXITSIZEMOVE: UINT = 0x0232;
        const WM_ENTERSIZEMOVE: UINT = 0x0231;
        const WM_SIZING: UINT = 0x0214;
        const WM_ACTIVATE: UINT = 0x0006;
        const WM_SETFOCUS: UINT = 0x0007;
        const WM_KILLFOCUS: UINT = 0x0008;
        const WM_ENABLE: UINT = 0x000A;
        const WM_SETREDRAW: UINT = 0x000B;
        const WM_SETTEXT: UINT = 0x000C;
        const WM_GETTEXT: UINT = 0x000D;
        const WM_GETTEXTLENGTH: UINT = 0x000E;
        const WM_PAINT: UINT = 0x000F;
        const WM_CLOSE: UINT = 0x0010;
        const WM_QUIT: UINT = 0x0012;
        const WM_ACTIVATEAPP: UINT = 0x001C;
        const WM_KEYDOWN: UINT = 0x0100;
        const WM_KEYUP: UINT = 0x0101;
        const WM_CHAR: UINT = 0x0102;
        const WM_SYSKEYDOWN: UINT = 0x0104;
        const WM_SYSKEYUP: UINT = 0x0105;
        const WM_SYSCHAR: UINT = 0x0106;
        const WM_MOUSEMOVE: UINT = 0x0200;
        const WM_LBUTTONDOWN: UINT = 0x0201;
        const WM_LBUTTONUP: UINT = 0x0202;
        const WM_LBUTTONDBLCLK: UINT = 0x0203;
        const WM_RBUTTONDOWN: UINT = 0x0204;
        const WM_RBUTTONUP: UINT = 0x0205;
        const WM_RBUTTONDBLCLK: UINT = 0x0206;
        const WM_MBUTTONDOWN: UINT = 0x0207;
        const WM_MBUTTONUP: UINT = 0x0208;
        const WM_MBUTTONDBLCLK: UINT = 0x0209;
        const WM_MOUSEWHEEL: UINT = 0x020A;

        // Virtual Keycodes https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
        const VK_SHIFT: c_int = 0x10;
        const VK_CONTROL: c_int = 0x11;
        const VK_MENU: c_int = 0x12;
        const VK_LWIN: c_int = 0x5B;
        const VK_RWIN: c_int = 0x5C;

        /// `GetKeyState(vk)` returns the keyboard state for the calling thread:
        /// high bit set = key currently down. For `VK_SHIFT/VK_CONTROL/VK_MENU`,
        /// the result is the OR of the corresponding L/R keys — exactly what we
        /// need to keep a collapsed `.shift/.control/.alt` flag correct when one
        /// side is released while the other is still held.
        extern "user32" fn GetKeyState(nVirtKey: c_int) callconv(.winapi) i16;

        // CW_USEDEFAULT
        const CW_USEDEFAULT: c_int = @bitCast(@as(c_uint, 0x80000000));

        // Standard cursor IDs (these are resource IDs cast to pointers)
        const IDC_ARROW: ?*const anyopaque = @ptrFromInt(32512);
        const IDC_IBEAM: ?*const anyopaque = @ptrFromInt(32513);
        const IDC_WAIT: ?*const anyopaque = @ptrFromInt(32514);
        const IDC_CROSS: ?*const anyopaque = @ptrFromInt(32515);
        const IDC_UPARROW: ?*const anyopaque = @ptrFromInt(32516);
        const IDC_SIZE: ?*const anyopaque = @ptrFromInt(32640);
        const IDC_ICON: ?*const anyopaque = @ptrFromInt(32641);
        const IDC_SIZENWSE: ?*const anyopaque = @ptrFromInt(32642);
        const IDC_SIZENESW: ?*const anyopaque = @ptrFromInt(32643);
        const IDC_SIZEWE: ?*const anyopaque = @ptrFromInt(32644);
        const IDC_SIZENS: ?*const anyopaque = @ptrFromInt(32645);
        const IDC_SIZEALL: ?*const anyopaque = @ptrFromInt(32646);
        const IDC_NO: ?*const anyopaque = @ptrFromInt(32648);
        const IDC_HAND: ?*const anyopaque = @ptrFromInt(32649);
        const IDC_APPSTARTING: ?*const anyopaque = @ptrFromInt(32650);
        const IDC_HELP: ?*const anyopaque = @ptrFromInt(32651);

        // PeekMessage flags
        const PM_NOREMOVE: UINT = 0x0000;
        const PM_REMOVE: UINT = 0x0001;
        const PM_NOYIELD: UINT = 0x0002;

        // ShowWindow commands
        const SW_HIDE: c_int = 0;
        const SW_SHOWNORMAL: c_int = 1;
        const SW_SHOW: c_int = 5;
        const SW_MINIMIZE: c_int = 6;
        const SW_MAXIMIZE: c_int = 3;
        const SW_RESTORE: c_int = 9;

        // WINDOWPOS flags
        /// Draws a frame (defined in the window's class description) around the
        /// window. Same as the SWP_FRAMECHANGED flag.
        const SWP_DRAWFRAME = 0x0020;
        /// Sends a WM_NCCALCSIZE message to the window, even if the window's size is
        /// not being changed. If this flag is not specified, WM_NCCALCSIZE is sent only
        /// when the window's size is being changed.
        const SWP_FRAMECHANGED = 0x0020;
        /// Hides the window.
        const SWP_HIDEWINDOW = 0x0080;
        /// Does not activate the window. If this flag is not set, the window is
        /// activated and moved to the top of either the topmost or non-topmost group
        /// (depending on the setting of the hwndInsertAfter member).
        const SWP_NOACTIVATE = 0x0010;
        /// Discards the entire contents of the client area. If this flag is not
        /// specified, the valid contents of the client area are saved and copied back
        /// into the client area after the window is sized or repositioned.
        const SWP_NOCOPYBITS = 0x0100;
        /// Retains the current position (ignores the x and y members).
        const SWP_NOMOVE = 0x0002;
        /// Does not change the owner window's position in the Z order.
        const SWP_NOOWNERZORDER = 0x0200;
        /// Does not redraw changes. If this flag is set, no repainting of any kind
        /// occurs. This applies to the client area, the nonclient area (including the
        /// title bar and scroll bars), and any part of the parent window uncovered as
        /// a result of the window being moved. When this flag is set, the application
        /// must explicitly invalidate or redraw any parts of the window and parent
        /// window that need redrawing.
        const SWP_NOREDRAW = 0x0008;
        /// Does not change the owner window's position in the Z order. Same as the
        /// SWP_NOOWNERZORDER flag.
        const SWP_NOREPOSITION = 0x0200;
        /// Prevents the window from receiving the WM_WINDOWPOSCHANGING message.
        const SWP_NOSENDCHANGING = 0x0400;
        /// Retains the current size (ignores the cx and cy members).
        const SWP_NOSIZE = 0x0001;
        /// Retains the current Z order (ignores the hwndInsertAfter member).
        const SWP_NOZORDER = 0x0004;
        /// Displays the window.
        const SWP_SHOWWINDOW = 0x0040;

        // External function declarations
        extern "kernel32" fn GetModuleHandleW(lpModuleName: ?LPCWSTR) callconv(.c) HMODULE;
        extern "kernel32" fn GetLastError() callconv(.c) DWORD;

        extern "user32" fn RegisterClassExW(lpWndClass: *const WNDCLASSEXW) callconv(.c) ATOM;
        extern "user32" fn UnregisterClassW(lpClassName: LPCWSTR, hInstance: HINSTANCE) callconv(.c) BOOL;

        extern "user32" fn CreateWindowExW(
            dwExStyle: DWORD,
            lpClassName: LPCWSTR,
            lpWindowName: LPCWSTR,
            dwStyle: DWORD,
            x: c_int,
            y: c_int,
            nWidth: c_int,
            nHeight: c_int,
            hWndParent: HWND,
            hMenu: HMENU,
            hInstance: HINSTANCE,
            lpParam: LPVOID,
        ) callconv(.c) HWND;

        extern "user32" fn DestroyWindow(hWnd: HWND) callconv(.c) BOOL;
        extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: c_int) callconv(.c) BOOL;
        extern "user32" fn UpdateWindow(hWnd: HWND) callconv(.c) BOOL;

        extern "user32" fn DefWindowProcW(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.c) LRESULT;

        extern "user32" fn GetMessageW(lpMsg: *MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) callconv(.c) BOOL;
        extern "user32" fn PeekMessageW(lpMsg: *MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) callconv(.c) BOOL;
        extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.c) BOOL;
        extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.c) LRESULT;
        extern "user32" fn PostQuitMessage(nExitCode: c_int) callconv(.c) void;

        extern "user32" fn LoadCursorW(hInstance: HINSTANCE, lpCursorName: ?*const anyopaque) callconv(.c) HCURSOR;
        extern "user32" fn SetCursor(hCursor: HCURSOR) callconv(.c) HCURSOR;

        extern "user32" fn AdjustWindowRectEx(lpRect: *RECT, dwStyle: DWORD, bMenu: BOOL, dwExStyle: DWORD) callconv(.c) BOOL;
        extern "user32" fn SetWindowPos(
            hWnd: HWND,
            hWndInsertAfter: HWND,
            X: c_int,
            Y: c_int,
            cx: c_int,
            cy: c_int,
            uFlags: UINT,
        ) callconv(.c) BOOL;
        extern "user32" fn GetClientRect(hWnd: HWND, lpRect: *RECT) callconv(.c) BOOL;
        extern "user32" fn GetWindowRect(hWnd: HWND, lpRect: *RECT) callconv(.c) BOOL;

        extern "user32" fn SetWindowTextW(hWnd: HWND, lpString: LPCWSTR) callconv(.c) BOOL;
        extern "user32" fn GetWindowTextW(hWnd: HWND, lpString: LPWSTR, nMaxCount: c_int) callconv(.c) c_int;

        extern "user32" fn InvalidateRect(hWnd: HWND, lpRect: ?*const RECT, bErase: BOOL) callconv(.c) BOOL;

        extern "user32" fn GetDC(hWnd: HWND) callconv(.c) HDC;
        extern "user32" fn ReleaseDC(hWnd: HWND, hDC: HDC) callconv(.c) c_int;

        // DPI awareness
        const DPI_AWARENESS_CONTEXT = ?HANDLE;
        const DPI_AWARENESS_CONTEXT_UNAWARE: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -1))));
        const DPI_AWARENESS_CONTEXT_SYSTEM_AWARE: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -2))));
        const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -3))));
        const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -4))));
        const DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -5))));

        extern "user32" fn GetDpiForWindow(hwnd: HWND) callconv(.c) UINT;
        extern "user32" fn SetThreadDpiAwarenessContext(dpiContext: DPI_AWARENESS_CONTEXT) callconv(.c) DPI_AWARENESS_CONTEXT;
        extern "user32" fn SetProcessDpiAwarenessContext(value: DPI_AWARENESS_CONTEXT) callconv(.c) BOOL;

        // Window long ptr indices
        const GWLP_WNDPROC: c_int = -4;
        const GWLP_HINSTANCE: c_int = -6;
        const GWLP_HWNDPARENT: c_int = -8;
        const GWLP_USERDATA: c_int = -21;
        const GWLP_ID: c_int = -12;

        extern "user32" fn SetWindowLongPtrW(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) callconv(.c) LONG_PTR;
        extern "user32" fn GetWindowLongPtrW(hWnd: HWND, nIndex: c_int) callconv(.c) LONG_PTR;

        // CREATESTRUCT for WM_CREATE/WM_NCCREATE
        const CREATESTRUCTW = extern struct {
            lpCreateParams: LPVOID,
            hInstance: HINSTANCE,
            hMenu: HMENU,
            hwndParent: HWND,
            cy: c_int,
            cx: c_int,
            y: c_int,
            x: c_int,
            style: LONG,
            lpszName: ?LPCWSTR,
            lpszClass: ?LPCWSTR,
            dwExStyle: DWORD,
        };

        // Monitor functions
        const HMONITOR = ?HANDLE;

        const MONITOR_DEFAULTTONULL: DWORD = 0x00000000;
        const MONITOR_DEFAULTTOPRIMARY: DWORD = 0x00000001;
        const MONITOR_DEFAULTTONEAREST: DWORD = 0x00000002;

        const MONITORINFOEXW = extern struct {
            cbSize: DWORD = @sizeOf(MONITORINFOEXW),
            rcMonitor: RECT = .{},
            rcWork: RECT = .{},
            dwFlags: DWORD = 0,
            szDevice: [32]u16 = [_]u16{0} ** 32,
        };

        const DEVMODEW = extern struct {
            dmDeviceName: [32]u16 = [_]u16{0} ** 32,
            dmSpecVersion: WORD = 0,
            dmDriverVersion: WORD = 0,
            dmSize: WORD = @sizeOf(DEVMODEW),
            dmDriverExtra: WORD = 0,
            dmFields: DWORD = 0,
            // Union of POINTL/display settings - using anonymous struct for display settings
            dmPosition: POINT = .{},
            dmDisplayOrientation: DWORD = 0,
            dmDisplayFixedOutput: DWORD = 0,
            dmColor: i16 = 0,
            dmDuplex: i16 = 0,
            dmYResolution: i16 = 0,
            dmTTOption: i16 = 0,
            dmCollate: i16 = 0,
            dmFormName: [32]u16 = [_]u16{0} ** 32,
            dmLogPixels: WORD = 0,
            dmBitsPerPel: DWORD = 0,
            dmPelsWidth: DWORD = 0,
            dmPelsHeight: DWORD = 0,
            dmDisplayFlags: DWORD = 0,
            dmDisplayFrequency: DWORD = 0,
            dmICMMethod: DWORD = 0,
            dmICMIntent: DWORD = 0,
            dmMediaType: DWORD = 0,
            dmDitherType: DWORD = 0,
            dmReserved1: DWORD = 0,
            dmReserved2: DWORD = 0,
            dmPanningWidth: DWORD = 0,
            dmPanningHeight: DWORD = 0,
        };

        const ENUM_CURRENT_SETTINGS: DWORD = 0xFFFFFFFF;

        extern "user32" fn MonitorFromWindow(hwnd: HWND, dwFlags: DWORD) callconv(.c) HMONITOR;
        extern "user32" fn GetMonitorInfoW(hMonitor: HMONITOR, lpmi: *MONITORINFOEXW) callconv(.c) BOOL;
        extern "user32" fn EnumDisplaySettingsW(lpszDeviceName: [*:0]const u16, iModeNum: DWORD, lpDevMode: *DEVMODEW) callconv(.c) BOOL;
    },
    .macos => struct {
        extern fn objc_autoreleasePoolPush() ?*anyopaque;
        extern fn objc_autoreleasePoolPop(pool: ?*anyopaque) void;

        const Self = @This();

        const linuxLeftMouseButton: u32 = 272; // BTN_LEFT, to match the shared pointerButton convention
        const buttonPressed: u32 = 1;
        const buttonReleased: u32 = 0;

        pub const ScrollAxis = enum(u32) {
            vertical = 0,
            horizontal = 1,
        };

        // Global variable to hold the current window instance for delegate callbacks
        var gCurrentWindow: ?*Self = null;

        pub const Handlers = struct {
            pointerMotion: ?struct {
                data: *anyopaque,
                function: *const fn (window: *Self, x: f32, y: f32, data: *anyopaque) void,
            } = null,
            pointerButton: ?struct {
                data: *anyopaque,
                function: *const fn (window: *Self, serial: u32, time: u32, button: u32, state: u32, data: *anyopaque) void,
            } = null,
            scroll: ?struct {
                data: *anyopaque,
                function: *const fn (window: *Self, axis: ScrollAxis, offset: f32, data: *anyopaque) void,
            } = null,
            resize: ?struct {
                data: *anyopaque,
                function: *const fn (
                    window: *Self,
                    newWidth: u32,
                    newHeight: u32,
                    newDpi: [2]u32,
                    data: *anyopaque,
                ) void,
            } = null,
        };

        // Objective-C / Cocoa types we need.
        const BOOL = c.BOOL;
        const NSInteger = c_long;
        const NSUInteger = c_ulong;

        const NSPoint = extern struct {
            x: f64,
            y: f64,
        };

        const NSSize = extern struct {
            width: f64,
            height: f64,
        };

        const NSRect = extern struct {
            origin: NSPoint,
            size: NSSize,
        };

        fn NSMakeRect(x: f64, y: f64, w: f64, h: f64) NSRect {
            return .{
                .origin = .{ .x = x, .y = y },
                .size = .{ .width = w, .height = h },
            };
        }

        const NSApplicationActivationPolicyRegular: NSInteger = 0;
        const NSBackingStoreBuffered: NSUInteger = 2;

        // NSEventType constants
        const NSEventTypeLeftMouseDown: NSUInteger = 1;
        const NSEventTypeLeftMouseUp: NSUInteger = 2;
        const NSEventTypeMouseMoved: NSUInteger = 5;
        const NSEventTypeLeftMouseDragged: NSUInteger = 6;
        const NSEventTypeRightMouseDragged: NSUInteger = 7;
        const NSEventTypeOtherMouseDragged: NSUInteger = 27;
        const NSEventTypeScrollWheel: NSUInteger = 22;
        const NSEventTypeKeyDown: NSUInteger = 10;
        const NSEventTypeKeyUp: NSUInteger = 11;
        /// Fired when *any* modifier key's state changes (Shift/Ctrl/Alt/Cmd/Caps).
        /// Pure modifier-key transitions on macOS never come through keyDown/keyUp.
        const NSEventTypeFlagsChanged: NSUInteger = 12;

        const NSEventModifierFlagCapsLock: NSUInteger = 1 << 16;
        const NSEventModifierFlagControl: NSUInteger = 1 << 18;
        const NSEventModifierFlagOption: NSUInteger = 1 << 19;
        const NSEventModifierFlagCommand: NSUInteger = 1 << 20;

        // kVK_* virtual key codes (HIToolbox/Events.h). Hardware-independent —
        // the same physical key reports the same kVK regardless of layout.
        fn macosKeycodeToKeys(code: u16) Keys {
            return switch (code) {
                0x00 => .{ .a = true },
                0x0B => .{ .b = true },
                0x08 => .{ .c = true },
                0x02 => .{ .d = true },
                0x0E => .{ .e = true },
                0x03 => .{ .f = true },
                0x05 => .{ .g = true },
                0x04 => .{ .h = true },
                0x22 => .{ .i = true },
                0x26 => .{ .j = true },
                0x28 => .{ .k = true },
                0x25 => .{ .l = true },
                0x2E => .{ .m = true },
                0x2D => .{ .n = true },
                0x1F => .{ .o = true },
                0x23 => .{ .p = true },
                0x0C => .{ .q = true },
                0x0F => .{ .r = true },
                0x01 => .{ .s = true },
                0x11 => .{ .t = true },
                0x20 => .{ .u = true },
                0x09 => .{ .v = true },
                0x0D => .{ .w = true },
                0x07 => .{ .x = true },
                0x10 => .{ .y = true },
                0x06 => .{ .z = true },
                0x1D => .{ .digit0 = true },
                0x12 => .{ .digit1 = true },
                0x13 => .{ .digit2 = true },
                0x14 => .{ .digit3 = true },
                0x15 => .{ .digit4 = true },
                0x17 => .{ .digit5 = true },
                0x16 => .{ .digit6 = true },
                0x1A => .{ .digit7 = true },
                0x1C => .{ .digit8 = true },
                0x19 => .{ .digit9 = true },
                0x7A => .{ .f1 = true },
                0x78 => .{ .f2 = true },
                0x63 => .{ .f3 = true },
                0x76 => .{ .f4 = true },
                0x60 => .{ .f5 = true },
                0x61 => .{ .f6 = true },
                0x62 => .{ .f7 = true },
                0x64 => .{ .f8 = true },
                0x65 => .{ .f9 = true },
                0x6D => .{ .f10 = true },
                0x67 => .{ .f11 = true },
                0x6F => .{ .f12 = true },
                // Modifier kVK codes (Shift L/R, Control L/R, Option L/R,
                // Command L/R, CapsLock) are intentionally not mapped here —
                // those transitions arrive as `NSEventTypeFlagsChanged`, not
                // keyDown/keyUp, and the unified `.shift/.control/.alt/.super/
                // .capsLock` flags are populated from `NSEvent.modifierFlags`
                // there.
                0x7B => .{ .arrowLeft = true },
                0x7C => .{ .arrowRight = true },
                0x7E => .{ .arrowUp = true },
                0x7D => .{ .arrowDown = true },
                0x73 => .{ .home = true },
                0x77 => .{ .end = true },
                0x74 => .{ .pageUp = true },
                0x79 => .{ .pageDown = true },
                0x30 => .{ .tab = true },
                0x35 => .{ .escape = true },
                0x24 => .{ .enter = true },
                0x31 => .{ .space = true },
                0x33 => .{ .backspace = true },
                0x75 => .{ .delete = true },
                0x72 => .{ .insert = true },
                else => .{},
            };
        }

        // NSEventModifierFlags
        const NSEventModifierFlagShift: NSUInteger = 1 << 17;

        const NSWindowStyleMaskTitled: NSUInteger = 1 << 0;
        const NSWindowStyleMaskClosable: NSUInteger = 1 << 1;
        const NSWindowStyleMaskMiniaturizable: NSUInteger = 1 << 2;
        const NSWindowStyleMaskResizable: NSUInteger = 1 << 3;

        fn msgSend(comptime FnPtr: type) FnPtr {
            return @ptrCast(&c.objc_msgSend);
        }

        fn sel(name: [*:0]const u8) c.SEL {
            return c.sel_registerName(name);
        }

        fn getClass(name: [*:0]const u8) c.Class {
            return @ptrCast(c.objc_getClass(name));
        }

        fn nsstring(cstr: [*:0]const u8) c.id {
            const NSString = getClass("NSString");
            const fnPtr = msgSend(*const fn (c.Class, c.SEL, [*:0]const u8) callconv(.c) c.id);
            return fnPtr(NSString, sel("stringWithUTF8String:"), cstr);
        }

        fn applicationShouldTerminateAfterLastWindowClosed(self: c.id, _cmd: c.SEL, application: c.id) callconv(.c) BOOL {
            _ = self;
            _ = _cmd;
            _ = application;
            return 1; // YES
        }

        fn windowDidResize(selfObj: c.id, _cmd: c.SEL, notification: c.id) callconv(.c) void {
            _ = selfObj;
            _ = _cmd;
            _ = notification;

            // Get the window instance from the global variable
            if (gCurrentWindow) |window| {
                // Get current window size
                const frame = msgSend(*const fn (c.id, c.SEL) callconv(.c) NSRect);
                const windowFrame = frame(window.window, sel("frame"));

                const newWidth: u32 = @intFromFloat(windowFrame.size.width);
                const newHeight: u32 = @intFromFloat(windowFrame.size.height);

                // Update window dimensions
                window.width = newWidth;
                window.height = newHeight;

                // Update DPI and scale (window may have moved to a different screen)
                window.updateDpiAndScale();

                // Call the resize handler if it exists
                if (window.handlers.resize) |handler| {
                    handler.function(window, newWidth, newHeight, window.dpi, handler.data);
                }
            }
        }

        fn windowDidChangeScreen(selfObj: c.id, _cmd: c.SEL, notification: c.id) callconv(.c) void {
            _ = selfObj;
            _ = _cmd;
            _ = notification;

            // When window moves to a different screen, update DPI and scale
            if (gCurrentWindow) |window| {
                window.updateDpiAndScale();

                // Notify via resize handler since DPI/scale may have changed
                if (window.handlers.resize) |handler| {
                    handler.function(window, window.width, window.height, window.dpi, handler.data);
                }
            }
        }

        fn windowDidChangeBackingProperties(selfObj: c.id, _cmd: c.SEL, notification: c.id) callconv(.c) void {
            _ = selfObj;
            _ = _cmd;
            _ = notification;

            // Called when backing scale factor changes (e.g., moving between Retina and non-Retina displays)
            if (gCurrentWindow) |window| {
                window.updateDpiAndScale();

                // Notify via resize handler since scale may have changed
                if (window.handlers.resize) |handler| {
                    handler.function(window, window.width, window.height, window.dpi, handler.data);
                }
            }
        }

        fn createMenuBar(app: c.id) void {
            const NSMenu = getClass("NSMenu");
            const NSMenuItem = getClass("NSMenuItem");

            const newId = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
            const addItem = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);
            const setMainMenu = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);
            const setSubmenu = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);

            const menubar = newId(NSMenu, sel("new"));
            const appMenuItem = newId(NSMenuItem, sel("new"));

            addItem(menubar, sel("addItem:"), appMenuItem);
            setMainMenu(app, sel("setMainMenu:"), menubar);

            const appMenu = newId(NSMenu, sel("new"));
            setSubmenu(appMenuItem, sel("setSubmenu:"), appMenu);

            const quitTitle = nsstring("Quit");
            const keyEquivalent = nsstring("q");

            const allocId = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
            const initQuit = msgSend(*const fn (c.id, c.SEL, c.id, c.SEL, c.id) callconv(.c) c.id);
            const setTarget = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);

            var quitItem = allocId(NSMenuItem, sel("alloc"));
            quitItem = initQuit(
                quitItem,
                sel("initWithTitle:action:keyEquivalent:"),
                quitTitle,
                sel("terminate:"),
                keyEquivalent,
            );

            setTarget(quitItem, sel("setTarget:"), app);
            addItem(appMenu, sel("addItem:"), quitItem);
        }

        // Everything native related to the window itself
        pool: ?*anyopaque,
        app: c.id,
        window: c.id,
        content_view: c.id,
        metal_layer: c.id,

        // Window state
        width: u32,
        height: u32,
        dpi: [2]u32,
        title: [:0]const u8,
        app_id: [:0]const u8,
        running: bool,

        allocator: std.mem.Allocator,

        handlers: Handlers,

        /// Guards `keysDown` / `pendingPressed` / `pendingReleased` between the
        /// input thread (where NSEvent callbacks fire) and Forbear's render thread
        /// (which drains via `snapshotKeyboard`).
        keysMutex: SpinLock = .{},
        keysDown: Keys = .{},
        pendingPressed: Keys = .{},
        pendingReleased: Keys = .{},

        pub fn init(
            allocator: std.mem.Allocator,
            width: u32,
            height: u32,
            title: [:0]const u8,
            app_id: [:0]const u8,
        ) !*Self {
            const self = try allocator.create(Self);
            errdefer allocator.destroy(self);

            self.allocator = allocator;
            self.width = width;
            self.height = height;
            self.dpi = .{ 96, 96 };
            self.title = title;
            self.app_id = app_id;
            self.running = true;

            self.handlers = .{};
            self.keysMutex = .{};
            self.keysDown = .{};
            self.pendingPressed = .{};
            self.pendingReleased = .{};

            self.pool = objc_autoreleasePoolPush();

            const NSApplication = getClass("NSApplication");
            const sharedApplication = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
            self.app = sharedApplication(NSApplication, sel("sharedApplication"));

            const setActivationPolicy = msgSend(*const fn (c.id, c.SEL, NSInteger) callconv(.c) BOOL);
            _ = setActivationPolicy(self.app, sel("setActivationPolicy:"), NSApplicationActivationPolicyRegular);

            // Create an application delegate at runtime.
            const NSObject = getClass("NSObject");
            const AppDelegate = c.objc_allocateClassPair(NSObject, "MinimalAppDelegate", 0);
            if (AppDelegate != null) {
                _ = c.class_addMethod(
                    AppDelegate,
                    sel("applicationShouldTerminateAfterLastWindowClosed:"),
                    @ptrCast(&applicationShouldTerminateAfterLastWindowClosed),
                    "c@:@",
                );
                c.objc_registerClassPair(AppDelegate);
            }

            const newId = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
            const setDelegate = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);
            const delegateClass = getClass("MinimalAppDelegate");
            const delegate = newId(delegateClass, sel("new"));
            setDelegate(self.app, sel("setDelegate:"), delegate);

            createMenuBar(self.app);

            const NSWindow = getClass("NSWindow");

            const contentRect = NSMakeRect(0, 0, @floatFromInt(width), @floatFromInt(height));
            const styleMask: NSUInteger = NSWindowStyleMaskTitled |
                NSWindowStyleMaskClosable |
                NSWindowStyleMaskMiniaturizable |
                NSWindowStyleMaskResizable;

            const alloc = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
            var windowObj = alloc(NSWindow, sel("alloc"));

            const initWithContentRect = msgSend(*const fn (c.id, c.SEL, NSRect, NSUInteger, NSUInteger, BOOL) callconv(.c) c.id);
            windowObj = initWithContentRect(
                windowObj,
                sel("initWithContentRect:styleMask:backing:defer:"),
                contentRect,
                styleMask,
                NSBackingStoreBuffered,
                0, // NO
            );
            if (windowObj == null) return error.WindowCreationFailed;

            self.window = windowObj;

            const setTitle = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);
            setTitle(self.window, sel("setTitle:"), nsstring(title.ptr));

            const center = msgSend(*const fn (c.id, c.SEL) callconv(.c) void);
            center(self.window, sel("center"));

            // Create a window delegate to handle resize and screen change events
            const WindowDelegate = c.objc_allocateClassPair(NSObject, "MinimalWindowDelegate", 0);
            if (WindowDelegate != null) {
                _ = c.class_addMethod(
                    WindowDelegate,
                    sel("windowDidResize:"),
                    @ptrCast(&windowDidResize),
                    "v@:@",
                );
                _ = c.class_addMethod(
                    WindowDelegate,
                    sel("windowDidChangeScreen:"),
                    @ptrCast(&windowDidChangeScreen),
                    "v@:@",
                );
                _ = c.class_addMethod(
                    WindowDelegate,
                    sel("windowDidChangeBackingProperties:"),
                    @ptrCast(&windowDidChangeBackingProperties),
                    "v@:@",
                );

                c.objc_registerClassPair(WindowDelegate);

                const windowDelegate = newId(@ptrCast(WindowDelegate), sel("new"));

                // Set the global window instance for delegate callbacks
                gCurrentWindow = self;

                setDelegate(self.window, sel("setDelegate:"), windowDelegate);
            }

            const contentView = msgSend(*const fn (c.id, c.SEL) callconv(.c) c.id);
            self.content_view = contentView(self.window, sel("contentView"));

            self.metal_layer = null;
            if (self.content_view != null) {
                const setWantsLayer = msgSend(*const fn (c.id, c.SEL, BOOL) callconv(.c) void);
                setWantsLayer(self.content_view, sel("setWantsLayer:"), 1);

                // MoltenVK expects a CAMetalLayer for presentation.
                const CAMetalLayer = getClass("CAMetalLayer");
                const newIdObj = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
                self.metal_layer = newIdObj(CAMetalLayer, sel("new"));

                const setLayer = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);
                setLayer(self.content_view, sel("setLayer:"), self.metal_layer);
            }

            const makeKeyAndOrderFront = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);
            makeKeyAndOrderFront(self.window, sel("makeKeyAndOrderFront:"), null);

            const activateIgnoringOtherApps = msgSend(*const fn (c.id, c.SEL, BOOL) callconv(.c) void);
            activateIgnoringOtherApps(self.app, sel("activateIgnoringOtherApps:"), 1);

            const finishLaunching = msgSend(*const fn (c.id, c.SEL) callconv(.c) void);
            finishLaunching(self.app, sel("finishLaunching"));

            // Get proper DPI and scale from the screen
            self.updateDpiAndScale();

            return self;
        }

        pub fn updateDpiAndScale(self: *Self) void {
            // Get the screen that the window is currently on
            const getScreen = msgSend(*const fn (c.id, c.SEL) callconv(.c) c.id);
            const screen = getScreen(self.window, sel("screen"));

            if (screen == null) {
                // Fallback to main screen if window's screen is not available
                const NSScreen = getClass("NSScreen");
                const mainScreen = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
                const main = mainScreen(NSScreen, sel("mainScreen"));
                if (main == null) return;
                self.updateDpiFromScreen(main);
            } else {
                self.updateDpiFromScreen(screen);
            }
        }

        fn updateDpiFromScreen(self: *Self, screen: c.id) void {
            // Get the backing scale factor (1.0 for standard displays, 2.0 for Retina)
            // const backingScaleFactor = msgSend(*const fn (c.id, c.SEL) callconv(.c) f64);
            // const scale_factor = backingScaleFactor(screen, sel("backingScaleFactor"));

            // Update scale (using the same 120-based scale as Linux for consistency)
            // scale = 120 means 1.0x, scale = 240 means 2.0x (Retina)
            // self.scale = @intFromFloat(@round(scale_factor * 120.0));

            // Get the NSDeviceDescription dictionary to access display ID
            const deviceDescription = msgSend(*const fn (c.id, c.SEL) callconv(.c) c.id);
            const deviceDesc = deviceDescription(screen, sel("deviceDescription"));

            if (deviceDesc == null) {
                // Fallback to 96 DPI if we can't get device description
                self.dpi = .{ 96, 96 };
                return;
            }

            // Get the NSScreenNumber (CGDirectDisplayID) from the device description
            const NSScreenNumber = nsstring("NSScreenNumber");
            const objectForKey = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) c.id);
            const screenNumberValue = objectForKey(deviceDesc, sel("objectForKey:"), NSScreenNumber);

            if (screenNumberValue == null) {
                self.dpi = .{ 96, 96 };
                return;
            }

            const unsignedIntValue = msgSend(*const fn (c.id, c.SEL) callconv(.c) c_uint);
            const displayId = unsignedIntValue(screenNumberValue, sel("unsignedIntValue"));

            // Get physical screen size in millimeters using CoreGraphics
            const physicalSizeMm = c.CGDisplayScreenSize(displayId);

            // Get pixel dimensions of the display
            const pixelWidth = c.CGDisplayPixelsWide(displayId);
            const pixelHeight = c.CGDisplayPixelsHigh(displayId);

            if (physicalSizeMm.width <= 0 or physicalSizeMm.height <= 0) {
                // Fallback if physical dimensions unavailable
                self.dpi = .{ 96, 96 };
                return;
            }

            // Calculate physical DPI (pixels per inch), similar to Linux Wayland implementation
            const millimetersPerInch: f64 = 25.4;
            const physicalDpiX = @as(f64, @floatFromInt(pixelWidth)) / (physicalSizeMm.width / millimetersPerInch);
            const physicalDpiY = @as(f64, @floatFromInt(pixelHeight)) / (physicalSizeMm.height / millimetersPerInch);

            // Apply backing scale factor (like Linux applies fractional scale)
            self.dpi = .{
                @intFromFloat(@round(physicalDpiX)),
                @intFromFloat(@round(physicalDpiY)),
            };

            std.log.debug(
                "macOS screen DPI: {d}x{d}, physical size: {d:.1}x{d:.1}mm, pixels: {d}x{d}",
                .{ self.dpi[0], self.dpi[1], physicalSizeMm.width, physicalSizeMm.height, pixelWidth, pixelHeight },
            );
        }

        pub fn nativeView(self: *Self) ?*anyopaque {
            if (self.content_view == null) return null;
            return @ptrCast(self.content_view);
        }

        pub fn nativeMetalLayer(self: *const Self) ?*anyopaque {
            if (self.metal_layer == null) return null;
            return @ptrCast(self.metal_layer);
        }

        pub fn isHoldingShift(_: *const Self) bool {
            const NSEvent = getClass("NSEvent");
            const modifierFlags = msgSend(*const fn (c.Class, c.SEL) callconv(.c) NSUInteger);
            const flags = modifierFlags(NSEvent, sel("modifierFlags"));
            return (flags & NSEventModifierFlagShift) != 0;
        }

        pub fn setCursor(self: *Self, cursor: Cursor, serial: u32) !void {
            _ = self;
            _ = serial;

            const NSCursor = getClass("NSCursor");
            const getCursor = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
            const set = msgSend(*const fn (c.id, c.SEL) callconv(.c) void);

            const nsCursor = switch (cursor) {
                .default => getCursor(NSCursor, sel("arrowCursor")),
                .text => getCursor(NSCursor, sel("IBeamCursor")),
                .pointer => getCursor(NSCursor, sel("pointingHandCursor")),
            };

            if (nsCursor != null) {
                set(nsCursor, sel("set"));
            }
        }

        /// Returns the target frame time in nanoseconds based on the display's refresh rate.
        /// Falls back to 60Hz (~16.67ms) if the refresh rate cannot be determined.
        pub fn targetFrameTimeNs(self: *const Self) u64 {
            const fallback60hz: u64 = 16_666_667; // ~60 Hz in nanoseconds

            // Get the screen that the window is currently on
            const getScreen = msgSend(*const fn (c.id, c.SEL) callconv(.c) c.id);
            var screen = getScreen(self.window, sel("screen"));

            if (screen == null) {
                // Fallback to main screen if window's screen is not available
                const NSScreen = getClass("NSScreen");
                const mainScreen = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
                screen = mainScreen(NSScreen, sel("mainScreen"));
                if (screen == null) return fallback60hz;
            }

            // Get the display ID for this screen
            const deviceDescription = msgSend(*const fn (c.id, c.SEL) callconv(.c) c.id);
            const deviceDesc = deviceDescription(screen, sel("deviceDescription"));
            if (deviceDesc == null) return fallback60hz;

            // Get the NSScreenNumber (CGDirectDisplayID) from the device description
            const NSScreenNumber = nsstring("NSScreenNumber");
            const objectForKey = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) c.id);
            const screenNumberValue = objectForKey(deviceDesc, sel("objectForKey:"), NSScreenNumber);
            if (screenNumberValue == null) return fallback60hz;

            // Get the unsigned int value (CGDirectDisplayID)
            const unsignedIntValue = msgSend(*const fn (c.id, c.SEL) callconv(.c) c_uint);
            const displayId = unsignedIntValue(screenNumberValue, sel("unsignedIntValue"));

            // Use Core Graphics to get the display mode and refresh rate
            const displayMode = c.CGDisplayCopyDisplayMode(displayId);
            if (displayMode == null) return fallback60hz;
            defer c.CGDisplayModeRelease(displayMode);

            const refreshRate = c.CGDisplayModeGetRefreshRate(displayMode);

            // Some displays (especially built-in Retina displays) report 0 refresh rate
            // In that case, fall back to 60Hz
            if (refreshRate <= 0) return fallback60hz;

            // Convert refresh rate (Hz) to frame time (nanoseconds)
            return @intFromFloat(@round(1_000_000_000.0 / refreshRate));
        }

        fn processEvent(self: *Self, event: c.id) void {
            // Get event type
            const getType = msgSend(*const fn (c.id, c.SEL) callconv(.c) NSUInteger);
            const eventType = getType(event, sel("type"));

            // Handle mouse motion events
            if (eventType == NSEventTypeMouseMoved or
                eventType == NSEventTypeLeftMouseDragged or
                eventType == NSEventTypeRightMouseDragged or
                eventType == NSEventTypeOtherMouseDragged)
            {
                if (self.handlers.pointerMotion) |handler| {
                    // Get the mouse location in window coordinates (relative to content view, origin at bottom-left)
                    const locationInWindow = msgSend(*const fn (c.id, c.SEL) callconv(.c) NSPoint);
                    const location = locationInWindow(event, sel("locationInWindow"));

                    // Get the content view's bounds to get the correct height for coordinate conversion
                    const getBounds = msgSend(*const fn (c.id, c.SEL) callconv(.c) NSRect);
                    const contentBounds = getBounds(self.content_view, sel("bounds"));

                    // macOS has origin at bottom-left, convert to top-left origin using content view height
                    const x: f32 = @floatCast(location.x);
                    const y: f32 = @as(f32, @floatCast(contentBounds.size.height)) - @as(f32, @floatCast(location.y));

                    handler.function(self, x, y, handler.data);
                }
            }

            if (eventType == NSEventTypeLeftMouseDown or eventType == NSEventTypeLeftMouseUp) {
                if (self.handlers.pointerButton) |handler| {
                    const state = if (eventType == NSEventTypeLeftMouseDown)
                        buttonPressed
                    else
                        buttonReleased;
                    handler.function(self, 0, 0, linuxLeftMouseButton, state, handler.data);
                }
            }

            if (eventType == NSEventTypeFlagsChanged) {
                const modifierFlagsFn = msgSend(*const fn (c.id, c.SEL) callconv(.c) NSUInteger);
                const flags = modifierFlagsFn(event, sel("modifierFlags"));

                var current: Keys = .{};
                current.shift = (flags & NSEventModifierFlagShift) != 0;
                current.control = (flags & NSEventModifierFlagControl) != 0;
                current.alt = (flags & NSEventModifierFlagOption) != 0;
                current.super = (flags & NSEventModifierFlagCommand) != 0;
                current.capsLock = (flags & NSEventModifierFlagCapsLock) != 0;

                self.keysMutex.lock();
                defer self.keysMutex.unlock();

                var oldMods: Keys = .{};
                oldMods.shift = self.keysDown.shift;
                oldMods.control = self.keysDown.control;
                oldMods.alt = self.keysDown.alt;
                oldMods.super = self.keysDown.super;
                oldMods.capsLock = self.keysDown.capsLock;

                self.pendingPressed = self.pendingPressed.with(current.without(oldMods));
                self.pendingReleased = self.pendingReleased.with(oldMods.without(current));

                self.keysDown.shift = current.shift;
                self.keysDown.control = current.control;
                self.keysDown.alt = current.alt;
                self.keysDown.super = current.super;
                self.keysDown.capsLock = current.capsLock;
                return;
            }

            if (eventType == NSEventTypeKeyDown or eventType == NSEventTypeKeyUp) {
                const keyCodeFn = msgSend(*const fn (c.id, c.SEL) callconv(.c) u16);
                const isARepeatFn = msgSend(*const fn (c.id, c.SEL) callconv(.c) BOOL);

                const code = keyCodeFn(event, sel("keyCode"));
                const key = macosKeycodeToKeys(code);
                const isRepeat = isARepeatFn(event, sel("isARepeat")) != 0;

                self.keysMutex.lock();
                if (eventType == NSEventTypeKeyDown) {
                    // Only fresh press transitions flip the edge bit; OS-driven
                    // repeats just keep the held bit set (already set).
                    if (!isRepeat) {
                        self.pendingPressed = self.pendingPressed.with(key);
                        self.keysDown = self.keysDown.with(key);
                    }
                } else {
                    self.pendingReleased = self.pendingReleased.with(key);
                    self.keysDown = self.keysDown.without(key);
                }
                self.keysMutex.unlock();
            }

            // Handle scroll wheel events
            if (eventType == NSEventTypeScrollWheel) {
                if (self.handlers.scroll) |handler| {
                    const scrollingDeltaY = msgSend(*const fn (c.id, c.SEL) callconv(.c) f64);
                    const deltaY: f32 = @floatCast(scrollingDeltaY(event, sel("scrollingDeltaY")));

                    const scrollingDeltaX = msgSend(*const fn (c.id, c.SEL) callconv(.c) f64);
                    const deltaX: f32 = @floatCast(scrollingDeltaX(event, sel("scrollingDeltaX")));

                    // macOS already applies the user's scroll direction preference
                    // (natural scrolling, Mac Mouse Fix reversal, etc.) to the delta
                    // values. We negate unconditionally to convert from macOS convention
                    // (positive deltaY = traditional scroll-up / content-down) to
                    // Forbear's convention (positive offset = scroll position increases
                    // = viewport moves down).
                    if (deltaY != 0) {
                        handler.function(self, .vertical, -deltaY, handler.data);
                    }
                    if (deltaX != 0) {
                        handler.function(self, .horizontal, -deltaX, handler.data);
                    }
                }
            }
        }

        /// Drain the keyboard state for the current frame. Holds the keys mutex
        /// just long enough to copy the bitsets and reset the pending fields.
        pub fn snapshotKeyboard(self: *Self) KeyboardSnapshot {
            self.keysMutex.lock();
            defer self.keysMutex.unlock();

            const snap: KeyboardSnapshot = .{
                .held = self.keysDown,
                .pressed = self.pendingPressed,
                .released = self.pendingReleased,
            };
            self.pendingPressed = .{};
            self.pendingReleased = .{};
            return snap;
        }

        pub fn handleEvents(self: *Self) !void {
            const NSDate = getClass("NSDate");
            const distantFuture = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
            const distantPast = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);

            const maskAny: NSUInteger = std.math.maxInt(NSUInteger);
            const mode = nsstring("kCFRunLoopDefaultMode");

            const nextEvent = msgSend(*const fn (c.id, c.SEL, NSUInteger, c.id, c.id, BOOL) callconv(.c) c.id);
            const sendEvent = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);
            const updateWindows = msgSend(*const fn (c.id, c.SEL) callconv(.c) void);
            const isVisible = msgSend(*const fn (c.id, c.SEL) callconv(.c) BOOL);

            // Enable mouse moved events for our window
            const setAcceptsMouseMovedEvents = msgSend(*const fn (c.id, c.SEL, BOOL) callconv(.c) void);
            setAcceptsMouseMovedEvents(self.window, sel("setAcceptsMouseMovedEvents:"), 1);

            while (self.running) {
                // Block waiting for the next event (like GetMessageW on Windows or wl_display_dispatch on Linux)
                const blockingDate = distantFuture(NSDate, sel("distantFuture"));
                const event = nextEvent(
                    self.app,
                    sel("nextEventMatchingMask:untilDate:inMode:dequeue:"),
                    maskAny,
                    blockingDate,
                    mode,
                    1, // YES
                );

                if (event != null) {
                    // Process event for our handlers first
                    self.processEvent(event);

                    // Then let the system handle it
                    sendEvent(self.app, sel("sendEvent:"), event);

                    // Process any additional pending events without blocking
                    const nonBlockingDate = distantPast(NSDate, sel("distantPast"));
                    while (true) {
                        const pendingEvent = nextEvent(
                            self.app,
                            sel("nextEventMatchingMask:untilDate:inMode:dequeue:"),
                            maskAny,
                            nonBlockingDate,
                            mode,
                            1,
                        );
                        if (pendingEvent == null) break;
                        self.processEvent(pendingEvent);
                        sendEvent(self.app, sel("sendEvent:"), pendingEvent);
                    }

                    updateWindows(self.app, sel("updateWindows"));
                }

                // Check if window was closed
                if (isVisible(self.window, sel("isVisible")) == 0) {
                    self.running = false;
                }
            }
        }

        pub fn deinit(self: *Self) void {
            // Clear the global window reference
            if (gCurrentWindow == self) {
                gCurrentWindow = null;
            }

            if (self.window != null) {
                const close = msgSend(*const fn (c.id, c.SEL) callconv(.c) void);
                close(self.window, sel("close"));
            }

            objc_autoreleasePoolPop(self.pool);
            self.allocator.destroy(self);
        }
    },
    else => @compileError("Unsupported OS"),
};
