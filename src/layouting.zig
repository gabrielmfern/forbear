const std = @import("std");

const Alignment = @import("node.zig").Alignment;
const BaseStyle = @import("node.zig").BaseStyle;
const Direction = @import("node.zig").Direction;
const Element = @import("node.zig").Element;
const forbear = @import("root.zig");
const IncompleteStyle = @import("node.zig").IncompleteStyle;
const Node = @import("node.zig").Node;
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
    minSize: Vec2,
    children: ?Children,

    style: Style,

    pub fn getMinSize(self: @This(), direction: Direction) f32 {
        if (direction == .leftToRight) {
            return self.minSize[0];
        }
        return self.minSize[1];
    }

    pub fn getSize(self: @This(), direction: Direction) f32 {
        if (direction == .leftToRight) {
            return self.size[0];
        }
        return self.size[1];
    }
};

fn makeAbsolute(layoutBox: *LayoutBox, base: Vec2) void {
    layoutBox.position += base;

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

fn growAndShrink(
    allocator: std.mem.Allocator,
    layoutBox: *LayoutBox,
) !void {
    if (layoutBox.children != null and layoutBox.children.? == .layoutBoxes) {
        const children = layoutBox.children.?.layoutBoxes;
        const direction = layoutBox.style.direction;

        var toGrowGradually = try std.ArrayList(*LayoutBox).initCapacity(allocator, children.len);
        defer toGrowGradually.deinit(allocator);
        var remaining = layoutBox.getSize(direction);
        for (children) |*child| {
            if (child.style.placement == .standard) {
                remaining -= child.getSize(direction);
                if (direction.perpendicular() == .topToBottom) {
                    if (child.style.preferredHeight == .grow or (child.size[1] > layoutBox.size[1] and child.minSize[1] < child.size[1])) {
                        child.size[1] = @max(layoutBox.size[1], child.minSize[1]);
                    }
                } else if (direction.perpendicular() == .leftToRight) {
                    if (child.style.preferredWidth == .grow or (child.size[0] > layoutBox.size[0] and child.minSize[0] < child.size[0])) {
                        child.size[0] = @max(layoutBox.size[0], child.minSize[0]);
                    }
                }
                if (child.style.getPreferredSize(direction) == .grow) {
                    try toGrowGradually.append(allocator, child);
                }
            }
        }
        if (toGrowGradually.items.len > 0) {
            while (remaining > 0) {
                var smallest = remaining;
                var secondSmallest = std.math.inf(f32);
                for (toGrowGradually.items) |child| {
                    if (child.getSize(direction) < smallest) {
                        smallest = child.getSize(direction);
                    } else if (child.getSize(direction) < secondSmallest) {
                        secondSmallest = child.getSize(direction);
                    }
                }
                // This ensures these two elements don't become so large that the remaining
                // space ends up not being shared across all of the elements
                var toAdd = @min(
                    secondSmallest - smallest,
                    remaining / @as(f32, @floatFromInt(toGrowGradually.items.len)),
                );
                // This avoids an infinte loop. It means all the children are the same size and
                // we can simply share the remaining space across all of them
                if (toAdd == 0) {
                    toAdd = remaining / @as(f32, @floatFromInt(toGrowGradually.items.len));
                }
                for (toGrowGradually.items) |child| {
                    if (direction == .leftToRight) {
                        if (child.size[0] == smallest) {
                            child.size[0] += toAdd;
                            remaining -= toAdd;
                        }
                    } else {
                        if (child.size[1] == smallest) {
                            child.size[1] += toAdd;
                            remaining -= toAdd;
                        }
                    }
                }
            }
        }

        if (remaining < 0) {
            var toShrinkGradually = try std.ArrayList(*LayoutBox).initCapacity(allocator, children.len);
            defer toShrinkGradually.deinit(allocator);
            for (children) |*child| {
                if (child.style.placement == .standard) {
                    if (child.getSize(direction) > child.getMinSize(direction)) {
                        try toShrinkGradually.append(allocator, child);
                    }
                }
            }
            while (remaining < -0.0000001 and toShrinkGradually.items.len > 0) {
                var largest: f32 = toShrinkGradually.items[0].getSize(direction);
                var secondLargest: f32 = 0.0;

                var index: usize = 0;
                while (index < toShrinkGradually.items.len) {
                    const child = toShrinkGradually.items[index];
                    if (child.getSize(direction) == child.getMinSize(direction)) {
                        _ = toShrinkGradually.orderedRemove(index);
                        continue;
                    }
                    if (child.getSize(direction) > largest) {
                        largest = child.getSize(direction);
                    } else if (child.getSize(direction) > secondLargest) {
                        secondLargest = child.getSize(direction);
                    }
                    index += 1;
                }
                var toSubtract = @min(
                    largest - secondLargest,
                    -remaining / @as(f32, @floatFromInt(toShrinkGradually.items.len)),
                );
                if (toSubtract == 0) {
                    toSubtract = -remaining / @as(f32, @floatFromInt(toShrinkGradually.items.len));
                }
                for (toShrinkGradually.items) |child| {
                    if (child.getSize(direction) == largest) {
                        if (child.getSize(direction) - toSubtract <= child.minSize[0]) {
                            if (direction == .leftToRight) {
                                child.size[0] = child.minSize[0];
                                remaining += @abs(toSubtract - child.minSize[0]);
                            } else {
                                child.size[1] = child.minSize[1];
                                remaining += @abs(toSubtract - child.minSize[1]);
                            }
                        } else {
                            if (direction == .leftToRight) {
                                child.size[0] = child.size[0] - toSubtract;
                            } else {
                                child.size[1] = child.size[1] - toSubtract;
                            }
                            remaining += toSubtract;
                        }
                    }
                }
            }
        }
        for (children) |*child| {
            try growAndShrink(allocator, child);
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
                    // std.debug.print("line start {}\n", .{line});
                    const startX = glyphs.slice[line.startIndex].position[0];
                    const endX = glyphs.slice[line.endIndex].position[0] + glyphs.slice[line.endIndex].advance[0];
                    const width = endX - startX;
                    for (glyphs.slice[line.startIndex .. line.endIndex + 1]) |*glyph| {
                        // std.debug.print("glyph {}\n", .{glyph.*});
                        switch (layoutBox.style.horizontalAlignment) {
                            .start => {},
                            .center => glyph.position[0] += (lineWidth - width) / 2.0,
                            .end => glyph.position[0] += lineWidth - width,
                        }
                        // std.debug.print("glyph after {}\n", .{glyph.*});
                        // std.debug.print("\n", .{});
                    }
                    // std.debug.print("\n", .{});
                }
                layoutBox.size[1] = cursor[1] + glyphs.lineHeight;
            },
        }
    }
}

