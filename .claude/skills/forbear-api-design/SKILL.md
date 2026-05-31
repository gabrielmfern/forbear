---
name: forbear-api-design
description: >-
  Design and write new public APIs for the Forbear UI framework (Zig). Use
  whenever adding, changing, or reviewing a public function, hook, style field,
  event, or built-in component in src/root.zig, src/node.zig, src/builtin.zig,
  or the rendering/layout surface — anything a Forbear user calls. Triggers on
  "design an API for…", "add a hook/component/style/event", "what should the
  signature be", "is this API consistent with Forbear", or any change to the
  user-facing surface. Not for internal refactors with no surface change.
---

# Forbear API Design

You are helping design the public surface of **Forbear** — a Zig UI framework
(Vulkan renderer, immediate-style mounting, retained component state). Forbear
exists to be the GUI framework that holds **three pillars at once** — most
frameworks pick one or two:

1. **Performance** — native, predictable frame times, no hidden cost.
2. **Beautiful** — capable of genuinely good-looking UIs out of the box.
3. **Perfect developer experience** — the API teaches itself.

Your job is not to invent APIs in a vacuum. It is to extend a surface that has
already converged on a strong grain through ~four full rewrites. Honor the grain.
Read `lessons-from-history.md` (next to this file) before proposing anything
non-trivial — it records what was tried, what survived, and *why*, so you don't
re-propose an approach the project already deleted.

---

## The three design principles (in priority order)

These are the author's stated principles. Apply them in this order when they
conflict.

### 1. Performance, safety, and memory are designed for — never bolted on.

You do not ship a feature and "optimize later." The shape of the API is chosen so
that the fast, safe, memory-correct path is the *only* path or the *default*
path. Concretely, in Forbear:

- **No per-frame allocation in the hot path that the user can't see or avoid.**
  The build pass runs every frame. An API that allocates per call per frame is a
  defect, not a tradeoff. Prefer the frame arena (`useArena()` /
  `frameMeta.arena`, reset each frame) over the general allocator. Prefer
  non-owning slices and indices over owned copies. (See the perf history: text
  per-glyph `dupe`, full-path rehashing, and linear scans were all hunted down —
  do not reintroduce their shapes.)
- **Keying is `@returnAddress()` + scope chain + node-stack depth, mixed with
  SplitMix64 (`mixU64`).** Any new tree node, scope, or hook must derive its key
  the same way so state stays stable across `if`/loops. Never hash mutable
  content (e.g. text) into a node key — it breaks state identity and future
  selection. Loop siblings take an explicit `key: ?[]const u8`.
- **Safety via Zig's own guarantees.** Errors inside a frame are captured into
  `frameMeta.err` and the rest of the frame no-ops gracefully (hooks return dummy
  storage), so a single failure never corrupts the tree. New mounting/hook APIs
  must respect `if (self.frameMeta.?.err != null) return …;` early-out and must
  not `return` errors to the user from inside the build pass — swallow into
  `handleFrameError`. Public *driver* functions (`frame`, `layout`, `update`)
  may return errors.
- **Memory is arena-scoped to lifetime.** Per-scope state lives in that scope's
  `ArenaAllocator` and dies in one `deinit()` when the scope unmounts. New
  retained state must attach to a scope arena, not leak into the global
  allocator. Frame-lifetime data uses the frame arena.
- **State the cost.** When you propose an API, say what it costs per frame (allocs,
  hashes, passes, scans) and how it scales with node count. If you can't state
  it, you haven't designed it yet. If a feature needs a second build pass or a
  tree walk, make it **opt-in / pay-for-what-you-use** (touched-flag), never a
  blanket tax on every frame.
- **Failures must be debuggable, not just caught.** (Per loggingsucks.com:
  optimize for the moment things go wrong, not the moment you write the code.)
  When an API can fail, the error captured into `frameMeta.err` /
  `handleFrameError` should carry enough context to answer "what happened to
  *this build*" — which node, which key, which call site — not a bare
  `error.OutOfMemory`. Design the failure surface for the person debugging it
  later, the same way you design the call site for the person reading it.

