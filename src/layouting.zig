const std = @import("std");

const Alignment = @import("node.zig").Alignment;
const BaseStyle = @import("node.zig").BaseStyle;
const Direction = @import("node.zig").Direction;
const Element = @import("node.zig").Element;
const LayoutGlyph = @import("node.zig").LayoutGlyph;
const Glyphs = @import("node.zig").Glyphs;
const forbear = @import("root.zig");
const Style = @import("node.zig").Style;
const Node = @import("node.zig").Node;
const NodeTree = @import("node.zig").NodeTree;
const Sizing = @import("node.zig").Sizing;
const CompleteStyle = @import("node.zig").CompleteStyle;
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
    // Collect grow children and reset them to 0, reclaiming their full space.
    // This allows us to distribute the TOTAL available space proportionally
    // (like CSS Grid fr units), rather than remaining space on top of content.
    var childIndexOption = node.firstChild;
    while (childIndexOption) |childIndex| {
        const child = nodeTree.at(childIndex);
        if (child.style.placement == .flow) {
            const factor = child.style.getPreferredSize(direction).growFactor();
            // Only include children with positive grow factors; grow: 0.0 means
            // "don't grow" so we leave those at their current size.
            if (factor > 0.0) {
                const currentSize = child.getSize(direction);
                // Reclaim the full size back into remaining
                remaining.* += currentSize;
                // Reset child to 0; the distribution loop handles minSize constraints
                if (direction == .horizontal) {
                    child.size[0] = 0;
                } else {
                    child.size[1] = 0;
                }
                if (child.getMaxSize(direction) > 0) {
                    activelyModifying.appendAssumeCapacity(child);
                }
            }
        }
        childIndexOption = child.nextSibling;
    }

    if (forbear.traceWriter) |w| {
        w.print("[grow] node={d} dir={s} remaining={d:.1} candidates={d}\n", .{
            node.key, @tagName(direction), remaining.*, activelyModifying.items.len,
        }) catch {};
    }

    while (remaining.* > 0.001 and activelyModifying.items.len > 0) {
        // Sum factors and find the smallest capacity-per-unit across candidates.
        // "capacity-per-unit" is how much a child can still grow divided by its
        // factor; the minimum across all candidates caps how far we can advance
        // in this pass before one of them hits maxSize.
        var totalFactor: f32 = 0.0;
        var smallestCapPerUnit: f32 = std.math.inf(f32);

        var index: usize = 0;
        while (index < activelyModifying.items.len) {
            const child = activelyModifying.items[index];
            if (approxEq(child.getSize(direction), child.getMaxSize(direction))) {
                _ = activelyModifying.swapRemove(index);
                continue;
            }
            const factor = child.style.getPreferredSize(direction).growFactor();
            totalFactor += factor;
            const capPerUnit = (child.getMaxSize(direction) - child.getSize(direction)) / factor;
            if (capPerUnit < smallestCapPerUnit) {
                smallestCapPerUnit = capPerUnit;
            }
            index += 1;
        }
        if (activelyModifying.items.len == 0) break;
        if (totalFactor <= 0.0) break;

        // Advance by at most smallestCapPerUnit units (so no child exceeds its
        // max), and at most remaining/totalFactor (so we don't overshoot the
        // available space).
        const toAddPerUnit = @min(smallestCapPerUnit, remaining.* / totalFactor);
        if (toAddPerUnit <= 0.0) break;

        const remainingBeforeLoop = remaining.*;
        for (activelyModifying.items) |child| {
            const factor = child.style.getPreferredSize(direction).growFactor();
            const oldSize = child.getSize(direction);
            const allowedDifference = @min(
                @max(oldSize + toAddPerUnit * factor, child.getMinSize(direction)),
                child.getMaxSize(direction),
            ) - oldSize;
            if (direction == .horizontal) {
                child.size[0] += allowedDifference;
            } else {
                child.size[1] += allowedDifference;
            }
            remaining.* -= allowedDifference;
            if (forbear.traceWriter) |w| {
                w.print("[grow]   child={d} factor={d:.1} {d:.1} -> {d:.1}\n", .{
                    child.key, factor, oldSize, child.getSize(direction),
                }) catch {};
            }
        }
        if (remaining.* == remainingBeforeLoop) {
            // Some constraint is impeding all children; avoid an infinite loop.
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
        if (child.style.placement == .flow) {
            if (child.getSize(direction) > child.getMinSize(direction)) {
                activelyModifying.appendAssumeCapacity(child);
            }
        }
        childIndexOption = child.nextSibling;
    }
    if (forbear.traceWriter) |w| {
        w.print("[shrink] node={d} dir={s} remaining={d:.1} candidates={d}\n", .{
            node.key, @tagName(direction), remaining.*, activelyModifying.items.len,
        }) catch {};
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
                _ = activelyModifying.swapRemove(index);
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
                const oldSize = child.getSize(direction);
                const allowedDifference = @max(
                    oldSize - toSubtract,
                    child.getMinSize(direction),
                ) - oldSize;
                if (direction == .horizontal) {
                    child.size[0] += allowedDifference;
                } else {
                    child.size[1] += allowedDifference;
                }
                remaining.* -= allowedDifference;
                if (forbear.traceWriter) |w| {
                    w.print("[shrink]   child={d} {d:.1} -> {d:.1}\n", .{
                        child.key, oldSize, child.getSize(direction),
                    }) catch {};
                }
            }
        }
        if (remaining.* == remainingBeforeLoop) {
            break;
        }
    }
}

