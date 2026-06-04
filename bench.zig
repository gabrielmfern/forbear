const std = @import("std");
const linux = std.os.linux;
const Type = std.builtin.Type;
const PERF_EVENT_IOC_RESET = linux.PERF.EVENT_IOC.RESET;
const PERF_EVENT_IOC_ENABLE = linux.PERF.EVENT_IOC.ENABLE;
const PERF_EVENT_IOC_DISABLE = linux.PERF.EVENT_IOC.DISABLE;
const Writer = std.Io.Writer;
const math = std.math;
const sort = std.sort;
const Timestamp = std.Io.Timestamp;
const Clock = std.Io.Clock;
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");

const forbear = @import("forbear");

// Per-node style picks for the layout benchmark. Dispatching by a
// runtime index lets us vary sizing/padding/justification/min-max
// constraints across the tree so layout does meaningful work for each
// kind of node (instead of only resolving uniform `grow` leaves).
fn leafStyle(idx: usize) forbear.Style {
    return switch (idx % 6) {
        0 => .{ .width = .{ .fixed = 40 }, .height = .{ .fixed = 30 } },
        1 => .{ .width = .{ .grow = 1.0 }, .height = .{ .fixed = 24 } },
        2 => .{
            .width = .{ .grow = 2.0 },
            .height = .{ .fixed = 30 },
            .padding = forbear.Padding.all(2),
        },
        3 => .{ .width = .{ .fixed = 60 }, .height = .{ .ratio = 0.5 } },
        4 => .{ .width = .{ .ratio = 2.0 }, .height = .{ .fixed = 28 } },
        else => .{
            .width = .{ .grow = 1.0 },
            .height = .{ .fixed = 30 },
            .minWidth = 24,
            .maxWidth = 200,
        },
    };
}

fn rowStyle(idx: usize) forbear.Style {
    return switch (idx % 3) {
        0 => .{
            .width = .{ .grow = 1.0 },
            .height = .fit,
            .direction = .horizontal,
        },
        1 => .{
            .width = .{ .grow = 1.0 },
            .height = .{ .fixed = 60 },
            .direction = .horizontal,
            .xJustification = .center,
        },
        else => .{
            .width = .{ .grow = 1.0 },
            .height = .fit,
            .direction = .horizontal,
            .padding = forbear.Padding.all(4),
            .yJustification = .center,
        },
    };
}

fn sectionStyle(idx: usize) forbear.Style {
    return switch (idx % 2) {
        0 => .{
            .width = .{ .grow = 1.0 },
            .height = .fit,
            .direction = .vertical,
        },
        else => .{
            .width = .{ .grow = 1.0 },
            .height = .fit,
            .direction = .vertical,
            .padding = forbear.Padding.all(8),
        },
    };
}

// Builds a layout-only tree of exactly `nodeCount` element nodes (root
// counts) by packing into uniformly shaped sections / rows / leaves and
// distributing any remainder as a partial section + partial row.
//
// Per-section: 1 wrapper + R rows × (1 + L leaves) = 1 + R*(1+L)
// With R=5, L=6: row = 7 nodes, section = 36 nodes.
//
// Runtime loops keep this monomorphic (one compiled copy regardless of
// `nodeCount`), so layout perf at 10000 nodes doesn't blow up codegen.
// Each element gets an explicit `key` because all iterations of a
// runtime `for` share the same `@returnAddress()`; the key string only
// needs to live long enough to be hashed inside `element()`, so we can
// reuse a single stack buffer.
fn buildLayoutTree(nodeCount: usize) void {
    const R: usize = 5;
    const L: usize = 6;
    const rowSize: usize = 1 + L;
    const sectionSize: usize = 1 + R * rowSize;

    const budgetAfterRoot: usize = if (nodeCount == 0) 0 else nodeCount - 1;

    const fullSections = budgetAfterRoot / sectionSize;
    const afterSections = budgetAfterRoot - fullSections * sectionSize;

    const hasPartialSection = afterSections >= 1 + rowSize;
    const partialBudget = if (hasPartialSection) afterSections - 1 else 0;
    const partialRows = partialBudget / rowSize;
    const afterRows = partialBudget - partialRows * rowSize;
    const hasPartialRow = hasPartialSection and afterRows >= 1;
    const tailLeavesInRow = if (hasPartialRow) afterRows - 1 else 0;
    const strayLeaves = if (hasPartialSection) 0 else afterSections;

    forbear.element(.{ .style = .{
        .width = .{ .grow = 1.0 },
        .height = .{ .grow = 1.0 },
        .direction = .vertical,
    } })({
        var keyBuf: [48]u8 = undefined;

        for (0..fullSections) |si| {
            const sk = std.fmt.bufPrint(&keyBuf, "s{d}", .{si}) catch unreachable;
            forbear.element(.{ .style = sectionStyle(si), .key = sk })({
                for (0..R) |ri| {
                    const rk = std.fmt.bufPrint(&keyBuf, "s{d}r{d}", .{ si, ri }) catch unreachable;
                    forbear.element(.{ .style = rowStyle(ri + si), .key = rk })({
                        for (0..L) |li| {
                            const lk = std.fmt.bufPrint(&keyBuf, "s{d}r{d}l{d}", .{ si, ri, li }) catch unreachable;
                            forbear.element(.{ .style = leafStyle(li + ri * 2 + si * 3), .key = lk })({});
                        }
                    });
                }
            });
        }

        if (hasPartialSection) {
            forbear.element(.{ .style = sectionStyle(fullSections), .key = "ps" })({
                for (0..partialRows) |ri| {
                    const rk = std.fmt.bufPrint(&keyBuf, "psr{d}", .{ri}) catch unreachable;
                    forbear.element(.{ .style = rowStyle(ri + fullSections), .key = rk })({
                        for (0..L) |li| {
                            const lk = std.fmt.bufPrint(&keyBuf, "psr{d}l{d}", .{ ri, li }) catch unreachable;
                            forbear.element(.{ .style = leafStyle(li + ri * 2 + fullSections * 3), .key = lk })({});
                        }
                    });
                }
                if (hasPartialRow) {
                    forbear.element(.{ .style = rowStyle(partialRows + fullSections), .key = "pstail" })({
                        for (0..tailLeavesInRow) |li| {
                            const lk = std.fmt.bufPrint(&keyBuf, "pstail_l{d}", .{li}) catch unreachable;
                            forbear.element(.{ .style = leafStyle(li + partialRows * 2 + fullSections * 3), .key = lk })({});
                        }
                    });
                }
            });
        }

        for (0..strayLeaves) |li| {
            const lk = std.fmt.bufPrint(&keyBuf, "stray{d}", .{li}) catch unreachable;
            forbear.element(.{ .style = leafStyle(li), .key = lk })({});
        }
    });
}

