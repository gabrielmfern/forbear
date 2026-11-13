#module_parameters(JAVASCRIPT_ADAPTER := false);

Vector2 :: Math.Vector2;
Vector3 :: Math.Vector3;
Vector4 :: Math.Vector4;
operator + :: Math.operator +;
operator - :: Math.operator -;
operator * :: Math.operator *;
operator / :: Math.operator /;
operator == :: Math.operator ==;

#scope_module

#import "Basic";
#import "Flat_Pool";
#import "GL";
#import "Hash";
#import "Hash_Table";
#import "Memory";
#if OS != .WINDOWS {
    #import "POSIX";
    #import "Socket";
}
#import "String";
Math :: #import "Math";

min :: Math.min;
max :: Math.max;
FLOAT32_NAN :: Math.FLOAT32_NAN;
FLOAT32_INFINITY :: Math.FLOAT32_INFINITY;
U16_MAX :: Math.U16_MAX;
U32_MAX :: Math.U32_MAX;
U64_MAX :: Math.U64_MAX;
floor :: Math.floor;
abs :: Math.abs;
isnan :: Math.isnan;
make_vector2 :: Math.make_vector2;
make_vector4 :: Math.make_vector4;

isnan :: (value: Vector2) -> bool {
    return isnan(value.x) || isnan(value.y);
}

compile_shader :: (kind: GLenum, source: string) -> u32 {
    shader := glCreateShader(kind);
    data := source.data;
    length: GLint = xx source.count;
    glShaderSource(shader, 1, *data, *length);
    glCompileShader(shader);

    status: GLint;
    glGetShaderiv(shader, GL_COMPILE_STATUS, *status);
    if !status {
        log: [1024]u8;
        log_length: GLsizei;
        glGetShaderInfoLog(shader, log.count, *log_length, log.data);
        log_error("failed to compile shader: %\n", to_string(log.data, log_length));
        exit(-1);
    }
    return shader;
}

append_text :: (source: string, destination: *string, buffer: []u8) {
    is_control_character := source.count == 1 && (source[0] < 0x20 || source[0] == 0x7f);
    if !is_control_character {
        if destination.count + source.count <= buffer.count {
            memcpy(destination.data + destination.count, source.data, source.count);
            destination.count += source.count;
        } else {
            log_error("trying to append to a buffered string of size %, which exceeds the buffer size %. dropping it entirely.", source.count, buffer.count);
        }
    }
}

is_high_surrogate :: (unit: u16) -> bool {
    return unit >= 0xD800 && unit <= 0xDBFF;
}
is_low_surrogate :: (unit: u16) -> bool {
    return unit >= 0xDC00 && unit <= 0xDFFF;
}
utf16_to_code_point :: (units: []u16, count: s32) -> u32 {
    assert(units.count >= 2);
    code_point: u32;
    if count == 1 && !is_high_surrogate(units[0]) && !is_low_surrogate(units[0]) {
        code_point = units[0];
    } else if count == 2 && is_high_surrogate(units[0]) && is_low_surrogate(units[1]) {
        code_point = 0x10000 + ((cast(u32) units[0] - 0xD800) << 10) + (units[1] - 0xDC00);
    }
    return code_point;
}
#if OS == .WINDOWS {
    key_from_virtual_key :: (vk: u32, scancode: u32) -> Key {
        state: [256]u8;
        GetKeyboardState(state.data);
        if !(state[VK_MENU] & 0x80) {
            state[VK_CONTROL] = 0;
            state[VK_LCONTROL] = 0;
            state[VK_RCONTROL] = 0;
        }
        units: [4]u16;
        count := ToUnicodeEx(vk, scancode, state.data, units.data, units.count, 0x4, GetKeyboardLayout(0));
        code_point := utf16_to_code_point(units, count);
        if (code_point >= #char "A" && code_point <= #char "Z")
        || (code_point >= 0xC0 && code_point <= 0xDE && code_point != 0xD7) {
            // lowercases all of the LATIN-1 uppercase characters
            //
            // TODO: should we use some builtin function that has a wider reach than this?
            code_point += 32;
        }
        return xx code_point;
    }
} else #if OS == .MACOS {
    carbon :: #library,system "Carbon";
    core_foundation :: #library,system "CoreFoundation";
    TISCopyCurrentKeyboardLayoutInputSource :: () -> *void #foreign carbon;
    TISGetInputSourceProperty :: (source: *void, key: *void) -> *void #foreign carbon;
    kTISPropertyUnicodeKeyLayoutData: *void #elsewhere carbon;
    LMGetKbdType :: () -> u8 #foreign carbon;
    UCKeyTranslate :: (layout: *void, code: u16, action: u16, modifiers: u32, keyboard_type: u32, options: u32, dead_key_state: *u32, max_length: u64, length: *u64, characters: *u16) -> s32 #foreign carbon;
    CFDataGetBytePtr :: (data: *void) -> *void #foreign core_foundation;
    CFRelease :: (object: *void) #foreign core_foundation;

    // Copied over from Carbon.framework/Frameworks/HIToolbox.framework/Headers/Events.h,
    // these are keycodes for keys that are independent of keyboard layout
    kVK_Return                    :: 0x24;
    kVK_Tab                       :: 0x30;
    kVK_Delete                    :: 0x33;
    kVK_Escape                    :: 0x35;
    kVK_Command                   :: 0x37;
    kVK_Shift                     :: 0x38;
    kVK_CapsLock                  :: 0x39;
    kVK_Option                    :: 0x3A;
    kVK_Control                   :: 0x3B;
    kVK_RightCommand              :: 0x36;
    kVK_RightShift                :: 0x3C;
    kVK_RightOption               :: 0x3D;
    kVK_RightControl              :: 0x3E;
    kVK_Function                  :: 0x3F; // TODO: also include this in the Key enum
    kVK_F17                       :: 0x40;
    kVK_VolumeUp                  :: 0x48; // TODO: also include this in the Key enum
    kVK_VolumeDown                :: 0x49; // TODO: also include this in the Key enum
    kVK_Mute                      :: 0x4A; // TODO: also include this in the Key enum
    kVK_F18                       :: 0x4F;
    kVK_F19                       :: 0x50;
    kVK_F20                       :: 0x5A;
    kVK_F5                        :: 0x60;
    kVK_F6                        :: 0x61;
    kVK_F7                        :: 0x62;
    kVK_F3                        :: 0x63;
    kVK_F8                        :: 0x64;
    kVK_F9                        :: 0x65;
    kVK_F11                       :: 0x67;
    kVK_F13                       :: 0x69;
    kVK_F16                       :: 0x6A;
    kVK_F14                       :: 0x6B;
    kVK_F10                       :: 0x6D;
    kVK_ContextualMenu            :: 0x6E; // TODO: also include this in the Key enum
    kVK_F12                       :: 0x6F;
    kVK_F15                       :: 0x71;
    kVK_Help                      :: 0x72; // TODO: also include this in the Key enum
    kVK_Home                      :: 0x73;
    kVK_PageUp                    :: 0x74;
    kVK_ForwardDelete             :: 0x75;
    kVK_F4                        :: 0x76;
    kVK_End                       :: 0x77;
    kVK_F2                        :: 0x78;
    kVK_PageDown                  :: 0x79;
    kVK_F1                        :: 0x7A;
    kVK_LeftArrow                 :: 0x7B;
    kVK_RightArrow                :: 0x7C;
    kVK_DownArrow                 :: 0x7D;
    kVK_UpArrow                   :: 0x7E;

    // In macOS there's no such thing as a virtual key, it's either the physical key or the logical key.
    // Carbon does call the physical key like it was virtual, though.
    key_from_key_code :: (code: u16) -> Key {
        key: Key;
        if code == {
            case kVK_Escape;        key = .ESCAPE;
            case kVK_Return;        key = .ENTER;
            case kVK_Tab;           key = .TAB;
            case kVK_Delete;        key = .BACKSPACE;
            case kVK_ForwardDelete; key = .DELETE;
            case kVK_LeftArrow;     key = .ARROW_LEFT;
            case kVK_RightArrow;    key = .ARROW_RIGHT;
            case kVK_UpArrow;       key = .ARROW_UP;
            case kVK_DownArrow;     key = .ARROW_DOWN;
            case kVK_Home;          key = .HOME;
            case kVK_End;           key = .END;
            case kVK_PageUp;        key = .PAGE_UP;
            case kVK_PageDown;      key = .PAGE_DOWN;
            case kVK_F1;            key = .F1;
            case kVK_F2;            key = .F2;
            case kVK_F3;            key = .F3;
            case kVK_F4;            key = .F4;
            case kVK_F5;            key = .F5;
            case kVK_F6;            key = .F6;
            case kVK_F7;            key = .F7;
            case kVK_F8;            key = .F8;
            case kVK_F9;            key = .F9;
            case kVK_F10;           key = .F10;
            case kVK_F11;           key = .F11;
            case kVK_F12;           key = .F12;
            case kVK_Shift;         key = .SHIFT_LEFT;
            case kVK_RightShift;    key = .SHIFT_RIGHT;
            case kVK_Control;       key = .CONTROL_LEFT;
            case kVK_RightControl;  key = .CONTROL_RIGHT;
            case kVK_Option;        key = .ALT_LEFT;
            case kVK_RightOption;   key = .ALT_RIGHT;
            case kVK_Command;       key = .SUPER_LEFT;
            case kVK_RightCommand;  key = .SUPER_RIGHT;
            case kVK_CapsLock;      key = .CAPS_LOCK;
            case kVK_Function;       #through;
            case kVK_F13;            #through;
            case kVK_F14;            #through;
            case kVK_F15;            #through;
            case kVK_F16;            #through;
            case kVK_F17;            #through;
            case kVK_F18;            #through;
            case kVK_F19;            #through;
            case kVK_F20;            #through;
            case kVK_VolumeUp;       #through;
            case kVK_VolumeDown;     #through;
            case kVK_Mute;           #through;
            case kVK_ContextualMenu; #through;
            case kVK_Help;           return 0;
        }
        if key == 0 {
            source := TISCopyCurrentKeyboardLayoutInputSource();
            defer CFRelease(source);
            layout := TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData);
            if layout {
                current_flags: (*void, Selector) -> NSEventModifierFlags #c_call = xx objc_msgSend;
                flags := current_flags(xx class(NSEvent), selector("modifierFlags"));
                modifiers: u32 = xx ifx flags & .NSEventModifierFlagShift then cast(u32)0x02 else 0;
                dead_key_state: u32;
                units: [4]u16;
                length: u64;
                UCKeyTranslate(CFDataGetBytePtr(layout), code, 0, modifiers, LMGetKbdType(), 1, *dead_key_state, xx units.count, *length, units.data);
                code_point := utf16_to_code_point(units, xx length);
                if (code_point >= #char "A" && code_point <= #char "Z")
                || (code_point >= 0xC0 && code_point <= 0xDE && code_point != 0xD7) {
                    code_point += 32;
                }
                key = xx code_point;
            }
        }
        return key;
    }
} else #if OS == .LINUX {
    key_text :: (state: *xkb_state, key_code: u32, utf8: []u8) -> string {
        text: string;
        if xkb_state_mod_name_is_active(state, XKB_MOD_NAME_ALT.data, .XKB_STATE_MODS_EFFECTIVE) == 0 &&
            xkb_state_mod_name_is_active(state, XKB_MOD_NAME_LOGO.data, .XKB_STATE_MODS_EFFECTIVE) == 0 {
            length := xkb_state_key_get_utf8(state, key_code, utf8.data, xx utf8.count);
            if length < utf8.count {
                text = to_string(utf8.data, length);
            } else {
                log_error("we separated a % sized utf8 buffer for the key %, but it required length %. dropping it entirely.", utf8.count, key_code, length);
            }
        }
        return text;
    }
    key_from_keysym :: (symbol: xkb_keysym_t) -> Key {
        key: Key;
        if symbol == {
            case XKB_KEY_Escape;       key = .ESCAPE;
            case XKB_KEY_Return;       #through;
            case XKB_KEY_KP_Enter;     key = .ENTER;
            case XKB_KEY_Tab;          #through;
            case XKB_KEY_ISO_Left_Tab; key = .TAB;
            case XKB_KEY_BackSpace;    key = .BACKSPACE;
            case XKB_KEY_Delete;       key = .DELETE;
            case XKB_KEY_Insert;       key = .INSERT;
            case XKB_KEY_Left;         key = .ARROW_LEFT;
            case XKB_KEY_Right;        key = .ARROW_RIGHT;
            case XKB_KEY_Up;           key = .ARROW_UP;
            case XKB_KEY_Down;         key = .ARROW_DOWN;
            case XKB_KEY_Home;         key = .HOME;
            case XKB_KEY_End;          key = .END;
            case XKB_KEY_Page_Up;      key = .PAGE_UP;
            case XKB_KEY_Page_Down;    key = .PAGE_DOWN;
            case XKB_KEY_Shift_L;      key = .SHIFT_LEFT;
            case XKB_KEY_Shift_R;      key = .SHIFT_RIGHT;
            case XKB_KEY_Control_L;    key = .CONTROL_LEFT;
            case XKB_KEY_Control_R;    key = .CONTROL_RIGHT;
            case XKB_KEY_Alt_L;        key = .ALT_LEFT;
            case XKB_KEY_Alt_R;        key = .ALT_RIGHT;
            case XKB_KEY_Super_L;      key = .SUPER_LEFT;
            case XKB_KEY_Super_R;      key = .SUPER_RIGHT;
            case XKB_KEY_Caps_Lock;    key = .CAPS_LOCK;
            case;
                if symbol >= XKB_KEY_F1 && symbol <= XKB_KEY_F12 {
                    key = Key.F1 + cast(Key) (symbol - XKB_KEY_F1);
                } else {
                    key = xx xkb_keysym_to_utf32(xkb_keysym_to_lower(symbol));
                }
        }
        return key;
    }
}

#scope_export

#if JAVASCRIPT_ADAPTER == true {
    #load "./adapters/javascript/javascript.jai";
}

