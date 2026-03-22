const std = @import("std");

const layout = @import("../layouting.zig").layout;
const utilities = @import("utilities.zig");
const forbear = @import("../root.zig");
const Vec2 = @Vector(2, f32);

test "wrapped text propagates height upward" {
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

        const tree = try layout();
        const rootNode = tree.at(0);
        const innerIdx = rootNode.firstChild.?;
        const innerNode = tree.at(innerIdx);

        try std.testing.expectEqual(100, rootNode.size[0]);
        try std.testing.expectEqual(100, textNode.size[0]);
        try std.testing.expectEqual(textNode.size[1], rootNode.size[1]);

        try std.testing.expectEqual(100, innerNode.size[0]);
        try std.testing.expectEqual(textNode.size[1], innerNode.size[1]);
    });
}

test "wrapped text simple ancestry stays at origin" {
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

        const tree = try layout();
        const rootNode = tree.at(0);
        const innerNode = tree.at(rootNode.firstChild.?);

        try std.testing.expectEqualDeep(Vec2{ 0.0, 0.0 }, textNode.position);
        try std.testing.expectEqualDeep(Vec2{ 0.0, 0.0 }, rootNode.position);
        try std.testing.expectEqualDeep(Vec2{ 0.0, 0.0 }, innerNode.position);
    });
}

test "wrapped text propagates height upward with siblings" {
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

        const tree = try layout();
        const rootNode = tree.at(0);
        const firstChild = tree.at(rootNode.firstChild.?);
        const secondChild = tree.at(firstChild.nextSibling.?);

        try std.testing.expectEqual(100, textNode.size[0]);
        try std.testing.expectEqual(100, rootNode.size[0]);
        try std.testing.expectEqual(textNode.size[1] + 100, rootNode.size[1]);
        try std.testing.expectEqual(100, firstChild.size[0]);
        try std.testing.expectEqual(textNode.size[1], firstChild.size[1]);
        try std.testing.expectEqual(100, secondChild.size[1]);
    });
}

test "wrapped text stacks siblings after wrapping" {
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

        const tree = try layout();
        const rootNode = tree.at(0);
        const firstChild = tree.at(rootNode.firstChild.?);
        const secondChild = tree.at(firstChild.nextSibling.?);

        try std.testing.expectEqualDeep(Vec2{ 0.0, 0.0 }, textNode.position);
        try std.testing.expectEqualDeep(Vec2{ 0.0, 0.0 }, rootNode.position);
        try std.testing.expectEqualDeep(Vec2{ 0.0, 0.0 }, firstChild.position);
        try std.testing.expectEqual(firstChild.position[0], secondChild.position[0]);
        try std.testing.expectEqual(firstChild.position[1] + firstChild.size[1], secondChild.position[1]);
    });
}