fn layoutOnce(arena: *std.heap.ArenaAllocator) void {
    // The frame arena is shared across every benchmark iteration. `layout()`
    // allocates transient scratch buffers (grow factors, sibling orderings,
    // etc.) per call; if we never reset, that memory accumulates over
    // thousands of iterations and balloons heap usage at large node counts.
    // The node tree itself lives in forbear's internal allocator, so
    // resetting the frame arena does not invalidate it.
    _ = arena.reset(.retain_capacity);
    _ = forbear.layout() catch unreachable;
}

// Builds the tree inside a frame once, then runs `run()` against
// `layoutOnce` so only the cost of `forbear.layout()` is measured.
// `layout()` is safe to call repeatedly within a single frame: it
// recomputes sizes/positions from scratch and the node tree is only
// cleared in `frameEnd`.
fn runLayoutBench(
    io: std.Io,
    allocator: std.mem.Allocator,
    comptime nodeCount: usize,
) !Metrics {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const frameEnd = forbear.frame(.{
        .arena = arena.allocator(),
        .viewportSize = .{ 1920, 1080 },
        .baseStyle = .{
            .font = forbear.useFont("Inter") catch unreachable,
            .color = .{ 0, 0, 0, 1 },
            .fontSize = 16,
            .fontWeight = 400,
            .lineHeight = 1.0,
            .textWrapping = .none,
            .blendMode = .normal,
            .cursor = .default,
        },
    });

    buildLayoutTree(nodeCount);

    const name = std.fmt.comptimePrint("layout() {d} nodes", .{nodeCount});
    const metrics = try run(io, allocator, name, layoutOnce, .{&arena}, .{});

    try frameEnd({});
    return metrics;
}

// ~stateCount useState calls spread across mixed component+element scopes
// at depths 0..7. Each leaf component contains both an inner element scope
// and is itself nested several components deep.
//
// Per-scope state counts (component scope + immediate element scope):
//   App     :  4 + 4 =  8
//   Section :  4 + 4 =  8  ×  N_sections    →
//   Panel   :  4 + 4 =  8  ×  N_sections×4  →
//   Leaf    :  4 + 4 =  8  ×  N_sections×4×5 →
//
// Runtime loops + explicit `key` strings keep this monomorphic. The 4
// useState calls per scope stay written out (not in a loop) so each call
// has a distinct `@returnAddress()` and hashes to a distinct state slot.
fn StateLeaf(tag: []const u8) void {
    forbear.component(.{ .key = tag })({
        _ = forbear.useState(u32, 0);
        _ = forbear.useState(f32, 0.0);
        _ = forbear.useState(bool, false);
        _ = forbear.useState(u64, 0);

        forbear.element(.{ .style = .{
            .width = .{ .fixed = 10 },
            .height = .{ .fixed = 10 },
        } })({
            _ = forbear.useState(u32, 0);
            _ = forbear.useState(f32, 0.0);
            _ = forbear.useState(bool, false);
            _ = forbear.useState(u64, 0);
        });
    });
}

fn StatePanel(tag: []const u8) void {
    forbear.component(.{ .key = tag })({
        _ = forbear.useState(u32, 0);
        _ = forbear.useState(f32, 0.0);
        _ = forbear.useState(bool, false);
        _ = forbear.useState(u64, 0);

        forbear.element(.{ .style = .{
            .width = .{ .grow = 1.0 },
            .height = .fit,
            .direction = .horizontal,
        } })({
            _ = forbear.useState(u32, 0);
            _ = forbear.useState(f32, 0.0);
            _ = forbear.useState(bool, false);
            _ = forbear.useState(u64, 0);

            var kb: [64]u8 = undefined;
            for (0..5) |i| {
                const child = std.fmt.bufPrint(&kb, "{s}_l{d}", .{ tag, i }) catch unreachable;
                StateLeaf(child);
            }
        });
    });
}

fn StateSection(tag: []const u8) void {
    forbear.component(.{ .key = tag })({
        _ = forbear.useState(u32, 0);
        _ = forbear.useState(f32, 0.0);
        _ = forbear.useState(bool, false);
        _ = forbear.useState(u64, 0);

        forbear.element(.{ .style = .{
            .width = .{ .grow = 1.0 },
            .height = .fit,
            .direction = .vertical,
        } })({
            _ = forbear.useState(u32, 0);
            _ = forbear.useState(f32, 0.0);
            _ = forbear.useState(bool, false);
            _ = forbear.useState(u64, 0);

            var kb: [64]u8 = undefined;
            for (0..4) |i| {
                const child = std.fmt.bufPrint(&kb, "{s}_p{d}", .{ tag, i }) catch unreachable;
                StatePanel(child);
            }
        });
    });
}

fn buildUseStateTree(stateCount: usize) void {
    var appKeyBuf: [40]u8 = undefined;
    const appKey = std.fmt.bufPrint(&appKeyBuf, "UseStateBenchApp_{d}", .{stateCount}) catch unreachable;

    forbear.component(.{ .key = appKey })({
        forbear.element(.{ .style = .{
            .width = .{ .grow = 1.0 },
            .height = .{ .grow = 1.0 },
            .direction = .vertical,
        } })({
            // Spread `stateCount` useState calls across mixed component +
            // element scopes at depths 2..7. Each leaf component owns 4
            // component-scope states and a child element with 4
            // element-scope states (8 per leaf). Any remainder past the
            // last full leaf is added as element-scope states on the
            // outer element above to keep the count exact.
            const leavesPerPanel: usize = 5;
            const panelsPerSection: usize = 4;

            const perLeaf: usize = 8;
            const perPanel: usize = leavesPerPanel * perLeaf;
            const perSection: usize = panelsPerSection * perPanel;

            const sections = stateCount / perSection;
            const afterSections = stateCount - sections * perSection;
            const fullPanels = afterSections / perPanel;
            const afterPanels = afterSections - fullPanels * perPanel;
            const fullLeaves = afterPanels / perLeaf;
            const tailLeafStates = afterPanels - fullLeaves * perLeaf;

            var kb: [64]u8 = undefined;
            for (0..sections) |si| {
                const ck = std.fmt.bufPrint(&kb, "us_{d}_s{d}", .{ stateCount, si }) catch unreachable;
                StateSection(ck);
            }

            if (fullPanels > 0 or fullLeaves > 0 or tailLeafStates > 0) {
                var tailKeyBuf: [40]u8 = undefined;
                const tailKey = std.fmt.bufPrint(&tailKeyBuf, "UseStateTail_{d}", .{stateCount}) catch unreachable;
                forbear.component(.{ .key = tailKey })({
                    forbear.element(.{ .style = .{
                        .width = .{ .grow = 1.0 },
                        .height = .fit,
                        .direction = .vertical,
                    } })({
                        var tkb: [64]u8 = undefined;
                        for (0..fullPanels) |pi| {
                            const ck = std.fmt.bufPrint(&tkb, "us_{d}_tp{d}", .{ stateCount, pi }) catch unreachable;
                            StatePanel(ck);
                        }
                        for (0..fullLeaves) |li| {
                            const ck = std.fmt.bufPrint(&tkb, "us_{d}_tl{d}", .{ stateCount, li }) catch unreachable;
                            StateLeaf(ck);
                        }

                        // `tailLeafStates ∈ 0..7`. Each `useState` call site
                        // needs to be a distinct source line so it hashes
                        // to a distinct state slot — runtime `for` would
                        // collapse them all onto one `@returnAddress`.
                        if (tailLeafStates >= 1) _ = forbear.useState(u32, 0);
                        if (tailLeafStates >= 2) _ = forbear.useState(u32, 0);
                        if (tailLeafStates >= 3) _ = forbear.useState(u32, 0);
                        if (tailLeafStates >= 4) _ = forbear.useState(u32, 0);
                        if (tailLeafStates >= 5) _ = forbear.useState(u32, 0);
                        if (tailLeafStates >= 6) _ = forbear.useState(u32, 0);
                        if (tailLeafStates >= 7) _ = forbear.useState(u32, 0);
                    });
                });
            }
        });
    });
}

