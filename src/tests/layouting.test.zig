const std = @import("std");

const layouting = @import("../layouting.zig");
const layout = layouting.layout;
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

// Regression: `forbear.image()` uses `width: grow` + `height: ratio`. Build-time
// `fitChild` saw height 0, so a `height: fit` hero column stayed short and the
// next root sibling (e.g. offerings card) overlapped the headline. `growAndShrink`
// applies ratio sizing then incrementally propagates the main-axis delta with
// `updateFittingForAncestorsInDirection` (same machinery as wrapped text). Same flex
// shape as examples/uhoh.com (hero block + text + sibling section).
test "uhoh-shaped grow-width ratio hero does not overlap following sibling section" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        // viewport 800px wide from utilities.frameMeta
        forbear.element(.{
            .width = .grow,
            .height = .fit,
            .direction = .topToBottom,
        })({
            forbear.element(.{
                .width = .grow,
                .maxWidth = 600,
                .alignment = .topCenter,
                .padding = forbear.Padding.top(22.5).withBottom(30.0),
                .direction = .topToBottom,
            })({
                // Stand-in for `forbear.image` (grow width + intrinsic aspect).
                forbear.element(.{
                    .width = .grow,
                    .height = .{ .ratio = 0.5 },
                })({});
                forbear.element(.{
                    .fontSize = 18,
                    .margin = forbear.Margin.block(13.5).withBottom(7.5),
                })({
                    forbear.text("We're here to reinvent how tech gets done.");
                });
                forbear.element(.{
                    .fontSize = 12,
                })({
                    forbear.text("We're replacing clunky IT with clean, fast, and flexible support.");
                });
            });
            forbear.element(.{
                .width = .grow,
                .height = .{ .fixed = 80 },
                .background = .{ .color = .{ 1, 1, 1, 1 } },
            })({});
        });

        const tree = try layout();
        const rootNode = tree.at(0);
        const hero = tree.at(rootNode.firstChild.?);
        const card = tree.at(hero.nextSibling.?);

        const illustration = tree.at(hero.firstChild.?);
        const heading = tree.at(illustration.nextSibling.?);
        const subtext = tree.at(heading.nextSibling.?);

        try std.testing.expectApproxEqAbs(600.0, illustration.size[0], 0.02);
        try std.testing.expectApproxEqAbs(300.0, illustration.size[1], 0.02);

        // `wrapAndPlace` advances the next sibling by this node's `size[1]` only.
        // That always equals `card.y - hero.y`, even when `hero.size[1]` is
        // stale — so comparing those two is useless. What breaks is: inner
        // children were laid out with the real illustration height, but `hero`
        // stayed short, so the card is placed in the middle of the hero text.
        const heroContentBottom = subtext.position[1] + subtext.size[1];
        try std.testing.expect(hero.size[1] >= illustration.size[1] + hero.fittingBase(.topToBottom) - 0.02);
        try std.testing.expect(heroContentBottom <= card.position[1] + 0.02);

        try std.testing.expect(heading.position[1] > illustration.position[1] + illustration.size[1] - 0.02);
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

// Regression: `updateFittingForAncestorsInDirection` must apply perpendicular
// `.ratio` against the ancestor's size *after* `setSize` on the propagation axis.
// A row with `width: ratio` (width = height × r) and `height: fit` gets its height
// from a word-wrapped text column; that height updates during `wrapGlyphs`. Using
// the pre-update main-axis size for the ratio left `width` too small (stale h × r).
test "ratio width tracks fit height after propagated text wrap" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .direction = .topToBottom,
        })({
            forbear.element(.{
                .width = .{ .ratio = 2.0 },
                .height = .fit,
                .direction = .leftToRight,
            })({
                forbear.element(.{
                    .width = .{ .fixed = 120 },
                    .height = .fit,
                    .direction = .topToBottom,
                    .textWrapping = .word,
                })({
                    forbear.text("One two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty.");
                });
            });
        });

        const tree = try layout();
        const root = tree.at(0);
        const row = tree.at(root.firstChild.?);

        // Wrapped text should make the row noticeably tall (not a single line).
        try std.testing.expect(row.size[1] > 45.0);
        // width = height × 2 after propagation from wrapGlyphs
        try std.testing.expectApproxEqAbs(row.size[0], row.size[1] * 2.0, 1.0);
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

