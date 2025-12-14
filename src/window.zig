const std = @import("std");
const posix = std.posix;
const os = std.os;
const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const c = @import("c.zig").c;

const Self = @This();

pub const Handlers = struct {
    pointer_enter: ?*const fn (window: *Self, serial: u32, x: c.wl_fixed_t, y: c.wl_fixed_t) void = null,
    pointer_leave: ?*const fn (window: *Self, serial: u32) void = null,
    pointer_motion: ?*const fn (window: *Self, time: u32, x: c.wl_fixed_t, y: c.wl_fixed_t) void = null,
    pointer_button: ?*const fn (window: *Self, serial: u32, time: u32, button: u32, state: u32) void = null,
    pointer_axis: ?*const fn (window: *Self, time: u32, axis: u32, value: c.wl_fixed_t) void = null,
};

// Everything native that is contextual
wl_display: *c.wl_display,
wl_registry: *c.wl_registry,
wl_compositor: *c.wl_compositor,
wl_keyboard: *c.wl_keyboard,
wl_shm: *c.wl_shm,
wl_seat: *c.wl_seat,
xdg_wm_base: *c.xdg_wm_base,

// cursor
wl_pointer: *c.wl_pointer,
wl_cursor_theme: *c.wl_cursor_theme,
cursor_wl_surface: *c.wl_surface,
default_wl_cursor: *c.wl_cursor,
pointer_wl_cursor: *c.wl_cursor,
text_wl_cursor: *c.wl_cursor,

// Everything native related to the window itself
wl_surface: *c.wl_surface,
xdg_surface: *c.xdg_surface,
xdg_toplevel: *c.xdg_toplevel,
egl_window: *c.wl_egl_window,

egl_display: c.EGLDisplay,
egl_config: c.EGLConfig,
egl_context: c.EGLContext,
egl_surface: c.EGLSurface,

// Window state
width: u32,
height: u32,
title: [:0]const u8,
app_id: [:0]const u8,
running: bool,

handlers: Handlers,

allocator: std.mem.Allocator,

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
            const self_name = self.interface.name[0..std.mem.len(self.interface.name)];
            return std.mem.eql(u8, interface_name, self_name);
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
    const shm = BindingInfo(c.wl_shm).new(
        &c.wl_shm_interface,
        1,
    );
    const xdg_wm_base = BindingInfo(c.xdg_wm_base).new(
        &c.xdg_wm_base_interface,
        1,
    );
    const seat = BindingInfo(c.wl_seat).new(
        &c.wl_seat_interface,
        1,
    );

    const interface_name: []const u8 = interface_ptr[0..std.mem.len(interface_ptr)];

    if (compositor.is(interface_name)) {
        window.wl_compositor = compositor.bind(registry, name);
    } else if (shm.is(interface_name)) {
        window.wl_shm = shm.bind(registry, name);
    } else if (xdg_wm_base.is(interface_name)) {
        window.xdg_wm_base = xdg_wm_base.bind(registry, name);
        _ = c.xdg_wm_base_add_listener(
            window.xdg_wm_base,
            &xdg_wm_base_listener,
            data,
        );
    } else if (seat.is(interface_name)) {
        window.wl_seat = seat.bind(registry, name);

        window.wl_pointer = c.wl_seat_get_pointer(window.wl_seat) orelse @panic("could not get wl_pointer from wl_seat");
        _ = c.wl_pointer_add_listener(window.wl_pointer, &wl_pointer_listener, data);

        window.wl_keyboard = c.wl_seat_get_keyboard(window.wl_seat) orelse @panic("could not get wl_keyboard from wl_seat");
        _ = c.wl_keyboard_add_listener(window.wl_keyboard, &wl_keyboard_listener, data);
    }
}

fn global_remove(
    _: ?*anyopaque,
    _: ?*c.wl_registry,
    _: u32,
) callconv(.c) void {}

fn xdg_wm_base_ping(_: ?*anyopaque, xdg_wm_base: ?*c.xdg_wm_base, serial: u32) callconv(.c) void {
    c.xdg_wm_base_pong(xdg_wm_base, serial);
}

const xdg_wm_base_listener: c.xdg_wm_base_listener = .{
    .ping = xdg_wm_base_ping,
};

