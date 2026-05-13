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

pub const NodeSlice = std.MultiArrayList(Node).Slice;

/// Vector lane access by runtime `Direction`. Inlined so each call expands
/// into a runtime branch with comptime-indexed vector access on either side
/// — vector indexing must be comptime, so we cannot use a `usize` index.
inline fn axisGet(v: Vec2, direction: Direction) f32 {
    return if (direction == .horizontal) v[0] else v[1];
}

inline fn axisSet(v: *Vec2, direction: Direction, x: f32) void {
    if (direction == .horizontal) {
        v[0] = x;
    } else {
        v[1] = x;
    }
}

inline fn axisAdd(v: *Vec2, direction: Direction, delta: f32) void {
    if (direction == .horizontal) {
        v[0] += delta;
    } else {
        v[1] += delta;
    }
}

/// Fit one flow child's contribution into its parent. Lifted out of
/// `Node.fitChild` so it can operate on column slices directly without
/// requiring `*Node` pointers (which `MultiArrayList` does not provide).
/// Called from the `fit` pass below and from `root.zig`'s text-node build
/// path.
pub fn fitChildInto(s: NodeSlice, parentIdx: usize, childIdx: usize) void {
    const styles = s.items(.style);
    const sizes = s.items(.size);
    const minSizes = s.items(.minSize);

    const childStyle: *const CompleteStyle = &styles[childIdx];
    if (childStyle.placement != .flow) return;

    const parentStyle: *const CompleteStyle = &styles[parentIdx];

    const fitH = parentStyle.width == .fit or parentStyle.width.isGrow() or parentStyle.shouldFitMin(.horizontal);
    const fitV = parentStyle.height == .fit or parentStyle.height.isGrow() or parentStyle.shouldFitMin(.vertical);
    if (!fitH and !fitV) return;

    const wraps = parentStyle.overflow == .wrap and parentStyle.direction == .horizontal;
    const layoutDirection = parentStyle.direction;

    inline for (Direction.array) |fitDirection| {
        const preferredSize = parentStyle.getPreferredSize(fitDirection);
        const marginVector = childStyle.margin.get(fitDirection);
        const margins = marginVector[0] + marginVector[1];

        const dirIdx: usize = if (fitDirection == .horizontal) 0 else 1;
        const childSizeInDir = sizes[childIdx][dirIdx];
        const childMinInDir = minSizes[childIdx][dirIdx];

        const contribution = margins + childSizeInDir;
        // For vertical minSize: use max(size, minSize) to capture wrapped text height
        // For horizontal minSize: use minSize only to avoid unwrapped text width bloat
        const minContribution = margins + if (fitDirection == .vertical)
            @max(childSizeInDir, childMinInDir)
        else
            childMinInDir;

        const shouldAccumulate = preferredSize == .fit or preferredSize.isGrow();
        const parentFittingBase = parentStyle.fittingBase(fitDirection);

        if (layoutDirection == fitDirection) {
            if (wraps) {
                // With wrapping, inline-axis min is the widest single child
                // (any child could end up alone on a line).
                if (shouldAccumulate) {
                    sizes[parentIdx][dirIdx] = @max(sizes[parentIdx][dirIdx], contribution + parentFittingBase);
                }
                if (parentStyle.shouldFitMin(fitDirection)) {
                    minSizes[parentIdx][dirIdx] = @max(minSizes[parentIdx][dirIdx], minContribution + parentFittingBase);
                }
            } else {
                if (preferredSize == .fit) {
                    sizes[parentIdx][dirIdx] += contribution;
                } else if (preferredSize.isGrow()) {
                    sizes[parentIdx][dirIdx] = @max(sizes[parentIdx][dirIdx], contribution + parentFittingBase);
                }
                if (parentStyle.shouldFitMin(fitDirection)) {
                    minSizes[parentIdx][dirIdx] += minContribution;
                }
            }
        } else {
            // cross-axis fitting
            if (shouldAccumulate) {
                sizes[parentIdx][dirIdx] = @max(contribution + parentFittingBase, sizes[parentIdx][dirIdx]);
            }
            if (parentStyle.shouldFitMin(fitDirection)) {
                minSizes[parentIdx][dirIdx] = @max(minContribution + parentFittingBase, minSizes[parentIdx][dirIdx]);
            }
        }
    }
}

