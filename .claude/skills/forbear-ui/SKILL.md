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
        if (forbear.on(.click)) count.* += 1;
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

## Events

All events should be handled through `forbear.on(event)`. For each given even type being listened to there may be a different return type. The function determines what element to check for the event at the exact moment of calling is the current parenting node.

All events and their respective return types:
- mouse
    - mouseEnter: `bool`
    - mouseLeave: `bool`
    - mouseDown: `bool`
    - mouseMove: `?Vec2`
    - mouseUp: `bool`
    - click: `bool`
- keyboard
    - keyDown: `Keys`
    - keyUp: `Keys`
- scroll: `?Vec2`

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

