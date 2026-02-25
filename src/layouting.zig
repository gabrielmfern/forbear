const std = @import("std");

const Alignment = @import("node.zig").Alignment;
const BaseStyle = @import("node.zig").BaseStyle;
const Direction = @import("node.zig").Direction;
const Element = @import("node.zig").Element;
const forbear = @import("root.zig");
const IncompleteStyle = @import("node.zig").IncompleteStyle;
const Node = @import("node.zig").Node;
const Sizing = @import("node.zig").Sizing;
const Style = @import("node.zig").Style;
const TextWrapping = @import("node.zig").TextWrapping;

const Vec4 = @Vector(4, f32);
const Vec3 = @Vector(3, f32);
const Vec2 = @Vector(2, f32);

pub const LayoutGlyph = struct {
    index: c_uint,
    position: Vec2,

    text: []const u8,

    /// Meant for the recalculation of the glyphs position if that's required
    /// at some other layouting step
    advance: Vec2,
    /// Meant for the recalculation of the glyphs position if that's required
    /// at some other layouting step
    offset: Vec2,
};

pub const Glyphs = struct {
    lineHeight: f32,
    slice: []LayoutGlyph,
};

pub const LayoutBox = struct {
    pub const Children = union(enum) {
        layoutBoxes: []LayoutBox,
        glyphs: Glyphs,
    };

    key: u64,

    position: Vec2,
    z: u16,
    size: Vec2,
    maxSize: Vec2,
    minSize: Vec2,
    children: ?Children,

    style: Style,

    pub fn debugPrint(self: @This(), indent: usize) void {
        for (0..indent) |_| {
            std.debug.print("  ", .{});
        }
        std.debug.print("LayoutBox (key: {}, pos: {}, size: {}, z: {})\n", .{ self.key, self.position, self.size, self.z });
        if (self.children) |children| {
            switch (children) {
                .layoutBoxes => |layoutBoxes| {
                    for (layoutBoxes) |*child| {
                        child.debugPrint(indent + 1);
                    }
                },
                .glyphs => |glyphs| {
                    for (glyphs.slice) |glyph| {
                        for (0..indent) |_| {
                            std.debug.print("  ", .{});
                        }
                        std.debug.print("Glyph (index: {}, pos: {}, text: \"{s}\")\n", .{ glyph.index, glyph.position, glyph.text });
                    }
                },
            }
        }
    }

    pub fn free(self: @This(), allocator: std.mem.Allocator) void {
        if (self.children) |children| {
            switch (children) {
                .layoutBoxes => |layoutBoxes| {
                    for (layoutBoxes) |*child| {
                        child.free(allocator);
                    }
                    allocator.free(layoutBoxes);
                },
                .glyphs => |glyphs| {
                    for (glyphs.slice) |*glyph| {
                        allocator.free(glyph.text);
                    }
                    allocator.free(glyphs.slice);
                },
            }
        }
    }

    pub fn setMinSize(self: *@This(), direction: Direction, size: f32) void {
        if (direction == .leftToRight) {
            self.minSize[0] = size;
        } else {
            self.minSize[1] = size;
        }
    }

    pub fn addMinSize(self: *@This(), direction: Direction, increment: f32) void {
        if (direction == .leftToRight) {
            self.minSize[0] += increment;
        } else {
            self.minSize[1] += increment;
        }
    }

    pub fn setSize(self: *@This(), direction: Direction, size: f32) void {
        if (direction == .leftToRight) {
            self.size[0] = size;
        } else {
            self.size[1] = size;
        }
    }

    pub fn addSize(self: *@This(), direction: Direction, increment: f32) void {
        if (direction == .leftToRight) {
            self.size[0] += increment;
        } else {
            self.size[1] += increment;
        }
    }

    pub fn getMinSize(self: @This(), direction: Direction) f32 {
        if (direction == .leftToRight) {
            return self.minSize[0];
        }
        return self.minSize[1];
    }

    pub fn getMaxSize(self: @This(), direction: Direction) f32 {
        if (direction == .leftToRight) {
            return self.maxSize[0];
        }
        return self.maxSize[1];
    }

    pub fn getSize(self: @This(), direction: Direction) f32 {
        if (direction == .leftToRight) {
            return self.size[0];
        }
        return self.size[1];
    }
};

fn makeAbsolute(layoutBox: *LayoutBox, base: Vec2) void {
    if (layoutBox.style.placement != .manual) {
        layoutBox.position += base;
    }

    if (layoutBox.children != null) {
        switch (layoutBox.children.?) {
            .layoutBoxes => |children| {
                for (children) |*child| {
                    makeAbsolute(child, layoutBox.position);
                }
            },
            .glyphs => |glyphs| {
                for (glyphs.slice) |*glyph| {
                    glyph.position += layoutBox.position;
                }
            },
        }
    }
}

fn approxEq(a: f32, b: f32) bool {
    return @abs(a - b) < 0.001;
}

fn readEnvBool(key: []const u8, default: bool) bool {
    const allocator = std.heap.page_allocator;
    const value = std.process.getEnvVarOwned(allocator, key) catch |err| {
        if (err != error.EnvironmentVariableNotFound) {
            std.log.warn("Failed to read env var {s}: {}", .{ key, err });
        }
        return default;
    };
    defer allocator.free(value);

    if (std.ascii.eqlIgnoreCase(value, "1") or std.ascii.eqlIgnoreCase(value, "true")) {
        return true;
    }
    if (std.ascii.eqlIgnoreCase(value, "0") or std.ascii.eqlIgnoreCase(value, "false")) {
        return false;
    }
    return default;
}

fn layoutDebugEnabled() bool {
    return readEnvBool("FORBEAR_LAYOUT_DEBUG", false);
}

fn shouldLogLoopIteration(iteration: usize) bool {
    return iteration <= 8 or iteration % 128 == 0;
}

fn logLayoutStage(debugEnabled: bool, stage: []const u8, layoutBox: *const LayoutBox) void {
    if (!debugEnabled) {
        return;
    }
    std.log.debug(
        "[layout-debug] {s}: rootKey={}, rootSize={any}, rootMin={any}, rootMax={any}",
        .{ stage, layoutBox.key, layoutBox.size, layoutBox.minSize, layoutBox.maxSize },
    );
}