fn useStateFrame(arena: *std.heap.ArenaAllocator, stateCount: usize) void {
    // Reset-and-reuse instead of init/deinit per iteration. A fresh arena
    // each call ends up doing mmap on init and munmap on deinit, which on
    // GitHub-hosted runners pays variable hypervisor overhead and dominates
    // the per-call cost for small `stateCount`. The layout bench already
    // uses this pattern (see `layoutOnce`).
    _ = arena.reset(.retain_capacity);
    (forbear.frame(.{
        .arena = arena.allocator(),
        .viewportSize = .{ 1920, 1080 },
        .baseStyle = .{
            .font = forbear.useFont("Inter") catch unreachable,
            .color = .{ 0, 0, 0, 1 },
            .fontSize = 16,
            .fontWeight = 400,
            .lineHeight = 1.0,
            .textWrapping = .none,
            .blendMode = .normal,
            .cursor = .default,
        },
    })({
        buildUseStateTree(stateCount);
    })) catch unreachable;
}

fn runUseStateBench(
    io: std.Io,
    allocator: std.mem.Allocator,
    comptime stateCount: usize,
) !Metrics {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const name = std.fmt.comptimePrint("useState() {d} states", .{stateCount});
    return try run(io, allocator, name, useStateFrame, .{ &arena, stateCount }, .{});
}

pub fn main(init: std.process.Init) !void {
    // Use a real general-purpose allocator instead of `init.arena.allocator()`.
    // `init.arena` is a non-freeing arena, so every `ArrayList` resize inside
    // forbear and every per-iteration `arena.deinit()` in the bench would leak
    // pages into it. At large node/state counts that growth easily reaches
    // multi-GB. `smp_allocator` actually frees on `rawFree`.
    const allocator = std.heap.smp_allocator;

    try forbear.init(allocator, init.io, undefined, undefined);
    defer forbear.deinit();
    try forbear.registerFont("Inter", @embedFile("Inter.ttf"));

    var layoutMetrics: [9]Metrics = undefined;
    layoutMetrics[0] = try runLayoutBench(init.io, allocator, 27);
    layoutMetrics[1] = try runLayoutBench(init.io, allocator, 135);
    layoutMetrics[2] = try runLayoutBench(init.io, allocator, 500);
    layoutMetrics[3] = try runLayoutBench(init.io, allocator, 1000);
    layoutMetrics[4] = try runLayoutBench(init.io, allocator, 2641);
    layoutMetrics[5] = try runLayoutBench(init.io, allocator, 5000);
    layoutMetrics[6] = try runLayoutBench(init.io, allocator, 10000);
    layoutMetrics[7] = try runLayoutBench(init.io, allocator, 20000);
    layoutMetrics[8] = try runLayoutBench(init.io, allocator, 50000);
    try print(.{ .metrics = &layoutMetrics });

    var stateMetrics: [9]Metrics = undefined;
    stateMetrics[0] = try runUseStateBench(init.io, allocator, 27);
    stateMetrics[1] = try runUseStateBench(init.io, allocator, 135);
    stateMetrics[2] = try runUseStateBench(init.io, allocator, 500);
    stateMetrics[3] = try runUseStateBench(init.io, allocator, 1000);
    stateMetrics[4] = try runUseStateBench(init.io, allocator, 2000);
    stateMetrics[5] = try runUseStateBench(init.io, allocator, 5000);
    stateMetrics[6] = try runUseStateBench(init.io, allocator, 10000);
    stateMetrics[7] = try runUseStateBench(init.io, allocator, 20000);
    stateMetrics[8] = try runUseStateBench(init.io, allocator, 50000);
    try print(.{ .metrics = &stateMetrics });
}

// =================================================================================
// The following code is a slightly modified version of
// https://github.com/pyk/bench
//
// MIT License
//
// Copyright (c) 2025 pyk
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// =================================================================================

const Metrics = struct {
    ///////////////////////////////////////////////////////////////////////////////
    // Meta

    /// The identifier string for the benchmark
    name: []const u8,
    /// Total number of measurement samples collected
    samples: usize,
    /// Number of executions per sample (batch size)
    iterations: u64,

    ///////////////////////////////////////////////////////////////////////////////
    // Time

    /// Minimum execution time per operation (nanoseconds)
    min_ns: f64,
    /// Maximum execution time per operation (nanoseconds)
    max_ns: f64,
    /// Mean execution time (nanoseconds)
    mean_ns: f64,
    /// Median execution time (nanoseconds)
    median_ns: f64,
    /// Standard deviation of the execution time
    std_dev_ns: f64,

    ///////////////////////////////////////////////////////////////////////////////
    // Throughput

    /// Calculated operations per second
    ops_sec: f64,
    /// Data throughput in MB/s (populated if `bytes_per_op` > 0)
    mb_sec: f64,

    ///////////////////////////////////////////////////////////////////////////////
    // Hardware (Linux only, null otherwise)

    /// Average CPU cycles per operation
    cycles: ?f64 = null,
    /// Average CPU instructions executed per operation
    instructions: ?f64 = null,
    /// Instructions Per Cycle (efficiency ratio)
    ipc: ?f64 = null,
    /// Average cache misses per operation
    cache_misses: ?f64 = null,

    ///////////////////////////////////////////////////////////////////////////////
    // Software events (Linux only, fallback when hardware PMU is unavailable —
    // e.g. inside CI runner VMs)

    /// Average page faults per operation
    page_faults: ?f64 = null,
    /// Average context switches per operation
    context_switches: ?f64 = null,
};

