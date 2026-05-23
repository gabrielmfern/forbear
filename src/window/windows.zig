const std = @import("std");
const win32 = @import("../windows/win32.zig");
const window_root = @import("root.zig");
const Cursor = window_root.Cursor;
pub const Key = window_root.Key;
pub const KeyboardKey = window_root.KeyboardKey;

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

keysDown: struct {
    shift: bool,
},

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
    /// One-shot: fires only on the initial transition to pressed.
    keypress: ?struct {
        data: *anyopaque,
        function: *const fn (window: *Self, key: KeyboardKey, data: *anyopaque) void,
    } = null,
    /// Fires on initial press and again for each OS-driven repeat tick
    /// (`is_repeat` mirrors lParam bit 30 / "previous key state" on
    /// WM_KEYDOWN, which is set when Windows re-fires the message for
    /// a held key).
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

fn virtualKeyToKey(vk: win32.WPARAM) Key {
    return switch (vk) {
        0x08 => .backspace,
        0x09 => .tab,
        0x0D => .enter,
        0x14 => .caps_lock,
        0x1B => .escape,
        0x20 => .space,
        0x21 => .page_up,
        0x22 => .page_down,
        0x23 => .end,
        0x24 => .home,
        0x25 => .arrow_left,
        0x26 => .arrow_up,
        0x27 => .arrow_right,
        0x28 => .arrow_down,
        0x2D => .insert,
        0x2E => .delete,
        '0' => .digit_0,
        '1' => .digit_1,
        '2' => .digit_2,
        '3' => .digit_3,
        '4' => .digit_4,
        '5' => .digit_5,
        '6' => .digit_6,
        '7' => .digit_7,
        '8' => .digit_8,
        '9' => .digit_9,
        'A' => .a,
        'B' => .b,
        'C' => .c,
        'D' => .d,
        'E' => .e,
        'F' => .f,
        'G' => .g,
        'H' => .h,
        'I' => .i,
        'J' => .j,
        'K' => .k,
        'L' => .l,
        'M' => .m,
        'N' => .n,
        'O' => .o,
        'P' => .p,
        'Q' => .q,
        'R' => .r,
        'S' => .s,
        'T' => .t,
        'U' => .u,
        'V' => .v,
        'W' => .w,
        'X' => .x,
        'Y' => .y,
        'Z' => .z,
        0x5B => .super_left,
        0x5C => .super_right,
        0x70 => .f1,
        0x71 => .f2,
        0x72 => .f3,
        0x73 => .f4,
        0x74 => .f5,
        0x75 => .f6,
        0x76 => .f7,
        0x77 => .f8,
        0x78 => .f9,
        0x79 => .f10,
        0x7A => .f11,
        0x7B => .f12,
        0xA0 => .shift_left,
        0xA1 => .shift_right,
        0xA2 => .control_left,
        0xA3 => .control_right,
        0xA4 => .alt_left,
        0xA5 => .alt_right,
        // Generic VK_SHIFT/CONTROL/MENU come through without left/right
        // distinction — bias to the left variant.
        0x10 => .shift_left,
        0x11 => .control_left,
        0x12 => .alt_left,
        else => .unknown,
    };
}

/// Translate the current keystroke into UTF-8 using the active keyboard
/// layout + modifier state. Writes into `out` and returns the byte length.
/// Returns 0 for keys with no textual interpretation (arrows, F-keys, etc.).
fn translateToUtf8(virtualKey: win32.WPARAM, scan_code: u32, out: *[16]u8) usize {
    var key_state: [256]u8 = undefined;
    if (win32.GetKeyboardState(&key_state) == 0) return 0;

    var utf16_buf: [4]u16 = undefined;
    const n = win32.ToUnicode(
        @intCast(virtualKey),
        scan_code,
        &key_state,
        &utf16_buf,
        utf16_buf.len,
        0,
    );
    if (n <= 0) return 0;

    const utf16_len: usize = @intCast(n);
    return std.unicode.utf16LeToUtf8(&out, utf16_buf[0..utf16_len]) catch return 0;
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

    window.keysDown = .{
        .shift = false,
    };

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
                switch (wParam) {
                    win32.VK_SHIFT => {
                        self.keysDown.shift = true;
                    },
                    else => {},
                }
                // lParam encoding (WM_KEYDOWN):
                //   bits 0 ..15  = repeat count (1 unless the message coalesces)
                //   bits 16..23 = scan code
                //   bit  24     = Indicates whether it's an extended key
                //   bit  30     = previous key state (1 = key was already down → OS repeat)
                const lp: u32 = @truncate(@as(u64, @bitCast(lParam)));
                const scan_code: u32 = (lp >> 16) & 0xFF;
                const is_repeat: bool = (lp & (1 << 30)) != 0;
                const mapped = virtualKeyToKey(wParam);
                var text_buf: [16]u8 = undefined;
                const text_len = translateToUtf8(wParam, scan_code, &text_buf);
                const ev: KeyboardKey = .{
                    .time = win32.GetMessageTime(),
                    .key = mapped,
                    .text = text_buf[0..text_len],
                    .is_repeat = is_repeat,
                };
                if (!is_repeat) {
                    if (self.handlers.keypress) |h| h.function(self, ev, h.data);
                }
                if (self.handlers.keydown) |h| h.function(self, ev, h.data);
            }
        },
        win32.WM_KEYUP => {
            if (window) |self| {
                switch (wParam) {
                    win32.VK_SHIFT => {
                        self.keysDown.shift = false;
                    },
                    else => {},
                }
                // lParam encoding (WM_KEYUP):
                //   bits 0 ..15  = repeat count (always 1 for WM_KEYUP)
                //   bits 16..23 = scan code
                //   bit  24     = Indicates whether it's an extended key
                //   bit  30     = previous key state (always 1 for WM_KEYUP)
                const lp: u32 = @truncate(@as(u64, @bitCast(lParam)));
                const scan_code: u32 = (lp >> 16) & 0xFF;
                const mapped = virtualKeyToKey(wParam);
                var text_buf: [16]u8 = undefined;
                const text_len = translateToUtf8(wParam, scan_code, &text_buf);
                const ev: KeyboardKey = .{
                    .time = win32.GetMessageTime(),
                    .key = mapped,
                    .text = text_buf[0..text_len],
                    .is_repeat = false,
                };
                if (self.handlers.keyup) |h| h.function(self, ev, h.data);
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

pub fn isHoldingShift(self: *const Self) bool {
    return self.keysDown.shift;
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
