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

test "cross-axis fit row height reflects full column height after text wrapping" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    // Reproduces the uhoh.com hero section pattern:
    //   topToBottom outer
    //     leftToRight row (fit height)
    //       topToBottom column (grow width)
    //         wrapped text  (height grows during wrapGlyphs)
    //         fixed child   (50px)
    //     sibling below
    //
    // After text wrapping, the column's total height is text + 50.
    // The row's height must match the column's total, not just the text's height.
    // The sibling must start below the row — not overlap it.
    try forbear.frame(try utilities.frameMeta(arena))({
        var textNode: *forbear.Node = undefined;

        forbear.element(.{
            .width = .grow,
            .height = .fit,
            .direction = .topToBottom,
            .textWrapping = .word,
        })({
            // Row (fit height, leftToRight)
            forbear.element(.{
                .width = .grow,
                .direction = .leftToRight,
            })({
                // Inner column stacking text + fixed child
                forbear.element(.{
                    .direction = .topToBottom,
                    .width = .grow,
                })({
                    forbear.element(.{
                        .width = .{ .fixed = 200 },
                        .height = .fit,
                    })({
                        forbear.text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt");
                        textNode = forbear.getPreviousNode().?;
                    });
                    forbear.element(.{
                        .width = .{ .fixed = 100 },
                        .height = .{ .fixed = 50 },
                    })({});
                });
            });
            // Sibling that must appear below the row
            forbear.element(.{
                .width = .{ .fixed = 100 },
                .height = .{ .fixed = 30 },
            })({});
        });

        const tree = try layout();
        const outer = tree.at(0);
        const row = tree.at(outer.firstChild.?);
        const column = tree.at(row.firstChild.?);
        const sibling = tree.at(row.nextSibling.?);

        const expectedColumnHeight = textNode.size[1] + 50.0;
        try std.testing.expectEqual(expectedColumnHeight, column.size[1]);
        try std.testing.expectEqual(expectedColumnHeight, row.size[1]);

        // The sibling must start at or below the row's bottom edge, not overlap
        try std.testing.expect(sibling.position[1] >= row.position[1] + row.size[1]);
    });
}

test "percentage children resolve against grown parent" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        // viewport is 800x600
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .direction = .topToBottom,
        })({
            forbear.element(.{
                .width = .{ .percentage = 0.5 },
                .height = .{ .percentage = 0.25 },
            })({});
            forbear.element(.{
                .width = .{ .percentage = 1.0 },
                .height = .{ .percentage = 0.75 },
            })({});
        });

        const tree = try layout();
        const root = tree.at(0);
        const childA = tree.at(root.firstChild.?);
        const childB = tree.at(childA.nextSibling.?);

        try std.testing.expectEqual(@as(f32, 800), root.size[0]);
        try std.testing.expectEqual(@as(f32, 600), root.size[1]);

        try std.testing.expectEqual(@as(f32, 400), childA.size[0]);
        try std.testing.expectEqual(@as(f32, 150), childA.size[1]);

        try std.testing.expectEqual(@as(f32, 800), childB.size[0]);
        try std.testing.expectEqual(@as(f32, 450), childB.size[1]);
    });
}

test "percentage children positioned correctly among fixed siblings" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        // viewport is 800x600; leftToRight row
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .direction = .leftToRight,
        })({
            forbear.element(.{
                .width = .{ .fixed = 100 },
                .height = .{ .fixed = 50 },
            })({});
            forbear.element(.{
                .width = .{ .percentage = 0.5 },
                .height = .{ .fixed = 50 },
            })({});
            forbear.element(.{
                .width = .{ .fixed = 60 },
                .height = .{ .fixed = 50 },
            })({});
        });

        const tree = try layout();
        const root = tree.at(0);
        const fixedA = tree.at(root.firstChild.?);
        const pctChild = tree.at(fixedA.nextSibling.?);
        const fixedB = tree.at(pctChild.nextSibling.?);

        try std.testing.expectEqual(@as(f32, 400), pctChild.size[0]);

        try std.testing.expectEqual(@as(f32, 0), fixedA.position[0]);
        try std.testing.expectEqual(@as(f32, 100), pctChild.position[0]);
        try std.testing.expectEqual(100.0 + 400.0, fixedB.position[0]);
    });
}