// Bits for perf_event_attr.read_format
const PERF_FORMAT_TOTAL_TIME_ENABLED = 1 << 0;
const PERF_FORMAT_TOTAL_TIME_RUNNING = 1 << 1;
const PERF_FORMAT_ID = 1 << 2;
const PERF_FORMAT_GROUP = 1 << 3;

// Various ioctls act on perf_event_open() file descriptors:
const PERF_EVENT_IOC_ID = linux.IOCTL.IOR('$', 7, u64);
/// Events supported by the kernel for performance monitoring. Each maps to a
/// `(type, config)` pair for the `perf_event_open` syscall. Hardware events
/// require a real PMU; the software events still work in VMs (CI runners
/// don't expose a hardware PMU), so we use them as a fallback.
const Event = enum {
    cpu_cycles,
    instructions,
    cache_misses,
    branch_misses,
    bus_cycles,
    // Software events — counted by the kernel, available even in VMs.
    page_faults,
    context_switches,
    cpu_migrations,

    fn toType(self: Event) linux.PERF.TYPE {
        return switch (self) {
            .cpu_cycles, .instructions, .cache_misses, .branch_misses, .bus_cycles => linux.PERF.TYPE.HARDWARE,
            .page_faults, .context_switches, .cpu_migrations => linux.PERF.TYPE.SOFTWARE,
        };
    }

    /// Converts the enum into the specific kernel configuration integer
    /// required by the `perf_event_open` syscall.
    fn toConfig(self: Event) u64 {
        return switch (self) {
            .cpu_cycles => @intFromEnum(linux.PERF.COUNT.HW.CPU_CYCLES),
            .instructions => @intFromEnum(linux.PERF.COUNT.HW.INSTRUCTIONS),
            .cache_misses => @intFromEnum(linux.PERF.COUNT.HW.CACHE_MISSES),
            .branch_misses => @intFromEnum(linux.PERF.COUNT.HW.BRANCH_MISSES),
            .bus_cycles => @intFromEnum(linux.PERF.COUNT.HW.BUS_CYCLES),
            .page_faults => @intFromEnum(linux.PERF.COUNT.SW.PAGE_FAULTS),
            .context_switches => @intFromEnum(linux.PERF.COUNT.SW.CONTEXT_SWITCHES),
            .cpu_migrations => @intFromEnum(linux.PERF.COUNT.SW.CPU_MIGRATIONS),
        };
    }
};

fn GroupReadOutputType(comptime events: []const Event) type {
    var fieldNames: [events.len][]const u8 = undefined;
    var fieldTypes: [events.len]type = undefined;
    var fieldAttrs: [events.len]Type.StructField.Attributes = undefined;
    for (events, 0..) |event, index| {
        fieldNames[index] = @tagName(event);
        fieldTypes[index] = u64;
        fieldAttrs[index] = .{
            .@"comptime" = false,
            .@"align" = @alignOf(u64),
            .default_value_ptr = null,
        };
    }
    return @Struct(
        .auto,
        null,
        &fieldNames,
        &fieldTypes,
        &fieldAttrs,
    );
}

