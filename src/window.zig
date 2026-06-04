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

pub const Window = struct {
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
};
