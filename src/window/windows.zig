const std = @import("std");
const win32 = @import("windows/win32.zig");

handle: win32.HWND,
hInstance: win32.HINSTANCE,

width: u32,
height: u32,
title: [:0]const u16,
className: [:0]const u16,
running: bool,
scale: u32,
dpi: [2]u32,

allocator: std.mem.Allocator,

pub fn init(
    width: u32,
    height: u32,
    title: [:0]const u8,
    app_id: [:0]const u8,
    allocator: std.mem.Allocator,
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
    window.scale = 120;
    window.dpi = .{ 96, 96 };

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

    return window;
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
        win32.WM_SIZING => {
            std.log.debug("sizing", .{});
            if (window) |self| {
                const rect: *win32.RECT = @ptrFromInt(@as(usize, @intCast(lParam)));
                self.width = @intCast(rect.right - rect.left);
                self.height = @intCast(rect.bottom - rect.top);
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

pub fn handleEvents(self: *@This()) !void {
    var message: win32.MSG = undefined;
    std.log.debug("get message started", .{});
    if (win32.GetMessageW(&message, self.handle, 0, 0) > 0) {
        std.log.debug("get message returned", .{});
        _ = win32.TranslateMessage(&message);
        _ = win32.DispatchMessageW(&message);
    } else {
        self.running = false;
    }
}