/// A type-safe wrapper for the Linux `perf_event_open` system call,
/// specifically configured for event grouping (`PERF_FORMAT_GROUP`).
///
/// `Group` leverages Zig's `comptime` features to generate a custom
/// `ReadOutputType` result type that strictly matches the requested `events`.
/// It manages the complexity of creating a group leader, attaching sibling
/// events, and handling the binary layout of the kernel's read buffer.
///
/// Notes:
/// * The `read()` method returns a struct with named fields corresponding
///   exactly to the input events (e.g. `.cpu_cycles`).
/// * The `read()` method automatically detects if the CPU was oversubscribed
///   and scales the counter values based on `time_enabled` and `time_running`.
///
/// References:
/// * man 2 perf_event_open
/// * man 1 perf-list
fn Group(comptime events: []const Event) type {
    if (events.len == 0) @compileError("Group requires at least 1 event");

    const Error = error{
        /// Failed to open group via perf_event_open
        OpenGroupFailed,
        /// Failed to retrieve the ID of the event via IOCTL
        GetIdFailed,
        /// Failed to reset counters via IOCTL
        ResetGroupFailed,
        /// Failed to enable counters via IOCTL
        EnableGroupFailed,
        /// Failed to disable counters via IOCTL
        DisableGroupFailed,
        /// Failed to read data from the file descriptor
        ReadGroupFailed,
        /// Group already deinitialized
        BadGroup,
    };

    const Output = GroupReadOutputType(events);

    // Matches the binary layout of the buffer read from the group leader fd.
    // See `man perf_event_open` section "Reading results".
    // Corresponds to `struct read_format` when using:
    // PERF_FORMAT_GROUP | PERF_FORMAT_TOTAL_TIME_ENABLED |
    // PERF_FORMAT_TOTAL_TIME_RUNNING | PERF_FORMAT_ID
    const ReadFormatGroup = extern struct {
        /// The number of events in this group.
        nr: u64,
        /// Total time the event group was enabled.
        time_enabled: u64,
        /// Total time the event group was actually running.
        time_running: u64,
        /// Array of values matching the `nr` of events.
        values: [events.len]extern struct {
            value: u64,
            id: u64,
        },
    };

    return struct {
        const Self = @This();

        event_fds: [events.len]linux.fd_t = undefined,
        event_ids: [events.len]u64 = undefined,

        /// Initializes the performance monitoring group.
        ///
        /// This opens a file descriptor for every event in the `events` list.
        /// The first event becomes the group leader. All subsequent events
        /// are created as siblings pinned to the leader.
        ///
        /// The counters start in a disabled state. You must call `enable()`
        /// to begin counting.
        ///
        /// **Note:** The caller owns the returned group and must call `deinit`
        /// to close the file descriptors.
        fn init() Error!Self {
            var self = Self{};
            @memset(&self.event_fds, -1);

            // Leader
            var groupFd = @as(i32, -1);
            self.event_fds[0] = try perfOpenGroup(groupFd, events[0].toType(), events[0].toConfig());
            self.event_ids[0] = try ioctlGetId(self.event_fds[0]);
            groupFd = self.event_fds[0];

            // Siblings
            if (events.len > 1) {
                for (events[1..], 1..) |event, i| {
                    self.event_fds[i] = try perfOpenGroup(groupFd, event.toType(), event.toConfig());
                    self.event_ids[i] = try ioctlGetId(self.event_fds[i]);
                }
            }
            return self;
        }

        /// Closes all file descriptors associated with this event group.
        /// This invalidates the group object.
        fn deinit(self: *Self) void {
            for (self.event_fds, 0..) |eventFd, index| {
                if (eventFd != -1) {
                    _ = linux.close(eventFd);
                }
                self.event_fds[index] = -1;
                self.event_ids[index] = 0;
            }
        }

        /// Resets and enables the event group. Counting begins immediately.
        fn enable(self: *Self) Error!void {
            const groupFd = self.event_fds[0];
            if (groupFd == -1) return error.BadGroup;
            try ioctlResetGroup(groupFd);
            try ioctlEnableGroup(groupFd);
        }

        /// Disables the event group. Counting stops immediately.
        fn disable(self: *Self) Error!void {
            const groupFd = self.event_fds[0];
            if (groupFd == -1) return error.BadGroup;
            try ioctlDisableGroup(groupFd);
        }

        /// Reads the current values from the kernel and maps them to the
        /// type-safe output struct.
        ///
        /// This performs the following operations:
        /// 1. Reads the `read_format` binary struct from the leader FD.
        /// 2. Checks `time_enabled` and `time_running` to detect if the CPU
        ///    was oversubscribed.
        /// 3. If multiplexing occurred (time_running < time_enabled), scales
        ///    the raw values: `val = raw_val * (time_enabled / time_running)`
        /// 4. Maps the kernel's event IDs back to the field names of the output
        ///    struct.
        fn read(self: *Self) Error!Output {
            var output: Output = std.mem.zeroes(Output);
            var data: ReadFormatGroup = undefined;

            const rc = linux.read(self.event_fds[0], @ptrCast(&data), @sizeOf(ReadFormatGroup));
            if (linux.errno(rc) != .SUCCESS) return error.ReadGroupFailed;

            // If time_running is 0, we can't scale, so return zeros.
            if (data.time_running == 0) return output;

            // Multiplexing scaling: scaled_value = value * (time_enabled / time_running)
            const scaleNeeded = data.time_running < data.time_enabled;
            const scaleFactor = if (scaleNeeded)
                @as(f64, @floatFromInt(data.time_enabled)) / @as(f64, @floatFromInt(data.time_running))
            else
                1.0;

            for (data.values) |item| {
                var val = item.value;

                if (scaleNeeded) {
                    val = @as(u64, @intFromFloat(@as(f64, @floatFromInt(val)) * scaleFactor));
                }

                // Map the kernel ID back to our event tags
                inline for (events, 0..) |tag, i| {
                    if (item.id == self.event_ids[i]) {
                        @field(output, @tagName(tag)) = val;
                    }
                }
            }

            return output;
        }

        ///////////////////////////////////////////////////////////////////////////////
        // perf & ioctl calls

        // Open new file descriptor for the specific event
        fn perfOpenGroup(groupFd: linux.fd_t, eventType: linux.PERF.TYPE, config: u64) Error!linux.fd_t {
            var attr = std.mem.zeroes(linux.perf_event_attr);
            attr.type = eventType;
            attr.config = config;

            // Enable grouping and ID tracking
            attr.read_format = PERF_FORMAT_GROUP |
                PERF_FORMAT_TOTAL_TIME_ENABLED |
                PERF_FORMAT_TOTAL_TIME_RUNNING |
                PERF_FORMAT_ID;

            attr.flags.disabled = (groupFd == -1); // Only leader starts disabled
            attr.flags.inherit = true;
            attr.flags.exclude_kernel = true;
            attr.flags.exclude_hv = true;

            // ref: `man 2 perf_event_open`
            // pid=0 (current process), cpu=-1 (any cpu), flags=0
            const pid = 0;
            const cpu = -1;
            const flags = 0;

            const rc = linux.perf_event_open(&attr, pid, cpu, groupFd, flags);
            if (linux.errno(rc) != .SUCCESS) return error.OpenGroupFailed;
            return @intCast(rc);
        }

        // ref: `man 2 perf_event_open` then search for `PERF_EVENT_IOC_ID`
        fn ioctlGetId(fd: linux.fd_t) Error!u64 {
            var id: u64 = 0;
            const rc = linux.ioctl(fd, PERF_EVENT_IOC_ID, @intFromPtr(&id));
            if (linux.errno(rc) != .SUCCESS) return error.GetIdFailed;
            return id;
        }

        // ref: `man 2 perf_event_open` then search for `PERF_EVENT_IOC_RESET`
        fn ioctlResetGroup(fd: linux.fd_t) Error!void {
            const rc = linux.ioctl(fd, PERF_EVENT_IOC_RESET, 0);
            if (linux.errno(rc) != .SUCCESS) return error.ResetGroupFailed;
        }

        // ref: `man 2 perf_event_open` then search for `PERF_EVENT_IOC_ENABLE`
        fn ioctlEnableGroup(fd: linux.fd_t) Error!void {
            const rc = linux.ioctl(fd, PERF_EVENT_IOC_ENABLE, 0);
            if (linux.errno(rc) != .SUCCESS) return error.EnableGroupFailed;
        }

        // ref: `man 2 perf_event_open` then search for `PERF_EVENT_IOC_DISABLE`
        fn ioctlDisableGroup(fd: linux.fd_t) Error!void {
            const rc = linux.ioctl(fd, PERF_EVENT_IOC_DISABLE, 0);
            if (linux.errno(rc) != .SUCCESS) return error.DisableGroupFailed;
        }
    };
}

const PrintOptions = struct {
    metrics: []const Metrics,
    baseline_index: ?usize = null,
};

const Column = struct {
    title: []const u8,
    width: usize,
    align_right: bool,
    active: bool,
};

fn print(options: PrintOptions) !void {
    var buffer: [64 * 1024]u8 = undefined;
    var w: Writer = .fixed(&buffer);
    try write(&w, options);
    std.debug.print("{s}", .{w.buffered()});
}

