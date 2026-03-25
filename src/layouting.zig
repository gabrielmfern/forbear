const std = @import("std");

const Alignment = @import("node.zig").Alignment;
const BaseStyle = @import("node.zig").BaseStyle;
const Direction = @import("node.zig").Direction;
const Element = @import("node.zig").Element;
const LayoutGlyph = @import("node.zig").LayoutGlyph;
const Glyphs = @import("node.zig").Glyphs;
const forbear = @import("root.zig");
const IncompleteStyle = @import("node.zig").IncompleteStyle;
const Node = @import("node.zig").Node;
const NodeTree = @import("node.zig").NodeTree;
const Sizing = @import("node.zig").Sizing;
const Style = @import("node.zig").Style;
const TextWrapping = @import("node.zig").TextWrapping;

const Vec4 = @Vector(4, f32);
const Vec3 = @Vector(3, f32);
const Vec2 = @Vector(2, f32);

fn approxEq(a: f32, b: f32) bool {
    return @abs(a - b) < 0.001;
}

fn growChildren(
    node: *Node,
    nodeTree: *const NodeTree,
    activelyModifying: *std.ArrayList(*Node),
    direction: Direction,
    remaining: *f32,
) void {
    var childIndexOption = node.firstChild;
    while (childIndexOption) |childIndex| {
        const child = nodeTree.at(childIndex);
        if (child.style.placement == .standard) {
            if (child.style.getPreferredSize(direction) == .grow and child.getSize(direction) < child.getMaxSize(direction)) {
                activelyModifying.appendAssumeCapacity(child);
            }
        }
        childIndexOption = child.nextSibling;
    }

    var iteration: usize = 0;
    while (remaining.* > 0.001 and activelyModifying.items.len > 0) {
        iteration += 1;
        var smallest: f32 = std.math.inf(f32);
        var secondSmallest = std.math.inf(f32);

        var index: usize = 0;
        while (index < activelyModifying.items.len) {
            const child = activelyModifying.items[index];
            if (approxEq(child.getSize(direction), child.getMaxSize(direction))) {
                _ = activelyModifying.orderedRemove(index);
                continue;
            }
            if (child.getSize(direction) < smallest and child.getSize(direction) < child.getMaxSize(direction)) {
                smallest = child.getSize(direction);
            } else if (child.getSize(direction) < secondSmallest and child.getSize(direction) < child.getMaxSize(direction)) {
                secondSmallest = child.getSize(direction);
            }
            index += 1;
        }
        if (activelyModifying.items.len == 0) {
            break;
        }

        // This ensures these two elements don't become so large that the remaining
        // space ends up not being shared across all of the elements
        var toAdd = @min(
            secondSmallest - smallest,
            remaining.* / @as(f32, @floatFromInt(activelyModifying.items.len)),
        );
        // This avoids an infinte loop. It means all the children are the same size and
        // we can simply share the remaining space across all of them
        if (toAdd == 0) {
            toAdd = remaining.* / @as(f32, @floatFromInt(activelyModifying.items.len));
        }
        const remainingBeforeLoop = remaining.*;
        for (activelyModifying.items) |child| {
            if (approxEq(child.getSize(direction), smallest)) {
                const allowedDifference = @min(
                    @max(child.getSize(direction) + toAdd, child.getMinSize(direction)),
                    child.getMaxSize(direction),
                ) - child.getSize(direction);
                if (direction == .leftToRight) {
                    child.size[0] += allowedDifference;
                } else {
                    child.size[1] += allowedDifference;
                }
                remaining.* -= allowedDifference;
            }
        }
        if (remaining.* == remainingBeforeLoop) {
            // This means that some constraint is impeding the growth
            // of the childen, so we do this to avoid an infinte loop
            break;
        }
    }
}