fn growChildren(
    allocator: std.mem.Allocator,
    children: []LayoutBox,
    direction: Direction,
    remaining: *f32,
    parentKey: u64,
    debugEnabled: bool,
) !void {
    const loopWatchdogLimit: usize = 65_536;
    var toGrowGradually = try std.ArrayList(*LayoutBox).initCapacity(allocator, children.len);
    defer toGrowGradually.deinit(allocator);
    for (children) |*child| {
        if (child.style.placement == .standard) {
            if (child.style.getPreferredSize(direction) == .grow and child.getSize(direction) < child.getMaxSize(direction)) {
                try toGrowGradually.append(allocator, child);
            }
        }
    }

    var iteration: usize = 0;
    while (remaining.* > 0.001 and toGrowGradually.items.len > 0) {
        iteration += 1;
        if (debugEnabled and shouldLogLoopIteration(iteration)) {
            std.log.debug(
                "[layout-debug] growChildren start: key={}, dir={s}, iter={}, active={}, remaining={d:.4}",
                .{ parentKey, @tagName(direction), iteration, toGrowGradually.items.len, remaining.* },
            );
        }
        if (debugEnabled and iteration > loopWatchdogLimit) {
            std.log.err(
                "[layout-debug] growChildren watchdog hit: key={}, dir={s}, iter={}, remaining={d:.4}, active={}",
                .{ parentKey, @tagName(direction), iteration, remaining.*, toGrowGradually.items.len },
            );
            break;
        }

        var smallest: f32 = std.math.inf(f32);
        var secondSmallest = std.math.inf(f32);

        var index: usize = 0;
        while (index < toGrowGradually.items.len) {
            const child = toGrowGradually.items[index];
            if (approxEq(child.getSize(direction), child.getMaxSize(direction))) {
                _ = toGrowGradually.orderedRemove(index);
                continue;
            }
            if (child.getSize(direction) < smallest and child.getSize(direction) < child.getMaxSize(direction)) {
                smallest = child.getSize(direction);
            } else if (child.getSize(direction) < secondSmallest and child.getSize(direction) < child.getMaxSize(direction)) {
                secondSmallest = child.getSize(direction);
            }
            index += 1;
        }
        if (toGrowGradually.items.len == 0) {
            if (debugEnabled) {
                std.log.debug(
                    "[layout-debug] growChildren stop: key={}, dir={s}, iter={} (no growable children remain)",
                    .{ parentKey, @tagName(direction), iteration },
                );
            }
            break;
        }

        // This ensures these two elements don't become so large that the remaining
        // space ends up not being shared across all of the elements
        var toAdd = @min(
            secondSmallest - smallest,
            remaining.* / @as(f32, @floatFromInt(toGrowGradually.items.len)),
        );
        // This avoids an infinte loop. It means all the children are the same size and
        // we can simply share the remaining space across all of them
        if (toAdd == 0) {
            toAdd = remaining.* / @as(f32, @floatFromInt(toGrowGradually.items.len));
        }
        const remainingBeforeLoop = remaining.*;
        for (toGrowGradually.items) |child| {
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
    allocator: std.mem.Allocator,
    children: []LayoutBox,
    direction: Direction,
    remaining: *f32,
    parentKey: u64,
    debugEnabled: bool,
) !void {
    const loopWatchdogLimit: usize = 65_536;
    if (remaining.* >= -0.001) {
        return;
    }

    var toShrinkGradually = try std.ArrayList(*LayoutBox).initCapacity(allocator, children.len);
    defer toShrinkGradually.deinit(allocator);
    for (children) |*child| {
        if (child.style.placement == .standard) {
            if (child.getSize(direction) > child.getMinSize(direction)) {
                try toShrinkGradually.append(allocator, child);
            }
        }
    }
    var iteration: usize = 0;
    while (remaining.* < -0.001 and toShrinkGradually.items.len > 0) {
        iteration += 1;
        if (debugEnabled and shouldLogLoopIteration(iteration)) {
            std.log.debug(
                "[layout-debug] shrinkChildren start: key={}, dir={s}, iter={}, active={}, remaining={d:.4}",
                .{ parentKey, @tagName(direction), iteration, toShrinkGradually.items.len, remaining.* },
            );
        }
        if (debugEnabled and iteration > loopWatchdogLimit) {
            std.log.err(
                "[layout-debug] shrinkChildren watchdog hit: key={}, dir={s}, iter={}, remaining={d:.4}, active={}",
                .{ parentKey, @tagName(direction), iteration, remaining.*, toShrinkGradually.items.len },
            );
            break;
        }

        var largest: f32 = toShrinkGradually.items[0].getSize(direction);
        var secondLargest: f32 = 0.0;

        var index: usize = 0;
        while (index < toShrinkGradually.items.len) {
            const child = toShrinkGradually.items[index];
            if (approxEq(child.getSize(direction), child.getMinSize(direction))) {
                _ = toShrinkGradually.orderedRemove(index);
                if (index == 0 and toShrinkGradually.items.len > 0) {
                    largest = toShrinkGradually.items[0].getSize(direction);
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
        if (toShrinkGradually.items.len == 0) {
            if (debugEnabled) {
                std.log.debug(
                    "[layout-debug] shrinkChildren stop: key={}, dir={s}, iter={} (no shrinkable children remain)",
                    .{ parentKey, @tagName(direction), iteration },
                );
            }
            break;
        }

        var toSubtract = @min(
            largest - secondLargest,
            -remaining.* / @as(f32, @floatFromInt(toShrinkGradually.items.len)),
        );
        if (toSubtract == 0) {
            toSubtract = -remaining.* / @as(f32, @floatFromInt(toShrinkGradually.items.len));
        }
        const remainingBeforeLoop = remaining.*;
        for (toShrinkGradually.items) |child| {
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
            if (debugEnabled) {
                std.log.warn(
                    "[layout-debug] shrinkChildren stalled: key={}, dir={s}, iter={}, remaining={d:.4}, largest={d:.4}, secondLargest={d:.4}, toSubtract={d:.4}, active={}",
                    .{
                        parentKey,
                        @tagName(direction),
                        iteration,
                        remaining.*,
                        largest,
                        secondLargest,
                        toSubtract,
                        toShrinkGradually.items.len,
                    },
                );
            }
            break;
        }
    }
}

fn growAndShrink(
    allocator: std.mem.Allocator,
    layoutBox: *LayoutBox,
) !void {
    try growAndShrinkWithDebug(allocator, layoutBox, layoutDebugEnabled());
}

fn growAndShrinkWithDebug(
    allocator: std.mem.Allocator,
    layoutBox: *LayoutBox,
    debugEnabled: bool,
) !void {
    if (layoutBox.children != null and layoutBox.children.? == .layoutBoxes) {
        const children = layoutBox.children.?.layoutBoxes;
        const direction = layoutBox.style.direction;

        var remaining = layoutBox.getSize(direction);
        for (children) |*child| {
            if (child.style.placement == .standard) {
                if (direction.perpendicular() == .topToBottom) {
                    if (child.style.height == .grow or (child.size[1] > layoutBox.size[1] and child.minSize[1] < child.size[1])) {
                        child.size[1] = @max(@min(layoutBox.size[1], child.maxSize[1]), child.minSize[1]);
                    }
                } else if (direction.perpendicular() == .leftToRight) {
                    if (child.style.width == .grow or (child.size[0] > layoutBox.size[0] and child.minSize[0] < child.size[0])) {
                        child.size[0] = @max(@min(layoutBox.size[0], child.maxSize[0]), child.minSize[0]);
                    }
                }
                applyOwnRatios(child);
                remaining -= child.getSize(direction);
            }
        }
        if (debugEnabled) {
            std.log.debug(
                "[layout-debug] growAndShrink begin: key={}, dir={s}, childCount={}, parentSize={any}, initialRemaining={d:.4}",
                .{ layoutBox.key, @tagName(direction), children.len, layoutBox.size, remaining },
            );
        }
        try growChildren(allocator, children, direction, &remaining, layoutBox.key, debugEnabled);
        try shrinkChildren(allocator, children, direction, &remaining, layoutBox.key, debugEnabled);
        if (debugEnabled and @abs(remaining) > 0.001) {
            std.log.debug(
                "[layout-debug] growAndShrink residual: key={}, dir={s}, remaining={d:.4}",
                .{ layoutBox.key, @tagName(direction), remaining },
            );
        }
        for (children) |*child| {
            try growAndShrinkWithDebug(allocator, child, debugEnabled);
        }
    }
}

fn wrap(arena: std.mem.Allocator, layoutBox: *LayoutBox) !void {
    if (layoutBox.children) |children| {
        switch (children) {
            .layoutBoxes => |childBoxes| {
                for (childBoxes) |*child| {
                    try wrap(arena, child);
                }
            },
            .glyphs => |glyphs| {
                if (layoutBox.style.textWrapping == .none) {
                    return;
                }
                const Line = struct {
                    startIndex: usize,
                    endIndex: usize,
                };
                var lines = try std.ArrayList(Line).initCapacity(arena, 4);

                const lineWidth = layoutBox.size[0];
                var cursor: Vec2 = @splat(0.0);
                var lineStartIndex: usize = 0;
                switch (layoutBox.style.textWrapping) {
                    .character => {
                        for (glyphs.slice, 0..) |*glyph, index| {
                            if (cursor[0] + glyph.advance[0] > lineWidth) {
                                try lines.append(arena, .{
                                    .startIndex = lineStartIndex,
                                    .endIndex = index - 1,
                                });
                                lineStartIndex = index;
                                cursor[0] = 0.0;
                                cursor[1] += glyphs.lineHeight;
                            }

                            glyph.position = cursor + glyph.offset;
                            cursor += glyph.advance;
                        }
                    },
                    .word => {
                        var lastSpaceInfoOpt: ?struct {
                            index: usize,
                            position: Vec2,
                        } = null;
                        for (glyphs.slice, 0..) |*glyph, index| {
                            if (cursor[0] + glyph.advance[0] > lineWidth) {
                                if (lastSpaceInfoOpt) |lastSpaceInfo| {
                                    cursor[0] = 0;
                                    cursor[1] += glyphs.lineHeight;

                                    const firstWordGlyph = glyphs.slice[lastSpaceInfo.index + 1];
                                    try lines.append(arena, .{
                                        .startIndex = lineStartIndex,
                                        .endIndex = lastSpaceInfo.index,
                                    });

                                    for (lastSpaceInfo.index + 1..index) |reverseIndex| {
                                        const reverseGlyph = &glyphs.slice[reverseIndex];
                                        reverseGlyph.position[0] -= firstWordGlyph.position[0];
                                        reverseGlyph.position[1] += glyphs.lineHeight;

                                        cursor += reverseGlyph.advance;
                                    }
                                    lineStartIndex = lastSpaceInfo.index + 1;
                                    lastSpaceInfoOpt = null;
                                }
                            }

                            glyph.position = cursor + glyph.offset;
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
                    if (lastLine.endIndex != glyphs.slice.len - 1) {
                        try lines.append(arena, .{
                            .startIndex = lastLine.endIndex + 1,
                            .endIndex = glyphs.slice.len - 1,
                        });
                    }
                } else {
                    try lines.append(arena, .{
                        .startIndex = 0,
                        .endIndex = glyphs.slice.len - 1,
                    });
                }
                for (lines.items) |line| {
                    const startX = glyphs.slice[line.startIndex].position[0];
                    const endX = glyphs.slice[line.endIndex].position[0] + glyphs.slice[line.endIndex].advance[0];
                    const width = endX - startX;
                    for (glyphs.slice[line.startIndex .. line.endIndex + 1]) |*glyph| {
                        switch (layoutBox.style.alignment.x) {
                            .start => {},
                            .center => glyph.position[0] += (lineWidth - width) / 2.0,
                            .end => glyph.position[0] += lineWidth - width,
                        }
                    }
                }
                layoutBox.size[1] = cursor[1] + glyphs.lineHeight;
            },
        }
    }
}

fn applyOwnRatios(layoutBox: *LayoutBox) void {
    if (layoutBox.style.width == .ratio) {
        layoutBox.size[0] = layoutBox.style.width.ratio * layoutBox.size[1];
    }
    if (layoutBox.style.height == .ratio) {
        layoutBox.size[1] = layoutBox.style.height.ratio * layoutBox.size[0];
    }
}

fn applyRatios(layoutBox: *LayoutBox) void {
    applyOwnRatios(layoutBox);
    if (layoutBox.children) |children| {
        switch (children) {
            .layoutBoxes => |childBoxes| {
                for (childBoxes) |*child| {
                    applyRatios(child);
                }
            },
            else => {},
        }
    }
}

fn fitAlong(layoutBox: *LayoutBox, fitDirection: Direction) void {
    if (layoutBox.children) |children| {
        switch (children) {
            .layoutBoxes => |childBoxes| {
                const shouldFitMin = layoutBox.style.getPreferredSize(fitDirection) != .fixed and layoutBox.style.getMinSize(fitDirection) == null;
                const layoutDirection = layoutBox.style.direction;

                const paddingVector = layoutBox.style.padding.get(fitDirection);
                const padding = paddingVector[0] + paddingVector[1];

                const borderWidthVector = layoutBox.style.borderWidth.get(fitDirection);
                const border = borderWidthVector[0] + borderWidthVector[1];

                const size = layoutBox.style.getPreferredSize(fitDirection);
                if (size == .fit) {
                    layoutBox.setSize(fitDirection, padding + border);
                }
                if (shouldFitMin) {
                    layoutBox.setMinSize(fitDirection, padding + border);
                }
                for (childBoxes) |*child| {
                    fitAlong(child, fitDirection);
                    if (child.style.placement == .standard) {
                        const childMarginVector = child.style.margin.get(fitDirection);
                        const childMargins = childMarginVector[0] + childMarginVector[1];
                        if (layoutDirection == fitDirection) {
                            if (size == .fit) {
                                layoutBox.addSize(fitDirection, childMargins + child.getSize(fitDirection));
                            }
                            if (shouldFitMin) {
                                layoutBox.addMinSize(fitDirection, childMargins + child.getMinSize(fitDirection));
                            }
                        }
                        if (layoutDirection != fitDirection) {
                            if (size == .fit) {
                                layoutBox.setSize(fitDirection, @max(
                                    childMargins + padding + border + child.getSize(fitDirection),
                                    layoutBox.getSize(fitDirection),
                                ));
                            }
                            if (shouldFitMin) {
                                layoutBox.setMinSize(
                                    fitDirection,
                                    @max(childMargins + padding + border + child.getMinSize(fitDirection), layoutBox.getMinSize(fitDirection)),
                                );
                            }
                        }
                    }
                }
            },
            else => {},
        }
    }
}

fn place(layoutBox: *LayoutBox) void {
    layoutBox.position += layoutBox.style.translate;
    if (layoutBox.children != null) {
        switch (layoutBox.children.?) {
            .layoutBoxes => |children| {
                const direction = layoutBox.style.direction;
                const hAlign = layoutBox.style.alignment.x;
                const vAlign = layoutBox.style.alignment.y;

                const availableSize = .{
                    layoutBox.size[0] - (layoutBox.style.padding.x[0] + layoutBox.style.padding.x[1]) - (layoutBox.style.borderWidth.x[0] + layoutBox.style.borderWidth.x[1]),
                    layoutBox.size[1] - (layoutBox.style.padding.y[0] + layoutBox.style.padding.y[1]) - (layoutBox.style.borderWidth.y[0] + layoutBox.style.borderWidth.y[1]),
                };

                var childrenSize: Vec2 = @splat(0.0);
                for (children) |child| {
                    if (child.style.placement == .standard) {
                        const contributingSize = Vec2{
                            child.size[0] + child.style.margin.x[0] + child.style.margin.x[1],
                            child.size[1] + child.style.margin.y[0] + child.style.margin.y[1],
                        };
                        if (direction == .leftToRight) {
                            childrenSize[0] += contributingSize[0];
                            childrenSize[1] = @max(contributingSize[1], childrenSize[1]);
                        } else if (direction == .topToBottom) {
                            childrenSize[0] = @max(contributingSize[0], childrenSize[0]);
                            childrenSize[1] += contributingSize[1];
                        }
                    }
                }

                var cursor: Vec2 = .{
                    layoutBox.style.padding.x[0] + layoutBox.style.borderWidth.x[0],
                    layoutBox.style.padding.y[0] + layoutBox.style.borderWidth.y[0],
                };
                if (direction == .leftToRight) {
                    switch (hAlign) {
                        .start => {},
                        .center => cursor[0] += (availableSize[0] - childrenSize[0]) / 2.0,
                        .end => cursor[0] += (availableSize[0] - childrenSize[0]),
                    }
                } else {
                    switch (vAlign) {
                        .start => {},
                        .center => cursor[1] += (availableSize[1] - childrenSize[1]) / 2.0,
                        .end => cursor[1] += (availableSize[1] - childrenSize[1]),
                    }
                }

                for (children) |*child| {
                    if (child.style.placement == .standard) {
                        const contributingSize = Vec2{
                            child.size[0] + child.style.margin.x[0] + child.style.margin.x[1],
                            child.size[1] + child.style.margin.y[0] + child.style.margin.y[1],
                        };
                        if (direction == .leftToRight) {
                            // Cross-axis alignment (Vertical)
                            switch (vAlign) {
                                .start => child.position[1] = child.style.margin.y[0],
                                .center => child.position[1] = (availableSize[1] - contributingSize[1]) / 2.0,
                                .end => child.position[1] = (availableSize[1] - contributingSize[1]),
                            }

                            cursor[0] += child.style.margin.x[0];
                            child.position += cursor;
                            cursor[0] += child.size[0] + child.style.margin.x[1];
                        } else {
                            // Cross-axis alignment (Horizontal)
                            switch (hAlign) {
                                .start => child.position[0] = child.style.margin.x[0],
                                .center => child.position[0] = (availableSize[0] - contributingSize[0]) / 2.0,
                                .end => child.position[0] = (availableSize[0] - contributingSize[0]),
                            }

                            cursor[1] += child.style.margin.y[0];
                            child.position += cursor;
                            cursor[1] += child.size[1] + child.style.margin.y[1];
                        }
                    }
                    place(child);
                }
            },
            else => {},
        }
    }
}

const LayoutCreator = struct {
    arenaAllocator: std.mem.Allocator,
    parent: ?LayoutBox,

    fn init(arenaAllocator: std.mem.Allocator) !@This() {
        return .{
            .arenaAllocator = arenaAllocator,
            .parent = null,
        };
    }

    fn create(self: *@This(), node: Node, baseStyle: BaseStyle, z: u16, dpi: Vec2) !LayoutBox {
        const resolutionMultiplier = dpi / @as(Vec2, @splat(72));
        var style = switch (node.content) {
            .element => |element| element.style.completeWith(baseStyle),
            .text => (IncompleteStyle{
                .alignment = if (self.parent) |parent| .{
                    .x = parent.style.alignment.x,
                    .y = .start,
                } else null,
            }).completeWith(baseStyle),
        };
        style.borderWidth.x *= @splat(resolutionMultiplier[0]);
        style.borderWidth.y *= @splat(resolutionMultiplier[1]);
        if (style.shadow) |*shadow| {
            shadow.offset.x *= @splat(resolutionMultiplier[0]);
            shadow.offset.y *= @splat(resolutionMultiplier[1]);
            shadow.blurRadius *= resolutionMultiplier[0];
            shadow.spread *= resolutionMultiplier[0];
        }
        style.padding.x *= @splat(resolutionMultiplier[0]);
        style.padding.y *= @splat(resolutionMultiplier[1]);
        style.margin.x *= @splat(resolutionMultiplier[0]);
        style.margin.y *= @splat(resolutionMultiplier[1]);
        style.borderRadius *= resolutionMultiplier[0];

        switch (node.content) {
            .element => |element| {
                var layoutBox = LayoutBox{
                    .position = if (style.placement == .manual) style.placement.manual else .{ 0.0, 0.0 },
                    .z = if (style.zIndex) |zIndex| zIndex else z,
                    .size = .{
                        switch (style.width) {
                            .fixed => |width| width,
                            .ratio => |ratio| if (style.height == .fixed)
                                style.height.fixed * ratio
                            else
                                0.0,
                            .fit, .grow => 0.0,
                        },
                        switch (style.height) {
                            .fixed => |height| height,
                            .ratio => |ratio| if (style.width == .fixed)
                                style.width.fixed * ratio
                            else
                                0.0,
                            .fit, .grow => 0.0,
                        },
                    },
                    .minSize = .{
                        style.minWidth orelse if (style.width == .fixed) style.width.fixed else 0.0,
                        style.minHeight orelse if (style.height == .fixed) style.height.fixed else 0.0,
                    },
                    .maxSize = .{
                        style.maxWidth orelse if (style.width == .fixed) style.width.fixed else std.math.inf(f32),
                        style.maxHeight orelse if (style.height == .fixed) style.height.fixed else std.math.inf(f32),
                    },
                    .key = node.key,
                    .children = null,
                    .style = style,
                };
                layoutBox.children = .{ .layoutBoxes = try self.arenaAllocator.alloc(LayoutBox, element.children.items.len) };
                errdefer self.arenaAllocator.free(layoutBox.children.?.layoutBoxes);
                const previousParent = self.parent;
                self.parent = layoutBox;
                for (element.children.items, 0..) |child, index| {
                    layoutBox.children.?.layoutBoxes[index] = try self.create(
                        child,
                        BaseStyle.from(style),
                        if (layoutBox.z == std.math.maxInt(u16)) layoutBox.z else layoutBox.z + 1,
                        dpi,
                    );
                }
                self.parent = previousParent;
                return layoutBox;
            },
            .text => |text| {
                const unitsPerEm: f32 = @floatFromInt(style.font.unitsPerEm());
                const unitsPerEmVec2: Vec2 = @splat(unitsPerEm);
                const pixelSizeVec2: Vec2 = @as(Vec2, @splat(style.fontSize)) * resolutionMultiplier;
                const pixelLineHeight = style.font.lineHeight() * style.lineHeight / unitsPerEm * pixelSizeVec2[1];

                const shapedGlyphs = try style.font.shape(text);
                var layoutGlyphs = try self.arenaAllocator.alloc(LayoutGlyph, shapedGlyphs.len);
                errdefer self.arenaAllocator.free(layoutGlyphs);
                var cursor: Vec2 = @splat(0.0);

                var minSize: Vec2 = .{ 0.0, pixelLineHeight };
                var maxSize: Vec2 = .{ 0.0, pixelLineHeight };

                var wordStart: usize = 0;
                var wordAdvance: Vec2 = @splat(0.0);
                for (shapedGlyphs, 0..) |shapedGlyph, i| {
                    const advance = shapedGlyph.advance / unitsPerEmVec2 * pixelSizeVec2;
                    const offset = shapedGlyph.offset / unitsPerEmVec2 * pixelSizeVec2;
                    const glyphText = try self.arenaAllocator.dupe(u8, shapedGlyph.utf8.Encoded[0..@intCast(shapedGlyph.utf8.EncodedLength)]);
                    layoutGlyphs[i] = LayoutGlyph{
                        .index = @intCast(shapedGlyph.index),
                        .position = cursor + offset,

                        .text = glyphText,

                        .advance = advance,
                        .offset = offset,
                    };

                    cursor += advance;
                    if (style.textWrapping == .word) {
                        if (std.mem.eql(u8, glyphText, " ")) {
                            wordStart = i;
                            wordAdvance = @splat(0.0);
                        } else {
                            wordAdvance += advance;
                        }
                        minSize = @max(minSize, wordAdvance);
                        maxSize[1] += pixelLineHeight;
                    } else if (style.textWrapping == .character) {
                        minSize = @max(minSize, advance);
                        maxSize[1] += pixelLineHeight;
                    } else if (style.textWrapping == .none) {
                        minSize = cursor;
                    }
                }
                maxSize[0] = cursor[0];

                return LayoutBox{
                    .position = .{ 0.0, 0.0 },
                    .z = z,
                    .key = node.key,
                    .size = .{ cursor[0], pixelLineHeight },
                    .minSize = minSize,
                    .maxSize = maxSize,
                    .children = .{ .glyphs = Glyphs{ .slice = layoutGlyphs, .lineHeight = pixelLineHeight } },
                    .style = style,
                };
            },
        }
    }
};

pub const LayoutTreeIterator = struct {
    stack: std.ArrayList(*const LayoutBox),
    allocator: std.mem.Allocator,

    root: *const LayoutBox,

    pub fn init(allocator: std.mem.Allocator, root: *const LayoutBox) !@This() {
        var iterator = @This(){
            .stack = try std.ArrayList(*const LayoutBox).initCapacity(allocator, 16),
            .allocator = allocator,
            .root = root,
        };
        try iterator.stack.append(allocator, root);
        return iterator;
    }

    pub fn deinit(self: *@This()) void {
        self.stack.deinit(self.allocator);
    }

    pub fn reset(self: *@This()) !void {
        self.stack.clearRetainingCapacity();
        try self.stack.append(self.allocator, self.root);
    }

    pub fn next(self: *@This()) !?*const LayoutBox {
        if (self.stack.items.len == 0) {
            return null;
        }
        const current = self.stack.pop();
        if (current != null and current.?.children != null) {
            if (current.?.children.? == .layoutBoxes) {
                for (current.?.children.?.layoutBoxes) |*child| {
                    try self.stack.append(self.allocator, child);
                }
            }
        }
        return current;
    }
};

pub fn countTreeSize(layoutBox: *const LayoutBox) usize {
    var count: usize = 1;
    if (layoutBox.children != null and layoutBox.children.? == .layoutBoxes) {
        for (layoutBox.children.?.layoutBoxes) |*child| {
            count += countTreeSize(child);
        }
    }
    return count;
}

pub fn layout(
    arena: std.mem.Allocator,
    baseStyle: BaseStyle,
    viewportSize: Vec2,
    dpi: Vec2,
) !LayoutBox {
    const context = forbear.getContext();
    if (context.rootFrameNode) |node| {
        const debugEnabled = layoutDebugEnabled();
        var startNs: i128 = 0;
        if (debugEnabled) {
            startNs = std.time.nanoTimestamp();
            std.log.debug("[layout-debug] layout start: viewport={any}, dpi={any}", .{ viewportSize, dpi });
        }

        var creator = try LayoutCreator.init(arena);
        var layoutBox = try creator.create(node, baseStyle, 1, dpi);
        if (debugEnabled) {
            std.log.debug("[layout-debug] created tree with {} nodes", .{countTreeSize(&layoutBox)});
        }
        logLayoutStage(debugEnabled, "after create", &layoutBox);
        fitAlong(&layoutBox, .leftToRight);
        fitAlong(&layoutBox, .topToBottom);
        logLayoutStage(debugEnabled, "after fitAlong x/y", &layoutBox);
        if (layoutBox.style.width == .grow) {
            layoutBox.size[0] = @min(@max(viewportSize[0], layoutBox.minSize[0]), layoutBox.maxSize[0]);
        }
        if (layoutBox.style.height == .grow) {
            layoutBox.size[1] = @min(@max(viewportSize[1], layoutBox.minSize[1]), layoutBox.maxSize[1]);
        }
        logLayoutStage(debugEnabled, "after root grow clamp", &layoutBox);
        applyRatios(&layoutBox);
        logLayoutStage(debugEnabled, "after applyRatios #1", &layoutBox);
        try growAndShrinkWithDebug(arena, &layoutBox, debugEnabled);
        logLayoutStage(debugEnabled, "after growAndShrink #1", &layoutBox);
        applyRatios(&layoutBox);
        logLayoutStage(debugEnabled, "after applyRatios #2", &layoutBox);
        try growAndShrinkWithDebug(arena, &layoutBox, debugEnabled);
        logLayoutStage(debugEnabled, "after growAndShrink #2", &layoutBox);
        try wrap(arena, &layoutBox);
        logLayoutStage(debugEnabled, "after wrap", &layoutBox);
        fitAlong(&layoutBox, .leftToRight);
        fitAlong(&layoutBox, .topToBottom);
        logLayoutStage(debugEnabled, "after fitAlong x/y #2", &layoutBox);
        applyRatios(&layoutBox);
        logLayoutStage(debugEnabled, "after applyRatios #3", &layoutBox);
        try growAndShrinkWithDebug(arena, &layoutBox, debugEnabled);
        logLayoutStage(debugEnabled, "after growAndShrink #3", &layoutBox);

        place(&layoutBox);
        makeAbsolute(&layoutBox, @as(Vec2, @splat(-1.0)) * context.scrollPosition);
        if (debugEnabled) {
            const elapsedMs: f64 = @as(f64, @floatFromInt(std.time.nanoTimestamp() - startNs)) / 1_000_000.0;
            std.log.debug(
                "[layout-debug] layout end: elapsed={d:.3}ms, rootPos={any}, rootSize={any}, scroll={any}",
                .{ elapsedMs, layoutBox.position, layoutBox.size, context.scrollPosition },
            );
        }
        return layoutBox;
    } else {
        std.log.err("You need to define a root frame node before layouting. You can do so by just doing forbear.text(...), for example.", .{});
        return error.NoRootFrameNode;
    }
}

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

    var layoutBox = LayoutBox{
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
        }),
    };

    try wrap(arenaAllocator, &layoutBox);

    const glyphPositions = try arenaAllocator.alloc(Vec2, configuration.glyphs.len);
    for (configuration.glyphs, 0..) |glyph, i| {
        glyphPositions[i] = glyph.position;
    }
    try std.testing.expectEqualDeep(configuration.expectedPositions, glyphPositions);
}

const defaultBaseStyle = BaseStyle{
    .font = undefined,
    .color = .{ 0.0, 0.0, 0.0, 1.0 },
    .fontSize = 16,
    .fontWeight = 400,
    .lineHeight = 1.0,
    .textWrapping = .none,
    .blendMode = .normal,
};

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

    const childBoxes = try arenaAllocator.alloc(LayoutBox, configuration.children.len);
    for (configuration.children, 0..) |child, i| {
        childBoxes[i] = LayoutBox{
            .key = @intCast(i),
            .position = .{ 0.0, 0.0 },
            .z = 0,
            .size = child.size,
            .minSize = child.minSize,
            .maxSize = child.maxSize,
            .children = null,
            .style = (IncompleteStyle{
                .width = child.width,
                .height = child.height,
            }).completeWith(defaultBaseStyle),
        };
    }

    var parent = LayoutBox{
        .key = 999,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = configuration.parentSize,
        .minSize = .{ 0.0, 0.0 },
        .maxSize = configuration.parentSize,
        .children = .{ .layoutBoxes = childBoxes },
        .style = (IncompleteStyle{
            .direction = configuration.direction,
        }).completeWith(defaultBaseStyle),
    };

    try growAndShrink(arenaAllocator, &parent);

    const actualSizes = try arenaAllocator.alloc(Vec2, configuration.children.len);
    for (parent.children.?.layoutBoxes, 0..) |child, i| {
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

test "fitAlong - vertical fit uses height axis fields" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const childBoxes = try arenaAllocator.alloc(LayoutBox, 2);
    childBoxes[0] = LayoutBox{
        .key = 1,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 20.0, 30.0 },
        .minSize = .{ 20.0, 30.0 },
        .maxSize = .{ 20.0, 30.0 },
        .children = null,
        .style = (IncompleteStyle{
            .width = .{ .fixed = 20.0 },
            .height = .{ .fixed = 30.0 },
            .margin = forbear.Margin.block(1.0).withBottom(2.0),
        }).completeWith(defaultBaseStyle),
    };
    childBoxes[1] = LayoutBox{
        .key = 2,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 20.0, 40.0 },
        .minSize = .{ 20.0, 40.0 },
        .maxSize = .{ 20.0, 40.0 },
        .children = null,
        .style = (IncompleteStyle{
            .width = .{ .fixed = 20.0 },
            .height = .{ .fixed = 40.0 },
            .margin = forbear.Margin.block(3.0).withBottom(4.0),
        }).completeWith(defaultBaseStyle),
    };

    var parent = LayoutBox{
        .key = 999,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 100.0, 0.0 },
        .minSize = .{ 100.0, 0.0 },
        .maxSize = .{ 100.0, std.math.inf(f32) },
        .children = .{ .layoutBoxes = childBoxes },
        .style = (IncompleteStyle{
            .direction = .topToBottom,
            .width = .{ .fixed = 100.0 },
            .height = .fit,
            .padding = forbear.Padding.block(10.0).withBottom(20.0),
            .borderWidth = forbear.BorderWidth.block(2.0).withBottom(3.0),
        }).completeWith(defaultBaseStyle),
    };

    fitAlong(&parent, .topToBottom);

    // height = (paddingY + borderY) + sum(child marginY + child height)
    try std.testing.expectEqual(@as(f32, 115.0), parent.size[1]);
    try std.testing.expectEqual(@as(f32, 115.0), parent.minSize[1]);
}

test "fitAlong - cross axis fit uses vertical padding and borders" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const childBoxes = try arenaAllocator.alloc(LayoutBox, 2);
    childBoxes[0] = LayoutBox{
        .key = 1,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 20.0, 30.0 },
        .minSize = .{ 20.0, 30.0 },
        .maxSize = .{ 20.0, 30.0 },
        .children = null,
        .style = (IncompleteStyle{
            .width = .{ .fixed = 20.0 },
            .height = .{ .fixed = 30.0 },
            .margin = forbear.Margin.block(1.0).withBottom(2.0),
        }).completeWith(defaultBaseStyle),
    };
    childBoxes[1] = LayoutBox{
        .key = 2,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 20.0, 40.0 },
        .minSize = .{ 20.0, 40.0 },
        .maxSize = .{ 20.0, 40.0 },
        .children = null,
        .style = (IncompleteStyle{
            .width = .{ .fixed = 20.0 },
            .height = .{ .fixed = 40.0 },
            .margin = forbear.Margin.block(3.0).withBottom(4.0),
        }).completeWith(defaultBaseStyle),
    };

    var parent = LayoutBox{
        .key = 999,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 100.0, 0.0 },
        .minSize = .{ 100.0, 0.0 },
        .maxSize = .{ 100.0, std.math.inf(f32) },
        .children = .{ .layoutBoxes = childBoxes },
        .style = (IncompleteStyle{
            .direction = .leftToRight,
            .width = .{ .fixed = 100.0 },
            .height = .fit,
            .padding = forbear.Padding.block(10.0).withBottom(20.0),
            .borderWidth = forbear.BorderWidth.block(2.0).withBottom(3.0),
        }).completeWith(defaultBaseStyle),
    };

    fitAlong(&parent, .topToBottom);

    // For leftToRight parent fitting height, we take max child contribution
    // plus vertical padding and border: max(1+2+30, 3+4+40) + (10+20) + (2+3)
    try std.testing.expectEqual(@as(f32, 82.0), parent.size[1]);
    try std.testing.expectEqual(@as(f32, 82.0), parent.minSize[1]);
}

