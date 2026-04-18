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
        .dpi = .{ 72.0, 72.0 },
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
            forbear.element(.{ .width = .{ .percentage = 0.33 }, .height = .{ .fixed = 80 } })({});
            forbear.element(.{ .width = .{ .percentage = 0.33 }, .height = .{ .fixed = 80 } })({});
            forbear.element(.{ .width = .{ .percentage = 0.33 }, .height = .{ .fixed = 80 } })({});
        });
        forbear.element(.{ .width = .grow, .height = .fit, .direction = .vertical })({
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 40 } })({});
            forbear.element(.{ .width = .{ .fixed = 600 }, .height = .{ .fixed = 40 } })({});
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 40 } })({});
            forbear.element(.{ .width = .{ .fixed = 400 }, .height = .{ .fixed = 40 } })({});
        });
        forbear.element(.{ .width = .grow, .height = .fit, .direction = .horizontal })({
            forbear.element(.{ .width = .grow, .height = .{ .fixed = 100 } })({
                forbear.element(.{ .width = .{ .percentage = 0.5 }, .height = .grow })({});
                forbear.element(.{ .width = .{ .percentage = 0.5 }, .height = .grow })({});
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
    try bench.add("layout()", benchLayout, .{});
    try bench.run(&file_writer.interface);
    try file_writer.interface.flush();
}
