const std = @import("std");

const wrapAndPlace = @import("../layouting.zig").wrapAndPlace;
const applyRatios = @import("../layouting.zig").applyRatios;
const growAndShrink = @import("../layouting.zig").growAndShrink;
const fit = @import("../layouting.zig").fit;
const layout = @import("../layouting.zig").layout;
const Node = @import("../node.zig").Node;
const Glyphs = @import("../node.zig").Glyphs;
const IncompleteStyle = @import("../node.zig").IncompleteStyle;
const Sizing = @import("../node.zig").Sizing;
const Direction = @import("../node.zig").Direction;
const BaseStyle = @import("../node.zig").BaseStyle;
const LayoutGlyph = @import("../node.zig").LayoutGlyph;
const Alignment = @import("../node.zig").Alignment;
const TextWrapping = @import("../node.zig").TextWrapping;
const forbear = @import("../root.zig");
const utilities = @import("utilities.zig");

const Vec2 = @Vector(2, f32);

fn testWrapConfiguration(configuration: struct {
    mode: TextWrapping,
    alignment: Alignment,
    lineWidth: f32,
    lineHeight: f32,
    glyphs: []LayoutGlyph,
    expectedPositions: []const Vec2,
}) !void {
    std.debug.assert(configuration.expectedPositions.len == configuration.glyphs.len);
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var totalAdvanceX: f32 = 0.0;
    for (configuration.glyphs) |glyph| {
        totalAdvanceX += glyph.advance[0];
    }

    var node = Node{
        .key = 1,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ configuration.lineWidth, configuration.lineHeight },
        .minSize = .{ 0.0, 20.0 },
        .maxSize = .{ totalAdvanceX, configuration.lineHeight * @as(f32, @floatFromInt(configuration.glyphs.len)) },
        .children = .{
            .glyphs = Glyphs{
                .slice = configuration.glyphs,
                .lineHeight = configuration.lineHeight,
            },
        },
        .style = (IncompleteStyle{
            .alignment = configuration.alignment,
        }).completeWith(BaseStyle{
            .font = undefined,
            .color = .{ 0.0, 0.0, 0.0, 1.0 },
            .fontSize = 16,
            .fontWeight = 400,
            .lineHeight = 1.0,
            .textWrapping = configuration.mode,
            .blendMode = .normal,
            .cursor = .default,
        }),
    };

    try wrapAndPlace(arenaAllocator, &node);

    const glyphPositions = try arenaAllocator.alloc(Vec2, configuration.glyphs.len);
    for (configuration.glyphs, 0..) |glyph, i| {
        glyphPositions[i] = glyph.position;
    }
    try std.testing.expectEqualDeep(configuration.expectedPositions, glyphPositions);
}

const MountedTextWrappingLayout = struct {
    rootSize: Vec2,
    textNodePosition: Vec2,
    textNodeSize: Vec2,
    textNodeMinSize: Vec2,
    lineHeight: f32,
    glyphPositions: []Vec2,

    fn deinit(self: @This()) void {
        std.testing.allocator.free(self.glyphPositions);
    }
};

fn layoutMountedText(configuration: struct {
    width: Sizing,
    alignment: Alignment = .topLeft,
    textWrapping: TextWrapping,
    content: []const u8,
}) !MountedTextWrappingLayout {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var root: Node = undefined;
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .leftToRight,
            .width = configuration.width,
            .height = .fit,
            .alignment = configuration.alignment,
            .textWrapping = configuration.textWrapping,
        })({
            forbear.text(configuration.content);
        });
        root = (try layout()).*;
    });

    try std.testing.expectEqual(@as(usize, 1), root.children.nodes.items.len);
    const textNode = root.children.nodes.items[0];
    std.debug.assert(textNode.children == .glyphs);

    const glyphs = textNode.children.glyphs;
    const glyphPositions = try std.testing.allocator.alloc(Vec2, glyphs.slice.len);
    for (glyphs.slice, 0..) |glyph, index| {
        glyphPositions[index] = glyph.position;
    }

    return .{
        .rootSize = root.size,
        .textNodePosition = textNode.position,
        .textNodeSize = textNode.size,
        .textNodeMinSize = textNode.minSize,
        .lineHeight = glyphs.lineHeight,
        .glyphPositions = glyphPositions,
    };
}

fn lineCountFromGlyphPositions(glyphPositions: []const Vec2) usize {
    if (glyphPositions.len == 0) {
        return 0;
    }

    var count: usize = 1;
    var previousX = glyphPositions[0][0];
    for (glyphPositions[1..]) |position| {
        if (position[0] < previousX - 0.001) {
            count += 1;
        }
        previousX = position[0];
    }

    return count;
}

fn secondLineStartX(glyphPositions: []const Vec2) ?f32 {
    if (glyphPositions.len < 2) {
        return null;
    }

    var previousX = glyphPositions[0][0];
    for (glyphPositions[1..]) |position| {
        if (position[0] < previousX - 0.001) {
            return position[0];
        }
        previousX = position[0];
    }

    return null;
}

const TestChild = struct {
    width: Sizing = .fit,
    height: Sizing = .fit,
    size: Vec2,
    minSize: Vec2 = .{ 0.0, 0.0 },
    maxSize: Vec2 = .{ std.math.inf(f32), std.math.inf(f32) },
};

