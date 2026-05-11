const std = @import("std");
const linux = std.os.linux;
const Type = std.builtin.Type;
const PERF_EVENT_IOC_RESET = linux.PERF.EVENT_IOC.RESET;
const PERF_EVENT_IOC_ENABLE = linux.PERF.EVENT_IOC.ENABLE;
const PERF_EVENT_IOC_DISABLE = linux.PERF.EVENT_IOC.DISABLE;
const Writer = std.Io.Writer;
const math = std.math;
const sort = std.sort;
const Timer = std.time.Timer;
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");

const forbear = @import("forbear");

// Builds a layout-only tree of exactly `nodeCount` element nodes (root
// counts) by packing into uniformly shaped sections / rows / leaves and
// distributing any remainder as a partial section + partial row.
//
// Per-section: 1 wrapper + R rows × (1 + L leaves) = 1 + R*(1+L)
// With R=5, L=6: row = 7 nodes, section = 36 nodes.
fn buildLayoutTree(comptime nodeCount: usize) void {
    @setEvalBranchQuota(1_000_000);

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
        inline for (0..fullSections) |_| {
            forbear.element(.{ .style = .{
                .width = .{ .grow = 1.0 },
                .height = .fit,
                .direction = .vertical,
            } })({
                inline for (0..R) |_| {
                    forbear.element(.{ .style = .{
                        .width = .{ .grow = 1.0 },
                        .height = .fit,
                        .direction = .horizontal,
                    } })({
                        inline for (0..L) |_| {
                            forbear.element(.{ .style = .{
                                .width = .{ .grow = 1.0 },
                                .height = .{ .fixed = 30 },
                            } })({});
                        }
                    });
                }
            });
        }

        if (hasPartialSection) {
            forbear.element(.{ .style = .{
                .width = .{ .grow = 1.0 },
                .height = .fit,
                .direction = .vertical,
            } })({
                inline for (0..partialRows) |_| {
                    forbear.element(.{ .style = .{
                        .width = .{ .grow = 1.0 },
                        .height = .fit,
                        .direction = .horizontal,
                    } })({
                        inline for (0..L) |_| {
                            forbear.element(.{ .style = .{
                                .width = .{ .grow = 1.0 },
                                .height = .{ .fixed = 30 },
                            } })({});
                        }
                    });
                }
                if (hasPartialRow) {
                    forbear.element(.{ .style = .{
                        .width = .{ .grow = 1.0 },
                        .height = .fit,
                        .direction = .horizontal,
                    } })({
                        inline for (0..tailLeavesInRow) |_| {
                            forbear.element(.{ .style = .{
                                .width = .{ .grow = 1.0 },
                                .height = .{ .fixed = 30 },
                            } })({});
                        }
                    });
                }
            });
        }

        inline for (0..strayLeaves) |_| {
            forbear.element(.{ .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .fixed = 30 },
            } })({});
        }
    });
}

fn LayoutBenchmark(comptime nodeCount: usize) fn (std.mem.Allocator) void {
    return struct {
        fn run(allocator: std.mem.Allocator) void {
            var arena = std.heap.ArenaAllocator.init(allocator);
            defer arena.deinit();
            forbear.init(allocator, std.testing.io, undefined) catch unreachable;
            defer forbear.deinit();

            forbear.registerFont("Inter", @embedFile("Inter.ttf")) catch unreachable;

            const meta = forbear.FrameMeta{
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
            };

            (forbear.frame(meta)({
                buildLayoutTree(nodeCount);
                _ = forbear.layout() catch unreachable;
            })) catch unreachable;
        }
    }.run;
}

test "bench layout" {}

// ~1000 useState calls spread across mixed component+element scopes at
// depths 0..7. Each leaf component contains both an inner element scope and
// is itself nested several components deep.
//
// Per-scope state counts (component scope + immediate element scope):
//   App     :  4 + 4 =  8
//   Section :  4 + 4 =  8  ×  5             =   40
//   Panel   :  4 + 4 =  8  ×  5×4           =  160
//   Leaf    :  4 + 4 =  8  ×  5×4×5         =  800
//   total                                   = 1008
fn StateLeaf(comptime tag: []const u8) void {
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

fn StatePanel(comptime tag: []const u8) void {
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

            inline for (0..5) |i| {
                StateLeaf(tag ++ "_l" ++ std.fmt.comptimePrint("{d}", .{i}));
            }
        });
    });
}