test "ratio height resolves after grow distributes width" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        // viewport 800x600; leftToRight root
        // child: width grows to fill 800, height = ratio(0.5) → 400
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .direction = .leftToRight,
        })({
            forbear.element(.{
                .width = .grow,
                .height = .{ .ratio = 0.5 },
            })({});
        });

        const tree = try layout();
        const root = tree.at(0);
        const child = tree.at(root.firstChild.?);

        try std.testing.expectEqual(@as(f32, 800), child.size[0]);
        try std.testing.expectEqual(@as(f32, 400), child.size[1]);
    });
}

test "ratio width resolves after grow distributes height" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        // viewport 800x600; topToBottom root
        // child: height grows to fill 600, width = ratio(2.0) → 1200
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .direction = .topToBottom,
        })({
            forbear.element(.{
                .width = .{ .ratio = 2.0 },
                .height = .grow,
            })({});
        });

        const tree = try layout();
        const root = tree.at(0);
        const child = tree.at(root.firstChild.?);

        try std.testing.expectEqual(@as(f32, 600), child.size[1]);
        try std.testing.expectEqual(@as(f32, 1200), child.size[0]);
    });
}

test "percentage and ratio children coexist in a row" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        // viewport 800x600; leftToRight root
        // child A: width = 50% of 800 = 400, height = ratio(0.5) → 200
        // child B: width = fixed 200, height = percentage(0.5) of 600 = 300
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .direction = .leftToRight,
        })({
            forbear.element(.{
                .width = .{ .percentage = 0.5 },
                .height = .{ .ratio = 0.5 },
            })({});
            forbear.element(.{
                .width = .{ .fixed = 200 },
                .height = .{ .percentage = 0.5 },
            })({});
        });

        const tree = try layout();
        const root = tree.at(0);
        const childA = tree.at(root.firstChild.?);
        const childB = tree.at(childA.nextSibling.?);

        try std.testing.expectEqual(@as(f32, 400), childA.size[0]);
        try std.testing.expectEqual(@as(f32, 200), childA.size[1]);

        try std.testing.expectEqual(@as(f32, 200), childB.size[0]);
        try std.testing.expectEqual(@as(f32, 300), childB.size[1]);

        try std.testing.expectEqual(@as(f32, 0), childA.position[0]);
        try std.testing.expectEqual(@as(f32, 400), childB.position[0]);
    });
}

test "overflow wrap places children on new lines and grows parent height" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        // A 300px-wide leftToRight container with overflow: wrap.
        // Three 120x50 children: the first two fit on line 1 (240px < 300px),
        // the third overflows and wraps to line 2.
        forbear.element(.{
            .width = .{ .fixed = 300 },
            .height = .fit,
            .direction = .leftToRight,
            .overflow = .wrap,
        })({
            forbear.element(.{
                .width = .{ .fixed = 120 },
                .height = .{ .fixed = 50 },
            })({});
            forbear.element(.{
                .width = .{ .fixed = 120 },
                .height = .{ .fixed = 50 },
            })({});
            forbear.element(.{
                .width = .{ .fixed = 120 },
                .height = .{ .fixed = 50 },
            })({});
        });

        const tree = try layout();
        const root = tree.at(0);
        const childA = tree.at(root.firstChild.?);
        const childB = tree.at(childA.nextSibling.?);
        const childC = tree.at(childB.nextSibling.?);

        try std.testing.expectEqual(@as(f32, 300), root.size[0]);

        // Line 1: childA and childB side by side at y=0
        try std.testing.expectEqual(@as(f32, 0), childA.position[0]);
        try std.testing.expectEqual(@as(f32, 0), childA.position[1]);

        try std.testing.expectEqual(@as(f32, 120), childB.position[0]);
        try std.testing.expectEqual(@as(f32, 0), childB.position[1]);

        // Line 2: childC wraps to a new row, x resets and y advances by
        // line 1's height (50)
        try std.testing.expectEqual(@as(f32, 0), childC.position[0]);
        try std.testing.expectEqual(@as(f32, 50), childC.position[1]);

        // Fit height = initial cross-axis max (50) + wrap addition (50) = 100
        try std.testing.expectEqual(@as(f32, 100), root.size[1]);
    });
}

