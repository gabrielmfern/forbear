const std = @import("std");
const win32 = @import("../windows/win32.zig");
const window_root = @import("root.zig");
const Cursor = window_root.Cursor;
pub const Keys = window_root.Keys;
pub const KeyboardSnapshot = window_root.KeyboardSnapshot;

const linux_left_mouse_button: u32 = 272; // BTN_LEFT, to match the shared pointerButton convention
const button_pressed: u32 = 1;
const button_released: u32 = 0;

handle: win32.HWND,
hInstance: win32.HINSTANCE,

width: u32,
height: u32,
title: [:0]const u16,
className: [:0]const u16,
running: bool,
dpi: [2]u32,

/// Keyboard state. The wndProc thread writes; Forbear's render thread drains
/// via `snapshotKeyboard()`. Held bitset + edge bitsets, all `Key`-typed.
keysMutex: window_root.SpinLock = .{},
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

fn virtualKeyToKeys(vk: win32.WPARAM) Keys {
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
        0x5B => .{ .superLeft = true },
        0x5C => .{ .superRight = true },
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
        0xA0 => .{ .shiftLeft = true },
        0xA1 => .{ .shiftRight = true },
        0xA2 => .{ .controlLeft = true },
        0xA3 => .{ .controlRight = true },
        0xA4 => .{ .altLeft = true },
        0xA5 => .{ .altRight = true },
        // Generic VK_SHIFT/CONTROL/MENU come through without left/right
        // distinction — bias to the left variant.
        0x10 => .{ .shiftLeft = true },
        0x11 => .{ .controlLeft = true },
        0x12 => .{ .altLeft = true },
        else => .{},
    };
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

    window.hInstance = win32.GetModuleHandleW(null);
    if (window.hInstance == null) {
        return error.CouldNotFindHInstance;
    }

    const windowClass = win32.WNDCLASSEXW{
        .hInstance = window.hInstance,
        .style = win32.CS_HREDRAW | win32.CS_VREDRAW | win32.CS_OWNDC,
        .lpfnWndProc = wndProc,
        .hCursor = win32.LoadCursorW(null, win32.IDC_ARROW),
        .lpszClassName = window.className.ptr,
    };

    if (win32.RegisterClassExW(&windowClass) == 0) {
        return error.FailedToRegisterWindowClass;
    }

    _ = win32.SetProcessDpiAwarenessContext(win32.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    _ = win32.SetThreadDpiAwarenessContext(win32.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

    var rect = win32.RECT{ .left = 0, .top = 0, .right = @intCast(width), .bottom = @intCast(height) };
    const style = win32.WS_OVERLAPPEDWINDOW | win32.WS_VISIBLE;
    _ = win32.AdjustWindowRectEx(&rect, style, 0, 0);

    window.handle = win32.CreateWindowExW(
        0,
        window.className.ptr,
        window.title.ptr,
        style,
        win32.CW_USEDEFAULT,
        win32.CW_USEDEFAULT,
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
    const dpi = win32.GetDpiForWindow(self.handle);
    self.dpi = .{ dpi, dpi };
}

fn updateClientSize(self: *@This()) void {
    var rect: win32.RECT = undefined;
    if (win32.GetClientRect(self.handle, &rect) == 0) {
        std.log.err("failed to query window client size", .{});
        return;
    }
    self.width = @intCast(rect.right - rect.left);
    self.height = @intCast(rect.bottom - rect.top);
}

fn emitResizeIfNeeded(self: *@This(), hwnd: win32.HWND, force: bool) void {
    var rect: win32.RECT = undefined;
    if (win32.GetClientRect(hwnd, &rect) == 0) {
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
    _ = win32.DestroyWindow(self.handle);
    _ = win32.UnregisterClassW(self.className.ptr, self.hInstance);
    self.allocator.free(self.className);
    self.allocator.free(self.title);
    self.allocator.destroy(self);
}

fn wndProc(hwnd: win32.HWND, message: win32.UINT, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(.c) win32.LRESULT {
    // Handle WM_NCCREATE to store the window pointer
    if (message == win32.WM_NCCREATE) {
        const createStruct: *win32.CREATESTRUCTW = @ptrFromInt(@as(usize, @bitCast(lParam)));
        const window: *@This() = @ptrCast(@alignCast(createStruct.lpCreateParams));
        _ = win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, @bitCast(@intFromPtr(window)));
        return win32.DefWindowProcW(hwnd, message, wParam, lParam);
    }

    // Retrieve the window pointer for all other messages
    const window: ?*@This() = blk: {
        const ptr = win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA);
        break :blk if (ptr == 0) null else @ptrFromInt(@as(usize, @bitCast(ptr)));
    };

    switch (message) {
        win32.WM_WINDOWPOSCHANGED => {
            if (window) |self| {
                const windowpos: *win32.WINDOWPOS = @ptrFromInt(@as(usize, @intCast(lParam)));
                if ((windowpos.flags & win32.SWP_NOSIZE) == 0) {
                    self.emitResizeIfNeeded(hwnd, false);
                }
            }
        },
        win32.WM_MOUSEMOVE => {
            if (window) |self| {
                const mouseX: u16 = @truncate(@as(u32, @intCast(lParam)));
                const mouseY: u16 = @truncate(@as(u32, @intCast(lParam)) >> 16);
                if (self.handlers.pointerMotion) |handler| {
                    handler.function(self, @floatFromInt(mouseX), @floatFromInt(mouseY), handler.data);
                }
            }
        },
        win32.WM_LBUTTONDOWN => {
            if (window) |self| {
                if (self.handlers.pointerButton) |handler| {
                    handler.function(self, 0, 0, linux_left_mouse_button, button_pressed, handler.data);
                }
            }
        },
        win32.WM_LBUTTONUP => {
            if (window) |self| {
                if (self.handlers.pointerButton) |handler| {
                    handler.function(self, 0, 0, linux_left_mouse_button, button_released, handler.data);
                }
            }
        },
        win32.WM_MOUSEWHEEL => {
            if (window) |self| {
                // this value is positive when going up and negative going down
                // see https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-mousewheel
                const offset: i16 = @bitCast(@as(u16, @truncate(wParam >> 16)));
                if (self.handlers.scroll) |handler| {
                    handler.function(self, .vertical, @floatFromInt(-1 * offset), handler.data);
                }
            }
        },
        win32.WM_KEYDOWN => {
            if (window) |self| {
                // lParam bit 30 is "previous key state": 1 = OS repeat,
                // 0 = fresh press. Only fresh presses flip the edge bit.
                // Coalesce count (bits 0..15) and scan code (bits 16..23)
                // are intentionally ignored.
                const lp: u32 = @truncate(@as(u64, @bitCast(lParam)));
                const was_already_down: bool = (lp & (1 << 30)) != 0;
                const key = virtualKeyToKeys(wParam);

                self.keysMutex.lock();
                if (!was_already_down) {
                    self.pendingPressed = self.pendingPressed.with(key);
                    self.keysDown = self.keysDown.with(key);
                }
                self.keysMutex.unlock();
            }
        },
        win32.WM_KEYUP => {
            if (window) |self| {
                const key = virtualKeyToKeys(wParam);
                self.keysMutex.lock();
                self.pendingReleased = self.pendingReleased.with(key);
                self.keysDown = self.keysDown.without(key);
                self.keysMutex.unlock();
            }
        },
        win32.WM_DPICHANGED => {
            if (window) |self| {
                const previousDpi = self.dpi;
                const wParam32: u32 = @truncate(wParam);
                const dpiX: u16 = @truncate(wParam32);
                const dpiY: u16 = @truncate(wParam32 >> 16);
                self.dpi = .{ @intCast(dpiX), @intCast(dpiY) };

                const suggestedRect: *const win32.RECT = @ptrFromInt(@as(usize, @bitCast(lParam)));
                _ = win32.SetWindowPos(
                    hwnd,
                    null,
                    @intCast(suggestedRect.left),
                    @intCast(suggestedRect.top),
                    @intCast(suggestedRect.right - suggestedRect.left),
                    @intCast(suggestedRect.bottom - suggestedRect.top),
                    win32.SWP_NOZORDER | win32.SWP_NOACTIVATE,
                );

                const dpiChanged = self.dpi[0] != previousDpi[0] or self.dpi[1] != previousDpi[1];
                self.emitResizeIfNeeded(hwnd, dpiChanged);
            }
        },
        win32.WM_DESTROY => {
            if (window) |self| {
                self.running = false;
            }
        },
        win32.WM_CLOSE => {
            if (window) |self| {
                self.running = false;
            }
        },
        win32.WM_ACTIVATEAPP => {
            std.log.debug("activate app", .{});
        },
        else => {
            return win32.DefWindowProcW(hwnd, message, wParam, lParam);
        },
    }

    return 0;
}

pub fn targetFrameTimeNs(self: *const @This()) u64 {
    const fallback_60hz: u64 = 16_666_667; // ~60 Hz in nanoseconds

    // Get the monitor that contains most of this window
    const monitor = win32.MonitorFromWindow(self.handle, win32.MONITOR_DEFAULTTONEAREST);
    if (monitor == null) {
        return fallback_60hz;
    }

    // Get monitor info to retrieve the device name
    var monitorInfo: win32.MONITORINFOEXW = .{};
    if (win32.GetMonitorInfoW(monitor, &monitorInfo) == 0) {
        return fallback_60hz;
    }

    // Get current display settings for this monitor
    var devMode: win32.DEVMODEW = .{};
    if (win32.EnumDisplaySettingsW(@ptrCast(&monitorInfo.szDevice), win32.ENUM_CURRENT_SETTINGS, &devMode) == 0) {
        return fallback_60hz;
    }

    const refreshRate = devMode.dmDisplayFrequency;
    if (refreshRate == 0 or refreshRate == 1) {
        // 0 or 1 means default/unknown
        return fallback_60hz;
    }

    return @divTrunc(1_000_000_000, @as(u64, refreshRate));
}

pub fn isHoldingShift(self: *Self) bool {
    self.keysMutex.lock();
    defer self.keysMutex.unlock();
    return self.keysDown.shiftLeft or self.keysDown.shiftRight;
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
        .default => win32.LoadCursorW(null, win32.IDC_ARROW),
        .text => win32.LoadCursorW(null, win32.IDC_IBEAM),
        .pointer => win32.LoadCursorW(null, win32.IDC_HAND),
    } orelse return error.FailedToLoadCursor;

    _ = win32.SetCursor(nativeCursor);
}

pub fn handleEvents(self: *@This()) !void {
    while (self.running) {
        var message: win32.MSG = undefined;
        if (win32.GetMessageW(&message, self.handle, 0, 0) != 0) {
            _ = win32.TranslateMessage(&message);
            _ = win32.DispatchMessageW(&message);
        } else {
            self.running = false;
        }
    }
}