test "wrap - no wrapping when glyphs fit on single line" {
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

test "wrap - character wrapping with small width" {
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

test "wrap - word wrapping with small width" {
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

test "wrap - alignment start" {
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

test "wrap - alignment center" {
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

test "wrap - alignment end" {
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

test "wrap - word wrapping with alignment start" {
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

test "wrap - word wrapping with alignment center" {
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

test "wrap - word wrapping with alignment end" {
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

test "ratio and grow passes are stable when reapplied" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const children = try arenaAllocator.alloc(LayoutBox, 2);
    children[0] = LayoutBox{
        .key = 1,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 0.0, 50.0 },
        .minSize = .{ 0.0, 0.0 },
        .maxSize = .{ std.math.inf(f32), 50.0 },
        .children = null,
        .style = (IncompleteStyle{
            .width = .{ .ratio = 0.2 },
            .height = .{ .fixed = 50.0 },
        }).completeWith(defaultBaseStyle),
    };
    children[1] = LayoutBox{
        .key = 2,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 0.0, 50.0 },
        .minSize = .{ 0.0, 0.0 },
        .maxSize = .{ std.math.inf(f32), 50.0 },
        .children = null,
        .style = (IncompleteStyle{
            .width = .grow,
            .height = .{ .fixed = 50.0 },
        }).completeWith(defaultBaseStyle),
    };

    var parent = LayoutBox{
        .key = 99,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 300.0, 50.0 },
        .minSize = .{ 300.0, 50.0 },
        .maxSize = .{ 300.0, 50.0 },
        .children = .{ .layoutBoxes = children },
        .style = (IncompleteStyle{
            .direction = .leftToRight,
            .width = .{ .fixed = 300.0 },
            .height = .{ .fixed = 50.0 },
        }).completeWith(defaultBaseStyle),
    };

    applyRatios(&parent);
    try growAndShrink(arenaAllocator, &parent);
    const firstRatio = parent.children.?.layoutBoxes[0].size[0];
    const firstGrow = parent.children.?.layoutBoxes[1].size[0];

    applyRatios(&parent);
    try growAndShrink(arenaAllocator, &parent);

    try std.testing.expectEqual(firstRatio, parent.children.?.layoutBoxes[0].size[0]);
    try std.testing.expectEqual(firstGrow, parent.children.?.layoutBoxes[1].size[0]);
    try std.testing.expectEqual(@as(f32, 10.0), parent.children.?.layoutBoxes[0].size[0]);
    try std.testing.expectEqual(@as(f32, 290.0), parent.children.?.layoutBoxes[1].size[0]);
}

test "layout pipeline - ratio and grow produce stable geometry" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const buildTree = struct {
        fn build(allocator: std.mem.Allocator) !void {
            (try forbear.element(allocator, .{
                .direction = .leftToRight,
                .width = .grow,
                .height = .{ .fixed = 100.0 },
            }))({
                (try forbear.element(allocator, .{
                    .width = .{ .ratio = 0.2 },
                    .height = .grow,
                }))({});
                (try forbear.element(allocator, .{
                    .width = .grow,
                    .height = .grow,
                }))({});
            });
        }
    }.build;

    try buildTree(arenaAllocator);
    const first = try layout(arenaAllocator, defaultBaseStyle, .{ 300.0, 400.0 }, .{ 72.0, 72.0 });

    const firstChildren = first.children.?.layoutBoxes;
    try std.testing.expectEqual(@as(usize, 2), firstChildren.len);
    try std.testing.expectEqual(@as(f32, 300.0), first.size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), first.size[1]);

    try std.testing.expectEqual(@as(f32, 20.0), firstChildren[0].size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), firstChildren[0].size[1]);
    try std.testing.expectEqual(@as(f32, 0.0), firstChildren[0].position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), firstChildren[0].position[1]);

    try std.testing.expectEqual(@as(f32, 280.0), firstChildren[1].size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), firstChildren[1].size[1]);
    try std.testing.expectEqual(@as(f32, 20.0), firstChildren[1].position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), firstChildren[1].position[1]);

    forbear.resetNodeTree();
    _ = arena.reset(.retain_capacity);

    try buildTree(arenaAllocator);
    const second = try layout(arenaAllocator, defaultBaseStyle, .{ 300.0, 400.0 }, .{ 72.0, 72.0 });
    const secondChildren = second.children.?.layoutBoxes;

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

    (try forbear.element(arenaAllocator, .{
        .direction = .leftToRight,
        .width = .{ .fixed = 200.0 },
        .height = .{ .fixed = 100.0 },
    }))({
        (try forbear.element(arenaAllocator, .{
            .width = .{ .ratio = 0.5 },
            .height = .grow,
        }))({});
        (try forbear.element(arenaAllocator, .{
            .placement = .{ .manual = .{ 10.0, 7.0 } },
            .width = .{ .fixed = 15.0 },
            .height = .{ .fixed = 12.0 },
        }))({});
        (try forbear.element(arenaAllocator, .{
            .width = .{ .fixed = 20.0 },
            .height = .grow,
        }))({});
    });

    const layoutBox = try layout(arenaAllocator, defaultBaseStyle, .{ 500.0, 500.0 }, .{ 72.0, 72.0 });

    try std.testing.expectEqual(@as(f32, 200.0), layoutBox.size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), layoutBox.size[1]);
    try std.testing.expectEqual(@as(f32, 0.0), layoutBox.position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), layoutBox.position[1]);

    const children = layoutBox.children.?.layoutBoxes;

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

    const buildTree = struct {
        fn build(allocator: std.mem.Allocator) !void {
            (try forbear.element(allocator, .{
                .direction = .topToBottom,
                .width = .{ .fixed = 120.0 },
                .height = .{ .fixed = 300.0 },
            }))({
                (try forbear.element(allocator, .{
                    .width = .grow,
                    .height = .{ .ratio = 0.5 },
                }))({});
                (try forbear.element(allocator, .{
                    .width = .grow,
                    .height = .grow,
                }))({});
            });
        }
    }.build;

    try buildTree(arenaAllocator);
    const first = try layout(arenaAllocator, defaultBaseStyle, .{ 500.0, 500.0 }, .{ 72.0, 72.0 });

    const firstChildren = first.children.?.layoutBoxes;
    try std.testing.expectEqual(@as(usize, 2), firstChildren.len);
    try std.testing.expectEqual(@as(f32, 120.0), first.size[0]);
    try std.testing.expectEqual(@as(f32, 300.0), first.size[1]);
    try std.testing.expectEqual(@as(f32, 0.0), first.position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), first.position[1]);

    try std.testing.expectEqual(@as(f32, 120.0), firstChildren[0].size[0]);
    try std.testing.expectEqual(@as(f32, 60.0), firstChildren[0].size[1]);
    try std.testing.expectEqual(@as(f32, 0.0), firstChildren[0].position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), firstChildren[0].position[1]);

    try std.testing.expectEqual(@as(f32, 120.0), firstChildren[1].size[0]);
    try std.testing.expectEqual(@as(f32, 240.0), firstChildren[1].size[1]);
    try std.testing.expectEqual(@as(f32, 0.0), firstChildren[1].position[0]);
    try std.testing.expectEqual(@as(f32, 60.0), firstChildren[1].position[1]);

    forbear.resetNodeTree();
    _ = arena.reset(.retain_capacity);

    try buildTree(arenaAllocator);
    const second = try layout(arenaAllocator, defaultBaseStyle, .{ 500.0, 500.0 }, .{ 72.0, 72.0 });
    const secondChildren = second.children.?.layoutBoxes;

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