fn shrinkChildren(
    node: *Node,
    nodeTree: *const NodeTree,
    activelyModifying: *std.ArrayList(*Node),
    direction: Direction,
    remaining: *f32,
) void {
    if (remaining.* >= -0.001) {
        return;
    }

    activelyModifying.clearRetainingCapacity();
    var childIndexOption = node.firstChild;
    while (childIndexOption) |childIndex| {
        const child = nodeTree.at(childIndex);
        if (child.style.placement == .standard) {
            if (child.getSize(direction) > child.getMinSize(direction) and child.style.getPreferredSize(direction) != .percentage) {
                activelyModifying.appendAssumeCapacity(child);
            }
        }
        childIndexOption = child.nextSibling;
    }
    var iteration: usize = 0;
    while (remaining.* < -0.001 and activelyModifying.items.len > 0) {
        iteration += 1;

        var largest: f32 = activelyModifying.items[0].getSize(direction);
        var secondLargest: f32 = 0.0;

        var index: usize = 0;
        while (index < activelyModifying.items.len) {
            const child = activelyModifying.items[index];
            if (approxEq(child.getSize(direction), child.getMinSize(direction))) {
                _ = activelyModifying.orderedRemove(index);
                if (index == 0 and activelyModifying.items.len > 0) {
                    largest = activelyModifying.items[0].getSize(direction);
                }
                continue;
            }
            if (child.getSize(direction) > largest) {
                largest = child.getSize(direction);
            } else if (child.getSize(direction) > secondLargest) {
                secondLargest = child.getSize(direction);
            }
            index += 1;
        }
        if (activelyModifying.items.len == 0) {
            break;
        }

        var toSubtract = @min(
            largest - secondLargest,
            -remaining.* / @as(f32, @floatFromInt(activelyModifying.items.len)),
        );
        if (toSubtract == 0) {
            toSubtract = -remaining.* / @as(f32, @floatFromInt(activelyModifying.items.len));
        }
        const remainingBeforeLoop = remaining.*;
        for (activelyModifying.items) |child| {
            if (approxEq(child.getSize(direction), largest)) {
                const allowedDifference = @max(
                    child.getSize(direction) - toSubtract,
                    child.getMinSize(direction),
                ) - child.getSize(direction);
                if (direction == .leftToRight) {
                    child.size[0] += allowedDifference;
                } else {
                    child.size[1] += allowedDifference;
                }
                remaining.* -= allowedDifference;
            }
        }
        if (remaining.* == remainingBeforeLoop) {
            break;
        }
    }
}

/// Propagates a size change along one physical axis (`direction`) up through
/// `.fit` / `shouldFitMin` ancestors. Used by `wrapGlyphs` (via
/// `updateFittingForAncestors`) and by `growAndShrink` when ratio sizing
/// changes a child's main-axis contribution to its parent.
fn updateFittingForAncestorsInDirection(
    node: *Node,
    nodeTree: *const NodeTree,
    addition: f32,
    direction: Direction,
) void {
    if (node.style.placement != .standard) return;

    var currentAddition = addition;
    var currentMinSize = node.getMinSize(direction);
    var currentSize = node.getSize(direction);
    var currentMargin = node.style.margin.get(direction);

    var ancestorIndexOptional = node.parent;
    while (ancestorIndexOptional) |ancestorIndex| {
        const ancestor = nodeTree.at(ancestorIndex);

        const ancestorSize = ancestor.getSize(direction);
        const ancestorMinSize = ancestor.getMinSize(direction);
        const ancestorWraps = ancestor.style.overflow == .wrap and ancestor.style.direction == .leftToRight;

        const ancestorFittingBase = ancestor.fittingBase(direction);

        if (ancestor.shouldFitMin(direction)) {
            if (ancestor.style.direction == direction) {
                if (ancestorWraps) {
                    ancestor.setMinSize(direction, @max(
                        ancestorMinSize,
                        currentMinSize + currentMargin[0] + currentMargin[1] + ancestorFittingBase,
                    ));
                } else {
                    ancestor.addMinSize(direction, currentAddition);
                }
            } else {
                ancestor.setMinSize(direction, @max(
                    ancestorMinSize,
                    currentMinSize + currentMargin[0] + currentMargin[1] + ancestorFittingBase,
                ));
            }
        }

        if (ancestor.style.getPreferredSize(direction) == .fit) {
            if (ancestor.style.direction == direction) {
                if (ancestorWraps) {
                    ancestor.setSize(direction, @max(
                        ancestorSize,
                        currentSize + currentMargin[0] + currentMargin[1] + ancestorFittingBase,
                    ));
                } else {
                    ancestor.addSize(direction, currentAddition);
                }
            } else {
                ancestor.setSize(direction, @max(
                    ancestorSize,
                    currentSize + currentMargin[0] + currentMargin[1] + ancestorFittingBase,
                ));
                if (ancestorWraps) {
                    break;
                }
            }

            currentAddition = ancestor.getSize(direction) - ancestorSize;

            const perpendicularDirection = direction.perpendicular();
            const perpendicularPreferredSize = ancestor.style.getPreferredSize(perpendicularDirection);
            if (perpendicularPreferredSize == .ratio) {
                ancestor.setSize(perpendicularDirection, ancestorSize * perpendicularPreferredSize.ratio);
            }

            currentSize = ancestor.getSize(direction);
            currentMinSize = ancestor.getMinSize(direction);
            currentMargin = ancestor.style.margin.get(direction);
        } else {
            break;
        }

        ancestorIndexOptional = ancestor.parent;
    }
}

