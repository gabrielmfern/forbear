// Manual Windows API declarations to avoid @cImport macro translation issues
// This provides clean Zig bindings for the Windows APIs needed for windowing

const std = @import("std");
const c = @import("../c.zig").c;

// Basic Windows types
pub const BOOL = c_int;
pub const WORD = u16;
pub const DWORD = u32;
pub const UINT = c_uint;
pub const INT = c_int;
pub const LONG = c_long;
pub const LONG_PTR = isize;
pub const UINT_PTR = usize;
pub const SIZE_T = usize;
pub const ATOM = WORD;

pub const LPVOID = ?*anyopaque;
pub const LPCVOID = ?*const anyopaque;
pub const LPWSTR = [*:0]u16;
pub const LPCWSTR = [*:0]const u16;

pub const HANDLE = *anyopaque;
pub const HWND = ?HANDLE;
pub const HINSTANCE = ?HANDLE;
pub const HMODULE = ?HANDLE;
pub const HICON = ?HANDLE;
pub const HCURSOR = ?HANDLE;
pub const HBRUSH = ?HANDLE;
pub const HMENU = ?HANDLE;
pub const HDC = ?HANDLE;

pub const WPARAM = UINT_PTR;
pub const LPARAM = LONG_PTR;
pub const LRESULT = LONG_PTR;

// Window procedure callback type
pub const WNDPROC = *const fn (hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.c) LRESULT;

// WNDCLASSEXW structure
pub const WNDCLASSEXW = extern struct {
    cbSize: UINT = @sizeOf(WNDCLASSEXW),
    style: UINT = 0,
    lpfnWndProc: WNDPROC,
    cbClsExtra: INT = 0,
    cbWndExtra: INT = 0,
    hInstance: HINSTANCE = null,
    hIcon: HICON = null,
    hCursor: HCURSOR = null,
    hbrBackground: HBRUSH = null,
    lpszMenuName: ?LPCWSTR = null,
    lpszClassName: LPCWSTR,
    hIconSm: HICON = null,
};

pub const WINDOWPOS = extern struct {
    hwnd: HWND = null,
    hwndInsertAfter: HWND = null,
    x: INT = 0,
    y: INT = 0,
    cx: INT = 0,
    cy: INT = 0,
    flags: UINT = 0,
};

// RECT structure
pub const RECT = extern struct {
    left: LONG = 0,
    top: LONG = 0,
    right: LONG = 0,
    bottom: LONG = 0,
};

// POINT structure
pub const POINT = extern struct {
    x: LONG = 0,
    y: LONG = 0,
};

// MSG structure
pub const MSG = extern struct {
    hwnd: HWND = null,
    message: UINT = 0,
    wParam: WPARAM = 0,
    lParam: LPARAM = 0,
    time: DWORD = 0,
    pt: POINT = .{},
};

// Window styles
pub const WS_OVERLAPPED: DWORD = 0x00000000;
pub const WS_POPUP: DWORD = 0x80000000;
pub const WS_CHILD: DWORD = 0x40000000;
pub const WS_MINIMIZE: DWORD = 0x20000000;
pub const WS_VISIBLE: DWORD = 0x10000000;
pub const WS_DISABLED: DWORD = 0x08000000;
pub const WS_CLIPSIBLINGS: DWORD = 0x04000000;
pub const WS_CLIPCHILDREN: DWORD = 0x02000000;
pub const WS_MAXIMIZE: DWORD = 0x01000000;
pub const WS_CAPTION: DWORD = 0x00C00000;
pub const WS_BORDER: DWORD = 0x00800000;
pub const WS_DLGFRAME: DWORD = 0x00400000;
pub const WS_VSCROLL: DWORD = 0x00200000;
pub const WS_HSCROLL: DWORD = 0x00100000;
pub const WS_SYSMENU: DWORD = 0x00080000;
pub const WS_THICKFRAME: DWORD = 0x00040000;
pub const WS_GROUP: DWORD = 0x00020000;
pub const WS_TABSTOP: DWORD = 0x00010000;
pub const WS_MINIMIZEBOX: DWORD = 0x00020000;
pub const WS_MAXIMIZEBOX: DWORD = 0x00010000;
pub const WS_OVERLAPPEDWINDOW: DWORD = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;

