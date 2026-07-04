---
name: forbear-ui
description: Write Forbear UI framework code — components, elements, hooks, contexts, children slots, events, and styling. Use when creating or modifying Forbear components, building UI with Forbear, or writing Zig code that uses the forbear API. To answer questions about Forbear, ALWAYS read the actual code.
---

# Writing Forbear Code

Forbear is an immediate-mode Zig UI framework with retained state. You build a node tree each frame; state persists across frames via keyed scopes. `element`, `component`, `text`, `useState`, and contexts all use `@returnAddress()` to generate unique keys per call site.

## Keying

Same source line = same key. Different lines = different keys automatically. The full key mixes: parent scope stack + node tree depth + `@returnAddress()` (or explicit `.key`). This matters in loops:

```zig
// WRONG — all iterations share one @returnAddress, state collides
for (items) |item| {
    forbear.element(.{})({
        const expanded = forbear.useState(bool, false); // one slot for ALL items
    });
}
// CORRECT — explicit key gives each iteration its own scope
for (items) |item| {
    forbear.element(.{ .key = item.id })({
        const expanded = forbear.useState(bool, false); // unique per item
    });
}
```

## Core call pattern

`element` and `component` return an end function — call it with a block:

```zig
forbear.element(.{ 
  .style = .{ .width = .{ .grow = 1.0 }, 
  .padding = .all(16.0) }, 
})({
    forbear.text("Hello");  // text is a direct call, no block
});
```

`element` creates a visual box AND a scope. `component` creates only a scope (no layout node). Both hold `useState` and create scope-lived arena that can be used through `useScopedArena`.

## Components with children (slots)

Return `*const fn (void) void`. Mark where children go with `componentChildrenSlot()`, return `componentChildrenSlotEnd()`:

```zig
pub fn Card(style: forbear.Style) *const fn (void) void {
    forbear.component(.{})({
        forbear.element(.{ 
            .style = style.overwrite(.{
                .borderRadius = 12.0, 
                .padding = .all(20.0), 
                .direction = .vertical,
            }), 
          })({
            forbear.text("Header");            // before children
            forbear.componentChildrenSlot();    // children inserted here
            forbear.text("Footer");            // after children
        });
    });
    return forbear.componentChildrenSlotEnd();
}
```

Can then be used as:

```zig
Card(.{ .width = .{ .grow = 1.0 } })({ 
  forbear.text("child"); 
});
```

Without children — return `void`, skip slots:

```zig
pub fn Counter() void {
    forbear.component(.{})({
        const count = forbear.useState(u32, 0);
        if (forbear.onClick()) count.* += 1;
        forbear.printText("Count: {d}", .{count.*});
    });
}
```

## Style

All fields of `Style` are optional. It is completed in the end to generate the one without optional fields `CompleteStyle`. Styles are completed from `BaseStyle`, which contains the subset of inheritable properties that `Style` contains, but as required.

A given `Style` can be "merged" to another given `Style` through `overwrite`. In `style.overwrite(other)`, `self` wins, `other` fills in the missing gaps.

Styles can define padding/margin which are just `Vec4` at the end, but have helper functions such that one can write:

```zig
Style{
  .padding = .block(10),
}
```

```zig
Style{
  .padding = .block(10).withInLine(25),
}
```

```zig
Style{
  .padding = .inLine(25),
}
```

Color helpers are also included:
- `forbear.hex("#ffffff")`
- `forbear.rgb(255, 255, 255, 1)`
- `forbear.white`
- `forbear.black`
- `forbear.red`

## Hooks

Bind to nearest enclosing scope, a scope can be a component, but also can be an element. Can be called conditionally because it also has its own returnAddress keying. 

- `useState(T, initial) -> *T` — persisted mutable pointer
- `useTransition(T, target, duration, easing) -> T` — animated value (`f32`/`Vec2`/`Vec3`/`Vec4`). Easings: `easeInOut`, `easeOut`, `ease`, `linear`
- `useSpringTransition(target, .{ .stiffness, .damping, .mass }) -> f32`
- `useAnimation(duration) -> Animation` — `.start()`, `.reset()`, `.progress() -> ?f32`
- `useViewportSize() -> Vec2` 
- `useMousePosition() -> Vec2`
- `useDeltaTime() -> f64`

## Builtin

All functionality that would be batteries included in a browser and we want to provide, such as handling focus, scrolling, perhaps some helpers like a performance metrics overlays, input, buttons and etc. are all included as builtins, and are completely implemented using only what's already available to the user through the existing primitives. 

The existing ones are:
- `forbear.useScrolling()` - pair with `forbear.ScrollBar(forbear.useScrolling())`
- `forbear.ScrollBar()` - pair with `forbear.useScrolling()`
- `forbear.ProfilingMetrics()`
- `forbear.FocusProvider()` - children slot that hosts keyboard focus (see Focus)