fn xdg_surface_configure(data: ?*anyopaque, xdg_surface: ?*c.xdg_surface, serial: u32) callconv(.c) void {
    std.log.debug("xdg surface configuration", .{});
    const window: *Self = @ptrCast(@alignCast(data));
    _ = window;
    c.xdg_surface_ack_configure(
        xdg_surface,
        serial,
    );
}

const xdg_surface_listener: c.xdg_surface_listener = .{
    .configure = xdg_surface_configure,
};

fn xdg_toplevel_configure(
    data: ?*anyopaque,
    xdg_toplevel: ?*c.xdg_toplevel,
    width: i32,
    height: i32,
    states: [*c]c.wl_array,
) callconv(.c) void {
    const window: *Self = @ptrCast(@alignCast(data));
    _ = xdg_toplevel;
    _ = states;

    if (width > 0 and height > 0) {
        window.width = @intCast(width);
        window.height = @intCast(height);
        c.wl_egl_window_resize(
            window.egl_window,
            width,
            height,
            0,
            0,
        );
    }
}

fn xdg_toplevel_close(data: ?*anyopaque, xdg_toplevel: ?*c.xdg_toplevel) callconv(.c) void {
    _ = xdg_toplevel;
    const window: *Self = @ptrCast(@alignCast(data));
    window.running = false;
}

const xdg_toplevel_listener: c.xdg_toplevel_listener = .{
    .configure = xdg_toplevel_configure,
    .close = xdg_toplevel_close,
};

fn pointer_handle_enter(
    data: ?*anyopaque,
    wl_pointer: ?*c.wl_pointer,
    serial: u32,
    surface: ?*c.wl_surface,
    surface_x: c.wl_fixed_t,
    surface_y: c.wl_fixed_t,
) callconv(.c) void {
    _ = wl_pointer;
    _ = surface;
    const window: *Self = @ptrCast(@alignCast(data));
    window.set_cursor(.default, serial) catch |err| {
        std.log.err("failed to set cursor: {}", .{err});
    };
    if (window.handlers.pointer_enter) |handler| {
        handler(window, serial, surface_x, surface_y);
    }
}

fn pointer_handle_leave(
    data: ?*anyopaque,
    wl_pointer: ?*c.wl_pointer,
    serial: u32,
    surface: ?*c.wl_surface,
) callconv(.c) void {
    const window: *Self = @ptrCast(@alignCast(data));
    if (window.handlers.pointer_leave) |handler| {
        handler(window, serial);
    }
    _ = wl_pointer;
    _ = surface;
}

fn pointer_handle_motion(
    data: ?*anyopaque,
    wl_pointer: ?*c.wl_pointer,
    time: u32,
    surface_x: c.wl_fixed_t,
    surface_y: c.wl_fixed_t,
) callconv(.c) void {
    const window: *Self = @ptrCast(@alignCast(data));
    if (window.handlers.pointer_motion) |handler| {
        handler(window, time, surface_x, surface_y);
    }
    _ = wl_pointer;
}

fn pointer_handle_button(
    data: ?*anyopaque,
    wl_pointer: ?*c.wl_pointer,
    serial: u32,
    time: u32,
    button: u32,
    state: u32,
) callconv(.c) void {
    const window: *Self = @ptrCast(@alignCast(data));
    if (window.handlers.pointer_button) |handler| {
        handler(window, serial, time, button, state);
    }
    _ = wl_pointer;
}

fn pointer_handle_axis(
    data: ?*anyopaque,
    wl_pointer: ?*c.wl_pointer,
    time: u32,
    axis: u32,
    value: c.wl_fixed_t,
) callconv(.c) void {
    const window: *Self = @ptrCast(@alignCast(data));
    if (window.handlers.pointer_axis) |handler| {
        handler(window, time, axis, value);
    }
    _ = wl_pointer;
}

const wl_pointer_listener: c.wl_pointer_listener = .{
    .enter = pointer_handle_enter,
    .leave = pointer_handle_leave,
    .motion = pointer_handle_motion,
    .button = pointer_handle_button,
    .axis = pointer_handle_axis,
};

fn keyboard_handle_keymap(
    data: ?*anyopaque,
    wl_keyboard: ?*c.wl_keyboard,
    format: u32,
    fd: i32,
    size: u32,
) callconv(.c) void {
    std.debug.assert(format == c.WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1);
    _ = fd;
    _ = size;
    // std.posix.mmap(
    //     null,
    //     size,
    //     undefined,
    //     undefined,
    //     fd,
    //     0,
    // ) catch @panic("failed to read the given keymap");

    _ = wl_keyboard;
    const window: *Self = @ptrCast(@alignCast(data));
    _ = window;
    // if (window.handlers.keyboard_keymap) |handler| {
    //     handler(window, format, fd, size);
    // }
}

