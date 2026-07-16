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

    // Water-filling needs at most ~one pass per candidate; anything beyond this
    // bound means the sub-pixel-progress break below has regressed and the loop
    // is spinning. `std.debug.assert` is a no-op in ReleaseFast, so the counter
    // is dead-code-eliminated there and this costs nothing in shipping builds.
    var passes: usize = 0;
    const maxPasses = activelyModifying.items.len * 4 + 64;

    while (remaining.* > 0.001 and activelyModifying.items.len > 0) {
        passes += 1;
        std.debug.assert(passes <= maxPasses);
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
        // Stop once a pass stops making sub-pixel progress. Exact float
        // equality is not enough: when total grow capacity is within a hair
        // of `remaining`, each pass keeps shaving an ever-smaller (but
        // nonzero) sliver, so the loop would spin for millions of iterations
        // before the difference underflows to exactly zero.
        if (remainingBeforeLoop - remaining.* < 0.001) {
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

    // Water-filling needs at most ~one pass per candidate; anything beyond this
    // bound means the sub-pixel-progress break below has regressed and the loop
    // is spinning. `std.debug.assert` is a no-op in ReleaseFast, so the counter
    // is dead-code-eliminated there and this costs nothing in shipping builds.
    var passes: usize = 0;
    const maxPasses = activelyModifying.items.len * 4 + 64;

    while (remaining.* < -0.001 and activelyModifying.items.len > 0) {
        passes += 1;
        std.debug.assert(passes <= maxPasses);
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
        // Stop once a pass stops making sub-pixel progress. Exact float
        // equality is not enough: when the children's total shrink capacity
        // is within a hair of the overflow, each pass keeps shaving an
        // ever-smaller (but nonzero) sliver, so the loop would spin for
        // millions of iterations before the difference underflows to zero.
        if (remaining.* - remainingBeforeLoop < 0.001) {
            break;
        }
    }
}

/// Bottom-up fit sizing pass.
///
/// For every container whose size depends on its content, reset it to
/// `fittingBase()` (padding + border) and accumulate each child's
/// contribution via `fitChild`. Leaves are skipped: they carry intrinsic
/// sizes (text glyphs, fixed dimensions).
pub fn fit(nodeTree: *NodeTree) void {
    var i = nodeTree.list.items.len;
    while (i > 0) {
        i -= 1;
        const node = &nodeTree.list.items[i];

        const shouldReset = node.firstChild != null and node.glyphs == null;
        if (!shouldReset) continue;

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
            node.fitChild(child);
            childIndexOption = child.nextSibling;
        }
    }
}