fn growChildren(
    s: NodeSlice,
    parentIdx: usize,
    activelyModifying: *std.ArrayList(usize),
    direction: Direction,
    remaining: *f32,
) void {
    switch (direction) {
        inline else => |comptime_dir| growChildrenImpl(s, parentIdx, activelyModifying, comptime_dir, remaining),
    }
}

fn growChildrenImpl(
    s: NodeSlice,
    parentIdx: usize,
    activelyModifying: *std.ArrayList(usize),
    comptime direction: Direction,
    remaining: *f32,
) void {
    const sizes = s.items(.size);
    const minSizes = s.items(.minSize);
    const maxSizes = s.items(.maxSize);
    const styles = s.items(.style);
    const firstChilds = s.items(.firstChild);
    const nextSiblings = s.items(.nextSibling);
    const keys = s.items(.key);
    const dirIdx: comptime_int = if (direction == .horizontal) 0 else 1;

    // Collect grow children and reset them to 0, reclaiming their full space.
    // This allows us to distribute the TOTAL available space proportionally
    // (like CSS Grid fr units), rather than remaining space on top of content.
    var childIndexOption = firstChilds[parentIdx];
    while (childIndexOption) |childIndex| {
        const childStyle = &styles[childIndex];
        if (childStyle.placement == .flow) {
            const factor = childStyle.getPreferredSize(direction).growFactor();
            // Only include children with positive grow factors; grow: 0.0 means
            // "don't grow" so we leave those at their current size.
            if (factor > 0.0) {
                const currentSize = sizes[childIndex][dirIdx];
                // Reclaim the full size back into remaining
                remaining.* += currentSize;
                // Reset child to 0; the distribution loop handles minSize constraints
                sizes[childIndex][dirIdx] = 0;
                if (maxSizes[childIndex][dirIdx] > 0) {
                    activelyModifying.appendAssumeCapacity(childIndex);
                }
            }
        }
        childIndexOption = nextSiblings[childIndex];
    }

    if (forbear.traceWriter) |w| {
        w.print("[grow] node={d} dir={s} remaining={d:.1} candidates={d}\n", .{
            keys[parentIdx], @tagName(direction), remaining.*, activelyModifying.items.len,
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
            const childIndex = activelyModifying.items[index];
            if (approxEq(sizes[childIndex][dirIdx], maxSizes[childIndex][dirIdx])) {
                _ = activelyModifying.swapRemove(index);
                continue;
            }
            const factor = styles[childIndex].getPreferredSize(direction).growFactor();
            totalFactor += factor;
            const capPerUnit = (maxSizes[childIndex][dirIdx] - sizes[childIndex][dirIdx]) / factor;
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
        for (activelyModifying.items) |childIndex| {
            const factor = styles[childIndex].getPreferredSize(direction).growFactor();
            const oldSize = sizes[childIndex][dirIdx];
            const allowedDifference = @min(
                @max(oldSize + toAddPerUnit * factor, minSizes[childIndex][dirIdx]),
                maxSizes[childIndex][dirIdx],
            ) - oldSize;
            sizes[childIndex][dirIdx] += allowedDifference;
            remaining.* -= allowedDifference;
            if (forbear.traceWriter) |w| {
                w.print("[grow]   child={d} factor={d:.1} {d:.1} -> {d:.1}\n", .{
                    keys[childIndex], factor, oldSize, sizes[childIndex][dirIdx],
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
    s: NodeSlice,
    parentIdx: usize,
    activelyModifying: *std.ArrayList(usize),
    direction: Direction,
    remaining: *f32,
) void {
    if (remaining.* >= -0.001) {
        return;
    }

    switch (direction) {
        inline else => |comptime_dir| shrinkChildrenImpl(s, parentIdx, activelyModifying, comptime_dir, remaining),
    }
}

fn shrinkChildrenImpl(
    s: NodeSlice,
    parentIdx: usize,
    activelyModifying: *std.ArrayList(usize),
    comptime direction: Direction,
    remaining: *f32,
) void {
    const sizes = s.items(.size);
    const minSizes = s.items(.minSize);
    const styles = s.items(.style);
    const firstChilds = s.items(.firstChild);
    const nextSiblings = s.items(.nextSibling);
    const keys = s.items(.key);
    const dirIdx: comptime_int = if (direction == .horizontal) 0 else 1;

    activelyModifying.clearRetainingCapacity();
    var childIndexOption = firstChilds[parentIdx];
    while (childIndexOption) |childIndex| {
        if (styles[childIndex].placement == .flow) {
            if (sizes[childIndex][dirIdx] > minSizes[childIndex][dirIdx]) {
                activelyModifying.appendAssumeCapacity(childIndex);
            }
        }
        childIndexOption = nextSiblings[childIndex];
    }
    if (forbear.traceWriter) |w| {
        w.print("[shrink] node={d} dir={s} remaining={d:.1} candidates={d}\n", .{
            keys[parentIdx], @tagName(direction), remaining.*, activelyModifying.items.len,
        }) catch {};
    }

    var iteration: usize = 0;
    while (remaining.* < -0.001 and activelyModifying.items.len > 0) {
        iteration += 1;

        var largest: f32 = sizes[activelyModifying.items[0]][dirIdx];
        var secondLargest: f32 = 0.0;

        var index: usize = 0;
        while (index < activelyModifying.items.len) {
            const childIndex = activelyModifying.items[index];
            if (approxEq(sizes[childIndex][dirIdx], minSizes[childIndex][dirIdx])) {
                _ = activelyModifying.swapRemove(index);
                if (index == 0 and activelyModifying.items.len > 0) {
                    largest = sizes[activelyModifying.items[0]][dirIdx];
                }
                continue;
            }
            const childSize = sizes[childIndex][dirIdx];
            if (childSize > largest) {
                largest = childSize;
            } else if (childSize > secondLargest) {
                secondLargest = childSize;
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
        for (activelyModifying.items) |childIndex| {
            if (approxEq(sizes[childIndex][dirIdx], largest)) {
                const oldSize = sizes[childIndex][dirIdx];
                const allowedDifference = @max(
                    oldSize - toSubtract,
                    minSizes[childIndex][dirIdx],
                ) - oldSize;
                sizes[childIndex][dirIdx] += allowedDifference;
                remaining.* -= allowedDifference;
                if (forbear.traceWriter) |w| {
                    w.print("[shrink]   child={d} {d:.1} -> {d:.1}\n", .{
                        keys[childIndex], oldSize, sizes[childIndex][dirIdx],
                    }) catch {};
                }
            }
        }
        if (remaining.* == remainingBeforeLoop) {
            break;
        }
    }
}

/// Bottom-up fit sizing pass.
///
/// For every container whose size depends on its content, reset it to
/// `fittingBase()` (padding + border) and accumulate each child's
/// contribution via `fitChildInto`. Leaves and wrap containers are skipped:
/// leaves carry intrinsic sizes (text glyphs, fixed dimensions) and wrap
/// containers are sized later by `wrapAndPlace` based on actual line
/// breaks.
pub fn fit(nodeTree: *NodeTree) void {
    const s = nodeTree.list.slice();
    const sizes = s.items(.size);
    const minSizes = s.items(.minSize);
    const styles = s.items(.style);
    const firstChilds = s.items(.firstChild);
    const nextSiblings = s.items(.nextSibling);
    const glyphsCol = s.items(.glyphs);

    var i = s.len;
    while (i > 0) {
        i -= 1;

        const shouldReset = firstChilds[i] != null and
            glyphsCol[i] == null and
            styles[i].overflow != .wrap;
        if (!shouldReset) continue;

        inline for (Direction.array) |fitDirection| {
            const dirIdx: usize = if (fitDirection == .horizontal) 0 else 1;
            const fittingBase = styles[i].fittingBase(fitDirection);
            if (styles[i].getPreferredSize(fitDirection) == .fit) {
                sizes[i][dirIdx] = fittingBase;
            }
            if (styles[i].shouldFitMin(fitDirection)) {
                minSizes[i][dirIdx] = fittingBase;
            }
        }

        var childIndexOption = firstChilds[i];
        while (childIndexOption) |childIndex| {
            fitChildInto(s, i, childIndex);
            childIndexOption = nextSiblings[childIndex];
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
    const s = nodeTree.list.slice();
    if (s.len == 0) return;

    const sizes = s.items(.size);
    const minSizes = s.items(.minSize);
    const maxSizes = s.items(.maxSize);
    const styles = s.items(.style);
    const firstChilds = s.items(.firstChild);
    const nextSiblings = s.items(.nextSibling);

    // Single reusable buffer sized to the widest sibling group
    var maxChildCount: usize = 0;
    for (0..s.len) |i| {
        var count: usize = 0;
        var ci = firstChilds[i];
        while (ci) |childIndex| {
            count += 1;
            ci = nextSiblings[childIndex];
        }
        if (count > maxChildCount) maxChildCount = count;
    }
    var activelyModifying = try std.ArrayList(usize).initCapacity(arena, maxChildCount);

    for (0..s.len) |i| {
        if (firstChilds[i] == null) continue;

        const direction = styles[i].direction;
        const fittingBaseMain = styles[i].fittingBase(direction);
        var remaining = axisGet(sizes[i], direction) - fittingBaseMain;

        var childIndexOption = firstChilds[i];
        while (childIndexOption) |childIndex| {
            // Ensure minSize doesn't exceed maxSize before using it
            minSizes[childIndex][0] = @min(minSizes[childIndex][0], maxSizes[childIndex][0]);
            minSizes[childIndex][1] = @min(minSizes[childIndex][1], maxSizes[childIndex][1]);

            const childStyle = &styles[childIndex];
            if (direction.perpendicular() == .vertical) {
                const available = sizes[i][1] - styles[i].fittingBase(.vertical) - childStyle.margin.y[0] - childStyle.margin.y[1];
                if (childStyle.height.isGrow() or (childStyle.placement == .flow and sizes[childIndex][1] > available and minSizes[childIndex][1] < sizes[childIndex][1])) {
                    sizes[childIndex][1] = @max(@min(available, maxSizes[childIndex][1]), minSizes[childIndex][1]);
                }
            } else if (direction.perpendicular() == .horizontal) {
                const available = sizes[i][0] - styles[i].fittingBase(.horizontal) - childStyle.margin.x[0] - childStyle.margin.x[1];
                if (childStyle.width.isGrow() or (childStyle.placement == .flow and sizes[childIndex][0] > available and minSizes[childIndex][0] < sizes[childIndex][0])) {
                    sizes[childIndex][0] = @max(@min(available, maxSizes[childIndex][0]), minSizes[childIndex][0]);
                }
            }

            if (childStyle.placement == .flow) {
                const marginMain = childStyle.margin.get(direction);
                remaining -= axisGet(sizes[childIndex], direction) + marginMain[0] + marginMain[1];
            } else if (childStyle.getPreferredSize(direction).isGrow()) {
                // Out-of-flow grow children size to the parent's content area on
                // the main axis. They don't share space with siblings, so grow
                // simply means "fill the parent on this axis".
                const marginMain = childStyle.margin.get(direction);
                const available = axisGet(sizes[i], direction) - fittingBaseMain - marginMain[0] - marginMain[1];
                axisSet(&sizes[childIndex], direction, @max(@min(available, axisGet(maxSizes[childIndex], direction)), axisGet(minSizes[childIndex], direction)));
            }
            childIndexOption = nextSiblings[childIndex];
        }

        activelyModifying.clearRetainingCapacity();
        growChildren(s, i, &activelyModifying, direction, &remaining);
        shrinkChildren(s, i, &activelyModifying, direction, &remaining);

        // Ratio axes depend on the opposite axis which may have just been
        // resolved by grow/shrink or perpendicular clamping above.
        childIndexOption = firstChilds[i];
        while (childIndexOption) |childIndex| {
            const childStyle = &styles[childIndex];
            if (childStyle.width == .ratio) {
                sizes[childIndex][0] = sizes[childIndex][1] * childStyle.width.ratio;
            }
            if (childStyle.height == .ratio) {
                sizes[childIndex][1] = sizes[childIndex][0] * childStyle.height.ratio;
            }
            childIndexOption = nextSiblings[childIndex];
        }
    }
}

fn wrapGlyphs(arena: std.mem.Allocator, s: NodeSlice, nodeIdx: usize, base: Vec2) !void {
    const sizes = s.items(.size);
    const styles = s.items(.style);
    const glyphsCol = s.items(.glyphs);

    std.debug.assert(glyphsCol[nodeIdx] != null);
    if (styles[nodeIdx].textWrapping == .none) {
        return;
    }

    const glyphs = glyphsCol[nodeIdx].?;

    const Line = struct {
        start: usize,
        end: usize,
    };
    var lines = try std.ArrayList(Line).initCapacity(arena, 4);

    const lineEnd = sizes[nodeIdx][0] - styles[nodeIdx].fittingBase(.horizontal);
    var cursor: Vec2 = @splat(0.0);
    var lineStartIndex: usize = 0;

    const breaks = glyphs.preBreakIndices;
    var breakCursor: usize = 0;

    switch (styles[nodeIdx].textWrapping) {
        .character => {
            for (glyphs.slice, 0..) |*glyph, index| {
                while (breakCursor < breaks.len and breaks[breakCursor] == index) : (breakCursor += 1) {
                    if (index > lineStartIndex) {
                        try lines.append(arena, .{
                            .start = lineStartIndex,
                            .end = index - 1,
                        });
                    }
                    lineStartIndex = index;
                    cursor[0] = 0.0;
                    cursor[1] += glyphs.lineHeight;
                }

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
                while (breakCursor < breaks.len and breaks[breakCursor] == index) : (breakCursor += 1) {
                    if (index > lineStartIndex) {
                        try lines.append(arena, .{
                            .start = lineStartIndex,
                            .end = index - 1,
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
            switch (styles[nodeIdx].xJustification) {
                .start => {},
                .center => glyph.position[0] += (lineEnd - width) / 2.0,
                .end => glyph.position[0] += lineEnd - width,
            }
        }
    }

    sizes[nodeIdx][1] = cursor[1] + glyphs.lineHeight;
    if (styles[nodeIdx].width == .ratio) {
        sizes[nodeIdx][0] = sizes[nodeIdx][1] * styles[nodeIdx].width.ratio;
    }
}

/// Wrap text, place children in parent-local coordinates, and expand
/// fit/wrap containers to enclose their content.
///
/// Iteration is a single backward pass over `nodeTree.list.items`. Reverse
/// order visits every descendant before its ancestor, which is what we need
/// because:
///   * Text wrapping inside a child sets the child's height before its
///     parent reads it during placement.
///   * A wrap container's own height depends on the line layout it computes
///     from already-sized children.
///
/// Each iteration handles ONE container (or one text node): it wraps glyphs
/// if it's a text node, otherwise it positions its direct children in its
/// own local coordinate space and expands itself to fit them. Global
/// (world-space) positions are computed later by `layout()` in a single
/// top-down pass that adds each ancestor's position to its descendants.
pub fn wrapAndPlace(arena: std.mem.Allocator, nodeTree: *NodeTree) !void {
    const s = nodeTree.list.slice();
    const sizes = s.items(.size);
    const positions = s.items(.position);
    const styles = s.items(.style);
    const firstChilds = s.items(.firstChild);
    const nextSiblings = s.items(.nextSibling);
    const glyphsCol = s.items(.glyphs);

    var i = s.len;
    while (i > 0) {
        i -= 1;

        const nodeStyle = &styles[i];
        const base = Vec2{
            nodeStyle.borderWidth.x[0] + nodeStyle.padding.x[0],
            nodeStyle.borderWidth.y[0] + nodeStyle.padding.y[0],
        };

        // TODO: find a way to not have duplicate code between children and glyphs
        if (glyphsCol[i] != null) {
            try wrapGlyphs(arena, s, i, base);
            continue;
        }
        if (firstChilds[i] == null) continue;

        if (nodeStyle.direction == .horizontal) {
            const Line = struct {
                start: usize,
                end: usize,
                width: f32,
                height: f32,
            };

            var cursor = base;
            var lines = std.ArrayList(Line).empty;
            var currentLine = Line{ .start = firstChilds[i].?, .end = firstChilds[i].?, .width = 0.0, .height = 0.0 };
            var wrapHeightAddition: f32 = 0.0;

            var childIndexOption = firstChilds[i];
            while (childIndexOption) |childIndex| {
                const childStyle = &styles[childIndex];

                if (childStyle.placement == .flow) {
                    const childOuterWidth = childStyle.margin.x[0] + sizes[childIndex][0] + childStyle.margin.x[1];
                    const childOuterHeight = childStyle.margin.y[0] + sizes[childIndex][1] + childStyle.margin.y[1];

                    if (nodeStyle.overflow == .wrap) {
                        const remainingSpace = sizes[i][0] - cursor[0] - nodeStyle.borderWidth.x[1] - nodeStyle.padding.x[1];
                        if (childOuterWidth > remainingSpace) {
                            const addition = currentLine.height + childStyle.margin.y[0];
                            cursor[1] += addition;
                            // TODO: where does the bottom margin get used in this flow? I believe we're missing something
                            sizes[i][1] += addition;
                            wrapHeightAddition += addition;
                            if (nodeStyle.width == .ratio) {
                                sizes[i][0] = sizes[i][1] * nodeStyle.width.ratio;
                            }
                            cursor[0] = base[0];
                            try lines.append(arena, currentLine);

                            // New line starts at the overflow child; .end is still the prior line until assigned below.
                            currentLine = .{ .start = childIndex, .end = childIndex, .width = 0, .height = 0 };
                        }
                    }

                    cursor[0] += childStyle.margin.x[0];
                    positions[childIndex] = cursor + Vec2{ 0, childStyle.margin.y[0] };
                    cursor[0] += sizes[childIndex][0] + childStyle.margin.x[1];

                    currentLine.width += childOuterWidth;
                    currentLine.height = @max(currentLine.height, childOuterHeight);
                }

                currentLine.end = childIndex;
                childIndexOption = nextSiblings[childIndex];
            }
            try lines.append(arena, currentLine);

            if (nodeStyle.overflow == .wrap) {
                // Wrap containers: height = base + wrapped lines + last line
                sizes[i][1] = nodeStyle.fittingBase(.vertical) + wrapHeightAddition + currentLine.height;
                if (nodeStyle.width == .ratio) {
                    sizes[i][0] = sizes[i][1] * nodeStyle.width.ratio;
                }
            } else if (nodeStyle.height == .fit or nodeStyle.height.isGrow()) {
                // Non-wrap: expand height to fit tallest child
                const newHeight = nodeStyle.fittingBase(.vertical) + currentLine.height;
                sizes[i][1] = @max(sizes[i][1], newHeight);
            }

            const availableWidth = sizes[i][0] - nodeStyle.fittingBase(.horizontal);
            const availableHeight = sizes[i][1] - nodeStyle.fittingBase(.vertical);
            for (lines.items) |line| {
                const xOffset: f32 = switch (nodeStyle.xJustification) {
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
                    const childStyle = &styles[childIndex];
                    if (childStyle.placement == .flow) {
                        positions[childIndex][0] += xOffset;
                        positions[childIndex][1] += switch (nodeStyle.yJustification) {
                            .start => 0.0,
                            .center => (alignHeight - sizes[childIndex][1]) / 2.0,
                            .end => alignHeight - sizes[childIndex][1],
                        };
                    }
                    if (childIndex == line.end) break;
                    childIndexOption = nextSiblings[childIndex];
                }
            }
        } else {
            var cursor = base;

            var childIndexOption = firstChilds[i];
            while (childIndexOption) |childIndex| {
                const childStyle = &styles[childIndex];
                if (childStyle.placement == .flow) {
                    cursor[1] += childStyle.margin.y[0];
                    positions[childIndex] = cursor;
                    cursor[1] += sizes[childIndex][1] + childStyle.margin.y[1];
                }
                childIndexOption = nextSiblings[childIndex];
            }

            const contentHeight = cursor[1] - base[1];

            // Update fit containers to match content (needed before parent positions siblings)
            if (nodeStyle.height == .fit or nodeStyle.height.isGrow()) {
                const newHeight = nodeStyle.fittingBase(.vertical) + contentHeight;
                sizes[i][1] = @max(sizes[i][1], newHeight);
            }
            const availableWidth = sizes[i][0] - nodeStyle.fittingBase(.horizontal);
            const availableHeight = sizes[i][1] - nodeStyle.fittingBase(.vertical);
            const yOffset: f32 = switch (nodeStyle.yJustification) {
                .start => 0.0,
                .center => (availableHeight - contentHeight) / 2.0,
                .end => availableHeight - contentHeight,
            };
            childIndexOption = firstChilds[i];
            while (childIndexOption) |childIndex| {
                const childStyle = &styles[childIndex];
                if (childStyle.placement == .flow) {
                    positions[childIndex][0] += switch (nodeStyle.xJustification) {
                        .start => 0.0,
                        .center => (availableWidth - sizes[childIndex][0]) / 2.0,
                        .end => availableWidth - sizes[childIndex][0],
                    };
                    positions[childIndex][1] += yOffset;
                }
                childIndexOption = nextSiblings[childIndex];
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

    if (context.nodeTree.list.len > 0) {
        const s = context.nodeTree.list.slice();
        const sizes = s.items(.size);
        const positions = s.items(.position);
        const minSizes = s.items(.minSize);
        const maxSizes = s.items(.maxSize);
        const styles = s.items(.style);
        const firstChilds = s.items(.firstChild);
        const nextSiblings = s.items(.nextSibling);
        const childrenOffsets = s.items(.childrenOffset);
        const contentSizes = s.items(.contentSize);
        const glyphsCol = s.items(.glyphs);
        const clipRects = s.items(.clipRect);
        const parents = s.items(.parent);

        fit(&context.nodeTree);

        if (styles[0].width.isGrow()) {
            sizes[0][0] = @min(@max(viewportSize[0], minSizes[0][0]), maxSizes[0][0]);
        }
        if (styles[0].height.isGrow()) {
            sizes[0][1] = @min(@max(viewportSize[1], minSizes[0][1]), maxSizes[0][1]);
        }

        try growAndShrink(arena, &context.nodeTree);

        try wrapAndPlace(arena, &context.nodeTree);

        // Wrapping in pass 3 changed perpendicular sizes (taller text nodes,
        // taller wrap containers) — ancestors were already effectively refit
        // by wrapAndPlace itself, but their grow-sized siblings still need
        // redistribution and cross-axis clamping against the new sizes.
        //
        // The intention is for this to only change cross-axis sizes.
        try growAndShrink(arena, &context.nodeTree);

        // Pass 4 may have shrunk or grown some children; cursors and
        // justification offsets need to be recomputed. Wrapping itself is
        // stable because widths haven't changed since pass 2, but placement
        // and wrapping share their main loop so the whole pass runs.
        //
        // The intention is for this to only change positions.
        try wrapAndPlace(arena, &context.nodeTree);

        positions[0] += styles[0].translate;

        for (0..s.len) |i| {
            var childIndexOption = firstChilds[i];
            while (childIndexOption) |childIndex| {
                const childStyle = &styles[childIndex];

                switch (childStyle.placement) {
                    // Viewport-pinned: ignore scroll and ancestor offsets.
                    .fixed => positions[childIndex] += childStyle.translate,
                    // Viewport-space but scroll-aware: the root's resolved
                    // position already contains `-scrollPosition` plus the
                    // root's own translate, so adding it gives document-space
                    // placement that scrolls with the page.
                    .absolute => positions[childIndex] += positions[0] + childStyle.translate,
                    // Parent-relative: the user-supplied Vec2 is an offset
                    // from the parent's content-box top-left (i.e. inside
                    // the parent's border + padding), matching how `grow`
                    // sizes against the content area. The child adopts the
                    // parent's resolved position so it inherits ancestor
                    // offsets and scroll naturally, but is not shifted by
                    // the parent's `childrenOffset` (which is the parent's
                    // per-container scroll offset for its flowing children).
                    .relative => positions[childIndex] += positions[i] + Vec2{
                        styles[i].borderWidth.x[0] + styles[i].padding.x[0],
                        styles[i].borderWidth.y[0] + styles[i].padding.y[0],
                    } + childStyle.translate,
                    // Flow children: positions were computed by wrapAndPlace
                    // relative to the parent. Add the parent's resolved
                    // position and its `childrenOffset` to scroll them
                    // together.
                    .flow => positions[childIndex] += positions[i] + childrenOffsets[i] + childStyle.translate,
                }
                if (glyphsCol[childIndex]) |glyphs| {
                    for (glyphs.slice) |*glyph| {
                        glyph.position += positions[childIndex];
                    }
                }

                childIndexOption = nextSiblings[childIndex];
            }
        }

        for (0..s.len) |i| {
            var contentSize: Vec2 = @splat(0.0);
            var childIndexOption = firstChilds[i];
            while (childIndexOption) |childIndex| {
                if (styles[childIndex].placement == .flow) {
                    // Subtract `childrenOffset` so contentSize reflects the
                    // natural (pre-scroll) extent. That keeps scroll bounds
                    // stable regardless of the current offset.
                    const right = positions[childIndex][0] + sizes[childIndex][0] - positions[i][0] - childrenOffsets[i][0];
                    const bottom = positions[childIndex][1] + sizes[childIndex][1] - positions[i][1] - childrenOffsets[i][1];
                    contentSize[0] = @max(contentSize[0], right);
                    contentSize[1] = @max(contentSize[1], bottom);
                }
                childIndexOption = nextSiblings[childIndex];
            }
            contentSizes[i] = contentSize;
        }

        const propagated = try arena.alloc(?Vec4, s.len);
        @memset(propagated, null);
        for (0..s.len) |idx| {
            const inherited: ?Vec4 = if (parents[idx]) |pi| propagated[pi] else null;

            if (inherited) |inh| {
                clipRects[idx] = if (clipRects[idx]) |existing|
                    intersectRect(existing, inh)
                else
                    inh;
            }

            // What this node passes down to its descendants defaults to what
            // it inherited; if the node generates its own clip, fold that in.
            propagated[idx] = inherited;

            const hasConstrainedWidth = styles[idx].width != .fit or sizes[idx][0] >= maxSizes[idx][0];
            const hasConstrainedHeight = styles[idx].height != .fit or sizes[idx][1] >= maxSizes[idx][1];
            if (!hasConstrainedWidth and !hasConstrainedHeight) continue;

            var hasOverflow = false;
            var childIndexOption = firstChilds[idx];
            while (childIndexOption) |childIndex| {
                const childRight = positions[childIndex][0] + sizes[childIndex][0];
                const childBottom = positions[childIndex][1] + sizes[childIndex][1];
                const nodeRight = positions[idx][0] + sizes[idx][0];
                const nodeBottom = positions[idx][1] + sizes[idx][1];

                if ((hasConstrainedWidth and (positions[childIndex][0] < positions[idx][0] or childRight > nodeRight)) or
                    (hasConstrainedHeight and (positions[childIndex][1] < positions[idx][1] or childBottom > nodeBottom)))
                {
                    hasOverflow = true;
                    break;
                }
                childIndexOption = nextSiblings[childIndex];
            }
            if (!hasOverflow) continue;

            const generatedClip = Vec4{
                positions[idx][0],
                positions[idx][1],
                sizes[idx][0],
                sizes[idx][1],
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