fn StateSection(comptime tag: []const u8) void {
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

            inline for (0..4) |i| {
                StatePanel(tag ++ "_p" ++ std.fmt.comptimePrint("{d}", .{i}));
            }
        });
    });
}

fn buildUseStateTree(comptime stateCount: usize) void {
    @setEvalBranchQuota(1_000_000);
    forbear.component(.{
        .key = "UseStateBenchApp_" ++ std.fmt.comptimePrint("{d}", .{stateCount}),
    })({
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
            const leavesPerPanel = 5;
            const panelsPerSection = 4;

            const perLeaf: usize = 8;
            const perPanel: usize = leavesPerPanel * perLeaf;
            const perSection: usize = panelsPerSection * perPanel;

            const sections = stateCount / perSection;
            const afterSections = stateCount - sections * perSection;
            const fullPanels = afterSections / perPanel;
            const afterPanels = afterSections - fullPanels * perPanel;
            const fullLeaves = afterPanels / perLeaf;
            const tailLeafStates = afterPanels - fullLeaves * perLeaf;

            inline for (0..sections) |si| {
                StateSection("us_" ++ std.fmt.comptimePrint("{d}_s{d}", .{ stateCount, si }));
            }

            if (fullPanels > 0 or fullLeaves > 0 or tailLeafStates > 0) {
                forbear.component(.{
                    .key = "UseStateTail_" ++ std.fmt.comptimePrint("{d}", .{stateCount}),
                })({
                    forbear.element(.{ .style = .{
                        .width = .{ .grow = 1.0 },
                        .height = .fit,
                        .direction = .vertical,
                    } })({
                        inline for (0..fullPanels) |pi| {
                            StatePanel("us_" ++ std.fmt.comptimePrint("{d}_tp{d}", .{ stateCount, pi }));
                        }
                        inline for (0..fullLeaves) |li| {
                            StateLeaf("us_" ++ std.fmt.comptimePrint("{d}_tl{d}", .{ stateCount, li }));
                        }
                        inline for (0..tailLeafStates) |_| {
                            _ = forbear.useState(u32, 0);
                        }
                    });
                });
            }
        });
    });
}

fn UseStateBenchmark(comptime stateCount: usize) fn (std.mem.Allocator) void {
    return struct {
        fn run(allocator: std.mem.Allocator) void {
            var arena = std.heap.ArenaAllocator.init(allocator);
            defer arena.deinit();
            forbear.init(allocator, std.testing.io, undefined) catch unreachable;
            defer forbear.deinit();

            forbear.registerFont("Inter", @embedFile("Inter.ttf")) catch unreachable;

            const meta = forbear.FrameMeta{
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
            };

            (forbear.frame(meta)({
                buildUseStateTree(stateCount);
            })) catch unreachable;
        }
    }.run;
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();

    var layoutBench = zbench.Benchmark.init(allocator, .{});
    defer layoutBench.deinit();

    try layoutBench.add("layout() 27 nodes", LayoutBenchmark(27), .{});
    try layoutBench.add("layout() 135 nodes", LayoutBenchmark(135), .{});
    try layoutBench.add("layout() 500 nodes", LayoutBenchmark(500), .{});
    try layoutBench.add("layout() 1000 nodes", LayoutBenchmark(1000), .{});
    try layoutBench.add("layout() 2641 nodes", LayoutBenchmark(2641), .{});
    try layoutBench.add("layout() 5000 nodes", LayoutBenchmark(5000), .{});
    try layoutBench.add("layout() 10000 nodes", LayoutBenchmark(10000), .{});

    try layoutBench.run(init.io, std.Io.File.stdout());

    var useStateBench = zbench.Benchmark.init(allocator, .{});
    defer useStateBench.deinit();

    try useStateBench.add("useState() 10 states", UseStateBenchmark(10), .{ .track_allocations = true });
    try useStateBench.add("useState() 50 states", UseStateBenchmark(50), .{ .track_allocations = true });
    try useStateBench.add("useState() 100 states", UseStateBenchmark(100), .{ .track_allocations = true });
    try useStateBench.add("useState() 250 states", UseStateBenchmark(250), .{ .track_allocations = true });
    try useStateBench.add("useState() 500 states", UseStateBenchmark(500), .{ .track_allocations = true });
    try useStateBench.add("useState() 1000 states", UseStateBenchmark(1000), .{ .track_allocations = true });
    try useStateBench.add("useState() 2000 states", UseStateBenchmark(2000), .{ .track_allocations = true });
    try useStateBench.add("useState() 5000 states", UseStateBenchmark(5000), .{ .track_allocations = true });

    try useStateBench.run(init.io, std.Io.File.stdout());
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
};