test "wrapAndPlace offsets standard children by border plus padding" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        forbear.element(.{
            .width = .{ .fixed = 200 },
            .height = .{ .fixed = 80 },
            .direction = .leftToRight,
            .borderWidth = .left(8),
            .padding = .left(7),
        })({
            forbear.element(.{
                .width = .{ .fixed = 40 },
                .height = .{ .fixed = 24 },
            })({});
        });

        const tree = try layout();
        const parent = tree.at(0);
        const child = tree.at(parent.firstChild.?);

        try std.testing.expectEqual(@as(f32, 15), child.position[0]);
        try std.testing.expectEqual(@as(f32, 0), child.position[1]);
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

test "overflow wrap line ranges start at the wrapping child for cross-axis alignment" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        // Same geometry as the basic wrap test, but center each row. The row that
        // wraps must still align every child on that row (including the wrapped
        // one); buggy line .start would attach the previous row's last child to
        // the new row and skip applying x alignment to the real wrapped child.
        forbear.element(.{
            .width = .{ .fixed = 300 },
            .height = .fit,
            .direction = .leftToRight,
            .overflow = .wrap,
            .alignment = .{ .x = .center, .y = .start },
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

        // Inner width 300px; line 1 is 240px wide → +30; line 2 is 120px → +90
        try std.testing.expectEqual(@as(f32, 30), childA.position[0]);
        try std.testing.expectEqual(@as(f32, 0), childA.position[1]);

        try std.testing.expectEqual(@as(f32, 150), childB.position[0]);
        try std.testing.expectEqual(@as(f32, 0), childB.position[1]);

        try std.testing.expectEqual(@as(f32, 90), childC.position[0]);
        try std.testing.expectEqual(@as(f32, 50), childC.position[1]);
    });
}

test "overflow wrap with grow-width parent wraps against resolved size" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        // Outer container anchors to the viewport (800x600).
        // The wrapping container uses grow so it fills the parent's
        // full 800px width. With wrapping-aware fitting, minSize is
        // the widest child (300) instead of the sum (900), so the
        // grow resolves to 800 rather than being floored at 900.
        // Three 300x60 children: the first two fit on line 1 (600 < 800),
        // the third overflows and wraps to line 2.
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .direction = .topToBottom,
        })({
            forbear.element(.{
                .width = .grow,
                .height = .fit,
                .direction = .leftToRight,
                .overflow = .wrap,
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
        });

        const tree = try layout();
        const outer = tree.at(0);
        const wrapper = tree.at(outer.firstChild.?);
        const childA = tree.at(wrapper.firstChild.?);
        const childB = tree.at(childA.nextSibling.?);
        const childC = tree.at(childB.nextSibling.?);

        // Wrapper grows to parent's 800px (not 900, since minSize
        // is now the widest child, not the sum)
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

test "percentage children resolve against non-root grown parent" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        // Fixed outer gives a known reference size (400x300).
        // Inner grow child should expand to fill it entirely.
        // Percentage grandchildren should resolve against the grown
        // inner's 400x300, not against zero.
        forbear.element(.{
            .width = .{ .fixed = 400 },
            .height = .{ .fixed = 300 },
            .direction = .topToBottom,
        })({
            forbear.element(.{
                .width = .grow,
                .height = .grow,
                .direction = .leftToRight,
            })({
                forbear.element(.{
                    .width = .{ .percentage = 0.5 },
                    .height = .{ .percentage = 0.5 },
                })({});
                forbear.element(.{
                    .width = .{ .percentage = 0.25 },
                    .height = .{ .percentage = 1.0 },
                })({});
            });
        });

        const tree = try layout();
        const outer = tree.at(0);
        const inner = tree.at(outer.firstChild.?);
        const pctA = tree.at(inner.firstChild.?);
        const pctB = tree.at(pctA.nextSibling.?);

        // Inner grows to fill the fixed outer
        try std.testing.expectEqual(@as(f32, 400), inner.size[0]);
        try std.testing.expectEqual(@as(f32, 300), inner.size[1]);

        // Percentage children resolve against the grown inner
        try std.testing.expectEqual(@as(f32, 200), pctA.size[0]);
        try std.testing.expectEqual(@as(f32, 150), pctA.size[1]);

        try std.testing.expectEqual(@as(f32, 100), pctB.size[0]);
        try std.testing.expectEqual(@as(f32, 300), pctB.size[1]);

        // Positioned side by side in the leftToRight row
        try std.testing.expectEqual(@as(f32, 0), pctA.position[0]);
        try std.testing.expectEqual(@as(f32, 200), pctB.position[0]);
    });
}

