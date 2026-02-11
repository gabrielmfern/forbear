const std = @import("std");
const win32 = @import("../windows/win32.zig");

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

    _ = win32.SetThreadDpiAwarenessContext(win32.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

    window.updateDpi();

    return window;
}

fn updateDpi(self: *@This()) void {
    const dpi = win32.GetDpiForWindow(self.handle);
    self.dpi = .{ dpi, dpi };
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
                    var rect: win32.RECT = undefined;
                    if (win32.GetClientRect(hwnd, &rect) != 0) {
                        const newWidth: u32 = @intCast(windowpos.cx);
                        const newHeight: u32 = @intCast(windowpos.cy);
                        if (self.width != newWidth or self.height != newHeight) {
                            self.width = newWidth;
                            self.height = newHeight;
                            if (self.handlers.resize) |handler| {
                                handler.function(self, self.width, self.height, self.dpi, handler.data);
                            }
                        }
                    } else {
                        std.log.err("failed to get new window size, ignoring event", .{});
                    }
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
            }
        },
        win32.WM_DPICHANGED => {
            if (window) |self| {
                const dpi: u16 = @truncate(@as(u32, @intCast(lParam)));
                self.dpi = .{ @intCast(dpi), @intCast(dpi) };
                if (self.handlers.resize) |handler| {
                    handler.function(self, self.width, self.height, self.dpi, handler.data);
                }
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
