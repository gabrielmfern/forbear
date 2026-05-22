const std = @import("std");
const posix = std.posix;
const os = std.os;

const c = @import("c");
const window_root = @import("root.zig");
const Cursor = window_root.Cursor;
pub const Key = window_root.Key;
pub const KeyboardKey = window_root.KeyboardKey;

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
    /// One-shot: fires only on the initial transition to pressed.
    keypress: ?struct {
        data: *anyopaque,
        function: *const fn (window: *Self, key: KeyboardKey, data: *anyopaque) void,
    } = null,
    /// Fires on initial press and again for each OS-driven repeat tick
    /// (rate/delay come from `wl_keyboard.repeat_info`). `key.is_repeat`
    /// distinguishes synthetic repeats from the initial press.
    keydown: ?struct {
        data: *anyopaque,
        function: *const fn (window: *Self, key: KeyboardKey, data: *anyopaque) void,
    } = null,
    /// One-shot: fires only on the transition to released.
    keyup: ?struct {
        data: *anyopaque,
        function: *const fn (window: *Self, key: KeyboardKey, data: *anyopaque) void,
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
wlKeyboard: *c.wl_keyboard,

/// Key-repeat parameters from `wl_keyboard.repeat_info`. `keyRepeatRate == 0`
/// means the compositor wants repeats disabled.
keyRepeatRate: i32 = 25,
keyRepeatDelay: i32 = 600,
/// The currently held repeatable key, if any. Drives the timerfd that
/// synthesizes `keydown` events. `xkb_keycode` is kept for the
/// release-match check (so we only cancel when *this* key is released);
/// `key` is what we ship in the synthetic event.
heldKey: ?struct {
    xkb_keycode: u32,
    key: Key,
} = null,
/// CLOCK_MONOTONIC timerfd that fires when the next synthetic `keydown`
/// is due. Disarmed when no key is held or the held key isn't repeatable.
keyRepeatTimerFd: i32 = -1,

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

        fn is(self: @This(), interface_name: []const u8) bool {
            const selfName = self.interface.name[0..std.mem.len(self.interface.name)];
            return std.mem.eql(u8, interface_name, selfName);
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
    physical_width: i32,
    physical_height: i32,
    subpixel: i32,
    make: [*c]const u8,
    model: [*c]const u8,
    transform: i32,
) callconv(.c) void {
    const window: *Self = @ptrCast(@alignCast(data));
    _ = wlOutput;
    _ = x;
    _ = y;
    window.physicalWidthMilimeters = physical_width;
    window.physicalHeightMilimeters = physical_height;
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
    interface_ptr: [*c]const u8,
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

    const interfaceName: []const u8 = interface_ptr[0..std.mem.len(interface_ptr)];

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

/// Translate an XKB keysym into the cross-platform `Key` enum.
/// Returns `.unknown` for keys not yet covered.
fn keysymToKey(sym: u32) Key {
    return switch (sym) {
        c.XKB_KEY_Tab, c.XKB_KEY_ISO_Left_Tab => .tab,
        c.XKB_KEY_Escape => .escape,
        c.XKB_KEY_Return, c.XKB_KEY_KP_Enter => .enter,
        c.XKB_KEY_space => .space,
        c.XKB_KEY_BackSpace => .backspace,
        c.XKB_KEY_Delete => .delete,
        c.XKB_KEY_Insert => .insert,
        c.XKB_KEY_Home => .home,
        c.XKB_KEY_End => .end,
        c.XKB_KEY_Page_Up => .page_up,
        c.XKB_KEY_Page_Down => .page_down,
        c.XKB_KEY_Left => .arrow_left,
        c.XKB_KEY_Right => .arrow_right,
        c.XKB_KEY_Up => .arrow_up,
        c.XKB_KEY_Down => .arrow_down,
        c.XKB_KEY_Shift_L => .shift_left,
        c.XKB_KEY_Shift_R => .shift_right,
        c.XKB_KEY_Control_L => .control_left,
        c.XKB_KEY_Control_R => .control_right,
        c.XKB_KEY_Alt_L => .alt_left,
        c.XKB_KEY_Alt_R => .alt_right,
        c.XKB_KEY_Super_L, c.XKB_KEY_Meta_L => .super_left,
        c.XKB_KEY_Super_R, c.XKB_KEY_Meta_R => .super_right,
        c.XKB_KEY_Caps_Lock => .caps_lock,
        c.XKB_KEY_F1 => .f1,
        c.XKB_KEY_F2 => .f2,
        c.XKB_KEY_F3 => .f3,
        c.XKB_KEY_F4 => .f4,
        c.XKB_KEY_F5 => .f5,
        c.XKB_KEY_F6 => .f6,
        c.XKB_KEY_F7 => .f7,
        c.XKB_KEY_F8 => .f8,
        c.XKB_KEY_F9 => .f9,
        c.XKB_KEY_F10 => .f10,
        c.XKB_KEY_F11 => .f11,
        c.XKB_KEY_F12 => .f12,
        c.XKB_KEY_a, c.XKB_KEY_A => .a,
        c.XKB_KEY_b, c.XKB_KEY_B => .b,
        c.XKB_KEY_c, c.XKB_KEY_C => .c,
        c.XKB_KEY_d, c.XKB_KEY_D => .d,
        c.XKB_KEY_e, c.XKB_KEY_E => .e,
        c.XKB_KEY_f, c.XKB_KEY_F => .f,
        c.XKB_KEY_g, c.XKB_KEY_G => .g,
        c.XKB_KEY_h, c.XKB_KEY_H => .h,
        c.XKB_KEY_i, c.XKB_KEY_I => .i,
        c.XKB_KEY_j, c.XKB_KEY_J => .j,
        c.XKB_KEY_k, c.XKB_KEY_K => .k,
        c.XKB_KEY_l, c.XKB_KEY_L => .l,
        c.XKB_KEY_m, c.XKB_KEY_M => .m,
        c.XKB_KEY_n, c.XKB_KEY_N => .n,
        c.XKB_KEY_o, c.XKB_KEY_O => .o,
        c.XKB_KEY_p, c.XKB_KEY_P => .p,
        c.XKB_KEY_q, c.XKB_KEY_Q => .q,
        c.XKB_KEY_r, c.XKB_KEY_R => .r,
        c.XKB_KEY_s, c.XKB_KEY_S => .s,
        c.XKB_KEY_t, c.XKB_KEY_T => .t,
        c.XKB_KEY_u, c.XKB_KEY_U => .u,
        c.XKB_KEY_v, c.XKB_KEY_V => .v,
        c.XKB_KEY_w, c.XKB_KEY_W => .w,
        c.XKB_KEY_x, c.XKB_KEY_X => .x,
        c.XKB_KEY_y, c.XKB_KEY_Y => .y,
        c.XKB_KEY_z, c.XKB_KEY_Z => .z,
        c.XKB_KEY_0 => .digit_0,
        c.XKB_KEY_1 => .digit_1,
        c.XKB_KEY_2 => .digit_2,
        c.XKB_KEY_3 => .digit_3,
        c.XKB_KEY_4 => .digit_4,
        c.XKB_KEY_5 => .digit_5,
        c.XKB_KEY_6 => .digit_6,
        c.XKB_KEY_7 => .digit_7,
        c.XKB_KEY_8 => .digit_8,
        c.XKB_KEY_9 => .digit_9,
        else => .unknown,
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
    window.cancelKeyRepeat();
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
    const window: *Self = @ptrCast(@alignCast(data));

    // wl_keyboard reports evdev keycodes; xkb keycodes are evdev + 8.
    const xkbKeycode: u32 = key + 8;
    const keysym: u32 = if (window.xkbState) |xs|
        c.xkb_state_key_get_one_sym(xs, xkbKeycode)
    else
        0;
    const mapped: Key = keysymToKey(keysym);

    const ev: KeyboardKey = .{
        .time = time,
        .key = mapped,
        .is_repeat = false,
    };

    if (state == c.WL_KEYBOARD_KEY_STATE_PRESSED) {
        if (window.handlers.keypress) |h| h.function(window, ev, h.data);
        if (window.handlers.keydown) |h| h.function(window, ev, h.data);

        // Arm repeat only if the compositor enabled repeats and the keymap
        // marks this key as repeatable.
        const repeats: bool = if (window.xkbKeymap) |km|
            c.xkb_keymap_key_repeats(km, xkbKeycode) != 0
        else
            true;
        if (window.keyRepeatRate > 0 and repeats) {
            window.heldKey = .{ .xkb_keycode = xkbKeycode, .key = mapped };
            window.armRepeatTimer(window.keyRepeatDelay);
        } else {
            window.cancelKeyRepeat();
        }
    } else if (state == c.WL_KEYBOARD_KEY_STATE_RELEASED) {
        if (window.handlers.keyup) |h| h.function(window, ev, h.data);
        if (window.heldKey) |held| {
            if (held.xkb_keycode == xkbKeycode) window.cancelKeyRepeat();
        }
    }
}

fn keyboardHandleModifiers(
    data: ?*anyopaque,
    wl_keyboard: ?*c.wl_keyboard,
    serial: u32,
    mods_depressed: u32,
    mods_latched: u32,
    mods_locked: u32,
    group: u32,
) callconv(.c) void {
    _ = wl_keyboard;
    _ = serial;

    const window: *Self = @ptrCast(@alignCast(data));

    if (window.xkbState) |xkbState| {
        _ = c.xkb_state_update_mask(xkbState, mods_depressed, mods_latched, mods_locked, 0, 0, group);
    }
}

fn keyboardHandleRepeatInfo(
    data: ?*anyopaque,
    wl_keyboard: ?*c.wl_keyboard,
    rate: i32,
    delay: i32,
) callconv(.c) void {
    _ = wl_keyboard;
    const window: *Self = @ptrCast(@alignCast(data));
    window.keyRepeatRate = rate;
    window.keyRepeatDelay = delay;
    if (rate == 0) window.cancelKeyRepeat();
}

/// Arm `keyRepeatTimerFd` to fire once after `ms` milliseconds.
/// Pass 0 to disarm.
fn armRepeatTimer(self: *Self, ms: i32) void {
    const ns_total: i64 = @as(i64, ms) * std.time.ns_per_ms;
    const its: std.os.linux.itimerspec = .{
        .it_interval = .{ .sec = 0, .nsec = 0 },
        .it_value = .{
            .sec = @intCast(@divTrunc(ns_total, std.time.ns_per_s)),
            .nsec = @intCast(@mod(ns_total, std.time.ns_per_s)),
        },
    };
    _ = std.os.linux.timerfd_settime(self.keyRepeatTimerFd, .{}, &its, null);
}

fn cancelKeyRepeat(self: *Self) void {
    self.heldKey = null;
    self.armRepeatTimer(0);
}

/// Called from the event loop when the timerfd fires. Emits one synthetic
/// `keydown` for the currently held key and re-arms at the OS-described rate.
fn fireKeyRepeat(self: *Self) void {
    const held = self.heldKey orelse return;
    if (self.keyRepeatRate <= 0) {
        self.cancelKeyRepeat();
        return;
    }

    if (self.handlers.keydown) |h| {
        const ev: KeyboardKey = .{
            .time = 0,
            .key = held.key,
            .is_repeat = true,
        };
        h.function(self, ev, h.data);
    }

    const interval_ms: i32 = @divTrunc(1000, self.keyRepeatRate);
    self.armRepeatTimer(if (interval_ms <= 0) 1 else interval_ms);
}

const wlKeyboardListener: c.wl_keyboard_listener = .{
    .keymap = keyboardHandleKeymap,
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

    window.keyRepeatRate = 25;
    window.keyRepeatDelay = 600;
    window.heldKey = null;
    {
        const rc = std.os.linux.timerfd_create(.MONOTONIC, .{ .CLOEXEC = true });
        switch (std.posix.errno(rc)) {
            .SUCCESS => {},
            else => return error.FailedToCreateTimerFd,
        }
        window.keyRepeatTimerFd = @intCast(rc);
    }
    errdefer _ = std.os.linux.close(window.keyRepeatTimerFd);

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

pub fn setKeypressHandler(
    self: *Self,
    handler: *const fn (window: *Self, key: KeyboardKey, data: *anyopaque) void,
    data: *anyopaque,
) void {
    self.handlers.keypress = .{ .data = data, .function = handler };
}

pub fn setKeydownHandler(
    self: *Self,
    handler: *const fn (window: *Self, key: KeyboardKey, data: *anyopaque) void,
    data: *anyopaque,
) void {
    self.handlers.keydown = .{ .data = data, .function = handler };
}

pub fn setKeyupHandler(
    self: *Self,
    handler: *const fn (window: *Self, key: KeyboardKey, data: *anyopaque) void,
    data: *anyopaque,
) void {
    self.handlers.keyup = .{ .data = data, .function = handler };
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
    const displayFd: i32 = c.wl_display_get_fd(self.wlDisplay);

    while (self.running) {
        // Drain anything already queued before we block on poll. This is the
        // standard `prepare_read` dance — keep dispatching pending events
        // until prepare_read succeeds (returns 0).
        while (c.wl_display_prepare_read(self.wlDisplay) != 0) {
            if (c.wl_display_dispatch_pending(self.wlDisplay) == -1) {
                return error.WaylandDispatchFailed;
            }
        }

        // Flush outgoing requests to the compositor.
        while (true) {
            const flushed = c.wl_display_flush(self.wlDisplay);
            if (flushed >= 0) break;
            if (std.posix.errno(@as(usize, @bitCast(@as(isize, flushed)))) == .AGAIN) {
                // socket would block; let poll wait for OUT below
                break;
            }
            c.wl_display_cancel_read(self.wlDisplay);
            return error.WaylandFlushFailed;
        }

        var fds = [_]std.posix.pollfd{
            .{ .fd = displayFd, .events = std.posix.POLL.IN, .revents = 0 },
            .{ .fd = self.keyRepeatTimerFd, .events = std.posix.POLL.IN, .revents = 0 },
        };
        const n = std.posix.poll(&fds, -1) catch |err| {
            c.wl_display_cancel_read(self.wlDisplay);
            return err;
        };
        if (n == 0) {
            c.wl_display_cancel_read(self.wlDisplay);
            continue;
        }

        if (fds[0].revents & std.posix.POLL.IN != 0) {
            if (c.wl_display_read_events(self.wlDisplay) == -1) {
                return error.WaylandReadFailed;
            }
            if (c.wl_display_dispatch_pending(self.wlDisplay) == -1) {
                return error.WaylandDispatchFailed;
            }
        } else {
            c.wl_display_cancel_read(self.wlDisplay);
        }

        if (fds[1].revents & std.posix.POLL.IN != 0) {
            var expirations: u64 = 0;
            _ = std.posix.read(self.keyRepeatTimerFd, std.mem.asBytes(&expirations)) catch {};
            self.fireKeyRepeat();
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

    if (self.keyRepeatTimerFd >= 0) _ = std.os.linux.close(self.keyRepeatTimerFd);

    self.allocator.destroy(self);
}
