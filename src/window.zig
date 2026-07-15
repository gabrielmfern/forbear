const std = @import("std");
const builtin = @import("builtin");
const c = @import("c");

// Explicit tag so the Windows backend can hold it in a std.atomic.Value.
pub const Cursor = enum(u8) {
    default,
    text,
    pointer,
};

/// Cross-platform key identity. Backends translate their native key code
/// (XKB keysym on Linux, virtual-key code on Windows, etc.) into one of
/// these. Layout-dependent keys (letters/digits) reflect the *typed*
/// character — on AZERTY the physical Q key reports `.a`.
pub const Keys = packed struct {
    /// Reserved bit. The backends mappers return a default `.{}` (all
    /// false) for keys not yet covered by this struct, so this field is
    /// never set — kept around so bit 0 of the backing u128 stays unused.
    _unknown: bool = false,

    // Letters
    a: bool = false,
    b: bool = false,
    c: bool = false,
    d: bool = false,
    e: bool = false,
    f: bool = false,
    g: bool = false,
    h: bool = false,
    i: bool = false,
    j: bool = false,
    k: bool = false,
    l: bool = false,
    m: bool = false,
    n: bool = false,
    o: bool = false,
    p: bool = false,
    q: bool = false,
    r: bool = false,
    s: bool = false,
    t: bool = false,
    u: bool = false,
    v: bool = false,
    w: bool = false,
    x: bool = false,
    y: bool = false,
    z: bool = false,

    // Top-row digits
    digit0: bool = false,
    digit1: bool = false,
    digit2: bool = false,
    digit3: bool = false,
    digit4: bool = false,
    digit5: bool = false,
    digit6: bool = false,
    digit7: bool = false,
    digit8: bool = false,
    digit9: bool = false,

    // Function keys
    f1: bool = false,
    f2: bool = false,
    f3: bool = false,
    f4: bool = false,
    f5: bool = false,
    f6: bool = false,
    f7: bool = false,
    f8: bool = false,
    f9: bool = false,
    f10: bool = false,
    f11: bool = false,
    f12: bool = false,

    // Modifiers. These reflect the *effective* modifier state from the
    // platform (xkb_state on Linux, NSEvent.modifierFlags on macOS,
    // VK_*/keymap on Windows) — not just whether a specific physical key
    // is held. So `caps:ctrl_modifier` on Linux makes `control` true
    // while CapsLock is held, even though the keysym is still Caps_Lock.
    // No left/right split: chord hotkeys virtually never care which side.
    shift: bool = false,
    control: bool = false,
    alt: bool = false,
    super: bool = false,
    capsLock: bool = false,

    // Navigation
    arrowLeft: bool = false,
    arrowRight: bool = false,
    arrowUp: bool = false,
    arrowDown: bool = false,
    home: bool = false,
    end: bool = false,
    pageUp: bool = false,
    pageDown: bool = false,

    // Editing & misc
    tab: bool = false,
    escape: bool = false,
    enter: bool = false,
    space: bool = false,
    backspace: bool = false,
    delete: bool = false,
    insert: bool = false,

    /// Integer type wide enough to hold every key bit. Tracks `Keys`
    /// automatically — add a key, and `Backing` widens with it.
    const Backing = @typeInfo(Keys).@"struct".backing_integer.?;

    /// `self | other` — union of two sets.
    pub fn with(self: Keys, other: Keys) Keys {
        return @bitCast(@as(Backing, @bitCast(self)) | @as(Backing, @bitCast(other)));
    }

    /// `self & ~other` — remove `other`'s bits from `self`.
    pub fn without(self: Keys, other: Keys) Keys {
        return @bitCast(@as(Backing, @bitCast(self)) & ~@as(Backing, @bitCast(other)));
    }

    /// `self & other` — bits set in both.
    pub fn intersect(self: Keys, other: Keys) Keys {
        return @bitCast(@as(Backing, @bitCast(self)) & @as(Backing, @bitCast(other)));
    }

    pub fn has(self: Keys, other: Keys) bool {
        return @as(Backing, @bitCast(self)) & @as(Backing, @bitCast(other)) == @as(Backing, @bitCast(other));
    }

    /// True if no bit is set.
    pub fn isEmpty(self: Keys) bool {
        return @as(Backing, @bitCast(self)) == 0;
    }

    /// Just the modifier bits of `self`.
    pub fn modifiers(self: Keys) Keys {
        return .{
            .shift = self.shift,
            .control = self.control,
            .alt = self.alt,
            .super = self.super,
            .capsLock = self.capsLock,
        };
    }

    /// The single-bit `Keys` value `offset` fields after `firstField` —
    /// `a..z` and `digit0..9` are declared contiguously, and so are the
    /// keysym/VK ranges backends map them from, so a letter or digit key can
    /// be resolved by arithmetic (`Keys.at("a", sym - firstKeysym)`) instead
    /// of one switch arm per key. Keeps the three tables (this struct, the
    /// keysym range, the VK range) from being able to drift out of sync.
    pub fn at(comptime firstField: []const u8, offset: u32) Keys {
        return @bitCast(@as(Backing, 1) << @intCast(@bitOffsetOf(Keys, firstField) + offset));
    }
};

pub const ScrollAxis = enum(u32) {
    vertical = 0,
    horizontal = 1,
};

/// Cross-platform mouse button identity. Backends translate their native
/// code (evdev BTN_* on Linux, WM_*BUTTON* messages on Windows) into one of
/// these; buttons without a mapping are dropped at the backend.
pub const MouseButton = enum {
    left,
    right,
    middle,
    back,
    forward,
};

/// Where the caret sits in surface coordinates — the IME docks its candidate
/// window against this rectangle.
pub const TextInputArea = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
};

pub const EventQueue = struct {
    buffer: [256]Event,
    head: std.atomic.Value(usize),
    tail: std.atomic.Value(usize),

    pub const empty: @This() = .{
        .buffer = undefined,
        .head = .init(0),
        .tail = .init(0),
    };

    pub fn push(self: *@This(), event: Event) void {
        const t = self.tail.raw;
        if (t - self.head.load(.acquire) < self.buffer.len) {
            self.buffer[t % self.buffer.len] = event;
            self.tail.store(t + 1, .release);
        } else {
            std.log.warn("event queue full; dropping {s}", .{@tagName(event)});
        }
    }

    const EventIterator = struct {
        queue: *EventQueue,
        tail: usize,
        head: usize,

        pub fn next(self: *@This()) ?Event {
            if (self.head < self.tail) {
                defer self.head += 1;
                return self.queue.buffer[self.head % self.queue.buffer.len];
            } else {
                self.queue.head.store(self.head, .release);
                return null;
            }
        }
    };

    pub fn iterate(self: *@This()) EventIterator {
        const tailLocal = self.tail.load(.acquire);
        return EventIterator{
            .queue = self,
            .tail = tailLocal,
            .head = self.head.raw,
        };
    }
};

pub const KeyboardState = struct {
    held: Keys = .{},
    pendingPressed: Keys = .{},
    pendingReleased: Keys = .{},

    pub fn keyDown(self: *@This(), mapped: Keys) void {
        self.pendingPressed = self.pendingPressed.with(mapped);
        self.held = self.held.with(mapped);
    }

    pub fn keyUp(self: *@This(), mapped: Keys) void {
        self.pendingReleased = self.pendingReleased.with(mapped);
        self.held = self.held.without(mapped);
    }

    pub fn setHeldModifiers(self: *@This(), newModifiers: Keys) void {
        const oldModifiers: Keys = .{
            .shift = self.held.shift,
            .control = self.held.control,
            .alt = self.held.alt,
            .super = self.held.super,
        };
        self.pendingReleased = self.pendingReleased.with(oldModifiers.without(newModifiers));
        self.held.shift = newModifiers.shift;
        self.held.control = newModifiers.control;
        self.held.alt = newModifiers.alt;
        self.held.super = newModifiers.super;
    }

    pub fn releaseAll(self: *@This()) void {
        self.pendingReleased = self.pendingReleased.with(self.held);
        self.held = .{};
    }

    pub fn flush(self: *@This(), queue: *EventQueue) void {
        const keys = self.pendingPressed.with(self.held.modifiers());
        if (!keys.isEmpty()) {
            queue.push(Event{ .keys = keys });
            self.pendingPressed = .{};
        }
        if (!self.pendingReleased.isEmpty()) {
            queue.push(Event{ .keysReleased = self.pendingReleased });
            self.pendingReleased = .{};
        }
    }
};

pub const Event = union(enum) {
    pointerEnter: PointerEnter,
    pointerLeave: PointerLeave,
    pointerMotion: PointerMotion,
    pointerButton: PointerButton,
    scroll: Scroll,
    /// Keyboard state for this delivery. Non-modifier bits are keys pressed —
    /// or OS auto-repeated — since the last delivery, like a DOM `keydown`
    /// with `repeat: true`; modifier bits reflect what is held right now.
    keys: Keys,
    /// Keys released since the last delivery — one edge per physical
    /// release, modifiers included, like a DOM `keyup`. Never repeats.
    keysReleased: Keys,
    /// One text-entry delivery, whole: a typed character, an IME batch, or
    /// both (a commit that ends a composition). Never split — the frame
    /// layer reads the entire transaction from a single event.
    input: Input,

    pub const PointerEnter = struct {
        serial: u32,
        x: i32,
        y: i32,
    };

    pub const PointerLeave = struct {
        serial: u32,
    };

    pub const PointerMotion = struct {
        time: u32,
        x: f32,
        y: f32,
    };

    pub const PointerButton = struct {
        serial: u32,
        time: u32,
        button: MouseButton,
        pressed: bool,
    };

    pub const Scroll = struct {
        axis: ScrollAxis,
        offset: f32,
    };

    pub const Input = struct {
        /// Committed text: a typed character or an IME commit string,
        /// repeated `repeats` times (OS key auto-repeat).
        textBuffer: [120]u8 = @splat(0),
        textLength: usize = 0,
        repeats: usize = 1,

        /// Whether this delivery carries a composition update. An update
        /// with an empty preedit means the composition ended.
        composition: bool = false,
        preeditBuffer: [120]u8 = @splat(0),
        preeditLength: usize = 0,
        /// Caret range inside the preedit, in bytes.
        cursor: [2]usize = .{ 0, 0 },
        deleteBefore: usize = 0,
        deleteAfter: usize = 0,

        pub fn text(self: @This(), arena: std.mem.Allocator) ![]u8 {
            var repeatedBuffer = try arena.alloc(u8, self.repeats * self.textLength);
            for (0..self.repeats) |i| {
                @memcpy(
                    repeatedBuffer[i * self.textLength .. (i + 1) * self.textLength],
                    self.textBuffer[0..self.textLength],
                );
            }
            return repeatedBuffer;
        }
    };
};