#if OS == .WINDOWS {
    #load "bindings-win32.jai";
    #import "Windows";
    #import "Windows_Utf8";
    #import "Unicode";
    user32 :: #library,system "user32";
    kernel32 :: #library,system "kernel32";

    AdjustWindowRectExForDpi :: (rect: *RECT, style: u32, menu: BOOL, extended_style: u32, dpi: u32) -> BOOL #foreign user32;
    DiscardVirtualMemory :: (VirtualAddress: *void, Size: SIZE_T) -> DWORD #foreign kernel32;
    GetDpiForWindow :: (hwnd: HWND) -> u32 #foreign user32;
    GetWindowLongPtrW :: (hwnd: HWND, index: s32) -> s64 #foreign user32;
    SetProcessDpiAwarenessContext :: (value: HANDLE) -> BOOL #foreign user32;
    SetProcessWorkingSetSize :: (hProcess: HANDLE, dwMinimumWorkingSetSize: SIZE_T, dwMaximumWorkingSetSize: SIZE_T) -> BOOL #foreign kernel32;
    TRACKMOUSEEVENT :: struct {
        cbSize: DWORD;
        dwFlags: DWORD;
        hwndTrack: HWND;
        dwHoverTime: DWORD;
    };
    TrackMouseEvent :: (lpEventTrack: *TRACKMOUSEEVENT) -> BOOL #foreign user32;
    ToUnicodeEx :: (wVirtKey: u32, wScanCode: u32, lpKeyState: *u8, pwszBuff: *u16, cchBuff: s32, wFlags: u32, dwhkl: *void) -> s32 #foreign user32;
    GetKeyboardState :: (lpKeyState: *u8) -> BOOL #foreign user32;
    GetKeyboardLayout :: (idThread: DWORD) -> *void #foreign user32;
    MapVirtualKeyW :: (uCode: u32, uMapType: u32) -> u32 #foreign user32;
    SetTimer :: (hWnd: HWND, nIDEvent: u64, uElapse: u32, lpTimerFunc: *void) -> u64 #foreign user32;
    KillTimer :: (hWnd: HWND, uIDEvent: u64) -> BOOL #foreign user32;
    WaitMessage :: () -> BOOL #foreign user32;
    IsIconic :: (hWnd: HWND) -> BOOL #foreign user32;
    GetMessageTime :: () -> s32 #foreign user32;
    GetClipboardSequenceNumber :: () -> DWORD #foreign user32;
    GlobalFree :: (hMem: HGLOBAL) -> HGLOBAL #foreign kernel32;

    MODAL_TAKEOVER_TIMER :: 1;

    MAPVK_VSC_TO_VK_EX :: 3;
    GWLP_USERDATA :: -21;
    TME_LEAVE :: 0x00000002;
    WM_MOUSELEAVE :: 0x02A3;
    WM_ENTERMENULOOP :: 0x0211;
    WM_EXITMENULOOP :: 0x0212;
    WM_CAPTURECHANGED :: 0x0215;

    Windows_GL_Backend :: struct {
        message: (data: *void, window: *Windows_GL_Window, hWnd: HWND, Msg: u32, wParam: WPARAM, lParam: LPARAM) -> result: s64, handled: bool;
        message_data: *void;
        wndproc_context: *#Context;

        cursors: [CURSOR_COUNT]HCURSOR;

        render: (data: *void);
        render_data: *void;

        clipboard_sequence: DWORD;
        clipboard_text_buffer: string;
        clipboard_text: string;
    };
    init_backend :: (using backend: *Windows_GL_Backend) {
        wndproc_context = *context;

        timeBeginPeriod(1);
        DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 :: cast(HANDLE) -4;
        SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

        cursors[Cursor.DEFAULT]     = LoadCursorW(null, xx IDC_ARROW);
        cursors[Cursor.TEXT]        = LoadCursorW(null, xx IDC_IBEAM);
        cursors[Cursor.POINTER]     = LoadCursorW(null, xx IDC_HAND);
        cursors[Cursor.WAIT]        = LoadCursorW(null, xx IDC_WAIT);
        cursors[Cursor.PROGRESS]    = LoadCursorW(null, xx IDC_APPSTARTING);
        cursors[Cursor.CROSSHAIR]   = LoadCursorW(null, xx IDC_CROSS);
        cursors[Cursor.HELP]        = LoadCursorW(null, xx IDC_HELP);
        cursors[Cursor.NOT_ALLOWED] = LoadCursorW(null, xx IDC_NO);
        cursors[Cursor.MOVE]        = LoadCursorW(null, xx IDC_SIZEALL);
        cursors[Cursor.EW_RESIZE]   = LoadCursorW(null, xx IDC_SIZEWE);
        cursors[Cursor.NS_RESIZE]   = LoadCursorW(null, xx IDC_SIZENS);
        cursors[Cursor.NWSE_RESIZE] = LoadCursorW(null, xx IDC_SIZENWSE);
        cursors[Cursor.NESW_RESIZE] = LoadCursorW(null, xx IDC_SIZENESW);

        class: WNDCLASSEXW;
        class.cbSize        = size_of(WNDCLASSEXW);
        class.style         = CS_OWNDC;
        class.lpfnWndProc   = wndproc;
        class.hInstance     = GetModuleHandleW(null);
        class.hCursor       = cursors[Cursor.DEFAULT];
        class.lpszClassName = utf8_to_wide("forbear",, temp);
        RegisterClassExW(*class);
    }
    wndproc :: (hwnd: HWND, message: u32, wparam: WPARAM, lparam: LPARAM) -> s64 #c_call {
        result: s64;
        if message != WM_NCCREATE {
            window := cast(*Windows_GL_Window) GetWindowLongPtrW(hwnd, GWLP_USERDATA);
            if window != null {
                push_context window.backend.wndproc_context.* {
                    handled := false;
                    if window.backend.message != null {
                        result, handled = window.backend.message(window.backend.message_data, window, hwnd, message, wparam, lparam);
                    }
                    if !handled if message == {
                        case WM_CLOSE;
                            window.running = false;
                        case WM_SYSCOMMAND;
                            if (wparam & 0xFFF0) != SC_KEYMENU || lparam != 0 {
                                result = DefWindowProcW(hwnd, message, wparam, lparam);
                            }
                        case WM_SETCURSOR;
                            HTCLIENT :: 1;
                            if (lparam & 0xFFFF) == HTCLIENT {
                                SetCursor(window.backend.cursors[window.mouse_state.cursor]);
                                result = 1;
                            } else {
                                result = DefWindowProcW(hwnd, message, wparam, lparam);
                            }
                        case WM_SIZE;
                            if wparam != SIZE_MINIMIZED {
                                window.width = cast(float64)(lparam & 0xFFFF);
                                window.height = cast(float64)((lparam >> 16) & 0xFFFF);
                                if window.backend.render != null {
                                    window.backend.render(window.backend.render_data);
                                }
                            }
                        case WM_MOVE;
                            if window.backend.render != null {
                                window.backend.render(window.backend.render_data);
                            }
                        case WM_ENTERMENULOOP; #through;
                        case WM_ENTERSIZEMOVE;
                            SetTimer(hwnd, MODAL_TAKEOVER_TIMER, 1, null);
                        case WM_EXITMENULOOP; #through;
                        case WM_EXITSIZEMOVE;
                            KillTimer(hwnd, MODAL_TAKEOVER_TIMER);
                        case WM_TIMER;
                            if wparam == MODAL_TAKEOVER_TIMER && window.backend.render {
                                window.backend.render(window.backend.render_data);
                            }
                        case WM_MOUSEMOVE;
                            if window.mouse_state.inside == false {
                                window.mouse_state.inside = true;
                                track := TRACKMOUSEEVENT.{
                                    cbSize = size_of(TRACKMOUSEEVENT),
                                    dwFlags = TME_LEAVE,
                                    hwndTrack = hwnd,
                                };
                                TrackMouseEvent(*track);
                            }
                            window.mouse_state.position = Vector2.{
                                cast(float) cast,trunc(s16) (lparam & 0xFFFF),
                                cast(float) cast,trunc(s16) ((lparam >> 16) & 0xFFFF),
                            } / cast(float) window.scale;
                        case WM_MOUSEWHEEL;
                            wheel := cast,trunc(s16) ((wparam >> 16) & 0xFFFF);
                            MK_SHIFT :: 0x0004;
                            if wparam & MK_SHIFT {
                                window.mouse_state.scroll_delta.x -= (cast(float)wheel) / 120.0 * SCROLL_MULTIPLIER;
                            } else {
                                window.mouse_state.scroll_delta.y -= (cast(float)wheel) / 120.0 * SCROLL_MULTIPLIER;
                            }
                        case WM_MOUSEHWHEEL;
                            wheel := cast,trunc(s16) ((wparam >> 16) & 0xFFFF);
                            window.mouse_state.scroll_delta.x += (cast(float)wheel) / 120.0 * SCROLL_MULTIPLIER;
                        case WM_MOUSELEAVE;
                            window.mouse_state.inside = false;
                        case WM_KILLFOCUS;
                            memset(window.keyboard_state.held.data, 0, size_of(type_of(window.keyboard_state.held)));
                        case WM_CAPTURECHANGED;
                            memset(window.mouse_state.held.data, 0, size_of(type_of(window.mouse_state.held)));
                        // TODO: handle double click events
                        case WM_LBUTTONDOWN; #through;
                        case WM_RBUTTONDOWN; #through;
                        case WM_MBUTTONDOWN; #through;
                        case WM_XBUTTONDOWN;
                            button: Mouse_Button = xx ((message - WM_LBUTTONDOWN) / 3);
                            if button == .BACK && ((wparam >> 16) & 0xFFFF) == 2 {
                                button = .FORWARD;
                            }
                            mouse_press(*window.mouse_state, button, Vector2.{
                                cast(float) cast,trunc(s16) (lparam & 0xFFFF),
                                cast(float) cast,trunc(s16) ((lparam >> 16) & 0xFFFF),
                            } / cast(float) window.scale);
                            SetCapture(hwnd);
                            if message == WM_XBUTTONDOWN {
                                result = 1;
                            }
                        case WM_LBUTTONUP; #through;
                        case WM_RBUTTONUP; #through;
                        case WM_MBUTTONUP; #through;
                        case WM_XBUTTONUP;
                            button: Mouse_Button = xx ((message - WM_LBUTTONUP) / 3);
                            if button == .BACK && ((wparam >> 16) & 0xFFFF) == 2 {
                                button = .FORWARD;
                            }
                            mouse_release(*window.mouse_state, button);
                            any_held := false;
                            for window.mouse_state.held {
                                if it {
                                    any_held = true;
                                    break;
                                }
                            }
                            if !any_held {
                                ReleaseCapture();
                            }
                            if message == WM_XBUTTONUP {
                                result = 1;
                            }
                        case WM_CHAR;
                            using window.keyboard_state;
                            unit := cast(u16) wparam;
                            code_point: u32;
                            if is_high_surrogate(unit) {
                                high_surrogate = unit;
                            } else if is_low_surrogate(unit) {
                                if is_high_surrogate(high_surrogate) {
                                    code_point = utf16_to_code_point(u16.[high_surrogate, unit], 2);
                                }
                                high_surrogate = 0;
                            } else {
                                code_point = unit;
                            }
                            if code_point != 0 {
                                bytes: [4]u8;
                                utf8 := string.{ data = bytes.data };
                                character_utf32_to_utf8(code_point, *utf8);
                                append_text(utf8, *window.text, window.text_buffer);
                            }
                        case WM_SYSCHAR;
                            // text typed while Alt is held
                            if wparam == #char " " {
                                result = DefWindowProcW(hwnd, message, wparam, lparam);
                            }
                        case WM_SYSKEYDOWN; #through;
                        case WM_KEYDOWN;
                            using window.keyboard_state;
                            if wparam != VK_PROCESSKEY && wparam != VK_PACKET { // ignores keys typed during an IME compose event
                                repeated := (lparam >> 30) & 1;
                                scancode := cast(u32) ((lparam >> 16) & 0xFF);
                                extended := (lparam >> 24) & 1;
                                index    := scancode | (extended << 8);
                                altgr_control := false;
                                if wparam == VK_CONTROL && extended == 0 {
                                    next: MSG;
                                    altgr_control = PeekMessageW(*next, null, 0, 0, PM_NOREMOVE) != 0 &&
                                        (next.message == WM_KEYDOWN || next.message == WM_SYSKEYDOWN) &&
                                        next.wParam == VK_MENU &&
                                        ((next.lParam >> 24) & 1) == 1 &&
                                        next.time == GetMessageTime();
                                }
                                if altgr_control {
                                } else if repeated && held[index] != 0 {
                                    add_key_event(*events, Key_Event.{ .REPEATED, held[index] });
                                } else {
                                    key: Key = 0;
                                    if wparam == {
                                        case VK_ESCAPE;  key = .ESCAPE;
                                        case VK_RETURN;  key = .ENTER;
                                        case VK_TAB;     key = .TAB;
                                        case VK_BACK;    key = .BACKSPACE;
                                        case VK_DELETE;  key = .DELETE;
                                        case VK_INSERT;  key = .INSERT;
                                        case VK_LEFT;    key = .ARROW_LEFT;
                                        case VK_RIGHT;   key = .ARROW_RIGHT;
                                        case VK_UP;      key = .ARROW_UP;
                                        case VK_DOWN;    key = .ARROW_DOWN;
                                        case VK_HOME;    key = .HOME;
                                        case VK_END;     key = .END;
                                        case VK_PRIOR;   key = .PAGE_UP;
                                        case VK_NEXT;    key = .PAGE_DOWN;
                                        case VK_F1;      key = .F1;
                                        case VK_F2;      key = .F2;
                                        case VK_F3;      key = .F3;
                                        case VK_F4;      key = .F4;
                                        case VK_F5;      key = .F5;
                                        case VK_F6;      key = .F6;
                                        case VK_F7;      key = .F7;
                                        case VK_F8;      key = .F8;
                                        case VK_F9;      key = .F9;
                                        case VK_F10;     key = .F10;
                                        case VK_F11;     key = .F11;
                                        case VK_F12;     key = .F12;
                                        case VK_SHIFT;   #through;
                                        case VK_CONTROL; #through;
                                        case VK_MENU;
                                            vk := MapVirtualKeyW(scancode | cast(u32) (ifx extended then 0xE000 else 0), MAPVK_VSC_TO_VK_EX);
                                            if vk == {
                                                case VK_LSHIFT;   key = .SHIFT_LEFT;
                                                case VK_RSHIFT;   key = .SHIFT_RIGHT;
                                                case VK_LCONTROL; key = .CONTROL_LEFT;
                                                case VK_RCONTROL; key = .CONTROL_RIGHT;
                                                case VK_LMENU;    key = .ALT_LEFT;
                                                case VK_RMENU;    key = .ALT_RIGHT;
                                            }
                                        case VK_LWIN;    key = .SUPER_LEFT;
                                        case VK_RWIN;    key = .SUPER_RIGHT;
                                        case VK_CAPITAL; key = .CAPS_LOCK;
                                        case;
                                            // the key could not be found, meaning it's not in the named ones, so we're going to write it as a character instead
                                            key = key_from_virtual_key(xx wparam, scancode);
                                    }
                                    if key != 0 {
                                        held[index] = key;
                                        add_key_event(*events, Key_Event.{ .PRESSED, key });
                                    }
                                    if wparam == VK_SHIFT || wparam == VK_CONTROL || wparam == VK_MENU || wparam == VK_CAPITAL {
                                        update_held_keys_by_modifiers(window.backend, *window.keyboard_state);
                                    }
                                }
                            }
                            if message == WM_SYSKEYDOWN {
                                result = DefWindowProcW(hwnd, message, wparam, lparam);
                            }
                        case WM_DPICHANGED;
                            window.scale = cast(float64) (wparam & 0xFFFF) / 96.0;
                            suggested := cast(*RECT) lparam;
                            SetWindowPos(hwnd, null, suggested.left, suggested.top,
                                suggested.right - suggested.left, suggested.bottom - suggested.top,
                                SWP_NOZORDER | SWP_NOACTIVATE);
                        case WM_KEYUP; #through;
                        case WM_SYSKEYUP;
                            using window.keyboard_state;
                            scancode := cast(u32) ((lparam >> 16) & 0xFF);
                            extended := cast(u32) ((lparam >> 24) & 1);
                            index := scancode | (extended << 8);
                            key := held[index];
                            if key != 0 {
                                add_key_event(*events, .{.RELEASED, key});
                                held[index] = 0;
                            }
                            if wparam == VK_SHIFT || wparam == VK_CONTROL || wparam == VK_MENU || wparam == VK_CAPITAL {
                                update_held_keys_by_modifiers(window.backend, *window.keyboard_state);
                            }
                            if message == WM_SYSKEYUP {
                                result = DefWindowProcW(hwnd, message, wparam, lparam);
                            }
                        case;
                            result = DefWindowProcW(hwnd, message, wparam, lparam);
                    }
                }
            } else {
                result = DefWindowProcW(hwnd, message, wparam, lparam);
            }
        } else {
            // lpCreateParams is the first field of CREATESTRUCTW
            create_params := (cast(**void) lparam).*;
            SetWindowLongPtrW(hwnd, GWLP_USERDATA, xx create_params);
            result = DefWindowProcW(hwnd, message, wparam, lparam);
        }
        return result;
    }
    update_backend :: (backend: *Backend) {
        backend.wndproc_context = *context;
        window := context.forbear.window;
        while true {
            message: MSG;
            while PeekMessageW(*message, null, 0, 0, PM_REMOVE) {
                TranslateMessage(*message);
                DispatchMessageW(*message);
            }
            if !window.running || !IsIconic(window.hwnd) {
                break;
            }
            WaitMessage();
        }

        sequence := GetClipboardSequenceNumber();
        if sequence != backend.clipboard_sequence && OpenClipboard(window.hwnd) {
            defer CloseClipboard();
            backend.clipboard_sequence = sequence;
            backend.clipboard_text.count = 0;

            handle := GetClipboardData(CF_UNICODETEXT);
            wide := cast(*u16) GlobalLock(handle);
            if wide {
                defer GlobalUnlock(handle);
                // with -1, the count includes the null terminator
                count := WideCharToMultiByte(CP_UTF8, 0, wide, -1, null, 0, null, null);
                if count + 1 > backend.clipboard_text_buffer.count {
                    backend.clipboard_text_buffer.data = realloc(backend.clipboard_text_buffer.data, count, backend.clipboard_text_buffer.count,, context.forbear.persistent_allocator);
                    backend.clipboard_text_buffer.count = count;
                }
                WideCharToMultiByte(CP_UTF8, 0, wide, -1, backend.clipboard_text_buffer.data, count, null, null);
                backend.clipboard_text = .{ count, backend.clipboard_text_buffer.data };
            }
        }
    }

    Windows_GL_Window :: struct {
        hwnd: HWND;
        hdc: HDC;
        backend: *Windows_GL_Backend;

        width: float64;
        height: float64;
        scale: float64;

        text_buffer: [256]u8;
        text: string;

        keyboard_state: Keyboard_State;
        mouse_state: Mouse_State;

        running := true;
    };
    init_window :: (backend: *Windows_GL_Backend,
                    window:  *Windows_GL_Window,
                    width:   float64,
                    height:  float64,
                    title:   string,
                    show_window := true) {
        window.text.data = window.text_buffer.data;
        window.backend = backend;
        init_keyboard_state(*window.keyboard_state);

        style :: WS_OVERLAPPEDWINDOW;
        window.hwnd = CreateWindowExW(
            0,
            utf8_to_wide("forbear",, temp),
            utf8_to_wide(title,, temp),
            style,
            CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
            null, null, GetModuleHandleW(null), window
        );

        dpi := GetDpiForWindow(window.hwnd);
        window.scale = dpi / 96.0;
        rectangle := RECT.{ right = xx (width * window.scale), bottom = xx (height * window.scale) };
        AdjustWindowRectExForDpi(*rectangle, style, 0, 0, dpi);
        SetWindowPos(window.hwnd, null, 0, 0, rectangle.right - rectangle.left, rectangle.bottom - rectangle.top, SWP_NOMOVE | SWP_NOZORDER);
        if show_window {
            ShowWindow(window.hwnd, SW_SHOW);
        }

        _, window.hdc = wgl_create_context(window.hwnd, null, 3, 3);
        gl_load(*gl);
        if gl.wglSwapIntervalEXT {
            gl.wglSwapIntervalEXT(1);
        }

        client: RECT;
        GetClientRect(window.hwnd, *client);
        window.width = xx client.right;
        window.height = xx client.bottom;
    }

    Backend :: Windows_GL_Backend;
    Window :: Windows_GL_Window;
} else #if OS == .MACOS {
    #load "bindings-darwin.jai";
    #import "Objective_C";
    #import "Objective_C/AppKit";
    #import "Process";
    #import "File";
    #import "File_Utilities";

    MacOS_GL_Window :: struct {
        width: float64;
        height: float64;
        scale: float64;

        ns_window: *NSWindow;
        view: *NSView;

        text_buffer: [256]u8;
        text: string;

        keyboard_state: Keyboard_State;
        mouse_state: Mouse_State;

        running := true;
    };
    init_window :: (backend: *MacOS_GL_Backend,
                    window:  *MacOS_GL_Window,
                    width:   float64,
                    height:  float64,
                    title:   string) {
        rectangle := NSRect.{ size = .{ width = width, height = height } };

        backend.pasteboard = NSPasteboard.generalPasteboard();
        window.ns_window = NSWindow.initWithContentRect(
            objc_alloc(NSWindow),
            rectangle,
            NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable,
            NSBackingStoreBuffered,
            NO,
            NSScreen.mainScreen()
        );
        NSWindow.setReleasedWhenClosed(window.ns_window, NO);
        NSWindow.setTitle(window.ns_window, title);
        NSWindow.center(window.ns_window);
        NSWindow.makeKeyAndOrderFront(window.ns_window, null);

        window.view = NSWindow.contentView(window.ns_window);
        NSView.setWantsBestResolutionOpenGLSurface(window.view, YES);
        NSOpenGLContext.setView(backend.gl_context, window.view);
        backend.attached_view = window.view;

        frame := NSView.frame(window.view);
        backing := NSView.convertRectToBacking(window.view, frame);
        window.width = backing.size.width;
        window.height = backing.size.height;
        window.scale = backing.size.width / frame.size.width;

        window.text.data = window.text_buffer.data;

        init_keyboard_state(*window.keyboard_state);
    }
    update_window :: (backend: *MacOS_GL_Backend, window: *MacOS_GL_Window) {
        is_visible: (*void, Selector) -> BOOL #c_call = xx objc_msgSend;
        // TODO: this isVisible is not the right way to do it, this also becomes true when
        // the program is minimized so the program just stops then which is a bug.
        if !is_visible(window.ns_window, selector("isVisible")) {
            window.running = false;
        }

        frame := NSView.frame(window.view);
        backing := NSView.convertRectToBacking(window.view, frame);
        if backing.size.width != window.width || backing.size.height != window.height {
            window.width = backing.size.width;
            window.height = backing.size.height;
            window.scale = backing.size.width / frame.size.width;
            NSOpenGLContext.update(backend.gl_context);
        }
        if NSApplication.keyWindow(backend.app) != window.ns_window {
            memset(window.keyboard_state.held.data, 0, size_of(type_of(window.keyboard_state.held)));
        }
    }

    MacOS_GL_Backend :: struct {
        render: (data: *void);
        render_data: *void;

        cursors: [CURSOR_COUNT]*NSCursor;

        app: *NSApplication;
        pixel_format: *NSOpenGLPixelFormat;
        gl_context: *NSOpenGLContext;

        pasteboard: *NSPasteboard;
        clipboard_change_count: NSInteger = -1;
        clipboard_text_buffer: string;
        clipboard_text: string;

        attached_view: *NSView;
    };
    init_backend :: (backend: *MacOS_GL_Backend) {
        init_objective_c();
        init_app_kit();
        using backend;

        cursors[Cursor.DEFAULT]     = NSCursor.arrowCursor();
        cursors[Cursor.TEXT]        = NSCursor.IBeamCursor();
        cursors[Cursor.POINTER]     = NSCursor.pointingHandCursor();
        cursors[Cursor.NOT_ALLOWED] = NSCursor.operationNotAllowedCursor();
        cursors[Cursor.MOVE]        = NSCursor.openHandCursor();
        cursors[Cursor.EW_RESIZE]   = NSCursor.resizeLeftRightCursor();
        cursors[Cursor.NS_RESIZE]   = NSCursor.resizeUpDownCursor();

        get: (*void, Selector) -> *NSCursor #c_call = xx objc_msgSend;
        cursors[Cursor.CROSSHAIR]                   = get(xx class(NSCursor), selector("crosshairCursor"));

        cursors[Cursor.WAIT]     = cursors[Cursor.DEFAULT];
        cursors[Cursor.PROGRESS] = cursors[Cursor.DEFAULT];
        cursors[Cursor.HELP]     = cursors[Cursor.DEFAULT];
        responds: (*void, Selector, Selector) -> BOOL #c_call = xx objc_msgSend;
        if responds(xx class(NSCursor), selector("respondsToSelector:"), selector("busyButClickableCursor")) {
            cursors[Cursor.WAIT]     = get(xx class(NSCursor), selector("busyButClickableCursor"));
            cursors[Cursor.PROGRESS] = cursors[Cursor.WAIT];
        }
        if responds(xx class(NSCursor), selector("respondsToSelector:"), selector("_helpCursor")) {
            cursors[Cursor.HELP] = get(xx class(NSCursor), selector("_helpCursor"));
        }

        frame_resize: (*void, Selector, NSUInteger, NSUInteger) -> *NSCursor #c_call = xx objc_msgSend;
        sel                                                                         := selector("frameResizeCursorFromPosition:inDirections:");
        cursors[Cursor.NWSE_RESIZE]                                                  = frame_resize(xx class(NSCursor), sel, 1 | 2, 3);
        cursors[Cursor.NESW_RESIZE]                                                  = frame_resize(xx class(NSCursor), sel, 1 | 8, 3);

        app = NSApplication.sharedApplication();
        NSApplication.setActivationPolicy(app, NSApplicationActivationPolicyRegular);
        NSApplication.finishLaunching(app);
        NSApplication.activateIgnoringOtherApps(app, YES);

        attributes := NSOpenGLPixelFormatAttribute.[
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFAAccelerated,
            NSOpenGLPFAColorSize, 24,
            NSOpenGLPFAAlphaSize, 8,
            NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion4_1Core,
            0,
        ];
        pixel_format = NSOpenGLPixelFormat.initWithAttributes(objc_alloc(NSOpenGLPixelFormat), attributes.data);
        gl_context = NSOpenGLContext.initWithFormat(objc_alloc(NSOpenGLContext), pixel_format, null);
        NSOpenGLContext.makeCurrentContext(gl_context);
        gl_load(*gl);
    }
    update_backend :: (backend: *MacOS_GL_Backend) {
        pool := objc_init(objc_alloc(NSAutoreleasePool));
        defer NSAutoreleasePool.drain(pool);

        window := context.forbear.window;
        using window.keyboard_state;

        frame := NSView.frame(window.view);
        location := NSWindow.mouseLocationOutsideOfEventStream(window.ns_window);

        window.mouse_state.inside = location.x >= 0 && location.y >= 0 &&
                                    location.x < frame.size.width && location.y < frame.size.height;
        window.mouse_state.position = Vector2.{ xx location.x, xx (frame.size.height - location.y) };

        change_count: (*void, Selector) -> NSInteger #c_call = xx objc_msgSend;
        count := change_count(backend.pasteboard, selector("changeCount"));
        if count != backend.clipboard_change_count {
            backend.clipboard_text.count = 0;
            backend.clipboard_change_count = count;
            nsstring := backend.pasteboard.stringForType(backend.pasteboard, NSPasteboardTypeString);
            if nsstring != null {
                utf8 := to_string(NSString.UTF8String(nsstring));
                if utf8.count > backend.clipboard_text_buffer.count {
                    backend.clipboard_text_buffer.data = realloc(
                        backend.clipboard_text_buffer.data,
                        utf8.count,
                        backend.clipboard_text_buffer.count,,
                        context.forbear.persistent_allocator
                    );
                    backend.clipboard_text_buffer.count = utf8.count;
                }
                memcpy(backend.clipboard_text_buffer.data, utf8.data, utf8.count);

                backend.clipboard_text.data = backend.clipboard_text_buffer.data;
                backend.clipboard_text.count = utf8.count;
            }
        }

        while true {
            event := NSApplication.nextEventMatchingMask(backend.app, NSEventMaskAny, NSDate.distantPast(), NSDefaultRunLoopMode, YES);
            if event {
                event_type := NSEvent.type(event);
                if event_type == {
                    case NSEventTypeRightMouseDown; #through;
                    case NSEventTypeLeftMouseDown; #through;
                    case NSEventTypeOtherMouseDown;
                        button := NSEvent.buttonNumber(event);
                        if window.mouse_state.inside {
                            if button < MOUSE_BUTTON_COUNT {
                                mouse_press(*window.mouse_state, xx button, window.mouse_state.position);
                            } else {
                                log_error("received a button that's bigger than what we expected to receive. in theory this can go to 31 button, but we only have LEFT, RIGHT, MIDDLE, BACK and FORWARD. button: %", button);
                            }
                        }
                        backend.app.sendEvent(backend.app, event);
                    case NSEventTypeLeftMouseUp; #through;
                    case NSEventTypeRightMouseUp; #through;
                    case NSEventTypeOtherMouseUp;
                        button := NSEvent.buttonNumber(event);
                        if button < MOUSE_BUTTON_COUNT {
                            mouse_release(*window.mouse_state, xx button);
                        } else {
                            log_error("received a button that's bigger than what we expected to receive. in theory this can go to 31 button, but we only have LEFT, RIGHT, MIDDLE, BACK and FORWARD. button: %", button);
                        }
                        backend.app.sendEvent(backend.app, event);
                    case NSEventTypeScrollWheel;
                        scrolling_delta: (*NSEvent, Selector) -> float64 #c_call = xx objc_msgSend;
                        has_precise:     (*NSEvent, Selector) -> BOOL #c_call    = xx objc_msgSend;

                        dy := cast(float) scrolling_delta(event, selector("scrollingDeltaX"));
                        dx := cast(float) scrolling_delta(event, selector("scrollingDeltaY"));
                        if !has_precise(event, selector("hasPreciseScrollingDeltas")) {
                            dy *= SCROLL_MULTIPLIER;
                        }
                        window.mouse_state.scroll_delta.y -= dy;
                        window.mouse_state.scroll_delta.x -= dx;
                        backend.app.sendEvent(backend.app, event);
                    case NSEventTypeKeyDown;
                        code := NSEvent.keyCode(event);
                        if NSEvent.isARepeat(event) && held[code] != 0 {
                            add_key_event(*events, Key_Event.{.REPEATED, held[code]});
                        } else {
                            key := key_from_key_code(code);
                            if key != 0 {
                                add_key_event(*events, Key_Event.{.PRESSED, key});
                                held[code] = key;
                            }
                        }
                        if !(NSEvent.modifierFlags(event) & .NSEventModifierFlagCommand) {
                            characters := NSEvent.characters(event);
                            if characters {
                                text := to_string(NSString.UTF8String(characters));
                                // TODO(bug): this is currently accepting the text version of stuff like CTRL, which doensn't make any sense.
                                // We should be using NSTextInputClient instead.
                                if text.count != 3 || text[0] == 0xEF && text[1] >= 0x9C && text[1] <= 0xA3 {
                                    append_text(text, *window.text, window.text_buffer);
                                }
                            }
                        }
                    case NSEventTypeKeyUp;
                        code := NSEvent.keyCode(event);
                        key := held[code];
                        if key != 0 {
                            add_key_event(*events, Key_Event.{.RELEASED, held[code]});
                            held[code] = 0;
                        }
                    case NSEventTypeFlagsChanged;
                        code := NSEvent.keyCode(event);
                        key := key_from_key_code(code);
                        if key != 0 {
                            flags := cast(u64) NSEvent.modifierFlags(event);
                            down: bool;
                            if key == {
                                case .CAPS_LOCK;     down = (flags & cast(u64) NSEventModifierFlags.NSEventModifierFlagCapsLock) != 0;
                                case .CONTROL_LEFT;  down = (flags & 0x00000001) != 0;
                                case .SHIFT_LEFT;    down = (flags & 0x00000002) != 0;
                                case .SHIFT_RIGHT;   down = (flags & 0x00000004) != 0;
                                case .SUPER_LEFT;    down = (flags & 0x00000008) != 0;
                                case .SUPER_RIGHT;   down = (flags & 0x00000010) != 0;
                                case .ALT_LEFT;      down = (flags & 0x00000020) != 0;
                                case .ALT_RIGHT;     down = (flags & 0x00000040) != 0;
                                case .CONTROL_RIGHT; down = (flags & 0x00002000) != 0;
                            }

                            if down && held[code] == 0 {
                                add_key_event(*events, Key_Event.{.PRESSED, key});
                                held[code] = key;
                            } else if !down && held[code] != 0 {
                                add_key_event(*events, Key_Event.{.RELEASED, key});
                                held[code] = 0;
                            }
                        }
                        update_held_keys_by_modifiers(backend, *window.keyboard_state);
                        backend.app.sendEvent(backend.app, event);
                    case;
                        backend.app.sendEvent(backend.app, event);
                }
            } else {
                break;
            }
        }
    }

    Backend :: MacOS_GL_Backend;
    Window :: MacOS_GL_Window;

    create_application :: (name: string, executable: string) {
        app := tprint("%/%.app", get_working_directory(), name);
        make_directory_if_it_does_not_exist(tprint("%/Contents/MacOS", app), recursive = true);
        bundled := tprint("%/Contents/MacOS/%", app, name);
        copy_file(executable, bundled);
        chmod(temp_c_string(bundled), 0x1ED);
        write_entire_file(
            tprint("%/Contents/Info.plist", app),
            tprint(#string PLIST
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0">
                <dict>
                <key>CFBundleExecutable</key><string>%1</string>
                <key>CFBundleIdentifier</key><string>com.forbear.%1</string>
                <key>CFBundleName</key><string>%1</string>
                <key>CFBundlePackageType</key><string>APPL</string>
                <key>NSHighResolutionCapable</key><true/>
                </dict>
                </plist>
                PLIST,
            name)
        );
        run_command("codesign", "--force", "--deep", "-s", "-", app);
    }
} else #if OS == .LINUX {
    #load "bindings-linux.jai";

    #scope_module
    WAYLAND_DEBUGGING   :: false;
    EGL_DEBUGGING       :: false;
    EXIT_ON_FIRST_FRAME :: false;

    GL_FRAMEBUFFER_FLIP_Y_MESA :: 35771;

    CURSOR_SHAPES :: Wp_Cursor_Shape_Device_V1_Shape.[
        .DEFAULT, .TEXT, .POINTER, .WAIT, .PROGRESS, .CROSSHAIR, .HELP,
        .NOT_ALLOWED, .MOVE, .EW_RESIZE, .NS_RESIZE, .NWSE_RESIZE, .NESW_RESIZE,
    ];

    Wayland_Message_header :: struct {
        object_id: u32;
        opcode:    u16;
        size:      u16;
    } #no_padding;
    MAX_WAYLAND_MESSAGE_SIZE :: 4096;
    #scope_export
    Wayland_Connection :: struct {
        fd:         s32;
        polling_fd: pollfd;

        wl_compositor_id:               u32;
        wl_data_device_id:              u32;
        wl_data_device_manager_id:      u32;
        wl_display_id:                  u32;
        wl_keyboard_id:                 u32;
        wl_pointer_id:                  u32;
        wl_registry_id:                 u32;
        wl_seat_id:                     u32;
        wp_cursor_shape_device_id:      u32;
        wp_cursor_shape_manager_id:     u32;
        wp_fractional_scale_manager_id: u32;
        wp_viewporter_id:               u32;
        xdg_wm_base_id:                 u32;
        zwp_dmabuf_id:                  u32;

        //
        // TODO(depessimization): I do not like that xkb allocates the structs and also does reference counting with
        // them which is quite bad.
        //
        // In the long-term, we should write our own implementation, but Wayland is already
        // taking a lot of the code here which is unfortunate because Wayland is actually most likely not going to
        // include most users.
        //

        xkb:           *xkb_context;
        keymap:        *xkb_keymap;
        key_state:     *xkb_state;
        compose_table: *xkb_compose_table;
        compose_state: *xkb_compose_state;

        reading_buffer:     [MAX_WAYLAND_MESSAGE_SIZE]u8;
        pending_reads:      []u8;
        reading_fds_buffer: [8]s32;
        pending_read_fds:   []s32;

        client_object_interfaces:         [..]Interface_Id;
        free_client_object_interface_ids: [..]s64;
        server_object_interfaces:         [..]Interface_Id;
    };
    sockaddr_un :: struct {
        sun_family: sa_family_t;
        sun_path:   [100]u8;
    };
    init_wayland_connection :: (connection: *Wayland_Connection) {
        connection.fd = socket(AF_UNIX, SOCK.STREAM, 0);
        connection.polling_fd = pollfd.{ fd = connection.fd, events = POLLIN };

        runtime_directory := to_string(getenv("XDG_RUNTIME_DIR"));
        wayland_display := to_string(getenv("WAYLAND_DISPLAY"));
        if trim(wayland_display).count == 0 {
            log_error("$WAYLAND_DISPLAY is not defined, using wayland-0");
            wayland_display = "wayland-0";
        }
        path := tprint("%/%", runtime_directory, wayland_display);

        address: sockaddr_un;
        address.sun_family = AF_UNIX;
        memcpy(cast(*void) address.sun_path.data, cast(*void) path.data, path.count);
        address.sun_path[path.count] = 0;

        if connect(connection.fd, cast(*sockaddr) *address, size_of(sockaddr_un)) != 0 {
            // I once got an errno 2 here and the WAYLAND_DISPLAY env undefined when I started a tmux session in x11 and then
            // reattached to it from Wayland. In that case I was able to fix by setting the env in the rnuning tmux session
            //
            // tmux set-environment -t [SESSION_NAME] WAYLAND_DISPLAY "$WAYLAND_DISPLAY"
            // tmux set-environment -t [SESSION_NAME] XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR"
            //
            log_error("connection failed: %\n", errno());
            exit(-1);
        }
        if WAYLAND_DEBUGGING {
            print("connected to %\n", path);
        }

        connection.wl_display_id = new_wayland_client_object(connection, Interface_Id.WL_DISPLAY);
        connection.wl_registry_id = new_wayland_client_object(connection, Interface_Id.WL_REGISTRY);

        connection.xkb = xkb_context_new(xkb_context_flags.XKB_CONTEXT_NO_FLAGS);

        locale := getenv("LC_ALL");
        if !locale || !locale[0] {
            locale = getenv("LC_CTYPE");
        }
        if !locale || !locale[0] {
            locale = getenv("LANG");
        }
        if !locale || !locale[0] {
            locale = "C".data;
        }
        connection.compose_table = xkb_compose_table_new_from_locale(connection.xkb, locale, .XKB_COMPOSE_COMPILE_NO_FLAGS);
        if connection.compose_table {
            connection.compose_state = xkb_compose_state_new(connection.compose_table, .XKB_COMPOSE_STATE_NO_FLAGS);
        } else {
            log_error("no compose table for locale %, dead keys and compose sequences will not work", to_string(locale));
        }

        send_wayland_message(connection, 1, Wl_Display_Request_Get_Registry.{ registry = connection.wl_registry_id });
        sync_id := new_wayland_client_object(connection, .WL_CALLBACK);
        send_wayland_message(connection, connection.wl_display_id, Wl_Display_Request_Sync.{ callback = sync_id });
        synced := false;
        while !synced {
            event := next_event(connection);
            if !event.something {
                poll(connection);
                continue;
            }

            update_wayland_connection(connection, event);
            if event.message.type == {
                case Wl_Registry_Event_Global;
                    bind_global :: (connection: *Wayland_Connection, interface_id: Interface_Id, global: Wl_Registry_Event_Global, version := U32_MAX) -> u32 {
                        id := new_wayland_client_object(connection, interface_id);
                        send_wayland_message(connection, connection.wl_registry_id, Wl_Registry_Request_Bind.{
                            name = global.name,
                            interface_name = global.interface_name,
                            version = ifx version == U32_MAX then
                                min(INTERFACES[interface_id].version, global.version)
                            else
                                min(version, global.version),
                            id = id,
                        });
                        return id;
                    }

                    global := cast(*Wl_Registry_Event_Global) event.data;
                    if global.interface_name == "wl_compositor" {
                        connection.wl_compositor_id = bind_global(connection, Interface_Id.WL_COMPOSITOR, global);
                    } else if global.interface_name == "xdg_wm_base" {
                        connection.xdg_wm_base_id = bind_global(connection, Interface_Id.XDG_WM_BASE, global);
                    } else if global.interface_name == "zwp_linux_dmabuf_v1" {
                        // version 3 of this makes it easier for us to get the buffer types back
                        connection.zwp_dmabuf_id = bind_global(connection, Interface_Id.ZWP_LINUX_DMABUF_V1, global, 3);
                    } else if global.interface_name == "wl_seat" {
                        connection.wl_seat_id = bind_global(connection, Interface_Id.WL_SEAT, global);
                    } else if global.interface_name == "wp_viewporter" {
                        connection.wp_viewporter_id = bind_global(connection, Interface_Id.WP_VIEWPORTER, global);
                    } else if global.interface_name == "wp_fractional_scale_manager_v1" {
                        connection.wp_fractional_scale_manager_id = bind_global(connection, Interface_Id.WP_FRACTIONAL_SCALE_MANAGER_V1, global);
                    } else if global.interface_name == "wp_cursor_shape_manager_v1" {
                        connection.wp_cursor_shape_manager_id = bind_global(connection, Interface_Id.WP_CURSOR_SHAPE_MANAGER_V1, global);
                    } else if global.interface_name == "wl_data_device_manager" {
                        connection.wl_data_device_manager_id = bind_global(connection, Interface_Id.WL_DATA_DEVICE_MANAGER, global);
                    }
                case Wl_Callback_Event_Done;
                    synced = true;
            }

            reset_temporary_storage();
        }
        assert(connection.wl_compositor_id != 0, "expected wl_compositor to have been bound");
        assert(connection.xdg_wm_base_id != 0, "expected xdg_wm_base to have been bound");
        assert(connection.zwp_dmabuf_id != 0, "expected zwp_dmabuf to have been bound");
        if connection.wl_data_device_manager_id != 0 && connection.wl_seat_id != 0 {
            connection.wl_data_device_id = new_wayland_client_object(connection, .WL_DATA_DEVICE);
            send_wayland_message(
                connection,
                connection.wl_data_device_manager_id,
                Wl_Data_Device_Manager_Request_Get_Data_Device.{
                    id   = connection.wl_data_device_id,
                    seat = connection.wl_seat_id
                }
            );
        }
    }
    update_wayland_connection :: (connection: *Wayland_Connection, event: Wayland_Event) {
        if event.object_id == connection.wl_display_id {
            if event.message.type == {
                case Wl_Display_Event_Delete_Id;
                    delete := cast(*Wl_Display_Event_Delete_Id) event.data;
                    array_add(*connection.free_client_object_interface_ids, delete.id);
                case Wl_Display_Event_Error;
                    error := cast(*Wl_Display_Event_Error) event.data;
                    log_error(
                        "protocol error on object % (%): code %, %",
                        error.object_id,
                        connection.client_object_interfaces[error.object_id - 1],
                        error.code,
                        error.message
                    );
                    exit(-1);
            }
        } else if event.object_id == connection.xdg_wm_base_id && event.message.type == Xdg_Wm_Base_Event_Ping {
            ping := cast(*Xdg_Wm_Base_Event_Ping) event.data;
            send_wayland_message(connection, connection.xdg_wm_base_id, Xdg_Wm_Base_Request_Pong.{ping.serial});
        } else if event.object_id == connection.wl_seat_id && event.message.type == Wl_Seat_Event_Capabilities {
            capabilities := cast(*Wl_Seat_Event_Capabilities) event.data;
            if (capabilities.capabilities & .POINTER) && connection.wl_pointer_id == 0 {
                connection.wl_pointer_id = new_wayland_client_object(connection, .WL_POINTER);
                send_wayland_message(connection, connection.wl_seat_id, Wl_Seat_Request_Get_Pointer.{ id = connection.wl_pointer_id });

                connection.wp_cursor_shape_device_id = new_wayland_client_object(connection, .WP_CURSOR_SHAPE_DEVICE_V1);
                send_wayland_message(
                    connection,
                    connection.wp_cursor_shape_manager_id,
                    Wp_Cursor_Shape_Manager_V1_Request_Get_Pointer.{
                        cursor_shape_device = connection.wp_cursor_shape_device_id,
                        pointer             = connection.wl_pointer_id
                    }
                );
            }
            if (capabilities.capabilities & .KEYBOARD) && connection.wl_keyboard_id == 0 {
                connection.wl_keyboard_id = new_wayland_client_object(connection, .WL_KEYBOARD);
                send_wayland_message(connection, connection.wl_seat_id, Wl_Seat_Request_Get_Keyboard.{ id = connection.wl_keyboard_id });
            }
        } else if event.object_id == connection.wl_keyboard_id {
            if event.message.type == {
                case Wl_Keyboard_Event_Keymap;
                    keymap := cast(*Wl_Keyboard_Event_Keymap) event.data;
                    defer close(cast(s32) keymap.fd);
                    assert(keymap.format == .XKB_V1, "unsupported keymap format");
                    memory := mmap(null, keymap.size, PROT_READ, MAP_PRIVATE, cast(s32) keymap.fd, 0);
                    defer munmap(memory, keymap.size);
                    assert(memory != MAP_FAILED, "could not map the keymap");
                    if connection.key_state {
                        xkb_state_unref(connection.key_state);
                    }
                    if connection.keymap {
                        xkb_keymap_unref(connection.keymap);
                    }
                    connection.keymap = xkb_keymap_new_from_string(
                        connection.xkb,
                        memory,
                        .XKB_KEYMAP_FORMAT_TEXT_V1,
                        .XKB_KEYMAP_COMPILE_NO_FLAGS
                    );
                    connection.key_state = xkb_state_new(connection.keymap);
                case Wl_Keyboard_Event_Modifiers;
                    modifiers := cast(*Wl_Keyboard_Event_Modifiers) event.data;
                    xkb_state_update_mask(
                        connection.key_state,
                        modifiers.mods_depressed,
                        modifiers.mods_latched,
                        modifiers.mods_locked,
                        0, 0, modifiers.group
                    );
            }
        }
    }
    poll :: (connection: *Wayland_Connection, timeout_ms: s32 = 1000) {
        polling_result := poll(*connection.polling_fd, 1, timeout_ms);
        if polling_result == {
            case 0;
                log_error("Timed out while waiting for the socket to have something readable");
                exit(-1);
            case -1;
                log_error("Failed to poll the compositor's socket: %", errno());
                exit(-1);
        }
    }

    track_wayland_server_object :: (connection: *Wayland_Connection, interface_id: Interface_Id, id: u32) {
        index := id - WAYLAND_SERVER_OBJECT_ID_CUTOFF;
        if connection.server_object_interfaces.count < index + 1 {
            array_resize(*connection.server_object_interfaces, index + 1);
        }
        connection.server_object_interfaces[index] = interface_id;
    }
    new_wayland_client_object :: (connection: *Wayland_Connection, interface_id: Interface_Id) -> u32 {
        if connection.free_client_object_interface_ids.count > 0 {
            // we reuse ids that have been deleted/freed
            id := pop(*connection.free_client_object_interface_ids);
            connection.client_object_interfaces[id - 1] = interface_id;

            return xx id;
        } else {
            array_add(*connection.client_object_interfaces, interface_id);
            return xx connection.client_object_interfaces.count;
        }
    }

    Wayland_Event :: struct {
        something: bool;
        message: Message_Info;
        data: *void;
        object_id: u32;
    };
    WAYLAND_SERVER_OBJECT_ID_CUTOFF :: 0xff000000;
    next_event :: (connection: *Wayland_Connection, wait := false) -> Wayland_Event {
        while connection.pending_reads.count < size_of(Wayland_Message_header) ||
        connection.pending_reads.count < (cast(*Wayland_Message_header) connection.pending_reads.data).size {
            leftover := connection.pending_reads.count;
            copy(connection.reading_buffer.data, connection.pending_reads.data, leftover);

            flags: MSG = .CMSG_CLOEXEC;
            if !wait {
                flags |= .DONTWAIT;
            }
            control: struct {
                using header: cmsghdr;
                fds: [8]s32;
            };
            iov := iovec.{
                iov_base = connection.reading_buffer.data + leftover,
                iov_len = xx (connection.reading_buffer.count - leftover)
            };
            message_header := msghdr.{
                msg_iov = *iov,
                msg_iovlen = 1,
                msg_control = *control,
                msg_controllen = size_of(type_of(control))
            };
            result := recvmsg(connection.fd, *message_header, flags);
            assert(!(message_header.msg_flags & xx MSG.CTRUNC), "control buffer too small, file descriptors were dropped");
            if result == 0 {
                log_error("compositor closed the connection");
                exit(-1);
            }
            if result == -1 {
                error_code := errno();
                if error_code == EINTR  {
                    continue;
                }
                if error_code == EAGAIN  {
                    return Wayland_Event.{};
                }
                log_error("failed to read back from socket: %\n", error_code);
                exit(-1);
            }
            if message_header.msg_controllen > 0 {
                assert(control.header.cmsg_level == SOL_SOCKET && control.header.cmsg_type == xx SCM.RIGHTS);

                new_fds_count := (cast(s64) control.header.cmsg_len - size_of(cmsghdr)) / size_of(s32);
                assert(connection.pending_read_fds.count + new_fds_count <= connection.reading_fds_buffer.count, "too many file descriptors pending");
                memcpy(*connection.reading_fds_buffer[connection.pending_read_fds.count], control.fds.data, new_fds_count * size_of(s32));
                connection.pending_read_fds.data = connection.reading_fds_buffer.data;
                connection.pending_read_fds.count += new_fds_count;
            }

            connection.pending_reads = array_view(connection.reading_buffer, 0, result + leftover);
        }

        incoming_message_header := cast(*Wayland_Message_header) connection.pending_reads.data;

        object_interface_id: Interface_Id;
        if incoming_message_header.object_id >= WAYLAND_SERVER_OBJECT_ID_CUTOFF {
            // means it's a server object id
            object_interface_id = connection.server_object_interfaces[incoming_message_header.object_id - WAYLAND_SERVER_OBJECT_ID_CUTOFF];
        } else {
            object_interface_id = connection.client_object_interfaces[incoming_message_header.object_id - 1];
        }
        message_info: Message_Info = MESSAGES[
            INTERFACES[object_interface_id].first_event + incoming_message_header.opcode
        ];

        incoming_message := array_view(connection.pending_reads, size_of(Wayland_Message_header), incoming_message_header.size - size_of(Wayland_Message_header));
        connection.pending_reads.data += incoming_message_header.size;
        connection.pending_reads.count -= incoming_message_header.size;

        data := parse_wayland_message(incoming_message, message_info, *connection.pending_read_fds);

        if WAYLAND_DEBUGGING {
            print("\n");
            print("message received\n");
            print("event.type %\n", message_info.type);
            print("object interface %\n", object_interface_id);
            print("\n");
        }

        return Wayland_Event.{
            message = message_info,
            data = data,
            something = true,
            object_id = incoming_message_header.object_id,
        };
    }
    // TODO(depessimization): we should be buffering the messages and flushing them instead of sending them all one by one
    writing_buffer: [MAX_WAYLAND_MESSAGE_SIZE]u8;
    send_wayland_message :: (connection: *Wayland_Connection, object_id: u32, message: $T) {
        bytes := array_view(writing_buffer, 0, size_of(Wayland_Message_header));

        m := message;
        message_type_info := type_info(T);

        add_bytes :: (bytes: *[]u8, source: *void, count: s64) {
            old := bytes.count;
            bytes.count = old + count;
            assert(bytes.count < MAX_WAYLAND_MESSAGE_SIZE);
            memcpy(bytes.data + old, source, count);
        }

        pad_to_four :: (bytes: *[]u8) {
            while bytes.count % 4 {
                bytes.count += 1;
                assert(bytes.count < MAX_WAYLAND_MESSAGE_SIZE);
            }
        }

        fd_to_send: s32 = -1;

        for T.ARGS {
            arg_member := message_type_info.members[it_index + 2];
            source := (cast(*u8) *m) + arg_member.offset_in_bytes;
            if it == {
                case .FILE_DESCRIPTOR;
                    fd_to_send = (cast(*s32) source).*;
                case .STRING;
                    value := (cast(*string) source).*;
                    length: u32 = xx (value.count + 1);
                    add_bytes(*bytes, *length, 4);
                    add_bytes(*bytes, value.data, value.count);
                    bytes.count += 1;
                    assert(bytes.count < MAX_WAYLAND_MESSAGE_SIZE);
                    bytes[bytes.count - 1] = 0;
                    pad_to_four(*bytes);
                case .ARRAY;
                    value := (cast(*[]u8) source).*;
                    count: u32 = xx value.count;
                    add_bytes(*bytes, *count, 4);
                    add_bytes(*bytes, value.data, value.count);
                    pad_to_four(*bytes);
                case;
                    add_bytes(*bytes, source, 4);
            }
        }

        header := cast(*Wayland_Message_header) bytes.data;
        header.object_id = object_id;
        header.opcode = T.OPCODE;
        header.size = xx bytes.count;

        if WAYLAND_DEBUGGING {
            print("\n");
            print("message sent\n");
            print("event %\n", T);
            print("\n");
        }

        iov := iovec.{ bytes.data, xx bytes.count };
        msg_header: msghdr;
        msg_header.msg_iov = *iov;
        msg_header.msg_iovlen = 1;

        control: [24] u8;
        if fd_to_send != -1 {
            cmsg := cast(*cmsghdr) control.data;
            cmsg.cmsg_len = 20;
            cmsg.cmsg_level = SOL_SOCKET;
            cmsg.cmsg_type = xx SCM.RIGHTS;
            (cast(*s32) (control.data + 16)).* = fd_to_send;
            msg_header.msg_control = control.data;
            msg_header.msg_controllen = control.count;
        }

        result := sendmsg(connection.fd, *msg_header, .NOSIGNAL);

        if result == -1 {
            error_code := errno();
            if error_code == EPIPE {
                log_error("compositor closed the connection, draining what it sent before closing:");
                while true {
                    next_event(connection);
                }
            }
            log_error("could not send wayland message: %\n", error_code);
            exit(-1);
        }
        memset(writing_buffer.data, 0, bytes.count);

        assert(result == bytes.count, "incomplete message was sent. something went wrong");
    }
    parsing_buffer : [MAX_MESSAGE_STRUCT_SIZE]u8;
    parse_wayland_message :: (bytes: []u8, message_info: Message_Info, fds: *[]s32) -> *void {
        args := array_view(ARGS, message_info.first_arg, message_info.arg_count);
        message_type_info := cast(*Type_Info_Struct) message_info.type;

        untyped_message_bytes := array_view(parsing_buffer, 0, message_type_info.runtime_size);

        remainder := bytes;
        for args {
            // + 1 because we want to igonre OPCODE and ARGS
            arg_member := message_type_info.members[it_index + 2];

            arg_type_info := cast(*Type_Info) arg_member.type;
            if it == {
                case ProtocolType.FILE_DESCRIPTOR;
                    assert(fds.count > 0, "a messaged named a file descriptor that never arrived");
                    fd := fds.*[0];
                    memcpy(*untyped_message_bytes[arg_member.offset_in_bytes], *fd, size_of(s32));
                    for 0..fds.count - 2 {
                        // move all fds one index down
                        fds.*[it] = fds.*[it + 1];
                    }
                    fds.count -= 1;
                case ProtocolType.STRING;
                    value: string;
                    // we subtract one because this is a C string, with a NULL terminator
                    value.count = xx (cast(*u32) remainder.data).* - 1;
                    remainder.data += 4;

                    value.data = remainder.data;
                    remainder.data += (value.count + 4) & ~3; // account for the padding to four, and the -1 we did before
                    memcpy(
                        cast(*void) *untyped_message_bytes[arg_member.offset_in_bytes],
                        cast(*void) *value,
                        arg_type_info.runtime_size
                    );
                case ProtocolType.ARRAY;
                    value: []u8;
                    value.count = xx (cast(*u32) remainder.data).*;
                    remainder.data += 4;

                    value.data = remainder.data;
                    remainder.data += (value.count + 3) & ~3;
                    memcpy(
                        cast(*void) *untyped_message_bytes[arg_member.offset_in_bytes],
                        cast(*void) *value,
                        arg_type_info.runtime_size
                    );
                case ProtocolType.INT; #through;
                case ProtocolType.FIXED; #through;
                case ProtocolType.OBJECT; #through;
                case ProtocolType.NEW_ID; #through;
                case ProtocolType.UINT;
                    memcpy(
                        cast(*void) *untyped_message_bytes[arg_member.offset_in_bytes],
                        cast(*void) remainder.data,
                        arg_type_info.runtime_size
                    );
                    remainder.data += arg_type_info.runtime_size;
            }
        }

        return cast(*void) untyped_message_bytes.data;
    }

    Wayland_EGL_Window :: struct {
        wl_surface_id: u32;
        wl_buffer_params_id: u32;
        wl_frame_callback_id: u32;
        wp_viewport_id: u32;
        wp_fractional_scale_id: u32;

        xdg_surface_id: u32;
        // only top level windows are supported. there are also popups
        xdg_toplevel_id: u32;

        width: s32;
        logical_width: s32;
        height: s32;
        logical_height: s32;
        scale: float64 = 1.0;

        text_buffer: [MAX_WAYLAND_MESSAGE_SIZE]u8;
        text: string;
        keyboard_state: Keyboard_State;
        mouse_state: Mouse_State;
        scroll_delta: Vector2;

        buffers: [2]Wayland_EGL_Buffer;
        current: s64;

        waiting_for_vblank: bool;
        running := true;
    };
    Wayland_EGL_Buffer :: struct {
        wl_buffer_id: u32;
        gbm_buffer_object: *gbm_bo;
        egl_image: EGLImage;
        texture: GLuint;
        fbo: GLuint;
        busy: bool;
    };
    init_window :: (backend: *Backend, window: *Wayland_EGL_Window, width: s32, height: s32, title: string) {
        window.logical_width = width;
        window.logical_height = height;

        init_keyboard_state(*window.keyboard_state);

        window.text.data = window.text_buffer.data;

        connection := *backend.connection;
        window.wl_surface_id = new_wayland_client_object(connection, Interface_Id.WL_SURFACE);
        send_wayland_message(connection, connection.wl_compositor_id, Wl_Compositor_Request_Create_Surface.{ id = window.wl_surface_id });
        if connection.wp_viewporter_id != 0 && connection.wp_fractional_scale_manager_id != 0 {
            window.wp_viewport_id = new_wayland_client_object(connection, .WP_VIEWPORT);
            send_wayland_message(connection, connection.wp_viewporter_id, Wp_Viewporter_Request_Get_Viewport.{ id = window.wp_viewport_id, surface = window.wl_surface_id });
            window.wp_fractional_scale_id = new_wayland_client_object(connection, .WP_FRACTIONAL_SCALE_V1);
            send_wayland_message(connection, connection.wp_fractional_scale_manager_id, Wp_Fractional_Scale_Manager_V1_Request_Get_Fractional_Scale.{ id = window.wp_fractional_scale_id, surface = window.wl_surface_id });
        }
        window.xdg_surface_id = new_wayland_client_object(connection, Interface_Id.XDG_SURFACE);
        send_wayland_message(connection, connection.xdg_wm_base_id, Xdg_Wm_Base_Request_Get_Xdg_Surface.{ id = window.xdg_surface_id, surface = window.wl_surface_id });
        window.xdg_toplevel_id = new_wayland_client_object(connection, Interface_Id.XDG_TOPLEVEL);
        send_wayland_message(connection, window.xdg_surface_id, Xdg_Surface_Request_Get_Toplevel.{ id = window.xdg_toplevel_id });
        send_wayland_message(connection, window.xdg_toplevel_id, Xdg_Toplevel_Request_Set_Title.{ title = title });
        send_wayland_message(connection, window.wl_surface_id, Wl_Surface_Request_Commit.{});

        for *buffer: window.buffers {
            glGenTextures(1, *buffer.texture);
            glGenFramebuffers(1, *buffer.fbo);
            glBindFramebuffer(GL_FRAMEBUFFER, buffer.fbo);
            glFramebufferParameteri(GL_FRAMEBUFFER, GL_FRAMEBUFFER_FLIP_Y_MESA, xx GL_TRUE);
        }
    }
    can_draw :: (window: Wayland_EGL_Window) -> bool {
        return !window.waiting_for_vblank && window.buffers[window.current].wl_buffer_id != 0 && !window.buffers[window.current].busy;
    }
    update_window :: (backend: *Backend, window: *Wayland_EGL_Window, event: Wayland_Event) {
        probably_create_buffers :: (backend: *Backend, window: *Wayland_EGL_Window) {
            scale_120 := cast(s64)(window.scale * 120 + 0.5);
            window.width  = xx ((window.logical_width  * scale_120 + 60) / 120);
            window.height = xx ((window.logical_height * scale_120 + 60) / 120);
            for *buffer: window.buffers {
                should_create_buffer := buffer.gbm_buffer_object == null ||
                gbm_bo_get_width(buffer.gbm_buffer_object) != xx window.width ||
                gbm_bo_get_height(buffer.gbm_buffer_object) != xx window.height;

                if should_create_buffer {
                    if buffer.egl_image != null {
                        if eglDestroyImage(context.forbear.backend.egl_display, buffer.egl_image) != 1 {
                            log_error("failed to destroy previous egl image: %\n", eglGetError());
                            exit(-1);
                        }
                    }
                    if buffer.gbm_buffer_object != null {
                        gbm_bo_destroy(buffer.gbm_buffer_object);
                    }

                    buffer.gbm_buffer_object = gbm_bo_create_with_modifiers2(
                        backend.device, xx window.width, xx window.height,
                        GBM_FORMAT_ABGR8888, backend.dmabuf_modifiers.data,
                        xx backend.dmabuf_modifiers.count, xx gbm_bo_flags.USE_RENDERING
                    );
                    if buffer.gbm_buffer_object == null {
                        log_error("failed to create gbm buffer object\n");
                        exit(-1);
                    }

                    fd, offset, stride, modifier_lo, modifier_hi: s64;
                    modifier    := gbm_bo_get_modifier(buffer.gbm_buffer_object);
                    plane_count := gbm_bo_get_plane_count(buffer.gbm_buffer_object);
                    assert(plane_count == 1, "expecting the buffer to have only one plane");
                    modifier_lo = xx (modifier & 0xFFFFFFFF);
                    modifier_hi = xx (modifier >> 32);
                    fd          = xx gbm_bo_get_fd_for_plane(buffer.gbm_buffer_object, 0);
                    defer close(xx fd);
                    offset      = xx gbm_bo_get_offset(buffer.gbm_buffer_object, 0);
                    stride      = xx gbm_bo_get_stride_for_plane(buffer.gbm_buffer_object, 0);

                    attributes := EGLAttrib.[
                        EGL_WIDTH,                          xx window.width,
                        EGL_HEIGHT,                         xx window.height,
                        EGL_LINUX_DRM_FOURCC_EXT,           GBM_FORMAT_ABGR8888,
                        EGL_DMA_BUF_PLANE0_FD_EXT,          fd,
                        EGL_DMA_BUF_PLANE0_OFFSET_EXT,      offset,
                        EGL_DMA_BUF_PLANE0_PITCH_EXT,       stride,
                        EGL_DMA_BUF_PLANE0_MODIFIER_LO_EXT, modifier_lo,
                        EGL_DMA_BUF_PLANE0_MODIFIER_HI_EXT, modifier_hi,
                        EGL_NONE,
                    ];
                    buffer.egl_image = eglCreateImage(backend.egl_display, null, EGL_LINUX_DMA_BUF_EXT, null, attributes.data);
                    if buffer.egl_image == null {
                        log_error("failed to create frame buffer: %\n", eglGetError());
                        exit(-1);
                    }

                    glBindTexture(GL_TEXTURE_2D, buffer.texture);
                    glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, buffer.egl_image);
                    glBindFramebuffer(GL_FRAMEBUFFER, buffer.fbo);
                    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, buffer.texture, 0);
                    assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
                    window.wl_buffer_params_id = new_wayland_client_object(*backend.connection, Interface_Id.ZWP_LINUX_BUFFER_PARAMS_V1);

                    send_wayland_message(*backend.connection, backend.connection.zwp_dmabuf_id, Zwp_Linux_Dmabuf_V1_Request_Create_Params.{
                        params_id = window.wl_buffer_params_id,
                    });
                    send_wayland_message(*backend.connection, window.wl_buffer_params_id, Zwp_Linux_Buffer_Params_V1_Request_Add.{
                        fd          = xx fd,
                        plane_idx   = 0,
                        offset      = xx offset,
                        stride      = xx stride,
                        modifier_lo = xx modifier_lo,
                        modifier_hi = xx modifier_hi,
                    });

                    previous_buffer_id := buffer.wl_buffer_id;
                    buffer.wl_buffer_id = new_wayland_client_object(*backend.connection, Interface_Id.WL_BUFFER);
                    buffer.busy = false;
                    send_wayland_message(*backend.connection, window.wl_buffer_params_id, Zwp_Linux_Buffer_Params_V1_Request_Create_Immed.{
                        buffer_id = buffer.wl_buffer_id,
                        width     = window.width,
                        height    = window.height,
                        format    = GBM_FORMAT_ABGR8888,
                        flags     = 0,
                    });

                    send_wayland_message(*backend.connection, window.wl_buffer_params_id, Zwp_Linux_Buffer_Params_V1_Request_Destroy.{ });
                    window.wl_buffer_params_id = 0;


                    if window.wp_viewport_id != 0 {
                        send_wayland_message(*backend.connection, window.wp_viewport_id, Wp_Viewport_Request_Set_Destination.{ width = window.logical_width, height = window.logical_height });
                    } else {
                        send_wayland_message(*backend.connection, window.wl_surface_id, Wl_Surface_Request_Set_Buffer_Scale.{ scale = xx window.scale });
                    }

                    if previous_buffer_id != 0 {
                        send_wayland_message(*backend.connection, previous_buffer_id, Wl_Buffer_Request_Destroy.{});
                    }
                }
            }
        }

        if event.object_id == window.xdg_surface_id && event.message.type == Xdg_Surface_Event_Configure {
            configure := cast(*Xdg_Surface_Event_Configure) event.data;
            send_wayland_message(*backend.connection, window.xdg_surface_id, Xdg_Surface_Request_Ack_Configure.{ serial = configure.serial });
            probably_create_buffers(backend, window);
        } else if event.object_id == window.xdg_toplevel_id {
            if event.message.type == {
                case Xdg_Toplevel_Event_Close;
                    window.waiting_for_vblank = false;
                    window.running = false;
                case Xdg_Toplevel_Event_Configure;
                    configure := cast(*Xdg_Toplevel_Event_Configure) event.data;
                    if configure.width {
                        window.logical_width = configure.width;
                    }
                    if configure.height {
                        window.logical_height = configure.height;
                    }
            }
        } else if event.object_id == window.wp_fractional_scale_id
               && event.message.type == Wp_Fractional_Scale_V1_Event_Preferred_Scale {
            preferred_scale := cast(*Wp_Fractional_Scale_V1_Event_Preferred_Scale) event.data;
            window.scale = (cast(float64)preferred_scale.scale) / 120.0;
            if window.buffers[0].gbm_buffer_object != null {
                // this should only ever recreate a buffer, never create one
                probably_create_buffers(backend, window);
            }
        } else if event.object_id == window.wl_surface_id && event.message.type == Wl_Surface_Event_Preferred_Buffer_Scale && window.wp_fractional_scale_id == 0 {
            preferred_scale := cast(*Wl_Surface_Event_Preferred_Buffer_Scale) event.data;
            window.scale = xx preferred_scale.factor;
            if window.buffers[0].gbm_buffer_object != null {
                // this should only ever recreate a buffer, never create one
                probably_create_buffers(backend, window);
            }
        } else if event.object_id == window.wl_frame_callback_id && event.message.type == Wl_Callback_Event_Done {
            window.waiting_for_vblank = false;
            window.wl_frame_callback_id = 0;
            if EXIT_ON_FIRST_FRAME {
                window.running = false;
            }
        } else if event.object_id == window.wl_buffer_params_id
               && event.message.type == Zwp_Linux_Buffer_Params_V1_Event_Failed {
            log_error("compositor failed to import the dmabuf (%x%)", window.width, window.height);
            exit(-1);
        } else if event.object_id == backend.connection.wl_pointer_id {
            using window.mouse_state;
            if event.message.type == {
                // TODO: support pointer gestures https://wayland.app/protocols/pointer-gestures-unstable-v1
                case Wl_Pointer_Event_Enter;
                    enter := cast(*Wl_Pointer_Event_Enter) event.data;
                    if window.wl_surface_id == enter.surface {
                        serial = enter.serial;
                        inside = true;

                        position = Vector2.{
                            cast(float) enter.surface_x,
                            cast(float) enter.surface_y,
                        } / 256.0;
                        send_wayland_message(
                            *backend.connection,
                            backend.connection.wp_cursor_shape_device_id,
                            Wp_Cursor_Shape_Device_V1_Request_Set_Shape.{
                                serial = window.mouse_state.serial,
                                shape  = CURSOR_SHAPES[window.mouse_state.cursor],
                            }
                        );
                    }
                case Wl_Pointer_Event_Leave;
                    leave := cast(*Wl_Pointer_Event_Leave) event.data;
                    if window.wl_surface_id == leave.surface {
                        inside = false;
                    }
                case Wl_Pointer_Event_Warp;
                    warp := cast(*Wl_Pointer_Event_Warp) event.data;
                    position = Vector2.{
                        cast(float) warp.surface_x,
                        cast(float) warp.surface_y,
                    } / 256.0;
                case Wl_Pointer_Event_Motion;
                    motion := cast(*Wl_Pointer_Event_Motion) event.data;
                    position = Vector2.{
                        cast(float) motion.surface_x,
                        cast(float) motion.surface_y,
                    } / 256.0;
                case Wl_Pointer_Event_Button;
                    button := cast(*Wl_Pointer_Event_Button) event.data;
                    // 0x110 through 0x117 are the buttons defined in the enum, in the same order as these are enumerated
                    index: s64 = xx (button.button - 0x110);
                    if index >= 0 && index < pressed.count {
                        if button.state == .RELEASED {
                            mouse_release(*window.mouse_state, xx index);
                        } else if button.state == .PRESSED {
                            mouse_press(*window.mouse_state, xx index, window.mouse_state.position);
                        }
                    }
                    backend.clipboard_selection_serial = button.serial;
                case Wl_Pointer_Event_Axis;
                    axis := cast(*Wl_Pointer_Event_Axis) event.data;
                    if axis.axis == .HORIZONTAL_SCROLL {
                        scroll_delta.x += cast(float) axis.value / 256.0;
                    } else if axis.axis == .VERTICAL_SCROLL {
                        scroll_delta.y += cast(float) axis.value / 256.0;
                    }
                // TODO: handle all of the remaining pointer events:
                // - wl_pointer::axis_relative_direction
                // - wl_pointer::axis_value120
                // - wl_pointer::axis_discrete
                // - wl_pointer::axis_stop
                // - wl_pointer::axis_source
                // - wl_pointer::axis_frame
            }
        } else if event.object_id == backend.connection.wl_keyboard_id {
            using window.keyboard_state;
            if event.message.type == {
                case Wl_Keyboard_Event_Enter;
                    enter := cast(*Wl_Keyboard_Event_Enter) event.data;
                    if enter.surface == window.wl_surface_id {
                        inside = true;
                        serial = enter.serial;

                        keys: []u32;
                        keys.data = cast(*u32) enter.keys.data;
                        keys.count = enter.keys.count / size_of(u32);
                        for code: keys {
                            xkb_key_code := code + 8;
                            symbol := xkb_state_key_get_one_sym(backend.connection.key_state, xkb_key_code);
                            if symbol > 0 {
                                key := key_from_keysym(symbol);
                                held[xkb_key_code] = key;
                            }
                        }
                    }
                case Wl_Keyboard_Event_Leave;
                    leave := cast(*Wl_Keyboard_Event_Leave) event.data;
                    if leave.surface == window.wl_surface_id {
                        inside = false;
                        repeating_key_code = 0;
                        xkb_compose_state_reset(backend.connection.compose_state);
                        memset(held.data, 0, size_of(type_of(held)));
                    }
                case Wl_Keyboard_Event_Repeat_Info;
                    repeat_info := cast(*Wl_Keyboard_Event_Repeat_Info) event.data;
                    repeat_rate = repeat_info.rate;
                    repeat_delay = repeat_info.delay;
                case Wl_Keyboard_Event_Modifiers;
                    update_held_keys_by_modifiers(backend, *window.keyboard_state);
                case Wl_Keyboard_Event_Key;
                    key_event := cast(*Wl_Keyboard_Event_Key) event.data;
                    backend.clipboard_selection_serial = key_event.serial;
                    xkb_key_code := key_event.key + 8;
                    if key_event.state == .RELEASED {
                        key := held[xkb_key_code];
                        if key != 0 {
                            add_key_event(*events, Key_Event.{.RELEASED, key});
                            held[xkb_key_code] = 0;
                            if xkb_key_code == repeating_key_code {
                                repeating_key_code = 0;
                            }
                        }
                    } else if key_event.state == .PRESSED {
                        symbol := xkb_state_key_get_one_sym(backend.connection.key_state, xkb_key_code);
                        if symbol > 0 {
                            key := key_from_keysym(symbol);
                            if key != 0 {
                                add_key_event(*events, Key_Event.{.PRESSED, key});
                                held[xkb_key_code] = key;
                            }

                            utf8: [64]u8;
                            compose_handled := false;
                            compose := backend.connection.compose_state;
                            if compose {
                                if xkb_compose_state_feed(compose, symbol) == .XKB_COMPOSE_FEED_ACCEPTED {
                                    status := xkb_compose_state_get_status(compose);
                                    if status == .XKB_COMPOSE_COMPOSING {
                                        compose_handled = true;
                                    } else if status == .XKB_COMPOSE_COMPOSED {
                                        length := xkb_compose_state_get_utf8(compose, utf8.data, utf8.count);
                                        append_text(to_string(utf8.data, length), *window.text, window.text_buffer);
                                        xkb_compose_state_reset(compose);
                                        compose_handled = true;
                                    } else if status == .XKB_COMPOSE_CANCELLED {
                                        xkb_compose_state_reset(compose);
                                        compose_handled = true;
                                    }
                                }
                            }
                            if !compose_handled {
                                append_text(key_text(backend.connection.key_state, xkb_key_code, utf8), *window.text, window.text_buffer);
                            }
                            if     key != 0
                                && repeat_rate > 0
                                && xkb_keymap_key_repeats(backend.connection.keymap, xkb_key_code) {
                                repeating_key = key;
                                repeating_key_code = xkb_key_code;
                                next_repeat = seconds_since_init() + (cast(float)repeat_delay) / 1000.0;
                            }
                        }
                    } else if key_event.state == .REPEATED {
                        key := held[xkb_key_code];
                        if key != 0 {
                            add_key_event(*events, Key_Event.{.REPEATED, key});
                            utf8: [64]u8;
                            append_text(key_text(backend.connection.key_state, xkb_key_code, utf8), *window.text, window.text_buffer);
                        }
                    }
            }
        }

        for *buffer: window.buffers {
            if event.object_id == buffer.wl_buffer_id && event.message.type == Wl_Buffer_Event_Release {
                buffer.busy = false;
            }
        }
    }

    Atlas_Entry :: struct {
        uv_min: Vector2;
        uv_max: Vector2;
    };

    Wayland_EGL_Backend :: struct {
        egl_display: EGLDisplay;
        egl_context: EGLContext;

        dri_fd: s32;
        device: *gbm_device;

        clipboard_selection_serial:  u32;
        clipboard_text_buffer:       string;
        clipboard_mime_is_text:      bool;
        clipboard_wl_data_source_id: u32;
        clipboard_text:              string;

        dmabuf_modifiers: [..]u64;

        connection: Wayland_Connection;
    };
    glEGLImageTargetTexture2DOES: (target: GLenum, image: *void) #c_call;
    GBM_FORMAT_ABGR8888 :: 0x34324241;
    DRM_FORMAT_MOD_INVALID :: 0x00ffffffffffffff;
    init_backend :: (backend: *Wayland_EGL_Backend) {
        signal(SIGPIPE, SIG_IGN);
        init_wayland_connection(*backend.connection);

        // TODO: this is hardcoded device, it can be wrong, and it can possibly not be the one the compositor is
        // using. we should use the version 4 of zwp_dmabuf which introduces a feedback event that tells us which
        // device the compositor is using
        backend.dri_fd = open("/dev/dri/renderD128", O_RDWR | O_CLOEXEC);
        if backend.dri_fd == -1 {
            log_error("could not open /dev/dri/renderD128: %\n", errno());
            exit(-1);
        }
        backend.device = gbm_create_device(backend.dri_fd);
        if backend.device == null {
            log_error("could not create the gbm device\n");
            exit(-1);
        }
        backend.egl_display = eglGetPlatformDisplay(EGL_PLATFORM_GBM_KHR, backend.device, null);
        major: s32;
        minor: s32;
        if eglInitialize(backend.egl_display, *major, *minor) != 1 {
            log_error("could not initialize egl");
            exit(-1);
        }
        if eglBindAPI(EGL_OPENGL_API) != 1 {
            log_error("could not bind opengl through egl");
            exit(-1);
        }
        egl_context_attributes := EGLint.[
            EGL_CONTEXT_MAJOR_VERSION, 3,
            EGL_CONTEXT_MINOR_VERSION, 3,
            EGL_CONTEXT_OPENGL_PROFILE_MASK, EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT,
            EGL_NONE
        ];
        backend.egl_context = eglCreateContext(backend.egl_display, null, null, egl_context_attributes.data);
        eglMakeCurrent(backend.egl_display, null, null, backend.egl_context);
        gl_load(*gl, xx eglGetProcAddress);

        if EGL_DEBUGGING {
            print("loaded OpenGL %.%\n", gl_version_major, gl_version_minor);
            print("opengl renderer %\n", to_string(glGetString(GL_RENDERER)));
        }

        glEGLImageTargetTexture2DOES = xx eglGetProcAddress("glEGLImageTargetTexture2DOES");
        if glEGLImageTargetTexture2DOES == null {
            log_error("glEGLImageTargetTexture2DOES is not supported\n");
            exit(-1);
        }

        sync_id := new_wayland_client_object(*backend.connection, .WL_CALLBACK);
        send_wayland_message(*backend.connection, backend.connection.wl_display_id, Wl_Display_Request_Sync.{ callback = sync_id });
        synced := false;
        while !synced {
            event := next_event(*backend.connection);
            if !event.something {
                poll(*backend.connection);
                continue;
            }

            update_wayland_connection(*backend.connection, event);
            if event.message.type == {
                case Zwp_Linux_Dmabuf_V1_Event_Modifier;
                    m := cast(*Zwp_Linux_Dmabuf_V1_Event_Modifier) event.data;
                    modifier := ((cast(u64) m.modifier_hi) << 32) | m.modifier_lo;
                    if m.format == GBM_FORMAT_ABGR8888 &&
                    gbm_device_get_format_modifier_plane_count(backend.device, GBM_FORMAT_ABGR8888, modifier) == 1 {
                        array_add(*backend.dmabuf_modifiers, modifier);
                    }
                case Wl_Callback_Event_Done;
                    synced = true;
            }

            reset_temporary_storage();
        }
        if backend.dmabuf_modifiers.count == 0 {
            log_error("the compositor doesn't accept ABGR8888 dmabufs or all modifiers require more than one plane, so forbear can't render to it.\n");
            // TODO(long-term): should we be falling back to other formats and support them in these kinds of cases?
            exit(-1);
        }
    }
    update_backend :: (backend: *Wayland_EGL_Backend, event: Wayland_Event) {
        update_wayland_connection(*backend.connection, event);

        if event.message.type == Wl_Data_Offer_Event_Offer {
            offer := cast(*Wl_Data_Offer_Event_Offer) event.data;
            if offer.mime_type == "text/plain;charset=utf-8" {
                backend.clipboard_mime_is_text = true;
            }
        } else if event.object_id == backend.connection.wl_data_device_id
               &&  event.message.type == Wl_Data_Device_Event_Data_Offer {
            offer := cast(*Wl_Data_Device_Event_Data_Offer) event.data;
            track_wayland_server_object(*backend.connection, .WL_DATA_OFFER, offer.id);
            backend.clipboard_mime_is_text = false;
        } else if event.object_id == backend.connection.wl_data_device_id
               && event.message.type == Wl_Data_Device_Event_Selection {
            selection := cast(*Wl_Data_Device_Event_Selection) event.data;
            using backend;
            if selection.id != 0 {
                if clipboard_wl_data_source_id == 0 {
                    clipboard_text.count = 0;
                    if clipboard_mime_is_text {
                        fds: [2]s32;
                        if pipe(*fds) == 0 {
                            send_wayland_message(
                                *connection,
                                selection.id,
                                Wl_Data_Offer_Request_Receive.{
                                    mime_type = "text/plain;charset=utf-8",
                                    fd        = cast(Fd) fds[1]
                                }
                            );
                            close(fds[1]);

                            while true {
                                if clipboard_text.count == clipboard_text_buffer.count {
                                    new_count := max(clipboard_text_buffer.count * 2, 4096);
                                    clipboard_text_buffer.data = realloc(
                                        clipboard_text_buffer.data,
                                        new_count,
                                        clipboard_text_buffer.count,,
                                        context.forbear.persistent_allocator
                                    );
                                    clipboard_text_buffer.count = new_count;
                                }
                                result := read(
                                    fds[0],
                                    clipboard_text_buffer.data + clipboard_text.count,
                                    xx (clipboard_text_buffer.count - clipboard_text.count)
                                );
                                if result <= 0 break;
                                clipboard_text.count += result;
                            }
                            clipboard_text.data = clipboard_text_buffer.data;
                            close(fds[0]);
                        }
                    }
                }
                send_wayland_message(*connection, selection.id, Wl_Data_Offer_Request_Destroy.{});
            } else {
                clipboard_text.count = 0;
                clipboard_mime_is_text = false;
            }
        } else if event.object_id == backend.connection.wl_data_device_id
               && event.message.type == Wl_Data_Device_Event_Enter {
            enter := cast(*Wl_Data_Device_Event_Enter) event.data;
            if enter.id != 0 {
                send_wayland_message(*backend.connection, enter.id, Wl_Data_Offer_Request_Destroy.{});
            }
        } else if event.message.type == Wl_Data_Source_Event_Send {
            send := cast(*Wl_Data_Source_Event_Send) event.data;
            fd   := cast(s32) send.fd;
            if event.object_id == backend.clipboard_wl_data_source_id {
                written := 0;
                while written < backend.clipboard_text.count {
                    result := write(
                        fd,
                        backend.clipboard_text.data + written,
                        xx (backend.clipboard_text.count - written)
                    );
                    if result > 0 {
                        written += result;
                    } else {
                        break;
                    }
                }
            }
            close(fd);
        } else if event.object_id == backend.clipboard_wl_data_source_id
               && event.message.type == Wl_Data_Source_Event_Cancelled {
            send_wayland_message(
                *backend.connection,
                backend.clipboard_wl_data_source_id,
                Wl_Data_Source_Request_Destroy.{}
            );
            backend.clipboard_wl_data_source_id = 0;
        }
    }

    Backend :: Wayland_EGL_Backend;
    Window :: Wayland_EGL_Window;
}

