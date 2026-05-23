const std = @import("std");

const c = @import("c");
const window_root = @import("root.zig");
const Cursor = window_root.Cursor;
pub const Keys = window_root.Keys;
pub const KeyboardSnapshot = window_root.KeyboardSnapshot;

extern fn objc_autoreleasePoolPush() ?*anyopaque;
extern fn objc_autoreleasePoolPop(pool: ?*anyopaque) void;

const Self = @This();

const linux_left_mouse_button: u32 = 272; // BTN_LEFT, to match the shared pointerButton convention
const button_pressed: u32 = 1;
const button_released: u32 = 0;

pub const ScrollAxis = enum(u32) {
    vertical = 0,
    horizontal = 1,
};

// Global variable to hold the current window instance for delegate callbacks
var g_current_window: ?*Self = null;

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
    const fn_ptr = msgSend(*const fn (c.Class, c.SEL, [*:0]const u8) callconv(.c) c.id);
    return fn_ptr(NSString, sel("stringWithUTF8String:"), cstr);
}

fn applicationShouldTerminateAfterLastWindowClosed(self: c.id, _cmd: c.SEL, application: c.id) callconv(.c) BOOL {
    _ = self;
    _ = _cmd;
    _ = application;
    return 1; // YES
}

fn windowDidResize(self_obj: c.id, _cmd: c.SEL, notification: c.id) callconv(.c) void {
    _ = self_obj;
    _ = _cmd;
    _ = notification;

    // Get the window instance from the global variable
    if (g_current_window) |window| {
        // Get current window size
        const frame = msgSend(*const fn (c.id, c.SEL) callconv(.c) NSRect);
        const window_frame = frame(window.window, sel("frame"));

        const new_width: u32 = @intFromFloat(window_frame.size.width);
        const new_height: u32 = @intFromFloat(window_frame.size.height);

        // Update window dimensions
        window.width = new_width;
        window.height = new_height;

        // Update DPI and scale (window may have moved to a different screen)
        window.updateDpiAndScale();

        // Call the resize handler if it exists
        if (window.handlers.resize) |handler| {
            handler.function(window, new_width, new_height, window.dpi, handler.data);
        }
    }
}

fn windowDidChangeScreen(self_obj: c.id, _cmd: c.SEL, notification: c.id) callconv(.c) void {
    _ = self_obj;
    _ = _cmd;
    _ = notification;

    // When window moves to a different screen, update DPI and scale
    if (g_current_window) |window| {
        window.updateDpiAndScale();

        // Notify via resize handler since DPI/scale may have changed
        if (window.handlers.resize) |handler| {
            handler.function(window, window.width, window.height, window.dpi, handler.data);
        }
    }
}

