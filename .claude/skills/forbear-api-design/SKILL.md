---
name: forbear-api-design
description: >-
  Design, change, or review a public API for Forbear — the Zig UI framework —
  any hook, component, element, style field, event, or signature a Forbear user
  calls, across src/root.zig, src/node.zig, src/builtin.zig, or the
  layout/render surface. Use for "design an API for…", "add a
  hook/component/style", "what should the signature be", "is this consistent
  with Forbear". Not for internal refactors with no surface change.
---

# Forbear API Design

You design the public surface of **Forbear** — a Zig UI framework (Vulkan
renderer, immediate-style mounting, retained component state) built to hold
**three pillars at once** where most frameworks pick one or two:

1. **Performance** — native, predictable frame times, no hidden cost.
2. **Beautiful** — genuinely good-looking UIs out of the box.
3. **Perfect developer experience** — the API teaches itself.

You don't invent APIs in a vacuum; you extend a surface that converged on a
strong **grain** through ~four rewrites. Honor the grain. Before proposing
anything non-trivial, read `lessons-from-history.md` (next to this file): it
records what was tried, what survived, and *why*, so you don't re-propose a
shape the project already deleted.

The three principles below are the author's, in priority order — apply them in
that order when they conflict.

## 1. Performance, safety, and memory are designed for, never bolted on

The shape of the API makes the fast, safe, memory-correct path the *only* path
or the *default* path. No "ship it and optimize later."

- **No per-frame heap allocation the user can't see or avoid.** The build pass
  runs every frame; an API that allocates per call per frame is a defect. Prefer
  the frame arena (`useArena()` / `frameMeta.arena`, reset each frame) over the
  general allocator, and non-owning slices/indices over owned copies. Per-glyph
  `dupe`, full-path rehashing, and linear scans were all hunted down — don't
  reintroduce their shapes.
- **Key by `@returnAddress()` + scope chain + node-stack depth, mixed with
  SplitMix64 (`mixU64`).** Every new node, scope, or hook derives its key this
  way so state stays stable across `if`/loops. Never hash mutable content (text)
  into a key — it breaks state identity. Loop siblings take an explicit
  `key: ?[]const u8`.
- **Safety via Zig's own guarantees.** Errors inside a frame are captured into
  `frameMeta.err` and the rest of the frame no-ops (hooks return dummy storage).
  New mounting/hook APIs early-out with `if (self.frameMeta.?.err != null)
  return …;` and swallow into `handleFrameError` — never `return` an error to the
  user from the build pass. Only the driver fns (`frame`, `layout`, `update`)
  return errors.
- **Memory is arena-scoped to lifetime.** Per-scope state lives in that scope's
  `ArenaAllocator` and dies in one `deinit()` on unmount; frame-lifetime data
  uses the frame arena. New retained state attaches to a scope arena, never the
  global allocator.
- **State the cost.** Say what the API costs per frame (allocs, hashes, passes,
  scans) and how it scales with node count. If you can't state it, you haven't
  designed it. A feature needing a second pass or a tree walk is **opt-in /
  pay-for-what-you-use** (touched-flag), never a blanket per-frame tax.
- **Design the failure for the debugger.** When the error lands in
  `frameMeta.err` / `handleFrameError`, it carries which node, which key, which
  call site — enough to answer "what happened to *this* build" — not a bare
  `error.OutOfMemory`.

## 2. Familiarity first — users learn fastest

The win condition is *time-to-understand for someone who has never seen
Forbear*, not elegance or power. Borrow shapes people already know; every new
concept or layer is a chunk against a ~4-chunk working memory.

- **Reuse Forbear's own shapes before inventing.** The vocabulary is set:
  `component(.{})({...})` / `element(.{...})({...})` block calls; `useX()` hooks
  on the nearest scope; `on(.event)` → `bool`/`?Vec2`; `registerX`/`useX` for
  resources; `.style = .{...}` with CSS-adjacent names (`padding`, `margin`,
  `borderRadius`, `direction`, `xJustification`). Matching one reads as obvious.
- **Borrow from what users already know** when Forbear has no precedent: React
  (hooks, keys, `useState`, enter/exit) and CSS (box model, flex
  direction/justification, easing like `easeInOut`). Match the mental model, not
  the exact name.