Direction :: enum u8 { HORIZONTAL; VERTICAL; };
DIRECTIONS :: Direction.[.HORIZONTAL, .VERTICAL];
opposite :: (direction: Direction) -> Direction {
    if #complete direction == {
    case .HORIZONTAL;
        return .VERTICAL;
    case .VERTICAL;
        return .HORIZONTAL;
    }
}

Sizing :: struct {
    Kind :: enum u8 {
        FIT; FIXED; GROW;
    };

    kind: Kind;

    union {
        fixed: float;
        // A ratio with respect to the opposite axis.
        ratio: float;
        // Grows to fill available space, taking a proportional share based on the factor. A factor of 2.0 claims twice the space
        // of 1.0.
        grow: float;
    }
};
fit :: () -> Sizing {
    return Sizing.{ kind = .FIT };
}
fixed :: (value: float) -> Sizing {
    return Sizing.{ kind = .FIXED, fixed = value };
}
grow :: (value := 1.0) -> Sizing {
    return Sizing.{ kind = .GROW, grow = value };
}

Shadow :: struct {
    offset: Sides;
    blur_radius: float;
    spread: float;
    color: Vector4;
};

Alignment :: enum u8 { START; CENTER; END; };

// Will modify the min size of layout boxes that wrap text accordingly
// character => largest character
// word => largest word
// none => all in one line
Text_Wrapping :: enum u8 {
    // Uses a simple greedy algorithm to break on word boundaries
    WORD;
    CHARACTER;
    NONE;
};