## Events

Each event is its own handler function, read inline inside an element's block. Mouse handlers report on the **current parenting node** (the element whose block you're in) at the moment of the call — call them inside the element you care about. They are hooks, so they can be called conditionally.

```zig
forbear.element(.{ .style = ... })({
    if (forbear.onClick()) { ... }
    if (forbear.onMouseEnter()) { ... }
    if (forbear.onScroll()) |delta| { ... }
});
```

Mouse (scoped to the current element):
- `onMouseEnter() bool` — true on the frame the cursor crosses in
- `onMouseLeave() bool` — true on the frame the cursor crosses out
- `onMouseDown() bool` — true on the frame the button goes down inside
- `onMouseUp() bool` — true on the frame the button releases inside
- `onMouseMove() ?Vec2` — movement delta while inside, else null
- `onClick() bool` — full press-and-release that both started and ended inside
- `onScroll() ?Vec2` — wheel/trackpad delta while inside, else null
- `isMouseInside() bool` — raw hit test against the current element's bounds

Keyboard (global for now, not element-scoped — `Keys` is a packed struct of bools like `.tab`, `.enter`, `.space`, `.escape`, `.shift`):
- `onKeyDown() Keys` — keys that transitioned to down since last frame: `if (forbear.onKeyDown().enter) ...`
- `onKeyUp() Keys` — keys that transitioned to up since last frame
- `getModifiersHeld() Keys` — the modifiers (shift/control/alt/super/caps lock) held right now, whichever frame they went down on. Use this for "is shift held?" during a wheel or mouse gesture; `onKeyDown` only carries modifiers on frames where a key event arrives

To scope keyboard input to a specific element, pair it with focus (see below).

## Contexts

```zig
// the opaque {} struct is required to generate a unique identifier for the
// given context by using the Zig-generated name given to the anonymous struct.
const ThemeContext = forbear.createContext(opaque {}, struct { accent: @Vector(4, f32) });

ThemeContext.Provider(.{ .accent = forbear.hex("3366ff") })({ 
  MyComponent(); 
});

if (forbear.useContext(ThemeCtx)) |theme| { 
  forbear.printText("theme accent: {}", .{theme.accent});
}
```

## Rich text

`text`/`printText` render a single style. To style different runs within one wrapped paragraph, open a `composeText` block and emit runs with `write`. The active style is the innermost enclosing `textStyle` (a nestable override layered over the block's base style); `Strong` is just `textStyle(.{ .fontWeight = 700 })`.

```zig
forbear.element(.{ .style = .{ .width = .{ .fixed = 420 }, .textWrapping = .word } })({
    forbear.composeText(.{})({           // .{} is the base TextStyle for the block
        forbear.write("Wayland is a ");
        forbear.Strong()({ forbear.write("display server protocol"); });
        forbear.write(", and you can ");
        forbear.textStyle(.{ .color = forbear.hex("#7dd3fc") })({
            forbear.Strong()({ forbear.write("nest styles"); });   // bold + color
        });
        forbear.write(" inside one paragraph.");
    });
});
```

Rules: one `composeText` per paragraph (nesting them errors), `write`/`textStyle`/`Strong` are only valid inside it, and don't call `text`/`element` inside a `composeText` block. `forbear.BreakLine()` inserts a hard line break.

## Focus

Keyboard focus is a builtin built on the primitives. Wrap focusable UI in `FocusProvider()` (a children slot). Inside, each focusable element grabs the context with `FocusContext.use().?` and `register`s a `consumes` function — a predicate over an `EventPayload` that says which key events this element acts on. The provider handles tab / shift-tab cycling and escape-to-blur; query `hasFocus()` to drive focus styling.

```zig
forbear.FocusProvider()({
    forbear.element(.{ .style = ... })({
        const focus = forbear.FocusContext.use().?;
        focus.register(&(struct {
            fn consume(payload: forbear.EventPayload) bool {
                return payload == .keyDown and (payload.keyDown.enter or payload.keyDown.space);
            }
        }).consume);

        // style on focus
        const node = forbear.getParentNode().?;
        node.style.borderColor = if (focus.hasFocus()) forbear.hex("#3F3F3F") else forbear.hex("#2F2F2F");

        // act on the key while focused
        const keys = forbear.onKeyDown();
        if (focus.hasFocus() and (keys.enter or keys.space)) { ... }
        if (forbear.onClick()) { ... }   // mouse still works independently
    });
});
```

`hasFocus()` reads the parent node, so it can't be called inside a `.style` definition (the node doesn't exist yet) — read it in the element body and assign onto `getParentNode().?.style`.