pub fn growAndShrink(
    arena: std.mem.Allocator,
    node: *Node,
    nodeTree: *NodeTree,
) !void {
    const direction = node.style.direction;

    var childIndexOption = node.firstChild;
    var childCount: usize = 0;
    var remaining = node.getSize(direction) - node.fittingBase(direction);
    while (childIndexOption) |childIndex| {
        const child = nodeTree.at(childIndex);
        childCount += 1;

        if (child.style.placement == .standard) {
            if (direction.perpendicular() == .topToBottom) {
                const available = node.size[1] - node.fittingBase(.topToBottom);
                if (child.style.height == .grow or (child.size[1] > available and child.minSize[1] < child.size[1])) {
                    child.size[1] = @max(@min(available, child.maxSize[1]), child.minSize[1]);
                }
            } else if (direction.perpendicular() == .leftToRight) {
                const available = node.size[0] - node.fittingBase(.leftToRight);
                if (child.style.width == .grow or (child.size[0] > available and child.minSize[0] < child.size[0])) {
                    child.size[0] = @max(@min(available, child.maxSize[0]), child.minSize[0]);
                }
            }
            if (child.style.width == .percentage) {
                child.size[0] = child.style.width.percentage * node.size[0];
            }
            if (child.style.height == .percentage) {
                child.size[1] = child.style.height.percentage * node.size[1];
            }
            const marginVector = child.style.margin.get(direction);
            remaining -= child.getSize(direction) + marginVector[0] + marginVector[1];
        }
        childIndexOption = child.nextSibling;
    }

    var activelyModifying = try std.ArrayList(*Node).initCapacity(arena, childCount);
    growChildren(node, nodeTree, &activelyModifying, direction, &remaining);
    shrinkChildren(node, nodeTree, &activelyModifying, direction, &remaining);

    childIndexOption = node.firstChild;
    while (childIndexOption) |childIndex| {
        const child = nodeTree.at(childIndex);

        // Ratio axes depend on the opposite axis which may have just been
        // resolved by grow/shrink or perpendicular clamping above.
        const beforeMain = child.getSize(direction);
        if (child.style.width == .ratio) {
            child.size[0] = child.size[1] * child.style.width.ratio;
        }
        if (child.style.height == .ratio) {
            child.size[1] = child.size[0] * child.style.height.ratio;
        }
        const afterMain = child.getSize(direction);
        const mainDelta = afterMain - beforeMain;
        if (!approxEq(mainDelta, 0)) {
            updateFittingForAncestorsInDirection(child, nodeTree, mainDelta, direction);
        }

        try growAndShrink(arena, child, nodeTree);

        childIndexOption = child.nextSibling;
    }
}