Overflow :: enum u8 { VISIBLE; WRAP; };

Sides :: struct {
    x: Vector2;
    y: Vector2;
};
#scope_module
get :: (sides: Sides, direction: Direction) -> Vector2 {
    if direction == .HORIZONTAL {
        return sides.x;
    } else {
        return sides.y;
    }
}
#scope_export
all :: (value: float) -> Sides {
    return Sides.{
        x = make_vector2(value),
        y = make_vector2(value),
    };
}
in_line :: (value: float) -> Sides {
    return Sides.{
        x = make_vector2(value),
        y = make_vector2(0.0),
    };
}
in_line :: (sides: Sides, value: float) -> Sides {
    return Sides.{
        x = make_vector2(value),
        y = sides.y
    };
}
block :: (value: float) -> Sides {
    return Sides.{
        x = make_vector2(0.0),
        y = make_vector2(value),
    };
}
block :: (sides: Sides, value: float) -> Sides {
    return Sides.{
        x = sides.x,
        y = make_vector2(value),
    };
}
left :: (value: float) -> Sides {
    return Sides.{
        x = Vector2.{ x = value, y = 0.0 },
        y = make_vector2(0.0),
    };
}
left :: (sides: Sides, value: float) -> Sides {
    return Sides.{
        x = Vector2.{ x = value, y = sides.x.y },
        y = sides.y,
    };
}
right :: (value: float) -> Sides {
    return Sides.{
        x = Vector2.{ x = 0.0, y = value },
        y = make_vector2(0.0),
    };
}
right :: (sides: Sides, value: float) -> Sides {
    return Sides.{
        x = Vector2.{ x = sides.x.x, y = value },
        y = sides.y,
    };
}
top :: (value: float) -> Sides {
    return Sides.{
        x = make_vector2(0.0),
        y = Vector2.{ x = value, y = 0.0 },
    };
}
top :: (sides: Sides, value: float) -> Sides {
    return Sides.{
        x = sides.x,
        y = Vector2.{ x = value, y = sides.y.y },
    };
}
bottom :: (value: float) -> Sides {
    return Sides.{
        x = make_vector2(0.0),
        y = Vector2.{ x = 0.0, y = value },
    };
}
bottom :: (sides: Sides, value: float) -> Sides {
    return Sides.{
        x = sides.x,
        y = Vector2.{ x = sides.y.x, y = value },
    };
}
Padding :: Sides;
Margin :: Sides;
Border_Width :: Sides;

CURSOR_COUNT :: #run enum_highest_value(Cursor) + 1;
Cursor :: enum u8 {
    DEFAULT;
    TEXT;
    POINTER;
    WAIT;
    PROGRESS;
    CROSSHAIR;
    HELP;
    NOT_ALLOWED;
    MOVE;
    EW_RESIZE;
    NS_RESIZE;
    NWSE_RESIZE;
    NESW_RESIZE;
};

Border_Style :: enum u32 { SOLID; DASHED; };

// -1 in values means it should be inferred by forbear
Complete_Style :: struct {
    background: Background;

    color: Vector4;
    border_radius: float;
    border_color: Vector4;
    border_width: Border_Width;
    border_style: Border_Style;

    shadow: Shadow;

    font: *Font;

    // Will do nothing if the font is not a variable font. If you don't have a variable font, you should use different fonts
    // for different weights.
    font_weight: u16;
    font_size: float;
    line_height: float;
    text_wrapping: Text_Wrapping;
    cursor: Cursor;

    overflow: Overflow;
    placement: Placement;
    z_index: u16 = U16_MAX;

    min_width: float = FLOAT32_NAN;
    max_width: float = FLOAT32_NAN;
    width: Sizing;
    max_height: float = FLOAT32_NAN;
    min_height: float = FLOAT32_NAN;
    height: Sizing;

    translate: Vector2;

    padding: Padding;
    margin: Margin;

    direction: Direction;
    x_justification: Alignment;
    y_justification: Alignment;
};

Base_Style :: struct {
    font: *Font;
    color: Vector4 = Vector4.{ 1.0, 1.0, 1.0, 1.0 };
    font_size: float = 16.0;
    font_weight: u16 = 600;
    line_height: float = 1.0;
    text_wrapping: Text_Wrapping = .WORD;
    cursor: Cursor = .DEFAULT;
};

from :: (style: Complete_Style) -> Base_Style {
    return Base_Style.{
        font = style.font,
        color = style.color,
        font_size = style.font_size,
        font_weight = style.font_weight,
        line_height = style.line_height,
        text_wrapping = style.text_wrapping,
        cursor = style.cursor,
    };
}

Gradient_Stop :: struct {
    color: Vector4;
    // Position along the gradient in the [0, 1] range.
    position: float;
} #no_padding;
angle :: (degrees: float) -> Vector2 {
    radians := degrees * Math.PI / 180.0;
    return Vector2.{ x = Math.sin(radians), y = -Math.cos(radians)};
}
to_top :: () -> Vector2 {
    return Vector2.{ x = 0, y = -1 };
}
to_bottom :: () -> Vector2 {
    return Vector2.{ x = 0, y = 1 };
}
to_left :: () -> Vector2 {
    return Vector2.{ x = -1, y = 0 };
}
to_right :: () -> Vector2 {
    return Vector2.{ x = 1, y = 0 };
}
to_top_left :: () -> Vector2 {
    return Vector2.{ x = xx -Math.SQRTH, y = xx -Math.SQRTH };
}
to_top_right :: () -> Vector2 {
    return Vector2.{ x = xx Math.SQRTH, y = xx -Math.SQRTH };
}
to_bottom_left :: () -> Vector2 {
    return Vector2.{ x = xx -Math.SQRTH, y = xx Math.SQRTH };
}
to_bottom_right :: () -> Vector2 {
    return Vector2.{ x = xx Math.SQRTH, y = xx Math.SQRTH };
}
Linear_Gradient :: struct {
    // Stops define where each color sits along the gradient; positions are expected to be monotonically increasing within the
    // [0, 1] range.
    stops: []Gradient_Stop;
    // Which way the gradient flows. Defaults to left-to-right.
    direction: Vector2;
};