test "percentage children wrap correctly inside a wrapping parent" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        // Fixed 400px-wide leftToRight container with overflow:wrap.
        // Three children each at 50% width (200px): the first two fit
        // on line 1 (400 == 400), the third wraps to line 2.
        forbear.element(.{
            .width = .{ .fixed = 400 },
            .height = .fit,
            .direction = .leftToRight,
            .overflow = .wrap,
        })({
            forbear.element(.{
                .width = .{ .percentage = 0.5 },
                .height = .{ .fixed = 60 },
            })({});
            forbear.element(.{
                .width = .{ .percentage = 0.5 },
                .height = .{ .fixed = 60 },
            })({});
            forbear.element(.{
                .width = .{ .percentage = 0.5 },
                .height = .{ .fixed = 60 },
            })({});
        });

        const tree = try layout();
        const root = tree.at(0);
        const childA = tree.at(root.firstChild.?);
        const childB = tree.at(childA.nextSibling.?);
        const childC = tree.at(childB.nextSibling.?);

        try std.testing.expectEqual(@as(f32, 400), root.size[0]);

        // Each child resolves to 50% of 400 = 200px wide
        try std.testing.expectEqual(@as(f32, 200), childA.size[0]);
        try std.testing.expectEqual(@as(f32, 200), childB.size[0]);
        try std.testing.expectEqual(@as(f32, 200), childC.size[0]);

        // Line 1: A and B side by side at y=0
        try std.testing.expectEqual(@as(f32, 0), childA.position[0]);
        try std.testing.expectEqual(@as(f32, 0), childA.position[1]);

        try std.testing.expectEqual(@as(f32, 200), childB.position[0]);
        try std.testing.expectEqual(@as(f32, 0), childB.position[1]);

        // Line 2: C wraps to a new row
        try std.testing.expectEqual(@as(f32, 0), childC.position[0]);
        try std.testing.expectEqual(@as(f32, 60), childC.position[1]);
    });
}