// Class styles
pub const CS_VREDRAW: UINT = 0x0001;
pub const CS_HREDRAW: UINT = 0x0002;
pub const CS_DBLCLKS: UINT = 0x0008;
pub const CS_OWNDC: UINT = 0x0020;
pub const CS_CLASSDC: UINT = 0x0040;
pub const CS_PARENTDC: UINT = 0x0080;
pub const CS_NOCLOSE: UINT = 0x0200;
pub const CS_SAVEBITS: UINT = 0x0800;
pub const CS_BYTEALIGNCLIENT: UINT = 0x1000;
pub const CS_BYTEALIGNWINDOW: UINT = 0x2000;
pub const CS_GLOBALCLASS: UINT = 0x4000;

// Window messages
pub const WM_NULL: UINT = 0x0000;
pub const WM_NCCREATE: UINT = 0x0081;
pub const WM_CREATE: UINT = 0x0001;
pub const WM_DESTROY: UINT = 0x0002;
pub const WM_DPICHANGED: UINT = 0x02E0;
pub const WM_WINDOWPOSCHANGED: UINT = 0x0047;
pub const WM_MOVE: UINT = 0x0003;
pub const WM_SIZE: UINT = 0x0005;
pub const WM_EXITSIZEMOVE: UINT = 0x0232;
pub const WM_ENTERSIZEMOVE: UINT = 0x0231;
pub const WM_SIZING: UINT = 0x0214;
pub const WM_ACTIVATE: UINT = 0x0006;
pub const WM_SETFOCUS: UINT = 0x0007;
pub const WM_KILLFOCUS: UINT = 0x0008;
pub const WM_ENABLE: UINT = 0x000A;
pub const WM_SETREDRAW: UINT = 0x000B;
pub const WM_SETTEXT: UINT = 0x000C;
pub const WM_GETTEXT: UINT = 0x000D;
pub const WM_GETTEXTLENGTH: UINT = 0x000E;
pub const WM_PAINT: UINT = 0x000F;
pub const WM_CLOSE: UINT = 0x0010;
pub const WM_QUIT: UINT = 0x0012;
pub const WM_ACTIVATEAPP: UINT = 0x001C;
pub const WM_KEYDOWN: UINT = 0x0100;
pub const WM_KEYUP: UINT = 0x0101;
pub const WM_CHAR: UINT = 0x0102;
pub const WM_SYSKEYDOWN: UINT = 0x0104;
pub const WM_SYSKEYUP: UINT = 0x0105;
pub const WM_SYSCHAR: UINT = 0x0106;
pub const WM_MOUSEMOVE: UINT = 0x0200;
pub const WM_LBUTTONDOWN: UINT = 0x0201;
pub const WM_LBUTTONUP: UINT = 0x0202;
pub const WM_LBUTTONDBLCLK: UINT = 0x0203;
pub const WM_RBUTTONDOWN: UINT = 0x0204;
pub const WM_RBUTTONUP: UINT = 0x0205;
pub const WM_RBUTTONDBLCLK: UINT = 0x0206;
pub const WM_MBUTTONDOWN: UINT = 0x0207;
pub const WM_MBUTTONUP: UINT = 0x0208;
pub const WM_MBUTTONDBLCLK: UINT = 0x0209;
pub const WM_MOUSEWHEEL: UINT = 0x020A;

// Virtual Keycodes https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
pub const VK_SHIFT: usize = 0x10;

// CW_USEDEFAULT
pub const CW_USEDEFAULT: c_int = @bitCast(@as(c_uint, 0x80000000));