pub fn wrapGlyphs(arena: std.mem.Allocator, node: *Node, nodeTree: *const NodeTree, base: Vec2) !void {
    std.debug.assert(node.glyphs != null);
    if (node.style.textWrapping == .none) {
        return;
    }

    const glyphs = node.glyphs.?;

    const Line = struct {
        start: usize,
        end: usize,
    };
    var lines = try std.ArrayList(Line).initCapacity(arena, 4);

    const lineEnd = node.size[0];
    var cursor: Vec2 = @splat(0.0);
    var lineStartIndex: usize = 0;
    switch (node.style.textWrapping) {
        .character => {
            for (glyphs.slice, 0..) |*glyph, index| {
                if (cursor[0] + glyph.advance[0] > lineEnd) {
                    try lines.append(arena, .{
                        .start = lineStartIndex,
                        .end = index - 1,
                    });
                    lineStartIndex = index;
                    cursor[0] = 0.0;
                    cursor[1] += glyphs.lineHeight;
                }

                glyph.position = base + cursor + glyph.offset;
                cursor += glyph.advance;
            }
        },
        .word => {
            var lastSpaceInfoOpt: ?struct {
                index: usize,
                position: Vec2,
            } = null;
            for (glyphs.slice, 0..) |*glyph, index| {
                if (cursor[0] + glyph.advance[0] > lineEnd) {
                    if (lastSpaceInfoOpt) |lastSpaceInfo| {
                        const firstWordGlyph = glyphs.slice[lastSpaceInfo.index + 1];
                        try lines.append(arena, .{
                            .start = lineStartIndex,
                            .end = lastSpaceInfo.index,
                        });
                        lineStartIndex = lastSpaceInfo.index + 1;
                        cursor[0] = 0.0;
                        cursor[1] += glyphs.lineHeight;

                        for (lastSpaceInfo.index + 1..index) |reverseIndex| {
                            const reverseGlyph = &glyphs.slice[reverseIndex];
                            reverseGlyph.position[0] -= firstWordGlyph.position[0] - base[0];
                            reverseGlyph.position[1] += glyphs.lineHeight;

                            cursor += reverseGlyph.advance;
                        }
                        lastSpaceInfoOpt = null;
                    }
                }

                glyph.position = base + cursor + glyph.offset;
                cursor += glyph.advance;
                if (std.mem.eql(u8, glyph.text, " ")) {
                    lastSpaceInfoOpt = .{
                        .index = index,
                        .position = glyph.position,
                    };
                }
            }
        },
        else => unreachable,
    }
    if (lines.getLastOrNull()) |lastLine| {
        if (lastLine.end != glyphs.slice.len - 1) {
            try lines.append(arena, .{
                .start = lastLine.end + 1,
                .end = glyphs.slice.len - 1,
            });
        }
    } else {
        try lines.append(arena, .{
            .start = 0,
            .end = glyphs.slice.len - 1,
        });
    }
    for (lines.items) |line| {
        const startX = glyphs.slice[line.start].position[0];
        const endX = glyphs.slice[line.end].position[0] + glyphs.slice[line.end].advance[0];
        const width = endX - startX;
        for (glyphs.slice[line.start .. line.end + 1]) |*glyph| {
            switch (node.style.alignment.x) {
                .start => {},
                .center => glyph.position[0] += (lineEnd - width) / 2.0,
                .end => glyph.position[0] += lineEnd - width,
            }
        }
    }

    const previousHeight = node.size[1];
    node.size[1] = cursor[1] + glyphs.lineHeight;
    if (previousHeight != node.size[1]) {
        if (node.style.width == .ratio) {
            node.size[0] = node.size[1] * node.style.width.ratio;
        }
        updateFittingForAncestors(node, nodeTree, node.size[1] - previousHeight);
    }
}