test "wrapping container with text cards does not inflate ancestor height" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    // Reproduces the uhoh.com testimonials bug: a topToBottom section contains
    // a leftToRight wrapping container with multiple percentage-width cards
    // that have word-wrapped text. Each card's text wrapping fires
    // updateFittingForAncestors, which should NOT additively inflate the
    // section's height — only the wrapping container's actual height change
    // should propagate.
    try forbear.frame(try utilities.frameMeta(arena))({
        forbear.element(.{
            .width = .grow,
            .height = .fit,
            .direction = .topToBottom,
            .textWrapping = .word,
        })({
            // Section with wrapping cards
            forbear.element(.{
                .width = .grow,
                .maxWidth = 810,
                .direction = .topToBottom,
            })({
                forbear.element(.{
                    .overflow = .wrap,
                    .width = .grow,
                })({
                    // Line 1: two cards with LONG text (tall after wrapping)
                    forbear.element(.{
                        .width = .{ .percentage = 0.5 },
                        .direction = .topToBottom,
                        .padding = .all(10),
                    })({
                        forbear.text("Card A has a very long body of text that will wrap to many lines when constrained to half the container width. This creates a tall card on line one which is important for reproducing the height inflation bug where the tallest card from any line inflates the wrapping containers base height. We need this to be significantly taller than the cards on line two to expose the double counting.");
                    });
                    forbear.element(.{
                        .width = .{ .percentage = 0.5 },
                        .direction = .topToBottom,
                        .padding = .all(10),
                    })({
                        forbear.text("Card B also has a very long body of text that will wrap to many lines when constrained to half width. This ensures line one is tall. The bug causes the wrapping container height to include this line height twice: once from the text wrapping cross axis max and once from the element wrapping line addition.");
                    });
                    // Line 2: two cards with SHORT text (short after wrapping)
                    forbear.element(.{
                        .width = .{ .percentage = 0.5 },
                        .direction = .topToBottom,
                        .padding = .all(10),
                    })({
                        forbear.text("Card C short.");
                    });
                    forbear.element(.{
                        .width = .{ .percentage = 0.5 },
                        .direction = .topToBottom,
                        .padding = .all(10),
                    })({
                        forbear.text("Card D short.");
                    });
                });
            });
            // Sibling below the section
            forbear.element(.{
                .width = .{ .fixed = 100 },
                .height = .{ .fixed = 50 },
            })({});
        });

        const tree = try layout();

        const outer = tree.at(0);
        const section = tree.at(outer.firstChild.?);
        const wrapper = tree.at(section.firstChild.?);
        const sibling = tree.at(section.nextSibling.?);

        // Section height should equal wrapper height (no extra inflation)
        try std.testing.expectEqual(wrapper.size[1], section.size[1]);

        // Sibling should be positioned right after the section
        try std.testing.expectEqual(section.position[1] + section.size[1], sibling.position[1]);

        // Outer height should be section + sibling, not grossly inflated
        try std.testing.expectEqual(section.size[1] + 50.0, outer.size[1]);

        // The wrapping container's height must equal the sum of its line
        // heights (not inflated by text wrapping cross-axis max).
        // With 4 cards at 50% width, there are 2 lines. Compute expected
        // height from the actual card sizes.
        const cardA = tree.at(wrapper.firstChild.?);
        const cardB = tree.at(cardA.nextSibling.?);
        const cardC = tree.at(cardB.nextSibling.?);
        const cardD = tree.at(cardC.nextSibling.?);

        const line1Height = @max(
            cardA.style.margin.y[0] + cardA.size[1] + cardA.style.margin.y[1],
            cardB.style.margin.y[0] + cardB.size[1] + cardB.style.margin.y[1],
        );
        const line2Height = @max(
            cardC.style.margin.y[0] + cardC.size[1] + cardC.style.margin.y[1],
            cardD.style.margin.y[0] + cardD.size[1] + cardD.style.margin.y[1],
        );
        // Inter-line margin is the top margin of the first child on line 2
        const interLineMargin = cardC.style.margin.y[0];
        const expectedWrapperHeight = line1Height + interLineMargin + line2Height;
        try std.testing.expectEqual(expectedWrapperHeight, wrapper.size[1]);
    });
}

test "text inside percentage card inside wrapping container stays within bounds" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .direction = .topToBottom,
            .textWrapping = .word,
        })({
            forbear.element(.{
                .width = .grow,
                .maxWidth = 810,
                .direction = .topToBottom,
            })({
                forbear.element(.{
                    .overflow = .wrap,
                    .width = .grow,
                })({
                    forbear.element(.{
                        .width = .{ .percentage = 0.5 },
                        .padding = .all(13.5),
                        .direction = .leftToRight,
                    })({
                        forbear.element(.{
                            .width = .{ .fixed = 80 },
                            .height = .{ .fixed = 80 },
                            .margin = .right(10.5),
                        })({});

                        forbear.text("I'll be honest, we didn't know we needed help with the IT side of our business. After bringing on uhoh, I realized that I was very wrong. In the first month we built out systems and processes that will give us the capacity to scale well past where we were targeting for this year. Bonus is any time we have a problem and hit a wall, they just fix it. It really is like having a full IT team on standby. 10/10 recommend this. Clifton Sellers, Founder Legacy Builders");
                    });
                });
            });
        });

        const tree = try layout();

        // outer -> section -> wrapper -> card
        const outer = tree.at(0);
        const section = tree.at(outer.firstChild.?);
        const wrapper = tree.at(section.firstChild.?);
        const card = tree.at(wrapper.firstChild.?);

        // Viewport is 800, maxWidth 810, so section = 800. Card = 50% = 400.
        try std.testing.expectEqual(@as(f32, 400), card.size[0]);

        // card -> image, text
        const image = tree.at(card.firstChild.?);
        const textNode = tree.at(image.nextSibling.?);

        // Available width for text = card_width - padding*2 - image_width - image_margin_right
        const availableForText = 400.0 - 13.5 * 2.0 - 80.0 - 10.5;

        // Text must be shrunk to fit within the card's content area
        try std.testing.expect(textNode.size[0] <= availableForText + 1.0);

        // Card height must contain the tallest child plus padding
        const tallestChild = @max(image.size[1], textNode.size[1]);
        const expectedMinCardHeight = tallestChild + 13.5 * 2.0;
        try std.testing.expect(card.size[1] >= expectedMinCardHeight - 1.0);
    });
}

