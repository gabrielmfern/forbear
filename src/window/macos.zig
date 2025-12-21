const std = @import("std");

const c = @import("../c.zig").c;

extern fn objc_autoreleasePoolPush() ?*anyopaque;
extern fn objc_autoreleasePoolPop(pool: ?*anyopaque) void;

const Self = @This();

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
    return true; // YES
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
title: [:0]const u8,
app_id: [:0]const u8,
running: bool,

allocator: std.mem.Allocator,

pub fn init(
    width: u32,
    height: u32,
    title: [:0]const u8,
    app_id: [:0]const u8,
    allocator: std.mem.Allocator,
) !*Self {
    const self = try allocator.create(Self);
    errdefer allocator.destroy(self);

    self.allocator = allocator;
    self.width = width;
    self.height = height;
    self.title = title;
    self.app_id = app_id;
    self.running = true;

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
        false, // NO
    );
    if (window_obj == null) return error.WindowCreationFailed;

    self.window = window_obj;

    const setTitle = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);
    setTitle(self.window, sel("setTitle:"), nsstring(title.ptr));

    const center = msgSend(*const fn (c.id, c.SEL) callconv(.c) void);
    center(self.window, sel("center"));

    const contentView = msgSend(*const fn (c.id, c.SEL) callconv(.c) c.id);
    self.content_view = contentView(self.window, sel("contentView"));

    self.metal_layer = null;
    if (self.content_view != null) {
        const setWantsLayer = msgSend(*const fn (c.id, c.SEL, BOOL) callconv(.c) void);
        setWantsLayer(self.content_view, sel("setWantsLayer:"), true);

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
    activateIgnoringOtherApps(self.app, sel("activateIgnoringOtherApps:"), true);

    const finishLaunching = msgSend(*const fn (c.id, c.SEL) callconv(.c) void);
    finishLaunching(self.app, sel("finishLaunching"));

    return self;
}

pub fn nativeView(self: *Self) ?*anyopaque {
    if (self.content_view == null) return null;
    return @ptrCast(self.content_view);
}

pub fn nativeMetalLayer(self: *Self) ?*anyopaque {
    if (self.metal_layer == null) return null;
    return @ptrCast(self.metal_layer);
}

const Cursor = enum {
    default,
    text,
    pointer,
};

pub fn setCursor(self: *Self, cursor: Cursor, serial: u32) !void {
    _ = self;
    _ = cursor;
    _ = serial;
    // TODO: map to NSCursor.
}

pub fn handleEvents(self: *Self) !void {
    // Non-blocking event pump; lets callers keep a per-frame loop.
    const NSDate = getClass("NSDate");
    const distantPast = msgSend(*const fn (c.Class, c.SEL) callconv(.c) c.id);
    const untilDate = distantPast(NSDate, sel("distantPast"));

    const mask_any: NSUInteger = std.math.maxInt(NSUInteger);
    const mode = nsstring("kCFRunLoopDefaultMode");

    const nextEvent = msgSend(*const fn (c.id, c.SEL, NSUInteger, c.id, c.id, BOOL) callconv(.c) c.id);
    const sendEvent = msgSend(*const fn (c.id, c.SEL, c.id) callconv(.c) void);

    while (true) {
        const event = nextEvent(
            self.app,
            sel("nextEventMatchingMask:untilDate:inMode:dequeue:"),
            mask_any,
            untilDate,
            mode,
            true,
        );
        if (event == null) break;
        sendEvent(self.app, sel("sendEvent:"), event);
    }

    const updateWindows = msgSend(*const fn (c.id, c.SEL) callconv(.c) void);
    updateWindows(self.app, sel("updateWindows"));

    // Treat a closed window as "stop running".
    const isVisible = msgSend(*const fn (c.id, c.SEL) callconv(.c) BOOL);
    if (isVisible(self.window, sel("isVisible")) == false) {
        self.running = false;
    }
}

pub fn deinit(self: *Self) void {
    if (self.window != null) {
        const close = msgSend(*const fn (c.id, c.SEL) callconv(.c) void);
        close(self.window, sel("close"));
    }

    objc_autoreleasePoolPop(self.pool);
    self.allocator.destroy(self);
}