fn testGrowAndShrinkConfiguration(configuration: struct {
    direction: Direction,
    parentSize: Vec2,
    children: []const TestChild,
    expectedSizes: []const Vec2,
}) !void {
    std.debug.assert(configuration.children.len == configuration.expectedSizes.len);
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var children = try std.ArrayList(Node).initCapacity(arenaAllocator, configuration.children.len);
    for (configuration.children, 0..) |child, i| {
        children.appendAssumeCapacity(Node{
            .key = @intCast(i),
            .position = .{ 0.0, 0.0 },
            .z = 0,
            .size = child.size,
            .minSize = child.minSize,
            .maxSize = child.maxSize,
            .children = .{ .nodes = .empty },
            .style = (IncompleteStyle{
                .width = child.width,
                .height = child.height,
            }).completeWith(utilities.shallowBaseStyle),
        });
    }

    var parent = Node{
        .key = 999,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = configuration.parentSize,
        .minSize = .{ 0.0, 0.0 },
        .maxSize = configuration.parentSize,
        .children = .{ .nodes = children },
        .style = (IncompleteStyle{
            .direction = configuration.direction,
        }).completeWith(utilities.shallowBaseStyle),
    };

    try growAndShrink(arenaAllocator, &parent);

    const actualSizes = try arenaAllocator.alloc(Vec2, configuration.children.len);
    for (parent.children.nodes.items, 0..) |child, i| {
        actualSizes[i] = child.size;
    }
    std.log.debug("Expecting {any}", .{configuration.expectedSizes});
    std.log.debug("Finding {any}", .{actualSizes});
    try std.testing.expectEqualDeep(configuration.expectedSizes, actualSizes);
}

test "growAndShrink - single grow child fills remaining space horizontally" {
    try testGrowAndShrinkConfiguration(.{
        .direction = .leftToRight,
        .parentSize = .{ 100.0, 50.0 },
        .children = &.{
            .{ .width = .grow, .size = .{ 0.0, 50.0 } },
        },
        .expectedSizes = &.{
            .{ 100.0, 50.0 },
        },
    });
}

test "growAndShrink - all grow children at maxSize with remaining space" {
    // Both grow children reach maxSize (40 each) but parent is 200 wide,
    // leaving 120 remaining. The loop must terminate even though no child
    // can grow further.
    try testGrowAndShrinkConfiguration(.{
        .direction = .leftToRight,
        .parentSize = .{ 200.0, 50.0 },
        .children = &.{
            .{ .width = .grow, .size = .{ 0.0, 50.0 }, .maxSize = .{ 40.0, 50.0 } },
            .{ .width = .grow, .size = .{ 0.0, 50.0 }, .maxSize = .{ 40.0, 50.0 } },
        },
        .expectedSizes = &.{
            .{ 40.0, 50.0 },
            .{ 40.0, 50.0 },
        },
    });
}

test "growAndShrink - grow child clamped by maxSize" {
    try testGrowAndShrinkConfiguration(.{
        .direction = .leftToRight,
        .parentSize = .{ 200.0, 50.0 },
        .children = &.{
            .{ .width = .grow, .size = .{ 0.0, 50.0 }, .maxSize = .{ 80.0, 50.0 } },
        },
        .expectedSizes = &.{
            .{ 80.0, 50.0 },
        },
    });
}

test "growAndShrink - grow child respects minSize when parent is small" {
    try testGrowAndShrinkConfiguration(.{
        .direction = .leftToRight,
        .parentSize = .{ 100.0, 50.0 },
        .children = &.{
            .{ .width = .grow, .size = .{ 0.0, 50.0 }, .minSize = .{ 60.0, 0.0 } },
            .{ .width = .{ .fixed = 80.0 }, .size = .{ 80.0, 50.0 }, .minSize = .{ 80.0, 0.0 } },
        },
        .expectedSizes = &.{
            .{ 60.0, 50.0 },
            .{ 80.0, 50.0 },
        },
    });
}

test "growAndShrink - two grow children split space equally" {
    try testGrowAndShrinkConfiguration(.{
        .direction = .leftToRight,
        .parentSize = .{ 200.0, 50.0 },
        .children = &.{
            .{ .width = .grow, .size = .{ 0.0, 50.0 } },
            .{ .width = .grow, .size = .{ 0.0, 50.0 } },
        },
        .expectedSizes = &.{
            .{ 100.0, 50.0 },
            .{ 100.0, 50.0 },
        },
    });
}

test "growAndShrink - two grow children with different maxSize" {
    try testGrowAndShrinkConfiguration(.{
        .direction = .leftToRight,
        .parentSize = .{ 200.0, 50.0 },
        .children = &.{
            .{ .width = .grow, .size = .{ 0.0, 50.0 }, .maxSize = .{ 60.0, 50.0 } },
            .{ .width = .grow, .size = .{ 0.0, 50.0 } },
        },
        .expectedSizes = &.{
            .{ 60.0, 50.0 },
            .{ 140.0, 50.0 },
        },
    });
}

test "growAndShrink - shrink respects minSize" {
    // Two fixed children that together exceed parent width; shrink should
    // reduce them but not below their minSize.
    try testGrowAndShrinkConfiguration(.{
        .direction = .leftToRight,
        .parentSize = .{ 100.0, 50.0 },
        .children = &.{
            .{ .width = .{ .fixed = 80.0 }, .size = .{ 80.0, 50.0 }, .minSize = .{ 50.0, 0.0 } },
            .{ .width = .{ .fixed = 80.0 }, .size = .{ 80.0, 50.0 }, .minSize = .{ 50.0, 0.0 } },
        },
        .expectedSizes = &.{
            .{ 50.0, 50.0 },
            .{ 50.0, 50.0 },
        },
    });
}

test "growAndShrink - grow vertically with maxSize constraint" {
    try testGrowAndShrinkConfiguration(.{
        .direction = .topToBottom,
        .parentSize = .{ 100.0, 300.0 },
        .children = &.{
            .{ .height = .grow, .size = .{ 100.0, 0.0 }, .maxSize = .{ 100.0, 120.0 } },
            .{ .height = .grow, .size = .{ 100.0, 0.0 } },
        },
        .expectedSizes = &.{
            .{ 100.0, 120.0 },
            .{ 100.0, 180.0 },
        },
    });
}

test "growAndShrink - grow with both minSize and maxSize" {
    // Three grow children: one clamped by maxSize, one has a minSize floor,
    // one unconstrained. Parent has 300 width.
    try testGrowAndShrinkConfiguration(.{
        .direction = .leftToRight,
        .parentSize = .{ 300.0, 50.0 },
        .children = &.{
            .{ .width = .grow, .size = .{ 0.0, 50.0 }, .maxSize = .{ 50.0, 50.0 } },
            .{ .width = .grow, .size = .{ 0.0, 50.0 }, .minSize = .{ 80.0, 0.0 } },
            .{ .width = .grow, .size = .{ 0.0, 50.0 } },
        },
        .expectedSizes = &.{
            .{ 50.0, 50.0 },
            .{ 125.0, 50.0 },
            .{ 125.0, 50.0 },
        },
    });
}

