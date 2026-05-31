# Lessons from Forbear's API history

Reference for the `forbear-api-design` skill. Distilled from `notes/` and ~428
commits of actual API evolution (Dec 2025 → May 2026). Read this before
proposing a non-trivial API so you extend the grain instead of fighting it.

## The grain: what every rewrite converged on

The public API was reshaped ~four times. Every rewrite moved the same direction:
**away from "build a value and hand it back," toward "append to an implicit tree
by call order, and resolve whatever depends on the whole tree in a later pass."**
Each rewrite deleted a layer of explicitness that turned out to be ceremony, not
control.

Principles that *survived by attrition* (these are load-bearing — match them):

1. **One declarative build pass per frame.**
   `frame(meta)({ App(); layout(); drawFrame(...); update(); })`.
2. **No user-visible allocation of structure.** Children are a side effect of
   call order (`element(.{...})({ ...children... })`), not data the user builds.
   The `fn(...)({...})` end-function trick marks a start/end around the block; it
   is *not* a closure the runtime can re-invoke.
3. **State is keyed by call site, not position.** `@returnAddress()` + enclosing
   scope key + node-stack depth, mixed with SplitMix64 (`mixU64`). This is why
   conditional `useState` works — keys don't shift when an earlier call is
   skipped. Loop siblings disambiguate with an explicit `key`.
4. **Hooks bind to the nearest enclosing scope.** Both `component` *and*
   `element` open a scope, so `useState`/`useScrolling` work directly inside an
   `element({...})` block — no wrapper component needed just to hold state.
5. **Interaction & tree-global resolution read the *previous* frame.** `on()`
   hit-tests against `previousFrameNodeMeasurements`; `useNodeMeasurement()`
   returns last frame's resolved box. The system is single-pass forward,
   one-frame-latent backward. **This is the source of the remaining hard
   problems** (see below).

## The settled core (bedrock — compose with it, don't churn it)

```zig
forbear.frame(.{ .arena, .viewportSize, .baseStyle })({
    App();
    const root = try forbear.layout();
    try renderer.drawFrame(arena, root, clearColor, targetFrameNs);
    try forbear.update();
});

fn App() void {
    forbear.component(.{})({                       // .key only for loop siblings
        const count = forbear.useState(u32, 0);    // no try; errors -> frame err
        forbear.element(.{ .style = .{ .cursor = .pointer } })({
            if (forbear.on(.mouseEnter)) forbear.setCursor(.pointer);
            if (forbear.on(.click)) count.* += 1;
            forbear.text("Increment");
        });
    });
}
```

- **Mount:** `component`, `element`, `text`, `printText`, `image`/`Image`, `BreakLine`.
- **State/anim:** `useState`, `useTransition`, `useSpringTransition`, `useAnimation`
  (+ `linear`/`ease`/`easeInOut`/`easeOut`/`cubicBezier`).
- **Reads:** `useMousePosition`, `useViewportSize`, `useDeltaTime`,
  `useNodeMeasurement` (prev frame), `getParentNode`, `getPreviousNode`, `useArena`.
- **Events:** `on(.mouseEnter|mouseLeave|mouseDown|mouseUp|mouseMove|click|scroll)`
  → `bool` (or `?Vec2` for `scroll`/`mouseMove`).
- **Resources:** `registerFont`/`useFont`, `registerImage`/`useImage`.
- **Slotting:** `componentChildrenSlot()` / `componentChildrenSlotEnd()`.
- **Built-ins (composed on the core, in `builtin.zig`):** `useScrolling`,
  `ScrollBar`, `ProfilingMetrics`.

Keying, conditional state, slotting, per-element scrolling are **done**. Treat
them as fixed.

## The discard list (do not re-propose without defeating the original reason)

| Discarded approach | Why it died | Replaced by |
|---|---|---|
| Heap children `.children = forbear.children(.{...})` | allocation + a second `resolve()` pass | `fn(...)({...})` append-by-call-order |
| Component returns `Node` | components-as-values blocked the append model | `void` fns that append as a side effect |
| Callback-pointer events w/ `?*anyopaque` data | boilerplate per handler | `on(.event)` reading raw input inline |
| Event polling `while (useNextEvent())` | too imperative | `if (on(.event))` |
| Mandatory string keys on every component | ceremony | optional `key`, auto `@returnAddress()` |
| `display:inline`-style text segmentation | forces ignoring styles on inline nodes — the exact CSS misfeature being avoided | per-glyph styles within one `text()` node (raddebugger-style) |
| Feeding previous-frame size back as current-frame input (for grid/%) | feedback loop: "values infinitely increasing from padding/margin" | a real second build pass (see below) |
| `measure()` block that re-runs code | the block isn't a closure; can't re-invoke it | runtime re-runs the build fn itself |