fn keyboard_handle_enter(
    data: ?*anyopaque,
    wl_keyboard: ?*c.wl_keyboard,
    serial: u32,
    surface: ?*c.wl_surface,
    keys: [*c]c.wl_array,
) callconv(.c) void {
    _ = wl_keyboard;
    _ = surface;
    const window: *Self = @ptrCast(@alignCast(data));
    _ = window;
    _ = serial;
    _ = keys;
    // if (window.handlers.keyboard_enter) |handler| {
    //     handler(window, serial, keys);
    // }
}

fn keyboard_handle_leave(
    data: ?*anyopaque,
    wl_keyboard: ?*c.wl_keyboard,
    serial: u32,
    surface: ?*c.wl_surface,
) callconv(.c) void {
    _ = wl_keyboard;
    _ = surface;
    const window: *Self = @ptrCast(@alignCast(data));
    _ = window;
    _ = serial;
    // if (window.handlers.keyboard_leave) |handler| {
    //     handler(window, serial);
    // }
}

fn keyboard_handle_key(
    data: ?*anyopaque,
    wl_keyboard: ?*c.wl_keyboard,
    serial: u32,
    time: u32,
    key: u32,
    state: u32,
) callconv(.c) void {
    _ = wl_keyboard;
    const window: *Self = @ptrCast(@alignCast(data));
    _ = window;
    _ = serial;
    _ = time;
    _ = key;
    _ = state;
    // if (window.handlers.keyboard_key) |handler| {
    //     handler(window, serial, time, key, state);
    // }
}

fn keyboard_handle_modifiers(
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
    _ = window;
    _ = serial;
    _ = mods_depressed;
    _ = mods_latched;
    _ = mods_locked;
    _ = group;
    // window.modifiers = .{
    //     .mods_depressed = mods_depressed,
    //     .mods_latched = mods_latched,
    //     .mods_locked = mods_locked,
    //     .group = group,
    // };
    // if (window.handlers.keyboard_modifiers) |handler| {
    //     handler(window, serial, mods_depressed, mods_latched, mods_locked, group);
    // }
}

fn keyboard_handle_repeat_info(
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
    //     handler(window, rate, delay);
    // }
}

const wl_keyboard_listener: c.wl_keyboard_listener = .{
    .keymap = keyboard_handle_keymap,
    .enter = keyboard_handle_enter,
    .leave = keyboard_handle_leave,
    .key = keyboard_handle_key,
    .modifiers = keyboard_handle_modifiers,
    .repeat_info = keyboard_handle_repeat_info,
};

fn setup_egl(self: *Self) !void {
    const config_attribs = [_]c.EGLint{
        c.EGL_SURFACE_TYPE,
        c.EGL_WINDOW_BIT,
        c.EGL_RENDERABLE_TYPE,
        c.EGL_OPENGL_BIT,
        c.EGL_RED_SIZE,
        8,
        c.EGL_GREEN_SIZE,
        8,
        c.EGL_BLUE_SIZE,
        8,
        c.EGL_ALPHA_SIZE,
        8,
        c.EGL_DEPTH_SIZE,
        24,
        c.EGL_STENCIL_SIZE,
        8,
        c.EGL_NONE,
    };

    const context_attribs = [_]c.EGLint{
        c.EGL_CONTEXT_MAJOR_VERSION,
        4,
        c.EGL_CONTEXT_MINOR_VERSION,
        6,
        c.EGL_CONTEXT_OPENGL_PROFILE_MASK,
        c.EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT,
        c.EGL_NONE,
    };
    self.egl_display = c.eglGetDisplay(self.wl_display);
    if (self.egl_display == c.EGL_NO_DISPLAY) {
        return error.FailedToGetEGLDisplay;
    }
    errdefer _ = c.eglTerminate(self.egl_display);

    var major: i32 = undefined;
    var minor: i32 = undefined;
    if (c.eglInitialize(self.egl_display, &major, &minor) == 0) {
        return error.FailedToInitializeEGL;
    }

    std.log.debug("EGL version {d}.{d}", .{ major, minor });

    if (c.eglBindAPI(c.EGL_OPENGL_API) == 0) {
        return error.FailedToBindOpenGLAPI;
    }

    var count: i32 = undefined;
    if (c.eglChooseConfig(
        self.egl_display,
        &config_attribs[0],
        &self.egl_config,
        1,
        &count,
    ) == 0) {
        return error.FailedToChooseEGLConfig;
    }

    self.egl_context = c.eglCreateContext(
        self.egl_display,
        self.egl_config,
        c.EGL_NO_CONTEXT,
        &context_attribs[0],
    );
    errdefer _ = c.eglDestroyContext(self.egl_display, self.egl_context);
    if (self.egl_context == c.EGL_NO_CONTEXT) {
        return error.FailedToCreateEGLContext;
    }
}