- **Make the common case the short case.** `printText("Count: {d}", .{n})`
  exists because formatting text is common. A usage written a hundred times gets
  the shortest honest spelling.
- **Deep module, simple interface.** A good Forbear API hides a lot behind a
  small surface — `useScrolling()` returns state and silently wires event
  consumption. Optimize the signature for the **call site**, read a hundred
  times, not for whatever is easiest to implement; pay the implementation
  complexity so the call site stays obvious.
- **The boring spelling wins.** Equal speed → the signature a newcomer guesses
  right on the first try.
- **No surprising ceremony.** The `fn(...)({...})` end-fn and automatic keying
  exist to *remove* ceremony (manual `resolve()`, manual keys). Don't add it
  back; never invent optional bookkeeping the user can forget.

## 3. Primitive first; the high level is a convenience on top

Lower-level isn't worse: a thin, zero-overhead layer over the real data model
yields both better performance and cleaner code, because complexity usually
worsens performance rather than improving it. Build ergonomics *on top* in
userland, never the reverse, so the convenience never hides a cost the advanced
user can't escape.

- **Name the primitive first.** The smallest, most direct expression against the
  real data model (`Node`, `Style`, the scope/key system, previous/current-frame
  measurements). Ship that.
- **Layer the convenience on top** as a separate optional fn an advanced user
  could have written from public primitives alone. `Image()` = `element()` +
  aspect-ratio; `ScrollBar`/`useScrolling` = `on(.scroll)` + `useState`;
  `printText` = `text` + `allocPrint`; `useTransition` = `useState`×3 +
  `useAnimation`. **Built-ins live in `builtin.zig` and compose the public core
  with no private privileges.**
- **The primitive stays reachable.** If the only way to do something is through
  the wrapper, the layering is wrong. Beginners reach for the convenience,
  experts for the primitive — and the convenience doubles as readable example
  code for using the primitive well.

## The process (when proposing an API)

1. **Locate it on the grain.** Read `lessons-from-history.md` and the relevant
   source (`src/root.zig` for hooks/mounting/events, `src/node.zig` for
   `Style`/sizing, `src/builtin.zig` for composed built-ins, `src/layouting.zig`
   for layout). Find the closest existing API and quote the real signature
   you're mirroring.
2. **Name the primitive.** Exact Zig signature, what scope/key it uses, what it
   allocates, which frame of data it reads (this frame vs `useNodeMeasurement`
   previous-frame).
3. **Run the three principles as gates, in order.** Each gate's questions are
   its principle above: perf/safety/memory, then familiarity, then layering.
4. **Check the discard list** in `lessons-from-history.md`. If the idea
   resembles a discarded shape (heap `.children`, components returning `Node`,
   callback-pointer events, event polling, mandatory keys, `display:inline`
   segmentation, feeding previous-frame size back as current-frame input), stop —
   either defeat the original objection out loud or pick another shape.
5. **Write the smallest playground usage** in the real `forbear.frame(...)({ ...
   })` shape. If it doesn't read cleanly there, it's not done.
6. **State the cost and the migration** for any existing call sites it changes.

## Before declaring an API good

Every box checked, or it isn't done:

- [ ] Matches an existing Forbear shape, or a well-known React/CSS one.
- [ ] Zero unavoidable per-frame heap allocation; arena-scoped if any, with a
      stated cost that scales acceptably with node count.
- [ ] Keyed via `mixU64` of scope + depth + `@returnAddress()`/explicit key.
- [ ] Errors no-op into `frameMeta.err`; only the driver fns return errors.
- [ ] Retained state lives in a scope arena and dies on unmount.
- [ ] A public primitive exists; conveniences are layered on it in `builtin.zig`.
- [ ] A newcomer guesses the signature; the common case is the short case.
- [ ] Doesn't tax frames that don't use the feature.
- [ ] Doesn't resurrect a discard-list shape.
- [ ] Has a clean 5–10 line playground example.

When in doubt: optimize for the reader of the **call site**, paying with
complexity in the implementation — deep module, simple interface, no hidden cost.