test "growAndShrink - shrink with asymmetric minSize" {
    // Two children overflow by 80. One has a high minSize so the other must
    // absorb more of the shrink.
    try testGrowAndShrinkConfiguration(.{
        .direction = .leftToRight,
        .parentSize = .{ 120.0, 50.0 },
        .children = &.{
            .{ .width = .{ .fixed = 100.0 }, .size = .{ 100.0, 50.0 }, .minSize = .{ 90.0, 0.0 } },
            .{ .width = .{ .fixed = 100.0 }, .size = .{ 100.0, 50.0 }, .minSize = .{ 20.0, 0.0 } },
        },
        .expectedSizes = &.{
            .{ 90.0, 50.0 },
            .{ 30.0, 50.0 },
        },
    });
}

test "growAndShrink - cross-axis grow clamped by maxSize" {
    // Direction is leftToRight, so cross-axis is height. Child has
    // preferredHeight = .grow, which should expand to parent height but
    // be clamped by maxSize.
    try testGrowAndShrinkConfiguration(.{
        .direction = .leftToRight,
        .parentSize = .{ 200.0, 100.0 },
        .children = &.{
            .{ .width = .{ .fixed = 200.0 }, .height = .grow, .size = .{ 200.0, 30.0 }, .maxSize = .{ 200.0, 60.0 } },
        },
        .expectedSizes = &.{
            .{ 200.0, 60.0 },
        },
    });
}

test "growAndShrink - cross-axis grow respects minSize" {
    // Direction is topToBottom, cross-axis is width. Child has
    // preferredWidth = .grow with a minSize larger than parent — minSize wins.
    try testGrowAndShrinkConfiguration(.{
        .direction = .topToBottom,
        .parentSize = .{ 80.0, 200.0 },
        .children = &.{
            .{ .height = .{ .fixed = 200.0 }, .width = .grow, .size = .{ 50.0, 200.0 }, .minSize = .{ 100.0, 0.0 }, .maxSize = .{ 200.0, 200.0 } },
        },
        .expectedSizes = &.{
            .{ 100.0, 200.0 },
        },
    });
}

test "growAndShrink - horizontal ratio uses cross-axis grow before remaining split" {
    // Child 0 gets its height from cross-axis grow and then derives width from
    // ratio. That derived width must be subtracted before grow children split
    // the remaining main-axis space.
    try testGrowAndShrinkConfiguration(.{
        .direction = .leftToRight,
        .parentSize = .{ 300.0, 100.0 },
        .children = &.{
            .{
                .width = .{ .ratio = 0.2 },
                .height = .grow,
                .size = .{ 0.0, 0.0 },
            },
            .{
                .width = .grow,
                .height = .grow,
                .size = .{ 0.0, 0.0 },
            },
        },
        .expectedSizes = &.{
            .{ 20.0, 100.0 },
            .{ 280.0, 100.0 },
        },
    });
}

test "growAndShrink - vertical ratio uses cross-axis grow before remaining split" {
    // Mirror case for topToBottom: child 0 gets width from cross-axis grow and
    // then derives height from ratio before the remaining height is allocated.
    try testGrowAndShrinkConfiguration(.{
        .direction = .topToBottom,
        .parentSize = .{ 120.0, 300.0 },
        .children = &.{
            .{
                .width = .grow,
                .height = .{ .ratio = 0.5 },
                .size = .{ 0.0, 0.0 },
            },
            .{
                .width = .grow,
                .height = .grow,
                .size = .{ 0.0, 0.0 },
            },
        },
        .expectedSizes = &.{
            .{ 120.0, 60.0 },
            .{ 120.0, 240.0 },
        },
    });
}

test "growAndShrink - horizontal ratio participates in shrink distribution" {
    // Child 0 derives width from ratio after cross-axis grow. Since total width
    // overflows the parent, shrink must include that derived width.
    try testGrowAndShrinkConfiguration(.{
        .direction = .leftToRight,
        .parentSize = .{ 40.0, 100.0 },
        .children = &.{
            .{
                .width = .{ .ratio = 0.5 },
                .height = .grow,
                .size = .{ 0.0, 0.0 },
            },
            .{
                .width = .{ .fixed = 30.0 },
                .height = .grow,
                .size = .{ 30.0, 0.0 },
            },
        },
        .expectedSizes = &.{
            .{ 20.0, 100.0 },
            .{ 20.0, 100.0 },
        },
    });
}

test "growAndShrink - vertical ratio participates in shrink distribution" {
    // Mirror case for topToBottom.
    try testGrowAndShrinkConfiguration(.{
        .direction = .topToBottom,
        .parentSize = .{ 100.0, 50.0 },
        .children = &.{
            .{
                .width = .grow,
                .height = .{ .ratio = 0.8 },
                .size = .{ 0.0, 0.0 },
            },
            .{
                .width = .grow,
                .height = .{ .fixed = 30.0 },
                .size = .{ 0.0, 30.0 },
            },
        },
        .expectedSizes = &.{
            .{ 100.0, 25.0 },
            .{ 100.0, 25.0 },
        },
    });
}