fn create_egl_surface(self: *Self) !void {
    self.egl_window = c.wl_egl_window_create(
        self.wl_surface,
        @intCast(self.width),
        @intCast(self.height),
    ) orelse return error.FailedToCreateEGLWindow;
    errdefer c.wl_egl_window_destroy(self.egl_window);

    self.egl_surface = c.eglCreateWindowSurface(
        self.egl_display,
        self.egl_config,
        self.egl_window,
        null,
    );
    errdefer _ = c.eglDestroySurface(self.egl_display, self.egl_surface);
    if (self.egl_surface == c.EGL_NO_SURFACE) {
        return error.FailedToCreateEGLSurface;
    }

    if (c.eglMakeCurrent(
        self.egl_display,
        self.egl_surface,
        self.egl_surface,
        self.egl_context,
    ) == 0) {
        return error.FailedToMakeEGLContextCurrent;
    }
}

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

    window.width = width;
    window.height = height;
    window.title = title;
    window.app_id = app_id;
    window.running = true;

    window.handlers = .{};

    window.wl_display = c.wl_display_connect(
        null,
    ) orelse return error.UnableToConnectToWaylandDisplay;
    errdefer c.wl_display_disconnect(window.wl_display);

    window.wl_registry = c.wl_display_get_registry(window.wl_display) orelse return error.UnableToGetRegistry;
    errdefer c.wl_registry_destroy(window.wl_registry);
    _ = c.wl_registry_add_listener(
        window.wl_registry,
        &.{ .global = global, .global_remove = global_remove },
        @ptrCast(@alignCast(window)),
    );
    _ = c.wl_display_roundtrip(window.wl_display);

    window.wl_surface = c.wl_compositor_create_surface(window.wl_compositor) orelse return error.UnableToCreateSurface;
    errdefer c.wl_surface_destroy(window.wl_surface);

    window.xdg_surface = c.xdg_wm_base_get_xdg_surface(
        window.xdg_wm_base,
        window.wl_surface,
    ) orelse return error.UnableToCreateXdgSurface;
    errdefer c.xdg_surface_destroy(window.xdg_surface);
    _ = c.xdg_surface_add_listener(
        window.xdg_surface,
        &xdg_surface_listener,
        @ptrCast(@alignCast(window)),
    );

    window.xdg_toplevel = c.xdg_surface_get_toplevel(
        window.xdg_surface,
    ) orelse return error.UnableToGetTopLevelXdg;
    errdefer c.xdg_toplevel_destroy(window.xdg_toplevel);
    _ = c.xdg_toplevel_add_listener(
        window.xdg_toplevel,
        &xdg_toplevel_listener,
        @ptrCast(@alignCast(window)),
    );
    c.xdg_toplevel_set_title(window.xdg_toplevel, title.ptr);
    c.xdg_toplevel_set_app_id(window.xdg_toplevel, app_id.ptr);
    c.wl_surface_commit(window.wl_surface);

    try window.setup_egl();
    errdefer {
        _ = c.eglDestroyContext(window.egl_display, window.egl_context);
        _ = c.eglTerminate(window.egl_display);
    }
    try window.create_egl_surface();
    errdefer {
        _ = c.eglDestroySurface(window.egl_display, window.egl_surface);
        c.wl_egl_window_destroy(window.egl_window);
    }

    try zopengl.loadCoreProfile(
        @ptrCast(&c.eglGetProcAddress),
        4,
        6,
    );
    gl.pixelStorei(gl.UNPACK_ALIGNMENT, 1);
    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    try window.setup_cursor();

    return window;
}