fn windowDidChangeBackingProperties(self_obj: c.id, _cmd: c.SEL, notification: c.id) callconv(.c) void {
    _ = self_obj;
    _ = _cmd;
    _ = notification;

    // Called when backing scale factor changes (e.g., moving between Retina and non-Retina displays)
    if (g_current_window) |window| {
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

    const new_id = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
    const add_item = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);
    const set_main_menu = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);
    const set_submenu = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);

    const menubar = new_id(NSMenu, sel("new"));
    const appMenuItem = new_id(NSMenuItem, sel("new"));

    add_item(menubar, sel("addItem:"), appMenuItem);
    set_main_menu(app, sel("setMainMenu:"), menubar);

    const appMenu = new_id(NSMenu, sel("new"));
    set_submenu(appMenuItem, sel("setSubmenu:"), appMenu);

    const quitTitle = nsstring("Quit");
    const keyEquivalent = nsstring("q");

    const alloc_id = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
    const init_quit = msgSend(*const fn (c.id, c.SEL, c.id, c.SEL, c.id) callconv(.c) c.id);
    const set_target = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);

    var quitItem = alloc_id(NSMenuItem, sel("alloc"));
    quitItem = init_quit(
        quitItem,
        sel("initWithTitle:action:keyEquivalent:"),
        quitTitle,
        sel("terminate:"),
        keyEquivalent,
    );

    set_target(quitItem, sel("setTarget:"), app);
    add_item(appMenu, sel("addItem:"), quitItem);
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
keysMutex: window_root.SpinLock = .{},
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

    const new_id = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
    const setDelegate = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);
    const delegate_class = getClass("MinimalAppDelegate");
    const delegate = new_id(delegate_class, sel("new"));
    setDelegate(self.app, sel("setDelegate:"), delegate);

    createMenuBar(self.app);

    const NSWindow = getClass("NSWindow");

    const contentRect = NSMakeRect(0, 0, @floatFromInt(width), @floatFromInt(height));
    const styleMask: NSUInteger = NSWindowStyleMaskTitled |
        NSWindowStyleMaskClosable |
        NSWindowStyleMaskMiniaturizable |
        NSWindowStyleMaskResizable;

    const alloc = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
    var window_obj = alloc(NSWindow, sel("alloc"));

    const initWithContentRect = msgSend(*const fn (c.id, c.SEL, NSRect, NSUInteger, NSUInteger, BOOL) callconv(.c) c.id);
    window_obj = initWithContentRect(
        window_obj,
        sel("initWithContentRect:styleMask:backing:defer:"),
        contentRect,
        styleMask,
        NSBackingStoreBuffered,
        0, // NO
    );
    if (window_obj == null) return error.WindowCreationFailed;

    self.window = window_obj;

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

        const window_delegate = new_id(@ptrCast(WindowDelegate), sel("new"));

        // Set the global window instance for delegate callbacks
        g_current_window = self;

        setDelegate(self.window, sel("setDelegate:"), window_delegate);
    }

    const contentView = msgSend(*const fn (c.id, c.SEL) callconv(.c) c.id);
    self.content_view = contentView(self.window, sel("contentView"));

    self.metal_layer = null;
    if (self.content_view != null) {
        const setWantsLayer = msgSend(*const fn (c.id, c.SEL, BOOL) callconv(.c) void);
        setWantsLayer(self.content_view, sel("setWantsLayer:"), 1);

        // MoltenVK expects a CAMetalLayer for presentation.
        const CAMetalLayer = getClass("CAMetalLayer");
        const new_id_obj = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
        self.metal_layer = new_id_obj(CAMetalLayer, sel("new"));

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
    const device_desc = deviceDescription(screen, sel("deviceDescription"));

    if (device_desc == null) {
        // Fallback to 96 DPI if we can't get device description
        self.dpi = .{ 96, 96 };
        return;
    }

    // Get the NSScreenNumber (CGDirectDisplayID) from the device description
    const NSScreenNumber = nsstring("NSScreenNumber");
    const objectForKey = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) c.id);
    const screen_number_value = objectForKey(device_desc, sel("objectForKey:"), NSScreenNumber);

    if (screen_number_value == null) {
        self.dpi = .{ 96, 96 };
        return;
    }

    const unsignedIntValue = msgSend(*const fn (c.id, c.SEL) callconv(.c) c_uint);
    const display_id = unsignedIntValue(screen_number_value, sel("unsignedIntValue"));

    // Get physical screen size in millimeters using CoreGraphics
    const physical_size_mm = c.CGDisplayScreenSize(display_id);

    // Get pixel dimensions of the display
    const pixel_width = c.CGDisplayPixelsWide(display_id);
    const pixel_height = c.CGDisplayPixelsHigh(display_id);

    if (physical_size_mm.width <= 0 or physical_size_mm.height <= 0) {
        // Fallback if physical dimensions unavailable
        self.dpi = .{ 96, 96 };
        return;
    }

    // Calculate physical DPI (pixels per inch), similar to Linux Wayland implementation
    const millimeters_per_inch: f64 = 25.4;
    const physical_dpi_x = @as(f64, @floatFromInt(pixel_width)) / (physical_size_mm.width / millimeters_per_inch);
    const physical_dpi_y = @as(f64, @floatFromInt(pixel_height)) / (physical_size_mm.height / millimeters_per_inch);

    // Apply backing scale factor (like Linux applies fractional scale)
    self.dpi = .{
        @intFromFloat(@round(physical_dpi_x)),
        @intFromFloat(@round(physical_dpi_y)),
    };

    std.log.debug(
        "macOS screen DPI: {d}x{d}, physical size: {d:.1}x{d:.1}mm, pixels: {d}x{d}",
        .{ self.dpi[0], self.dpi[1], physical_size_mm.width, physical_size_mm.height, pixel_width, pixel_height },
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
    const fallback_60hz: u64 = 16_666_667; // ~60 Hz in nanoseconds

    // Get the screen that the window is currently on
    const getScreen = msgSend(*const fn (c.id, c.SEL) callconv(.c) c.id);
    var screen = getScreen(self.window, sel("screen"));

    if (screen == null) {
        // Fallback to main screen if window's screen is not available
        const NSScreen = getClass("NSScreen");
        const mainScreen = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
        screen = mainScreen(NSScreen, sel("mainScreen"));
        if (screen == null) return fallback_60hz;
    }

    // Get the display ID for this screen
    const deviceDescription = msgSend(*const fn (c.id, c.SEL) callconv(.c) c.id);
    const device_desc = deviceDescription(screen, sel("deviceDescription"));
    if (device_desc == null) return fallback_60hz;

    // Get the NSScreenNumber (CGDirectDisplayID) from the device description
    const NSScreenNumber = nsstring("NSScreenNumber");
    const objectForKey = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) c.id);
    const screen_number_value = objectForKey(device_desc, sel("objectForKey:"), NSScreenNumber);
    if (screen_number_value == null) return fallback_60hz;

    // Get the unsigned int value (CGDirectDisplayID)
    const unsignedIntValue = msgSend(*const fn (c.id, c.SEL) callconv(.c) c_uint);
    const display_id = unsignedIntValue(screen_number_value, sel("unsignedIntValue"));

    // Use Core Graphics to get the display mode and refresh rate
    const display_mode = c.CGDisplayCopyDisplayMode(display_id);
    if (display_mode == null) return fallback_60hz;
    defer c.CGDisplayModeRelease(display_mode);

    const refresh_rate = c.CGDisplayModeGetRefreshRate(display_mode);

    // Some displays (especially built-in Retina displays) report 0 refresh rate
    // In that case, fall back to 60Hz
    if (refresh_rate <= 0) return fallback_60hz;

    // Convert refresh rate (Hz) to frame time (nanoseconds)
    return @intFromFloat(@round(1_000_000_000.0 / refresh_rate));
}

