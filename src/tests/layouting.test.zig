const std = @import("std");

const layout = @import("../layouting.zig").layout;
const utilities = @import("utilities.zig");
const forbear = @import("../root.zig");

test "wrapping does not cause stale heights for simple ancestry" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        var textNode: *forbear.Node = undefined;

        forbear.element(.{
            .textWrapping = .word,
            .width = .fit,
            .height = .fit,
            .direction = .topToBottom,
        })({
            forbear.element(.{
                .width = .{ .fixed = 100 },
                .height = .fit,
            })({
                forbear.text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore");
                textNode = forbear.getPreviousNode().?;
            });
        });

        const root = try layout();

        try std.testing.expectEqual(100, root.size[0]);
        try std.testing.expectEqual(100, textNode.size[0]);
        try std.testing.expectEqual(textNode.size[1], root.size[1]);

        try std.testing.expectEqual(100, root.children.nodes.items[0].size[0]);
        try std.testing.expectEqual(textNode.size[1], root.children.nodes.items[0].size[1]);
    });
}

test "wrapping does not cause stale heights for ancestors when there are siblings" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        var textNode: *forbear.Node = undefined;

        forbear.element(.{
            .textWrapping = .word,
            .width = .fit,
            .height = .fit,
            .direction = .topToBottom,
        })({
            forbear.element(.{
                .width = .{ .fixed = 100 },
                .height = .fit,
            })({
                forbear.text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore");
                textNode = forbear.getPreviousNode().?;
            });
            forbear.element(.{
                .height = .{ .fixed = 100 },
            })({});
        });

        const root = try layout();

        forbear.getPreviousNode().?.debugPrint(0);

        try std.testing.expectEqual(100, root.size[0]);
        try std.testing.expectEqual(100, textNode.size[0]);
        try std.testing.expectEqual(textNode.size[1] + 100, root.size[1]);

        try std.testing.expectEqual(100, root.children.nodes.items[0].size[0]);
        try std.testing.expectEqual(textNode.size[1] + 100, root.children.nodes.items[0].size[1]);
    });
}