fn fitHeight(layoutBox: *LayoutBox) void {
    if (layoutBox.children) |children| {
        switch (children) {
            .layoutBoxes => |childBoxes| {
                const shouldFitMin = layoutBox.style.preferredHeight != .fixed and layoutBox.style.minHeight == null;
                const direction = layoutBox.style.direction;
                const padding = layoutBox.style.paddingBlock[0] + layoutBox.style.paddingBlock[1];
                const border = layoutBox.style.borderBlockWidth[0] + layoutBox.style.borderBlockWidth[1];
                if (layoutBox.style.preferredHeight == .fit) {
                    layoutBox.size[1] = padding + border;
                }
                if (shouldFitMin) {
                    layoutBox.minSize[1] = padding + border;
                }
                for (childBoxes) |*child| {
                    fitHeight(child);
                    if (child.style.placement == .standard) {
                        const childMargins = child.style.marginBlock[0] + child.style.marginBlock[1];
                        if (direction == .topToBottom) {
                            if (layoutBox.style.preferredHeight == .fit) {
                                layoutBox.size[1] += childMargins + child.size[1];
                            }
                            if (shouldFitMin) {
                                layoutBox.minSize[1] += childMargins + child.minSize[1];
                            }
                        }
                        if (direction == .leftToRight) {
                            if (layoutBox.style.preferredHeight == .fit) {
                                layoutBox.size[1] = @max(childMargins + padding + border + child.size[1], layoutBox.size[1]);
                            }
                            if (shouldFitMin) {
                                layoutBox.minSize[1] = @max(childMargins + padding + border + child.minSize[1], layoutBox.minSize[1]);
                            }
                        }
                    }
                }
            },
            else => {},
        }
    }
}