### 2. API design is familiarity first — users learn fastest.

The win condition is *time-to-understand for someone who has never seen Forbear*,
not elegance or power. Borrow shapes people already know; reduce cognitive load
(per minds.md/zakirullin/cognitive — humans hold ~4 chunks in working memory;
every new concept or layer is a chunk).

- **Reuse Forbear's own established shapes before inventing new ones.** The
  vocabulary is already set: `component(.{})({...})` / `element(.{...})({...})`
  block calls; `useX()` hooks bound to the nearest scope; `on(.event)` returning
  `bool`/`?Vec2`; `registerX`/`useX` for resources; `.style = .{...}` structs
  with CSS-adjacent names (`padding`, `margin`, `borderRadius`, `direction`,
  `xJustification`). A new API that matches one of these reads as "obvious."
- **Borrow from what users already know** when Forbear has no precedent: React
  (hooks, keys, `useState`, exit/enter semantics), CSS (box model, flex
  direction/justification, easing names like `easeInOut`). Match the mental
  model, not necessarily the exact name.
- **Make the common case the short case.** `printText("Count: {d}", .{n})`
  exists because formatting text is common. If a usage will be written a hundred
  times, it gets the shortest honest spelling.
- **Deep modules, simple interface.** (Ousterhout, via the cognitive-load post.)
  A good Forbear API hides a lot behind a small surface — `useScrolling()` returns
  a state and silently wires event consumption. Resist shallow APIs that make the
  user assemble many small pieces. *"The author of a smart solution feels proud.
  The reader feels stupid. Don't be a smart developer."*
- **The boring spelling wins.** If two signatures are equally fast, choose the one
  a newcomer guesses correctly on the first try.
