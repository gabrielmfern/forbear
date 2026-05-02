const std = @import("std");
const zbench = @import("zbench");
const forbear = @import("forbear");

var gArena: *std.heap.ArenaAllocator = undefined;
var gFont: *forbear.Font = undefined;

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

fn benchLayoutGeneric(comptime nodeCount: usize) fn (std.mem.Allocator) void {
    return struct {
        fn run(alloc: std.mem.Allocator) void {
            _ = alloc;
            _ = gArena.reset(.retain_capacity);
            const arena = gArena.allocator();

            const meta = forbear.FrameMeta{
                .arena = arena,
                .viewportSize = .{ 1920, 1080 },
                .baseStyle = .{
                    .font = gFont,
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
    forbear.component(.{ .text = tag })({
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
    forbear.component(.{ .text = tag })({
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
    forbear.component(.{ .text = tag })({
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

fn buildStateTree() void {
    forbear.component(.{ .text = "StateBenchApp" })({
        _ = forbear.useState(u32, 0);
        _ = forbear.useState(f32, 0.0);
        _ = forbear.useState(bool, false);
        _ = forbear.useState(u64, 0);

        forbear.element(.{ .style = .{
            .width = .{ .grow = 1.0 },
            .height = .{ .grow = 1.0 },
            .direction = .vertical,
        } })({
            _ = forbear.useState(u32, 0);
            _ = forbear.useState(f32, 0.0);
            _ = forbear.useState(bool, false);
            _ = forbear.useState(u64, 0);

            inline for (0..5) |i| {
                StateSection("s" ++ std.fmt.comptimePrint("{d}", .{i}));
            }
        });
    });
}

test "bench layout" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    try forbear.registerFont("Inter", @embedFile("Inter.ttf"));
    gFont = try forbear.useFont("Inter");

    var arenaAlloc = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAlloc.deinit();
    gArena = &arenaAlloc;

    var bench = zbench.Benchmark.init(std.testing.allocator, .{});
    defer bench.deinit();

    try bench.add("layout() 27 nodes", benchLayoutGeneric(27), .{});
    try bench.add("layout() 135 nodes", benchLayoutGeneric(135), .{});
    try bench.add("layout() 500 nodes", benchLayoutGeneric(500), .{});
    try bench.add("layout() 1000 nodes", benchLayoutGeneric(1000), .{});
    try bench.add("layout() 2641 nodes", benchLayoutGeneric(2641), .{});
    try bench.add("layout() 5000 nodes", benchLayoutGeneric(5000), .{});
    try bench.add("layout() 10000 nodes", benchLayoutGeneric(10000), .{});

    try bench.run(std.testing.io, std.Io.File.stdout());
}

fn buildUseStateTree(comptime stateCount: usize) void {
    @setEvalBranchQuota(1_000_000);
    forbear.component(.{
        .text = "UseStateBenchApp_" ++ std.fmt.comptimePrint("{d}", .{stateCount}),
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
                    .text = "UseStateTail_" ++ std.fmt.comptimePrint("{d}", .{stateCount}),
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
        fn run(alloc: std.mem.Allocator) void {
            _ = alloc;
            _ = gArena.reset(.retain_capacity);
            const arena = gArena.allocator();

            const meta = forbear.FrameMeta{
                .arena = arena,
                .viewportSize = .{ 1920, 1080 },
                .baseStyle = .{
                    .font = gFont,
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

test "bench useState" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    try forbear.registerFont("Inter", @embedFile("Inter.ttf"));
    gFont = try forbear.useFont("Inter");

    var arenaAlloc = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAlloc.deinit();
    gArena = &arenaAlloc;

    var bench = zbench.Benchmark.init(std.testing.allocator, .{});
    defer bench.deinit();

    try bench.add("useState() 10 states", UseStateBenchmark(10), .{ .track_allocations = true });
    try bench.add("useState() 50 states", UseStateBenchmark(50), .{ .track_allocations = true });
    try bench.add("useState() 100 states", UseStateBenchmark(100), .{ .track_allocations = true });
    try bench.add("useState() 250 states", UseStateBenchmark(250), .{ .track_allocations = true });
    try bench.add("useState() 500 states", UseStateBenchmark(500), .{ .track_allocations = true });
    try bench.add("useState() 1000 states", UseStateBenchmark(1000), .{ .track_allocations = true });
    try bench.add("useState() 2000 states", UseStateBenchmark(2000), .{ .track_allocations = true });
    try bench.add("useState() 5000 states", UseStateBenchmark(5000), .{ .track_allocations = true });

    try bench.run(std.testing.io, std.Io.File.stdout());
}