// Standard cursor IDs (these are resource IDs cast to pointers)
pub const IDC_ARROW: LPCWSTR = @ptrFromInt(32512);
pub const IDC_IBEAM: LPCWSTR = @ptrFromInt(32513);
pub const IDC_WAIT: LPCWSTR = @ptrFromInt(32514);
pub const IDC_CROSS: LPCWSTR = @ptrFromInt(32515);
pub const IDC_UPARROW: LPCWSTR = @ptrFromInt(32516);
pub const IDC_SIZE: LPCWSTR = @ptrFromInt(32640);
pub const IDC_ICON: LPCWSTR = @ptrFromInt(32641);
pub const IDC_SIZENWSE: LPCWSTR = @ptrFromInt(32642);
pub const IDC_SIZENESW: LPCWSTR = @ptrFromInt(32643);
pub const IDC_SIZEWE: LPCWSTR = @ptrFromInt(32644);
pub const IDC_SIZENS: LPCWSTR = @ptrFromInt(32645);
pub const IDC_SIZEALL: LPCWSTR = @ptrFromInt(32646);
pub const IDC_NO: LPCWSTR = @ptrFromInt(32648);
pub const IDC_HAND: LPCWSTR = @ptrFromInt(32649);
pub const IDC_APPSTARTING: LPCWSTR = @ptrFromInt(32650);
pub const IDC_HELP: LPCWSTR = @ptrFromInt(32651);

// PeekMessage flags
pub const PM_NOREMOVE: UINT = 0x0000;
pub const PM_REMOVE: UINT = 0x0001;
pub const PM_NOYIELD: UINT = 0x0002;

// ShowWindow commands
pub const SW_HIDE: c_int = 0;
pub const SW_SHOWNORMAL: c_int = 1;
pub const SW_SHOW: c_int = 5;
pub const SW_MINIMIZE: c_int = 6;
pub const SW_MAXIMIZE: c_int = 3;
pub const SW_RESTORE: c_int = 9;

// WINDOWPOS flags
/// Draws a frame (defined in the window's class description) around the
/// window. Same as the SWP_FRAMECHANGED flag.
pub const SWP_DRAWFRAME = 0x0020;
/// Sends a WM_NCCALCSIZE message to the window, even if the window's size is
/// not being changed. If this flag is not specified, WM_NCCALCSIZE is sent only
/// when the window's size is being changed.
pub const SWP_FRAMECHANGED = 0x0020;
/// Hides the window.
pub const SWP_HIDEWINDOW = 0x0080;
/// Does not activate the window. If this flag is not set, the window is
/// activated and moved to the top of either the topmost or non-topmost group
/// (depending on the setting of the hwndInsertAfter member).
pub const SWP_NOACTIVATE = 0x0010;
/// Discards the entire contents of the client area. If this flag is not
/// specified, the valid contents of the client area are saved and copied back
/// into the client area after the window is sized or repositioned.
pub const SWP_NOCOPYBITS = 0x0100;
/// Retains the current position (ignores the x and y members).
pub const SWP_NOMOVE = 0x0002;
/// Does not change the owner window's position in the Z order.
pub const SWP_NOOWNERZORDER = 0x0200;
/// Does not redraw changes. If this flag is set, no repainting of any kind
/// occurs. This applies to the client area, the nonclient area (including the
/// title bar and scroll bars), and any part of the parent window uncovered as
/// a result of the window being moved. When this flag is set, the application
/// must explicitly invalidate or redraw any parts of the window and parent
/// window that need redrawing.
pub const SWP_NOREDRAW = 0x0008;
/// Does not change the owner window's position in the Z order. Same as the
/// SWP_NOOWNERZORDER flag.
pub const SWP_NOREPOSITION = 0x0200;
/// Prevents the window from receiving the WM_WINDOWPOSCHANGING message.
pub const SWP_NOSENDCHANGING = 0x0400;
/// Retains the current size (ignores the cx and cy members).
pub const SWP_NOSIZE = 0x0001;
/// Retains the current Z order (ignores the hwndInsertAfter member).
pub const SWP_NOZORDER = 0x0004;
/// Displays the window.
pub const SWP_SHOWWINDOW = 0x0040;

// External function declarations
pub extern "kernel32" fn GetModuleHandleW(lpModuleName: ?LPCWSTR) callconv(.c) HMODULE;
pub extern "kernel32" fn GetLastError() callconv(.c) DWORD;

pub extern "user32" fn RegisterClassExW(lpWndClass: *const WNDCLASSEXW) callconv(.c) ATOM;
pub extern "user32" fn UnregisterClassW(lpClassName: LPCWSTR, hInstance: HINSTANCE) callconv(.c) BOOL;