test "overflow wrap with percentage-width parent wraps against resolved size" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        // Outer container anchors to the viewport (800x600).
        // The wrapping container uses percentage(1.0) to resolve to
        // the parent's full 800px width — the common CSS "width:100%;
        // flex-wrap:wrap" pattern.
        // Three 300x60 children: the first two fit on line 1 (600 < 800),
        // the third overflows and wraps to line 2.
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .direction = .topToBottom,
        })({
            forbear.element(.{
                .width = .{ .fixed = 300 },
                .height = .{ .fixed = 60 },
            })({});
            forbear.element(.{
                .width = .{ .fixed = 300 },
                .height = .{ .fixed = 60 },
            })({});
            forbear.element(.{
                .width = .{ .fixed = 300 },
                .height = .{ .fixed = 60 },
            })({});
        });

        const tree = try layout();
        const outer = tree.at(0);
        const wrapper = tree.at(outer.firstChild.?);
        const childA = tree.at(wrapper.firstChild.?);
        const childB = tree.at(childA.nextSibling.?);
        const childC = tree.at(childB.nextSibling.?);

        // Wrapper resolves to 100% of outer's 800px
        try std.testing.expectEqual(@as(f32, 800), wrapper.size[0]);

        // Line 1: A and B side by side at y=0
        try std.testing.expectEqual(@as(f32, 0), childA.position[0]);
        try std.testing.expectEqual(@as(f32, 0), childA.position[1]);

        try std.testing.expectEqual(@as(f32, 300), childB.position[0]);
        try std.testing.expectEqual(@as(f32, 0), childB.position[1]);

        // Line 2: C wraps, x resets and y advances by line 1 height (60)
        try std.testing.expectEqual(@as(f32, 0), childC.position[0]);
        try std.testing.expectEqual(@as(f32, 60), childC.position[1]);

        // Fit height = initial cross-axis max (60) + wrap addition (60) = 120
        try std.testing.expectEqual(@as(f32, 120), wrapper.size[1]);
    });
}

test "grow children split remaining space and stretch cross-axis" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .direction = .leftToRight,
        })({
            forbear.element(.{
                .width = .{ .fixed = 100 },
                .height = .{ .fixed = 40 },
            })({});
            forbear.element(.{
                .width = .grow,
                .height = .grow,
            })({});
            forbear.element(.{
                .width = .grow,
                .height = .grow,
            })({});
        });

        const tree = try layout();
        const root = tree.at(0);

        try std.testing.expectEqual(@as(f32, 800), root.size[0]);
        try std.testing.expectEqual(@as(f32, 600), root.size[1]);

        const fixedChild = tree.at(root.firstChild.?);
        const growA = tree.at(fixedChild.nextSibling.?);
        const growB = tree.at(growA.nextSibling.?);

        try std.testing.expectEqual(@as(f32, 100), fixedChild.size[0]);
        try std.testing.expectEqual(@as(f32, 40), fixedChild.size[1]);

        const remainingWidth = 800.0 - 100.0;
        const expectedGrowWidth = remainingWidth / 2.0;
        try std.testing.expectEqual(expectedGrowWidth, growA.size[0]);
        try std.testing.expectEqual(expectedGrowWidth, growB.size[0]);

        try std.testing.expectEqual(@as(f32, 600), growA.size[1]);
        try std.testing.expectEqual(@as(f32, 600), growB.size[1]);

        try std.testing.expectEqual(@as(f32, 0), fixedChild.position[0]);
        try std.testing.expectEqual(@as(f32, 100), growA.position[0]);
        try std.testing.expectEqual(100.0 + expectedGrowWidth, growB.position[0]);
    });
}