fn fitWidth(layoutBox: *LayoutBox) void {
    if (layoutBox.children) |children| {
        switch (children) {
            .layoutBoxes => |childBoxes| {
                const shouldFitMin = layoutBox.style.preferredWidth != .fixed and layoutBox.style.minWidth == null;
                const direction = layoutBox.style.direction;
                const padding = layoutBox.style.paddingInline[0] + layoutBox.style.paddingInline[1];
                const border = layoutBox.style.borderInlineWidth[0] + layoutBox.style.borderInlineWidth[1];
                if (layoutBox.style.preferredWidth == .fit) {
                    layoutBox.size[0] = padding + border;
                }
                if (shouldFitMin) {
                    layoutBox.minSize[0] = padding + border;
                }
                for (childBoxes) |*child| {
                    fitWidth(child);
                    if (child.style.placement == .standard) {
                        const childMargins = child.style.marginInline[0] + child.style.marginInline[1];
                        if (direction == .leftToRight) {
                            if (layoutBox.style.preferredWidth == .fit) {
                                layoutBox.size[0] += childMargins + child.size[0];
                            }
                            if (shouldFitMin) {
                                layoutBox.minSize[0] += childMargins + child.minSize[0];
                            }
                        }
                        if (direction == .topToBottom) {
                            if (layoutBox.style.preferredWidth == .fit) {
                                layoutBox.size[0] = @max(childMargins + padding + border + child.size[0], layoutBox.size[0]);
                            }
                            if (shouldFitMin) {
                                layoutBox.minSize[0] = @max(childMargins + padding + border + child.minSize[0], layoutBox.minSize[0]);
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
                const hAlign = layoutBox.style.horizontalAlignment;
                const vAlign = layoutBox.style.verticalAlignment;

                const availableSize = .{
                    layoutBox.size[0] - (layoutBox.style.paddingInline[0] + layoutBox.style.paddingInline[1]) - (layoutBox.style.borderInlineWidth[0] + layoutBox.style.borderInlineWidth[1]),
                    layoutBox.size[1] - (layoutBox.style.paddingBlock[0] + layoutBox.style.paddingBlock[1]) - (layoutBox.style.borderBlockWidth[0] + layoutBox.style.borderBlockWidth[1]),
                };

                var childrenSize: Vec2 = @splat(0.0);
                for (children) |child| {
                    if (child.style.placement == .standard) {
                        const contributingSize = Vec2{
                            child.size[0] + child.style.marginInline[0] + child.style.marginInline[1],
                            child.size[1] + child.style.marginBlock[0] + child.style.marginBlock[1],
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
                    layoutBox.style.paddingInline[0] + layoutBox.style.borderInlineWidth[0],
                    layoutBox.style.paddingBlock[0] + layoutBox.style.borderBlockWidth[0],
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
                            child.size[0] + child.style.marginInline[0] + child.style.marginInline[1],
                            child.size[1] + child.style.marginBlock[0] + child.style.marginBlock[1],
                        };
                        if (direction == .leftToRight) {
                            // Cross-axis alignment (Vertical)
                            switch (vAlign) {
                                .start => child.position[1] = child.style.marginBlock[0],
                                .center => child.position[1] = (availableSize[1] - contributingSize[1]) / 2.0,
                                .end => child.position[1] = (availableSize[1] - contributingSize[1]),
                            }

                            cursor[0] += child.style.marginInline[0];
                            child.position += cursor;
                            cursor[0] += child.size[0] + child.style.marginInline[1];
                        } else {
                            // Cross-axis alignment (Horizontal)
                            switch (hAlign) {
                                .start => child.position[0] = child.style.marginInline[0],
                                .center => child.position[0] = (availableSize[0] - contributingSize[0]) / 2.0,
                                .end => child.position[0] = (availableSize[0] - contributingSize[0]),
                            }

                            cursor[1] += child.style.marginBlock[0];
                            child.position += cursor;
                            cursor[1] += child.size[1] + child.style.marginBlock[1];
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
    path: std.ArrayList(usize),
    parent: ?LayoutBox,

    fn init(arenaAllocator: std.mem.Allocator) !@This() {
        return .{
            .arenaAllocator = arenaAllocator,
            .path = try std.ArrayList(usize).initCapacity(arenaAllocator, 0),
            .parent = null,
        };
    }

    fn create(self: *@This(), node: Node, baseStyle: BaseStyle, z: u16, dpi: Vec2) !LayoutBox {
        const resolutionMultiplier = dpi / @as(Vec2, @splat(72));
        var style = switch (node.content) {
            .element => |element| element.style.completeWith(baseStyle),
            .text => (IncompleteStyle{
                .horizontalAlignment = if (self.parent) |parent|
                    parent.style.horizontalAlignment
                else
                    null,
            }).completeWith(baseStyle),
        };
        style.borderInlineWidth *= @splat(resolutionMultiplier[0]);
        style.borderBlockWidth *= @splat(resolutionMultiplier[1]);
        if (style.shadow) |*shadow| {
            shadow.offsetInline *= @splat(resolutionMultiplier[0]);
            shadow.offsetBlock *= @splat(resolutionMultiplier[1]);
            shadow.blurRadius *= resolutionMultiplier[0];
            shadow.spread *= resolutionMultiplier[0];
        }
        style.paddingInline *= @splat(resolutionMultiplier[0]);
        style.paddingBlock *= @splat(resolutionMultiplier[1]);
        style.marginInline *= @splat(resolutionMultiplier[0]);
        style.marginBlock *= @splat(resolutionMultiplier[1]);
        style.borderRadius *= resolutionMultiplier[0];

        switch (node.content) {
            .element => |element| {
                var layoutBox = LayoutBox{
                    .position = if (style.placement == .manual) style.placement.manual else .{ 0.0, 0.0 },
                    .z = if (style.zIndex) |zIndex| zIndex else z,
                    .size = .{
                        switch (style.preferredWidth) {
                            .fixed => |width| width,
                            .fit, .grow => 0.0,
                        },
                        switch (style.preferredHeight) {
                            .fixed => |height| height,
                            .fit, .grow => 0.0,
                        },
                    },
                    .minSize = .{
                        style.minWidth orelse if (style.preferredWidth == .fixed) style.preferredWidth.fixed else 0.0,
                        style.minHeight orelse if (style.preferredHeight == .fixed) style.preferredHeight.fixed else 0.0,
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
                    try self.path.append(self.arenaAllocator, index);
                    defer _ = self.path.pop();

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
                const fontSize: f32 = @floatFromInt(style.fontSize);
                const pixelSizeVec2: Vec2 = @as(Vec2, @splat(fontSize)) * resolutionMultiplier;
                const pixelLineHeight = style.font.lineHeight() / unitsPerEm * pixelSizeVec2[1];

                const shapedGlyphs = try style.font.shape(text);
                var layoutGlyphs = try self.arenaAllocator.alloc(LayoutGlyph, shapedGlyphs.len);
                errdefer self.arenaAllocator.free(layoutGlyphs);
                var cursor: Vec2 = @splat(0.0);

                var minSize: Vec2 = .{ 0.0, pixelLineHeight };

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
                    } else if (style.textWrapping == .character) {
                        minSize = @max(minSize, advance);
                    } else if (style.textWrapping == .none) {
                        minSize = cursor;
                    }
                }

                return LayoutBox{
                    .position = .{ 0.0, 0.0 },
                    .z = z,
                    .key = node.key,
                    .size = .{ cursor[0], pixelLineHeight },
                    .minSize = minSize,
                    .children = .{ .glyphs = Glyphs{ .slice = layoutGlyphs, .lineHeight = pixelLineHeight } },
                    .style = style,
                };
            },
        }
    }
};

pub fn flattenTreeInto(allocator: std.mem.Allocator, list: *std.ArrayList(*const LayoutBox), layoutBox: *const LayoutBox) !void {
    try list.append(allocator, layoutBox);
    if (layoutBox.children != null and layoutBox.children.? == .layoutBoxes) {
        for (layoutBox.children.?.layoutBoxes) |*child| {
            try flattenTreeInto(allocator, list, child);
        }
    }
}

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
    if (context.rootFrameNode) |rootFrameNode| {
        var creator = try LayoutCreator.init(arena);
        var layoutBox = try creator.create(rootFrameNode, baseStyle, 1, dpi);
        fitWidth(&layoutBox);
        fitHeight(&layoutBox);
        if (layoutBox.style.preferredWidth == .grow) {
            layoutBox.size[0] = viewportSize[0];
        }
        if (layoutBox.style.preferredHeight == .grow) {
            layoutBox.size[1] = viewportSize[1];
        }
        try growAndShrink(arena, &layoutBox);
        try wrap(arena, &layoutBox);
        fitWidth(&layoutBox);
        fitHeight(&layoutBox);
        place(&layoutBox);
        makeAbsolute(&layoutBox, .{ 0.0, 0.0 });
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

    var layoutBox = LayoutBox{
        .key = 1,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ configuration.lineWidth, configuration.lineHeight },
        .minSize = .{ 0.0, 20.0 },
        .children = .{
            .glyphs = Glyphs{
                .slice = configuration.glyphs,
                .lineHeight = configuration.lineHeight,
            },
        },
        .style = (IncompleteStyle{
            .horizontalAlignment = configuration.alignment,
        }).completeWith(BaseStyle{
            .font = undefined,
            .color = .{ 0.0, 0.0, 0.0, 1.0 },
            .fontSize = 16,
            .fontWeight = 400,
            .lineHeight = 1.0,
            .textWrapping = configuration.mode,
        }),
    };

    try wrap(arenaAllocator, &layoutBox);

    const glyphPositions = try arenaAllocator.alloc(Vec2, configuration.glyphs.len);
    for (configuration.glyphs, 0..) |glyph, i| {
        glyphPositions[i] = glyph.position;
    }
    try std.testing.expectEqualDeep(configuration.expectedPositions, glyphPositions);
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
        .alignment = .start,
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
        .alignment = .start,
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
        .alignment = .start,
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
        .alignment = .start,
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
        .alignment = .end,
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
        .alignment = .start,
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
        .alignment = .end,
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