test "layout pipeline - manual ratio child stays out of flow" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    (try forbear.element(arenaAllocator, .{
        .direction = .leftToRight,
        .width = .{ .fixed = 200.0 },
        .height = .{ .fixed = 100.0 },
    }))({
        (try forbear.element(arenaAllocator, .{
            .width = .{ .ratio = 0.5 },
            .height = .grow,
        }))({});
        (try forbear.element(arenaAllocator, .{
            .placement = .{ .manual = .{ 10.0, 7.0 } },
            .width = .{ .ratio = 0.5 },
            .height = .{ .fixed = 40.0 },
        }))({});
        (try forbear.element(arenaAllocator, .{
            .width = .{ .fixed = 20.0 },
            .height = .grow,
        }))({});
    });

    const layoutBox = try layout(arenaAllocator, defaultBaseStyle, .{ 500.0, 500.0 }, .{ 72.0, 72.0 });
    const children = layoutBox.children.?.layoutBoxes;

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

    const buildTree = struct {
        fn build(allocator: std.mem.Allocator) !void {
            (try forbear.element(allocator, .{
                .direction = .leftToRight,
                .width = .{ .fixed = 40.0 },
                .height = .{ .fixed = 100.0 },
            }))({
                (try forbear.element(allocator, .{
                    .width = .{ .ratio = 0.5 },
                    .height = .grow,
                }))({});
                (try forbear.element(allocator, .{
                    .width = .{ .fixed = 30.0 },
                    .height = .grow,
                }))({});
            });
        }
    }.build;

    try buildTree(arenaAllocator);
    const first = try layout(arenaAllocator, defaultBaseStyle, .{ 500.0, 500.0 }, .{ 72.0, 72.0 });
    const firstChildren = first.children.?.layoutBoxes;

    try std.testing.expectEqual(@as(usize, 2), firstChildren.len);
    try std.testing.expectEqual(@as(f32, 40.0), first.size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), first.size[1]);

    try std.testing.expectEqual(@as(f32, 10.0), firstChildren[0].size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), firstChildren[0].size[1]);
    try std.testing.expectEqual(@as(f32, 0.0), firstChildren[0].position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), firstChildren[0].position[1]);

    try std.testing.expectEqual(@as(f32, 30.0), firstChildren[1].size[0]);
    try std.testing.expectEqual(@as(f32, 100.0), firstChildren[1].size[1]);
    try std.testing.expectEqual(@as(f32, 10.0), firstChildren[1].position[0]);
    try std.testing.expectEqual(@as(f32, 0.0), firstChildren[1].position[1]);

    forbear.resetNodeTree();
    _ = arena.reset(.retain_capacity);

    try buildTree(arenaAllocator);
    const second = try layout(arenaAllocator, defaultBaseStyle, .{ 500.0, 500.0 }, .{ 72.0, 72.0 });
    const secondChildren = second.children.?.layoutBoxes;

    try std.testing.expectEqual(firstChildren[0].size[0], secondChildren[0].size[0]);
    try std.testing.expectEqual(firstChildren[1].size[0], secondChildren[1].size[0]);
    try std.testing.expectEqual(firstChildren[1].position[0], secondChildren[1].position[0]);
}