/// Top-down sizing pass.
///
/// For every container, distribute available main-axis space among children
/// using `grow` factors, clamp each child's perpendicular axis to the
/// parent's available room, and resolve ratio sizes that depend on the
/// just-set opposite axis.
pub fn growAndShrink(arena: std.mem.Allocator, nodeTree: *NodeTree) !void {
    if (nodeTree.list.items.len == 0) return;

    // Single reusable buffer sized to the widest sibling group
    var maxChildCount: usize = 0;
    for (nodeTree.list.items) |*node| {
        var count: usize = 0;
        var childIndexOption = node.firstChild;
        while (childIndexOption) |childIndex| {
            count += 1;
            childIndexOption = nodeTree.at(childIndex).nextSibling;
        }
        if (count > maxChildCount) maxChildCount = count;
    }
    var activelyModifying = try std.ArrayList(*Node).initCapacity(arena, maxChildCount);

    for (nodeTree.list.items) |*node| {
        if (node.firstChild == null) continue;

        const direction = node.style.direction;
        var remaining = node.getSize(direction) - node.fittingBase(direction);

        var childIndexOption = node.firstChild;
        while (childIndexOption) |childIndex| {
            const child = nodeTree.at(childIndex);

            // Ensure minSize doesn't exceed maxSize before using it
            child.minSize[0] = @min(child.minSize[0], child.maxSize[0]);
            child.minSize[1] = @min(child.minSize[1], child.maxSize[1]);

            if (direction.perpendicular() == .vertical) {
                const available = node.size[1] - node.fittingBase(.vertical) - child.style.margin.y[0] - child.style.margin.y[1];
                if (child.style.height.isGrow() or (child.style.placement == .flow and child.size[1] > available and child.minSize[1] < child.size[1])) {
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
                if (child.style.width.isGrow() or (child.style.placement == .flow and child.size[0] > available and child.minSize[0] < child.size[0])) {
                    child.size[0] = @max(
                        @min(
                            available,
                            child.maxSize[0],
                        ),
                        child.minSize[0],
                    );
                }
            }

            if (child.style.placement == .flow) {
                remaining -= child.getOuterSize(direction);
            } else if (child.style.getPreferredSize(direction).isGrow()) {
                // Out-of-flow grow children size to the parent's content area on
                // the main axis. They don't share space with siblings, so grow
                // simply means "fill the parent on this axis".
                const available = node.getSize(direction) - node.fittingBase(direction) - child.style.margin.get(direction)[0] - child.style.margin.get(direction)[1];
                child.setSize(direction, @max(
                    @min(available, child.getMaxSize(direction)),
                    child.getMinSize(direction),
                ));
            }
            childIndexOption = child.nextSibling;
        }

        activelyModifying.clearRetainingCapacity();
        growChildren(node, nodeTree, &activelyModifying, direction, &remaining);
        shrinkChildren(node, nodeTree, &activelyModifying, direction, &remaining);

        // Ratio axes depend on the opposite axis which may have just been
        // resolved by grow/shrink or perpendicular clamping above.
        childIndexOption = node.firstChild;
        while (childIndexOption) |childIndex| {
            const child = nodeTree.at(childIndex);
            if (child.style.width == .ratio) {
                child.size[0] = child.size[1] * child.style.width.ratio;
            }
            if (child.style.height == .ratio) {
                child.size[1] = child.size[0] * child.style.height.ratio;
            }
            childIndexOption = child.nextSibling;
        }
    }
}

/// Wrap `glyphs` to `lineEnd` (content width, padding/border already excluded),
/// repositioning each glyph from `base` and returning the laid-out height.
/// `.none` is handled by the caller and never reaches here.
pub fn wrapGlyphs(
    arena: std.mem.Allocator,
    glyphs: *Glyphs,
    lineEnd: f32,
    textWrapping: TextWrapping,
    xJustification: Alignment,
    base: Vec2,
) !f32 {
    const Line = struct {
        start: usize,
        end: usize,
    };
    var lines = try std.ArrayList(Line).initCapacity(arena, 4);

    var cursor: Vec2 = @splat(0.0);
    var lineStartIndex: usize = 0;

    const breaks = glyphs.preBreakIndices;
    var breakCursor: usize = 0;

    switch (textWrapping) {
        .character => {
            for (glyphs.slice, 0..) |*glyph, index| {
                while (breakCursor < breaks.len and breaks[breakCursor] == index) : (breakCursor += 1) {
                    if (index > lineStartIndex) {
                        try lines.append(arena, .{
                            .start = lineStartIndex,
                            .end = if (index == 0) index else index - 1,
                        });
                    }
                    lineStartIndex = index;
                    cursor[0] = 0.0;
                    cursor[1] += glyphs.lineHeight;
                }

                if (cursor[0] + glyph.advance[0] > lineEnd) {
                    try lines.append(arena, .{
                        .start = lineStartIndex,
                        .end = if (index == 0) index else index - 1,
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
                while (breakCursor < breaks.len and breaks[breakCursor] == index) : (breakCursor += 1) {
                    if (index > lineStartIndex) {
                        try lines.append(arena, .{
                            .start = lineStartIndex,
                            .end = if (index == 0) index else index - 1,
                        });
                    }
                    lineStartIndex = index;
                    cursor[0] = 0.0;
                    cursor[1] += glyphs.lineHeight;
                    lastSpaceInfoOpt = null;
                }

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
                if (std.mem.startsWith(u8, &glyph.textBuf, " ")) {
                    lastSpaceInfoOpt = .{
                        .index = index,
                        .position = glyph.position,
                    };
                }
            }
        },
        else => unreachable,
    }

    // Flush any trailing manual breaks past the last glyph so node height
    // accounts for empty lines at the end of the text.
    while (breakCursor < breaks.len) : (breakCursor += 1) {
        cursor[1] += glyphs.lineHeight;
    }

    if (glyphs.slice.len > 0) {
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
    }
    for (lines.items) |line| {
        const startX = glyphs.slice[line.start].position[0];
        const endX = glyphs.slice[line.end].position[0] + glyphs.slice[line.end].advance[0];
        const width = endX - startX;
        for (glyphs.slice[line.start .. line.end + 1]) |*glyph| {
            switch (xJustification) {
                .start => {},
                .center => glyph.position[0] += (lineEnd - width) / 2.0,
                .end => glyph.position[0] += lineEnd - width,
            }
        }
    }

    return cursor[1] + glyphs.lineHeight;
}

pub fn place(nodeTree: *NodeTree) void {
    var i = nodeTree.list.items.len;
    // walk in reverse so that we go through nodes deeper in the tree first,
    // before going into the ones closer to the top
    while (i > 0) {
        i -= 1;
        const parent = &nodeTree.list.items[i];

        var childIndexOpt = parent.firstChild;

        var contentSize: Vec2 = @splat(0.0);
        {
            // computing the size that the content will be spanning inside of
            // the parent. used for: 1. justification 2. adjusting sizes
            // because of changed wrapping width
            while (childIndexOpt) |childIndex| {
                const child = &nodeTree.list.items[childIndex];
                if (child.style.placement == .flow) {
                    if (parent.style.direction == .horizontal) {
                        contentSize[0] += child.style.margin.x[0] + child.size[0] + child.style.margin.x[1];
                        contentSize[1] = @max(child.style.margin.y[0] + child.size[1] + child.style.margin.y[1], contentSize[1]);
                    } else if (parent.style.direction == .vertical) {
                        contentSize[0] = @max(child.style.margin.x[0] + child.size[0] + child.style.margin.x[1], contentSize[0]);
                        contentSize[1] += child.style.margin.y[0] + child.size[1] + child.style.margin.y[1];
                    }
                }
                childIndexOpt = child.nextSibling;
            }
        }

        if (parent.style.height == .fit or parent.style.height.isGrow()) {
            const newHeight = parent.fittingBase(.vertical) + contentSize[1];
            parent.size[1] = @max(parent.size[1], newHeight);
        }

        const availableSize: Vec2 = parent.size - Vec2{
            parent.fittingBase(.horizontal),
            parent.fittingBase(.vertical),
        };

        var cursor: Vec2 = @splat(0.0);
        cursor += Vec2{
            parent.style.padding.x[0] + parent.style.borderWidth.x[0],
            parent.style.padding.y[0] + parent.style.borderWidth.y[0],
        };
        {
            // justification step
            if (parent.style.direction == .horizontal) {
                cursor[0] += switch (parent.style.xJustification) {
                    .start => 0.0,
                    .center => (availableSize[0] - contentSize[0]) / 2,
                    .end => availableSize[0] - contentSize[0],
                };
            }
            if (parent.style.direction == .vertical) {
                cursor[1] += switch (parent.style.yJustification) {
                    .start => 0.0,
                    .center => (availableSize[1] - contentSize[1]) / 2,
                    .end => availableSize[1] - contentSize[1],
                };
            }
        }

        {
            childIndexOpt = parent.firstChild;
            // real placement
            while (childIndexOpt) |childIndex| {
                const child = &nodeTree.list.items[childIndex];
                if (child.style.placement == .flow) {
                    if (parent.style.direction == .horizontal) {
                        child.position += cursor;
                        child.position[0] += child.style.margin.x[0];
                        child.position[1] += switch (parent.style.yJustification) {
                            .start => child.style.margin.y[0],
                            .center => (availableSize[1] - child.style.margin.y[0] - child.size[1] - child.style.margin.y[1]) / 2 + child.style.margin.y[0],
                            .end => availableSize[1] - child.size[1] - child.style.margin.y[1],
                        };

                        cursor[0] += child.style.margin.x[0] + child.size[0] + child.style.margin.x[1];
                    } else if (parent.style.direction == .vertical) {
                        child.position += cursor;
                        child.position[0] += switch (parent.style.xJustification) {
                            .start => child.style.margin.x[0],
                            .center => (availableSize[0] - child.style.margin.x[0] - child.size[0] - child.style.margin.x[1]) / 2 + child.style.margin.x[0],
                            .end => availableSize[0] - child.size[0] - child.style.margin.x[1],
                        };
                        child.position[1] += child.style.margin.y[0];

                        cursor[1] += child.style.margin.y[0] + child.size[1] + child.style.margin.y[1];
                    }
                }
                childIndexOpt = child.nextSibling;
            }
        }
    }
}

pub fn wrap(arena: std.mem.Allocator, nodeTree: *NodeTree) !void {
    var i = nodeTree.list.items.len;
    while (i > 0) {
        i -= 1;
        const node = &nodeTree.list.items[i];

        const base = Vec2{
            node.style.borderWidth.x[0] + node.style.padding.x[0],
            node.style.borderWidth.y[0] + node.style.padding.y[0],
        };

        if (node.glyphs) |*glyphs| {
            if (node.style.textWrapping != .none) {
                node.size[1] = try wrapGlyphs(
                    arena,
                    glyphs,
                    node.size[0] - node.fittingBase(.horizontal),
                    node.style.textWrapping,
                    node.style.xJustification,
                    base,
                );
                if (node.style.width == .ratio) {
                    node.size[0] = node.size[1] * node.style.width.ratio;
                }
            }
            continue;
        }
    }
}

pub fn layout() !*NodeTree {
    const context = forbear.getForbear();

    std.debug.assert(context.frameMeta != null);
    if (context.frameMeta.?.err) |err| return err;
    const viewportSize = context.frameMeta.?.viewportSize;
    const arena = context.frameMeta.?.arena;

    if (context.nodeTree.list.items.len > 0) {
        const root = context.nodeTree.at(0);

        fit(&context.nodeTree);

        if (root.style.width.isGrow()) {
            root.size[0] = @min(@max(viewportSize[0], root.minSize[0]), root.maxSize[0]);
        }
        if (root.style.height.isGrow()) {
            root.size[1] = @min(@max(viewportSize[1], root.minSize[1]), root.maxSize[1]);
        }

        try growAndShrink(arena, &context.nodeTree);

        try wrap(arena, &context.nodeTree);
        place(&context.nodeTree);

        // Wrapping in pass 3 changed perpendicular sizes (taller text
        // nodes) — grow-sized siblings still need redistribution and
        // cross-axis clamping against the new sizes.
        //
        // The intention is for this to only change cross-axis sizes.
        try growAndShrink(arena, &context.nodeTree);

        // Pass 4 may have shrunk or grown some children; glyph positions
        // need to be recomputed against the new sizes.
        //
        // The intention is for this to only change positions.
        try wrap(arena, &context.nodeTree);

        root.position += root.style.translate;

        for (context.nodeTree.list.items) |*node| {
            var childIndexOption = node.firstChild;
            while (childIndexOption) |childIndex| {
                const child = context.nodeTree.at(childIndex);

                switch (child.style.placement) {
                    // Viewport-pinned: ignore scroll and ancestor offsets.
                    .fixed => child.position += child.style.translate,
                    // Parent-relative: the user-supplied Vec2 is an offset
                    // from the parent's content-box top-left (i.e. inside
                    // the parent's border + padding), matching how `grow`
                    // sizes against the content area. The child adopts the
                    // parent's resolved position so it inherits ancestor
                    // offsets and scroll naturally, but is not shifted by
                    // the parent's `childrenOffset` (which is the parent's
                    // per-container scroll offset for its flowing children).
                    .relative => child.position += node.position + Vec2{
                        node.style.borderWidth.x[0] + node.style.padding.x[0],
                        node.style.borderWidth.y[0] + node.style.padding.y[0],
                    } + child.style.translate,
                    // Flow children: positions were computed by wrapAndPlace
                    // relative to the parent. Add the parent's resolved
                    // position and its `childrenOffset` to scroll them
                    // together.
                    .flow => child.position += node.position + node.childrenOffset + child.style.translate,
                }
                if (child.glyphs) |glyphs| {
                    for (glyphs.slice) |*glyph| {
                        glyph.position += child.position;
                    }
                }

                childIndexOption = child.nextSibling;
            }
        }

        for (context.nodeTree.list.items) |*node| {
            var contentSize: Vec2 = @splat(0.0);
            var childIndexOption = node.firstChild;
            while (childIndexOption) |childIndex| {
                const child = context.nodeTree.at(childIndex);
                if (child.style.placement == .flow) {
                    // Subtract `childrenOffset` so contentSize reflects the
                    // natural (pre-scroll) extent. That keeps scroll bounds
                    // stable regardless of the current offset.
                    const right = child.position[0] + child.size[0] - node.position[0] - node.childrenOffset[0];
                    const bottom = child.position[1] + child.size[1] - node.position[1] - node.childrenOffset[1];
                    contentSize[0] = @max(contentSize[0], right);
                    contentSize[1] = @max(contentSize[1], bottom);
                }
                childIndexOption = child.nextSibling;
            }
            node.contentSize = contentSize;
        }

        const propagated = try arena.alloc(?Vec4, context.nodeTree.list.items.len);
        @memset(propagated, null);
        for (context.nodeTree.list.items, 0..) |*node, idx| {
            const inherited: ?Vec4 = if (node.parent) |pi| propagated[pi] else null;

            if (inherited) |inh| {
                node.clipRect = if (node.clipRect) |existing|
                    intersectRect(existing, inh)
                else
                    inh;
            }

            // What this node passes down to its descendants defaults to what
            // it inherited; if the node generates its own clip, fold that in.
            propagated[idx] = inherited;

            // `.visible` lets children spill out unclipped.
            if (node.style.overflow == .visible) continue;

            const hasConstrainedWidth = node.style.width != .fit or node.size[0] >= node.maxSize[0];
            const hasConstrainedHeight = node.style.height != .fit or node.size[1] >= node.maxSize[1];
            if (!hasConstrainedWidth and !hasConstrainedHeight) continue;

            var hasOverflow = false;
            var childIndexOption = node.firstChild;
            while (childIndexOption) |childIndex| {
                const child = context.nodeTree.at(childIndex);
                const childRight = child.position[0] + child.size[0];
                const childBottom = child.position[1] + child.size[1];
                const nodeRight = node.position[0] + node.size[0];
                const nodeBottom = node.position[1] + node.size[1];

                if ((hasConstrainedWidth and (child.position[0] < node.position[0] or childRight > nodeRight)) or
                    (hasConstrainedHeight and (child.position[1] < node.position[1] or childBottom > nodeBottom)))
                {
                    hasOverflow = true;
                    break;
                }
                childIndexOption = child.nextSibling;
            }
            if (!hasOverflow) continue;

            const generatedClip = Vec4{
                node.position[0],
                node.position[1],
                node.size[0],
                node.size[1],
            };
            propagated[idx] = if (inherited) |inh|
                intersectRect(inh, generatedClip)
            else
                generatedClip;
        }
    }

    return &context.nodeTree;
}

fn intersectRect(a: Vec4, b: Vec4) Vec4 {
    const x1 = @max(a[0], b[0]);
    const y1 = @max(a[1], b[1]);
    const x2 = @min(a[0] + a[2], b[0] + b[2]);
    const y2 = @min(a[1] + a[3], b[1] + b[3]);
    return Vec4{ x1, y1, @max(0, x2 - x1), @max(0, y2 - y1) };
}