Background :: struct {
    Kind :: enum u8 {
        COLOR;
        // IMAGE;
        GRADIENT;
    };

    kind: Kind;
    union {
        // image: *Graphics.Image,
        color: Vector4;
        // A linear gradient across the element. Defaults to flowing left-to-right; set `direction` to change which way it runs.
        // See `Linear_Gradient`.
        gradient: Linear_Gradient;
    }
};
rgb :: (r: float, g: float, b: float) -> Vector4 {
    return Vector4.{r / 255.0, g / 255.0, b / 255.0, 1.0};
}
rgba :: (r: float, g: float, b: float) -> Vector4 {
    return rgb(r, g, b);
}
rgba :: (r: float, g: float, b: float, a: float) -> Vector4 {
    return Vector4.{r / 255.0, g / 255.0, b / 255.0, a};
}
hex :: ($code: string) -> Vector4 {
    COLOR :: #run -> Vector4 {
        digits := code;
        if digits.count > 0 && digits[0] == #char "#" then advance(*digits);
        assert(digits.count == 6 || digits.count == 8, "hex: expected #RRGGBB or #RRGGBBAA, got \"%\"", code);
        channels := Vector4.{w = 1};
        for i: 0..digits.count / 2 - 1 {
            value := 0;
            for j: 0..1 {
                c := digits[i * 2 + j];
                if c >= #char "0" && c <= #char "9" value = value * 16 + c - #char "0";
                else if c >= #char "a" && c <= #char "f" value = value * 16 + c - #char "a" + 10;
                else if c >= #char "A" && c <= #char "F" value = value * 16 + c - #char "A" + 10;
                else assert(false, "hex: '%' is not a hexadecimal digit in \"%\"", string.{1, *digits[i * 2 + j]}, code);
            }
            channels.component[i] = value / 255.0;
        }
        return channels;
    };
    return COLOR;
}
color :: (value: Vector4) -> Background {
    return Background.{ kind = .COLOR, color = value };
}
gradient :: (value: Linear_Gradient) -> Background {
    return Background.{ kind = .GRADIENT, gradient = value };
}

Placement :: struct {
    Kind :: enum u8 { FLOW; FIXED; RELATIVE; };

    kind: Kind;
    union {
        fixed: Vector2;
        relative: Vector2;
    }
};
flow :: () -> Placement {
    return Placement.{ kind = .FLOW };
}
fixed :: (value: Vector2) -> Placement {
    return Placement.{ kind = .FIXED, fixed = value };
}
relative :: (value: Vector2) -> Placement {
    return Placement.{ kind = .RELATIVE, relative = value };
}

UNSET :: 0xFF;
VECTOR2_NAN :: Vector2.{ x = FLOAT32_NAN, y = FLOAT32_NAN };
VECTOR4_NAN :: Vector4.{ x = FLOAT32_NAN, y = FLOAT32_NAN, z = FLOAT32_NAN, w = FLOAT32_NAN };
SIDES_NAN :: Sides.{ x = VECTOR2_NAN, y = VECTOR2_NAN };
Style :: struct {
    background: Background = Background.{ kind = UNSET };

    color: Vector4 = VECTOR4_NAN;
    border_radius: float = FLOAT32_NAN;
    border_color: Vector4 = VECTOR4_NAN;
    border_width: Border_Width = SIDES_NAN;
    border_style: Border_Style = UNSET;

    shadow: Shadow = Shadow.{
        offset = SIDES_NAN,
        blur_radius = FLOAT32_NAN,
        spread = FLOAT32_NAN,
        color = VECTOR4_NAN,
    };

    font: *Font;
    font_weight: u16 = 0;
    font_size: float = FLOAT32_NAN;
    line_height: float = FLOAT32_NAN;
    text_wrapping: Text_Wrapping = UNSET;

    cursor: Cursor = UNSET;

    // TODO: use this. we're currently not using this for anything I think this can wrap, without having to flow with text.
    // Flowing with text is meant for text decorations and such, which can be done with a text builder API
    overflow: Overflow = UNSET;
    placement: Placement = Placement.{ kind = UNSET };
    z_index: u16 = U16_MAX;

    min_width: float = FLOAT32_NAN;
    max_width: float = FLOAT32_NAN;
    width: Sizing = Sizing.{ kind = UNSET };
    min_height: float = FLOAT32_NAN;
    max_height: float = FLOAT32_NAN;
    height: Sizing = Sizing.{ kind = UNSET };

    translate: Vector2 = VECTOR2_NAN;

    padding: Padding = SIDES_NAN;
    margin: Margin = SIDES_NAN;

    x_justification: Alignment = UNSET;
    y_justification: Alignment = UNSET;
    direction: Direction = UNSET;
};

overwrite :: (overwriter: Style, overwritten: Style) -> Style {
    result := overwriter;

    if result.background.kind == xx UNSET  result.background = overwritten.background;

    if isnan(result.color.x)  result.color = overwritten.color;
    if isnan(result.border_radius)  result.border_radius = overwritten.border_radius;
    if isnan(result.border_color.x)  result.border_color = overwritten.border_color;
    if isnan(result.border_width.x.x)  result.border_width = overwritten.border_width;
    if result.border_style == xx UNSET  result.border_style = overwritten.border_style;

    if isnan(result.shadow.blur_radius)  result.shadow = overwritten.shadow;

    if result.font == null  result.font = overwritten.font;
    if result.font_weight == 0  result.font_weight = overwritten.font_weight;
    if isnan(result.font_size)  result.font_size = overwritten.font_size;
    if isnan(result.line_height)  result.line_height = overwritten.line_height;
    if result.text_wrapping == xx UNSET  result.text_wrapping = overwritten.text_wrapping;
    if result.cursor == xx UNSET  result.cursor = overwritten.cursor;

    if result.overflow == xx UNSET  result.overflow = overwritten.overflow;
    if result.placement.kind == xx UNSET  result.placement = overwritten.placement;
    if result.z_index == U16_MAX  result.z_index = overwritten.z_index;

    if isnan(result.min_width)  result.min_width = overwritten.min_width;
    if isnan(result.max_width)  result.max_width = overwritten.max_width;
    if result.width.kind == xx UNSET  result.width = overwritten.width;
    if isnan(result.min_height)  result.min_height = overwritten.min_height;
    if isnan(result.max_height)  result.max_height = overwritten.max_height;
    if result.height.kind == xx UNSET  result.height = overwritten.height;

    if isnan(result.translate.x)  result.translate = overwritten.translate;

    if isnan(result.padding.x.x)  result.padding = overwritten.padding;
    if isnan(result.margin.x.x)  result.margin = overwritten.margin;

    if result.x_justification == xx UNSET  result.x_justification = overwritten.x_justification;
    if result.y_justification == xx UNSET  result.y_justification = overwritten.y_justification;
    if result.direction == xx UNSET  result.direction = overwritten.direction;

    return result;
}

complete_with :: (style: Style, base: Base_Style, out: *Complete_Style) {
    out.background = ifx style.background.kind == xx UNSET then Background.{ kind = .COLOR, color = make_vector4(0.0) } else style.background;

    out.color = ifx isnan(style.color.x) then base.color else style.color;

    out.border_radius = ifx isnan(style.border_radius) then 0.0 else style.border_radius;
    out.border_color = ifx isnan(style.border_color.x) then make_vector4(0.0) else style.border_color;
    out.border_width = ifx isnan(style.border_width.x.x) then all(0.0) else style.border_width;
    out.border_style = ifx style.border_style == xx UNSET then .SOLID else style.border_style;

    out.shadow = style.shadow;

    out.font = ifx style.font == null then base.font else style.font;
    out.font_weight = ifx style.font_weight == 0 then base.font_weight else style.font_weight;
    out.font_size = ifx isnan(style.font_size) then base.font_size else style.font_size;
    out.line_height = ifx isnan(style.line_height) then base.line_height else style.line_height;
    out.text_wrapping = ifx style.text_wrapping == xx UNSET then base.text_wrapping else style.text_wrapping;
    out.cursor = ifx style.cursor == xx UNSET then base.cursor else style.cursor;

    out.overflow = ifx style.overflow == xx UNSET then .VISIBLE else style.overflow;
    out.placement = ifx style.placement.kind == xx UNSET then Placement.{ kind = .FLOW } else style.placement;
    out.z_index = style.z_index;

    out.min_width = style.min_width;
    out.max_width = style.max_width;
    out.width = ifx style.width.kind == xx UNSET then Sizing.{ kind = .FIT } else style.width;

    out.min_height = style.min_height;
    out.max_height = style.max_height;
    out.height = ifx style.height.kind == xx UNSET then Sizing.{ kind = .FIT } else style.height;

    out.translate = ifx isnan(style.translate.x) then make_vector2(0.0) else style.translate;

    out.padding = ifx isnan(style.padding.x.x) then all(0.0) else style.padding;
    out.margin = ifx isnan(style.margin.x.x) then all(0.0) else style.margin;

    out.direction = ifx style.direction == xx UNSET then .HORIZONTAL else style.direction;
    out.x_justification = ifx style.x_justification == xx UNSET then .START else style.x_justification;
    out.y_justification = ifx style.y_justification == xx UNSET then .START else style.y_justification;
}

Pool_Slot :: struct {
    pool: Flat_Pool;
    allocator: Allocator;
    last_frame: s64;
    used: bool;
};
Node :: struct {
    Kind :: enum {
        ELEMENT; SCOPE;
    }
    kind: Kind = .ELEMENT;

    size: Vector2;
    position: Vector2;
    min_size: Vector2;
    max_size: Vector2 = Vector2.{FLOAT32_INFINITY, FLOAT32_INFINITY};
    z: u16;

    first_child: s64 = -1;
    last_child: s64 = -1;
    next_sibling: s64 = -1;
    previous_sibling: s64 = -1;
    parent: s64 = -1;
    glyphs: Glyphs;

    style: Complete_Style;

    content_size: Vector2;
    // TODO: should we have this? this feels like the wrong solution to the problem, there should be a user-accessible way of
    // changing the offset of the children without a specific property for it
    //
    // Generally used for scrolling. This is added to the position of the children of this node
    children_offset: Vector2;

    // Clip rect inherited from ancestors that have constrained size with overflowing children. Format: [x, y, width, height].
    // If NAN, no clipping is applied.
    clipping_rectangle: Vector4 = VECTOR4_NAN;
    state_offset: s64;
    state_size: s64;
    pool_slot: s64 = -1;
    key: u64;

    tree: *Node_Tree;
};
Node_Measurement :: struct {
    size: Vector2 = VECTOR2_NAN;
    content_size: Vector2 = VECTOR2_NAN;
    position: Vector2 = VECTOR2_NAN;
    clipping_rectangle: Vector4 = VECTOR4_NAN;
    state_offset: s64;
    state_size: s64;
    pool_slot: s64 = -1;
    key: u64 = U64_MAX;
}
get_measurement :: (node_index: s64 = -1, include_scopes := false) -> measurement: Node_Measurement, defined: bool {
    using context.forbear;
    measurement_index := ifx node_index == -1 then parent_index else node_index;
    if !include_scopes && node_index == -1 {
        measurement_index = get_parent_element_index();
    }
    expected_key := node_tree[measurement_index].key;
    if measurement_index != -1 {
        if measurement_index < measurements.count && measurements[measurement_index].key == expected_key {
            return measurements[measurement_index], true;
        } else {
            //
            // I don't think we should sort these measurements by keys because that would be making the normal case
            // slower in favour of a case that should be rare as I expect things to be.
            //
            // TOOD(depessimization): we should store the previous_index in open_element(), then look up based on that here.
            // There, if the indices don't match, we should iterate to find the index
            // TODO(optimization): we should store a contiguous array of the keys of the previous frame's node tree's keys
            for measurement_by_index: measurements {
                if measurement_by_index.key == expected_key {
                    return measurement_by_index, true;
                }
            }
            return Node_Measurement.{}, false;
        }
    } else {
        return Node_Measurement.{}, false;
    }
}
node_pool :: () -> Allocator {
    using context.forbear;
    assert(parent_index != -1, "node_pool() must be called from inside an element");
    node := *node_tree[parent_index];
    pool_slot := node.pool_slot;
    if pool_slot == -1 {
        measurement, defined := get_measurement(include_scopes = true);
        if defined {
            pool_slot = measurement.pool_slot;
        }
    }
    if pool_slot == -1 {
        for *slot: pool_slots {
            if !slot.used {
                pool_slot = it_index;
                if slot.pool.memory_base == null {
                    init(*slot.pool, 64 * 1024 * 1024);
                    slot.allocator.proc = flat_pool_allocator_proc;
                    slot.allocator.data = *slot.pool;
                }
                slot.used = true;
                break;
            }
        }
    }
    if pool_slot == -1 {
        log_error(#string END
There are no more pool slots available (256). This means one of three things:
1) you have a bug in your code using more pools than you need;
2) you're abusing pools, and you should not;
3) we should increase our pool count to more than 256.

If you think it is 3), get in touch with us to know if we should.
END);
        exit(-1);
    }
    node.pool_slot = pool_slot;
    pool_slots[node.pool_slot].last_frame = frame;
    return pool_slots[node.pool_slot].allocator;
}
state :: ($T: Type, initial: T) -> *T, first_frame: bool {
    using context.forbear;

    assert(parent_index != -1, "state(initial: $T) must be called from inside an element");
    node := *node_tree[parent_index];
    if node.state_size == 0 {
        node.state_offset = state_used;
    }
    assert(node.state_offset + node.state_size == state_used, "call state() before any child element that uses state");
    size := (size_of(T) + 7) & ~7;
    if state_used + size > state_buffers.*[0].count {
        log_error("state buffer is full: % bytes used, % more requested", state_used, size);
        exit(-1);
    }

    result := cast(*T) *state_buffers.*[state_current][state_used];
    result.* = initial;
    is_resizable :: (T: Type) -> bool {
        info := cast(*Type_Info) T;
        return info.type == .ARRAY && (cast(*Type_Info_Array) info).array_type == .RESIZABLE;
    }
    #if #run is_resizable(T) {
        result.allocator = node_pool();
    }
    measurement, defined := get_measurement(include_scopes = true);
    copy_forward := defined && node.state_size + size <= measurement.state_size;
    if copy_forward {
        memcpy(result, *state_buffers.*[1 - state_current][measurement.state_offset + node.state_size], size_of(T));
    }
    node.state_size += size;
    state_used += size;
    return result, !copy_forward;
}
state :: (initial: $T) -> *T, first_frame: bool {
    data, first_frame := state(T, initial);
    return data, first_frame;
}
state :: ($T: Type) -> *T, first_frame: bool {
    initial: T;
    data, first_frame := state(T, initial);
    return data, first_frame;
}
transition :: (value: $T, duration: float, easing: (float) -> float) -> T
#modify { return T == float || T == Vector2 || T == Vector3 || T == Vector4, "transition only supports float, Vector2, Vector3 and Vector4"; } {
    start := state(value);
    target := state(value);
    progress := state(1.0);

    progress.* = min(1.0, progress.* + context.forbear.delta_time / duration);
    current := start.* + (target.* - start.*) * easing(progress.*);

    retarget: bool;
    #if T == float {
        retarget = abs(value - target.*) > 0.0001;
    } else {
        retarget = Math.length(value - target.*) > 0.0001;
    }
    if retarget {
        start.* = current;
        target.* = value;
        progress.* = 0.0;
    }
    return current;
} @hook
Spring_Config :: struct (T: Type) {
    stiffness: float;
    damping: float;
    mass: float;

    current: *T;
}
spring_transition :: (target: $T, config: Spring_Config(T)) -> T
#modify { return T == float || T == Vector2 || T == Vector3 || T == Vector4, "spring_transition only supports float, Vector2, Vector3 and Vector4"; } {
    value := config.current;
    if !value {
        value = state(target);
    }
    velocity := state(T);

    dt := context.forbear.delta_time;
    if dt != 0.0 {
        N :: size_of(T) / size_of(float);
        values := cast(*[N]float) value;
        velocities := cast(*[N]float) velocity;
        targets := cast(*[N]float) *target;
        for i: 0..N-1 {
            displacement := targets.*[i] - values.*[i];
            if (displacement > 0.0 && velocities.*[i] < 0.0) || (displacement < 0.0 && velocities.*[i] > 0.0) {
                velocities.*[i] = 0.0;
            }
            acceleration := (config.stiffness * displacement - config.damping * velocities.*[i]) / config.mass;
            velocities.*[i] += acceleration * dt;
            values.*[i] += velocities.*[i] * dt;

            if abs(displacement) <= 0.0001 && abs(velocities.*[i]) <= 0.0001 {
                values.*[i] = targets.*[i];
                velocities.*[i] = 0.0;
            }
        }
    }
    return value.*;
} @hook
// beware that this pointer might be come invalid if you define one more element
get_node :: (node_index: s64) -> *Node {
    using context.forbear;
    return *node_tree[node_index];
}
// beware that this pointer might be come invalid if you define one more element
get_node :: () -> *Node {
    using context.forbear;
    parent_element_index := get_parent_element_index();
    if parent_element_index != -1 {
        return *node_tree[parent_element_index];
    } else {
        return null;
    }
}
SCROLL_MULTIPLIER :: 48; // TODO: assess if this value shoud be 1) dynamic and/or 2) configurable by the user
Mouse_State :: struct {
    #if OS == .LINUX {
        serial: u32;
    }
    inside: bool;
    position: Vector2;
    scroll_delta: Vector2;

    cursor: Cursor;

    press_position: [MOUSE_BUTTON_COUNT]Vector2;
    pressed: [MOUSE_BUTTON_COUNT]bool;
    released: [MOUSE_BUTTON_COUNT]bool;
    held: [MOUSE_BUTTON_COUNT]bool;
};
#scope_module
mouse_press :: (using state: *Mouse_State, button: Mouse_Button, new_position: Vector2) {
    position = new_position;
    press_position[button] = new_position;
    pressed[button] = true;
    held[button] = true;
}
mouse_release :: (using state: *Mouse_State, button: Mouse_Button) {
    released[button] = true;
    held[button] = false;
}
#scope_export
Keyboard_State :: struct {
    #if OS == .WINDOWS {
        // used in WM_CHAR since Windows inputs utf16 piece by piece and
        // we want to convert to utf8
        high_surrogate: u16;
    } else #if OS == .LINUX {
        serial: u32;
        inside: bool;

        // The Wayland protocol does not handle keys repeating and their rates, they
        // just inform you how they should be repeated.
        //
        // There is no alternative to this in Linux, so we have to handle it ourselves.
        repeating_key: Key;
        repeating_key_code: u32;
        next_repeat: float64;
        // in characters per second
        repeat_rate: s32;
        // in milliseconds
        repeat_delay: s32;
    }
    events_buffer: [32 * 3]Key_Event;
    events: []Key_Event;
    held: [776]Key;
};
#scope_module
init_keyboard_state :: (using state: *Keyboard_State) {
    events.data = events_buffer.data;
    events.count = 0;
}
add_key_event :: (events: *[]Key_Event, key_event: Key_Event) {
    assert(events.count < 32 * 3);
    events.count += 1;
    events.*[events.count - 1] = key_event;
}
// This ensures that the keys held are updated as the modifiers change, so that, in a US Keyboard Layout doing SHIFT+EQUALS holds PLUS, and then releasing SHIFT makes it hold EQUALS. This only applies for keys that
update_held_keys_by_modifiers :: (backend: *Backend, using state: *Keyboard_State) {
    for key, code: held {
        // only update the keys that correspond to unicode characters
        if key != 0 && key < .ESCAPE {
            #if OS == .WINDOWS {
                vk := MapVirtualKeyW(xx ((code & 0xFF) | (ifx code & 0x100 then 0xE000 else 0)), MAPVK_VSC_TO_VK_EX);
                new_key := key_from_virtual_key(vk, cast(u32) code & 0xFF);
            } else #if OS == .MACOS {
                new_key := key_from_key_code(xx code);
            } else #if OS == .LINUX {
                new_key := key_from_keysym(xkb_state_key_get_one_sym(backend.connection.key_state, xx code));
            }
            if new_key != 0 && key != new_key {
                // This means that this key changes with some modifier on or off, so, we need to replace the previous
                // key it represented in favour of a new one. We also need to trigger the release and pressed key events
                // for both keys.
                add_key_event(*events, Key_Event.{.RELEASED, key});
                held[code] = new_key;
                #if OS == .LINUX {
                    if repeating_key_code == code {
                        repeating_key = new_key;
                    }
                }
            }
        }
    }
}
#scope_export
Key_Event :: struct {
    Kind :: enum {
        REPEATED; RELEASED; PRESSED;
    };

    kind: Kind;
    key: Key;
}
Key :: enum u32 {
    // printable keys are their Unicode code point: cast(Key) #char "+"
    A :: #char "a"; B :: #char "b"; C :: #char "c"; D :: #char "d"; E :: #char "e"; F :: #char "f";
    G :: #char "g"; H :: #char "h"; I :: #char "i"; J :: #char "j"; K :: #char "k"; L :: #char "l";
    M :: #char "m"; N :: #char "n"; O :: #char "o"; P :: #char "p"; Q :: #char "q"; R :: #char "r";
    S :: #char "s"; T :: #char "t"; U :: #char "u"; V :: #char "v"; W :: #char "w"; X :: #char "x";
    Y :: #char "y"; Z :: #char "z";

    DIGIT_0 :: #char "0"; DIGIT_1 :: #char "1"; DIGIT_2 :: #char "2"; DIGIT_3 :: #char "3"; DIGIT_4 :: #char "4";
    DIGIT_5 :: #char "5"; DIGIT_6 :: #char "6"; DIGIT_7 :: #char "7"; DIGIT_8 :: #char "8"; DIGIT_9 :: #char "9";

    SPACE :: #char " ";
    EXCLAMATION :: #char "!";
    QUOTE :: #char "\"";
    HASH :: #char "#";
    DOLLAR :: #char "$";
    PERCENT :: #char "%";
    AMPERSAND :: #char "&";
    APOSTROPHE :: #char "'";
    PARENTHESIS_LEFT :: #char "(";
    PARENTHESIS_RIGHT :: #char ")";
    ASTERISK :: #char "*";
    PLUS :: #char "+";
    COMMA :: #char ",";
    MINUS :: #char "-";
    PERIOD :: #char ".";
    SLASH :: #char "/";
    COLON :: #char ":";
    SEMICOLON :: #char ";";
    LESS :: #char "<";
    EQUAL :: #char "=";
    GREATER :: #char ">";
    QUESTION :: #char "?";
    AT :: #char "@";
    BRACKET_LEFT :: #char "[";
    BACKSLASH :: #char "\\";
    BRACKET_RIGHT :: #char "]";
    CARET :: #char "^";
    UNDERSCORE :: #char "_";
    GRAVE :: #char "`";
    BRACE_LEFT :: #char "{";
    PIPE :: #char "|";
    BRACE_RIGHT :: #char "}";
    TILDE :: #char "~";

    ESCAPE :: 0x110000;  // first value above the Unicode range
    ENTER;
    TAB;
    BACKSPACE;
    DELETE;
    INSERT;
    ARROW_LEFT; ARROW_RIGHT; ARROW_UP; ARROW_DOWN;
    HOME; END; PAGE_UP; PAGE_DOWN;
    F1; F2; F3; F4; F5; F6; F7; F8; F9; F10; F11; F12;
    SHIFT_LEFT; SHIFT_RIGHT; CONTROL_LEFT; CONTROL_RIGHT;
    ALT_LEFT; ALT_RIGHT; SUPER_LEFT; SUPER_RIGHT;
    CAPS_LOCK; FUNCTION;
}
MOUSE_BUTTON_COUNT :: #run enum_highest_value(Mouse_Button) + 1;
Mouse_Button :: enum {
    #if OS == .LINUX {
        LEFT;
        RIGHT;
        MIDDLE;
        SIDE;
        EXTRA;
        FORWARD;
        BACK;
        TASK;
    } else {
        LEFT;
        RIGHT;
        MIDDLE;
        BACK;
        FORWARD;
    }
};
get_delta_time :: () -> float {
    return context.forbear.delta_time;
}
get_last_frame_time :: () -> float {
    return context.forbear.last_frame_time;
}
get_viewport_size :: () -> Vector2 {
    using context.forbear;
    return Vector2.{cast(float)window.width, cast(float)window.height} / (cast(float)window.scale);
}
get_mouse_position :: () -> Vector2 {
    return context.forbear.window.mouse_state.position;
}
is_mouse_inside :: () -> bool {
    using context.forbear;
    measurement, defined := get_measurement();
    position             := get_mouse_position();
    return defined && window.mouse_state.inside && is_point_inside(position, measurement);
}
is_mouse_held :: (button := Mouse_Button.LEFT) -> bool {
    using context.forbear;
    return window.mouse_state.held[button] && window.mouse_state.inside;
}
get_scroll_delta :: () -> Vector2 {
    return context.forbear.window.mouse_state.scroll_delta;
}
on_mouse_down :: (button := Mouse_Button.LEFT, check_inside := true) -> bool {
    return context.forbear.window.mouse_state.pressed[button] && (!check_inside || is_mouse_inside());
}
on_mouse_up :: (button := Mouse_Button.LEFT, check_inside := true) -> bool {
    return context.forbear.window.mouse_state.released[button] && (!check_inside || is_mouse_inside());
}
is_point_inside :: (point: Vector2, measurement: Node_Measurement) -> bool {
    return point.x >= measurement.position.x
        && point.y >= measurement.position.y
        && point.x <= measurement.position.x + measurement.size.x
        && point.y <= measurement.position.y + measurement.size.y;
}
on_drag :: (button := Mouse_Button.LEFT) -> bool {
    using context.forbear;
    measurement, defined := get_measurement();
    if defined {
        press_position := window.mouse_state.press_position[button];
        mouse          := get_mouse_position();
        delta          := mouse - press_position;
        moved          := delta.x*delta.x + delta.y*delta.y > 4*4;
        return window.mouse_state.held[button] && is_point_inside(press_position, measurement) && moved;
    } else {
        return false;
    }
}
on_click :: (button := Mouse_Button.LEFT, check_inside := true) -> bool {
    using context.forbear;
    if on_mouse_up(button, check_inside) {
        measurement, defined := get_measurement();
        assert(defined, "the measurement should exist if is_mouse_inside is true");
        mouse          := get_mouse_position();
        press_position := window.mouse_state.press_position[button];
        delta          := mouse - press_position;
        moved          := delta.x*delta.x + delta.y*delta.y > 4*4;
        return is_point_inside(press_position, measurement) && !moved;
    } else {
        return false;
    }
}
// TODO: Currently, this only supports text, but we should support other clipboard content types.
// Each operating system defines the type in the clipboard in a different manner, which make this quite difficult.
get_clipboard_text :: () -> string {
    return context.forbear.backend.clipboard_text;
}
copy_to_clipboard :: (text: string) {
    using context.forbear;
    #if OS == .WINDOWS {
        units  := MultiByteToWideChar(CP_UTF8, 0, text.data, xx text.count, null, 0);
        memory := GlobalAlloc(GMEM_MOVEABLE, cast(u64) (units + 1) * size_of(u16));
        wide   := cast(*u16) GlobalLock(memory);
        MultiByteToWideChar(CP_UTF8, 0, text.data, xx text.count, wide, units);
        wide[units] = 0;
        GlobalUnlock(memory);

        if OpenClipboard(window.hwnd) {
            EmptyClipboard();
            if !SetClipboardData(CF_UNICODETEXT, memory) {
                GlobalFree(memory);
            }
            CloseClipboard();
        } else {
            GlobalFree(memory);
        }
    } else #if OS == .MACOS {
        pool := objc_init(objc_alloc(NSAutoreleasePool));
        defer NSAutoreleasePool.drain(pool);

        // TODO(depessimization): this also applies in other places where we use Apple's APIs, but we should be looking
        // for ways to minimize the amount of stupid heap allocations Apple forces us to do. This is kind of impossible
        // because of Objective C, though.
        nsstring := NSString.initWithBytes(objc_alloc(NSString), text.data, xx text.count, NSUTF8StringEncoding);
        defer release(nsstring);
        backend.clipboard_change_count = backend.pasteboard.clearContents(backend.pasteboard);
        backend.pasteboard.setString(backend.pasteboard, nsstring, NSPasteboardTypeString);

        if text.count > backend.clipboard_text_buffer.count {
            backend.clipboard_text_buffer.data = realloc(
                backend.clipboard_text_buffer.data,
                text.count,
                backend.clipboard_text_buffer.count,,
                persistent_allocator
            );
            backend.clipboard_text_buffer.count = text.count;
        }
        memcpy(backend.clipboard_text_buffer.data, text.data, text.count);
        backend.clipboard_text.data  = backend.clipboard_text_buffer.data;
        backend.clipboard_text.count = text.count;
    } else #if OS == .LINUX {
        connection := *backend.connection;
        if connection.wl_data_device_id != 0 {
            if text.count > backend.clipboard_text_buffer.count {
                backend.clipboard_text_buffer.data = realloc(
                    backend.clipboard_text_buffer.data,
                    text.count,
                    backend.clipboard_text_buffer.count,,
                    persistent_allocator
                );
                backend.clipboard_text_buffer.count = text.count;
            }
            for 0..text.count - 1 {
                backend.clipboard_text_buffer.data[it] = text.data[it];
            }
            backend.clipboard_text.data  = backend.clipboard_text_buffer.data;
            backend.clipboard_text.count = text.count;

            if backend.clipboard_wl_data_source_id != 0 {
                send_wayland_message(connection, backend.clipboard_wl_data_source_id, Wl_Data_Source_Request_Destroy.{});
            }
            backend.clipboard_wl_data_source_id = new_wayland_client_object(connection, .WL_DATA_SOURCE);
            send_wayland_message(
                connection,
                connection.wl_data_device_manager_id,
                Wl_Data_Device_Manager_Request_Create_Data_Source.{ id = backend.clipboard_wl_data_source_id }
            );
            send_wayland_message(
                connection,
                backend.clipboard_wl_data_source_id,
                Wl_Data_Source_Request_Offer.{ mime_type = "text/plain;charset=utf-8" }
            );
            send_wayland_message(
                connection,
                connection.wl_data_device_id,
                Wl_Data_Device_Request_Set_Selection.{
                    source = backend.clipboard_wl_data_source_id,
                    serial = backend.clipboard_selection_serial
                }
            );
        }
    }
}
set_cursor :: (cursor: Cursor) {
    using context.forbear;
    if window.mouse_state.cursor != cursor {
        window.mouse_state.cursor = cursor;
        if window.mouse_state.inside {
            #if OS == .WINDOWS {
                SetCursor(window.backend.cursors[cursor]);
            } else #if OS == .MACOS {
                NSCursor.set(backend.cursors[cursor]);
            } else #if OS == .LINUX {
                if backend.connection.wp_cursor_shape_device_id != 0 {
                    send_wayland_message(
                        *backend.connection,
                        backend.connection.wp_cursor_shape_device_id,
                        Wp_Cursor_Shape_Device_V1_Request_Set_Shape.{
                            serial = window.mouse_state.serial,
                            shape  = CURSOR_SHAPES[cursor],
                        }
                    );
                }
            }
        }
    }
}
get_text_input :: () -> string {
    return context.forbear.window.text;
}
on_key_down :: (code_point: u32, on_repeat := false) -> bool {
    return on_key_down(cast(Key) code_point, on_repeat);
}
on_key_down :: (key: Key, on_repeat := false) -> bool {
    using context.forbear.window.keyboard_state;
    for event: events {
        if (event.kind == .PRESSED || (on_repeat && event.kind == .REPEATED))
         && event.key == key {
            return true;
        }
    }
    return false;
}
on_key_up :: (code_point: u32) -> bool {
    return on_key_up(cast(Key) code_point);
}
on_key_up :: (key: Key) -> bool {
    using context.forbear.window.keyboard_state;
    for event: events {
        if event.kind == .RELEASED && event.key == key {
            return true;
        }
    }
    return false;
}
is_key_held :: (key: Key) -> bool {
    using context.forbear;
    #if OS == .WINDOWS {
        vk: s32;
        if key == {
            case .SHIFT_LEFT;    vk = VK_LSHIFT;
            case .SHIFT_RIGHT;   vk = VK_RSHIFT;
            case .CONTROL_LEFT;  vk = VK_LCONTROL;
            case .CONTROL_RIGHT; vk = VK_RCONTROL;
            case .ALT_LEFT;      vk = VK_LMENU;
            case .ALT_RIGHT;     vk = VK_RMENU;
            case .SUPER_LEFT;    vk = VK_LWIN;
            case .SUPER_RIGHT;   vk = VK_RWIN;
        }
        if vk != 0 {
            return GetKeyState(vk) < 0;
        }
    } else #if OS == .MACOS {
        if key >= .SHIFT_LEFT && key <= .SUPER_RIGHT {
            current_flags: (*void, Selector) -> NSEventModifierFlags #c_call = xx objc_msgSend;
            flags := current_flags(xx class(NSEvent), selector("modifierFlags"));
            mask: NSEventModifierFlags;
            if key == {
                case .SHIFT_LEFT;    #through;
                case .SHIFT_RIGHT;   mask = .NSEventModifierFlagShift;
                case .CONTROL_LEFT;  #through;
                case .CONTROL_RIGHT; mask = .NSEventModifierFlagControl;
                case .ALT_LEFT;      #through;
                case .ALT_RIGHT;     mask = .NSEventModifierFlagOption;
                case .SUPER_LEFT;    #through;
                case .SUPER_RIGHT;   mask = .NSEventModifierFlagCommand;
            }
            if !(flags & mask) {
                return false;
            }
        }
    } else #if OS == .LINUX {
        if key == {
            // TODO(depessimization): for all modifiers here we're lookgin them up by name when we should instead store the index of the modifier and just look it up
            case .SHIFT_LEFT; #through;
            case .SHIFT_RIGHT;
                return xkb_state_mod_name_is_active(backend.connection.key_state, XKB_MOD_NAME_SHIFT.data, .XKB_STATE_MODS_EFFECTIVE) == 1;
            case .ALT_LEFT; #through;
            case .ALT_RIGHT;
                return xkb_state_mod_name_is_active(backend.connection.key_state, XKB_MOD_NAME_ALT.data, .XKB_STATE_MODS_EFFECTIVE) == 1;
            case .CONTROL_LEFT; #through;
            case .CONTROL_RIGHT;
                return xkb_state_mod_name_is_active(backend.connection.key_state, XKB_MOD_NAME_CTRL.data, .XKB_STATE_MODS_EFFECTIVE) == 1;
            case .SUPER_LEFT; #through;
            case .SUPER_RIGHT;
                return xkb_state_mod_name_is_active(backend.connection.key_state, XKB_MOD_NAME_LOGO.data, .XKB_STATE_MODS_EFFECTIVE) == 1;
        }
    }

    using window.keyboard_state;
    for held {
        if it == key {
            return true;
        }
    }
    return false;
}
#scope_module
get_justification :: (node: *Node, direction: Direction) -> Alignment #expand {
    if direction == Direction.HORIZONTAL {
        return node.style.x_justification;
    } else {
        return node.style.y_justification;
    }
}
get_preferred_size :: (node: *Node, direction: Direction) -> Sizing #expand {
    if direction == Direction.HORIZONTAL {
        return node.style.width;
    } else {
        return node.style.height;
    }
}
should_fit_min :: (node: *Node, direction: Direction) -> bool #expand {
    if direction == .HORIZONTAL {
        return isnan(node.style.min_width) && node.style.width.kind != .FIXED;
    } else {
        return isnan(node.style.min_height) && node.style.height.kind != .FIXED;
    }
}
clamp :: (v: *Vector2, a: Vector2, b: Vector2) #expand {
    v.x = clamp(v.x, a.x, b.x);
    v.y = clamp(v.y, a.y, b.y);
}
add :: (vector: *Vector2, direction: Direction, increment: float) #expand {
    if direction == Direction.HORIZONTAL {
        vector.x += increment;
    } else {
        vector.y += increment;
    }
}
get :: (vector: Vector2, direction: Direction) -> float #expand {
    if direction == Direction.HORIZONTAL {
        return vector.x;
    } else {
        return vector.y;
    }
}
set :: (vector: *Vector2, direction: Direction, value: float) #expand {
    if direction == Direction.HORIZONTAL {
        vector.x = value;
    } else {
        vector.y = value;
    }
}
outer_size :: (node: Node, direction: Direction) -> float {
    margin := get(node.style.margin, direction);
    return get(node.size, direction) + margin.x + margin.y;

}
inner_size :: (node: Node, direction: Direction) -> float {
    return get(node.size, direction) - fitting_base(node, direction);
}
fitting_base :: (node: Node, direction: Direction) -> float {
    padding_axis := get(node.style.padding, direction);
    padding := padding_axis.x + padding_axis.y;
    border_axis := get(node.style.border_width, direction);
    border := border_axis.x + border_axis.y;
    return padding + border;
}
#scope_export