fn testCreateElementConfiguration(configuration: struct {
    style: IncompleteStyle,
    expectedSize: Vec2,
}) !void {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var creator = try LayoutCreator.init(arenaAllocator);
    const node = Node{
        .key = 1,
        .content = .{
            .element = .{
                .style = configuration.style,
                .children = .empty,
            },
        },
    };

    const layoutBox = try creator.create(node, defaultBaseStyle, 0, .{ 72.0, 72.0 });
    try std.testing.expectEqualDeep(configuration.expectedSize, layoutBox.size);
}

test "create - width ratio uses fixed height" {
    try testCreateElementConfiguration(.{
        .style = .{
            .width = .{ .ratio = 1.5 },
            .height = .{ .fixed = 40.0 },
        },
        .expectedSize = .{ 60.0, 40.0 },
    });
}

test "create - height ratio uses fixed width" {
    try testCreateElementConfiguration(.{
        .style = .{
            .width = .{ .fixed = 40.0 },
            .height = .{ .ratio = 1.5 },
        },
        .expectedSize = .{ 40.0, 60.0 },
    });
}

test "create - ratio without opposite fixed axis starts at zero" {
    try testCreateElementConfiguration(.{
        .style = .{
            .width = .{ .ratio = 2.0 },
            .height = .fit,
        },
        .expectedSize = .{ 0.0, 0.0 },
    });
}