fn write(w: *Writer, options: PrintOptions) !void {
    if (options.metrics.len == 0) return;

    // Initialize columns with Header names and default visibility
    var colName = Column{ .title = "Benchmark", .width = 0, .align_right = false, .active = true };
    var colTime = Column{ .title = "Time", .width = 0, .align_right = true, .active = true };
    var colSpeedup = Column{ .title = "Speedup", .width = 0, .align_right = true, .active = false };
    var colIter = Column{ .title = "Iterations", .width = 0, .align_right = true, .active = true };

    var colBytes = Column{ .title = "Bytes/s", .width = 0, .align_right = true, .active = false };
    var colOps = Column{ .title = "Ops/s", .width = 0, .align_right = true, .active = false };
    var colCycles = Column{ .title = "Cycles", .width = 0, .align_right = true, .active = false };
    var colInstr = Column{ .title = "Instructions", .width = 0, .align_right = true, .active = false };
    var colIpc = Column{ .title = "IPC", .width = 0, .align_right = true, .active = false };
    var colMiss = Column{ .title = "Cache Misses", .width = 0, .align_right = true, .active = false };
    var colPageFaults = Column{ .title = "Page Faults", .width = 0, .align_right = true, .active = false };
    var colCtxSwitches = Column{ .title = "Ctx Switches", .width = 0, .align_right = true, .active = false };

    // We must format every number to a temporary buffer to know its length.
    var buf: [64]u8 = undefined;

    // Activate Rel column if baseline_index is valid
    if (options.baseline_index) |idx| {
        if (idx < options.metrics.len) {
            colSpeedup.active = true;
        }
    }

    // Check headers first
    colName.width = colName.title.len;
    colTime.width = colTime.title.len;
    colSpeedup.width = colSpeedup.title.len;
    colIter.width = colIter.title.len;
    colBytes.width = colBytes.title.len;
    colOps.width = colOps.title.len;
    colCycles.width = colCycles.title.len;
    colInstr.width = colInstr.title.len;
    colIpc.width = colIpc.title.len;
    colMiss.width = colMiss.title.len;
    colPageFaults.width = colPageFaults.title.len;
    colCtxSwitches.width = colCtxSwitches.title.len;

    for (options.metrics) |m| {
        // Name: +2 for backticks
        colName.width = @max(colName.width, m.name.len + 2);

        // Time (with ± std deviation)
        const sTime = try fmtTimeWithSd(&buf, m.median_ns, m.std_dev_ns);
        colTime.width = @max(colTime.width, sTime.len);

        // Relative
        if (colSpeedup.active) {
            const base = options.metrics[options.baseline_index.?];
            // Avoid division by zero
            const ratio = if (m.median_ns > 0) base.median_ns / m.median_ns else 0;
            const sRel = try std.fmt.bufPrint(&buf, "{d:.2}x", .{ratio});
            colSpeedup.width = @max(colSpeedup.width, sRel.len);
        }

        // Iterations (batch size — how many ops per sample)
        const sIter = try std.fmt.bufPrint(&buf, "{d}", .{m.iterations});
        colIter.width = @max(colIter.width, sIter.len);

        // Optional Columns (Enable & Measure)
        if (m.mb_sec > 0.001) {
            colBytes.active = true;
            const s = try fmtBytes(&buf, m.mb_sec);
            colBytes.width = @max(colBytes.width, s.len);
        }
        if (m.ops_sec > 0.001 and m.mb_sec <= 0.001) {
            colOps.active = true;
            const sVal = try fmtMetric(&buf, m.ops_sec);
            // We append "/s" in the final output, so add 2 to length
            colOps.width = @max(colOps.width, sVal.len + 2);
        }
        if (m.cycles) |v| {
            colCycles.active = true;
            const s = try fmtMetric(&buf, v);
            colCycles.width = @max(colCycles.width, s.len);
        }
        if (m.instructions) |v| {
            colInstr.active = true;
            const s = try fmtMetric(&buf, v);
            colInstr.width = @max(colInstr.width, s.len);
        }
        if (m.ipc) |v| {
            colIpc.active = true;
            const s = try std.fmt.bufPrint(&buf, "{d:.2}", .{v});
            colIpc.width = @max(colIpc.width, s.len);
        }
        if (m.cache_misses) |v| {
            colMiss.active = true;
            const s = try fmtMetric(&buf, v);
            colMiss.width = @max(colMiss.width, s.len);
        }
        // Software events are typically 0 in a CPU-bound steady-state
        // benchmark, so only surface the column if at least one row has a
        // non-trivial value worth showing.
        if (m.page_faults) |v| {
            if (v > 0.001) {
                colPageFaults.active = true;
                const s = try fmtMetric(&buf, v);
                colPageFaults.width = @max(colPageFaults.width, s.len);
            }
        }
        if (m.context_switches) |v| {
            if (v > 0.001) {
                colCtxSwitches.active = true;
                const s = try fmtMetric(&buf, v);
                colCtxSwitches.width = @max(colCtxSwitches.width, s.len);
            }
        }
    }

    // Header Row
    try w.writeAll("| ");
    try printCell(w, colName.title, colName);
    try printCell(w, colTime.title, colTime);
    if (colSpeedup.active) try printCell(w, colSpeedup.title, colSpeedup);
    try printCell(w, colIter.title, colIter);
    if (colBytes.active) try printCell(w, colBytes.title, colBytes);
    if (colOps.active) try printCell(w, colOps.title, colOps);
    if (colCycles.active) try printCell(w, colCycles.title, colCycles);
    if (colInstr.active) try printCell(w, colInstr.title, colInstr);
    if (colIpc.active) try printCell(w, colIpc.title, colIpc);
    if (colMiss.active) try printCell(w, colMiss.title, colMiss);
    if (colPageFaults.active) try printCell(w, colPageFaults.title, colPageFaults);
    if (colCtxSwitches.active) try printCell(w, colCtxSwitches.title, colCtxSwitches);
    try w.writeAll("\n");

    // Separator Row
    try w.writeAll("| ");
    try printDivider(w, colName);
    try printDivider(w, colTime);
    if (colSpeedup.active) try printDivider(w, colSpeedup);
    try printDivider(w, colIter);
    if (colBytes.active) try printDivider(w, colBytes);
    if (colOps.active) try printDivider(w, colOps);
    if (colCycles.active) try printDivider(w, colCycles);
    if (colInstr.active) try printDivider(w, colInstr);
    if (colIpc.active) try printDivider(w, colIpc);
    if (colMiss.active) try printDivider(w, colMiss);
    if (colPageFaults.active) try printDivider(w, colPageFaults);
    if (colCtxSwitches.active) try printDivider(w, colCtxSwitches);
    try w.writeAll("\n");

    // Data Rows
    for (options.metrics) |m| {
        try w.writeAll("| ");

        // Name
        const nameS = try std.fmt.bufPrint(&buf, "`{s}`", .{m.name});
        try printCell(w, nameS, colName);

        // Time (with ± std deviation)
        try printCell(w, try fmtTimeWithSd(&buf, m.median_ns, m.std_dev_ns), colTime);

        // Relative
        if (colSpeedup.active) {
            const base = options.metrics[options.baseline_index.?];
            const ratio = if (m.median_ns > 0) base.median_ns / m.median_ns else 0;
            const sRel = try std.fmt.bufPrint(&buf, "{d:.2}x", .{ratio});
            try printCell(w, sRel, colSpeedup);
        }

        // Iterations
        const iterS = try std.fmt.bufPrint(&buf, "{d}", .{m.iterations});
        try printCell(w, iterS, colIter);

        // Optional
        if (colBytes.active) {
            if (m.mb_sec > 0.001) try printCell(w, try fmtBytes(&buf, m.mb_sec), colBytes) else try printCell(w, "-", colBytes);
        }
        if (colOps.active) {
            if (m.ops_sec > 0.001) {
                // Must manually construct the string with suffix to match width measurement
                const val = try fmtMetric(&buf, m.ops_sec);
                var buf2: [64]u8 = undefined;
                const final = try std.fmt.bufPrint(&buf2, "{s}/s", .{val});
                try printCell(w, final, colOps);
            } else try printCell(w, "-", colOps);
        }
        if (colCycles.active) {
            if (m.cycles) |v| try printCell(w, try fmtMetric(&buf, v), colCycles) else try printCell(w, "-", colCycles);
        }
        if (colInstr.active) {
            if (m.instructions) |v| try printCell(w, try fmtMetric(&buf, v), colInstr) else try printCell(w, "-", colInstr);
        }
        if (colIpc.active) {
            if (m.ipc) |v| {
                const s = try std.fmt.bufPrint(&buf, "{d:.2}", .{v});
                try printCell(w, s, colIpc);
            } else try printCell(w, "-", colIpc);
        }
        if (colMiss.active) {
            if (m.cache_misses) |v| try printCell(w, try fmtMetric(&buf, v), colMiss) else try printCell(w, "-", colMiss);
        }
        if (colPageFaults.active) {
            if (m.page_faults) |v| try printCell(w, try fmtMetric(&buf, v), colPageFaults) else try printCell(w, "-", colPageFaults);
        }
        if (colCtxSwitches.active) {
            if (m.context_switches) |v| try printCell(w, try fmtMetric(&buf, v), colCtxSwitches) else try printCell(w, "-", colCtxSwitches);
        }

        try w.writeAll("\n");
    }
}