pub fn get_frame_buffer_size(self: *Self) !struct { width: u32, height: u32 } {
    var w: u32 = undefined;
    var h: u32 = undefined;
    if (c.eglQuerySurface(
        self.egl_display,
        self.egl_surface,
        c.EGL_WIDTH,
        &w,
    ) == 0)
        return error.EglQueryFailed;
    if (c.eglQuerySurface(
        self.egl_display,
        self.egl_surface,
        c.EGL_HEIGHT,
        &h,
    ) == 0)
        return error.EglQueryFailed;
    return .{ .width = w, .height = h };
}

fn setup_cursor(self: *Self) !void {
    self.wl_cursor_theme = c.wl_cursor_theme_load(null, 24, self.wl_shm) orelse return error.FailedGettingCursorTheme;
    self.default_wl_cursor = c.wl_cursor_theme_get_cursor(self.wl_cursor_theme, "default");
    self.pointer_wl_cursor = c.wl_cursor_theme_get_cursor(self.wl_cursor_theme, "pointer");
    self.text_wl_cursor = c.wl_cursor_theme_get_cursor(self.wl_cursor_theme, "text");

    self.cursor_wl_surface = c.wl_compositor_create_surface(self.wl_compositor) orelse return error.FailedCreatingCursorSurface;
}

const Cursor = enum {
    default,
    text,
    pointer,
};

pub fn set_cursor(self: *Self, cursor: Cursor, serial: u32) !void {
    const wl_cursor_image = switch (cursor) {
        .default => self.default_wl_cursor.images[0],
        .pointer => self.pointer_wl_cursor.images[0],
        .text => self.text_wl_cursor.images[0],
    };
    const wl_buffer = c.wl_cursor_image_get_buffer(wl_cursor_image) orelse return error.FailedGettingCursorBuffer;
    c.wl_surface_attach(self.cursor_wl_surface, wl_buffer, 0, 0);
    c.wl_surface_damage(self.cursor_wl_surface, 0, 0, @intCast(wl_cursor_image.*.width), @intCast(wl_cursor_image.*.height));
    c.wl_surface_commit(self.cursor_wl_surface);
    c.wl_pointer_set_cursor(
        self.wl_pointer,
        serial,
        self.cursor_wl_surface,
        @intCast(wl_cursor_image.*.hotspot_x),
        @intCast(wl_cursor_image.*.hotspot_y),
    );
}

pub fn handle_events(self: *Self) !void {
    while (c.wl_display_prepare_read(self.wl_display) != 0) {
        if (c.wl_display_dispatch_pending(self.wl_display) == -1) {
            return error.WaylandDispatchFailed;
        }
    }

    if (c.wl_display_flush(self.wl_display) == -1) {
        c.wl_display_cancel_read(self.wl_display);
        return error.WaylandFlushFailed;
    }

    if (c.wl_display_read_events(self.wl_display) == -1) {
        return error.WaylandReadEventsFailed;
    }

    if (c.wl_display_dispatch_pending(self.wl_display) == -1) {
        return error.WaylandDispatchFailed;
    }
}

pub fn swap_buffers(self: *Self) !void {
    if (c.eglSwapBuffers(
        self.egl_display,
        self.egl_surface,
    ) == c.EGL_FALSE) {
        return error.FailedToSwapBuffers;
    }
}

pub fn deinit(self: *Self) void {
    _ = c.eglDestroyContext(self.egl_display, self.egl_context);
    _ = c.eglTerminate(self.egl_display);
    _ = c.eglDestroySurface(self.egl_display, self.egl_surface);

    c.wl_egl_window_destroy(self.egl_window);
    c.xdg_toplevel_destroy(self.xdg_toplevel);
    c.xdg_surface_destroy(self.xdg_surface);

    c.wl_cursor_theme_destroy(self.wl_cursor_theme);
    c.wl_pointer_destroy(self.wl_pointer);
    c.wl_keyboard_destroy(self.wl_keyboard);
    c.wl_shm_destroy(self.wl_shm);
    c.wl_compositor_destroy(self.wl_compositor);

    c.xdg_wm_base_destroy(self.xdg_wm_base);

    c.wl_surface_destroy(self.wl_surface);
    c.wl_registry_destroy(self.wl_registry);

    c.wl_display_disconnect(self.wl_display);

    self.allocator.destroy(self);
}