// Bits for perf_event_attr.read_format
const PERF_FORMAT_TOTAL_TIME_ENABLED = 1 << 0;
const PERF_FORMAT_TOTAL_TIME_RUNNING = 1 << 1;
const PERF_FORMAT_ID = 1 << 2;
const PERF_FORMAT_GROUP = 1 << 3;

// Various ioctls act on perf_event_open() file descriptors:
const PERF_EVENT_IOC_ID = linux.IOCTL.IOR('$', 7, u64);
/// The hardware events supported by the kernel for performance monitoring.
/// These map directly to `perf_event_attr.config` values.
const Event = enum {
    cpu_cycles,
    instructions,
    cache_misses,
    branch_misses,
    bus_cycles,

    /// Converts the enum into the specific kernel configuration integer
    /// required by the `perf_event_open` syscall.
    fn toConfig(self: Event) u64 {
        return switch (self) {
            .cpu_cycles => @intFromEnum(linux.PERF.COUNT.HW.CPU_CYCLES),
            .instructions => @intFromEnum(linux.PERF.COUNT.HW.INSTRUCTIONS),
            .cache_misses => @intFromEnum(linux.PERF.COUNT.HW.CACHE_MISSES),
            .branch_misses => @intFromEnum(linux.PERF.COUNT.HW.BRANCH_MISSES),
            .bus_cycles => @intFromEnum(linux.PERF.COUNT.HW.BUS_CYCLES),
        };
    }
};