If a new idea resembles a row above, either present the new angle that beats the
original objection, or choose a different shape.

## Open tensions and their intended direction

Four notes wrestle with what is really **one** problem: features that need
geometry resolved against the **current** frame, not the previous one. Reading
the previous frame is the cheap, latent option; it is not enough for these.

1. **Measurement before placement (the central problem).** Grid layouts,
   percentage sizing, centering on a sibling's size, virtual scrolling. Direction:
   make `frame()` run the build **twice, invisibly** — pass 1 fits sizes
   bottom-up, pass 2 lays out with measurements available — and make it
   **opt-in/pay-per-use** (only when a `useMeasurement()` is touched; skip pass 2
   otherwise). Add `useMeasurement()` returning the *current* frame's box with a
   `done: bool` (false in pass 1, true in pass 2). Keep `useNodeMeasurement()`
   (previous-frame) for things that tolerate one frame of lag.

2. **Event propagation / ordering.** `on()` runs top-to-bottom in mount order, so
   an ancestor consumes scroll before a descendant — no stop-propagation, and
   slotting breaks any "handle after subtree" scheme. Direction: keep the `on()`
   *call site*, but register interest in pass 1 and read consumption from a
   single post-build, innermost-first tree resolution in pass 2 — i.e. fold it
   into the same two-pass machinery as (1). They are the same problem.

3. **Layout animations** (animate computed values; list insert/delete/reorder).
   Primitives already exist: `useNodeMeasurement()` (prev box) + optional `.key`
   (stable identity across positions/frames). Missing glue: a `useLayoutTransition`
   built-in driving a spring between prev and current box via `.placement =
   .relative`, plus the one genuinely new core affordance — **deferring unmount
   of a keyed node by one frame** so exit animations can play (opt-in).

4. **Custom component events.** Components are `void` fns, nothing to attach a
   handler to. Resolution: **out-param `*T` slots in props** (`Button(.{ .clicked
   = &clicked })`); the component writes during its body (which runs before
   slotted children). Don't build a parallel event system.

Adjacent, mostly orthogonal: **per-glyph text styling** (a `node.zig`/`font.zig`
shaping change, keeps tree shape intact; node keys already deliberately exclude
text content so selection survives edits), **text selection** (Range-style
primitives + glyph→byte mapping via kb_text_shape `SOURCE_INDEX`; depends on the
hit-testing from tension 2 — build that first), and **multiple windows** ("a
window is a root node with its own frame context" — defer until single-window
two-pass is settled).

## Sequencing implied by the dependencies

1. Two-pass / current-frame measurement (invisible, opt-in-per-frame).
2. Tree-level event resolution, folded into the same two passes.
3. Layout animations as `builtin.zig` hooks on (1) + deferred keyed unmount.
4. Per-glyph text styling and text selection (selection gated on (2)).
5. Custom component events — no new core API; document the out-param pattern.

## Performance ground truth (from `notes/performance-plan.md` + perf commits)

Dominant cost is **CPU-side build/layout/alloc**, not GPU submit. Hotspots hunted
down already: per-glyph `dupe` during layout, full node-path rehashing per
`element`/`text`, linear scans in `update`/image registration, per-frame z-sort.
Hence: non-owning glyph metadata, incremental/`mixU64` hashing, O(1) lookups,
z-bucketing, hot fields at the front of the context struct. **Any new API must
not reintroduce these shapes.** The two-pass model (tension 1) reopens the perf
budget, which is exactly why it must stay opt-in and lean on the warm
keyed-state cache.

## The one-line thesis

The API converges on **one declarative build pass + deferred whole-tree
resolution**. The remaining hard features are all blocked on the same missing
piece: resolving against the *current* frame's geometry instead of the previous
one. New APIs should fit this shape — primitive first, conveniences layered in
`builtin.zig`, cost stated, fast/safe path the default.