pub extern "user32" fn CreateWindowExW(
    dwExStyle: DWORD,
    lpClassName: LPCWSTR,
    lpWindowName: LPCWSTR,
    dwStyle: DWORD,
    x: c_int,
    y: c_int,
    nWidth: c_int,
    nHeight: c_int,
    hWndParent: HWND,
    hMenu: HMENU,
    hInstance: HINSTANCE,
    lpParam: LPVOID,
) callconv(.c) HWND;

pub extern "user32" fn DestroyWindow(hWnd: HWND) callconv(.c) BOOL;
pub extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: c_int) callconv(.c) BOOL;
pub extern "user32" fn UpdateWindow(hWnd: HWND) callconv(.c) BOOL;

pub extern "user32" fn DefWindowProcW(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.c) LRESULT;

pub extern "user32" fn GetMessageW(lpMsg: *MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) callconv(.c) BOOL;
pub extern "user32" fn PeekMessageW(lpMsg: *MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) callconv(.c) BOOL;
pub extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.c) BOOL;
pub extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.c) LRESULT;
pub extern "user32" fn PostQuitMessage(nExitCode: c_int) callconv(.c) void;

pub extern "user32" fn LoadCursorW(hInstance: HINSTANCE, lpCursorName: LPCWSTR) callconv(.c) HCURSOR;
pub extern "user32" fn SetCursor(hCursor: HCURSOR) callconv(.c) HCURSOR;

pub extern "user32" fn AdjustWindowRectEx(lpRect: *RECT, dwStyle: DWORD, bMenu: BOOL, dwExStyle: DWORD) callconv(.c) BOOL;
pub extern "user32" fn SetWindowPos(
    hWnd: HWND,
    hWndInsertAfter: HWND,
    X: c_int,
    Y: c_int,
    cx: c_int,
    cy: c_int,
    uFlags: UINT,
) callconv(.c) BOOL;
pub extern "user32" fn GetClientRect(hWnd: HWND, lpRect: *RECT) callconv(.c) BOOL;
pub extern "user32" fn GetWindowRect(hWnd: HWND, lpRect: *RECT) callconv(.c) BOOL;

pub extern "user32" fn SetWindowTextW(hWnd: HWND, lpString: LPCWSTR) callconv(.c) BOOL;
pub extern "user32" fn GetWindowTextW(hWnd: HWND, lpString: LPWSTR, nMaxCount: c_int) callconv(.c) c_int;

pub extern "user32" fn InvalidateRect(hWnd: HWND, lpRect: ?*const RECT, bErase: BOOL) callconv(.c) BOOL;

pub extern "user32" fn GetDC(hWnd: HWND) callconv(.c) HDC;
pub extern "user32" fn ReleaseDC(hWnd: HWND, hDC: HDC) callconv(.c) c_int;

// DPI awareness
pub const DPI_AWARENESS_CONTEXT = ?HANDLE;
pub const DPI_AWARENESS_CONTEXT_UNAWARE: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -1))));
pub const DPI_AWARENESS_CONTEXT_SYSTEM_AWARE: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -2))));
pub const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -3))));
pub const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -4))));
pub const DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -5))));

pub extern "user32" fn GetDpiForWindow(hwnd: HWND) callconv(.c) UINT;
pub extern "user32" fn SetThreadDpiAwarenessContext(dpiContext: DPI_AWARENESS_CONTEXT) callconv(.c) DPI_AWARENESS_CONTEXT;
pub extern "user32" fn SetProcessDpiAwarenessContext(value: DPI_AWARENESS_CONTEXT) callconv(.c) BOOL;

// Window long ptr indices
pub const GWLP_WNDPROC: c_int = -4;
pub const GWLP_HINSTANCE: c_int = -6;
pub const GWLP_HWNDPARENT: c_int = -8;
pub const GWLP_USERDATA: c_int = -21;
pub const GWLP_ID: c_int = -12;

pub extern "user32" fn SetWindowLongPtrW(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) callconv(.c) LONG_PTR;
pub extern "user32" fn GetWindowLongPtrW(hWnd: HWND, nIndex: c_int) callconv(.c) LONG_PTR;