Node_Tree :: [..]Node;
append_to_node_tree :: (node_tree: *Node_Tree, parent_index: s64 = -1) -> pointer: *Node, index: s64 {
    index := node_tree.count;
    node := Node.{
        parent = parent_index,
        tree = node_tree,
    };
    if parent_index != -1 {
        parent := *node_tree.*[parent_index];
        if parent.last_child != -1 {
            node_tree.*[parent.last_child].next_sibling = index;
        }
        node.previous_sibling = parent.last_child;
        if parent.first_child == -1 {
            parent.first_child = index;
        }
        parent.last_child = index;
    }
    array_add(node_tree, node);
    return *node_tree.*[index], index;
}

Node_Opening_Data :: struct {
    parent_index: s64;
    scope_key: u64;
    base_style: Base_Style;
    node_index: s64;
};
// Since components/hooks/scopes (all the same thing) are actually nodes, this function is used so that element
// creation, get_node and get_measurement calls are all properly using the closest parent that's an element instead
// of the direct parent which might be a scope.
//
// TODO: This is a terrible trade-off of using a single fat struct for both scopes and elements.
get_parent_element_index :: () -> s64 {
    element_ancestor_index := context.forbear.parent_index;
    previous_parent_index := context.forbear.parent_index;
    while element_ancestor_index != -1 && context.forbear.node_tree[element_ancestor_index].kind == .SCOPE {
        element_ancestor_index = context.forbear.node_tree[element_ancestor_index].parent;
    }
    return element_ancestor_index;
}
// intermediary API that's used from adapters, such as the javascript one. when in jai, use `element`
open_element :: (style: Style, key: u64) -> Node_Opening_Data {
    previous_parent_index := context.forbear.parent_index;
    parent_index := get_parent_element_index();

    node, index := append_to_node_tree(*context.forbear.node_tree, parent_index);
    previous_base_style := context.forbear.base_style;
    complete_with(style, context.forbear.base_style, *node.style);
    context.forbear.base_style = from(node.style);
    if style.z_index < U16_MAX {
        node.z = style.z_index;
    } else if parent_index != -1 {
        node.z = context.forbear.node_tree[parent_index].z;
    }
    node.key = key;
    if node.style.width.kind == {
        // we don't handle FIT or GROW since the node already has the right width by default
        case Sizing.Kind.FIXED;
            node.size.x = node.style.width.fixed;
    }
    if node.style.height.kind == {
        // we don't handle FIT or GROW since the node already has the right width by default
        case Sizing.Kind.FIXED;
            node.size.y = node.style.height.fixed;
    }
    if !isnan(node.style.min_width) {
        node.min_size.x = node.style.min_width;
    } else if node.style.width.kind == .FIXED {
        node.min_size.x = node.style.width.fixed;
    }
    if !isnan(node.style.min_height) {
        node.min_size.y = node.style.min_height;
    } else if node.style.height.kind == .FIXED {
        node.min_size.y = node.style.height.fixed;
    }
    if !isnan(node.style.max_width) {
        node.max_size.x = node.style.max_width;
    } else if node.style.width.kind == .FIXED {
        node.max_size.x = node.style.width.fixed;
    }
    if !isnan(node.style.max_height) {
        node.max_size.y = node.style.max_height;
    } else if node.style.height.kind == .FIXED {
        node.max_size.y = node.style.height.fixed;
    }

    node.size.x = clamp(node.size.x, node.min_size.x, node.max_size.x);
    node.size.y = clamp(node.size.y, node.min_size.y, node.max_size.y);

    previous_scope_key := context.forbear.scope_key;
    context.forbear.parent_index = index;
    context.forbear.scope_key = node.key;

    if node.style.width.kind == Sizing.Kind.FIT {
        node.size.x = fitting_base(node, Direction.HORIZONTAL);
    }
    if node.style.width.kind != Sizing.Kind.FIXED && isnan(node.style.min_width) {
        node.min_size.x = fitting_base(node, Direction.HORIZONTAL);
    }
    if node.style.height.kind == Sizing.Kind.FIT {
        node.size.y = fitting_base(node, Direction.VERTICAL);
    }
    if node.style.height.kind != Sizing.Kind.FIXED && isnan(node.style.min_height) {
        node.min_size.y = fitting_base(node, Direction.VERTICAL);
    }
    // if (isNodeActive()) {
    //     setCursor(result.ptr.style.cursor);
    // }

    return Node_Opening_Data.{
        base_style = previous_base_style,
        scope_key = previous_scope_key,
        parent_index = previous_parent_index,
        node_index = index,
    };
}
close_element :: (using data: Node_Opening_Data) {
    node := *context.forbear.node_tree[node_index];
    node.size.x = clamp(node.size.x, node.min_size.x, node.max_size.x);
    node.size.y = clamp(node.size.y, node.min_size.y, node.max_size.y);

    measurement, defined := get_measurement();
    assert(
        !defined || node.state_size == measurement.state_size,
        "element called state() a different number of times than last frame"
    );

    context.forbear.parent_index = parent_index;
    context.forbear.scope_key = scope_key;
    context.forbear.base_style = base_style;
}
// API used when building UIs straight from jai
element :: (
    style := Style.{},
    manual_key := "",
    body: Code = #code {},
    location := #caller_location
) -> s64 #expand {
    key: u64;
    if manual_key.count > 0 {
        key = fnv1a_hash(manual_key.data, manual_key.count);
    } else {
        key = fnv1a_hash(*location, size_of(Source_Code_Location));
    }
    if context.forbear.scope_key != U64_MAX {
        key = fnv1a_hash(context.forbear.scope_key, key);
    }

    opening := open_element(style, key);
    #insert body;
    close_element(opening);
    return opening.node_index;
}
element :: (body: Code, location := #caller_location) -> s64 #expand {
    return element(Style.{}, "", body, location);
}
element :: (style: Style, body: Code, location := #caller_location) -> s64 #expand {
    return element(style, "", body, location);
}
// TODO: I dislike that this API is different from the open_element because it receives the caller location
// and is not really meant to be called by adapters.
//
// The main reason this exists is because there's a bug in the compiler where if you nest unbraced #code blocks
// you can loose access to locals of where the #code was defined and this is our workaround. :(
open_scope :: (manual_key := "", location := #caller_location) -> Node_Opening_Data {
    key: u64;
    if manual_key.count > 0 {
        key = fnv1a_hash(manual_key.data, manual_key.count);
    } else {
        key = fnv1a_hash(*location, size_of(Source_Code_Location));
    }
    if context.forbear.scope_key != U64_MAX {
        key = fnv1a_hash(context.forbear.scope_key, key);
    }

    parent_index := context.forbear.parent_index;
    index := context.forbear.node_tree.count;
    previous_parent_index := parent_index;
    previous_scope_key := context.forbear.scope_key;
    {
        node := Node.{
            parent = parent_index,
            tree = *context.forbear.node_tree,
        };
        node.kind = .SCOPE;
        node.key = key;
        array_add(*context.forbear.node_tree, node);
        context.forbear.parent_index = index;
        context.forbear.scope_key = key;
    }
    return .{
        parent_index = previous_parent_index,
        scope_key = previous_scope_key,
        node_index = index,
    };
}
close_scope :: (using opening_data: Node_Opening_Data, value: $T) -> T {
    measurement, defined := get_measurement(include_scopes = true);
    assert(
        !defined || context.forbear.node_tree[node_index].state_size == measurement.state_size,
        "scope called state() a different number of times than last frame"
    );

    context.forbear.parent_index = parent_index;
    context.forbear.scope_key    = scope_key;
    return value;
}
scope :: (manual_key: string, $body: Code = #code {}, location := #caller_location) -> body.type #expand {
    return close_scope(open_scope(manual_key, location), void);
}
scope :: ($body: Code, location := #caller_location) -> body.type #expand {
    return close_scope(open_scope(location = location), #insert body);
}

Glyph :: struct {
    index: s32;
    index_into_original_text: s64;
    utf8: kbts_encode_utf8;

    // all of these are in points units, that means they do not account for the font size, but they do account for the font weight.
    position: Vector2;
    // Meant for the recalculation of the glyphs position if that's required at some other layouting step
    advance: Vector2;
    // Meant for the recalculation of the glyphs position if that's required at some other layouting step
    offset: Vector2;
};
Glyphs :: struct {
    hash: u64;
    length: s32;
    array: [..]Glyph;
    pre_break_indices: [..]s64;

    //
    // all of the properties bellow are in font point units. this means they do not account for the font size, but they do account
    // for the font weight.
    //

    // Distance from line top to the shared baseline
    ascent: float;
    line_height: float;
    min_size: Vector2;
    max_size: Vector2;
};
Glyph_Atlas_Entry :: struct {
    bearing: Vector2;
    size:    Vector2;
    uv_min:  Vector2;
    uv_max:  Vector2;
};
// Shaping_Cache :: struct {
//     slots: [4096]Glyphs;
//     arena: Flat_Pool;
// };
Font :: struct {
    memory: string;

    raster_face: FT_Face;
    shaping_font: *kbts_font;
    key: u16;

    // kept track of so that this can be set during kbts text shaping
    weight: u16 = U16_MAX;

    // prev_cache: Shaping_Cache;
    // next_cache: Shaping_Cache;
};
create_font :: (memory: string) -> Font {
    #import "File";

    font: Font;
    font.memory = memory;
    return font;
}
// TOOD: handle errors for all of the freetype calls
init_font :: (using font: *Font) {
    if context.forbear.freetype_library == null {
        FT_Init_FreeType(*context.forbear.freetype_library);
        // TODO: implement subpixel font rendering and auto enable in lower DPI
        // environments to match browser behavior.
        //
        // FT_Library_SetLcdFilter(freetype_library, FT_LCD_FILTER_DEFAULT);
    }
    if context.forbear.shaping_context == null {
        context.forbear.shaping_context = kbts_CreateShapeContext(null, null);
    }
    FT_New_Memory_Face(context.forbear.freetype_library, memory.data, xx memory.count, 0, *raster_face);
    // TODO: judege if we should support more than unicode here
    assert(raster_face.charmap.encoding == FT_Encoding.UNICODE);
    font.key = context.forbear.font_counter;
    context.forbear.font_counter += 1;
    shaping_font = kbts_ShapePushFontFromMemory(context.forbear.shaping_context, memory.data, xx memory.count, 0);
}
Raster_Glyph :: struct {
    // might be null
    bitmap: string;
    left: s32;
    top: s32;
    width: u32;
    height: u32;
    pitch: s32;
};
set_weight :: (font: *Font, weight: u16) {
    // TODO: cache that this was already set so that we can avoid work
    mm: *FT_MM_Var;
    err := FT_Get_MM_Var(font.raster_face, *mm);
    if err == xx FT_Err.Invalid_Argument {
        log_error("cannot set weight - font does not support multiple masters. this is most likely not a variable font, doing nothing.");
        return;
    }
    defer FT_Done_MM_Var(context.forbear.freetype_library, mm);

    coords := NewArray(xx mm.num_axis, FT_Fixed);
    defer free(coords.data);
    FT_Get_Var_Design_Coordinates(font.raster_face, mm.num_axis, coords.data);

    for i: 0..mm.*.num_axis - 1 {
        a := *mm.*.axis[i];
        w: u64 = #char "w";
        g: u64 = #char "g";
        h: u64 = #char "h";
        t: u64 = #char "t";
        wght := (w << 24) | (g << 16) | (h << 8) | t;
        if a.tag == wght {
            coords[i] = xx clamp(cast(s64)weight * 65536, xx a.minimum, xx a.maximum);
            break;
        }
    }
    FT_Set_Var_Design_Coordinates(font.raster_face, mm.num_axis, coords.data);
    font.weight = weight;
}
set_font_size :: (font: *Font, size: u16) {
    // TODO: cache that this was already set so that we can avoid work
    FT_Set_Pixel_Sizes(font.raster_face, size, size);
}
round_font_size :: (size: float) -> u16 #expand {
   assert(size <= 0xFFFF, "font sizes need to be packed to u16");
   return xx floor(size + 0.5);
}
get_font_units_to_pixel :: (font: *Font, font_size: float) -> float {
    using context.forbear;
    scale             := cast(float) window.scale;
    rounded_font_size := round_font_size(font_size * scale);
    return (cast(float) rounded_font_size) / (cast(float) font.raster_face.units_per_EM) / scale;
}
font_raster_glyph :: (font: *Font, glyph_index: u16) -> Raster_Glyph {
    FT_LOAD_TARGET_LIGHT :: 1 << 16;
    FT_Load_Glyph(font.raster_face, xx glyph_index, FT_LOAD_RENDER | FT_LOAD_TARGET_LIGHT);
    glyph := font.raster_face.glyph;
    // FT_LOAD_RENDER already renders the glyph
    // FT_Render_Glyph(glyph, FT_Render_Mode.NORMAL);
    raster_glyph: Raster_Glyph;
    if glyph.bitmap.buffer != null {
        raster_glyph.bitmap.data = glyph.bitmap.buffer;
        raster_glyph.bitmap.count = xx (abs(glyph.bitmap.pitch) * xx glyph.bitmap.rows);
    }
    raster_glyph.width = glyph.bitmap.width;
    raster_glyph.height = glyph.bitmap.rows;
    raster_glyph.left = glyph.bitmap_left;
    raster_glyph.top = glyph.bitmap_top;
    raster_glyph.pitch = glyph.bitmap.pitch;
    return raster_glyph;
}
shape_text :: (font: *Font, text_wrapping: Text_Wrapping, content: string) -> Glyphs {
    // TODO(next): cache these shaped glyphs arrays for the given text so that we can reuse it in between frames
    glyphs: Glyphs;
    glyphs.line_height = cast(float) font.raster_face.height;
    glyphs.ascent = cast(float) font.raster_face.ascender;

    // TODO(next): pass the language and direction down as styles
    kbts_ShapeBegin(
        context.forbear.shaping_context,
        xx kbts_direction_enum.KBTS_DIRECTION_LTR,
        xx kbts_language_enum.KBTS_LANGUAGE_DONT_KNOW
    );
    WGHT : u32 : 0x77676874;
    if font.weight != U16_MAX {
        kbts_ShapePushGlobalVariation(context.forbear.shaping_context, WGHT, cast(float) font.weight);
    }
    kbts_ShapeUtf8(
        context.forbear.shaping_context,
        content.data,
        xx content.count,
        xx kbts_user_id_generation_mode_enum.KBTS_USER_ID_GENERATION_MODE_SOURCE_INDEX
    );
    if font.weight != U16_MAX {
        kbts_ShapePopGlobalVariation(context.forbear.shaping_context, WGHT);
    }
    kbts_ShapeEnd(context.forbear.shaping_context);

    run: kbts_run;
    pen: Vector2;
    // the advance local to this word
    word_advance: Vector2;
    while (kbts_ShapeRun(context.forbear.shaping_context, *run) != 0) {
        shaping_glyph: *kbts_glyph;
        while (kbts_GlyphIteratorNext(*run.Glyphs, *shaping_glyph) != 0) {
            shape_codepoint: kbts_shape_codepoint;
            if kbts_ShapeGetShapeCodepoint(context.forbear.shaping_context, shaping_glyph.UserIdOrCodepointIndex, *shape_codepoint) == 0 {
                log_error("Could not get original codeopint for glyph with user id %", shaping_glyph.UserIdOrCodepointIndex);
                continue;
            }

            utf8_encoded := kbts_EncodeUtf8(shape_codepoint.Codepoint);

            advance := Vector2.{ xx shaping_glyph.AdvanceX, xx shaping_glyph.AdvanceY };
            offset := Vector2.{ xx shaping_glyph.OffsetX, xx shaping_glyph.OffsetY };
            utf8: string;
            utf8.data = utf8_encoded.Encoded.data;
            utf8.count = utf8_encoded.EncodedLength;
            is_linebreak := starts_with(utf8, "\n");
            if is_linebreak {
                advance.x = -pen.x;
                advance.y += glyphs.line_height;
                array_add(*glyphs.pre_break_indices, glyphs.array.count);
            } else {
                glyph: Glyph;
                glyph.index = xx shaping_glyph.Id;
                glyph.advance = advance;
                glyph.offset = offset;
                glyph.position = pen + glyph.offset;
                glyph.utf8 = utf8_encoded;
                glyph.index_into_original_text = shape_codepoint.UserId;
                array_add(*glyphs.array, glyph);
            }

            pen += advance;
            glyphs.max_size.x = max(glyphs.max_size.x, pen.x);
            if text_wrapping == .WORD {
                if starts_with(utf8, " ") || is_linebreak {
                    word_advance = Vector2.{};
                    glyphs.max_size.y += glyphs.line_height;
                } else {
                    word_advance += advance;
                }
                glyphs.min_size.x = max(glyphs.min_size.x, word_advance.x);
            } else if text_wrapping == .CHARACTER {
                glyphs.min_size.x = max(glyphs.min_size.x, advance.x);
                glyphs.max_size.y += glyphs.line_height;
            } else if text_wrapping == .NONE {
                glyphs.min_size.x = max(glyphs.min_size.x, pen.x);
            }
        }
    }
    glyphs.min_size.y = pen.y + glyphs.line_height;
    glyphs.max_size.y = max(glyphs.min_size.y, glyphs.max_size.y);

    return glyphs;
}
free_font :: (font: *Font) {
    // TODO: should we delete this function?
    FT_Done_Face(font.raster_face);
}
// TODO: Support receiving any number of arguments that are passed down to sprint to then be rendered into text.
// TODO: Support building multiple text runs for the same node's glyphs. This is quite important for text-heavy applications might have, say, emphasis on text.
text :: (style := Style.{}, content := "", manual_key := "", location := #caller_location) -> s64 #expand {
    return element(style, manual_key, #code {
        node := *context.forbear.node_tree[context.forbear.node_tree.count - 1];
        rounded_font_size := round_font_size(node.style.font_size * (cast(float) context.forbear.window.scale));
        set_weight(node.style.font, node.style.font_weight);
        set_font_size(node.style.font, rounded_font_size);
        node.glyphs = shape_text(node.style.font, node.style.text_wrapping, content);
        font_units_to_point := get_font_units_to_pixel(node.style.font, node.style.font_size);
        node.size = Vector2.{node.glyphs.max_size.x, node.glyphs.min_size.y} * font_units_to_point;
        node.min_size = node.glyphs.min_size * font_units_to_point;
        node.max_size = node.glyphs.max_size * font_units_to_point;

        if node.parent != -1 {
            parent := context.forbear.node_tree[node.parent];
            if parent.style.cursor == .DEFAULT {
                node.style.cursor = .TEXT;
            }
            node.style.x_justification = parent.style.x_justification;
            node.style.y_justification = parent.style.y_justification;
        }
    }, location);
}
text :: (content: string, manual_key := "", location := #caller_location) -> s64 #expand {
    return text(Style.{}, content, "", location);
}
Glyph_Atlas :: struct {
    // TODO: change this based on the render API that's selected. currently we only support OpenGL, though.
    texture: u32;
    table: Table(u64, Glyph_Atlas_Entry);

    cursor_x: s32;
    cursor_y: s32;
    row_height: s32;
    size: s32 = INITIAL_SIZE;

    PADDING :: 1;
    INITIAL_SIZE :: 1024;
    MAX_SIZE :: 4096;
};
glyph_atlas_key :: (font: *Font, glyph_index: u16, size: u16, weight: u16) -> u64 {
    key := (cast(u64) font.key) << 48;
    key |= (cast(u64) glyph_index) << 32;
    key |= (cast(u64) size) << 16;
    key |= (cast(u64) weight);
    return key;
}
glyph_atlas_place :: (glyph_atlas: *Glyph_Atlas, width: s32, height: s32) -> x: s32, y: s32, ok: bool {
    using glyph_atlas;
    if cursor_x + width + PADDING > size {
        cursor_x = 0;
        cursor_y += row_height + PADDING;
        row_height = 0;
    }
    if cursor_y + height + PADDING > size {
        return 0, 0, false;
    }

    x, y := cursor_x, cursor_y;
    cursor_x += width + PADDING;
    row_height = max(row_height, height);
    return x, y, true;
}
glyph_atlas_reset :: (glyph_atlas: *Glyph_Atlas) {
    using glyph_atlas;
    table_reset(*table);
    cursor_x = 0;
    cursor_y = 0;
    row_height = 0;
}
// doubles the size of the atlas, throwing away everything that was in it
glyph_atlas_grow :: (glyph_atlas: *Glyph_Atlas) -> bool {
    using glyph_atlas;
    if size * 2 > MAX_SIZE  return false;

    size *= 2;
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, xx GL_R8, xx size, xx size, 0, GL_RED, GL_UNSIGNED_BYTE, null);
    glyph_atlas_reset(glyph_atlas);
    return true;
}
// rasters every glyph in the node tree that isn't in the atlas yet, returns false if the atlas got full before
// all of them could be placed
glyph_atlas_fill :: () -> bool {
    using context.forbear;
    for node: node_tree if node.kind == .ELEMENT && node.glyphs.array.count != 0 {
        rounded_font_size := round_font_size(node.style.font_size * (cast(float) window.scale));
        for glyph: node.glyphs.array {
            atlas_key := glyph_atlas_key(node.style.font, xx glyph.index, rounded_font_size, node.style.font_weight);
            if table_find_pointer(*glyph_atlas.table, atlas_key) != null  continue;

            set_weight(node.style.font, node.style.font_weight);
            set_font_size(node.style.font, rounded_font_size);
            raster := font_raster_glyph(node.style.font, xx glyph.index);
            x, y, ok := glyph_atlas_place(*glyph_atlas, xx raster.width, xx raster.height);
            if !ok  return false;

            if raster.bitmap.data != null {
                glBindTexture(GL_TEXTURE_2D, glyph_atlas.texture);
                glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
                glPixelStorei(GL_UNPACK_ROW_LENGTH, raster.pitch);
                glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, raster.width, raster.height, GL_RED, GL_UNSIGNED_BYTE, raster.bitmap.data);
                glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
            }

            new_entry: Glyph_Atlas_Entry;
            new_entry.bearing = .{ xx raster.left, xx -raster.top };
            new_entry.size    = .{ xx raster.width, xx raster.height };
            new_entry.uv_min  = .{
                x = x / (cast(float) glyph_atlas.size),
                y = y / (cast(float) glyph_atlas.size)
            };
            new_entry.uv_max  = .{
                x = ((cast(float)x) + (cast(float)raster.width)) / (cast(float) glyph_atlas.size),
                y = ((cast(float)y) + (cast(float)raster.height)) / (cast(float) glyph_atlas.size)
            };
            table_add(*glyph_atlas.table, atlas_key, new_entry);
        }
    }
    return true;
}

