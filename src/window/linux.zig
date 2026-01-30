const std = @import("std");
const posix = std.posix;
const os = std.os;

const c = @import("../c.zig").c;

const Self = @This();

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
        function: *const fn (window: *Self, time: u32, x: f32, y: f32, data: *anyopaque) void,
    } = null,
    pointerButton: ?struct {
        data: *anyopaque,
        function: *const fn (window: *Self, serial: u32, time: u32, button: u32, state: u32, data: *anyopaque) void,
    } = null,
    pointerAxis: ?struct {
        data: *anyopaque,
        function: *const fn (window: *Self, time: u32, axis: u32, value: c.wl_fixed_t, data: *anyopaque) void,
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

// cursor
wlPointer: *c.wl_pointer,
wlKeyboard: *c.wl_keyboard,
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

        fn bind(self: @This(), registry: ?*c.wl_registry, name: u32) *T {
            return @ptrCast(@alignCast(
                c.wl_registry_bind(
                    registry,
                    name,
                    self.interface,
                    self.version,
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
    _ = version;

    const window: *Self = @ptrCast(@alignCast(data.?));

    const compositor = BindingInfo(c.wl_compositor).new(
        &c.wl_compositor_interface,
        4,
    );
    const output = BindingInfo(c.wl_output).new(
        &c.wl_output_interface,
        3,
    );
    const shm = BindingInfo(c.wl_shm).new(
        &c.wl_shm_interface,
        1,
    );
    const xdgWmBase = BindingInfo(c.xdg_wm_base).new(
        &c.xdg_wm_base_interface,
        1,
    );
    const seat = BindingInfo(c.wl_seat).new(
        &c.wl_seat_interface,
        1,
    );
    const fractionalScaleManager = BindingInfo(c.wp_fractional_scale_manager_v1).new(
        &c.wp_fractional_scale_manager_v1_interface,
        1,
    );
    const viewporter = BindingInfo(c.wp_viewporter).new(
        &c.wp_viewporter_interface,
        1,
    );

    const interfaceName: []const u8 = interface_ptr[0..std.mem.len(interface_ptr)];

    if (compositor.is(interfaceName)) {
        window.wlCompositor = compositor.bind(registry, name);
    } else if (shm.is(interfaceName)) {
        window.wlShm = shm.bind(registry, name);
    } else if (xdgWmBase.is(interfaceName)) {
        window.xdgWmBase = xdgWmBase.bind(registry, name);
        _ = c.xdg_wm_base_add_listener(
            window.xdgWmBase,
            &xdgWmBaseListener,
            data,
        );
    } else if (seat.is(interfaceName)) {
        window.wlSeat = seat.bind(registry, name);

        window.wlPointer = c.wl_seat_get_pointer(window.wlSeat) orelse @panic("could not get wl_pointer from wl_seat");
        _ = c.wl_pointer_add_listener(window.wlPointer, &wlPointerListener, data);

        window.wlKeyboard = c.wl_seat_get_keyboard(window.wlSeat) orelse @panic("could not get wl_keyboard from wl_seat");
        _ = c.wl_keyboard_add_listener(window.wlKeyboard, &wlKeyboardListener, data);
    } else if (output.is(interfaceName)) {
        window.wlOutput = output.bind(registry, name);

        _ = c.wl_output_add_listener(window.wlOutput, &outputListener, data);
    } else if (fractionalScaleManager.is(interfaceName)) {
        window.wpFractionalScaleManager = fractionalScaleManager.bind(registry, name);
    } else if (viewporter.is(interfaceName)) {
        window.wpViewporter = viewporter.bind(registry, name);
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
    _ = window;
    c.xdg_surface_ack_configure(
        xdgSurface,
        serial,
    );
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

const xdgToplevelListener: c.xdg_toplevel_listener = .{
    .configure = xdgToplevelConfigure,
    .close = xdgToplevelClose,
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
            time,
            @floatCast(c.wl_fixed_to_double(surfaceX)),
            @floatCast(c.wl_fixed_to_double(surfaceY)),
            handler.data,
        );
    }
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
    if (window.handlers.pointerAxis) |handler| {
        handler.function(window, time, axis, value, handler.data);
    }
    _ = wlPointer;
}

const wlPointerListener: c.wl_pointer_listener = .{
    .enter = pointerHandleEnter,
    .leave = pointerHandleLeave,
    .motion = pointerHandleMotion,
    .button = pointerHandleButton,
    .axis = pointerHandleAxis,
};

fn keyboardHandleKeymap(
    data: ?*anyopaque,
    wlKeyboard: ?*c.wl_keyboard,
    format: u32,
    fd: i32,
    size: u32,
) callconv(.c) void {
    std.debug.assert(format == c.WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1);

    // std.posix.mmap(
    //     null,
    //     size,
    //     undefined,
    //     undefined,
    //     fd,
    //     0,
    // ) catch @panic("failed to read the given keymap");

    _ = fd;
    _ = size;
    _ = wlKeyboard;
    _ = data;
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
    const window: *Self = @ptrCast(@alignCast(data));
    _ = window;
    _ = serial;
    // if (window.handlers.keyboard_leave) |handler| {
    //     handler.function(window, serial, handler.data);
    // }
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
    const window: *Self = @ptrCast(@alignCast(data));
    _ = window;
    _ = serial;
    _ = time;
    _ = key;
    _ = state;
    // if (window.handlers.keyboard_key) |handler| {
    //     handler.function(window, serial, time, key, state, handler.data);
    // }
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
    const window: *Self = @ptrCast(@alignCast(data));
    // window.modifiers = .{
    //     .mods_depressed = mods_depressed,
    //     .mods_latched = mods_latched,
    //     .mods_locked = mods_locked,
    //     .group = group,
    // };
    _ = window;
    _ = mods_depressed;
    _ = mods_latched;
    _ = mods_locked;
    _ = group;
    _ = serial;
    // if (window.handlers.keyboard_modifiers) |handler| {
    //     handler.function(window, serial, mods_depressed, mods_latched, mods_locked, group, handler.data);
    // }
}

fn keyboardHandleRepeatInfo(
    data: ?*anyopaque,
    wl_keyboard: ?*c.wl_keyboard,
    rate: i32,
    delay: i32,
) callconv(.c) void {
    _ = wl_keyboard;
    const window: *Self = @ptrCast(@alignCast(data));
    _ = window;
    _ = rate;
    _ = delay;
    // if (window.handlers.keyboard_repeat_info) |handler| {
    //     handler.function(window, rate, delay, handler.data);
    // }
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

    if (window.wpFractionalScaleManager) |manager| {
        window.wpFractionalScale = c.wp_fractional_scale_manager_v1_get_fractional_scale(manager, window.wlSurface);
        _ = c.wp_fractional_scale_v1_add_listener(window.wpFractionalScale, &fractionalScaleListener, @ptrCast(@alignCast(window)));
    }

    if (window.wpViewporter) |viewporter| {
        window.wpViewport = c.wp_viewporter_get_viewport(viewporter, window.wlSurface);
        c.wp_viewport_set_destination(window.wpViewport, @intCast(window.width), @intCast(window.height));
    }

    c.wl_surface_commit(window.wlSurface);

    // gl.pixelStorei(gl.UNPACK_ALIGNMENT, 1);
    // gl.enable(gl.BLEND);
    // gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

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

const Cursor = enum {
    default,
    text,
    pointer,
};

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

pub fn setCursor(self: *Self, cursor: Cursor, serial: u32) !void {
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
        serial,
        self.cursorWlSurface,
        @intCast(wlCursorImage.*.hotspot_x),
        @intCast(wlCursorImage.*.hotspot_y),
    );
}

pub fn handleEvents(self: *Self) !void {
    while (self.running) {
        if (c.wl_display_dispatch(self.wlDisplay) != 0) {
            return error.WaylandDispatchFailed;
        }

        if (c.wl_display_flush(self.wlDisplay) == -1) {
            c.wl_display_cancel_read(self.wlDisplay);
            return error.WaylandFlushFailed;
        }

        if (c.wl_display_read_events(self.wlDisplay) == -1) {
            return error.WaylandReadEventsFailed;
        }

        if (c.wl_display_dispatch_pending(self.wlDisplay) == -1) {
            return error.WaylandDispatchFailed;
        }
    }
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
    if (self.wpFractionalScale) |fs| c.wp_fractional_scale_v1_destroy(fs);
    if (self.wpViewport) |vp| c.wp_viewport_destroy(vp);

    c.xdg_toplevel_destroy(self.xdgToplevel);
    c.xdg_surface_destroy(self.xdgSurface);

    c.wl_cursor_theme_destroy(self.wlCursorTheme);
    c.wl_pointer_destroy(self.wlPointer);
    c.wl_keyboard_destroy(self.wlKeyboard);
    if (self.wpFractionalScaleManager) |fsm| c.wp_fractional_scale_manager_v1_destroy(fsm);
    if (self.wpViewporter) |vp| c.wp_viewporter_destroy(vp);
    c.wl_shm_destroy(self.wlShm);
    c.wl_compositor_destroy(self.wlCompositor);

    c.xdg_wm_base_destroy(self.xdgWmBase);

    c.wl_surface_destroy(self.wlSurface);
    c.wl_registry_destroy(self.wlRegistry);

    c.wl_display_disconnect(self.wlDisplay);

    self.allocator.destroy(self);
}