fn testFitConfiguration(configuration: struct {
    direction: Direction,
    expectedHeight: f32,
}) !void {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var children = try std.ArrayList(Node).initCapacity(arenaAllocator, 2);
    children.appendAssumeCapacity(Node{
        .key = 1,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 20.0, 30.0 },
        .minSize = .{ 20.0, 30.0 },
        .maxSize = .{ 20.0, 30.0 },
        .children = .{ .nodes = .empty },
        .style = (IncompleteStyle{
            .width = .{ .fixed = 20.0 },
            .height = .{ .fixed = 30.0 },
            .margin = forbear.Margin.block(1.0).withBottom(2.0),
        }).completeWith(utilities.shallowBaseStyle),
    });
    children.appendAssumeCapacity(Node{
        .key = 2,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 20.0, 40.0 },
        .minSize = .{ 20.0, 40.0 },
        .maxSize = .{ 20.0, 40.0 },
        .children = .{ .nodes = .empty },
        .style = (IncompleteStyle{
            .width = .{ .fixed = 20.0 },
            .height = .{ .fixed = 40.0 },
            .margin = forbear.Margin.block(3.0).withBottom(4.0),
        }).completeWith(utilities.shallowBaseStyle),
    });

    var parent = Node{
        .key = 999,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 100.0, 0.0 },
        .minSize = .{ 100.0, 0.0 },
        .maxSize = .{ 100.0, std.math.inf(f32) },
        .children = .{ .nodes = children },
        .style = (IncompleteStyle{
            .direction = configuration.direction,
            .width = .{ .fixed = 100.0 },
            .height = .fit,
            .padding = forbear.Padding.block(10.0).withBottom(20.0),
            .borderWidth = forbear.BorderWidth.block(2.0).withBottom(3.0),
        }).completeWith(utilities.shallowBaseStyle),
    };

    fit(&parent);

    try std.testing.expectEqual(configuration.expectedHeight, parent.size[1]);
    try std.testing.expectEqual(configuration.expectedHeight, parent.minSize[1]);
}

test "fit - fitted height handles main and cross axis cases" {
    try testFitConfiguration(.{
        .direction = .topToBottom,
        .expectedHeight = 115.0,
    });
    try testFitConfiguration(.{
        .direction = .leftToRight,
        .expectedHeight = 82.0,
    });
}

test "text wrapping - no wrapping when glyphs fit on single line" {
    var glyphs = [_]LayoutGlyph{
        .{
            .index = 0,
            .position = .{ 0.0, 0.0 },
            .text = "a",
            .advance = .{ 10.0, 0.0 },
            .offset = .{ 0.0, 0.0 },
        },
    } ** 5;
    try testWrapConfiguration(.{
        .glyphs = &glyphs,
        .alignment = .topLeft,
        .mode = .character,
        .lineWidth = 100.0,
        .lineHeight = 20.0,
        .expectedPositions = &.{
            .{ 0.0, 0.0 },
            .{ 10.0, 0.0 },
            .{ 20.0, 0.0 },
            .{ 30.0, 0.0 },
            .{ 40.0, 0.0 },
        },
    });
}

test "text wrapping - character wrapping with small width" {
    var glyphs = [_]LayoutGlyph{
        .{
            .index = 0,
            .position = .{ 0.0, 0.0 },
            .text = "a",
            .advance = .{ 15.0, 0.0 },
            .offset = .{ 0.0, 0.0 },
        },
    } ** 6;
    try testWrapConfiguration(.{
        .glyphs = &glyphs,
        .alignment = .topLeft,
        .mode = .character,
        .lineWidth = 35.0,
        .lineHeight = 20.0,
        .expectedPositions = &.{
            .{ 0.0, 0.0 },
            .{ 15.0, 0.0 },
            .{ 0.0, 20.0 },
            .{ 15.0, 20.0 },
            .{ 0.0, 40.0 },
            .{ 15.0, 40.0 },
        },
    });
}