fn processEvent(self: *Self, event: c.id) void {
    // Get event type
    const getType = msgSend(*const fn (c.id, c.SEL) callconv(.c) NSUInteger);
    const event_type = getType(event, sel("type"));

    // Handle mouse motion events
    if (event_type == NSEventTypeMouseMoved or
        event_type == NSEventTypeLeftMouseDragged or
        event_type == NSEventTypeRightMouseDragged or
        event_type == NSEventTypeOtherMouseDragged)
    {
        if (self.handlers.pointerMotion) |handler| {
            // Get the mouse location in window coordinates (relative to content view, origin at bottom-left)
            const locationInWindow = msgSend(*const fn (c.id, c.SEL) callconv(.c) NSPoint);
            const location = locationInWindow(event, sel("locationInWindow"));

            // Get the content view's bounds to get the correct height for coordinate conversion
            const getBounds = msgSend(*const fn (c.id, c.SEL) callconv(.c) NSRect);
            const content_bounds = getBounds(self.content_view, sel("bounds"));

            // macOS has origin at bottom-left, convert to top-left origin using content view height
            const x: f32 = @floatCast(location.x);
            const y: f32 = @as(f32, @floatCast(content_bounds.size.height)) - @as(f32, @floatCast(location.y));

            handler.function(self, x, y, handler.data);
        }
    }

    if (event_type == NSEventTypeLeftMouseDown or event_type == NSEventTypeLeftMouseUp) {
        if (self.handlers.pointerButton) |handler| {
            const state = if (event_type == NSEventTypeLeftMouseDown)
                button_pressed
            else
                button_released;
            handler.function(self, 0, 0, linux_left_mouse_button, state, handler.data);
        }
    }

    if (event_type == NSEventTypeFlagsChanged) {
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

    if (event_type == NSEventTypeKeyDown or event_type == NSEventTypeKeyUp) {
        const keyCodeFn = msgSend(*const fn (c.id, c.SEL) callconv(.c) u16);
        const isARepeatFn = msgSend(*const fn (c.id, c.SEL) callconv(.c) BOOL);

        const code = keyCodeFn(event, sel("keyCode"));
        const key = macosKeycodeToKeys(code);
        const is_repeat = isARepeatFn(event, sel("isARepeat")) != 0;

        self.keysMutex.lock();
        if (event_type == NSEventTypeKeyDown) {
            // Only fresh press transitions flip the edge bit; OS-driven
            // repeats just keep the held bit set (already set).
            if (!is_repeat) {
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
    if (event_type == NSEventTypeScrollWheel) {
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

    const mask_any: NSUInteger = std.math.maxInt(NSUInteger);
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
        const blocking_date = distantFuture(NSDate, sel("distantFuture"));
        const event = nextEvent(
            self.app,
            sel("nextEventMatchingMask:untilDate:inMode:dequeue:"),
            mask_any,
            blocking_date,
            mode,
            1, // YES
        );

        if (event != null) {
            // Process event for our handlers first
            self.processEvent(event);

            // Then let the system handle it
            sendEvent(self.app, sel("sendEvent:"), event);

            // Process any additional pending events without blocking
            const non_blocking_date = distantPast(NSDate, sel("distantPast"));
            while (true) {
                const pending_event = nextEvent(
                    self.app,
                    sel("nextEventMatchingMask:untilDate:inMode:dequeue:"),
                    mask_any,
                    non_blocking_date,
                    mode,
                    1,
                );
                if (pending_event == null) break;
                self.processEvent(pending_event);
                sendEvent(self.app, sel("sendEvent:"), pending_event);
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
    if (g_current_window == self) {
        g_current_window = null;
    }

    if (self.window != null) {
        const close = msgSend(*const fn (c.id, c.SEL) callconv(.c) void);
        close(self.window, sel("close"));
    }

    objc_autoreleasePoolPop(self.pool);
    self.allocator.destroy(self);
}