/// Runs `updateFittingForAncestorsInDirection` for both axes with the same `addition`
/// (used after glyph wrapping changes text height; width ratio on the node is
/// applied before this runs from `wrapGlyphs`).
pub fn updateFittingForAncestors(node: *Node, nodeTree: *const NodeTree, addition: f32) void {
    if (node.style.placement != .standard) return;
    inline for (Direction.array) |direction| {
        updateFittingForAncestorsInDirection(node, nodeTree, addition, direction);
    }
}

/// does not change the size of children, but recursively updates the sizes of parents
pub fn wrapAndPlace(arena: std.mem.Allocator, node: *Node, nodeTree: *const NodeTree) !void {
    const base = Vec2{
        node.style.padding.x[0],
        node.style.padding.y[0],
    };

    // TODO: find a way to not have ambiguity between children and glyphs
    if (node.glyphs != null) {
        try wrapGlyphs(arena, node, nodeTree, base);
    } else {
        if (node.style.direction == .leftToRight) {
            const Line = struct {
                start: usize,
                end: usize,
                width: f32,
                height: f32,
            };

            if (node.firstChild) |firstChildIndex| {
                // Save height before processing children so we can compute
                // the correct total change for wrapping containers.
                const preWrapHeight = node.size[1];
                var cursor = base;
                var lines = std.ArrayList(Line).empty;
                var currentLine = Line{ .start = firstChildIndex, .end = firstChildIndex, .width = 0.0, .height = 0.0 };
                // Height additions from element wrapping (overflow: wrap) that
                // have not yet been propagated to ancestors. Descendant text
                // wrapping propagates its own height changes via wrapGlyphs →
                // updateFittingForAncestors, so we must not re-propagate those.
                var wrapHeightAddition: f32 = 0.0;

                var childIndexOption = node.firstChild;
                while (childIndexOption) |childIndex| {
                    const child = nodeTree.at(childIndex);
                    try wrapAndPlace(arena, child, nodeTree);

                    if (child.style.placement == .standard) {
                        const childOuterWidth = child.style.margin.x[0] + child.size[0] + child.style.margin.x[1];
                        const childOuterHeight = child.style.margin.y[0] + child.size[1] + child.style.margin.y[1];

                        if (node.style.overflow == .wrap) {
                            const remainingSpace = node.size[0] - (cursor[0] + node.style.padding.x[1]);
                            if (childOuterWidth > remainingSpace) {
                                const addition = currentLine.height + child.style.margin.y[0];
                                cursor[1] += addition;
                                // TODO: where does the bottom margin get used in this flow? I believe we're missing something
                                node.size[1] += addition;
                                wrapHeightAddition += addition;
                                if (node.style.width == .ratio) {
                                    node.size[0] = node.size[1] * node.style.width.ratio;
                                }
                                cursor[0] = base[0];
                                try lines.append(arena, currentLine);

                                currentLine = .{ .start = currentLine.end, .end = currentLine.end, .width = 0, .height = 0 };
                            }
                        }

                        cursor[0] += child.style.margin.x[0];
                        child.position = cursor;
                        cursor[0] += child.size[0] + child.style.margin.x[1];

                        currentLine.width += childOuterWidth;
                        currentLine.height = @max(currentLine.height, childOuterHeight);
                    }

                    currentLine.end = childIndex;
                    childIndexOption = child.nextSibling;
                }
                try lines.append(arena, currentLine);

                if (node.style.overflow == .wrap) {
                    // Compute authoritative height from actual line data.
                    // Text wrapping propagation via updateFittingForAncestors
                    // stops at the wrapping container, so we compute the correct
                    // total here: fitting base + all wrap additions (previous
                    // lines + inter-line margins) + last line's height.
                    node.size[1] = node.fittingBase(.topToBottom) + wrapHeightAddition + currentLine.height;
                    if (node.style.width == .ratio) {
                        node.size[0] = node.size[1] * node.style.width.ratio;
                    }
                    const totalChange = node.size[1] - preWrapHeight;
                    if (totalChange > 0.001) {
                        updateFittingForAncestors(node, nodeTree, totalChange);
                    }
                } else if (wrapHeightAddition > 0.001) {
                    updateFittingForAncestors(node, nodeTree, wrapHeightAddition);
                }

                const availableWidth = node.size[0] - node.style.padding.x[0] - node.style.padding.x[1];
                for (lines.items) |line| {
                    const xOffset: f32 = switch (node.style.alignment.x) {
                        .start => 0.0,
                        .center => (availableWidth - line.width) / 2.0,
                        .end => availableWidth - line.width,
                    };
                    childIndexOption = line.start;
                    while (childIndexOption) |childIndex| {
                        const child = nodeTree.at(childIndex);
                        if (child.style.placement == .standard) {
                            child.position[0] += xOffset;
                            child.position[1] += switch (node.style.alignment.y) {
                                .start => 0.0,
                                .center => (line.height - child.size[1]) / 2.0,
                                .end => line.height - child.size[1],
                            };
                        }
                        childIndexOption = child.nextSibling;
                        if (child.nextSibling == line.end) {
                            break;
                        }
                    }
                }
            }
        } else {
            var cursor = base;

            var childIndexOption = node.firstChild;
            while (childIndexOption) |childIndex| {
                const child = nodeTree.at(childIndex);
                try wrapAndPlace(arena, child, nodeTree);

                if (child.style.placement == .standard) {
                    cursor[1] += child.style.margin.y[0];
                    child.position = cursor;
                    cursor[1] += child.size[1] + child.style.margin.y[1];
                }
                childIndexOption = child.nextSibling;
            }

            const contentHeight = cursor[1] - base[1];
            const availableWidth = node.size[0] - node.style.padding.x[0] - node.style.padding.x[1];
            const availableHeight = node.size[1] - node.style.padding.y[0] - node.style.padding.y[1];
            const yOffset: f32 = switch (node.style.alignment.y) {
                .start => 0.0,
                .center => (availableHeight - contentHeight) / 2.0,
                .end => availableHeight - contentHeight,
            };
            childIndexOption = node.firstChild;
            while (childIndexOption) |childIndex| {
                const child = nodeTree.at(childIndex);
                if (child.style.placement == .standard) {
                    child.position[0] += switch (node.style.alignment.x) {
                        .start => 0.0,
                        .center => (availableWidth - child.size[0]) / 2.0,
                        .end => availableWidth - child.size[0],
                    };
                    child.position[1] += yOffset;
                }
                childIndexOption = child.nextSibling;
            }
        }
    }
}