test "text wrapping - word wrapping with small width" {
    // Create glyphs representing "hello world" (11 glyphs including space)
    var glyphs = [_]LayoutGlyph{
        .{ .index = 0, .position = .{ 0.0, 0.0 }, .text = "h", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 1, .position = .{ 0.0, 0.0 }, .text = "e", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 2, .position = .{ 0.0, 0.0 }, .text = "l", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 3, .position = .{ 0.0, 0.0 }, .text = "l", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 4, .position = .{ 0.0, 0.0 }, .text = "o", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 5, .position = .{ 0.0, 0.0 }, .text = " ", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 6, .position = .{ 0.0, 0.0 }, .text = "w", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 7, .position = .{ 0.0, 0.0 }, .text = "o", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 8, .position = .{ 0.0, 0.0 }, .text = "r", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 9, .position = .{ 0.0, 0.0 }, .text = "l", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 10, .position = .{ 0.0, 0.0 }, .text = "d", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
    };
    try testWrapConfiguration(.{
        .glyphs = &glyphs,
        .alignment = .topLeft,
        .mode = .word,
        .lineWidth = 60.0,
        .lineHeight = 20.0,
        .expectedPositions = &.{
            .{ 0.0, 0.0 }, // h
            .{ 10.0, 0.0 }, // e
            .{ 20.0, 0.0 }, // l
            .{ 30.0, 0.0 }, // l
            .{ 40.0, 0.0 }, // o
            .{ 50.0, 0.0 }, // (space)
            .{ 0.0, 20.0 }, // w
            .{ 10.0, 20.0 }, // o
            .{ 20.0, 20.0 }, // r
            .{ 30.0, 20.0 }, // l
            .{ 40.0, 20.0 }, // d
        },
    });
}

test "text wrapping - alignment start" {
    var glyphs = [_]LayoutGlyph{
        .{
            .index = 0,
            .position = .{ 0.0, 0.0 },
            .text = "a",
            .advance = .{ 20.0, 0.0 },
            .offset = .{ 0.0, 0.0 },
        },
    } ** 5;
    try testWrapConfiguration(.{
        .glyphs = &glyphs,
        .alignment = .topLeft,
        .mode = .character,
        .lineWidth = 45.0,
        .lineHeight = 20.0,
        .expectedPositions = &.{
            .{ 0.0, 0.0 },
            .{ 20.0, 0.0 },
            .{ 0.0, 20.0 },
            .{ 20.0, 20.0 },
            .{ 0.0, 40.0 },
        },
    });
}

test "text wrapping - alignment center" {
    var glyphs = [_]LayoutGlyph{
        .{
            .index = 0,
            .position = .{ 0.0, 0.0 },
            .text = "a",
            .advance = .{ 20.0, 0.0 },
            .offset = .{ 0.0, 0.0 },
        },
    } ** 5;
    try testWrapConfiguration(.{
        .glyphs = &glyphs,
        .alignment = .center,
        .mode = .character,
        .lineWidth = 45.0,
        .lineHeight = 20.0,
        .expectedPositions = &.{
            .{ 2.5, 0.0 }, // line offest 2.5 (45 - 20 * 2) / 2
            .{ 22.5, 0.0 },
            .{ 2.5, 20.0 }, // line offest 2.5 (45 - 20 * 2) / 2
            .{ 22.5, 20.0 },
            .{ 12.5, 40.0 }, // line offset 12.5 (45 - 20) / 2
        },
    });
}

test "text wrapping - alignment end" {
    var glyphs = [_]LayoutGlyph{
        .{
            .index = 0,
            .position = .{ 0.0, 0.0 },
            .text = "a",
            .advance = .{ 20.0, 0.0 },
            .offset = .{ 0.0, 0.0 },
        },
    } ** 5;
    try testWrapConfiguration(.{
        .glyphs = &glyphs,
        .alignment = .topRight,
        .mode = .character,
        .lineWidth = 45.0,
        .lineHeight = 20.0,
        .expectedPositions = &.{
            .{ 5.0, 0.0 }, // line offset 5 = 45 - 20 * 2
            .{ 25.0, 0.0 },
            .{ 5.0, 20.0 }, // line offset 5 = 45 - 20 * 2
            .{ 25.0, 20.0 },
            .{ 25.0, 40.0 }, // line offset 25 = 45 - 20
        },
    });
}

test "text wrapping - word wrapping with alignment start" {
    var glyphs = [_]LayoutGlyph{
        .{ .index = 0, .position = .{ 0.0, 0.0 }, .text = "h", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 1, .position = .{ 0.0, 0.0 }, .text = "e", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 2, .position = .{ 0.0, 0.0 }, .text = "l", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 3, .position = .{ 0.0, 0.0 }, .text = "l", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 4, .position = .{ 0.0, 0.0 }, .text = "o", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 5, .position = .{ 0.0, 0.0 }, .text = " ", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 6, .position = .{ 0.0, 0.0 }, .text = "w", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 7, .position = .{ 0.0, 0.0 }, .text = "o", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 8, .position = .{ 0.0, 0.0 }, .text = "r", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 9, .position = .{ 0.0, 0.0 }, .text = "l", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 10, .position = .{ 0.0, 0.0 }, .text = "d", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
    };
    try testWrapConfiguration(.{
        .glyphs = &glyphs,
        .alignment = .topLeft,
        .mode = .word,
        .lineWidth = 60.0,
        .lineHeight = 20.0,
        .expectedPositions = &.{
            .{ 0.0, 0.0 }, // h - Line 0 starts at x=0
            .{ 10.0, 0.0 }, // e
            .{ 20.0, 0.0 }, // l
            .{ 30.0, 0.0 }, // l
            .{ 40.0, 0.0 }, // o
            .{ 50.0, 0.0 }, // (space)
            .{ 0.0, 20.0 }, // w - Line 1 starts at x=0
            .{ 10.0, 20.0 }, // o
            .{ 20.0, 20.0 }, // r
            .{ 30.0, 20.0 }, // l
            .{ 40.0, 20.0 }, // d
        },
    });
}

test "text wrapping - word wrapping with alignment center" {
    var glyphs = [_]LayoutGlyph{
        .{ .index = 0, .position = .{ 0.0, 0.0 }, .text = "h", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 1, .position = .{ 0.0, 0.0 }, .text = "e", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 2, .position = .{ 0.0, 0.0 }, .text = "l", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 3, .position = .{ 0.0, 0.0 }, .text = "l", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 4, .position = .{ 0.0, 0.0 }, .text = "o", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 5, .position = .{ 0.0, 0.0 }, .text = " ", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 6, .position = .{ 0.0, 0.0 }, .text = "w", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 7, .position = .{ 0.0, 0.0 }, .text = "o", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 8, .position = .{ 0.0, 0.0 }, .text = "r", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 9, .position = .{ 0.0, 0.0 }, .text = "l", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 10, .position = .{ 0.0, 0.0 }, .text = "d", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
    };
    try testWrapConfiguration(.{
        .glyphs = &glyphs,
        .alignment = .center,
        .mode = .word,
        .lineWidth = 100.0,
        .lineHeight = 20.0,
        .expectedPositions = &.{
            // Expected: "hello" on line 0 (centered), space stays in place, "world" on line 1 (centered)
            .{ 20.0, 0.0 }, // h - placeholder, needs actual values
            .{ 30.0, 0.0 }, // e
            .{ 40.0, 0.0 }, // l
            .{ 50.0, 0.0 }, // l
            .{ 60.0, 0.0 }, // o
            .{ 70.0, 0.0 }, // (space)
            .{ 25.0, 20.0 }, // w
            .{ 35.0, 20.0 }, // o
            .{ 45.0, 20.0 }, // r
            .{ 55.0, 20.0 }, // l
            .{ 65.0, 20.0 }, // d
        },
    });
}

test "text wrapping - word wrapping with alignment end" {
    var glyphs = [_]LayoutGlyph{
        .{ .index = 0, .position = .{ 0.0, 0.0 }, .text = "h", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 1, .position = .{ 0.0, 0.0 }, .text = "e", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 2, .position = .{ 0.0, 0.0 }, .text = "l", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 3, .position = .{ 0.0, 0.0 }, .text = "l", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 4, .position = .{ 0.0, 0.0 }, .text = "o", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 5, .position = .{ 0.0, 0.0 }, .text = " ", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 6, .position = .{ 0.0, 0.0 }, .text = "w", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 7, .position = .{ 0.0, 0.0 }, .text = "o", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 8, .position = .{ 0.0, 0.0 }, .text = "r", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 9, .position = .{ 0.0, 0.0 }, .text = "l", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
        .{ .index = 10, .position = .{ 0.0, 0.0 }, .text = "d", .advance = .{ 10.0, 0.0 }, .offset = .{ 0.0, 0.0 } },
    };
    try testWrapConfiguration(.{
        .glyphs = &glyphs,
        .alignment = .topRight,
        .mode = .word,
        .lineWidth = 100.0,
        .lineHeight = 20.0,
        .expectedPositions = &.{
            // Expected: "hello" on line 0 (end-aligned), space stays in place, "world" on line 1 (end-aligned)
            .{ 40.0, 0.0 }, // h - placeholder, needs actual values
            .{ 50.0, 0.0 }, // e
            .{ 60.0, 0.0 }, // l
            .{ 70.0, 0.0 }, // l
            .{ 80.0, 0.0 }, // o
            .{ 90.0, 0.0 }, // (space)
            .{ 50.0, 20.0 }, // w
            .{ 60.0, 20.0 }, // o
            .{ 70.0, 20.0 }, // r
            .{ 80.0, 20.0 }, // l
            .{ 90.0, 20.0 }, // d
        },
    });
}

test "layout pipeline - text wrapping word wrap works with mounted text" {
    const measured = try layoutMountedText(.{
        .width = .fit,
        .textWrapping = .word,
        .content = "hello hello",
    });
    defer measured.deinit();

    const lineWidth = (measured.textNodeMinSize[0] + measured.textNodeSize[0]) / 2.0;

    const wrapped = try layoutMountedText(.{
        .width = .{ .fixed = lineWidth },
        .textWrapping = .word,
        .content = "hello hello",
    });
    defer wrapped.deinit();

    try std.testing.expectEqual(@as(usize, 2), lineCountFromGlyphPositions(wrapped.glyphPositions));
    try std.testing.expectApproxEqAbs(lineWidth, wrapped.rootSize[0], 0.01);
    try std.testing.expectApproxEqAbs(lineWidth, wrapped.textNodeSize[0], 0.01);
    try std.testing.expectApproxEqAbs(wrapped.lineHeight * 2.0, wrapped.rootSize[1], 0.01);
    try std.testing.expectApproxEqAbs(wrapped.lineHeight * 2.0, wrapped.textNodeSize[1], 0.01);
}

test "layout pipeline - text wrapping center alignment offsets narrower mounted lines" {
    const measured = try layoutMountedText(.{
        .width = .fit,
        .textWrapping = .word,
        .content = "hello hello",
    });
    defer measured.deinit();

    const lineWidth = (measured.textNodeMinSize[0] + measured.textNodeSize[0]) / 2.0;

    const wrapped = try layoutMountedText(.{
        .width = .{ .fixed = lineWidth },
        .alignment = .topCenter,
        .textWrapping = .word,
        .content = "hello hello",
    });
    defer wrapped.deinit();

    try std.testing.expectEqual(@as(usize, 2), lineCountFromGlyphPositions(wrapped.glyphPositions));

    const lineTwoStartX = secondLineStartX(wrapped.glyphPositions) orelse unreachable;
    try std.testing.expect(lineTwoStartX > wrapped.glyphPositions[0][0]);
    try std.testing.expect(lineTwoStartX >= wrapped.textNodePosition[0]);
}

test "layout pipeline - text wrapping character wrap works with mounted text" {
    const measured = try layoutMountedText(.{
        .width = .fit,
        .textWrapping = .character,
        .content = "aaaa",
    });
    defer measured.deinit();

    const lineWidth = (measured.textNodeMinSize[0] + measured.textNodeSize[0]) / 2.0;

    const wrapped = try layoutMountedText(.{
        .width = .{ .fixed = lineWidth },
        .textWrapping = .character,
        .content = "aaaa",
    });
    defer wrapped.deinit();

    try std.testing.expectEqual(@as(usize, 2), lineCountFromGlyphPositions(wrapped.glyphPositions));
    try std.testing.expectApproxEqAbs(wrapped.lineHeight * 2.0, wrapped.rootSize[1], 0.01);
    try std.testing.expectApproxEqAbs(wrapped.lineHeight * 2.0, wrapped.textNodeSize[1], 0.01);
}

test "ratio and grow passes are stable when reapplied" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var children = try std.ArrayList(Node).initCapacity(arenaAllocator, 2);
    children.appendAssumeCapacity(Node{
        .key = 1,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 0.0, 50.0 },
        .minSize = .{ 0.0, 0.0 },
        .maxSize = .{ std.math.inf(f32), 50.0 },
        .children = .{ .nodes = .empty },
        .style = (IncompleteStyle{
            .width = .{ .ratio = 0.2 },
            .height = .{ .fixed = 50.0 },
        }).completeWith(utilities.shallowBaseStyle),
    });
    children.appendAssumeCapacity(Node{
        .key = 2,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 0.0, 50.0 },
        .minSize = .{ 0.0, 0.0 },
        .maxSize = .{ std.math.inf(f32), 50.0 },
        .children = .{ .nodes = .empty },
        .style = (IncompleteStyle{
            .width = .grow,
            .height = .{ .fixed = 50.0 },
        }).completeWith(utilities.shallowBaseStyle),
    });

    var parent = Node{
        .key = 99,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 300.0, 50.0 },
        .minSize = .{ 300.0, 50.0 },
        .maxSize = .{ 300.0, 50.0 },
        .children = .{ .nodes = children },
        .style = (IncompleteStyle{
            .direction = .leftToRight,
            .width = .{ .fixed = 300.0 },
            .height = .{ .fixed = 50.0 },
        }).completeWith(utilities.shallowBaseStyle),
    };

    applyRatios(&parent);
    try growAndShrink(arenaAllocator, &parent);
    const firstRatio = parent.children.nodes.items[0].size[0];
    const firstGrow = parent.children.nodes.items[1].size[0];

    applyRatios(&parent);
    try growAndShrink(arenaAllocator, &parent);

    try std.testing.expectEqual(firstRatio, parent.children.nodes.items[0].size[0]);
    try std.testing.expectEqual(firstGrow, parent.children.nodes.items[1].size[0]);
    try std.testing.expectEqual(@as(f32, 10.0), parent.children.nodes.items[0].size[0]);
    try std.testing.expectEqual(@as(f32, 290.0), parent.children.nodes.items[1].size[0]);
}

