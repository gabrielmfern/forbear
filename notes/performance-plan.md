# Performance Plan (No Layout Caching)

This plan explicitly excludes layout caching. The goal is to push CPU usage and frame-time consistency as far as possible without it.

## Perf Learnings (Debug + Steady-State)

From `notes/perf-uhoh-debug.data` and `notes/perf-uhoh-debug-steady.data`:

- Dominant CPU is CPU-side layout/build/allocation work, not GPU submission.
- Top hotspots in steady-state:
  - `memcpy` (~6.3%)
  - `layouting.LayoutCreator.create` (~5.9%)
  - `mem.eqlBytes` (~5.4%)
  - `heap.arena_allocator.ArenaAllocator.alloc` (~4.5%)
  - `layouting.wrap` (~3.2%)
  - `kbts__PlaceShapeConfig` and related shaping lookups (combined significant)
- `stbi__*` PNG decode still appears in steady-state samples, indicating image decode/load is still contaminating measurements (or still happening during sampled interval).
- `debug.assert` is non-trivial in Debug and should be treated as measurement overhead, not product behavior.

## 1. Instrument before changing behavior

- Add timers around:
  - `component(...)` in `examples/uhoh.com/src/main.zig`
  - `layout(...)` in `examples/uhoh.com/src/main.zig`
  - `drawFrame(...)` in `examples/uhoh.com/src/main.zig`
  - `update(...)` in `examples/uhoh.com/src/main.zig`
- Print p50/p95 and max every 2s.
- Keep this instrumentation while iterating.

Success criteria:
- You can attribute frame cost by stage, not guess.

## 2. Remove per-frame text allocation churn

- In `src/layouting.zig`, avoid per-glyph `dupe(...)` work during layout.
- Replace per-frame glyph text allocation with compact non-owning metadata (ex: `is_space`, codepoint, or equivalent marker needed by wrap logic).

Success criteria:
- Lower allocator pressure.
- Lower and smoother layout time.

## 3. Reduce node-build hashing overhead

- In `src/root.zig`, avoid rehashing full node path bytes for each `element(...)` / `text(...)`.
- Move to an incremental hash stack model (push/pop updates) per traversal depth.

Success criteria:
- Lower CPU in UI tree construction at scale.

## 4. Optimize update traversal data structures

- In `src/root.zig:update(...)`, replace repeated linear scans for hovered keys with O(1)-ish structures (hash set / mark table).
- Keep semantics the same (`mouseOver`/`mouseOut` dispatch behavior).

Success criteria:
- Update pass scales better with many elements.

## 5. Cut draw prep overhead

- In `src/graphics.zig:drawFrame(...)`, avoid sorting full layout list by z each frame if possible.
- Use z-bucketing while traversing or equivalent strategy to preserve ordering guarantees with less work.

Success criteria:
- Lower CPU in render prep for larger scenes.

## 6. Make image registration lookup constant time

- `ElementsPipeline.registerImage(...)` currently scans linearly for already-registered image pointers.
- Add pointer->index map so repeated lookup in draw prep is O(1).

Success criteria:
- Image-heavy UIs stop paying repeated linear lookup cost.

## 7. Keep debug overhead out of performance measurements

- For profiling runs, disable Vulkan validation layers/debug messenger and high-frequency logging.
- Keep correctness checks for normal debug work, but use measurement-specific configuration when profiling.

Success criteria:
- Profiling reflects engine workload, not validation/log overhead.

## 8. Eliminate measurement contamination from startup work

- Warm up app first, then attach profiler to running PID for steady-state sampling.
- Ensure all image/font decode/load has completed before sampling interval.

Success criteria:
- `stbi__*` startup decode work should mostly disappear from steady-state profiles.

## 9. Re-profile after each step

- Use:
  - `perf stat -d -- zig build run`
  - `perf record -F 999 -g -- zig build run`
  - `perf report`
- Do not batch many changes before measuring.

Success criteria:
- Each change has clear before/after evidence.

## 10. Final "milk it" pass

- Revisit layout pass ordering and merge passes where safe.
- Reuse persistent scratch buffers for renderer prep.
- Parallelize independent root layout subtrees only after single-thread optimizations are exhausted.

Success criteria:
- Final measurable CPU and frame-time gains after major bottlenecks are addressed.