static_state_buffers: [2][16 * 1024 * 1024]u8 #align 16;
Forbear :: struct {
    node_tree: Node_Tree;
    measurements: [..]Node_Measurement;

    frame: s64;
    delta_time: float;
    last_frame_time: float64;
    persistent_allocator: Allocator;

    parent_index: s64 = -1;
    state_buffers := *static_state_buffers;
    pool_slots: [256]Pool_Slot;
    scope_key: u64 = U64_MAX;
    base_style: Base_Style;
    font_counter: u16;
    state_current: s64;
    state_used: s64;
    freetype_library: FT_Library;
    shaping_context: *kbts_shape_context;

    shader_program: u32;
    shader_vao: u32;
    node_vbo: u32;
    glyph_atlas: Glyph_Atlas;

    // TODO: we're going to have to change this once we support multiple windows
    // Perhaps we can have a Window_Manager struct that can keep track of multiple windows,
    // and give one specific window back.
    window: *Window;
    backend: *Backend;
};
#add_context forbear: *Forbear;
init_forbear :: (
    forbear: *Forbear,
    program_window: *Window,
    // TOOD: currently we're defining the specific backend names to be just one here, but in the long-term we will include
    // multiple backends for each operating system, not one, so we need to handle that in a better way.
    program_backend: *Backend,
    program_base_style: Base_Style,
) {
    using forbear;
    context.forbear = forbear;

    forbear.window = program_window;
    forbear.persistent_allocator = context.allocator;
    forbear.glyph_atlas.table.allocator = forbear.persistent_allocator;
    forbear.node_tree.allocator = forbear.persistent_allocator;
    forbear.measurements.allocator = forbear.persistent_allocator;

    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

    //
    // ==== node rendering setup ====
    //
    glGenVertexArrays(1, *shader_vao);
    glBindVertexArray(shader_vao);
    glGenBuffers(1, *node_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, node_vbo);

    stride :: size_of(Draw_Instance);
    // position
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, stride, cast(*void) 0);
    glVertexAttribDivisor(0, 1);

    // size
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, stride, cast(*void) 8);
    glVertexAttribDivisor(1, 1);

    // color
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 4, GL_FLOAT, GL_FALSE, stride, cast(*void) 16);
    glVertexAttribDivisor(2, 1);

    // border_width
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(3, 4, GL_FLOAT, GL_FALSE, stride, cast(*void) 32);
    glVertexAttribDivisor(3, 1);

    // border_color
    glEnableVertexAttribArray(4);
    glVertexAttribPointer(4, 4, GL_FLOAT, GL_FALSE, stride, cast(*void) 48);
    glVertexAttribDivisor(4, 1);

    // border_radius
    glEnableVertexAttribArray(5);
    glVertexAttribPointer(5, 1, GL_FLOAT, GL_FALSE, stride, cast(*void) 64);
    glVertexAttribDivisor(5, 1);

    // uv_min
    glEnableVertexAttribArray(6);
    glVertexAttribPointer(6, 2, GL_FLOAT, GL_FALSE, stride, cast(*void) 68);
    glVertexAttribDivisor(6, 1);

    // uv_max
    glEnableVertexAttribArray(7);
    glVertexAttribPointer(7, 2, GL_FLOAT, GL_FALSE, stride, cast(*void) 76);
    glVertexAttribDivisor(7, 1);

    // kind
    glEnableVertexAttribArray(8);
    glVertexAttribIPointer(8, 1, GL_UNSIGNED_INT, stride, cast(*void) 84);
    glVertexAttribDivisor(8, 1);

    //
    // === node shaders ===
    //
    vertex_shader := compile_shader(GL_VERTEX_SHADER, #string GLSL
        #version 330 core
        layout(location = 0) in vec2 position;
        layout(location = 1) in vec2 size;
        layout(location = 2) in vec4 color;
        layout(location = 3) in vec4 border_width;
        layout(location = 4) in vec4 border_color;
        layout(location = 5) in float border_radius;
        layout(location = 6) in vec2 uv_min;
        layout(location = 7) in vec2 uv_max;
        layout(location = 8) in uint kind;

        uniform vec2 viewport;

        out vec2 v_position;
        out vec2 v_size;
        out vec4 v_color;
        out vec4 v_border_width;
        out vec4 v_border_color;
        out float v_border_radius;
        out vec2 v_uv;
        flat out uint v_kind;

        const vec2 corners[6] = vec2[](
          vec2(0, 0), vec2(1, 0), vec2(0, 1),
          vec2(0, 1), vec2(1, 0), vec2(1, 1)
        );

        void main() {
            vec2 corner = corners[gl_VertexID];
            v_position = corner * size.xy;
            v_size = size.xy;
            v_color = vec4(color.rgb * color.a, color.a);
            v_border_width = border_width;
            v_border_color = vec4(border_color.rgb * border_color.a, border_color.a);
            v_border_radius = border_radius;
            v_uv = mix(uv_min, uv_max, corner);
            v_kind = kind;

            gl_Position = vec4((position.xy + corner * size.xy) / viewport * 2.0 - 1.0, 0.0, 1.0);
            gl_Position.y = -gl_Position.y;
        }
GLSL);
    defer glDeleteShader(vertex_shader);
    fragment_shader := compile_shader(GL_FRAGMENT_SHADER, #string GLSL
        #version 330 core

        in vec2 v_position;
        in vec2 v_size;
        in vec4 v_color;
        in vec4 v_border_width;
        in vec4 v_border_color;
        in float v_border_radius;
        in vec2 v_uv;
        flat in uint v_kind;

        uniform sampler2D atlas;

        out vec4 out_color;

        void main() {
            if (v_kind == 1u) {
                out_color = v_color;

                vec2 p = v_position - v_size / 2.0;
                vec2 q = abs(p);
                vec2 circle_center = v_size / 2.0 - v_border_radius;

                float horizontal_width = p.x < 0.0 ? v_border_width.x : v_border_width.y;
                float vertical_width = p.y < 0.0 ? v_border_width.z : v_border_width.w;

                float ellipse_radius_a = max(v_border_radius - horizontal_width, 0);
                float ellipse_radius_b = max(v_border_radius - vertical_width, 0);

                vec2 d = q - circle_center;
                float outer_border_distance = length(d) - v_border_radius;
                float outer_border_coverage = clamp(0.5 - outer_border_distance / fwidth(outer_border_distance), 0.0, 1.0);

                vec2 e = vec2(0.0);
                if (ellipse_radius_a != 0 && ellipse_radius_b != 0) {
                    e = d / vec2(ellipse_radius_a, ellipse_radius_b);
                }
                float inner_border_distance = length(e) - 1;
                float inner_border_coverage = clamp(0.5 - inner_border_distance / fwidth(inner_border_distance), 0.0, 1.0);

                if (d.x > 0.0 && d.y > 0.0) {
                    if (ellipse_radius_a != 0 && ellipse_radius_b != 0) {
                        out_color = mix(v_border_color, v_color, inner_border_coverage);
                    } else {
                        out_color = v_border_color;
                    }

                    out_color *= outer_border_coverage;
                } else {
                    float to_left = v_position.x;
                    float to_top = v_position.y;
                    float to_right = v_size.x - v_position.x;
                    float to_bottom = v_size.y - v_position.y;
                    if (to_left <= v_border_width.x || to_right <= v_border_width.y ||
                        to_top <= v_border_width.z || to_bottom <= v_border_width.w) {
                        out_color = v_border_color;
                    }
                }
            } else if (v_kind == 2u) {
                // TODO: handle subpixel rendering
                out_color = v_color * texture(atlas, v_uv).r;
            }
        }
GLSL);
    defer glDeleteShader(fragment_shader);

    shader_program = glCreateProgram();
    glAttachShader(shader_program, vertex_shader);
    glAttachShader(shader_program, fragment_shader);
    glLinkProgram(shader_program);

    status: GLint;
    glGetProgramiv(shader_program, GL_LINK_STATUS, *status);
    if !status {
        log: [1024]u8;
        log_length: GLsizei;
        glGetProgramInfoLog(shader_program, log.count, *log_length, log.data);
        log_error("failed to link program: %\n", to_string(log.data, log_length));
        exit(-1);
    }

    glGenTextures(1, *glyph_atlas.texture);
    glBindTexture(GL_TEXTURE_2D, glyph_atlas.texture);
    // TOOD: keep track of whether subpixel rendering is enabled to create the texture atlas here accordingly
    glTexImage2D(GL_TEXTURE_2D, 0, xx GL_R8, xx glyph_atlas.size, xx glyph_atlas.size, 0, GL_RED, GL_UNSIGNED_BYTE, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    backend = program_backend;
    base_style = program_base_style;
}

//
// ======== frame lifecycle functions ========
//