fn GroupReadOutputType(comptime events: []const Event) type {
    var field_names: [events.len][]const u8 = undefined;
    var field_types: [events.len]type = undefined;
    var field_attrs: [events.len]Type.StructField.Attributes = undefined;
    for (events, 0..) |event, index| {
        field_names[index] = @tagName(event);
        field_types[index] = u64;
        field_attrs[index] = .{
            .@"comptime" = false,
            .@"align" = @alignOf(u64),
            .default_value_ptr = null,
        };
    }
    return @Struct(
        .auto,
        null,
        &field_names,
        &field_types,
        &field_attrs,
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
            var group_fd = @as(i32, -1);
            const event_config = events[0].toConfig();
            self.event_fds[0] = try perf_open_group(group_fd, event_config);
            self.event_ids[0] = try ioctl_get_id(self.event_fds[0]);
            group_fd = self.event_fds[0];

            // Siblings
            if (events.len > 1) {
                for (events[1..], 1..) |event, i| {
                    const config = event.toConfig();
                    self.event_fds[i] = try perf_open_group(group_fd, config);
                    self.event_ids[i] = try ioctl_get_id(self.event_fds[i]);
                }
            }
            return self;
        }

        /// Closes all file descriptors associated with this event group.
        /// This invalidates the group object.
        fn deinit(self: *Self) void {
            for (self.event_fds, 0..) |event_fd, index| {
                if (event_fd != -1) {
                    _ = linux.close(event_fd);
                }
                self.event_fds[index] = -1;
                self.event_ids[index] = 0;
            }
        }

        /// Resets and enables the event group. Counting begins immediately.
        fn enable(self: *Self) Error!void {
            const group_fd = self.event_fds[0];
            if (group_fd == -1) return error.BadGroup;
            try ioctl_reset_group(group_fd);
            try ioctl_enable_group(group_fd);
        }

        /// Disables the event group. Counting stops immediately.
        fn disable(self: *Self) Error!void {
            const group_fd = self.event_fds[0];
            if (group_fd == -1) return error.BadGroup;
            try ioctl_disable_group(group_fd);
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
            const scale_needed = data.time_running < data.time_enabled;
            const scale_factor = if (scale_needed)
                @as(f64, @floatFromInt(data.time_enabled)) / @as(f64, @floatFromInt(data.time_running))
            else
                1.0;

            for (data.values) |item| {
                var val = item.value;

                if (scale_needed) {
                    val = @as(u64, @intFromFloat(@as(f64, @floatFromInt(val)) * scale_factor));
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
        fn perf_open_group(group_fd: linux.fd_t, config: u64) Error!linux.fd_t {
            var attr = std.mem.zeroes(linux.perf_event_attr);
            attr.type = linux.PERF.TYPE.HARDWARE;
            attr.config = config;

            // Enable grouping and ID tracking
            attr.read_format = PERF_FORMAT_GROUP |
                PERF_FORMAT_TOTAL_TIME_ENABLED |
                PERF_FORMAT_TOTAL_TIME_RUNNING |
                PERF_FORMAT_ID;

            attr.flags.disabled = (group_fd == -1); // Only leader starts disabled
            attr.flags.inherit = true;
            attr.flags.exclude_kernel = true;
            attr.flags.exclude_hv = true;

            // ref: `man 2 perf_event_open`
            // pid=0 (current process), cpu=-1 (any cpu), flags=0
            const pid = 0;
            const cpu = -1;
            const flags = 0;

            const rc = linux.perf_event_open(&attr, pid, cpu, group_fd, flags);
            if (linux.errno(rc) != .SUCCESS) return error.OpenGroupFailed;
            return @intCast(rc);
        }

        // ref: `man 2 perf_event_open` then search for `PERF_EVENT_IOC_ID`
        fn ioctl_get_id(fd: linux.fd_t) Error!u64 {
            var id: u64 = 0;
            const rc = linux.ioctl(fd, PERF_EVENT_IOC_ID, @intFromPtr(&id));
            if (linux.errno(rc) != .SUCCESS) return error.GetIdFailed;
            return id;
        }

        // ref: `man 2 perf_event_open` then search for `PERF_EVENT_IOC_RESET`
        fn ioctl_reset_group(fd: linux.fd_t) Error!void {
            const rc = linux.ioctl(fd, PERF_EVENT_IOC_RESET, 0);
            if (linux.errno(rc) != .SUCCESS) return error.ResetGroupFailed;
        }

        // ref: `man 2 perf_event_open` then search for `PERF_EVENT_IOC_ENABLE`
        fn ioctl_enable_group(fd: linux.fd_t) Error!void {
            const rc = linux.ioctl(fd, PERF_EVENT_IOC_ENABLE, 0);
            if (linux.errno(rc) != .SUCCESS) return error.EnableGroupFailed;
        }

        // ref: `man 2 perf_event_open` then search for `PERF_EVENT_IOC_DISABLE`
        fn ioctl_disable_group(fd: linux.fd_t) Error!void {
            const rc = linux.ioctl(fd, PERF_EVENT_IOC_DISABLE, 0);
            if (linux.errno(rc) != .SUCCESS) return error.DisableGroupFailed;
        }
    };
}

const BenchmarkOptions = struct {};

const Column = struct {
    title: []const u8,
    width: usize,
    align_right: bool,
    active: bool,
};

fn print(options: Options) !void {
    var buffer: [64 * 1024]u8 = undefined;
    var w: Writer = .fixed(&buffer);
    try write(&w, options);
    std.debug.print("{s}", .{w.buffered()});
}

fn write(w: *Writer, options: Options) !void {
    if (options.metrics.len == 0) return;

    // Initialize columns with Header names and default visibility
    var col_name = Column{ .title = "Benchmark", .width = 0, .align_right = false, .active = true };
    var col_time = Column{ .title = "Time", .width = 0, .align_right = true, .active = true };
    var col_speedup = Column{ .title = "Speedup", .width = 0, .align_right = true, .active = false };
    var col_iter = Column{ .title = "Iterations", .width = 0, .align_right = true, .active = true };

    var col_bytes = Column{ .title = "Bytes/s", .width = 0, .align_right = true, .active = false };
    var col_ops = Column{ .title = "Ops/s", .width = 0, .align_right = true, .active = false };
    var col_cycles = Column{ .title = "Cycles", .width = 0, .align_right = true, .active = false };
    var col_instr = Column{ .title = "Instructions", .width = 0, .align_right = true, .active = false };
    var col_ipc = Column{ .title = "IPC", .width = 0, .align_right = true, .active = false };
    var col_miss = Column{ .title = "Cache Misses", .width = 0, .align_right = true, .active = false };

    // We must format every number to a temporary buffer to know its length.
    var buf: [64]u8 = undefined;

    // Activate Rel column if baseline_index is valid
    if (options.baseline_index) |idx| {
        if (idx < options.metrics.len) {
            col_speedup.active = true;
        }
    }

    // Check headers first
    col_name.width = col_name.title.len;
    col_time.width = col_time.title.len;
    col_speedup.width = col_speedup.title.len;
    // col_cpu.width = col_cpu.title.len;
    col_iter.width = col_iter.title.len;
    col_bytes.width = col_bytes.title.len;
    col_ops.width = col_ops.title.len;
    col_cycles.width = col_cycles.title.len;
    col_instr.width = col_instr.title.len;
    col_ipc.width = col_ipc.title.len;
    col_miss.width = col_miss.title.len;

    for (options.metrics) |m| {
        // Name: +2 for backticks
        col_name.width = @max(col_name.width, m.name.len + 2);

        // Time
        const s_time = try fmtTime(&buf, m.mean_ns);
        col_time.width = @max(col_time.width, s_time.len);

        // Relative
        if (col_speedup.active) {
            const base = options.metrics[options.baseline_index.?];
            // Avoid division by zero
            const ratio = if (m.mean_ns > 0) base.mean_ns / m.mean_ns else 0;
            const s_rel = try std.fmt.bufPrint(&buf, "{d:.2}x", .{ratio});
            col_speedup.width = @max(col_speedup.width, s_rel.len);
        }

        // Iterations
        const s_iter = try std.fmt.bufPrint(&buf, "{d}", .{m.samples});
        col_iter.width = @max(col_iter.width, s_iter.len);

        // Optional Columns (Enable & Measure)
        if (m.mb_sec > 0.001) {
            col_bytes.active = true;
            const s = try fmtBytes(&buf, m.mb_sec);
            col_bytes.width = @max(col_bytes.width, s.len);
        }
        if (m.ops_sec > 0.001 and m.mb_sec <= 0.001) {
            col_ops.active = true;
            const s_val = try fmtMetric(&buf, m.ops_sec);
            // We append "/s" in the final output, so add 2 to length
            col_ops.width = @max(col_ops.width, s_val.len + 2);
        }
        if (m.cycles) |v| {
            col_cycles.active = true;
            const s = try fmtMetric(&buf, v);
            col_cycles.width = @max(col_cycles.width, s.len);
        }
        if (m.instructions) |v| {
            col_instr.active = true;
            const s = try fmtMetric(&buf, v);
            col_instr.width = @max(col_instr.width, s.len);
        }
        if (m.ipc) |v| {
            col_ipc.active = true;
            const s = try std.fmt.bufPrint(&buf, "{d:.2}", .{v});
            col_ipc.width = @max(col_ipc.width, s.len);
        }
        if (m.cache_misses) |v| {
            col_miss.active = true;
            const s = try fmtMetric(&buf, v);
            col_miss.width = @max(col_miss.width, s.len);
        }
    }

    // Header Row
    try w.writeAll("| ");
    try printCell(w, col_name.title, col_name);
    try printCell(w, col_time.title, col_time);
    if (col_speedup.active) try printCell(w, col_speedup.title, col_speedup);
    try printCell(w, col_iter.title, col_iter);
    if (col_bytes.active) try printCell(w, col_bytes.title, col_bytes);
    if (col_ops.active) try printCell(w, col_ops.title, col_ops);
    if (col_cycles.active) try printCell(w, col_cycles.title, col_cycles);
    if (col_instr.active) try printCell(w, col_instr.title, col_instr);
    if (col_ipc.active) try printCell(w, col_ipc.title, col_ipc);
    if (col_miss.active) try printCell(w, col_miss.title, col_miss);
    try w.writeAll("\n");

    // Separator Row
    try w.writeAll("| ");
    try printDivider(w, col_name);
    try printDivider(w, col_time);
    if (col_speedup.active) try printDivider(w, col_speedup);
    try printDivider(w, col_iter);
    if (col_bytes.active) try printDivider(w, col_bytes);
    if (col_ops.active) try printDivider(w, col_ops);
    if (col_cycles.active) try printDivider(w, col_cycles);
    if (col_instr.active) try printDivider(w, col_instr);
    if (col_ipc.active) try printDivider(w, col_ipc);
    if (col_miss.active) try printDivider(w, col_miss);
    try w.writeAll("\n");

    // Data Rows
    for (options.metrics) |m| {
        try w.writeAll("| ");

        // Name
        const name_s = try std.fmt.bufPrint(&buf, "`{s}`", .{m.name});
        try printCell(w, name_s, col_name);

        // Time
        try printCell(w, try fmtTime(&buf, m.mean_ns), col_time);

        // Relative
        if (col_speedup.active) {
            const base = options.metrics[options.baseline_index.?];
            const ratio = if (m.mean_ns > 0) base.mean_ns / m.mean_ns else 0;
            const s_rel = try std.fmt.bufPrint(&buf, "{d:.2}x", .{ratio});
            try printCell(w, s_rel, col_speedup);
        }

        // Iterations
        const iter_s = try std.fmt.bufPrint(&buf, "{d}", .{m.iterations});
        try printCell(w, iter_s, col_iter);

        // Optional
        if (col_bytes.active) {
            if (m.mb_sec > 0.001) try printCell(w, try fmtBytes(&buf, m.mb_sec), col_bytes) else try printCell(w, "-", col_bytes);
        }
        if (col_ops.active) {
            if (m.ops_sec > 0.001) {
                // Must manually construct the string with suffix to match width measurement
                const val = try fmtMetric(&buf, m.ops_sec);
                var buf2: [64]u8 = undefined;
                const final = try std.fmt.bufPrint(&buf2, "{s}/s", .{val});
                try printCell(w, final, col_ops);
            } else try printCell(w, "-", col_ops);
        }
        if (col_cycles.active) {
            if (m.cycles) |v| try printCell(w, try fmtMetric(&buf, v), col_cycles) else try printCell(w, "-", col_cycles);
        }
        if (col_instr.active) {
            if (m.instructions) |v| try printCell(w, try fmtMetric(&buf, v), col_instr) else try printCell(w, "-", col_instr);
        }
        if (col_ipc.active) {
            if (m.ipc) |v| {
                const s = try std.fmt.bufPrint(&buf, "{d:.2}", .{v});
                try printCell(w, s, col_ipc);
            } else try printCell(w, "-", col_ipc);
        }
        if (col_miss.active) {
            if (m.cache_misses) |v| try printCell(w, try fmtMetric(&buf, v), col_miss) else try printCell(w, "-", col_miss);
        }

        try w.writeAll("\n");
    }
}

fn printCell(w: *Writer, text: []const u8, col: Column) !void {
    const pad_len = if (col.width > text.len) col.width - text.len else 0;

    if (col.align_right) {
        _ = try w.splatByte(' ', pad_len);
        try w.writeAll(text);
    } else {
        try w.writeAll(text);
        _ = try w.splatByte(' ', pad_len);
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
    sample_size: u64 = 1000,
    bytes_per_op: usize = 0,
};

pub fn run(allocator: Allocator, name: []const u8, function: anytype, args: anytype, options: Options) !Metrics {
    assertFunctionDef(function, args);

    // ref: https://pyk.sh/blog/2025-12-08-bench-fixing-constant-folding
    var runtime_args = createRuntimeArgs(function, args);
    std.mem.doNotOptimizeAway(&runtime_args);

    for (0..options.warmup_iters) |_| {
        try execute(function, runtime_args);
    }

    // We need to determine a batch_size such that the total execution time of the batch
    // is large enough to minimize timer resolution noise.
    // Target: 1ms (1,000,000 ns) per measurement block.
    const min_sample_time_ns = 1_000_000;
    var batch_size: u64 = 1;
    var timer = try Timer.start();

    while (true) {
        timer.reset();
        for (0..batch_size) |_| {
            try execute(function, runtime_args);
        }
        const duration = timer.read();

        if (duration >= min_sample_time_ns) break;

        // If the duration is 0 (too fast to measure) or small, scale up
        if (duration == 0) {
            batch_size *= 10;
        } else {
            const ratio = @as(f64, @floatFromInt(min_sample_time_ns)) / @as(f64, @floatFromInt(duration));
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
        timer.reset();
        for (0..batch_size) |_| {
            try execute(function, runtime_args);
        }
        const total_ns = timer.read();
        // Average time per operation for this batch
        samples[i] = @as(f64, @floatFromInt(total_ns)) / @as(f64, @floatFromInt(batch_size));
    }

    // Sort samples to find the median and process min/max
    sort.block(f64, samples, {}, sort.asc(f64));

    var sum: f64 = 0;
    for (samples) |s| sum += s;

    const mean = sum / @as(f64, @floatFromInt(options.sample_size));

    // Calculate Variance for Standard Deviation
    var sum_sq_diff: f64 = 0;
    for (samples) |s| {
        const diff = s - mean;
        sum_sq_diff += diff * diff;
    }
    const variance = sum_sq_diff / @as(f64, @floatFromInt(options.sample_size));

    // Calculate Operations Per Second
    const ops_sec = if (mean > 0) 1_000_000_000.0 / mean else 0;

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
        .median_ns = samples[options.sample_size / 2],
        .std_dev_ns = math.sqrt(variance),
        .samples = options.sample_size,
        .iterations = batch_size,
        .ops_sec = ops_sec,
        .mb_sec = mb_sec,
    };

    if (builtin.os.tag == .linux) {
        const events = [_]Event{ .cpu_cycles, .instructions, .cache_misses };
        const perf_group = Group(&events);
        if (perf_group.init()) |pg| {
            var group = pg;
            defer group.deinit();

            try group.enable();
            for (0..options.sample_size) |_| {
                for (0..batch_size) |_| {
                    try execute(function, runtime_args);
                }
            }
            try group.disable();

            const m = try group.read();
            const total_ops = @as(f64, @floatFromInt(options.sample_size * batch_size));
            const avg_cycles = @as(f64, @floatFromInt(m.cpu_cycles)) / total_ops;
            const avg_instr = @as(f64, @floatFromInt(m.instructions)) / total_ops;
            const avg_misses = @as(f64, @floatFromInt(m.cache_misses)) / total_ops;

            metrics.cycles = avg_cycles;
            metrics.instructions = avg_instr;
            metrics.cache_misses = avg_misses;
            if (avg_cycles > 0) {
                metrics.ipc = avg_instr / avg_cycles;
            }
        } else |_| {} // skip counter if we can't open it
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
    const args_info = @typeInfo(ArgsType);
    if (args_info != .@"struct" or !args_info.@"struct".is_tuple) {
        @compileError("Expected 'args' to be a tuple, found '" ++ @typeName(ArgsType) ++ "'");
    }

    const FnType = unwrapFnType(@TypeOf(function));
    if (@typeInfo(FnType) != .@"fn") {
        @compileError("Expected 'function' to be a function or function pointer, found '" ++ @typeName(@TypeOf(function)) ++ "'");
    }

    const params_len = @typeInfo(FnType).@"fn".params.len;
    const args_len = @typeInfo(ArgsType).@"struct".fields.len;

    if (params_len != args_len) {
        @compileError(std.fmt.comptimePrint(
            "Function expects {d} arguments, but args tuple has {d}",
            .{ params_len, args_len },
        ));
    }
}

////////////////////////////////////////////////////////////////////////////////
// Runtime Arguments Helpers

/// Constructs the runtime argument tuple based on function parameters and input args.
fn createRuntimeArgs(function: anytype, args: anytype) RuntimeArgsType(@TypeOf(function), @TypeOf(args)) {
    const TupleType = RuntimeArgsType(@TypeOf(function), @TypeOf(args));
    var runtime_args: TupleType = undefined;

    // We only need the length here to iterate
    const fn_params = getFnParams(@TypeOf(function));

    inline for (0..fn_params.len) |i| {
        runtime_args[i] = args[i];
    }
    return runtime_args;
}

/// Computes the precise Tuple type required to hold the arguments.
fn RuntimeArgsType(comptime FnType: type, comptime ArgsType: type) type {
    const fn_params = getFnParams(FnType);
    const args_fields = @typeInfo(ArgsType).@"struct".fields;
    comptime var types: [fn_params.len]type = undefined;
    inline for (fn_params, 0..) |p, i| {
        if (p.type) |t| {
            types[i] = t;
        } else {
            types[i] = args_fields[i].type;
        }
    }
    return std.meta.Tuple(&types);
}

/// Helper to unwrap function pointers and retrieve parameter info
fn getFnParams(comptime FnType: type) []const std.builtin.Type.Fn.Param {
    return @typeInfo(unwrapFnType(FnType)).@"fn".params;
}