pub const Window = switch (builtin.os.tag) {
    .linux => struct {
        const posix = std.posix;
        const os = std.os;

        const Self = @This();

        // Everything native that is contextual
        wlDisplay: *c.wl_display,
        wlRegistry: *c.wl_registry,
        wlCompositor: *c.wl_compositor,
        wlShm: *c.wl_shm,
        wlSeat: *c.wl_seat,
        xdgWmBase: *c.xdg_wm_base,
        wpFractionalScaleManager: ?*c.wp_fractional_scale_manager_v1 = null,
        wpViewporter: ?*c.wp_viewporter = null,

        // Keyboard
        xkbContext: *c.xkb_context,
        xkbKeymap: ?*c.xkb_keymap,
        xkbState: ?*c.xkb_state,
        /// Dead-key composition (´ + a = á), driven client-side from the
        /// locale's Compose table; null when the locale has none.
        xkbComposeState: ?*c.xkb_compose_state,
        /// The pending compose sequence, previewed as a preedit while it
        /// waits for its next key. Wayland event thread only.
        composePreview: [16]u8,
        composePreviewLength: usize,
        repeatInfo: struct {
            /// the rate of repeating keys in characters per second
            rate: i32,
            /// delay in milliseconds since key down until repeating starts
            delay: i32,
        },
        wlKeyboard: *c.wl_keyboard,
        /// Serial from the most recent key event. `wl_data_device_set_selection`
        /// requires one to prove the request is tied to real input.
        keyboardSerial: u32,

        wlDataDeviceManager: ?*c.wl_data_device_manager,
        wlDataDevice: ?*c.wl_data_device,

        zwpTextInputManager: ?*c.zwp_text_input_manager_v3,
        zwpTextInput: ?*c.zwp_text_input_v3,
        /// One IME batch accumulated between text-input events until `done`
        /// applies it atomically. Wayland event thread only.
        textInputPending: TextInputPending,
        /// Guards the fields below: `textInputWanted`/`textInputArea` are
        /// written by the render thread (`setTextInput`), `textInputFocused`
        /// by the Wayland thread's enter/leave — whichever flips last sends
        /// the enable/disable requests (libwayland requests are thread-safe).
        textInputMutex: std.Io.Mutex,
        textInputWanted: bool,
        textInputFocused: bool,
        textInputArea: TextInputArea,
        /// Guards every clipboard field below: the `dataSource*`/`dataDevice*`
        /// listeners run on the Wayland event thread while
        /// `setClipboardText`/`getClipboardText` run on the render thread —
        /// unlike `keyboard`, this state isn't funneled through `eventQueue`.
        clipboardMutex: std.Io.Mutex,
        /// The data source we created last time we set the clipboard. Lives
        /// until another app takes the selection (`cancelled`) or we replace
        /// it ourselves.
        clipboardSource: ?*c.wl_data_source,
        /// Bytes offered by `clipboardSource`, owned by `allocator`.
        clipboardText: []const u8,
        /// The offer backing the current clipboard selection, as announced by
        /// `wl_data_device`'s `selection` event. Null when nothing is
        /// selected, or while we're the current owner.
        selectionOffer: ?*c.wl_data_offer,

        /// The Wayland event thread writes; Forbear's render thread drains
        /// the event queue at frame start.
        keyboard: KeyboardState,
        /// The one key currently auto-repeating, per xkb's convention that the
        /// latest repeatable key owns the repeat timer. `handleEvents` re-fires
        /// it into `pendingPressed` (and `.input` when it carries text) at the
        /// compositor-advertised rate.
        activeRepeat: ?struct {
            /// Repeat identity: releasing this exact keycode cancels the
            /// repeat; releasing anything else leaves it running.
            xkbKeycode: u32,
            key: Keys,
            characterBuffer: [7:0]u8,
            /// 0 when the key produces no text (arrows, delete, ...) — the
            /// repeat then only re-fires the key edge, no `.input` events.
            characterLength: usize,
            /// Does not count the first character from the initial key event
            totalRepeats: usize,
            startTime: std.Io.Timestamp,
        },

        eventQueue: EventQueue = .empty,

        // Resize is delivered as a direct callback on the window thread instead of
        // through `eventQueue`, so the swapchain is recreated synchronously while
        // the platform holds this thread mid-resize — letting frames track the
        // drag rather than stalling until release.
        handlers: struct {
            resize: ?struct {
                data: *anyopaque,
                function: *const fn (window: *Self, newWidth: u32, newHeight: u32, newDpi: [2]u32, data: *anyopaque) void,
            } = null,
        } = .{},

        // cursor
        wlPointer: *c.wl_pointer,
        pointerSerial: ?u32,
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
        xdgDecorationManager: ?*c.zxdg_decoration_manager_v1 = null,
        xdgToplevelDecoration: ?*c.zxdg_toplevel_decoration_v1 = null,

        // Window state
        width: u32,
        height: u32,
        title: [:0]const u8,
        appId: [:0]const u8,
        running: std.atomic.Value(bool),
        dpi: [2]u32,

        scale: f32 = 1.0,
        physicalWidthMilimeters: i32 = 0,
        physicalHeightMilimeters: i32 = 0,
        monitorWidth: i32 = 0,
        monitorHeight: i32 = 0,
        refreshRate: u32 = 60000, // in millihertz (mHz), default 60Hz

        allocator: std.mem.Allocator,
        io: std.Io,

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

                fn is(self: @This(), interfaceName: []const u8) bool {
                    const selfName = self.interface.name[0..std.mem.len(self.interface.name)];
                    return std.mem.eql(u8, interfaceName, selfName);
                }

                fn bind(self: @This(), registry: ?*c.wl_registry, name: u32, advertisedVersion: u32) *T {
                    return @ptrCast(@alignCast(
                        c.wl_registry_bind(
                            registry,
                            name,
                            self.interface,
                            @min(self.version, advertisedVersion),
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
            physicalWidth: i32,
            physicalHeight: i32,
            subpixel: i32,
            make: [*c]const u8,
            model: [*c]const u8,
            transform: i32,
        ) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data));
            _ = wlOutput;
            _ = x;
            _ = y;
            window.physicalWidthMilimeters = physicalWidth;
            window.physicalHeightMilimeters = physicalHeight;
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
            if (window.handlers.resize) |h| h.function(window, window.width, window.height, window.dpi, h.data);
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
            if (window.handlers.resize) |h| h.function(window, window.width, window.height, window.dpi, h.data);
            std.log.debug("Fractional scale changed to: {d}", .{@as(f32, @floatFromInt(scale)) / 120.0});
        }

        const fractionalScaleListener: c.wp_fractional_scale_v1_listener = .{
            .preferred_scale = handleFractionalScale,
        };

        fn global(
            data: ?*anyopaque,
            registry: ?*c.wl_registry,
            name: u32,
            interfacePtr: [*c]const u8,
            version: u32,
        ) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data.?));

            const compositor = BindingInfo(c.wl_compositor).new(
                &c.wl_compositor_interface,
                6,
            );
            const output = BindingInfo(c.wl_output).new(
                &c.wl_output_interface,
                4,
            );
            const shm = BindingInfo(c.wl_shm).new(
                &c.wl_shm_interface,
                2,
            );
            const xdgWmBase = BindingInfo(c.xdg_wm_base).new(
                &c.xdg_wm_base_interface,
                6,
            );
            const seat = BindingInfo(c.wl_seat).new(
                &c.wl_seat_interface,
                9,
            );
            const fractionalScaleManager = BindingInfo(c.wp_fractional_scale_manager_v1).new(
                &c.wp_fractional_scale_manager_v1_interface,
                1,
            );
            const viewporter = BindingInfo(c.wp_viewporter).new(
                &c.wp_viewporter_interface,
                1,
            );
            const decorationManager = BindingInfo(c.zxdg_decoration_manager_v1).new(
                &c.zxdg_decoration_manager_v1_interface,
                1,
            );
            const dataDeviceManager = BindingInfo(c.wl_data_device_manager).new(
                &c.wl_data_device_manager_interface,
                3,
            );
            const textInputManager = BindingInfo(c.zwp_text_input_manager_v3).new(
                &c.zwp_text_input_manager_v3_interface,
                1,
            );

            const interfaceName: []const u8 = interfacePtr[0..std.mem.len(interfacePtr)];

            if (compositor.is(interfaceName)) {
                window.wlCompositor = compositor.bind(registry, name, version);
            } else if (shm.is(interfaceName)) {
                window.wlShm = shm.bind(registry, name, version);
            } else if (xdgWmBase.is(interfaceName)) {
                window.xdgWmBase = xdgWmBase.bind(registry, name, version);
                _ = c.xdg_wm_base_add_listener(
                    window.xdgWmBase,
                    &xdgWmBaseListener,
                    data,
                );
            } else if (seat.is(interfaceName)) {
                window.wlSeat = seat.bind(registry, name, version);

                window.wlPointer = c.wl_seat_get_pointer(window.wlSeat) orelse @panic("could not get wl_pointer from wl_seat");
                _ = c.wl_pointer_add_listener(window.wlPointer, &wlPointerListener, data);

                window.wlKeyboard = c.wl_seat_get_keyboard(window.wlSeat) orelse @panic("could not get wl_keyboard from wl_seat");
                _ = c.wl_keyboard_add_listener(window.wlKeyboard, &wlKeyboardListener, data);
            } else if (output.is(interfaceName)) {
                window.wlOutput = output.bind(registry, name, version);

                _ = c.wl_output_add_listener(window.wlOutput, &outputListener, data);
            } else if (fractionalScaleManager.is(interfaceName)) {
                window.wpFractionalScaleManager = fractionalScaleManager.bind(registry, name, version);
            } else if (viewporter.is(interfaceName)) {
                window.wpViewporter = viewporter.bind(registry, name, version);
            } else if (decorationManager.is(interfaceName)) {
                window.xdgDecorationManager = decorationManager.bind(registry, name, version);
            } else if (dataDeviceManager.is(interfaceName)) {
                window.wlDataDeviceManager = dataDeviceManager.bind(registry, name, version);
            } else if (textInputManager.is(interfaceName)) {
                window.zwpTextInputManager = textInputManager.bind(registry, name, version);
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
            c.xdg_surface_ack_configure(
                xdgSurface,
                serial,
            );
            c.wl_surface_commit(window.wlSurface);
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
                if (window.handlers.resize) |h| h.function(window, window.width, window.height, window.dpi, h.data);
            }
        }

        fn xdgToplevelClose(data: ?*anyopaque, xdgToplevel: ?*c.xdg_toplevel) callconv(.c) void {
            _ = xdgToplevel;
            const window: *Self = @ptrCast(@alignCast(data));
            window.running.store(false, .release);
        }

        fn xdgToplevelConfigureBounds(
            data: ?*anyopaque,
            xdgToplevel: ?*c.xdg_toplevel,
            width: i32,
            height: i32,
        ) callconv(.c) void {
            _ = data;
            _ = xdgToplevel;
            std.log.debug("xdg toplevel configure bounds: {}x{}", .{ width, height });
        }

        fn xdgToplevelWmCapabilities(
            data: ?*anyopaque,
            xdgToplevel: ?*c.xdg_toplevel,
            capabilities: [*c]c.wl_array,
        ) callconv(.c) void {
            _ = data;
            _ = xdgToplevel;
            _ = capabilities;
        }

        const xdgToplevelListener: c.xdg_toplevel_listener = .{
            .configure = xdgToplevelConfigure,
            .close = xdgToplevelClose,
            .configure_bounds = xdgToplevelConfigureBounds,
            .wm_capabilities = xdgToplevelWmCapabilities,
        };

        fn xdgToplevelDecorationConfigure(
            data: ?*anyopaque,
            decoration: ?*c.zxdg_toplevel_decoration_v1,
            mode: u32,
        ) callconv(.c) void {
            _ = data;
            _ = decoration;
            if (mode == c.ZXDG_TOPLEVEL_DECORATION_V1_MODE_CLIENT_SIDE) {
                std.log.warn("compositor fell back to client-side decorations", .{});
            } else {
                std.log.debug("using server-side decorations", .{});
            }
        }

        const xdgToplevelDecorationListener: c.zxdg_toplevel_decoration_v1_listener = .{
            .configure = xdgToplevelDecorationConfigure,
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
            window.pointerSerial = serial;
            window.setCursor(.default, serial) catch |err| {
                std.log.err("failed to set cursor: {}", .{err});
            };
            window.eventQueue.push(Event{
                .pointerEnter = .{
                    .serial = serial,
                    .x = surfaceX,
                    .y = surfaceY,
                },
            });
        }

        fn pointerHandleLeave(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            serial: u32,
            surface: ?*c.wl_surface,
        ) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data));
            window.pointerSerial = null;
            window.eventQueue.push(Event{
                .pointerLeave = .{ .serial = serial },
            });
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
            window.eventQueue.push(Event{
                .pointerMotion = .{
                    .time = time,
                    .x = @floatCast(c.wl_fixed_to_double(surfaceX)),
                    .y = @floatCast(c.wl_fixed_to_double(surfaceY)),
                },
            });
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
            const mapped: MouseButton = switch (button) {
                272 => .left, // BTN_LEFT
                273 => .right, // BTN_RIGHT
                274 => .middle, // BTN_MIDDLE
                275 => .back, // BTN_SIDE
                276 => .forward, // BTN_EXTRA
                else => return,
            };
            window.eventQueue.push(Event{
                .pointerButton = .{
                    .serial = serial,
                    .time = time,
                    .button = mapped,
                    .pressed = state == c.WL_POINTER_BUTTON_STATE_PRESSED,
                },
            });
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
            window.eventQueue.push(Event{
                .scroll = .{ .axis = @enumFromInt(axis), .offset = @floatCast(c.wl_fixed_to_double(value)) },
            });
            _ = time;
            _ = wlPointer;
        }

        fn pointerHandleFrame(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
        ) callconv(.c) void {
            _ = data;
            _ = wlPointer;
        }

        fn pointerHandleAxisSource(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            axisSource: u32,
        ) callconv(.c) void {
            _ = data;
            _ = wlPointer;
            _ = axisSource;
        }

        fn pointerHandleAxisStop(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            time: u32,
            axis: u32,
        ) callconv(.c) void {
            _ = data;
            _ = wlPointer;
            _ = time;
            _ = axis;
        }

        fn pointerHandleAxisDiscrete(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            axis: u32,
            discrete: i32,
        ) callconv(.c) void {
            _ = data;
            _ = wlPointer;
            _ = axis;
            _ = discrete;
        }

        fn pointerHandleAxisValue120(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            axis: u32,
            value120: i32,
        ) callconv(.c) void {
            _ = data;
            _ = wlPointer;
            _ = axis;
            _ = value120;
        }

        fn pointerHandleAxisRelativeDirection(
            data: ?*anyopaque,
            wlPointer: ?*c.wl_pointer,
            axis: u32,
            direction: u32,
        ) callconv(.c) void {
            _ = data;
            _ = wlPointer;
            _ = axis;
            _ = direction;
        }

        const wlPointerListener: c.wl_pointer_listener = .{
            .enter = pointerHandleEnter,
            .leave = pointerHandleLeave,
            .motion = pointerHandleMotion,
            .button = pointerHandleButton,
            .axis = pointerHandleAxis,
            .frame = pointerHandleFrame,
            .axis_source = pointerHandleAxisSource,
            .axis_stop = pointerHandleAxisStop,
            .axis_discrete = pointerHandleAxisDiscrete,
            .axis_value120 = pointerHandleAxisValue120,
            .axis_relative_direction = pointerHandleAxisRelativeDirection,
        };

        /// Look up the *unmodified* keysym for an xkb keycode under the current
        /// layout — i.e. what the key "is", not what it would type given the
        /// current Shift/AltGr state. This is what we want as a stable key
        /// identifier for `Keys.digit1`, `Keys.a`, etc.
        ///
        /// Returns 0 if the keycode produces no symbols at level 0.
        fn baseKeysymForKeycode(window: *Self, xkbKeycode: u32) u32 {
            const km = window.xkbKeymap orelse return 0;
            const xs = window.xkbState orelse return 0;
            const layout = c.xkb_state_key_get_layout(xs, xkbKeycode);
            var syms: [*c]const c.xkb_keysym_t = undefined;
            const n = c.xkb_keymap_key_get_syms_by_level(km, xkbKeycode, layout, 0, &syms);
            if (n <= 0) return 0;
            return syms[0];
        }

        /// Translate an XKB keysym into a single-key `Keys` set.
        /// Returns an empty set for keys not yet covered.
        fn keysymToKeys(sym: u32) Keys {
            if (sym >= c.XKB_KEY_a and sym <= c.XKB_KEY_z) return .at("a", sym - c.XKB_KEY_a);
            if (sym >= c.XKB_KEY_A and sym <= c.XKB_KEY_Z) return .at("a", sym - c.XKB_KEY_A);
            if (sym >= c.XKB_KEY_0 and sym <= c.XKB_KEY_9) return .at("digit0", sym - c.XKB_KEY_0);
            return switch (sym) {
                c.XKB_KEY_Tab, c.XKB_KEY_ISO_Left_Tab => .{ .tab = true },
                c.XKB_KEY_Escape => .{ .escape = true },
                c.XKB_KEY_Return, c.XKB_KEY_KP_Enter => .{ .enter = true },
                c.XKB_KEY_space => .{ .space = true },
                c.XKB_KEY_BackSpace => .{ .backspace = true },
                c.XKB_KEY_Delete => .{ .delete = true },
                c.XKB_KEY_Insert => .{ .insert = true },
                c.XKB_KEY_Home => .{ .home = true },
                c.XKB_KEY_End => .{ .end = true },
                c.XKB_KEY_Page_Up => .{ .pageUp = true },
                c.XKB_KEY_Page_Down => .{ .pageDown = true },
                c.XKB_KEY_Left => .{ .arrowLeft = true },
                c.XKB_KEY_Right => .{ .arrowRight = true },
                c.XKB_KEY_Up => .{ .arrowUp = true },
                c.XKB_KEY_Down => .{ .arrowDown = true },
                // Plain modifier keysyms are intentionally not mapped here —
                // shift/control/alt/super come from xkb_state's *effective*
                // modifier mask in `keyboardHandleModifiers`. That path also
                // catches XKB remaps like `caps:ctrl_modifier`, where pressing
                // CapsLock makes Control active even though the keysym stays
                // `Caps_Lock`.
                c.XKB_KEY_Caps_Lock => .{ .capsLock = true },
                c.XKB_KEY_F1 => .{ .f1 = true },
                c.XKB_KEY_F2 => .{ .f2 = true },
                c.XKB_KEY_F3 => .{ .f3 = true },
                c.XKB_KEY_F4 => .{ .f4 = true },
                c.XKB_KEY_F5 => .{ .f5 = true },
                c.XKB_KEY_F6 => .{ .f6 = true },
                c.XKB_KEY_F7 => .{ .f7 = true },
                c.XKB_KEY_F8 => .{ .f8 = true },
                c.XKB_KEY_F9 => .{ .f9 = true },
                c.XKB_KEY_F10 => .{ .f10 = true },
                c.XKB_KEY_F11 => .{ .f11 = true },
                c.XKB_KEY_F12 => .{ .f12 = true },
                else => .{},
            };
        }

        /// Append the visible face of a fed keysym to the compose preview.
        /// Dead keysyms have no unicode value of their own, so the common
        /// ones map to their spacing lookalikes, the way browsers render a
        /// pending dead key ("Jo~" while ~ waits for its letter).
        fn appendComposePreview(window: *Self, keysym: u32) void {
            const codepoint: u21 = switch (keysym) {
                c.XKB_KEY_dead_acute => '´',
                c.XKB_KEY_dead_grave => '`',
                c.XKB_KEY_dead_tilde => '~',
                c.XKB_KEY_dead_circumflex => '^',
                c.XKB_KEY_dead_diaeresis => '¨',
                c.XKB_KEY_dead_cedilla => '¸',
                c.XKB_KEY_dead_abovering => '°',
                c.XKB_KEY_dead_macron => '¯',
                c.XKB_KEY_Multi_key => '·',
                else => blk: {
                    const value = c.xkb_keysym_to_utf32(keysym);
                    break :blk if (value != 0 and value <= 0x10FFFF) @intCast(value) else return;
                },
            };
            var buffer: [4]u8 = undefined;
            const length = std.unicode.utf8Encode(codepoint, &buffer) catch return;
            if (window.composePreviewLength + length > window.composePreview.len) return;
            @memcpy(window.composePreview[window.composePreviewLength..][0..length], buffer[0..length]);
            window.composePreviewLength += length;
        }

        /// Publish the pending compose sequence as a preedit — empty when it
        /// resolved or cancelled, which removes the preview.
        fn pushComposePreview(window: *Self) void {
            var input = Event.Input{
                .composition = true,
                .preeditLength = window.composePreviewLength,
                .cursor = .{ window.composePreviewLength, window.composePreviewLength },
            };
            @memcpy(
                input.preeditBuffer[0..window.composePreviewLength],
                window.composePreview[0..window.composePreviewLength],
            );
            window.eventQueue.push(Event{ .input = input });
        }

        fn keyboardHandleKeymap(
            data: ?*anyopaque,
            wlKeyboard: ?*c.wl_keyboard,
            format: u32,
            fd: i32,
            size: u32,
        ) callconv(.c) void {
            std.debug.assert(format == c.WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1);
            const window: *Self = @ptrCast(@alignCast(data));

            const mapSharedMemory = std.posix.mmap(
                null,
                @intCast(size),
                .{ .READ = true },
                std.os.linux.MAP{ .TYPE = .PRIVATE },
                fd,
                0,
            ) catch |err| {
                std.log.err("failed to mmap keymap shared memory: {}", .{err});
                @panic("Could not mmap keymap shared memory");
            };
            defer std.posix.munmap(mapSharedMemory);
            defer _ = std.os.linux.close(fd);

            if (window.xkbKeymap) |previousKeymap| {
                c.xkb_keymap_unref(previousKeymap);
            }
            window.xkbKeymap = c.xkb_keymap_new_from_string(
                window.xkbContext,
                mapSharedMemory.ptr,
                c.XKB_KEYMAP_FORMAT_TEXT_V1,
                c.XKB_KEYMAP_COMPILE_NO_FLAGS,
            ) orelse @panic("failed to create xkb keymap from string");

            if (window.xkbState) |previousState| {
                c.xkb_state_unref(previousState);
            }
            window.xkbState = c.xkb_state_new(window.xkbKeymap) orelse @panic("failed to create xkb state from keymap");

            _ = wlKeyboard;
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
            _ = serial;
            const window: *Self = @ptrCast(@alignCast(data));

            // Focus is gone: stop any repeat and mark every held key as
            // released so keyup consumers see the transition, then clear the
            // held set so modifier levels read as released.
            window.activeRepeat = null;
            window.keyboard.releaseAll();
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
            _ = time;
            const window: *Self = @ptrCast(@alignCast(data));

            {
                window.clipboardMutex.lockUncancelable(window.io);
                defer window.clipboardMutex.unlock(window.io);
                window.keyboardSerial = serial;
            }

            // wl_keyboard reports evdev keycodes; xkb keycodes are evdev + 8.
            const xkbKeycode: u32 = key + 8;
            // We want the *base* (level-0) keysym so the key's identity is stable
            // across modifier state. `xkb_state_key_get_one_sym` would return e.g.
            // `XKB_KEY_exclam` when Shift+1 is pressed, and we'd lose the
            // `digit1` mapping. Looking up level 0 of the current layout gives
            // `XKB_KEY_1` regardless of held modifiers, while still respecting
            // the user's active keyboard layout.
            const keysym: u32 = baseKeysymForKeycode(window, xkbKeycode);
            const mapped: Keys = keysymToKeys(keysym);

            if (state == c.WL_KEYBOARD_KEY_STATE_PRESSED) {
                std.debug.assert(window.xkbState != null);

                var characterBuffer: [7:0]u8 = undefined;
                var characterLength: usize = @intCast(c.xkb_state_key_get_utf8(
                    window.xkbState,
                    xkbKeycode,
                    &characterBuffer,
                    characterBuffer.len,
                ));
                std.debug.assert(characterLength <= characterBuffer.len);

                // Dead-key accents never reach any IME: xkb composes them
                // client-side. Feed the effective (shift-aware) keysym; while
                // a sequence is pending the key types nothing, and the key
                // that completes it types the composed character instead of
                // its own.
                if (window.xkbComposeState) |composeState| {
                    const keysymEffective = c.xkb_state_key_get_one_sym(window.xkbState, xkbKeycode);
                    if (c.xkb_compose_state_feed(composeState, keysymEffective) == c.XKB_COMPOSE_FEED_ACCEPTED) {
                        switch (c.xkb_compose_state_get_status(composeState)) {
                            c.XKB_COMPOSE_COMPOSING => {
                                characterLength = 0;
                                window.appendComposePreview(keysymEffective);
                                window.pushComposePreview();
                            },
                            c.XKB_COMPOSE_CANCELLED => {
                                characterLength = 0;
                                c.xkb_compose_state_reset(composeState);
                                window.composePreviewLength = 0;
                                window.pushComposePreview();
                            },
                            c.XKB_COMPOSE_COMPOSED => {
                                characterLength = @min(@as(usize, @intCast(c.xkb_compose_state_get_utf8(
                                    composeState,
                                    &characterBuffer,
                                    characterBuffer.len,
                                ))), characterBuffer.len);
                                c.xkb_compose_state_reset(composeState);
                                window.composePreviewLength = 0;
                                window.pushComposePreview();
                            },
                            else => {},
                        }
                    }
                }
                // Control codepoints (C0, DEL, C1) aren't text; route them through
                // `Keys` only.
                const codepoint = if (characterLength > 0) std.unicode.utf8Decode(characterBuffer[0..characterLength]) catch null else null;
                const isControl = if (codepoint) |cp| cp < 0x20 or (cp >= 0x7f and cp <= 0x9f) else false;
                const hasText = characterLength > 0 and !isControl;

                if (hasText) {
                    var input = Event.Input{ .textLength = characterLength };
                    @memcpy(input.textBuffer[0..characterLength], characterBuffer[0..characterLength]);
                    window.eventQueue.push(Event{ .input = input });
                }

                // The keymap says which keys auto-repeat: arrows, letters,
                // backspace do; modifiers don't — so pressing Shift mid-repeat
                // no longer steals the timer from the repeating key.
                if (window.xkbKeymap != null and c.xkb_keymap_key_repeats(window.xkbKeymap, xkbKeycode) == 1) {
                    window.activeRepeat = .{
                        .xkbKeycode = xkbKeycode,
                        .key = mapped,
                        .characterBuffer = characterBuffer,
                        .characterLength = if (hasText) characterLength else 0,
                        .totalRepeats = 0,
                        .startTime = std.Io.Clock.now(.awake, window.io),
                    };
                }

                window.keyboard.keyDown(mapped);
            } else if (state == c.WL_KEYBOARD_KEY_STATE_RELEASED) {
                if (window.activeRepeat) |activeRepeat| {
                    if (activeRepeat.xkbKeycode == xkbKeycode) {
                        window.activeRepeat = null;
                    }
                }

                window.keyboard.keyUp(mapped);
            }
        }

        fn keyboardHandleModifiers(
            data: ?*anyopaque,
            wl_keyboard: ?*c.wl_keyboard,
            serial: u32,
            modsDepressed: u32,
            modsLatched: u32,
            modsLocked: u32,
            group: u32,
        ) callconv(.c) void {
            _ = wl_keyboard;
            _ = serial;

            const window: *Self = @ptrCast(@alignCast(data));

            const xkbState = window.xkbState orelse return;
            _ = c.xkb_state_update_mask(xkbState, modsDepressed, modsLatched, modsLocked, 0, 0, group);

            // Translate the effective xkb modifier mask into our `Keys` modifier
            // bits. This is the path that picks up remaps like `caps:ctrl_modifier`
            // — pressing CapsLock makes `Control` active here even though the
            // keysym in `keyboardHandleKey` is still `Caps_Lock`.
            const effective: c_int = c.XKB_STATE_MODS_EFFECTIVE;
            var newMods: Keys = .{};
            newMods.shift = c.xkb_state_mod_name_is_active(xkbState, c.XKB_MOD_NAME_SHIFT, effective) > 0;
            newMods.control = c.xkb_state_mod_name_is_active(xkbState, c.XKB_MOD_NAME_CTRL, effective) > 0;
            newMods.alt = c.xkb_state_mod_name_is_active(xkbState, c.XKB_MOD_NAME_ALT, effective) > 0;
            newMods.super = c.xkb_state_mod_name_is_active(xkbState, c.XKB_MOD_NAME_LOGO, effective) > 0;

            window.keyboard.setHeldModifiers(newMods);
        }

        fn keyboardHandleRepeatInfo(
            data: ?*anyopaque,
            _: ?*c.wl_keyboard,
            // the rate of repeating keys in characters per second
            rate: i32,
            // delay in milliseconds since key down until repeating starts
            delay: i32,
        ) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data));

            window.repeatInfo = .{
                .rate = rate,
                .delay = delay,
            };
        }

        const wlKeyboardListener: c.wl_keyboard_listener = .{
            .keymap = keyboardHandleKeymap,
            // TODO: should we be tracking some state based on enter and leave here?
            // Does not doing this introduce some kind of bug?
            .enter = keyboardHandleEnter,
            .leave = keyboardHandleLeave,
            .key = keyboardHandleKey,
            .modifiers = keyboardHandleModifiers,
            .repeat_info = keyboardHandleRepeatInfo,
        };

        pub fn updateDpi(self: *Self) void {
            const millimetersPerInch = 25.4;

            if (self.monitorWidth <= 0 or self.monitorHeight <= 0 or self.physicalWidthMilimeters <= 0 or self.physicalHeightMilimeters <= 0) {
                const fallbackDpi = @max(
                    @as(u32, 1),
                    @as(u32, @intFromFloat(@round(96.0 * self.scale))),
                );
                self.dpi = .{ fallbackDpi, fallbackDpi };
                return;
            }

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
            io: std.Io,
            width: u32,
            height: u32,
            title: [:0]const u8,
            appId: [:0]const u8,
        ) !*Self {
            // I really dislike that we need to keep this in the heap, I feel like this
            // is an artifact from libwayland and might not really be a problem if we
            // implemented our own wayland client from scratch
            const window = try allocator.create(Self);
            errdefer allocator.destroy(window);
            window.allocator = allocator;
            window.io = io;

            window.width = width;
            window.height = height;
            window.scale = 1.0;
            window.dpi = .{ 96, 96 };
            window.title = title;
            window.appId = appId;
            window.running = .init(true);
            window.eventQueue = .empty;
            window.handlers = .{};

            window.xkbContext = c.xkb_context_new(c.XKB_CONTEXT_NO_FLAGS) orelse return error.FailedToCreateXkbContext;
            errdefer c.xkb_context_unref(window.xkbContext);
            window.xkbKeymap = null;
            window.xkbState = null;

            window.xkbComposeState = null;
            window.composePreview = undefined;
            window.composePreviewLength = 0;
            const locale: [*:0]const u8 = std.c.getenv("LC_ALL") orelse std.c.getenv("LC_CTYPE") orelse std.c.getenv("LANG") orelse "C";
            if (c.xkb_compose_table_new_from_locale(window.xkbContext, locale, c.XKB_COMPOSE_COMPILE_NO_FLAGS)) |composeTable| {
                // The state holds its own reference to the table.
                defer c.xkb_compose_table_unref(composeTable);
                window.xkbComposeState = c.xkb_compose_state_new(composeTable, c.XKB_COMPOSE_STATE_NO_FLAGS);
            } else {
                std.log.warn("no compose table for locale {s}; dead keys won't compose accents", .{std.mem.span(locale)});
            }

            window.keyboard = .{};
            window.activeRepeat = null;
            // Some setups never emit repeat_info; default to typical X11 values.
            window.repeatInfo = .{ .rate = 25, .delay = 600 };
            window.keyboardSerial = 0;

            window.clipboardMutex = .init;
            window.clipboardSource = null;
            window.clipboardText = &.{};
            window.selectionOffer = null;

            // Initialize optional fields to null before the registry roundtrip,
            // since allocator.create does not zero-initialize memory.
            window.pointerSerial = null;
            window.wpFractionalScaleManager = null;
            window.wpViewporter = null;
            window.xdgDecorationManager = null;
            window.xdgToplevelDecoration = null;
            window.wlDataDeviceManager = null;
            window.wlDataDevice = null;
            window.wpFractionalScale = null;
            window.wpViewport = null;
            window.zwpTextInputManager = null;
            window.zwpTextInput = null;
            window.textInputPending = .empty;
            window.textInputMutex = .init;
            window.textInputWanted = false;
            window.textInputFocused = false;
            window.textInputArea = .{ .x = 0, .y = 0, .width = 1, .height = 1 };

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
            c.xdg_toplevel_set_app_id(window.xdgToplevel, appId.ptr);

            if (window.xdgDecorationManager) |manager| {
                window.xdgToplevelDecoration = c.zxdg_decoration_manager_v1_get_toplevel_decoration(manager, window.xdgToplevel);
                if (window.xdgToplevelDecoration) |decoration| {
                    c.zxdg_toplevel_decoration_v1_set_mode(decoration, c.ZXDG_TOPLEVEL_DECORATION_V1_MODE_SERVER_SIDE);
                    _ = c.zxdg_toplevel_decoration_v1_add_listener(decoration, &xdgToplevelDecorationListener, @ptrCast(@alignCast(window)));
                }
            }

            if (window.wpFractionalScaleManager) |manager| {
                window.wpFractionalScale = c.wp_fractional_scale_manager_v1_get_fractional_scale(manager, window.wlSurface);
                _ = c.wp_fractional_scale_v1_add_listener(window.wpFractionalScale, &fractionalScaleListener, @ptrCast(@alignCast(window)));
            }

            if (window.wpViewporter) |viewporter| {
                window.wpViewport = c.wp_viewporter_get_viewport(viewporter, window.wlSurface);
                c.wp_viewport_set_destination(window.wpViewport, @intCast(window.width), @intCast(window.height));
            }

            if (window.wlDataDeviceManager) |manager| {
                window.wlDataDevice = c.wl_data_device_manager_get_data_device(
                    manager,
                    window.wlSeat,
                ) orelse return error.UnableToGetDataDevice;
                _ = c.wl_data_device_add_listener(window.wlDataDevice, &wlDataDeviceListener, @ptrCast(@alignCast(window)));
            }

            if (window.zwpTextInputManager) |manager| {
                window.zwpTextInput = c.zwp_text_input_manager_v3_get_text_input(
                    manager,
                    window.wlSeat,
                ) orelse return error.UnableToGetTextInput;
                _ = c.zwp_text_input_v3_add_listener(window.zwpTextInput, &textInputListener, @ptrCast(@alignCast(window)));
            }

            c.wl_surface_commit(window.wlSurface);
            _ = c.wl_display_roundtrip(window.wlDisplay);

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
            const effectiveSerial = if (serial != 0)
                serial
            else
                self.pointerSerial orelse return;

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
                effectiveSerial,
                self.cursorWlSurface,
                @intCast(wlCursorImage.*.hotspot_x),
                @intCast(wlCursorImage.*.hotspot_y),
            );
        }

        /// Mime type we offer and request; effectively universal among apps
        /// that put text on the clipboard (GTK, Qt, browsers, terminals).
        const clipboardMimeType = "text/plain;charset=utf-8";

        fn dataSourceSend(
            data: ?*anyopaque,
            source: ?*c.wl_data_source,
            mimeType: [*c]const u8,
            fd: i32,
        ) callconv(.c) void {
            _ = source;
            _ = mimeType;
            const window: *Self = @ptrCast(@alignCast(data));
            const file: std.Io.File = .{ .handle = fd, .flags = .{ .nonblocking = false } };
            defer file.close(window.io);

            window.clipboardMutex.lockUncancelable(window.io);
            const text = window.clipboardText;
            window.clipboardMutex.unlock(window.io);

            file.writeStreamingAll(window.io, text) catch |err| {
                std.log.err("clipboard: failed writing selection to requester: {}", .{err});
            };
        }

        fn dataSourceCancelled(data: ?*anyopaque, source: ?*c.wl_data_source) callconv(.c) void {
            const window: *Self = @ptrCast(@alignCast(data));

            window.clipboardMutex.lockUncancelable(window.io);
            defer window.clipboardMutex.unlock(window.io);
            // Another app took the selection; only free if `source` is still
            // the one we last handed to `wl_data_device_set_selection` — a
            // `setClipboardText` call already destroyed/replaced anything older.
            if (window.clipboardSource == source) {
                c.wl_data_source_destroy(source);
                window.allocator.free(window.clipboardText);
                window.clipboardText = &.{};
                window.clipboardSource = null;
            }
        }

        fn dataSourceTarget(data: ?*anyopaque, source: ?*c.wl_data_source, mimeType: [*c]const u8) callconv(.c) void {
            _ = data;
            _ = source;
            // Meant for drag-and-drop feedback, but a receiving client
            // calling `wl_data_offer.accept` on our clipboard offer gets
            // forwarded here too, so it arrives in practice.
            _ = mimeType;
        }

        fn dataSourceDndDropPerformed(data: ?*anyopaque, source: ?*c.wl_data_source) callconv(.c) void {
            _ = data;
            _ = source;
        }

        fn dataSourceDndFinished(data: ?*anyopaque, source: ?*c.wl_data_source) callconv(.c) void {
            _ = data;
            _ = source;
        }

        fn dataSourceAction(data: ?*anyopaque, source: ?*c.wl_data_source, dndAction: u32) callconv(.c) void {
            _ = data;
            _ = source;
            _ = dndAction;
        }

        // Like `wlDataDeviceListener`: every slot needs a function even for
        // events we ignore, since libwayland aborts on a NULL entry the
        // moment that event arrives.
        const dataSourceListener: c.wl_data_source_listener = .{
            .target = dataSourceTarget,
            .send = dataSourceSend,
            .cancelled = dataSourceCancelled,
            .dnd_drop_performed = dataSourceDndDropPerformed,
            .dnd_finished = dataSourceDndFinished,
            .action = dataSourceAction,
        };

        fn dataDeviceSelection(data: ?*anyopaque, dataDevice: ?*c.wl_data_device, offer: ?*c.wl_data_offer) callconv(.c) void {
            _ = dataDevice;
            const window: *Self = @ptrCast(@alignCast(data));

            window.clipboardMutex.lockUncancelable(window.io);
            defer window.clipboardMutex.unlock(window.io);
            if (window.selectionOffer) |old| c.wl_data_offer_destroy(old);
            window.selectionOffer = offer;
        }

        fn dataDeviceDataOffer(data: ?*anyopaque, dataDevice: ?*c.wl_data_device, offer: ?*c.wl_data_offer) callconv(.c) void {
            _ = data;
            _ = dataDevice;
            // Just introduces the object; `selection` re-delivers the same
            // pointer once it's known to be the clipboard offer, and `enter`
            // delivers (and destroys) the drag-and-drop ones.
            _ = offer;
        }

        fn dataDeviceEnter(
            data: ?*anyopaque,
            dataDevice: ?*c.wl_data_device,
            serial: u32,
            surface: ?*c.wl_surface,
            x: c.wl_fixed_t,
            y: c.wl_fixed_t,
            offer: ?*c.wl_data_offer,
        ) callconv(.c) void {
            _ = data;
            _ = dataDevice;
            _ = serial;
            _ = surface;
            _ = x;
            _ = y;
            // We never accept drops, and drag offers are not re-delivered
            // through `selection`, so this is the only chance to free them.
            if (offer) |dragOffer| c.wl_data_offer_destroy(dragOffer);
        }

        fn dataDeviceLeave(data: ?*anyopaque, dataDevice: ?*c.wl_data_device) callconv(.c) void {
            _ = data;
            _ = dataDevice;
        }

        fn dataDeviceMotion(data: ?*anyopaque, dataDevice: ?*c.wl_data_device, time: u32, x: c.wl_fixed_t, y: c.wl_fixed_t) callconv(.c) void {
            _ = data;
            _ = dataDevice;
            _ = time;
            _ = x;
            _ = y;
        }

        fn dataDeviceDrop(data: ?*anyopaque, dataDevice: ?*c.wl_data_device) callconv(.c) void {
            _ = data;
            _ = dataDevice;
        }

        // We only care about the clipboard, not drag-and-drop, but every slot
        // still needs a function: libwayland aborts the process on a NULL
        // listener entry the moment that event arrives ("listener function
        // for opcode N of wl_data_device is NULL").
        const wlDataDeviceListener: c.wl_data_device_listener = .{
            .data_offer = dataDeviceDataOffer,
            .enter = dataDeviceEnter,
            .leave = dataDeviceLeave,
            .motion = dataDeviceMotion,
            .drop = dataDeviceDrop,
            .selection = dataDeviceSelection,
        };

        const TextInputPending = struct {
            preeditBuffer: [120]u8,
            preeditLength: usize,
            cursorBegin: i32,
            cursorEnd: i32,
            deleteBefore: u32,
            deleteAfter: u32,
            commitBuffer: [120]u8,
            commitLength: usize,

            const empty: @This() = .{
                .preeditBuffer = undefined,
                .preeditLength = 0,
                .cursorBegin = 0,
                .cursorEnd = 0,
                .deleteBefore = 0,
                .deleteAfter = 0,
                .commitBuffer = undefined,
                .commitLength = 0,
            };
        };

        /// Copy a text-input string into `buffer`, truncating at a UTF-8
        /// boundary when it doesn't fit — the IME keeps composing fine, only
        /// what we relay is clipped.
        fn copyTextInputString(textPtr: [*c]const u8, buffer: []u8) usize {
            if (textPtr == null) return 0;
            const full = std.mem.span(@as([*:0]const u8, @ptrCast(textPtr)));
            var length = @min(full.len, buffer.len);
            if (length < full.len) {
                std.log.warn("text-input string of {} bytes truncated to {}", .{ full.len, buffer.len });
                while (length > 0 and full[length] & 0xC0 == 0x80) length -= 1;
            }
            @memcpy(buffer[0..length], full[0..length]);
            return length;
        }

        fn textInputEnter(data: ?*anyopaque, textInput: ?*c.zwp_text_input_v3, surface: ?*c.wl_surface) callconv(.c) void {
            _ = surface;
            const window: *Self = @ptrCast(@alignCast(data));

            window.textInputMutex.lockUncancelable(window.io);
            defer window.textInputMutex.unlock(window.io);
            window.textInputFocused = true;
            // Enable resets on every focus change, so re-request what the
            // app last declared it wanted.
            if (window.textInputWanted) {
                c.zwp_text_input_v3_enable(textInput);
                const area = window.textInputArea;
                c.zwp_text_input_v3_set_cursor_rectangle(textInput, area.x, area.y, area.width, area.height);
                c.zwp_text_input_v3_commit(textInput);
            }
        }

        fn textInputLeave(data: ?*anyopaque, textInput: ?*c.zwp_text_input_v3, surface: ?*c.wl_surface) callconv(.c) void {
            _ = textInput;
            _ = surface;
            const window: *Self = @ptrCast(@alignCast(data));

            window.textInputMutex.lockUncancelable(window.io);
            defer window.textInputMutex.unlock(window.io);
            // The compositor deactivates the text input on leave by itself.
            window.textInputFocused = false;
            window.textInputPending = .empty;
        }

        fn textInputPreeditString(
            data: ?*anyopaque,
            textInput: ?*c.zwp_text_input_v3,
            textPtr: [*c]const u8,
            cursorBegin: i32,
            cursorEnd: i32,
        ) callconv(.c) void {
            _ = textInput;
            const window: *Self = @ptrCast(@alignCast(data));
            window.textInputPending.preeditLength = copyTextInputString(textPtr, &window.textInputPending.preeditBuffer);
            window.textInputPending.cursorBegin = cursorBegin;
            window.textInputPending.cursorEnd = cursorEnd;
        }

        fn textInputCommitString(data: ?*anyopaque, textInput: ?*c.zwp_text_input_v3, textPtr: [*c]const u8) callconv(.c) void {
            _ = textInput;
            const window: *Self = @ptrCast(@alignCast(data));
            window.textInputPending.commitLength = copyTextInputString(textPtr, &window.textInputPending.commitBuffer);
        }

        fn textInputDeleteSurroundingText(
            data: ?*anyopaque,
            textInput: ?*c.zwp_text_input_v3,
            beforeLength: u32,
            afterLength: u32,
        ) callconv(.c) void {
            _ = textInput;
            const window: *Self = @ptrCast(@alignCast(data));
            window.textInputPending.deleteBefore = beforeLength;
            window.textInputPending.deleteAfter = afterLength;
        }

        fn textInputDone(data: ?*anyopaque, textInput: ?*c.zwp_text_input_v3, serial: u32) callconv(.c) void {
            _ = textInput;
            _ = serial;
            const window: *Self = @ptrCast(@alignCast(data));
            const pending = &window.textInputPending;

            // A negative preedit cursor means "hide the caret"; land it at
            // the preedit's end.
            const cursorBegin: usize = if (pending.cursorBegin < 0)
                pending.preeditLength
            else
                @min(@as(usize, @intCast(pending.cursorBegin)), pending.preeditLength);
            const cursorEnd: usize = if (pending.cursorEnd < 0)
                pending.preeditLength
            else
                @min(@as(usize, @intCast(pending.cursorEnd)), pending.preeditLength);

            // The whole batch — commit, preedit, deletions — as it arrived,
            // in one event.
            var input = Event.Input{
                .textLength = pending.commitLength,
                .composition = true,
                .preeditBuffer = pending.preeditBuffer,
                .preeditLength = pending.preeditLength,
                .cursor = .{ @min(cursorBegin, cursorEnd), @max(cursorBegin, cursorEnd) },
                .deleteBefore = pending.deleteBefore,
                .deleteAfter = pending.deleteAfter,
            };
            @memcpy(input.textBuffer[0..pending.commitLength], pending.commitBuffer[0..pending.commitLength]);
            window.eventQueue.push(Event{ .input = input });

            pending.* = .empty;
        }

        const textInputListener: c.zwp_text_input_v3_listener = .{
            .enter = textInputEnter,
            .leave = textInputLeave,
            .preedit_string = textInputPreeditString,
            .commit_string = textInputCommitString,
            .delete_surrounding_text = textInputDeleteSurroundingText,
            .done = textInputDone,
        };

        /// Declares whether the app wants IME input right now and where the
        /// caret is. Diffed — requests only go out on change — and safe to
        /// call from the render thread like `setClipboardText`.
        pub fn setTextInput(self: *Self, request: ?TextInputArea) void {
            const textInput = self.zwpTextInput orelse return;

            self.textInputMutex.lockUncancelable(self.io);
            defer self.textInputMutex.unlock(self.io);

            const wanted = request != null;
            const wantedChanged = wanted != self.textInputWanted;
            self.textInputWanted = wanted;
            var areaChanged = false;
            if (request) |area| {
                areaChanged = !std.meta.eql(area, self.textInputArea);
                self.textInputArea = area;
            }
            if (!self.textInputFocused) return;

            var dirty = false;
            if (wantedChanged) {
                if (wanted) {
                    c.zwp_text_input_v3_enable(textInput);
                } else {
                    c.zwp_text_input_v3_disable(textInput);
                }
                dirty = true;
            }
            if (wanted and (wantedChanged or areaChanged)) {
                const area = self.textInputArea;
                c.zwp_text_input_v3_set_cursor_rectangle(textInput, area.x, area.y, area.width, area.height);
                dirty = true;
            }
            if (dirty) {
                c.zwp_text_input_v3_commit(textInput);
                _ = c.wl_display_flush(self.wlDisplay);
            }
        }

        /// Copies `text` into an `allocator`-owned buffer, since the caller's
        /// slice (typically frame- or scope-arena-backed) won't outlive this call.
        pub fn setClipboardText(self: *Self, text: []const u8) !void {
            const manager = self.wlDataDeviceManager orelse return error.ClipboardUnavailable;
            const dataDevice = self.wlDataDevice orelse return error.ClipboardUnavailable;

            const owned = try self.allocator.dupe(u8, text);
            errdefer self.allocator.free(owned);

            const source = c.wl_data_device_manager_create_data_source(manager) orelse
                return error.FailedToCreateDataSource;
            _ = c.wl_data_source_add_listener(source, &dataSourceListener, self);
            _ = c.wl_data_source_offer(source, clipboardMimeType);

            self.clipboardMutex.lockUncancelable(self.io);
            defer self.clipboardMutex.unlock(self.io);

            c.wl_data_device_set_selection(dataDevice, source, self.keyboardSerial);
            _ = c.wl_display_flush(self.wlDisplay);

            if (self.clipboardSource) |old| c.wl_data_source_destroy(old);
            self.allocator.free(self.clipboardText);
            self.clipboardSource = source;
            self.clipboardText = owned;
        }

        /// Reads the current clipboard selection as text, allocated with
        /// `allocator`. Returns `null` if there's no selection, the source
        /// doesn't offer `clipboardMimeType`, or it doesn't answer within
        /// a second — a stuck/dead clipboard owner shouldn't hang the caller.
        pub fn getClipboardText(self: *Self, allocator: std.mem.Allocator) !?[]const u8 {
            self.clipboardMutex.lockUncancelable(self.io);
            const offer = self.selectionOffer;
            self.clipboardMutex.unlock(self.io);
            const dataOffer = offer orelse return null;

            // `Io` has no portable pipe-creation primitive (see `Io.File`),
            // so the pipe itself is the one raw syscall here; the read/close
            // that follow go through `Io.File` like the rest of this codebase.
            var pipeFds: [2]std.c.fd_t = undefined;
            if (std.c.pipe(&pipeFds) != 0) return error.FailedToCreatePipe;
            const readFile: std.Io.File = .{ .handle = pipeFds[0], .flags = .{ .nonblocking = false } };
            const writeFile: std.Io.File = .{ .handle = pipeFds[1], .flags = .{ .nonblocking = false } };

            c.wl_data_offer_receive(dataOffer, clipboardMimeType, writeFile.handle);
            // Our copy of the write end must close before we block on the
            // read end, so the read observes EOF once the source client
            // (which got its own copy of the fd via the compositor) closes
            // its side — otherwise we'd wait on a pipe we're still holding open.
            writeFile.close(self.io);
            _ = c.wl_display_flush(self.wlDisplay);

            defer readFile.close(self.io);

            var list = std.ArrayList(u8).empty;
            errdefer list.deinit(allocator);
            var buffer: [4096]u8 = undefined;
            while (true) {
                const result = self.io.operateTimeout(
                    .{ .file_read_streaming = .{ .file = readFile, .data = &.{buffer[0..]} } },
                    .{ .duration = .{ .raw = .fromSeconds(1), .clock = .awake } },
                ) catch break; // timed out, or cancelled
                const n = result.file_read_streaming catch break; // EndOfStream, or a real read error
                if (n == 0) break;
                try list.appendSlice(allocator, buffer[0..n]);
            }

            if (list.items.len == 0) {
                list.deinit(allocator);
                return null;
            }
            return try list.toOwnedSlice(allocator);
        }

        pub fn handleEvents(self: *Self) !void {
            while (self.running.load(.acquire)) {
                if (c.wl_display_dispatch(self.wlDisplay) == -1) {
                    return error.WaylandDispatchFailed;
                }

                if (self.activeRepeat) |*activeRepeat| {
                    const elapsedMilliseconds: f64 = @floatFromInt(activeRepeat.startTime.untilNow(self.io, .awake).toMilliseconds());
                    const delay: f64 = @floatFromInt(self.repeatInfo.delay);
                    const rate: f64 = @floatFromInt(self.repeatInfo.rate);
                    if (elapsedMilliseconds >= delay) {
                        const due: usize = @trunc((elapsedMilliseconds - delay) * rate / 1000);
                        const new = due - activeRepeat.totalRepeats;
                        if (new > 0) {
                            activeRepeat.totalRepeats += new;
                            // Reuses the same pendingPressed queue as a fresh press.
                            self.keyboard.pendingPressed = self.keyboard.pendingPressed.with(activeRepeat.key);
                            if (activeRepeat.characterLength > 0) {
                                var input = Event.Input{
                                    .textLength = activeRepeat.characterLength,
                                    .repeats = new,
                                };
                                @memcpy(
                                    input.textBuffer[0..activeRepeat.characterLength],
                                    activeRepeat.characterBuffer[0..activeRepeat.characterLength],
                                );
                                self.eventQueue.push(Event{ .input = input });
                            }
                        }
                    }
                }

                self.keyboard.flush(&self.eventQueue);
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
            if (self.xdgToplevelDecoration) |decoration| c.zxdg_toplevel_decoration_v1_destroy(decoration);
            if (self.wpFractionalScale) |fs| c.wp_fractional_scale_v1_destroy(fs);
            if (self.wpViewport) |vp| c.wp_viewport_destroy(vp);

            if (self.selectionOffer) |offer| c.wl_data_offer_destroy(offer);
            if (self.clipboardSource) |source| c.wl_data_source_destroy(source);
            self.allocator.free(self.clipboardText);
            if (self.wlDataDevice) |dd| c.wl_data_device_release(dd);
            if (self.wlDataDeviceManager) |ddm| c.wl_data_device_manager_destroy(ddm);

            if (self.zwpTextInput) |textInput| c.zwp_text_input_v3_destroy(textInput);
            if (self.zwpTextInputManager) |manager| c.zwp_text_input_manager_v3_destroy(manager);

            c.xdg_toplevel_destroy(self.xdgToplevel);
            c.xdg_surface_destroy(self.xdgSurface);

            c.wl_cursor_theme_destroy(self.wlCursorTheme);
            c.wl_pointer_destroy(self.wlPointer);
            c.wl_keyboard_destroy(self.wlKeyboard);
            if (self.xdgDecorationManager) |dm| c.zxdg_decoration_manager_v1_destroy(dm);
            if (self.wpFractionalScaleManager) |fsm| c.wp_fractional_scale_manager_v1_destroy(fsm);
            if (self.wpViewporter) |vp| c.wp_viewporter_destroy(vp);
            c.wl_shm_destroy(self.wlShm);
            c.wl_compositor_destroy(self.wlCompositor);

            c.xdg_wm_base_destroy(self.xdgWmBase);

            c.wl_surface_destroy(self.wlSurface);
            c.wl_registry_destroy(self.wlRegistry);

            c.wl_display_disconnect(self.wlDisplay);

            if (self.xkbComposeState) |composeState| {
                c.xkb_compose_state_unref(composeState);
            }
            if (self.xkbState) |xkbState| {
                c.xkb_state_unref(xkbState);
            }
            if (self.xkbKeymap) |xkbKeymap| {
                c.xkb_keymap_unref(xkbKeymap);
            }
            c.xkb_context_unref(self.xkbContext);

            self.allocator.destroy(self);
        }
    },
    .windows => struct {
        handle: HWND,
        hInstance: HINSTANCE,

        width: u32,
        height: u32,
        title: [:0]const u16,
        className: [:0]const u16,
        running: std.atomic.Value(bool),
        dpi: [2]u32,

        /// `wndProc` runs synchronously inside `DispatchMessageW` on the event
        /// thread, so it shares a thread with `handleEvents` and needs no
        /// lock; `handleEvents` drains it into `eventQueue` each iteration so
        /// the render thread only ever observes pushed events.
        keyboard: KeyboardState = .{},
        /// A WM_CHAR carrying a UTF-16 high surrogate is held here until its paired
        /// low-surrogate WM_CHAR arrives, so astral-plane codepoints survive.
        pendingHighSurrogate: ?u16 = null,
        /// A WM_DEADCHAR is being previewed as a preedit until its WM_CHAR
        /// resolves it — the OS composes dead keys itself and shows nothing.
        deadCharPending: bool = false,
        /// Whether the pointer is over the client area. Win32 has no native
        /// enter event, so the first WM_MOUSEMOVE after a WM_MOUSELEAVE
        /// synthesizes `pointerEnter` and re-arms `TrackMouseEvent`.
        mouseInside: bool = false,

        /// The cursor the render thread last asked for. `SetCursor` only
        /// works from the window thread, and the OS resets the cursor on
        /// every mouse move anyway, so it is reasserted in WM_SETCURSOR.
        cursor: std.atomic.Value(Cursor) = .init(.default),

        /// IME request state: written by the render thread (`setTextInput`),
        /// applied in `wndProc` via a posted `WM_APP_TEXT_INPUT` — IMM32
        /// input contexts are bound to the thread that owns the window.
        textInputMutex: std.Io.Mutex = .init,
        textInputWanted: bool = false,
        textInputApplied: bool = false,
        textInputArea: TextInputArea = .{ .x = 0, .y = 0, .width = 1, .height = 1 },

        eventQueue: EventQueue = .empty,

        // Resize is delivered as a direct callback on the window thread instead of
        // through `eventQueue`, so the swapchain is recreated synchronously while
        // the Win32 modal move/size loop holds this thread — letting frames track
        // the drag rather than stalling until release.
        handlers: struct {
            resize: ?struct {
                data: *anyopaque,
                function: *const fn (window: *Self, newWidth: u32, newHeight: u32, newDpi: [2]u32, data: *anyopaque) void,
            } = null,
        } = .{},

        allocator: std.mem.Allocator,
        io: std.Io,

        const Self = @This();

        fn virtualKeyToKeys(vk: WPARAM) Keys {
            if (vk >= '0' and vk <= '9') return .at("digit0", @intCast(vk - '0'));
            if (vk >= 'A' and vk <= 'Z') return .at("a", @intCast(vk - 'A'));
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
                0x5B, 0x5C => .{ .super = true },
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
                // Modifier VKs (`VK_*SHIFT/CONTROL/MENU/LWIN/RWIN`) are
                // intentionally not mapped here — `refreshModifiersFromOS`
                // samples the OS's combined state on every key event so the
                // collapsed `.shift/.control/.alt/.super` flags stay correct
                // when one side is released while the other is still held.
                else => .{},
            };
        }

        /// Samples the OS's effective modifier state via `GetKeyState` into
        /// `self.keyboard`; modifiers that flipped off become keyup edges.
        fn refreshModifiersFromOS(self: *Self) void {
            const down = struct {
                fn f(vk: c_int) bool {
                    return (GetKeyState(vk) & @as(i16, @bitCast(@as(u16, 0x8000)))) != 0;
                }
            }.f;

            var current: Keys = .{};
            // `VK_SHIFT/CONTROL/MENU` themselves report the OR of L/R state.
            current.shift = down(VK_SHIFT);
            current.control = down(VK_CONTROL);
            current.alt = down(VK_MENU);
            // No combined "Windows key" VK — OR the two sides explicitly.
            current.super = down(VK_LWIN) or down(VK_RWIN);

            self.keyboard.setHeldModifiers(current);
        }

        pub fn init(
            allocator: std.mem.Allocator,
            io: std.Io,
            width: u32,
            height: u32,
            title: [:0]const u8,
            className: [:0]const u8,
        ) !*Self {
            const window = try allocator.create(Self);
            errdefer allocator.destroy(window);

            window.width = width;
            window.height = height;
            window.title = try std.unicode.utf8ToUtf16LeAllocZ(allocator, title);
            errdefer allocator.free(window.title);
            window.className = try std.unicode.utf8ToUtf16LeAllocZ(allocator, className);
            errdefer allocator.free(window.className);
            window.running = .init(true);
            window.eventQueue = .empty;

            window.keyboard = .{};
            window.pendingHighSurrogate = null;
            window.deadCharPending = false;
            window.mouseInside = false;
            window.cursor = .init(.default);
            window.eventQueue = .empty;
            window.handlers = .{};

            window.textInputMutex = .init;
            window.textInputWanted = false;
            window.textInputApplied = false;
            window.textInputArea = .{ .x = 0, .y = 0, .width = 1, .height = 1 };

            window.allocator = allocator;
            window.io = io;

            window.hInstance = GetModuleHandleW(null);
            if (window.hInstance == null) {
                return error.CouldNotFindHInstance;
            }

            const windowClass = WNDCLASSEXW{
                .hInstance = window.hInstance,
                .style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC,
                .lpfnWndProc = wndProc,
                .hCursor = LoadCursorW(null, IDC_ARROW),
                .lpszClassName = window.className.ptr,
            };

            if (RegisterClassExW(&windowClass) == 0) {
                return error.FailedToRegisterWindowClass;
            }

            _ = SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
            _ = SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

            var rect = RECT{ .left = 0, .top = 0, .right = @intCast(width), .bottom = @intCast(height) };
            const style = WS_OVERLAPPEDWINDOW | WS_VISIBLE;
            _ = AdjustWindowRectEx(&rect, style, 0, 0);

            window.handle = CreateWindowExW(
                0,
                window.className.ptr,
                window.title.ptr,
                style,
                CW_USEDEFAULT,
                CW_USEDEFAULT,
                rect.right - rect.left,
                rect.bottom - rect.top,
                null,
                null,
                window.hInstance,
                window,
            ) orelse return error.FailedToCreateWindow;

            // Windows associates an IME context with every window by default;
            // start detached to match "disabled until `setTextInput` asks".
            _ = ImmAssociateContext(window.handle, null);

            window.updateDpi();
            window.updateClientSize();

            return window;
        }

        fn updateDpi(self: *Self) void {
            const dpi = GetDpiForWindow(self.handle);
            self.dpi = .{ dpi, dpi };
        }

        fn updateClientSize(self: *Self) void {
            var rect: RECT = undefined;
            if (GetClientRect(self.handle, &rect) == 0) {
                std.log.err("failed to query window client size", .{});
                return;
            }
            self.width = @intCast(rect.right - rect.left);
            self.height = @intCast(rect.bottom - rect.top);
        }

        fn emitResizeIfNeeded(self: *Self, hwnd: HWND, force: bool) void {
            var rect: RECT = undefined;
            if (GetClientRect(hwnd, &rect) == 0) {
                std.log.err("failed to get new window size, ignoring event", .{});
                return;
            }

            const newWidth: u32 = @intCast(rect.right - rect.left);
            const newHeight: u32 = @intCast(rect.bottom - rect.top);

            if (force or self.width != newWidth or self.height != newHeight) {
                self.width = newWidth;
                self.height = newHeight;
                if (self.handlers.resize) |h| h.function(self, self.width, self.height, self.dpi, h.data);
            }
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

        pub fn deinit(self: *Self) void {
            _ = DestroyWindow(self.handle);
            _ = UnregisterClassW(self.className.ptr, self.hInstance);
            self.allocator.free(self.className);
            self.allocator.free(self.title);
            self.allocator.destroy(self);
        }

        /// Preview a pressed dead key inline ("Jo~" while ~ waits for its
        /// letter), like the Linux compose path; the WM_CHAR that resolves
        /// the combination clears it.
        fn handleDeadChar(self: *Self, wParam: WPARAM) void {
            self.deadCharPending = true;
            var input = Event.Input{ .composition = true };
            const codeUnit: u16 = @truncate(wParam);
            input.preeditLength = std.unicode.utf8Encode(codeUnit, &input.preeditBuffer) catch 0;
            input.cursor = .{ input.preeditLength, input.preeditLength };
            self.eventQueue.push(Event{ .input = input });
        }

        /// Decode a WM_CHAR code unit into a `.input` event, joining UTF-16
        /// surrogate pairs (which arrive as two consecutive WM_CHARs) and dropping
        /// control codepoints — those reach the app through `Keys` instead.
        fn handleChar(self: *Self, wParam: WPARAM, lParam: LPARAM) void {
            if (self.deadCharPending) {
                self.deadCharPending = false;
                // Empty composition update: the dead-key preview clears.
                self.eventQueue.push(Event{ .input = .{ .composition = true } });
            }

            const codeUnit: u16 = @truncate(wParam);

            const codepoint: u21 = blk: {
                if (codeUnit >= 0xD800 and codeUnit <= 0xDBFF) {
                    self.pendingHighSurrogate = codeUnit;
                    return;
                } else if (codeUnit >= 0xDC00 and codeUnit <= 0xDFFF) {
                    const high = self.pendingHighSurrogate orelse return;
                    self.pendingHighSurrogate = null;
                    break :blk 0x10000 +
                        (@as(u21, high - 0xD800) << 10) +
                        (codeUnit - 0xDC00);
                } else {
                    self.pendingHighSurrogate = null;
                    break :blk codeUnit;
                }
            };

            // Control codepoints (C0, DEL, C1) aren't text.
            if (codepoint < 0x20 or (codepoint >= 0x7f and codepoint <= 0x9f)) return;

            var buffer: [7]u8 = undefined;
            const length = std.unicode.utf8Encode(codepoint, &buffer) catch return;

            // lParam bits 0..15 are the OS auto-repeat count, so a held key coalesces
            // into a single event carrying its repeat multiplier.
            const lp: u32 = @truncate(@as(u64, @bitCast(lParam)));
            const repeats: usize = @max(1, lp & 0xFFFF);

            var input = Event.Input{ .textLength = length, .repeats = repeats };
            @memcpy(input.textBuffer[0..length], buffer[0..length]);
            self.eventQueue.push(Event{ .input = input });
        }

        fn pushPointerButton(self: *Self, button: MouseButton, pressed: bool) void {
            self.eventQueue.push(Event{
                .pointerButton = .{
                    .serial = 0,
                    .time = 0,
                    .button = button,
                    .pressed = pressed,
                },
            });
        }

        fn nativeCursorId(cursor: Cursor) ?*const anyopaque {
            return switch (cursor) {
                .default => IDC_ARROW,
                .text => IDC_IBEAM,
                .pointer => IDC_HAND,
            };
        }

        fn wndProc(hwnd: HWND, message: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.c) LRESULT {
            // Handle WM_NCCREATE to store the window pointer
            if (message == WM_NCCREATE) {
                const createStruct: *CREATESTRUCTW = @ptrFromInt(@as(usize, @bitCast(lParam)));
                const window: *Self = @ptrCast(@alignCast(createStruct.lpCreateParams));
                _ = SetWindowLongPtrW(hwnd, GWLP_USERDATA, @bitCast(@intFromPtr(window)));
                return DefWindowProcW(hwnd, message, wParam, lParam);
            }

            // Retrieve the window pointer for all other messages
            const window: ?*Self = blk: {
                const ptr = GetWindowLongPtrW(hwnd, GWLP_USERDATA);
                break :blk if (ptr == 0) null else @ptrFromInt(@as(usize, @bitCast(ptr)));
            };

            switch (message) {
                WM_WINDOWPOSCHANGED => {
                    if (window) |self| {
                        const windowpos: *WINDOWPOS = @ptrFromInt(@as(usize, @intCast(lParam)));
                        if ((windowpos.flags & SWP_NOSIZE) == 0) {
                            self.emitResizeIfNeeded(hwnd, false);
                        }
                    }
                },
                WM_MOUSEMOVE => {
                    if (window) |self| {
                        const mouseX: u16 = @truncate(@as(u32, @intCast(lParam)));
                        const mouseY: u16 = @truncate(@as(u32, @intCast(lParam)) >> 16);
                        if (!self.mouseInside) {
                            self.mouseInside = true;
                            // WM_MOUSELEAVE is one-shot: it has to be
                            // requested again on every re-entry.
                            var track = TRACKMOUSEEVENT{ .dwFlags = TME_LEAVE, .hwndTrack = hwnd };
                            _ = TrackMouseEvent(&track);
                            self.eventQueue.push(Event{
                                .pointerEnter = .{
                                    .serial = 0,
                                    .x = mouseX,
                                    .y = mouseY,
                                },
                            });
                        }
                        self.eventQueue.push(Event{
                            .pointerMotion = .{
                                .time = 0,
                                .x = @floatFromInt(mouseX),
                                .y = @floatFromInt(mouseY),
                            },
                        });
                    }
                },
                WM_MOUSELEAVE => {
                    if (window) |self| {
                        self.mouseInside = false;
                        self.eventQueue.push(Event{ .pointerLeave = .{ .serial = 0 } });
                    }
                },
                WM_LBUTTONDOWN => {
                    if (window) |self| self.pushPointerButton(.left, true);
                },
                WM_LBUTTONUP => {
                    if (window) |self| self.pushPointerButton(.left, false);
                },
                WM_RBUTTONDOWN => {
                    if (window) |self| self.pushPointerButton(.right, true);
                },
                WM_RBUTTONUP => {
                    if (window) |self| self.pushPointerButton(.right, false);
                },
                WM_MBUTTONDOWN => {
                    if (window) |self| self.pushPointerButton(.middle, true);
                },
                WM_MBUTTONUP => {
                    if (window) |self| self.pushPointerButton(.middle, false);
                },
                WM_XBUTTONDOWN, WM_XBUTTONUP => {
                    if (window) |self| {
                        const xButton: u16 = @truncate(wParam >> 16);
                        const button: MouseButton = if (xButton == XBUTTON1) .back else .forward;
                        self.pushPointerButton(button, message == WM_XBUTTONDOWN);
                    }
                    // Unlike the other button messages, WM_XBUTTON* asks
                    // handlers to return TRUE.
                    return 1;
                },
                WM_MOUSEWHEEL => {
                    if (window) |self| {
                        // this value is positive when going up and negative going down
                        // see https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-mousewheel
                        const offset: i16 = @bitCast(@as(u16, @truncate(wParam >> 16)));
                        self.eventQueue.push(Event{
                            .scroll = .{
                                .axis = .vertical,
                                .offset = @floatFromInt(-1 * offset),
                            },
                        });
                    }
                },
                WM_MOUSEHWHEEL => {
                    if (window) |self| {
                        // Positive = tilted right, same sign as Wayland's
                        // horizontal axis — no flip needed.
                        const offset: i16 = @bitCast(@as(u16, @truncate(wParam >> 16)));
                        self.eventQueue.push(Event{
                            .scroll = .{
                                .axis = .horizontal,
                                .offset = @floatFromInt(offset),
                            },
                        });
                    }
                },
                WM_SETCURSOR => {
                    // The OS resets to the window class's arrow cursor on
                    // every mouse move; reassert the frame-requested cursor
                    // while over the client area.
                    const hitTest: u16 = @truncate(@as(usize, @bitCast(lParam)));
                    if (window != null and hitTest == HTCLIENT) {
                        _ = SetCursor(LoadCursorW(null, nativeCursorId(window.?.cursor.load(.monotonic))));
                        return 1;
                    }
                    return DefWindowProcW(hwnd, message, wParam, lParam);
                },
                WM_KILLFOCUS => {
                    if (window) |self| {
                        // Mirrors the Wayland keyboard-leave handler: releases
                        // happening while another window has focus are never
                        // delivered, so treat everything as released now.
                        self.keyboard.releaseAll();
                        self.pendingHighSurrogate = null;
                        if (self.deadCharPending) {
                            self.deadCharPending = false;
                            // Empty composition update: the dead-key preview clears.
                            self.eventQueue.push(Event{ .input = .{ .composition = true } });
                        }
                    }
                },
                WM_CHAR => {
                    if (window) |self| self.handleChar(wParam, lParam);
                },
                WM_DEADCHAR => {
                    if (window) |self| self.handleDeadChar(wParam);
                },
                WM_APP_TEXT_INPUT => {
                    if (window) |self| self.applyTextInput();
                },
                WM_IME_SETCONTEXT => {
                    // The preedit renders inline via `.input` events;
                    // strip the flag so the system composition window stays
                    // hidden. Everything else passes through.
                    const masked: LPARAM = @bitCast(@as(usize, @bitCast(lParam)) & ~@as(usize, ISC_SHOWUICOMPOSITIONWINDOW));
                    return DefWindowProcW(hwnd, message, wParam, masked);
                },
                WM_IME_STARTCOMPOSITION => {},
                WM_IME_COMPOSITION => {
                    if (window) |self| {
                        self.handleImeComposition(@truncate(@as(usize, @bitCast(lParam))));
                    }
                },
                WM_IME_ENDCOMPOSITION => {
                    if (window) |self| {
                        // An empty preedit tells consumers the composition is
                        // over (a commit's text already arrived through
                        // WM_IME_COMPOSITION's result string).
                        self.eventQueue.push(Event{ .input = .{ .composition = true } });
                    }
                },
                WM_KEYDOWN => {
                    if (window) |self| {
                        // WM_KEYDOWN re-fires on OS auto-repeat, so unlike a
                        // naive port we don't filter it out here — repeats are
                        // supposed to flow through. Coalesce count (bits
                        // 0..15) and scan code (bits 16..23) of lParam are
                        // intentionally ignored.
                        const key = virtualKeyToKeys(wParam);
                        self.keyboard.keyDown(key);
                        refreshModifiersFromOS(self);
                    }
                },
                WM_KEYUP => {
                    if (window) |self| {
                        const key = virtualKeyToKeys(wParam);
                        self.keyboard.keyUp(key);
                        refreshModifiersFromOS(self);
                    }
                },
                WM_DPICHANGED => {
                    if (window) |self| {
                        const previousDpi = self.dpi;
                        const wParam32: u32 = @truncate(wParam);
                        const dpiX: u16 = @truncate(wParam32);
                        const dpiY: u16 = @truncate(wParam32 >> 16);
                        self.dpi = .{ @intCast(dpiX), @intCast(dpiY) };

                        const suggestedRect: *const RECT = @ptrFromInt(@as(usize, @bitCast(lParam)));
                        _ = SetWindowPos(
                            hwnd,
                            null,
                            @intCast(suggestedRect.left),
                            @intCast(suggestedRect.top),
                            @intCast(suggestedRect.right - suggestedRect.left),
                            @intCast(suggestedRect.bottom - suggestedRect.top),
                            SWP_NOZORDER | SWP_NOACTIVATE,
                        );

                        const dpiChanged = self.dpi[0] != previousDpi[0] or self.dpi[1] != previousDpi[1];
                        self.emitResizeIfNeeded(hwnd, dpiChanged);
                    }
                },
                WM_DESTROY => {
                    if (window) |self| {
                        self.running.store(false, .release);
                    }
                },
                WM_CLOSE => {
                    if (window) |self| {
                        self.running.store(false, .release);
                    }
                },
                WM_ACTIVATEAPP => {
                    std.log.debug("activate app", .{});
                },
                else => {
                    return DefWindowProcW(hwnd, message, wParam, lParam);
                },
            }

            return 0;
        }

        pub fn targetFrameTimeNs(self: *const Self) u64 {
            const fallback60hz: u64 = 16_666_667; // ~60 Hz in nanoseconds

            // Get the monitor that contains most of this window
            const monitor = MonitorFromWindow(self.handle, MONITOR_DEFAULTTONEAREST);
            if (monitor == null) {
                return fallback60hz;
            }

            // Get monitor info to retrieve the device name
            var monitorInfo: MONITORINFOEXW = .{};
            if (GetMonitorInfoW(monitor, &monitorInfo) == 0) {
                return fallback60hz;
            }

            // Get current display settings for this monitor
            var devMode: DEVMODEW = .{};
            if (EnumDisplaySettingsW(@ptrCast(&monitorInfo.szDevice), ENUM_CURRENT_SETTINGS, &devMode) == 0) {
                return fallback60hz;
            }

            const refreshRate = devMode.dmDisplayFrequency;
            if (refreshRate == 0 or refreshRate == 1) {
                // 0 or 1 means default/unknown
                return fallback60hz;
            }

            return @divTrunc(1_000_000_000, @as(u64, refreshRate));
        }

        pub fn setCursor(self: *Self, cursor: Cursor, serial: u32) !void {
            _ = serial;
            // Only records the request: `SetCursor` binds to the calling
            // thread and this runs on the render thread, so the window
            // thread applies it in WM_SETCURSOR.
            self.cursor.store(cursor, .monotonic);
        }

        pub fn setClipboardText(self: *Self, text: []const u8) !void {
            const wide = try std.unicode.utf8ToUtf16LeAllocZ(self.allocator, text);
            defer self.allocator.free(wide);

            if (OpenClipboard(self.handle) == 0) return error.FailedToOpenClipboard;
            defer _ = CloseClipboard();

            if (EmptyClipboard() == 0) return error.FailedToEmptyClipboard;

            const byteLen: SIZE_T = (wide.len + 1) * @sizeOf(u16);
            const hMem = GlobalAlloc(GMEM_MOVEABLE, byteLen) orelse return error.FailedToAllocateClipboardMemory;
            const dest = GlobalLock(hMem) orelse {
                _ = GlobalFree(hMem);
                return error.FailedToLockClipboardMemory;
            };
            const destSlice: [*]u16 = @ptrCast(@alignCast(dest));
            @memcpy(destSlice[0..wide.len], wide);
            destSlice[wide.len] = 0;
            _ = GlobalUnlock(hMem);

            // Ownership of `hMem` transfers to the system on success; freeing
            // it ourselves afterwards would be a double free.
            if (SetClipboardData(CF_UNICODETEXT, hMem) == null) {
                _ = GlobalFree(hMem);
                return error.FailedToSetClipboardData;
            }
        }

        /// Reads the OS clipboard as text, allocated with `allocator`. Returns
        /// `null` if the clipboard doesn't currently hold text.
        pub fn getClipboardText(self: *Self, allocator: std.mem.Allocator) !?[]const u8 {
            if (IsClipboardFormatAvailable(CF_UNICODETEXT) == 0) return null;

            if (OpenClipboard(self.handle) == 0) return error.FailedToOpenClipboard;
            defer _ = CloseClipboard();

            const hMem = GetClipboardData(CF_UNICODETEXT) orelse return null;
            const ptr = GlobalLock(hMem) orelse return error.FailedToLockClipboardMemory;
            defer _ = GlobalUnlock(hMem);

            const wide: [*:0]const u16 = @ptrCast(@alignCast(ptr));
            return try std.unicode.utf16LeToUtf8Alloc(allocator, std.mem.span(wide));
        }

        /// Declares whether the app wants IME input right now and where the
        /// caret is, in client coordinates. Only records the request and pokes
        /// the window thread, which applies it in `wndProc` — IMM32 contexts
        /// belong to the thread that owns the window.
        pub fn setTextInput(self: *Self, request: ?TextInputArea) void {
            self.textInputMutex.lockUncancelable(self.io);
            const wanted = request != null;
            const changed = wanted != self.textInputWanted or
                (request != null and !std.meta.eql(request.?, self.textInputArea));
            self.textInputWanted = wanted;
            if (request) |area| self.textInputArea = area;
            self.textInputMutex.unlock(self.io);

            if (changed) _ = PostMessageW(self.handle, WM_APP_TEXT_INPUT, 0, 0);
        }

        fn applyTextInput(self: *Self) void {
            self.textInputMutex.lockUncancelable(self.io);
            const wanted = self.textInputWanted;
            const area = self.textInputArea;
            const applied = self.textInputApplied;
            self.textInputApplied = wanted;
            self.textInputMutex.unlock(self.io);

            if (wanted != applied) {
                if (wanted) {
                    // Reattach the window's default IME context.
                    _ = ImmAssociateContextEx(self.handle, null, IACE_DEFAULT);
                } else {
                    _ = ImmAssociateContext(self.handle, null);
                }
            }
            if (wanted) {
                const himc = ImmGetContext(self.handle) orelse return;
                defer _ = ImmReleaseContext(self.handle, himc);
                var form = CANDIDATEFORM{
                    .dwIndex = 0,
                    .dwStyle = CFS_EXCLUDE,
                    .ptCurrentPos = .{ .x = area.x, .y = area.y },
                    .rcArea = .{
                        .left = area.x,
                        .top = area.y,
                        .right = area.x + area.width,
                        .bottom = area.y + area.height,
                    },
                };
                _ = ImmSetCandidateWindow(himc, &form);
            }
        }

        /// One WM_IME_COMPOSITION can carry both a result string (text to
        /// commit) and a composition string (the new preedit) — in that
        /// order, mirroring the Wayland `done` batch. Handled fully here so
        /// DefWindowProc doesn't re-deliver the result as WM_CHARs.
        fn handleImeComposition(self: *Self, flags: u32) void {
            const himc = ImmGetContext(self.handle) orelse return;
            defer _ = ImmReleaseContext(self.handle, himc);

            var input = Event.Input{ .composition = true };

            if (flags & GCS_RESULTSTR != 0) result: {
                // 40 UTF-16 units keep the worst-case UTF-8 within the event
                // buffers, same clipping policy as the Wayland backend.
                var wide: [40]u16 = undefined;
                const byteCount = ImmGetCompositionStringW(himc, GCS_RESULTSTR, &wide, @sizeOf(@TypeOf(wide)));
                if (byteCount <= 0) break :result;
                const units = @min(@as(usize, @intCast(byteCount)) / 2, wide.len);
                input.textLength = std.unicode.utf16LeToUtf8(&input.textBuffer, wide[0..units]) catch 0;
            }

            if (flags & GCS_COMPSTR != 0) preedit: {
                var wide: [40]u16 = undefined;
                const byteCount = ImmGetCompositionStringW(himc, GCS_COMPSTR, &wide, @sizeOf(@TypeOf(wide)));
                if (byteCount <= 0) break :preedit;
                const units = @min(@as(usize, @intCast(byteCount)) / 2, wide.len);
                input.preeditLength = std.unicode.utf16LeToUtf8(&input.preeditBuffer, wide[0..units]) catch 0;

                // GCS_CURSORPOS is in UTF-16 units; converting just the
                // prefix gives the byte offset into the UTF-8 preedit.
                const caret = ImmGetCompositionStringW(himc, GCS_CURSORPOS, null, 0);
                const caretUnits: usize = if (caret < 0) units else @min(@as(usize, @intCast(caret)), units);
                var prefix: [120]u8 = undefined;
                const caretBytes = std.unicode.utf16LeToUtf8(&prefix, wide[0..caretUnits]) catch input.preeditLength;
                input.cursor = .{
                    @min(caretBytes, input.preeditLength),
                    @min(caretBytes, input.preeditLength),
                };
            }
            self.eventQueue.push(Event{ .input = input });
        }

        pub fn handleEvents(self: *Self) !void {
            while (self.running.load(.acquire)) {
                var message: MSG = undefined;
                // `TranslateMessage` turns WM_KEYDOWN into WM_CHAR for text input;
                // `DispatchMessageW` then calls `wndProc` synchronously on this
                // thread, which is the sole producer pushing onto `eventQueue`.
                const result = GetMessageW(&message, null, 0, 0);
                if (result == 0) {
                    // WM_QUIT
                    self.running.store(false, .release);
                    break;
                }
                if (result == -1) {
                    return error.FailedToGetMessage;
                }
                _ = TranslateMessage(&message);
                _ = DispatchMessageW(&message);

                // Mirror the keyboard state accumulated by `wndProc` into the
                // queue, matching the Linux backend's per-iteration snapshot.
                self.keyboard.flush(&self.eventQueue);
            }
        }

        // Manual Windows API declarations to avoid @cImport macro translation issues
        // This provides clean Zig bindings for the Windows APIs needed for windowing
        // Basic Windows types
        const BOOL = c_int;
        const WORD = u16;
        const DWORD = u32;
        const UINT = c_uint;
        const INT = c_int;
        const LONG = c_long;
        const LONG_PTR = isize;
        const UINT_PTR = usize;
        const SIZE_T = usize;
        const ATOM = WORD;

        const LPVOID = ?*anyopaque;
        const LPCVOID = ?*const anyopaque;
        const LPWSTR = [*:0]u16;
        const LPCWSTR = [*:0]const u16;

        const HANDLE = *anyopaque;
        const HWND = ?HANDLE;
        const HINSTANCE = ?HANDLE;
        const HMODULE = ?HANDLE;
        const HICON = ?HANDLE;
        const HCURSOR = ?HANDLE;
        const HBRUSH = ?HANDLE;
        const HMENU = ?HANDLE;
        const HDC = ?HANDLE;

        const WPARAM = UINT_PTR;
        const LPARAM = LONG_PTR;
        const LRESULT = LONG_PTR;

        // Window procedure callback type
        const WNDPROC = *const fn (hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.c) LRESULT;

        // WNDCLASSEXW structure
        const WNDCLASSEXW = extern struct {
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

        const WINDOWPOS = extern struct {
            hwnd: HWND = null,
            hwndInsertAfter: HWND = null,
            x: INT = 0,
            y: INT = 0,
            cx: INT = 0,
            cy: INT = 0,
            flags: UINT = 0,
        };

        // RECT structure
        const RECT = extern struct {
            left: LONG = 0,
            top: LONG = 0,
            right: LONG = 0,
            bottom: LONG = 0,
        };

        // POINT structure
        const POINT = extern struct {
            x: LONG = 0,
            y: LONG = 0,
        };

        // MSG structure
        const MSG = extern struct {
            hwnd: HWND = null,
            message: UINT = 0,
            wParam: WPARAM = 0,
            lParam: LPARAM = 0,
            time: DWORD = 0,
            pt: POINT = .{},
        };

        // Window styles
        const WS_OVERLAPPED: DWORD = 0x00000000;
        const WS_POPUP: DWORD = 0x80000000;
        const WS_CHILD: DWORD = 0x40000000;
        const WS_MINIMIZE: DWORD = 0x20000000;
        const WS_VISIBLE: DWORD = 0x10000000;
        const WS_DISABLED: DWORD = 0x08000000;
        const WS_CLIPSIBLINGS: DWORD = 0x04000000;
        const WS_CLIPCHILDREN: DWORD = 0x02000000;
        const WS_MAXIMIZE: DWORD = 0x01000000;
        const WS_CAPTION: DWORD = 0x00C00000;
        const WS_BORDER: DWORD = 0x00800000;
        const WS_DLGFRAME: DWORD = 0x00400000;
        const WS_VSCROLL: DWORD = 0x00200000;
        const WS_HSCROLL: DWORD = 0x00100000;
        const WS_SYSMENU: DWORD = 0x00080000;
        const WS_THICKFRAME: DWORD = 0x00040000;
        const WS_GROUP: DWORD = 0x00020000;
        const WS_TABSTOP: DWORD = 0x00010000;
        const WS_MINIMIZEBOX: DWORD = 0x00020000;
        const WS_MAXIMIZEBOX: DWORD = 0x00010000;
        const WS_OVERLAPPEDWINDOW: DWORD = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;

        // Class styles
        const CS_VREDRAW: UINT = 0x0001;
        const CS_HREDRAW: UINT = 0x0002;
        const CS_DBLCLKS: UINT = 0x0008;
        const CS_OWNDC: UINT = 0x0020;
        const CS_CLASSDC: UINT = 0x0040;
        const CS_PARENTDC: UINT = 0x0080;
        const CS_NOCLOSE: UINT = 0x0200;
        const CS_SAVEBITS: UINT = 0x0800;
        const CS_BYTEALIGNCLIENT: UINT = 0x1000;
        const CS_BYTEALIGNWINDOW: UINT = 0x2000;
        const CS_GLOBALCLASS: UINT = 0x4000;

        // Window messages
        const WM_NULL: UINT = 0x0000;
        const WM_NCCREATE: UINT = 0x0081;
        const WM_CREATE: UINT = 0x0001;
        const WM_DESTROY: UINT = 0x0002;
        const WM_DPICHANGED: UINT = 0x02E0;
        const WM_WINDOWPOSCHANGED: UINT = 0x0047;
        const WM_MOVE: UINT = 0x0003;
        const WM_SIZE: UINT = 0x0005;
        const WM_EXITSIZEMOVE: UINT = 0x0232;
        const WM_ENTERSIZEMOVE: UINT = 0x0231;
        const WM_SIZING: UINT = 0x0214;
        const WM_ACTIVATE: UINT = 0x0006;
        const WM_SETFOCUS: UINT = 0x0007;
        const WM_KILLFOCUS: UINT = 0x0008;
        const WM_ENABLE: UINT = 0x000A;
        const WM_SETREDRAW: UINT = 0x000B;
        const WM_SETTEXT: UINT = 0x000C;
        const WM_GETTEXT: UINT = 0x000D;
        const WM_GETTEXTLENGTH: UINT = 0x000E;
        const WM_PAINT: UINT = 0x000F;
        const WM_CLOSE: UINT = 0x0010;
        const WM_QUIT: UINT = 0x0012;
        const WM_ACTIVATEAPP: UINT = 0x001C;
        const WM_KEYDOWN: UINT = 0x0100;
        const WM_KEYUP: UINT = 0x0101;
        const WM_CHAR: UINT = 0x0102;
        const WM_SYSKEYDOWN: UINT = 0x0104;
        const WM_SYSKEYUP: UINT = 0x0105;
        const WM_SYSCHAR: UINT = 0x0106;
        const WM_MOUSEMOVE: UINT = 0x0200;
        const WM_LBUTTONDOWN: UINT = 0x0201;
        const WM_LBUTTONUP: UINT = 0x0202;
        const WM_LBUTTONDBLCLK: UINT = 0x0203;
        const WM_RBUTTONDOWN: UINT = 0x0204;
        const WM_RBUTTONUP: UINT = 0x0205;
        const WM_RBUTTONDBLCLK: UINT = 0x0206;
        const WM_MBUTTONDOWN: UINT = 0x0207;
        const WM_MBUTTONUP: UINT = 0x0208;
        const WM_MBUTTONDBLCLK: UINT = 0x0209;
        const WM_MOUSEWHEEL: UINT = 0x020A;
        const WM_XBUTTONDOWN: UINT = 0x020B;
        const WM_XBUTTONUP: UINT = 0x020C;
        const WM_MOUSEHWHEEL: UINT = 0x020E;
        const WM_MOUSELEAVE: UINT = 0x02A3;
        const WM_SETCURSOR: UINT = 0x0020;
        const XBUTTON1: u16 = 0x0001;
        const HTCLIENT: u16 = 1;

        const TME_LEAVE: DWORD = 0x00000002;
        const TRACKMOUSEEVENT = extern struct {
            cbSize: DWORD = @sizeOf(TRACKMOUSEEVENT),
            dwFlags: DWORD,
            hwndTrack: HWND,
            dwHoverTime: DWORD = 0,
        };
        extern "user32" fn TrackMouseEvent(lpEventTrack: *TRACKMOUSEEVENT) callconv(.winapi) BOOL;

        // Virtual Keycodes https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
        const VK_SHIFT: c_int = 0x10;
        const VK_CONTROL: c_int = 0x11;
        const VK_MENU: c_int = 0x12;
        const VK_LWIN: c_int = 0x5B;
        const VK_RWIN: c_int = 0x5C;

        /// `GetKeyState(vk)` returns the keyboard state for the calling thread:
        /// high bit set = key currently down. For `VK_SHIFT/VK_CONTROL/VK_MENU`,
        /// the result is the OR of the corresponding L/R keys — exactly what we
        /// need to keep a collapsed `.shift/.control/.alt` flag correct when one
        /// side is released while the other is still held.
        extern "user32" fn GetKeyState(nVirtKey: c_int) callconv(.winapi) i16;
        extern "user32" fn PostMessageW(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) BOOL;

        const WM_DEADCHAR: UINT = 0x0103;
        const WM_IME_STARTCOMPOSITION: UINT = 0x010D;
        const WM_IME_ENDCOMPOSITION: UINT = 0x010E;
        const WM_IME_COMPOSITION: UINT = 0x010F;
        const WM_IME_SETCONTEXT: UINT = 0x0281;
        /// WM_APP: private to this window class, used to hop `setTextInput`
        /// requests from the render thread onto the window thread.
        const WM_APP_TEXT_INPUT: UINT = 0x8000;

        const GCS_COMPSTR: u32 = 0x0008;
        const GCS_CURSORPOS: u32 = 0x0080;
        const GCS_RESULTSTR: u32 = 0x0800;
        const CFS_EXCLUDE: DWORD = 0x0080;
        const IACE_DEFAULT: DWORD = 0x0010;
        const ISC_SHOWUICOMPOSITIONWINDOW: u32 = 0x80000000;

        const HIMC = *anyopaque;
        const CANDIDATEFORM = extern struct {
            dwIndex: DWORD,
            dwStyle: DWORD,
            ptCurrentPos: POINT,
            rcArea: RECT,
        };

        extern "imm32" fn ImmGetContext(hWnd: HWND) callconv(.winapi) ?HIMC;
        extern "imm32" fn ImmReleaseContext(hWnd: HWND, hIMC: ?HIMC) callconv(.winapi) BOOL;
        extern "imm32" fn ImmGetCompositionStringW(hIMC: ?HIMC, dwIndex: DWORD, lpBuf: ?*anyopaque, dwBufLen: DWORD) callconv(.winapi) i32;
        extern "imm32" fn ImmAssociateContext(hWnd: HWND, hIMC: ?HIMC) callconv(.winapi) ?HIMC;
        extern "imm32" fn ImmAssociateContextEx(hWnd: HWND, hIMC: ?HIMC, dwFlags: DWORD) callconv(.winapi) BOOL;
        extern "imm32" fn ImmSetCandidateWindow(hIMC: ?HIMC, lpCandidate: *CANDIDATEFORM) callconv(.winapi) BOOL;

        // CW_USEDEFAULT
        const CW_USEDEFAULT: c_int = @bitCast(@as(c_uint, 0x80000000));

        // Standard cursor IDs (these are resource IDs cast to pointers)
        const IDC_ARROW: ?*const anyopaque = @ptrFromInt(32512);
        const IDC_IBEAM: ?*const anyopaque = @ptrFromInt(32513);
        const IDC_WAIT: ?*const anyopaque = @ptrFromInt(32514);
        const IDC_CROSS: ?*const anyopaque = @ptrFromInt(32515);
        const IDC_UPARROW: ?*const anyopaque = @ptrFromInt(32516);
        const IDC_SIZE: ?*const anyopaque = @ptrFromInt(32640);
        const IDC_ICON: ?*const anyopaque = @ptrFromInt(32641);
        const IDC_SIZENWSE: ?*const anyopaque = @ptrFromInt(32642);
        const IDC_SIZENESW: ?*const anyopaque = @ptrFromInt(32643);
        const IDC_SIZEWE: ?*const anyopaque = @ptrFromInt(32644);
        const IDC_SIZENS: ?*const anyopaque = @ptrFromInt(32645);
        const IDC_SIZEALL: ?*const anyopaque = @ptrFromInt(32646);
        const IDC_NO: ?*const anyopaque = @ptrFromInt(32648);
        const IDC_HAND: ?*const anyopaque = @ptrFromInt(32649);
        const IDC_APPSTARTING: ?*const anyopaque = @ptrFromInt(32650);
        const IDC_HELP: ?*const anyopaque = @ptrFromInt(32651);

        // PeekMessage flags
        const PM_NOREMOVE: UINT = 0x0000;
        const PM_REMOVE: UINT = 0x0001;
        const PM_NOYIELD: UINT = 0x0002;

        // ShowWindow commands
        const SW_HIDE: c_int = 0;
        const SW_SHOWNORMAL: c_int = 1;
        const SW_SHOW: c_int = 5;
        const SW_MINIMIZE: c_int = 6;
        const SW_MAXIMIZE: c_int = 3;
        const SW_RESTORE: c_int = 9;

        // WINDOWPOS flags
        const SWP_DRAWFRAME = 0x0020;
        const SWP_FRAMECHANGED = 0x0020;
        const SWP_HIDEWINDOW = 0x0080;
        const SWP_NOACTIVATE = 0x0010;
        const SWP_NOCOPYBITS = 0x0100;
        const SWP_NOMOVE = 0x0002;
        const SWP_NOOWNERZORDER = 0x0200;
        const SWP_NOREDRAW = 0x0008;
        const SWP_NOREPOSITION = 0x0200;
        const SWP_NOSENDCHANGING = 0x0400;
        const SWP_NOSIZE = 0x0001;
        const SWP_NOZORDER = 0x0004;
        const SWP_SHOWWINDOW = 0x0040;

        // External function declarations
        extern "kernel32" fn GetModuleHandleW(lpModuleName: ?LPCWSTR) callconv(.c) HMODULE;
        extern "kernel32" fn GetLastError() callconv(.c) DWORD;

        extern "user32" fn RegisterClassExW(lpWndClass: *const WNDCLASSEXW) callconv(.c) ATOM;
        extern "user32" fn UnregisterClassW(lpClassName: LPCWSTR, hInstance: HINSTANCE) callconv(.c) BOOL;

        extern "user32" fn CreateWindowExW(
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

        extern "user32" fn DestroyWindow(hWnd: HWND) callconv(.c) BOOL;
        extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: c_int) callconv(.c) BOOL;
        extern "user32" fn UpdateWindow(hWnd: HWND) callconv(.c) BOOL;

        extern "user32" fn DefWindowProcW(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.c) LRESULT;

        extern "user32" fn GetMessageW(lpMsg: *MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) callconv(.c) BOOL;
        extern "user32" fn PeekMessageW(lpMsg: *MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) callconv(.c) BOOL;
        extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.c) BOOL;
        extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.c) LRESULT;
        extern "user32" fn PostQuitMessage(nExitCode: c_int) callconv(.c) void;

        extern "user32" fn LoadCursorW(hInstance: HINSTANCE, lpCursorName: ?*const anyopaque) callconv(.c) HCURSOR;
        extern "user32" fn SetCursor(hCursor: HCURSOR) callconv(.c) HCURSOR;

        // Clipboard
        const HGLOBAL = ?HANDLE;
        const CF_UNICODETEXT: UINT = 13;
        const GMEM_MOVEABLE: UINT = 0x0002;

        extern "user32" fn OpenClipboard(hWndNewOwner: HWND) callconv(.c) BOOL;
        extern "user32" fn CloseClipboard() callconv(.c) BOOL;
        extern "user32" fn EmptyClipboard() callconv(.c) BOOL;
        extern "user32" fn SetClipboardData(uFormat: UINT, hMem: HGLOBAL) callconv(.c) HGLOBAL;
        extern "user32" fn GetClipboardData(uFormat: UINT) callconv(.c) HGLOBAL;
        extern "user32" fn IsClipboardFormatAvailable(format: UINT) callconv(.c) BOOL;

        extern "kernel32" fn GlobalAlloc(uFlags: UINT, dwBytes: SIZE_T) callconv(.c) HGLOBAL;
        extern "kernel32" fn GlobalLock(hMem: HGLOBAL) callconv(.c) LPVOID;
        extern "kernel32" fn GlobalUnlock(hMem: HGLOBAL) callconv(.c) BOOL;
        extern "kernel32" fn GlobalFree(hMem: HGLOBAL) callconv(.c) HGLOBAL;

        extern "user32" fn AdjustWindowRectEx(lpRect: *RECT, dwStyle: DWORD, bMenu: BOOL, dwExStyle: DWORD) callconv(.c) BOOL;
        extern "user32" fn SetWindowPos(
            hWnd: HWND,
            hWndInsertAfter: HWND,
            X: c_int,
            Y: c_int,
            cx: c_int,
            cy: c_int,
            uFlags: UINT,
        ) callconv(.c) BOOL;
        extern "user32" fn GetClientRect(hWnd: HWND, lpRect: *RECT) callconv(.c) BOOL;
        extern "user32" fn GetWindowRect(hWnd: HWND, lpRect: *RECT) callconv(.c) BOOL;

        extern "user32" fn SetWindowTextW(hWnd: HWND, lpString: LPCWSTR) callconv(.c) BOOL;
        extern "user32" fn GetWindowTextW(hWnd: HWND, lpString: LPWSTR, nMaxCount: c_int) callconv(.c) c_int;

        extern "user32" fn InvalidateRect(hWnd: HWND, lpRect: ?*const RECT, bErase: BOOL) callconv(.c) BOOL;

        extern "user32" fn GetDC(hWnd: HWND) callconv(.c) HDC;
        extern "user32" fn ReleaseDC(hWnd: HWND, hDC: HDC) callconv(.c) c_int;

        // DPI awareness
        const DPI_AWARENESS_CONTEXT = ?HANDLE;
        const DPI_AWARENESS_CONTEXT_UNAWARE: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -1))));
        const DPI_AWARENESS_CONTEXT_SYSTEM_AWARE: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -2))));
        const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -3))));
        const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -4))));
        const DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED: DPI_AWARENESS_CONTEXT = @ptrFromInt(@as(usize, @bitCast(@as(isize, -5))));

        extern "user32" fn GetDpiForWindow(hwnd: HWND) callconv(.c) UINT;
        extern "user32" fn SetThreadDpiAwarenessContext(dpiContext: DPI_AWARENESS_CONTEXT) callconv(.c) DPI_AWARENESS_CONTEXT;
        extern "user32" fn SetProcessDpiAwarenessContext(value: DPI_AWARENESS_CONTEXT) callconv(.c) BOOL;

        // Window long ptr indices
        const GWLP_WNDPROC: c_int = -4;
        const GWLP_HINSTANCE: c_int = -6;
        const GWLP_HWNDPARENT: c_int = -8;
        const GWLP_USERDATA: c_int = -21;
        const GWLP_ID: c_int = -12;

        extern "user32" fn SetWindowLongPtrW(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) callconv(.c) LONG_PTR;
        extern "user32" fn GetWindowLongPtrW(hWnd: HWND, nIndex: c_int) callconv(.c) LONG_PTR;

        // CREATESTRUCT for WM_CREATE/WM_NCCREATE
        const CREATESTRUCTW = extern struct {
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
        const HMONITOR = ?HANDLE;

        const MONITOR_DEFAULTTONULL: DWORD = 0x00000000;
        const MONITOR_DEFAULTTOPRIMARY: DWORD = 0x00000001;
        const MONITOR_DEFAULTTONEAREST: DWORD = 0x00000002;

        const MONITORINFOEXW = extern struct {
            cbSize: DWORD = @sizeOf(MONITORINFOEXW),
            rcMonitor: RECT = .{},
            rcWork: RECT = .{},
            dwFlags: DWORD = 0,
            szDevice: [32]u16 = [_]u16{0} ** 32,
        };

        const DEVMODEW = extern struct {
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

        const ENUM_CURRENT_SETTINGS: DWORD = 0xFFFFFFFF;

        extern "user32" fn MonitorFromWindow(hwnd: HWND, dwFlags: DWORD) callconv(.c) HMONITOR;
        extern "user32" fn GetMonitorInfoW(hMonitor: HMONITOR, lpmi: *MONITORINFOEXW) callconv(.c) BOOL;
        extern "user32" fn EnumDisplaySettingsW(lpszDeviceName: [*:0]const u16, iModeNum: DWORD, lpDevMode: *DEVMODEW) callconv(.c) BOOL;
    },
    else => @compileError("unsupported platform: " ++ @tagName(builtin.os.tag)),
};