test "layout pipeline - ratio and grow produce stable geometry" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var first: Node = undefined;
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .leftToRight,
            .width = .grow,
            .height = .{ .fixed = 100.0 },
        })({
            forbear.element(.{
                .width = .{ .ratio = 0.2 },
                .height = .grow,
            })({});
            forbear.element(.{
                .width = .grow,
                .height = .grow,
            })({});
        });
        first = (try layout()).*;
    });

    const firstChildren = try std.testing.allocator.dupe(Node, first.children.nodes.items);
    defer std.testing.allocator.free(firstChildren);
    try std.testing.expectEqual(@as(usize, 2), firstChildren.len);
    try std.testing.expectEqual(@as(f32, 800.0), first.size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), first.size[1]);

    try std.testing.expectEqual(@as(f32, 20.0), firstChildren[0].size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), firstChildren[0].size[1]);
    try std.testing.expectEqual(@as(f32, 0.0), firstChildren[0].position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), firstChildren[0].position[1]);

    try std.testing.expectEqual(@as(f32, 780.0), firstChildren[1].size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), firstChildren[1].size[1]);
    try std.testing.expectEqual(@as(f32, 20.0), firstChildren[1].position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), firstChildren[1].position[1]);

    _ = arena.reset(.retain_capacity);

    var second: Node = undefined;
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .leftToRight,
            .width = .grow,
            .height = .{ .fixed = 100.0 },
        })({
            forbear.element(.{
                .width = .{ .ratio = 0.2 },
                .height = .grow,
            })({});
            forbear.element(.{
                .width = .grow,
                .height = .grow,
            })({});
        });
        second = (try layout()).*;
    });
    const secondChildren = second.children.nodes.items;

    try std.testing.expectEqual(first.size[0], second.size[0]);
    try std.testing.expectEqual(first.size[1], second.size[1]);
    try std.testing.expectEqual(first.position[0], second.position[0]);
    try std.testing.expectEqual(first.position[1], second.position[1]);

    try std.testing.expectEqual(firstChildren[0].size[0], secondChildren[0].size[0]);
    try std.testing.expectEqual(firstChildren[0].size[1], secondChildren[0].size[1]);
    try std.testing.expectEqual(firstChildren[0].position[0], secondChildren[0].position[0]);
    try std.testing.expectEqual(firstChildren[0].position[1], secondChildren[0].position[1]);

    try std.testing.expectEqual(firstChildren[1].size[0], secondChildren[1].size[0]);
    try std.testing.expectEqual(firstChildren[1].size[1], secondChildren[1].size[1]);
    try std.testing.expectEqual(firstChildren[1].position[0], secondChildren[1].position[0]);
    try std.testing.expectEqual(firstChildren[1].position[1], secondChildren[1].position[1]);
}