// layouting is completely dependent on the fact that the children are appended in in the order of parent -> children, if
// we ever change that, layouting completely changes too, at least in the way it traverses things, but the core algorithms
// will remain.
//
// heavily inspired by Clay distrubuted under the zlib/libpng license:
// - https://github.com/nicbarker/clay
// - https://www.clay.com/
// - https://www.youtube.com/watch?v=by9lQvpvMIc
layout :: () {
    using context.forbear;
    if node_tree.count > 0 {
        fit_child :: (node: *Node, child: *Node, fit_direction: Direction) {
            preferred_size := get_preferred_size(node, fit_direction);
            child_margin_vector := get(child.style.margin, fit_direction);
            child_margins := child_margin_vector.x + child_margin_vector.y;

            child_size := get(child.size, fit_direction);
            child_min_size := get(child.min_size, fit_direction);
            child_size_contribution := child_margins + child_size;
            child_min_size_contribution := child_margins + ifx fit_direction == .VERTICAL && preferred_size.kind != .GROW then
                max(child_size, child_min_size)
            else
                child_min_size;

            should_accumulate := preferred_size.kind == .FIT || preferred_size.kind == .GROW;

            if node.style.direction == fit_direction {
                if preferred_size.kind == .FIT {
                    add(*node.size, fit_direction, child_size_contribution);
                } else if preferred_size.kind == .GROW {
                    // TODO: ensure the max and min sizes here
                    if fit_direction == .HORIZONTAL {
                        node.size.x = max(node.size.x, child_size_contribution + fitting_base(node, .HORIZONTAL));
                    } else {
                        node.size.y = max(node.size.y, child_size_contribution + fitting_base(node, .VERTICAL));
                    }
                }
                if should_fit_min(node, fit_direction) {
                    add(*node.min_size, fit_direction, child_min_size_contribution);
                }
            } else {
                // cross axis fitting
                if should_accumulate {
                    // TODO: ensure the max and min sizes here
                    set(
                        *node.size,
                        fit_direction,
                        max(
                            child_size_contribution + fitting_base(node, fit_direction),
                            get(node.size, fit_direction)
                        )
                    );
                }
                if should_fit_min(node, fit_direction) {
                    set(*node.min_size, fit_direction, max(
                        child_min_size_contribution + fitting_base(node, fit_direction),
                        get(node.min_size, fit_direction),
                    ));
                }
            }
        }

        {
            //
            // ==== fitting nodes ====
            //
            for <*node: node_tree if node.kind == .ELEMENT && node.first_child != -1 && node.glyphs.array.count == 0 {
                if node.style.width.kind == .FIT {
                    node.size.x = fitting_base(node, .HORIZONTAL);
                }
                if isnan(node.style.min_width) && node.style.width.kind != .FIXED {
                    node.min_size.x = fitting_base(node, .HORIZONTAL);
                }
                if node.style.height.kind == .FIT {
                    node.size.y = fitting_base(node, .VERTICAL);
                }
                if isnan(node.style.min_height) && node.style.height.kind != .FIXED {
                    node.min_size.y = fitting_base(node, .VERTICAL);
                }
                child_index := node.first_child;
                while child_index != -1 {
                    child := *node_tree[child_index];
                    defer child_index = child.next_sibling;
                    if child.style.placement.kind == .FLOW &&
                    (node.style.width.kind == .FIT || node.style.width.kind == .GROW ||
                    should_fit_min(node, .HORIZONTAL) || node.style.height.kind == .FIT ||
                    node.style.height.kind == .GROW || should_fit_min(node, .VERTICAL)) {
                        fit_child(node, child, .HORIZONTAL);
                        fit_child(node, child, .VERTICAL);
                    }
                }
                clamp(*node.size, node.min_size, node.max_size);
            }
        }

        EPSILON :: 0.001;
        approximately_equal :: (a: float, b: float) -> bool {
            return abs(a - b) < EPSILON;
        }

        {
            //
            // ==== growing and shrinking nodes ====
            //
            changing: [..]*Node;
            for *node: node_tree if node.kind == .ELEMENT {
                if node.parent == -1 {
                    if node.style.width.kind == .GROW {
                        node.size.x = (cast(float) window.width) / (cast(float) window.scale);
                    }
                    if node.style.height.kind == .GROW {
                        node.size.y = (cast(float) window.height) / (cast(float) window.scale);
                    }
                }
                if node.first_child != -1 && node.glyphs.array.count == 0 {
                    array_reset_keeping_memory(*changing);
                    layout_direction := node.style.direction;
                    opposite_direction := opposite(layout_direction);
                    // this value is only the initial one, it's modified during the iteration over the children that follows
                    remaining := inner_size(node, layout_direction);

                    // this grows the children of this node. we need to do three visits here:
                    // 1) grow the children on the opposite axis of the layout direction (Style.direction)
                    // 2) iteratively grow the children equally in the layout direciton
                    // 3) iteratively shrink the children equally in the layout direction
                    child_index := node.first_child;
                    {
                        //
                        // === growing the children ===
                        //
                        while child_index != -1 {
                            child := *node_tree[child_index];
                            defer child_index = child.next_sibling;

                            child.min_size = min(child.min_size, child.max_size);

                            {
                                //
                                // == cross-axis growth ==
                                //
                                child_opposite_margin := get(child.style.margin, opposite_direction);
                                available := get(node.size, opposite_direction)
                                    - fitting_base(node, opposite_direction)
                                    - child_opposite_margin.x - child_opposite_margin.y;
                                preferred_size := get_preferred_size(child, opposite_direction);
                                size := get(child.size, opposite_direction);
                                min_size := get(child.min_size, opposite_direction);
                                max_size := get(child.max_size, opposite_direction);
                                if preferred_size.kind == .GROW ||
                                    (child.style.placement.kind == .FLOW &&
                                    size > available && min_size < size) {
                                    set(*child.size, opposite_direction, clamp(
                                        available, min_size, max_size
                                    ));
                                }
                            }

                            preferred_size := get_preferred_size(child, layout_direction);
                            child_margin := get(child.style.margin, layout_direction);

                            if (child.style.placement.kind == .RELATIVE || child.style.placement.kind == .FIXED)
                                && preferred_size.kind == .GROW {
                                // growing child that's placed RELATIVE or FIXED will have a size based on the parent solely without considering its
                                // siblings.
                                available := inner_size(node, layout_direction) - child_margin.x - child_margin.y;
                                set(*child.size, layout_direction, clamp(
                                    available,
                                    get(child.min_size, layout_direction),
                                    get(child.max_size, layout_direction),
                                ));
                            } else if child.style.placement.kind == .FLOW {
                                if preferred_size.kind == .GROW && preferred_size.grow > 0.0 {
                                    // we reset the size of the node to 0 so that the division is fair later
                                    set(*child.size, layout_direction, 0);
                                    if get(child.max_size, layout_direction) > 0 {
                                        array_add(*changing, child);
                                    }
                                }
                                remaining -= outer_size(child, layout_direction);
                            }
                        }

                        child_index = node.first_child;
                        // grow the children equally in the layout direciton
                        while remaining > EPSILON && changing.count > 0 {
                            total_factor: float = 0.0;
                            max_to_add: float = FLOAT32_INFINITY;
                            index: s64 = 0;
                            while index < changing.count {
                                child := changing[index];
                                max_size := get(child.max_size, layout_direction);
                                size := get(child.size, layout_direction);
                                if approximately_equal(size, max_size) {
                                    array_unordered_remove_by_index(*changing, index);
                                    // since the remove moves another child over to this same index, we go to the next iteration with the same index
                                    continue;
                                }
                                preferred_size := get_preferred_size(child, layout_direction);
                                total_factor += preferred_size.grow;
                                max_to_add = min(max_to_add, (max_size - size) / preferred_size.grow);

                                index += 1;
                            }

                            if changing.count > 0 && total_factor > 0 {
                                to_add := min(max_to_add, remaining / total_factor);
                                if to_add > 0.0 {
                                    remaining_before_loop := remaining;
                                    for child: changing {
                                        preferred_size := get_preferred_size(child, layout_direction);
                                        size := get(child.size, layout_direction);
                                        min_size := get(child.min_size, layout_direction);
                                        max_size := get(child.max_size, layout_direction);
                                        clamp_addendum := clamp(size + to_add * preferred_size.grow, min_size, max_size) - size;
                                        add(*child.size, layout_direction, clamp_addendum);
                                        remaining -= clamp_addendum;
                                    }
                                    if approximately_equal(remaining, remaining_before_loop) {
                                        // this means there's a max size constraint that doesn't let more size be added to any of the children
                                        break;
                                    }
                                } else {
                                    break;
                                }
                            } else if total_factor == 0 {
                                break;
                            }
                        }
                    }


                    if remaining < -EPSILON {
                        //
                        // === nodes shrinking ===
                        //
                        // we shrink children so that nodes don't overflow the parent, but fit to the largest size possible that's bigger than
                        // their minimum size
                        array_reset_keeping_memory(*changing);
                        child_index = node.first_child;
                        while child_index != -1 {
                            child := *node_tree[child_index];
                            defer child_index = child.next_sibling;
                            if child.style.placement.kind == .FLOW &&
                                get(child.size, layout_direction) > get(child.min_size, layout_direction) {
                                array_add(*changing, child);
                            }
                        }
                        while remaining < -EPSILON && changing.count > 0 {
                            largest := get(changing[0].size, layout_direction);
                            second_largest: float = 0.0;
                            index := 0;
                            while index < changing.count {
                                child := changing[index];
                                size := get(child.size, layout_direction);
                                min_size := get(child.min_size, layout_direction);
                                if approximately_equal(size, min_size) {
                                    array_unordered_remove_by_index(*changing, index);
                                    if index == 0 && changing.count > 0 {
                                        largest = get(changing[0].size, layout_direction);
                                    }
                                    // since the remove moves another child over to this same index, we go to the next iteration with the same index
                                    continue;
                                }
                                if size > largest {
                                    largest = size;
                                } else if size > second_largest {
                                    second_largest = size;
                                }
                                index += 1;
                            }
                            if changing.count > 0 {
                                to_subtract := min(
                                    largest - second_largest,
                                    -remaining / cast(float)changing.count,
                                );
                                if to_subtract == 0 {
                                    to_subtract = -remaining / cast(float)changing.count;
                                }
                                remaining_before_loop := remaining;
                                for child: changing {
                                    old_size := get(child.size, layout_direction);
                                    if approximately_equal(old_size, largest) {
                                        min_size := get(child.min_size, layout_direction);
                                        clamped_reduction := max(old_size - to_subtract, min_size) - old_size;
                                        add(*child.size, layout_direction, clamped_reduction);
                                        remaining -= clamped_reduction;
                                    }
                                }
                                if approximately_equal(remaining, remaining_before_loop) {
                                    break;
                                }
                            } else {
                                break;
                            }
                        }
                    }
                }
            }
        }

        {
            //
            // ==== wrapping glyphs ====
            //
            for <*node: node_tree if node.kind == .ELEMENT {
                font_units_to_point := get_font_units_to_pixel(node.style.font, node.style.font_size);
                base := Vector2.{
                    node.style.border_width.x.x + node.style.padding.x.x,
                    node.style.border_width.y.x + node.style.padding.y.x,
                } / font_units_to_point;

                if node.glyphs.array.count > 0 && node.style.text_wrapping != .NONE {
                    using node.glyphs;

                    Line :: struct {
                        start: s64;
                        end: s64;
                    }
                    lines: [..]Line;
                    line_end := (node.size.x - fitting_base(node, .HORIZONTAL)) / font_units_to_point;
                    pen: Vector2;
                    line_start_index: s64 = 0;

                    break_cursor: s64 = 0;

                    if node.style.text_wrapping == {
                        case .CHARACTER;
                            for *glyph: array {
                                while break_cursor < pre_break_indices.count &&
                                    pre_break_indices[break_cursor] == it_index {
                                    defer break_cursor += 1;
                                    if it_index > line_start_index {
                                        array_add(*lines, Line.{
                                            start = line_start_index,
                                            end = it_index - 1,
                                        });
                                    }
                                    line_start_index = it_index;
                                    pen.x = 0.0;
                                    pen.y += line_height;
                                }

                                if pen.x + glyph.advance.x > line_end && it_index > line_start_index {
                                    array_add(*lines, .{
                                        start = line_start_index,
                                        end = it_index - 1,
                                    });
                                    line_start_index = it_index;
                                    pen.x = 0.0;
                                    pen.y += line_height;
                                }

                                glyph.position = base + pen + glyph.offset;
                                pen += glyph.advance;
                            }
                        case .WORD;
                            Space :: struct {
                                index: s64 = -1;
                                position: Vector2;
                            }
                            last_space: Space;
                            for *glyph: array {
                                while break_cursor < pre_break_indices.count &&
                                pre_break_indices[break_cursor] == it_index {
                                    defer break_cursor += 1;
                                    if it_index > line_start_index {
                                        array_add(*lines, Line.{
                                            start = line_start_index,
                                            end = it_index - 1,
                                        });
                                    }
                                    line_start_index = it_index;
                                    pen.x = 0.0;
                                    pen.y += line_height;
                                    last_space = Space.{};
                                }

                                if pen.x + glyph.advance.x > line_end && last_space.index != -1 {
                                    first_word_glyph := array[last_space.index + 1];
                                    array_add(*lines, Line.{
                                        start = line_start_index,
                                        end = last_space.index,
                                    });
                                    line_start_index = last_space.index + 1;
                                    pen.x = 0.0;
                                    pen.y += line_height;

                                    for reverse_index: (last_space.index + 1)..(it_index - 1) {
                                        reverse_glyph := *array[reverse_index];
                                        reverse_glyph.position.x -= first_word_glyph.position.x - base.x;
                                        reverse_glyph.position.y += line_height;

                                        pen += reverse_glyph.advance;
                                    }
                                    last_space = Space.{};
                                }

                                glyph.position = base + pen + glyph.offset;
                                pen += glyph.advance;
                                if starts_with(to_string(glyph.utf8.Encoded), " ") {
                                    last_space = Space.{
                                        index = it_index,
                                        position = glyph.position,
                                    };
                                }
                            }
                    }

                    while break_cursor < pre_break_indices.count {
                        pen.y += line_height;
                        break_cursor += 1;
                    }

                    if array.count > 0 {
                        if lines.count > 0 {
                            last_line := lines[lines.count - 1];
                            if last_line.end != array.count - 1 {
                                array_add(*lines, Line.{
                                    start = last_line.end + 1,
                                    end = array.count - 1,
                                });
                            }
                        } else {
                            array_add(*lines, Line.{
                                start = 0,
                                end = array.count - 1,
                            });
                        }
                    }
                    for line: lines {
                        start_x := array[line.start].position.x;
                        end_x := array[line.end].position.x + array[line.end].advance.x;

                        width := end_x - start_x;
                        line_glyphs := array_view(array, line.start, line.end + 1);
                        for *glyph: line_glyphs {
                            if node.style.x_justification == {
                                case .START;
                                case .CENTER;
                                    glyph.position.x += (line_end - width) / 2.0;
                                case .END;
                                    glyph.position.x += line_end - width;
                            }
                        }
                    }
                    node.size.y = (pen.y + line_height) * font_units_to_point;
                }
            }
        }

        {
            //
            // ==== refit heights ====
            //
            for <*node: node_tree if node.kind == .ELEMENT {
                if node.first_child != -1 && node.glyphs.array.count == 0 {
                    if node.style.height.kind == .FIT {
                        node.size.y = fitting_base(node, .VERTICAL);
                    }
                    if isnan(node.style.min_height) && node.style.height.kind != .FIXED {
                        node.min_size.y = fitting_base(node, .VERTICAL);
                    }
                    child_index := node.first_child;
                    while child_index != -1 {
                        child := *node_tree[child_index];
                        defer child_index = child.next_sibling;
                        if child.style.placement.kind == .FLOW && (node.style.height.kind == .FIT || node.style.height.kind == .GROW || should_fit_min(node, .VERTICAL)) {
                            fit_child(node, child, .VERTICAL);
                        }
                    }
                }
            }
        }

        {
            //
            // ==== regrowing nodes veritcally ====
            //
            changing: [..]*Node;
            for *node: node_tree if node.kind == .ELEMENT {
                if node.parent == -1 {
                    if node.style.height.kind == .GROW {
                        node.size.y = (cast(float) window.height) / (cast(float) window.scale);
                    }
                }
                if node.first_child != -1 && node.glyphs.array.count == 0 {
                    array_reset_keeping_memory(*changing);
                    layout_direction := node.style.direction;
                    opposite_direction := opposite(layout_direction);
                    // this value is only the initial one, it's modified during the iteration over the children that follows
                    remaining := inner_size(node, layout_direction);

                    // this grows the children of this node. we need to do three visits here:
                    // 1) grow the children on the opposite axis of the layout direction (Style.direction)
                    // 2) iteratively grow the children equally in the layout direciton
                    // 3) iteratively shrink the children equally in the layout direction
                    child_index := node.first_child;
                    {
                        //
                        // === growing the children ===
                        //
                        while child_index != -1 {
                            child := *node_tree[child_index];
                            defer child_index = child.next_sibling;

                            child.min_size = min(child.min_size, child.max_size);

                            if opposite_direction == .VERTICAL {
                                //
                                // == cross-axis growth ==
                                //
                                child_opposite_margin := get(child.style.margin, opposite_direction);
                                available := get(node.size, opposite_direction)
                                    - fitting_base(node, opposite_direction)
                                    - child_opposite_margin.x - child_opposite_margin.y;
                                preferred_size := get_preferred_size(child, opposite_direction);
                                size := get(child.size, opposite_direction);
                                min_size := get(child.min_size, opposite_direction);
                                max_size := get(child.max_size, opposite_direction);
                                if preferred_size.kind == .GROW ||
                                    (child.style.placement.kind == .FLOW &&
                                    size > available && min_size < size) {
                                    set(*child.size, opposite_direction, clamp(
                                        available, min_size, max_size
                                    ));
                                }
                            }

                            if layout_direction == .VERTICAL {
                                preferred_size := get_preferred_size(child, layout_direction);
                                child_margin := get(child.style.margin, layout_direction);

                                if (child.style.placement.kind == .RELATIVE || child.style.placement.kind == .FIXED)
                                    && preferred_size.kind == .GROW {
                                    // growing child that's placed RELATIVE or FIXED will have a size based on the parent solely without considering its
                                    // siblings.
                                    available := inner_size(node, layout_direction) - child_margin.x - child_margin.y;
                                    set(*child.size, layout_direction, clamp(
                                        available,
                                        get(child.min_size, layout_direction),
                                        get(child.max_size, layout_direction),
                                    ));
                                } else if child.style.placement.kind == .FLOW {
                                    if preferred_size.kind == .GROW && preferred_size.grow > 0.0 {
                                        // we reset the size of the node to 0 so that the division is fair later
                                        set(*child.size, layout_direction, 0);
                                        if get(child.max_size, layout_direction) > 0 {
                                            array_add(*changing, child);
                                        }
                                    }
                                    remaining -= outer_size(child, layout_direction);
                                }
                            }
                        }

                        if layout_direction == .VERTICAL {
                            child_index = node.first_child;
                            // grow the children equally in the layout direciton
                            while remaining > EPSILON && changing.count > 0 {
                                total_factor: float = 0.0;
                                max_to_add: float = FLOAT32_INFINITY;
                                index: s64 = 0;
                                while index < changing.count {
                                    child := changing[index];
                                    max_size := get(child.max_size, layout_direction);
                                    size := get(child.size, layout_direction);
                                    if approximately_equal(size, max_size) {
                                        array_unordered_remove_by_index(*changing, index);
                                        // since the remove moves another child over to this same index, we go to the next iteration with the same index
                                        continue;
                                    }
                                    preferred_size := get_preferred_size(child, layout_direction);
                                    total_factor += preferred_size.grow;
                                    max_to_add = min(max_to_add, (max_size - size) / preferred_size.grow);

                                    index += 1;
                                }

                                if changing.count > 0 && total_factor > 0 {
                                    to_add := min(max_to_add, remaining / total_factor);
                                    if to_add > 0.0 {
                                        remaining_before_loop := remaining;
                                        for child: changing {
                                            preferred_size := get_preferred_size(child, layout_direction);
                                            size := get(child.size, layout_direction);
                                            min_size := get(child.min_size, layout_direction);
                                            max_size := get(child.max_size, layout_direction);
                                            clamp_addendum := clamp(size + to_add * preferred_size.grow, min_size, max_size) - size;
                                            add(*child.size, layout_direction, clamp_addendum);
                                            remaining -= clamp_addendum;
                                        }
                                        if approximately_equal(remaining, remaining_before_loop) {
                                            // this means there's a max size constraint that doesn't let more size be added to any of the children
                                            break;
                                        }
                                    } else {
                                        break;
                                    }
                                } else if total_factor == 0 {
                                    break;
                                }
                            }
                        }
                    }
                    // TODO: should we shrink nodes here again? if we indeed decide to do this, the min sizes for
                    // wrapped text should also change, otherwise this will reduce the wrapped text's height again after
                    // it wrapped and increased.
                }
            }
        }

        {
            //
            // === place nodes and justifying them in both directions ===
            //
            for *node: node_tree if node.kind == .ELEMENT {
                if node.parent == -1 {
                    if node.style.placement.kind == {
                        case .FLOW;
                            node.position = node.style.translate;
                            node.position.x += node.style.margin.x.x;
                            node.position.y += node.style.margin.y.x;
                        case .FIXED;
                            node.position = node.style.placement.fixed + node.style.translate;
                        case .RELATIVE;
                            node.position = node.style.placement.relative + node.style.translate;
                            node.position.x += node.style.margin.x.x;
                            node.position.y += node.style.margin.y.x;
                    }
                }
                if node.first_child != -1 {
                    base := node.position + Vector2.{
                        node.style.border_width.x.x + node.style.padding.x.x,
                        node.style.border_width.y.x + node.style.padding.y.x,
                    };

                    // TODO: when the direction is horizontal, we should also handle node overflow wrapping here.
                    pen := base;
                    direction := node.style.direction;
                    opposite_direction := opposite(node.style.direction);

                    child_index := node.first_child;
                    while child_index != -1 {
                        child := *node_tree[child_index];
                        if child.style.placement.kind == {
                            case .FIXED;
                                child.position = child.style.placement.fixed + child.style.translate;
                            case .RELATIVE;
                                child.position = node.position + child.style.placement.relative + child.style.translate;
                            case .FLOW;
                                margin := get(child.style.margin, direction);
                                add(*pen, direction, margin.x);
                                child.position = pen + child.style.translate + node.children_offset;
                                add(*pen, direction, get(child.size, direction) + margin.y);
                                opposite_margin := get(child.style.margin, opposite_direction);
                                set(*node.content_size, opposite_direction, max(
                                    get(node.content_size, opposite_direction),
                                    opposite_margin.x + get(child.size, opposite_direction) + opposite_margin.y,
                                ));
                        }
                        child_index = child.next_sibling;
                    }

                    content_size := get(pen, direction) - get(base, direction);
                    set(*node.content_size, direction, content_size);
                    available := get(node.size, direction) - fitting_base(node, direction);
                    justification := get_justification(node, direction);
                    offset: float;
                    if justification == {
                        case .CENTER;
                            offset = (available - content_size) / 2.0;
                        case .END;
                            offset = available - content_size;
                    };

                    available_opposite := get(node.size, opposite_direction) - fitting_base(node, opposite_direction);
                    justification_opposite := get_justification(node, opposite_direction);
                    child_index = node.first_child;
                    while child_index != -1 {
                        child := *node_tree[child_index];
                        if child.style.placement.kind == .FLOW {
                            if justification_opposite == {
                                case .CENTER;
                                    add(*child.position, opposite_direction, (available_opposite - get(child.size, opposite_direction)) / 2.0);
                                case .END;
                                    add(*child.position, opposite_direction, available_opposite - get(child.size, opposite_direction));
                            };
                            add(*child.position, direction, offset);
                        }
                        child_index = child.next_sibling;
                    }
                }
            }
        }
    }
}
Draw_Instance :: struct {
    Draw_Instance_Kind :: enum u32 {
        NODE :: 1;
        GLYPH :: 2;
    };

    position: Vector2;
    size: Vector2;
    color: Vector4;

    // node
    border_width: Vector4;
    border_color: Vector4;
    border_radius: float;

    // glyph
    uv_min:  Vector2;
    uv_max:  Vector2;

    kind: Draw_Instance_Kind;
    z: u16;
};
draw :: (clearing_color := Vector4.{1.0, 1.0, 1.0, 1.0}) {
    using context.forbear;
    #if OS == .MACOS {
        if backend.attached_view != window.view {
            NSOpenGLContext.setView(backend.gl_context, window.view);
            backend.attached_view = window.view;
        }
    } else #if OS == .LINUX {
        glBindFramebuffer(GL_FRAMEBUFFER, window.buffers[window.current].fbo);
    }

    glViewport(0, 0, xx window.width, xx window.height);
    glClearColor(clearing_color.x, clearing_color.y, clearing_color.z, clearing_color.w);
    glClear(GL_COLOR_BUFFER_BIT);

    // every glyph has to be in the atlas before any of the instances are gathered, so that resetting or growing
    // the atlas can't invalidate UVs that were already written out
    if !glyph_atlas_fill() {
        // glyphs that aren't used anymore may be what's filling it up, so start over with only this frame's
        glyph_atlas_reset(*glyph_atlas);
        while !glyph_atlas_fill() {
            if !glyph_atlas_grow(*glyph_atlas) {
                log_error("the glyph atlas is full at its maximum size of %, some glyphs will not be rendered", Glyph_Atlas.MAX_SIZE);
                break;
            }
        }
    }

    z_buckets: [..]u32;
    instance_count: s64;
    array_reserve(*z_buckets, node_tree.count);
    for node: node_tree if node.kind == .ELEMENT {
        if node.z >= z_buckets.count {
            array_resize(*z_buckets, node.z + 1);
        }
        z_buckets[node.z] += xx (1 + node.glyphs.array.count);
        instance_count += 1 + node.glyphs.array.count;
    }

    draw_instances := NewArray(instance_count, Draw_Instance, false);

    offset: u32;
    for *start: z_buckets {
        count := start.*;
        start.* = xx offset;
        offset += count;
    }
    assert(offset == draw_instances.count);
    for node: node_tree if node.kind == .ELEMENT {
        instance: Draw_Instance;
        {
            using instance;
            kind = .NODE;
            z = node.z;
            position = node.position;
            size = node.size;
            // TODO: write out the instance gathering for the other types of backgrounds
            if node.style.background.kind == .COLOR {
                color = node.style.background.color;
            }
            border_width = Vector4.{
                node.style.border_width.x.x, // left
                node.style.border_width.x.y, // right
                node.style.border_width.y.x, // top
                node.style.border_width.y.y  // bottom
            };
            border_color = node.style.border_color;
            border_radius = min(node.style.border_radius, min(node.size.x, node.size.y));
        }
        draw_instances[z_buckets[instance.z]] = instance;
        z_buckets[instance.z] += 1;

        if node.glyphs.array.count != 0 {
            rounded_font_size := round_font_size(node.style.font_size * (cast(float) window.scale));
            font_units_to_point := get_font_units_to_pixel(node.style.font, node.style.font_size);

            for glyph: node.glyphs.array {
                atlas_key := glyph_atlas_key(node.style.font, xx glyph.index, rounded_font_size, node.style.font_weight);
                entry := table_find_pointer(*glyph_atlas.table, atlas_key);

                instance: Draw_Instance;
                instance.kind = .GLYPH;
                instance.z = node.z;
                scale := cast(float) window.scale;
                // the entry is only missing if the atlas is full at its maximum size, the instance was already
                // counted in the z buckets though, so it's left with no size
                if entry != null {
                    using instance;
                    position = node.position + (Vector2.{0.0, node.glyphs.ascent} + glyph.position) * font_units_to_point;
                    size = entry.size / scale;
                    position += entry.bearing / scale;
                    position.x = floor(position.x * scale + 0.5) / scale;
                    position.y = floor(position.y * scale + 0.5) / scale;
                    color = node.style.color;

                    uv_min = entry.uv_min;
                    uv_max = entry.uv_max;
                }
                draw_instances[z_buckets[instance.z]] = instance;
                z_buckets[instance.z] += 1;
            }
        }
    }

    viewport_size := get_viewport_size();

    glUseProgram(shader_program);
    glUniform2f(glGetUniformLocation(shader_program, "viewport"), viewport_size.x, viewport_size.y);
    glBindVertexArray(shader_vao);
    glBindBuffer(GL_ARRAY_BUFFER, node_vbo);
    glBufferData(GL_ARRAY_BUFFER, draw_instances.count * size_of(Draw_Instance), draw_instances.data, GL_STREAM_DRAW);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, glyph_atlas.texture);
    glDrawArraysInstanced(GL_TRIANGLES, 0, 6, xx draw_instances.count);

    #if OS == .WINDOWS {
        SwapBuffers(window.hdc);
        if frame == 3 {
            SetProcessWorkingSetSize(GetCurrentProcess(), U64_MAX, U64_MAX);
        }
    } else #if OS == .MACOS {
        NSOpenGLContext.flushBuffer(backend.gl_context);
    } else #if OS == .LINUX {
        glFlush();

        send_wayland_message(*backend.connection, window.wl_surface_id, Wl_Surface_Request_Attach.{ buffer = window.buffers[window.current].wl_buffer_id, x = 0, y = 0 });
        send_wayland_message(*backend.connection, window.wl_surface_id, Wl_Surface_Request_Damage_Buffer.{ x = 0, y = 0, width = window.width, height = window.height });
        window.wl_frame_callback_id = new_wayland_client_object(*backend.connection, .WL_CALLBACK);
        send_wayland_message(*backend.connection, window.wl_surface_id, Wl_Surface_Request_Frame.{
            callback = window.wl_frame_callback_id,
        });
        window.waiting_for_vblank = true;
        window.buffers[window.current].busy = true;
        send_wayland_message(*backend.connection, window.wl_surface_id, Wl_Surface_Request_Commit.{});
        window.current = (window.current + 1) % 2;
    }
}
prepare_for_next_frame :: () {
    using context.forbear;
    now            := seconds_since_init();
    delta_time      = xx min(now - last_frame_time, 1.0 / 30.0);
    last_frame_time = now;

    window.keyboard_state.events.count = 0;
    window.text.count                  = 0;
    window.mouse_state.scroll_delta    = Vector2.{0.0, 0.0};
    memset(*window.mouse_state.released, 0, size_of(type_of(window.mouse_state.released)));
    memset(*window.mouse_state.pressed, 0, size_of(type_of(window.mouse_state.pressed)));

    cursor := Cursor.DEFAULT;
    array_resize(*measurements, node_tree.count, false);
    for node: node_tree {
        // we can't just copy the entire Node_Tree with a mempcy here because it points into frame allocated data
        // that was allocated in the frame pool. besides, in what I was able to measure, this copy tends to be more
        // performant than if we were to copy the entire Node_Tree with memcpy.
        measurements[it_index] = Node_Measurement.{
            size               = node.size,
            content_size       = node.content_size,
            position           = node.position,
            clipping_rectangle = node.clipping_rectangle,
            state_offset       = node.state_offset,
            state_size         = node.state_size,
            pool_slot          = node.pool_slot,
            key                = node.key,
        };
        if window.mouse_state.inside {
            mouse := window.mouse_state.position;
            top_z := 0;
            for node: node_tree if node.kind == .ELEMENT {
                inside :=
                       mouse.x >= node.position.x
                    && mouse.x <= node.position.x + node.size.x
                    && mouse.y >= node.position.y
                    && mouse.y <= node.position.y + node.size.y;
                if inside && node.z >= top_z {
                    top_z  = node.z;
                    cursor = node.style.cursor;
                }
            }
        }
    }
    set_cursor(cursor);

    #if OS == .LINUX {
        using window.keyboard_state;
        if repeating_key_code != 0 {
            while now >= next_repeat {
                add_key_event(*events, Key_Event.{.REPEATED, repeating_key});
                utf8: [64]u8;
                append_text(key_text(backend.connection.key_state, repeating_key_code, utf8), *window.text, window.text_buffer);
                next_repeat += 1.0 / repeat_rate;
            }
        }
    }
    state_current = 1 - state_current;
    state_used    = 0;
    array_reset_keeping_memory(*node_tree);

    for *slot: pool_slots {
        if slot.used && slot.last_frame != frame {
            if slot.pool.current_point != slot.pool.memory_base {
                #if OS == .WINDOWS {
                    DiscardVirtualMemory(slot.pool.memory_base, cast(u64) ((slot.pool.current_point - slot.pool.memory_base + 4095) & ~4095));
                } else {
                    madvise(slot.pool.memory_base, cast(u64) (slot.pool.current_point - slot.pool.memory_base), MADV_DONTNEED);
                }
            }
            reset(*slot.pool);
            slot.used = false;
        }
    }

    frame += 1;
}

// This introduces a compiler plugin so that users can do +forbear in their compiliation command,
// and automatically get scope(#code Function(...)) for all of their components or hooks. The proper
// name is `@scope`, but there's also the two aliases `@component` or @hook` for what people
// might prefer.
#import "Compiler";
COMPILER_PLUGIN_DEBUGGING :: false;
get_plugin :: () -> *Metaprogram_Plugin {
    // TODO: instead of wrapping the caller with a macro that re-returns the function's return values,
    // we should instead modify the scope's procedure body to have the scope definition.
    //
    // to properly support this, we should pass the scope's location thruogh the context, and thus we will still
    // need to modify the procedure callers, but just to add a `,, scope_location = #location()`
    format                          := *context.print_style.default_format_struct;
    format.use_newlines_if_long_form = true;
    format.indentation_width         = 4;

    using plugin := New(Metaprogram_Plugin);
    message       = (plugin: *Metaprogram_Plugin, message: *Message) {
        if message.kind == .TYPECHECKED {
            typechecked := cast(*Message_Typechecked) message;
            log_source :: (prefix: string, location: Code_Node.Location) {
                #import "File";
                if !location.enclosing_load {
                    return;
                }
                path := location.enclosing_load.fully_pathed_filename;
                source, success := read_entire_file(path, log_errors = false);
                if !success {
                    return;
                }
                defer free(source);

                start, end := -1, -1;
                line       := 1;
                line_start := 0;
                for source {
                    if line == location.l0 && start < 0 {
                        start = line_start + location.c0 - 1;
                    }
                    if line == location.l1 {
                        end = line_start + location.c1 - 1;
                        break;
                    }
                    if it == #char "\n" {
                        line      += 1;
                        line_start = it_index + 1;
                    }
                }
                if start < 0 || end < start {
                    return;
                }
                print("%: %:%:%: %\n", prefix, path, location.l0, location.c0, string.{end - start, source.data + start});
            }
            for typechecked_body: typechecked.procedure_bodies {
                body := typechecked_body.expression;
                if body.body_flags & .ALREADY_MODIFIED {
                    continue;
                }

                scope_locations: [..]Code_Node.Location;
                for typechecked_body.subexpressions if it.kind == .PROCEDURE_CALL {
                    resolved := (cast(*Code_Procedure_Call) it).resolved_procedure_expression;
                    if resolved && resolved.kind == .PROCEDURE_HEADER {
                        // `expected` should be lower cased already
                        lower_compare :: (actual: string, expected: string) -> bool {
                            equals := true;
                            if actual.count == expected.count {
                                for expected if to_lower(actual[it_index]) != it {
                                    equals = false;
                                    break;
                                }
                            } else {
                                equals = false;
                            }
                            return equals;
                        }

                        for note: (cast(*Code_Procedure_Header) resolved).notes if     lower_compare(note.text, "scope")
                                                                                    || lower_compare(note.text, "component")
                                                                                    || lower_compare(note.text, "hook") {
                            if COMPILER_PLUGIN_DEBUGGING {
                                log_source("found scope call", it.location);
                            }
                            array_add(*scope_locations, it.location);
                            break;
                        }
                    }
                }

                modified := false;
                for sub: typechecked_body.subexpressions {
                    if sub.kind == .PROCEDURE_CALL {
                        call    := cast(*Code_Procedure_Call) sub;
                        matches := false;
                        for scope_locations if memcmp(*it, *call.location, size_of(Code_Node.Location)) == 0 {
                            matches = true;
                            break;
                        }
                        if matches {
                            if COMPILER_PLUGIN_DEBUGGING {
                                log_source("wrapping in scope", call.location);
                            }
                            original  := New(Code_Procedure_Call);
                            original.* = call.*;

                            open_scope_ident         := New(Code_Ident);
                            open_scope_ident.location = call.location;
                            open_scope_ident.name     = "open_scope";

                            open_scope_call                     := New(Code_Procedure_Call);
                            open_scope_call.location             = call.location;
                            open_scope_call.procedure_expression = open_scope_ident;

                            close_scope_ident         := New(Code_Ident);
                            close_scope_ident.location = call.location;
                            close_scope_ident.name     = "close_scope";

                            arguments              := NewArray(2, Code_Argument);
                            arguments[0].expression = open_scope_call;
                            arguments[1].expression = original;

                            call.*                    = .{};
                            call.location             = original.location;
                            call.procedure_expression = close_scope_ident;
                            call.arguments_unsorted   = arguments;

                            modified = true;
                        }
                    } else if sub.kind == .PROCEDURE_HEADER {
                        // This is meant as a workaround to compiler bug where, a procedure defined inside a #code block looses its body
                        // after compiler_modify_procedure because the procedure has no body in the syntax tree at that point.
                        header := cast(*Code_Procedure_Header) sub;
                        if !header.body_or_null {
                            for typechecked_body.subexpressions if it.kind == .DECLARATION {
                                declaration := cast(*Code_Declaration) it;
                                if declaration.expression && declaration.expression.kind == .PROCEDURE_HEADER {
                                    inserted := cast(*Code_Procedure_Header) declaration.expression;
                                    if inserted.body_or_null && memcmp(*inserted.location, *header.location, size_of(Code_Node.Location)) == 0 {
                                        if COMPILER_PLUGIN_DEBUGGING {
                                            log_source("restoring body", header.location);
                                        }
                                        header.body_or_null = inserted.body_or_null;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
                if modified compiler_modify_procedure(message.workspace, body);
            }
        }
    }
    return plugin;
}