// CREATESTRUCT for WM_CREATE/WM_NCCREATE
pub const CREATESTRUCTW = extern struct {
    lpCreateParams: LPVOID,
    hInstance: HINSTANCE,
    hMenu: HMENU,
    hwndParent: HWND,
    cy: c_int,
    cx: c_int,
    y: c_int,
    x: c_int,
    style: LONG,
    lpszName: ?LPCWSTR,
    lpszClass: ?LPCWSTR,
    dwExStyle: DWORD,
};

// Monitor functions
pub const HMONITOR = ?HANDLE;

pub const MONITOR_DEFAULTTONULL: DWORD = 0x00000000;
pub const MONITOR_DEFAULTTOPRIMARY: DWORD = 0x00000001;
pub const MONITOR_DEFAULTTONEAREST: DWORD = 0x00000002;

pub const MONITORINFOEXW = extern struct {
    cbSize: DWORD = @sizeOf(MONITORINFOEXW),
    rcMonitor: RECT = .{},
    rcWork: RECT = .{},
    dwFlags: DWORD = 0,
    szDevice: [32]u16 = [_]u16{0} ** 32,
};

pub const DEVMODEW = extern struct {
    dmDeviceName: [32]u16 = [_]u16{0} ** 32,
    dmSpecVersion: WORD = 0,
    dmDriverVersion: WORD = 0,
    dmSize: WORD = @sizeOf(DEVMODEW),
    dmDriverExtra: WORD = 0,
    dmFields: DWORD = 0,
    // Union of POINTL/display settings - using anonymous struct for display settings
    dmPosition: POINT = .{},
    dmDisplayOrientation: DWORD = 0,
    dmDisplayFixedOutput: DWORD = 0,
    dmColor: i16 = 0,
    dmDuplex: i16 = 0,
    dmYResolution: i16 = 0,
    dmTTOption: i16 = 0,
    dmCollate: i16 = 0,
    dmFormName: [32]u16 = [_]u16{0} ** 32,
    dmLogPixels: WORD = 0,
    dmBitsPerPel: DWORD = 0,
    dmPelsWidth: DWORD = 0,
    dmPelsHeight: DWORD = 0,
    dmDisplayFlags: DWORD = 0,
    dmDisplayFrequency: DWORD = 0,
    dmICMMethod: DWORD = 0,
    dmICMIntent: DWORD = 0,
    dmMediaType: DWORD = 0,
    dmDitherType: DWORD = 0,
    dmReserved1: DWORD = 0,
    dmReserved2: DWORD = 0,
    dmPanningWidth: DWORD = 0,
    dmPanningHeight: DWORD = 0,
};

pub const ENUM_CURRENT_SETTINGS: DWORD = 0xFFFFFFFF;

pub extern "user32" fn MonitorFromWindow(hwnd: HWND, dwFlags: DWORD) callconv(.c) HMONITOR;
pub extern "user32" fn GetMonitorInfoW(hMonitor: HMONITOR, lpmi: *MONITORINFOEXW) callconv(.c) BOOL;
pub extern "user32" fn EnumDisplaySettingsW(lpszDeviceName: [*:0]const u16, iModeNum: DWORD, lpDevMode: *DEVMODEW) callconv(.c) BOOL;

pub extern "user32" fn SetProcessWorkingSetSize(hProcess: HANDLE, dwMinimumWorkingSetSize: SIZE_T, dwMaximumWorkingSetSize: SIZE_T) callconv(.c) BOOL;
pub extern "user32" fn GetCurrentProcess() callconv(.c) HANDLE;

// Vulkan
pub const VkWin32SurfaceCreateFlagsKHR = c.VkFlags;
pub const VkWin32SurfaceCreateInfoKHR = extern struct {
    sType: c.VkStructureType,
    pNext: ?*const anyopaque,
    flags: VkWin32SurfaceCreateFlagsKHR,
    hinstance: HINSTANCE,
    hwnd: HWND,
};

pub extern "vulkan" fn vkCreateWin32SurfaceKHR(
    instance: c.VkInstance,
    pCreateInfo: ?*const VkWin32SurfaceCreateInfoKHR,
    pAllocator: ?*c.VkAllocationCallbacks,
    pSurface: ?*c.VkSurfaceKHR,
) c.VkResult;