fn printCell(w: *Writer, text: []const u8, col: Column) !void {
    const padLen = if (col.width > text.len) col.width - text.len else 0;

    if (col.align_right) {
        _ = try w.splatByte(' ', padLen);
        try w.writeAll(text);
    } else {
        try w.writeAll(text);
        _ = try w.splatByte(' ', padLen);
    }
    try w.writeAll(" | ");
}

fn printDivider(w: *Writer, col: Column) !void {
    if (col.align_right) {
        // "-----------:"
        _ = try w.splatByte('-', col.width - 1);
        try w.writeAll(":");
    } else {
        // ":-----------"
        try w.writeAll(":");
        _ = try w.splatByte('-', col.width - 1);
    }
    try w.writeAll(" | ");
}

fn fmtTime(buf: []u8, ns: f64) ![]const u8 {
    if (ns < 1_000) return std.fmt.bufPrint(buf, "{d:.2} ns", .{ns});
    if (ns < 1_000_000) return std.fmt.bufPrint(buf, "{d:.2} us", .{ns / 1_000.0});
    if (ns < 1_000_000_000) return std.fmt.bufPrint(buf, "{d:.2} ms", .{ns / 1_000_000.0});
    return std.fmt.bufPrint(buf, "{d:.2} s", .{ns / 1_000_000_000.0});
}

/// Formats `mean ns ± sd ns` using the unit picked by `mean` for both halves,
/// so the values line up visually instead of jumping between us / ns / ms.
fn fmtTimeWithSd(buf: []u8, mean_ns: f64, sdNs: f64) ![]const u8 {
    const divisor: f64, const unit: []const u8 = blk: {
        if (mean_ns < 1_000) break :blk .{ 1.0, "ns" };
        if (mean_ns < 1_000_000) break :blk .{ 1_000.0, "us" };
        if (mean_ns < 1_000_000_000) break :blk .{ 1_000_000.0, "ms" };
        break :blk .{ 1_000_000_000.0, "s" };
    };
    return std.fmt.bufPrint(buf, "{d:.2} {s} ± {d:.3}", .{
        mean_ns / divisor,
        unit,
        sdNs / divisor,
    });
}

fn fmtBytes(buf: []u8, mb: f64) ![]const u8 {
    if (mb > 1000) return std.fmt.bufPrint(buf, "{d:.2}GB/s", .{mb / 1024.0});
    return std.fmt.bufPrint(buf, "{d:.2}MB/s", .{mb});
}

fn fmtMetric(buf: []u8, val: f64) ![]const u8 {
    if (val < 1_000) return std.fmt.bufPrint(buf, "{d:.1}", .{val});
    if (val < 1_000_000) return std.fmt.bufPrint(buf, "{d:.1}k", .{val / 1_000.0});
    if (val < 1_000_000_000) return std.fmt.bufPrint(buf, "{d:.1}M", .{val / 1_000_000.0});
    return std.fmt.bufPrint(buf, "{d:.1}G", .{val / 1_000_000_000.0});
}

pub const Options = struct {
    warmup_iters: u64 = 100,
    sample_size: u64 = 3000,
    bytes_per_op: usize = 0,
};