test "perpendicular clamping respects parent padding" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        // A topToBottom parent with fixed width and padding,
        // containing a long text that should be clamped to the content area.
        forbear.element(.{
            .width = .{ .fixed = 200 },
            .height = .fit,
            .direction = .topToBottom,
            .padding = .all(20),
            .textWrapping = .word,
        })({
            forbear.text("This is a long piece of text that should definitely wrap within the parent's content area and not overflow beyond its padding boundaries");
        });

        const tree = try layout();
        const parent = tree.at(0);
        const textNode = tree.at(parent.firstChild.?);

        // Content area = 200 - 20 - 20 = 160
        const contentWidth = 200.0 - 20.0 - 20.0;

        // The text node's width must not exceed the parent's content area
        try std.testing.expect(textNode.size[0] <= contentWidth + 0.001);
    });
}

test "manually placed elements are not affected by scroll" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .direction = .topToBottom,
        })({
            forbear.element(.{
                .width = .{ .fixed = 50 },
                .height = .{ .fixed = 50 },
                .placement = .{ .manual = .{ 10.0, 20.0 } },
            })({});

            forbear.element(.{
                .width = .{ .fixed = 50 },
                .height = .{ .fixed = 50 },
            })({});
        });

        // Simulate a scroll offset
        forbear.getContext().scrollPosition = .{ 0.0, 100.0 };

        const tree = try layout();
        const root = tree.at(0);
        const manualNode = tree.at(root.firstChild.?);
        const standardNode = tree.at(manualNode.nextSibling.?);

        // The manually placed element should be at its manual position, not offset by scroll
        try std.testing.expectEqual(@as(f32, 10.0), manualNode.position[0]);
        try std.testing.expectEqual(@as(f32, 20.0), manualNode.position[1]);

        // The standard element should be offset by scroll (root moves by -100)
        try std.testing.expectEqual(@as(f32, -100.0), standardNode.position[1]);
    });
}

test "fixed-width ratio-height children with maxSize don't inflate parent cross-axis" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    // Simulates the image() pattern: fixed width, ratio height, maxWidth/maxHeight constraints.
    // Without clamping, the parent sees the unclamped size and inflates its cross-axis height.
    try forbear.frame(try utilities.frameMeta(arena))({
        forbear.element(.{
            .width = .{ .fixed = 800 },
            .direction = .topToBottom,
        })({
            forbear.element(.{
                .direction = .leftToRight,
            })({
                // Mimics an image: fixed width 400, ratio height 0.75, maxWidth 128, maxHeight 112.
                // Unclamped size would be (400, 300); clamped should be (128, 96).
                forbear.element(.{
                    .width = .{ .fixed = 400 },
                    .height = .{ .ratio = 0.75 },
                    .minWidth = 0,
                    .minHeight = 0,
                    .maxWidth = 128,
                    .maxHeight = 112,
                })({});

                forbear.element(.{
                    .width = .{ .fixed = 300 },
                    .height = .{ .ratio = 0.5 },
                    .minWidth = 0,
                    .minHeight = 0,
                    .maxWidth = 128,
                    .maxHeight = 112,
                })({});
            });
        });

        const tree = try layout();
        const root = tree.at(0);
        const container = tree.at(root.firstChild.?);
        const child1 = tree.at(container.firstChild.?);
        const child2 = tree.at(child1.nextSibling.?);

        // Children should be clamped to their maxWidth, and height follows ratio
        try std.testing.expectEqual(@as(f32, 128), child1.size[0]);
        try std.testing.expectEqual(@as(f32, 96), child1.size[1]); // 128 * 0.75

        try std.testing.expectEqual(@as(f32, 128), child2.size[0]);
        try std.testing.expectEqual(@as(f32, 64), child2.size[1]); // 128 * 0.5

        // The container's cross-axis height should be max(96, 64) = 96, NOT 300
        try std.testing.expectEqual(@as(f32, 96), container.size[1]);
    });
}