/// Computes fit sizes bottom-up from the complete tree.
///
/// This is called at the start of layout() to compute initial fit sizes, and
/// again after layout passes that may change child sizes (text wrapping,
/// grow distribution).
///
/// Processing order:
/// 1. Children first (post-order traversal)
/// 2. Reset container sizes to base (padding + border)
/// 3. Accumulate child sizes via fitChild
///
/// Preserves:
/// - Leaf/text node sizes (content-derived, not from children)
/// - Wrap container sizes (computed specially by wrapAndPlace)
pub fn fit(node: *Node, nodeTree: *NodeTree) void {
    const shouldReset = node.firstChild != null and
        node.glyphs == null and
        node.style.overflow != .wrap;

    if (shouldReset) {
        inline for (Direction.array) |fitDirection| {
            if (node.style.getPreferredSize(fitDirection) == .fit) {
                node.setSize(fitDirection, node.fittingBase(fitDirection));
            }
            if (node.shouldFitMin(fitDirection)) {
                node.setMinSize(fitDirection, node.fittingBase(fitDirection));
            }
        }

        var childIndexOption = node.firstChild;
        while (childIndexOption) |childIndex| {
            const child = nodeTree.at(childIndex);
            fit(child, nodeTree);
            node.fitChild(child);
            childIndexOption = child.nextSibling;
        }
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

        if (child.style.placement == .flow) {
            // Ensure minSize doesn't exceed maxSize before using it
            child.minSize[0] = @min(child.minSize[0], child.maxSize[0]);
            child.minSize[1] = @min(child.minSize[1], child.maxSize[1]);

            if (direction.perpendicular() == .vertical) {
                const available = node.size[1] - node.fittingBase(.vertical) - child.style.margin.y[0] - child.style.margin.y[1];
                if (child.style.height.isGrow() or (child.size[1] > available and child.minSize[1] < child.size[1])) {
                    child.size[1] = @max(
                        @min(
                            available,
                            child.maxSize[1],
                        ),
                        child.minSize[1],
                    );
                }
            } else if (direction.perpendicular() == .horizontal) {
                const available = node.size[0] - node.fittingBase(.horizontal) - child.style.margin.x[0] - child.style.margin.x[1];
                if (child.style.width.isGrow() or (child.size[0] > available and child.minSize[0] < child.size[0])) {
                    child.size[0] = @max(
                        @min(
                            available,
                            child.maxSize[0],
                        ),
                        child.minSize[0],
                    );
                }
            }
            remaining -= child.getOuterSize(direction);
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
        if (child.style.width == .ratio) {
            child.size[0] = child.size[1] * child.style.width.ratio;
        }
        if (child.style.height == .ratio) {
            child.size[1] = child.size[0] * child.style.height.ratio;
        }

        try growAndShrink(arena, child, nodeTree);

        childIndexOption = child.nextSibling;
    }
}

fn wrapGlyphs(arena: std.mem.Allocator, node: *Node, base: Vec2) !void {
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

    const lineEnd = node.size[0] - node.fittingBase(.horizontal);
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
            switch (node.style.xJustification) {
                .start => {},
                .center => glyph.position[0] += (lineEnd - width) / 2.0,
                .end => glyph.position[0] += lineEnd - width,
            }
        }
    }

    node.size[1] = cursor[1] + glyphs.lineHeight;
    if (node.style.width == .ratio) {
        node.size[0] = node.size[1] * node.style.width.ratio;
    }
}