pub fn run(io: std.Io, allocator: Allocator, name: []const u8, function: anytype, args: anytype, options: Options) !Metrics {
    assertFunctionDef(function, args);

    // ref: https://pyk.sh/blog/2025-12-08-bench-fixing-constant-folding
    var runtimeArgs = createRuntimeArgs(function, args);
    std.mem.doNotOptimizeAway(&runtimeArgs);

    for (0..options.warmup_iters) |_| {
        try execute(function, runtimeArgs);
    }

    // We need to determine a batch_size such that the total execution time of the batch
    // is large enough to minimize timer resolution noise.
    // Target: 1ms (1,000,000 ns) per measurement block.
    const minSampleTimeNs = 1_000_000;
    var batch_size: u64 = 1;
    var ts = Timestamp.now(io, .awake);

    while (true) {
        ts = Timestamp.now(io, .awake);
        for (0..batch_size) |_| {
            try execute(function, runtimeArgs);
        }
        const duration: u64 = @intCast(ts.durationTo(Timestamp.now(io, .awake)).nanoseconds);

        if (duration >= minSampleTimeNs) break;

        // If the duration is 0 (too fast to measure) or small, scale up
        if (duration == 0) {
            batch_size *= 10;
        } else {
            const ratio = @as(f64, @floatFromInt(minSampleTimeNs)) / @as(f64, @floatFromInt(duration));
            const multiplier = @as(u64, @intFromFloat(std.math.ceil(ratio)));
            if (multiplier <= 1) {
                batch_size *= 2; // Fallback growth
            } else {
                batch_size *= multiplier;
            }
        }
    }

    const samples = try allocator.alloc(f64, options.sample_size);
    defer allocator.free(samples);

    for (0..options.sample_size) |i| {
        ts = Timestamp.now(io, .awake);
        for (0..batch_size) |_| {
            try execute(function, runtimeArgs);
        }
        const totalNs: u64 = @intCast(ts.durationTo(Timestamp.now(io, .awake)).nanoseconds);
        // Average time per operation for this batch
        samples[i] = @as(f64, @floatFromInt(totalNs)) / @as(f64, @floatFromInt(batch_size));
    }

    // Sort samples to find the median and process min/max
    sort.block(f64, samples, {}, sort.asc(f64));

    var sum: f64 = 0;
    for (samples) |s| sum += s;

    const mean = sum / @as(f64, @floatFromInt(options.sample_size));

    // Calculate Variance for Standard Deviation
    var sumSqDiff: f64 = 0;
    for (samples) |s| {
        const diff = s - mean;
        sumSqDiff += diff * diff;
    }
    const variance = sumSqDiff / @as(f64, @floatFromInt(options.sample_size));

    const median = samples[options.sample_size / 2];

    // Derive ops_sec from the median rather than the mean. On noisy hosts
    // (e.g. GitHub-hosted runners) a handful of slow samples drag the mean
    // upward and make the headline number jump run-to-run even when the
    // underlying work is unchanged. Median is robust to that tail.
    const ops_sec = if (median > 0) 1_000_000_000.0 / median else 0;

    // Calculate MB/s (Megabytes per second)
    // Formula: (Ops/Sec * Bytes/Op) / 1,000,000
    const mb_sec = if (options.bytes_per_op > 0)
        (ops_sec * @as(f64, @floatFromInt(options.bytes_per_op))) / 1_000_000.0
    else
        0;

    var metrics = Metrics{
        .name = name,
        .min_ns = samples[0],
        .max_ns = samples[samples.len - 1],
        .mean_ns = mean,
        .median_ns = median,
        .std_dev_ns = math.sqrt(variance),
        .samples = options.sample_size,
        .iterations = batch_size,
        .ops_sec = ops_sec,
        .mb_sec = mb_sec,
    };

    if (builtin.os.tag == .linux) {
        const hwEvents = [_]Event{ .cpu_cycles, .instructions, .cache_misses };
        const swEvents = [_]Event{ .page_faults, .context_switches };
        const HwGroup = Group(&hwEvents);
        const SwGroup = Group(&swEvents);

        // Counters just accumulate, so we don't need anywhere near `sample_size`
        // samples for an accurate per-op average — cap the perf pass so a
        // larger timing-pass `sample_size` doesn't multiply the bench runtime.
        const perf_samples = @min(options.sample_size, 1000);
        const totalOps = @as(f64, @floatFromInt(perf_samples * batch_size));

        // Hardware PMU events. These require a real PMU; CI runners and other
        // VMs typically don't expose one, so this attempt fails there.
        if (HwGroup.init()) |pg| {
            var group = pg;
            defer group.deinit();

            try group.enable();
            for (0..perf_samples) |_| {
                for (0..batch_size) |_| {
                    try execute(function, runtimeArgs);
                }
            }
            try group.disable();

            const m = try group.read();
            const avgCycles = @as(f64, @floatFromInt(m.cpu_cycles)) / totalOps;
            const avgInstr = @as(f64, @floatFromInt(m.instructions)) / totalOps;
            const avgMisses = @as(f64, @floatFromInt(m.cache_misses)) / totalOps;

            metrics.cycles = avgCycles;
            metrics.instructions = avgInstr;
            metrics.cache_misses = avgMisses;
            if (avgCycles > 0) {
                metrics.ipc = avgInstr / avgCycles;
            }
        } else |_| {
            // Hardware PMU unavailable — fall back to kernel-tracked software
            // events. These at least give *something* visible in CI (page
            // faults catch allocation churn, context switches catch noise).
            if (SwGroup.init()) |pg| {
                var group = pg;
                defer group.deinit();

                try group.enable();
                for (0..perf_samples) |_| {
                    for (0..batch_size) |_| {
                        try execute(function, runtimeArgs);
                    }
                }
                try group.disable();

                const m = try group.read();
                metrics.page_faults = @as(f64, @floatFromInt(m.page_faults)) / totalOps;
                metrics.context_switches = @as(f64, @floatFromInt(m.context_switches)) / totalOps;
            } else |_| {}
        }
    }

    return metrics;
}

inline fn execute(function: anytype, args: anytype) !void {
    const FnType = unwrapFnType(@TypeOf(function));
    const return_type = @typeInfo(FnType).@"fn".return_type.?;

    // Conditional execution based on whether the function can fail
    if (@typeInfo(return_type) == .error_union) {
        const result = try @call(.auto, function, args);
        std.mem.doNotOptimizeAway(result);
    } else {
        const result = @call(.auto, function, args);
        std.mem.doNotOptimizeAway(result);
    }
}

/// Returns the underlying Function type, unwrapping it if it is a pointer.
fn unwrapFnType(comptime T: type) type {
    if (@typeInfo(T) == .pointer) return @typeInfo(T).pointer.child;
    return T;
}

////////////////////////////////////////////////////////////////////////////////
// Function definition checker

fn assertFunctionDef(function: anytype, args: anytype) void {
    const ArgsType = @TypeOf(args);
    const argsInfo = @typeInfo(ArgsType);
    if (argsInfo != .@"struct" or !argsInfo.@"struct".is_tuple) {
        @compileError("Expected 'args' to be a tuple, found '" ++ @typeName(ArgsType) ++ "'");
    }

    const FnType = unwrapFnType(@TypeOf(function));
    if (@typeInfo(FnType) != .@"fn") {
        @compileError("Expected 'function' to be a function or function pointer, found '" ++ @typeName(@TypeOf(function)) ++ "'");
    }

    const params_len = @typeInfo(FnType).@"fn".params.len;
    const argsLen = @typeInfo(ArgsType).@"struct".fields.len;

    if (params_len != argsLen) {
        @compileError(std.fmt.comptimePrint(
            "Function expects {d} arguments, but args tuple has {d}",
            .{ params_len, argsLen },
        ));
    }
}

////////////////////////////////////////////////////////////////////////////////
// Runtime Arguments Helpers

/// Constructs the runtime argument tuple based on function parameters and input args.
fn createRuntimeArgs(function: anytype, args: anytype) RuntimeArgsType(@TypeOf(function), @TypeOf(args)) {
    const TupleType = RuntimeArgsType(@TypeOf(function), @TypeOf(args));
    var runtimeArgs: TupleType = undefined;

    // We only need the length here to iterate
    const params_len = comptime getFnParams(@TypeOf(function)).len;

    inline for (0..params_len) |i| {
        runtimeArgs[i] = args[i];
    }
    return runtimeArgs;
}

/// Computes the precise Tuple type required to hold the arguments.
fn RuntimeArgsType(comptime FnType: type, comptime ArgsType: type) type {
    const fnParams = getFnParams(FnType);
    const argsFields = @typeInfo(ArgsType).@"struct".fields;
    comptime var types: [fnParams.len]type = undefined;
    inline for (fnParams, 0..) |p, i| {
        if (p.type) |t| {
            types[i] = t;
        } else {
            types[i] = argsFields[i].type;
        }
    }
    return std.meta.Tuple(&types);
}

/// Helper to unwrap function pointers and retrieve parameter info
fn getFnParams(comptime FnType: type) []const std.builtin.Type.Fn.Param {
    return @typeInfo(unwrapFnType(FnType)).@"fn".params;
}