test "ltr row with fixed height centers children vertically" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        // A 400x200 horizontal row with a 50px tall child.
        // With .center alignment the child should be at y = (200-50)/2 = 75.
        // With .end alignment the child should be at y = 200-50 = 150.
        forbear.element(.{
            .width = .{ .fixed = 400 },
            .height = .fit,
            .direction = .topToBottom,
        })({
            forbear.element(.{
                .width = .{ .fixed = 400 },
                .height = .{ .fixed = 200 },
                .direction = .leftToRight,
                .alignment = .{ .x = .start, .y = .center },
            })({
                forbear.element(.{
                    .width = .{ .fixed = 100 },
                    .height = .{ .fixed = 50 },
                })({});
            });

            forbear.element(.{
                .width = .{ .fixed = 400 },
                .height = .{ .fixed = 200 },
                .direction = .leftToRight,
                .alignment = .{ .x = .start, .y = .end },
            })({
                forbear.element(.{
                    .width = .{ .fixed = 100 },
                    .height = .{ .fixed = 50 },
                })({});
            });
        });

        const tree = try layout();
        const wrapper = tree.at(0);

        const centerRow = tree.at(wrapper.firstChild.?);
        const centerChild = tree.at(centerRow.firstChild.?);

        const endRow = tree.at(centerRow.nextSibling.?);
        const endChild = tree.at(endRow.firstChild.?);

        // Center: child should be vertically centered within the 200px parent
        try std.testing.expectEqual(@as(f32, 75), centerChild.position[1] - centerRow.position[1]);

        // End: child should be at the bottom of the 200px parent
        try std.testing.expectEqual(@as(f32, 150), endChild.position[1] - endRow.position[1]);
    });
}

test "layoutDump produces expected output for a simple tree" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        forbear.element(.{
            .width = .{ .fixed = 200 },
            .height = .{ .fixed = 100 },
            .padding = .all(10),
            .direction = .leftToRight,
        })({
            forbear.element(.{
                .width = .{ .fixed = 80 },
                .height = .{ .fixed = 40 },
                .margin = .all(5),
            })({});
        });

        const tree = try layout();

        var buf = try std.ArrayList(u8).initCapacity(std.testing.allocator, 256);
        defer buf.deinit(std.testing.allocator);

        try tree.layoutDump(buf.writer(std.testing.allocator).any());

        const output = buf.items;

        // Verify the dump contains key structural markers
        try std.testing.expect(std.mem.indexOf(u8, output, "[0]") != null);
        try std.testing.expect(std.mem.indexOf(u8, output, "[1]") != null);
        try std.testing.expect(std.mem.indexOf(u8, output, "dir=leftToRight") != null);
        try std.testing.expect(std.mem.indexOf(u8, output, "fixed(200.0)") != null);
        try std.testing.expect(std.mem.indexOf(u8, output, "fixed(80.0)") != null);
        try std.testing.expect(std.mem.indexOf(u8, output, "padding=x[10.0,10.0] y[10.0,10.0]") != null);
        try std.testing.expect(std.mem.indexOf(u8, output, "margin=x[5.0,5.0] y[5.0,5.0]") != null);
        try std.testing.expect(std.mem.indexOf(u8, output, "fittingBase:") != null);
    });
}

test "layoutDump reports glyph line count" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try utilities.frameMeta(arena))({
        forbear.element(.{
            .width = .{ .fixed = 100 },
            .height = .fit,
            .textWrapping = .word,
        })({
            forbear.text("Hello world, this is a test of wrapping text output");
        });

        const tree = try layout();

        var buf = try std.ArrayList(u8).initCapacity(std.testing.allocator, 256);
        defer buf.deinit(std.testing.allocator);

        try tree.layoutDump(buf.writer(std.testing.allocator).any());

        const output = buf.items;
        // The text node should have glyphs reported
        try std.testing.expect(std.mem.indexOf(u8, output, "glyphs=") != null);
        try std.testing.expect(std.mem.indexOf(u8, output, "lines)") != null);
    });
}