test "layout pipeline - manual children stay out of flow" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var node: Node = undefined;
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .leftToRight,
            .width = .{ .fixed = 200.0 },
            .height = .{ .fixed = 100.0 },
        })({
            forbear.element(.{
                .width = .{ .ratio = 0.5 },
                .height = .grow,
            })({});
            forbear.element(.{
                .placement = .{ .manual = .{ 10.0, 7.0 } },
                .width = .{ .fixed = 15.0 },
                .height = .{ .fixed = 12.0 },
            })({});
            forbear.element(.{
                .width = .{ .fixed = 20.0 },
                .height = .grow,
            })({});
        });
        node = (try layout()).*;
    });

    try std.testing.expectEqual(@as(f32, 200.0), node.size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), node.size[1]);
    try std.testing.expectEqual(@as(f32, 0.0), node.position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), node.position[1]);

    const children = node.children.nodes.items;

    try std.testing.expectEqual(@as(usize, 3), children.len);

    try std.testing.expectEqual(@as(f32, 50.0), children[0].size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), children[0].size[1]);
    try std.testing.expectEqual(@as(f32, 0.0), children[0].position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), children[0].position[1]);

    try std.testing.expectEqual(@as(f32, 15.0), children[1].size[0]);
    try std.testing.expectEqual(@as(f32, 12.0), children[1].size[1]);
    try std.testing.expectEqual(@as(f32, 10.0), children[1].position[0]);
    try std.testing.expectEqual(@as(f32, 7.0), children[1].position[1]);

    try std.testing.expectEqual(@as(f32, 20.0), children[2].size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), children[2].size[1]);
    try std.testing.expectEqual(@as(f32, 50.0), children[2].position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), children[2].position[1]);
}