/// Wraps text and positions children. Also updates container heights to fit
/// content so sibling positioning works correctly.
pub fn wrapAndPlace(arena: std.mem.Allocator, node: *Node, nodeTree: *const NodeTree) !void {
    const base = Vec2{
        node.style.borderWidth.x[0] + node.style.padding.x[0],
        node.style.borderWidth.y[0] + node.style.padding.y[0],
    };

    // TODO: find a way to not have duplicate code between children and glyphs
    if (node.glyphs != null) {
        try wrapGlyphs(arena, node, base);
    } else {
        if (node.style.direction == .horizontal) {
            const Line = struct {
                start: usize,
                end: usize,
                width: f32,
                height: f32,
            };

            if (node.firstChild) |firstChildIndex| {
                var cursor = base;
                var lines = std.ArrayList(Line).empty;
                var currentLine = Line{ .start = firstChildIndex, .end = firstChildIndex, .width = 0.0, .height = 0.0 };
                var wrapHeightAddition: f32 = 0.0;

                var childIndexOption = node.firstChild;
                while (childIndexOption) |childIndex| {
                    const child = nodeTree.at(childIndex);
                    try wrapAndPlace(arena, child, nodeTree);

                    if (child.style.placement == .flow) {
                        const childOuterWidth = child.style.margin.x[0] + child.size[0] + child.style.margin.x[1];
                        const childOuterHeight = child.style.margin.y[0] + child.size[1] + child.style.margin.y[1];

                        if (node.style.overflow == .wrap) {
                            const remainingSpace = node.size[0] - cursor[0] - node.style.borderWidth.x[1] - node.style.padding.x[1];
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

                                // New line starts at the overflow child; .end is still the prior line until assigned below.
                                currentLine = .{ .start = childIndex, .end = childIndex, .width = 0, .height = 0 };
                            }
                        }

                        cursor[0] += child.style.margin.x[0];
                        child.position = cursor + Vec2{ 0, child.style.margin.y[0] };
                        cursor[0] += child.size[0] + child.style.margin.x[1];

                        currentLine.width += childOuterWidth;
                        currentLine.height = @max(currentLine.height, childOuterHeight);
                    }

                    currentLine.end = childIndex;
                    childIndexOption = child.nextSibling;
                }
                try lines.append(arena, currentLine);

                if (node.style.overflow == .wrap) {
                    // Wrap containers: height = base + wrapped lines + last line
                    node.size[1] = node.fittingBase(.vertical) + wrapHeightAddition + currentLine.height;
                    if (node.style.width == .ratio) {
                        node.size[0] = node.size[1] * node.style.width.ratio;
                    }
                } else if (node.style.height == .fit or node.style.height.isGrow()) {
                    // Non-wrap: expand height to fit tallest child
                    const newHeight = node.fittingBase(.vertical) + currentLine.height;
                    node.size[1] = @max(node.size[1], newHeight);
                }

                const availableWidth = node.size[0] - node.fittingBase(.horizontal);
                const availableHeight = node.size[1] - node.fittingBase(.vertical);
                for (lines.items) |line| {
                    const xOffset: f32 = switch (node.style.xJustification) {
                        .start => 0.0,
                        .center => (availableWidth - line.width) / 2.0,
                        .end => availableWidth - line.width,
                    };
                    // For single-line containers, align children within the
                    // full available height so .center/.end work when the
                    // parent is taller than its content. For multi-line
                    // (wrapping), align within each line's height.
                    const alignHeight = if (lines.items.len == 1) @max(line.height, availableHeight) else line.height;
                    childIndexOption = line.start;
                    while (childIndexOption) |childIndex| {
                        const child = nodeTree.at(childIndex);
                        if (child.style.placement == .flow) {
                            child.position[0] += xOffset;
                            child.position[1] += switch (node.style.yJustification) {
                                .start => 0.0,
                                .center => (alignHeight - child.size[1]) / 2.0,
                                .end => alignHeight - child.size[1],
                            };
                        }
                        if (childIndex == line.end) break;
                        childIndexOption = child.nextSibling;
                    }
                }
            }
        } else {
            var cursor = base;

            var childIndexOption = node.firstChild;
            while (childIndexOption) |childIndex| {
                const child = nodeTree.at(childIndex);
                try wrapAndPlace(arena, child, nodeTree);

                if (child.style.placement == .flow) {
                    cursor[1] += child.style.margin.y[0];
                    child.position = cursor;
                    cursor[1] += child.size[1] + child.style.margin.y[1];
                }
                childIndexOption = child.nextSibling;
            }

            const contentHeight = cursor[1] - base[1];

            // Update fit containers to match content (needed before parent positions siblings)
            if (node.style.height == .fit or node.style.height.isGrow()) {
                const newHeight = node.fittingBase(.vertical) + contentHeight;
                node.size[1] = @max(node.size[1], newHeight);
            }
            const availableWidth = node.size[0] - node.fittingBase(.horizontal);
            const availableHeight = node.size[1] - node.fittingBase(.vertical);
            const yOffset: f32 = switch (node.style.yJustification) {
                .start => 0.0,
                .center => (availableHeight - contentHeight) / 2.0,
                .end => availableHeight - contentHeight,
            };
            childIndexOption = node.firstChild;
            while (childIndexOption) |childIndex| {
                const child = nodeTree.at(childIndex);
                if (child.style.placement == .flow) {
                    child.position[0] += switch (node.style.xJustification) {
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

        fit(root, &context.nodeTree);

        if (root.style.width.isGrow()) {
            root.size[0] = @min(@max(viewportSize[0], root.minSize[0]), root.maxSize[0]);
        }
        if (root.style.height.isGrow()) {
            root.size[1] = @min(@max(viewportSize[1], root.minSize[1]), root.maxSize[1]);
        }

        try growAndShrink(arena, root, &context.nodeTree);
        try wrapAndPlace(arena, root, &context.nodeTree);
        // wrap and place invalidates growth, at least perpendicular growth we
        // can change this to just do perpendicular growth and things would
        // work as expected
        try growAndShrink(arena, root, &context.nodeTree);
        // growth invalidates fitting, so we need to re-apply fitting after
        // growth to ensure things like text-wrapping containers get the
        // correct size for their content before placement
        fit(root, &context.nodeTree);
        // the fitting and growth invalidate the placement of elements, but not
        // necessarily the wrapping. we only call this because they're
        // inherently connected
        try wrapAndPlace(arena, root, &context.nodeTree);

        root.position -= context.scrollPosition;
        root.position += root.style.translate;

        var walker = context.nodeTree.walk();
        while (walker.next()) |node| {
            var childIndexOption = node.firstChild;
            while (childIndexOption) |childIndex| {
                const child = context.nodeTree.at(childIndex);

                switch (child.style.placement) {
                    // Viewport-pinned: ignore scroll and ancestor offsets.
                    .fixed => child.position += child.style.translate,
                    // Viewport-space but scroll-aware: the root's resolved
                    // position already contains `-scrollPosition` plus the
                    // root's own translate, so adding it gives document-space
                    // placement that scrolls with the page.
                    .absolute => child.position += root.position + child.style.translate,
                    // Parent-relative: the user-supplied Vec2 is an offset
                    // from the parent's top-left corner. `.flow` children
                    // have their `child.position` computed by wrapAndPlace;
                    // `.relative` children use the Vec2 stashed at element
                    // creation time. Both paths then adopt the parent's
                    // resolved position, so they inherit ancestor offsets
                    // and scroll naturally.
                    .flow, .relative => child.position += node.position + child.style.translate,
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
