const std = @import("std");
const zbench = @import("zbench");
const forbear = @import("forbear");

var gArena: *std.heap.ArenaAllocator = undefined;
var gFont: *forbear.Font = undefined;

fn benchLayout(alloc: std.mem.Allocator) void {
    _ = alloc;
    _ = gArena.reset(.retain_capacity);
    const arena = gArena.allocator();

    const meta = forbear.FrameMeta{
        .arena = arena,
        .viewportSize = .{ 800, 600 },
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
        buildTree();
        _ = forbear.layout() catch unreachable;
    })) catch unreachable;
}

fn buildTree() void {
    forbear.element(.{ .width = .grow, .height = .grow, .direction = .vertical })({
        forbear.element(.{ .width = .grow, .height = .fit, .direction = .horizontal })({
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 60 } })({});
            forbear.element(.{ .width = .{ .fixed = 200 }, .height = .{ .fixed = 60 } })({});
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 60 } })({});
        });
        forbear.element(.{ .width = .grow, .height = .fit, .direction = .horizontal })({
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 80 } })({});
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 80 } })({});
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 80 } })({});
        });
        forbear.element(.{ .width = .grow, .height = .fit, .direction = .vertical })({
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 40 } })({});
            forbear.element(.{ .width = .{ .fixed = 600 }, .height = .{ .fixed = 40 } })({});
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 40 } })({});
            forbear.element(.{ .width = .{ .fixed = 400 }, .height = .{ .fixed = 40 } })({});
        });
        forbear.element(.{ .width = .grow, .height = .fit, .direction = .horizontal })({
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 100 } })({
                forbear.element(.{ .width = .grow, .height = .grow })({});
                forbear.element(.{ .width = .grow, .height = .grow })({});
            });
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 100 } })({
                forbear.element(.{ .width = .grow, .height = .{ .fixed = 30 } })({});
                forbear.element(.{ .width = .grow, .height = .{ .fixed = 30 } })({});
                forbear.element(.{ .width = .grow, .height = .{ .fixed = 30 } })({});
            });
        });
        forbear.element(.{ .width = .grow, .height = .fit, .direction = .horizontal })({
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 50 } })({});
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 50 } })({});
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 50 } })({});
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 50 } })({});
        });
    });
}

fn buildLargeTree() void {
    forbear.element(.{ .width = .grow, .height = .grow, .direction = .vertical })({
        // Header section
        forbear.element(.{ .width = .grow, .height = .fit, .direction = .horizontal })({
            forbear.element(.{ .width = .{ .fixed = 150 }, .height = .{ .fixed = 60 } })({});
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 60 }, .direction = .horizontal })({
                inline for (0..8) |_| {
                    forbear.element(.{ .width = .grow, .height = .grow })({});
                }
            });
            forbear.element(.{ .width = .{ .fixed = 100 }, .height = .{ .fixed = 60 } })({});
        });

        // Hero section with ratio
        forbear.element(.{ .width = .grow, .height = .{ .ratio = 0.4 } })({
            forbear.element(.{ .width = .fit, .height = .fit, .direction = .vertical })({
                forbear.element(.{ .width = .{ .fixed = 400 }, .height = .{ .fixed = 60 } })({});
                forbear.element(.{ .width = .{ .fixed = 300 }, .height = .{ .fixed = 40 } })({});
                forbear.element(.{ .width = .{ .fixed = 150 }, .height = .{ .fixed = 50 } })({});
            });
        });

        // Grid of cards (simulates product listing)
        inline for (0..4) |_| {
            forbear.element(.{ .width = .grow, .height = .fit, .direction = .horizontal })({
                inline for (0..4) |_| {
                    forbear.element(.{ .width = .grow, .height = .fit, .direction = .vertical })({
                        forbear.element(.{ .width = .grow, .height = .{ .ratio = 1.0 } })({});
                        forbear.element(.{ .width = .grow, .height = .{ .fixed = 24 } })({});
                        forbear.element(.{ .width = .grow, .height = .{ .fixed = 18 } })({});
                        forbear.element(.{ .width = .{ .fixed = 80 }, .height = .{ .fixed = 36 } })({});
                    });
                }
            });
        }

        // Footer with nested columns
        forbear.element(.{ .width = .grow, .height = .fit, .direction = .horizontal })({
            inline for (0..4) |_| {
                forbear.element(.{ .width = .grow, .height = .fit, .direction = .vertical })({
                    forbear.element(.{ .width = .grow, .height = .{ .fixed = 24 } })({});
                    inline for (0..6) |_| {
                        forbear.element(.{ .width = .grow, .height = .{ .fixed = 20 } })({});
                    }
                });
            }
        });
    });
}

fn buildHugeTree() void {
    forbear.element(.{ .width = .grow, .height = .grow, .direction = .vertical })({
        // 20 sections, each with nested grids
        inline for (0..20) |_| {
            forbear.element(.{ .width = .grow, .height = .fit, .direction = .vertical })({
                // Header row
                forbear.element(.{ .width = .grow, .height = .{ .fixed = 40 }, .direction = .horizontal })({
                    inline for (0..5) |_| {
                        forbear.element(.{ .width = .grow, .height = .grow })({});
                    }
                });
                // Grid of cards: 5 rows x 6 cols = 30 cards per section
                inline for (0..5) |_| {
                    forbear.element(.{ .width = .grow, .height = .fit, .direction = .horizontal })({
                        inline for (0..6) |_| {
                            forbear.element(.{ .width = .grow, .height = .fit, .direction = .vertical })({
                                forbear.element(.{ .width = .grow, .height = .{ .ratio = 0.75 } })({});
                                forbear.element(.{ .width = .grow, .height = .{ .fixed = 20 } })({});
                                forbear.element(.{ .width = .{ .fixed = 60 }, .height = .{ .fixed = 30 } })({});
                            });
                        }
                    });
                }
            });
        }
    });
}

fn benchHugeLayout(alloc: std.mem.Allocator) void {
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
        buildHugeTree();
        _ = forbear.layout() catch unreachable;
    })) catch unreachable;
}

fn benchLargeLayout(alloc: std.mem.Allocator) void {
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
        buildLargeTree();
        _ = forbear.layout() catch unreachable;
    })) catch unreachable;
}

test "bench layout" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    try forbear.registerFont("Inter", @embedFile("Inter.ttf"));
    gFont = try forbear.useFont("Inter");

    var arenaAlloc = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAlloc.deinit();
    gArena = &arenaAlloc;

    var buf: [4096]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&buf);
    var bench = zbench.Benchmark.init(std.testing.allocator, .{});
    defer bench.deinit();
    try bench.add("layout() 27 nodes", benchLayout, .{});
    try bench.add("layout() 135 nodes", benchLargeLayout, .{});
    try bench.add("layout() 2641 nodes", benchHugeLayout, .{});
    try bench.run(&file_writer.interface);
    try file_writer.interface.flush();
}