test "layout pipeline - vertical ratio and grow produce stable geometry" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var first: Node = undefined;
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .topToBottom,
            .width = .{ .fixed = 120.0 },
            .height = .{ .fixed = 300.0 },
        })({
            forbear.element(.{
                .width = .grow,
                .height = .{ .ratio = 0.5 },
            })({});
            forbear.element(.{
                .width = .grow,
                .height = .grow,
            })({});
        });
        first = (try layout()).*;
    });

    const firstsChildren = try std.testing.allocator.dupe(Node, first.children.nodes.items);
    defer std.testing.allocator.free(firstsChildren);
    try std.testing.expectEqual(@as(usize, 2), firstsChildren.len);
    try std.testing.expectEqual(@as(f32, 120.0), first.size[0]);
    try std.testing.expectEqual(@as(f32, 300.0), first.size[1]);
    try std.testing.expectEqual(@as(f32, 0.0), first.position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), first.position[1]);

    try std.testing.expectEqual(@as(f32, 120.0), firstsChildren[0].size[0]);
    try std.testing.expectEqual(@as(f32, 60.0), firstsChildren[0].size[1]);
    try std.testing.expectEqual(@as(f32, 0.0), firstsChildren[0].position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), firstsChildren[0].position[1]);

    try std.testing.expectEqual(@as(f32, 120.0), firstsChildren[1].size[0]);
    try std.testing.expectEqual(@as(f32, 240.0), firstsChildren[1].size[1]);
    try std.testing.expectEqual(@as(f32, 0.0), firstsChildren[1].position[0]);
    try std.testing.expectEqual(@as(f32, 60.0), firstsChildren[1].position[1]);

    _ = arena.reset(.retain_capacity);

    var second: Node = undefined;
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .topToBottom,
            .width = .{ .fixed = 120.0 },
            .height = .{ .fixed = 300.0 },
        })({
            forbear.element(.{
                .width = .grow,
                .height = .{ .ratio = 0.5 },
            })({});
            forbear.element(.{
                .width = .grow,
                .height = .grow,
            })({});
        });
        second = (try layout()).*;
    });
    const secondsChildren = second.children.nodes.items;

    try std.testing.expectEqual(first.size[0], second.size[0]);
    try std.testing.expectEqual(first.size[1], second.size[1]);
    try std.testing.expectEqual(first.position[0], second.position[0]);
    try std.testing.expectEqual(first.position[1], second.position[1]);

    try std.testing.expectEqual(firstsChildren[0].size[0], secondsChildren[0].size[0]);
    try std.testing.expectEqual(firstsChildren[0].size[1], secondsChildren[0].size[1]);
    try std.testing.expectEqual(firstsChildren[0].position[0], secondsChildren[0].position[0]);
    try std.testing.expectEqual(firstsChildren[0].position[1], secondsChildren[0].position[1]);

    try std.testing.expectEqual(firstsChildren[1].size[0], secondsChildren[1].size[0]);
    try std.testing.expectEqual(firstsChildren[1].size[1], secondsChildren[1].size[1]);
    try std.testing.expectEqual(firstsChildren[1].position[0], secondsChildren[1].position[0]);
    try std.testing.expectEqual(firstsChildren[1].position[1], secondsChildren[1].position[1]);
}

test "layout pipeline - manual ratio child stays out of flow" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var node: Node = undefined;
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .leftToRight,
            .width = .{ .fixed = 200.0 },
            .height = .{ .fixed = 100.0 },
        })({
            forbear.element(.{
                .width = .{ .ratio = 0.5 },
                .height = .grow,
            })({});
            forbear.element(.{
                .placement = .{ .manual = .{ 10.0, 7.0 } },
                .width = .{ .ratio = 0.5 },
                .height = .{ .fixed = 40.0 },
            })({});
            forbear.element(.{
                .width = .{ .fixed = 20.0 },
                .height = .grow,
            })({});
        });
        node = (try layout()).*;
    });
    const children = node.children.nodes.items;

    try std.testing.expectEqual(@as(usize, 3), children.len);

    try std.testing.expectEqual(@as(f32, 50.0), children[0].size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), children[0].size[1]);
    try std.testing.expectEqual(@as(f32, 0.0), children[0].position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), children[0].position[1]);

    try std.testing.expectEqual(@as(f32, 20.0), children[1].size[0]);
    try std.testing.expectEqual(@as(f32, 40.0), children[1].size[1]);
    try std.testing.expectEqual(@as(f32, 10.0), children[1].position[0]);
    try std.testing.expectEqual(@as(f32, 7.0), children[1].position[1]);

    try std.testing.expectEqual(@as(f32, 20.0), children[2].size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), children[2].size[1]);
    try std.testing.expectEqual(@as(f32, 50.0), children[2].position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), children[2].position[1]);
}

test "layout pipeline - ratio and shrink keep children within parent flow" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var first: Node = undefined;
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .leftToRight,
            .width = .{ .fixed = 40.0 },
            .height = .{ .fixed = 100.0 },
        })({
            forbear.element(.{
                .width = .{ .ratio = 0.5 },
                .height = .grow,
            })({});
            forbear.element(.{
                .width = .{ .fixed = 30.0 },
                .height = .grow,
            })({});
        });
        first = (try layout()).*;
    });
    const firstsChildren = try std.testing.allocator.dupe(Node, first.children.nodes.items);
    defer std.testing.allocator.free(firstsChildren);

    try std.testing.expectEqual(@as(usize, 2), firstsChildren.len);
    try std.testing.expectEqual(@as(f32, 40.0), first.size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), first.size[1]);

    try std.testing.expectEqual(@as(f32, 10.0), firstsChildren[0].size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), firstsChildren[0].size[1]);
    try std.testing.expectEqual(@as(f32, 0.0), firstsChildren[0].position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), firstsChildren[0].position[1]);

    try std.testing.expectEqual(@as(f32, 30.0), firstsChildren[1].size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), firstsChildren[1].size[1]);
    try std.testing.expectEqual(@as(f32, 10.0), firstsChildren[1].position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), firstsChildren[1].position[1]);

    _ = arena.reset(.retain_capacity);

    var second: Node = undefined;
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .leftToRight,
            .width = .{ .fixed = 40.0 },
            .height = .{ .fixed = 100.0 },
        })({
            forbear.element(.{
                .width = .{ .ratio = 0.5 },
                .height = .grow,
            })({});
            forbear.element(.{
                .width = .{ .fixed = 30.0 },
                .height = .grow,
            })({});
        });
        second = (try layout()).*;
    });
    const secondsChildren = second.children.nodes.items;

    try std.testing.expectEqual(firstsChildren[0].size[0], secondsChildren[0].size[0]);
    try std.testing.expectEqual(firstsChildren[1].size[0], secondsChildren[1].size[0]);
    try std.testing.expectEqual(firstsChildren[1].position[0], secondsChildren[1].position[0]);
}

test "layout pipeline - percentage sizes track parent axis" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var result: Node = undefined;
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .leftToRight,
            .width = .{ .fixed = 200.0 },
            .height = .{ .fixed = 100.0 },
        })({
            forbear.element(.{
                .width = .{ .percentage = 0.5 },
                .height = .{ .percentage = 0.25 },
            })({});
        });
        result = (try layout()).*;
    });
    const children = result.children.nodes.items;

    try std.testing.expectEqual(@as(usize, 1), children.len);
    try std.testing.expectEqual(@as(f32, 100.0), children[0].size[0]);
    try std.testing.expectEqual(@as(f32, 25.0), children[0].size[1]);
}