- **Design for the consumer, not the emitter.** (loggingsucks.com's core move:
  logging is broken because it's "optimized for *writing*, not for *querying*.")
  The analog in API design: don't optimize the signature for whatever is easiest
  to *implement* — optimize it for how it will be *read and used* at the call
  site, a hundred times, by someone who didn't write the implementation. The
  convenience of emitting a call has no relationship to how well it reads later;
  pay the implementation complexity so the call site stays obvious.
- **Familiarity is not the same as simplicity** (Dan North). Borrowing a known
  shape lowers *extraneous* load (no new concept to learn); it does not excuse
  *intrinsic* complexity. Use familiar shapes to remove the former, deep modules
  to contain the latter.
- **No surprising required ceremony.** The `fn(...)({...})` end-function trick and
  automatic keying both exist to *remove* ceremony (manual `resolve()`, manual
  keys). Don't add ceremony back. If Zig forces a return value the user must
  consume (like the end-fn), lean into it as a safety rail, but never invent
  optional bookkeeping the user can forget.

### 3. Start from the low level; the high level is a convenience built on top.

(Inspired by Sebastian Aaltonen's "no graphics API" stance: **lower-level doesn't
mean worse** — exposing the machine directly as a thin, zero-overhead layer
yields *both* better performance and cleaner code, because **complexity doesn't
improve performance, it usually worsens it**. Build ergonomic conveniences *on
top* in userland, never the reverse, so the convenience never hides a cost the
advanced user can't escape, and the abstraction always matches the real data
model rather than papering over it.)

- **Design the primitive first.** What is the smallest, most direct expression of
  the capability against the real data model (`Node`, `Style`, the scope/key
  system, previous/current-frame measurements)? Ship that.
- **Then layer the ergonomic API on top of the primitive**, as a separate,
  optional function — ideally one that an *advanced user could have written
  themselves* using only public primitives. `Image()` is `element()` plus
  aspect-ratio logic. `ScrollBar`/`useScrolling` are built on `on(.scroll)` +
  `useState`. `printText` is `text` + `allocPrint`. `useTransition` is `useState`
  ×3 + `useAnimation`. This is the pattern: **built-ins live in `builtin.zig` and
  compose the public core; they get no private privileges.**
- **The low level must stay reachable.** An advanced user who needs control must
  be able to drop to the primitive without fighting the convenience. If the only
  way to do something is through the high-level wrapper, the layering is wrong.
- **New users and advanced users are both served** by this stacking: beginners
  reach for the convenience, experts reach for the primitive, and the convenience
  is just readable example code for how to use the primitive well.

---

## The design process (follow this when proposing an API)

1. **Locate it on the grain.** Read `lessons-from-history.md` and the relevant
   current source (`src/root.zig` for hooks/mounting/events, `src/node.zig` for
   `Style`/sizing, `src/builtin.zig` for composed built-ins, `src/layouting.zig`
   for layout). Find the closest existing API and mirror its shape. Quote the
   real signatures you're matching.
2. **Name the primitive.** State the lowest-level form first: exact Zig
   signature, what scope/key it uses, what it allocates, what frame(s) of data it
   reads (this frame vs `useNodeMeasurement` previous-frame).
3. **Run the three principles as gates, in order:**
   - *Perf/safety/memory:* per-frame cost? alloc strategy? error-path no-op?
     scope-arena lifetime? Does it tax frames that don't use it?
   - *Familiarity:* what existing Forbear shape or React/CSS concept does it
     mirror? Could a newcomer guess it? How many new chunks does it add?
   - *Layering:* is this the primitive or the convenience? If convenience, can it
     be written purely from public primitives and live in `builtin.zig`?
4. **Check it against the discard list** in `lessons-from-history.md`. If your
   idea resembles heap `.children`, components returning `Node`, callback-pointer
   events, event polling, mandatory keys, `display:inline`-style segmentation, or
   feeding previous-frame size back as current-frame input — stop. Those were
   deleted for reasons. Either you have a new angle that defeats the original
   objection (say what it is) or you pick a different shape.
5. **Write the smallest playground usage** that shows the API in context, in the
   real `forbear.frame(...)({ ... })` shape. If it doesn't read cleanly there,
   it's not done.
6. **State the cost and the migration**, if it changes existing call sites.

---

## Review checklist (before declaring an API "good")

- [ ] Matches an existing Forbear call shape, or a well-known React/CSS one.
- [ ] Zero unavoidable per-frame heap allocation; arena-scoped if any.
- [ ] Keyed via `mixU64` of scope + depth + `@returnAddress()`/explicit key.
- [ ] Errors no-op into `frameMeta.err`, never returned from the build pass.
- [ ] Retained state lives in a scope arena and dies on unmount.
- [ ] A primitive exists and is public; conveniences are layered on top in
      `builtin.zig` using only public APIs.
- [ ] A newcomer could guess the signature; the common case is the short case.
- [ ] Per-frame cost is stated and scales acceptably with node count.
- [ ] Doesn't tax frames that don't use the feature.
- [ ] Doesn't resurrect a discarded approach (checked against history).
- [ ] Has a clean 5–10 line playground example.

---

## Anti-patterns (reject on sight)

- Returning structure as data the user assembles (`.children = ...`). Forbear
  appends via call order.
- Components returning `Node` / values to express events. Use `*T` out-param
  slots in props (the resolved pattern for custom component events).
- A parallel event system. Compose on `on(...)`.
- Per-frame `dupe`/owned copies of glyph/text/path data in the hot path.
- Optional bookkeeping the user must remember (manual resolve, manual reset,
  manual unmount).
- A high-level API with no reachable low-level primitive underneath.
- "We'll make it fast later."

When in doubt, optimize for the reader of the *call site*, paying with complexity
in the *implementation* — deep module, simple interface, no hidden cost.