pub fn layout() !*NodeTree {
    const context = forbear.getContext();

    std.debug.assert(context.frameMeta != null);
    if (context.frameMeta.?.err) |err| return err;
    const viewportSize = context.frameMeta.?.viewportSize;
    const arena = context.frameMeta.?.arena;

    if (context.nodeTree.list.items.len > 0) {
        const root = context.nodeTree.at(0);

        if (root.style.width == .grow) {
            root.size[0] = @min(@max(viewportSize[0], root.minSize[0]), root.maxSize[0]);
        }
        if (root.style.height == .grow) {
            root.size[1] = @min(@max(viewportSize[1], root.minSize[1]), root.maxSize[1]);
        }

        try growAndShrink(arena, root, &context.nodeTree);
        try wrapAndPlace(arena, root, &context.nodeTree);

        root.position -= context.effectiveScrollPosition;
        root.position += root.style.translate;

        var walker = context.nodeTree.walk();
        while (walker.next()) |node| {
            var childIndexOption = node.firstChild;
            while (childIndexOption) |childIndex| {
                const child = context.nodeTree.at(childIndex);

                if (child.style.placement == .manual) {
                    child.position += child.style.translate;
                } else {
                    child.position += node.position + child.style.translate;
                }
                if (child.glyphs) |glyphs| {
                    for (glyphs.slice) |*glyph| {
                        glyph.position += child.position;
                    }
                }

                childIndexOption = child.nextSibling;
            }
        }
    }

    return &context.nodeTree;
}