test "slotted component children propagate size to fit ancestors" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    const SlottedComponent = struct {
        fn render() *const fn (void) void {
            forbear.component("slotted")({
                forbear.element(.{
                    .width = .fit,
                    .height = .fit,
                    .padding = forbear.Padding.all(10),
                })({
                    forbear.componentChildrenSlot();
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    };

    try forbear.frame(try utilities.frameMeta(arena))({
        forbear.element(.{
            .width = .fit,
            .height = .fit,
        })({
            SlottedComponent.render()({
                forbear.element(.{
                    .width = .{ .fixed = 100 },
                    .height = .{ .fixed = 50 },
                })({});
            });
        });

        const tree = try layout();

        // Root element (index 0) should fit around the slotted component's
        // inner element (padding 10 on each side) + the fixed 100×50 child.
        const root = tree.at(0);
        try std.testing.expectEqual(120, root.size[0]); // 100 + 10 + 10
        try std.testing.expectEqual(70, root.size[1]); // 50 + 10 + 10

        // Inner element (index 1) from the slotted component
        const inner = tree.at(1);
        try std.testing.expectEqual(120, inner.size[0]);
        try std.testing.expectEqual(70, inner.size[1]);
    });
}

test "slotted component with before/after content sizes correctly" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    const SlottedComponent = struct {
        fn render() *const fn (void) void {
            forbear.component("slotted")({
                forbear.element(.{
                    .width = .fit,
                    .height = .fit,
                    .direction = .leftToRight,
                })({
                    forbear.element(.{
                        .width = .{ .fixed = 20 },
                        .height = .{ .fixed = 30 },
                    })({});
                    forbear.componentChildrenSlot();
                    forbear.element(.{
                        .width = .{ .fixed = 20 },
                        .height = .{ .fixed = 30 },
                    })({});
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    };

    try forbear.frame(try utilities.frameMeta(arena))({
        forbear.element(.{
            .width = .fit,
            .height = .fit,
        })({
            SlottedComponent.render()({
                forbear.element(.{
                    .width = .{ .fixed = 60 },
                    .height = .{ .fixed = 40 },
                })({});
            });
        });

        const tree = try layout();

        // Inner element: 20 (before) + 60 (child) + 20 (after) = 100 width
        // Height: max(30, 40, 30) = 40
        const inner = tree.at(1);
        try std.testing.expectEqual(100, inner.size[0]);
        try std.testing.expectEqual(40, inner.size[1]);

        // Root should match
        const root = tree.at(0);
        try std.testing.expectEqual(100, root.size[0]);
        try std.testing.expectEqual(40, root.size[1]);
    });
}

test "nested slotted components propagate sizes correctly" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    const Inner = struct {
        fn render() *const fn (void) void {
            forbear.component("inner")({
                forbear.element(.{
                    .width = .fit,
                    .height = .fit,
                    .padding = forbear.Padding.all(5),
                })({
                    forbear.componentChildrenSlot();
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    };

    const Outer = struct {
        fn render() *const fn (void) void {
            forbear.component("outer")({
                forbear.element(.{
                    .width = .fit,
                    .height = .fit,
                    .padding = forbear.Padding.all(10),
                })({
                    forbear.componentChildrenSlot();
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    };

    try forbear.frame(try utilities.frameMeta(arena))({
        forbear.element(.{
            .width = .fit,
            .height = .fit,
        })({
            Outer.render()({
                Inner.render()({
                    forbear.element(.{
                        .width = .{ .fixed = 50 },
                        .height = .{ .fixed = 30 },
                    })({});
                });
            });
        });

        const tree = try layout();

        // Inner element: 50 + 5+5 = 60 width, 30 + 5+5 = 40 height
        // Outer element: 60 + 10+10 = 80 width, 40 + 10+10 = 60 height
        // Root: 80 × 60
        const root = tree.at(0);
        try std.testing.expectEqual(80, root.size[0]);
        try std.testing.expectEqual(60, root.size[1]);
    });
}
