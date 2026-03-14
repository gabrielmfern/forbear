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
const Sizing = @import("node.zig").Sizing;
const Style = @import("node.zig").Style;
const TextWrapping = @import("node.zig").TextWrapping;

const Vec4 = @Vector(4, f32);
const Vec3 = @Vector(3, f32);
const Vec2 = @Vector(2, f32);

fn approxEq(a: f32, b: f32) bool {
    return @abs(a - b) < 0.001;
}

fn makeAbsolute(node: *Node, base: Vec2) void {
    if (node.style.placement != .manual) {
        node.position += base;
    }

    switch (node.children) {
        .nodes => |nodes| {
            for (nodes.items) |*child| {
                makeAbsolute(child, node.position);
            }
        },
        .glyphs => |glyphs| {
            for (glyphs.slice) |*glyph| {
                glyph.position += node.position;
            }
        },
    }
}

fn growChildren(
    children: []Node,
    activelyModifying: *std.ArrayList(*Node),
    direction: Direction,
    remaining: *f32,
) void {
    for (children) |*child| {
        if (child.style.placement == .standard) {
            if (child.style.getPreferredSize(direction) == .grow and child.getSize(direction) < child.getMaxSize(direction)) {
                activelyModifying.appendAssumeCapacity(child);
            }
        }
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
    children: []Node,
    activelyModifying: *std.ArrayList(*Node),
    direction: Direction,
    remaining: *f32,
) void {
    if (remaining.* >= -0.001) {
        return;
    }

    activelyModifying.clearRetainingCapacity();
    for (children) |*child| {
        if (child.style.placement == .standard) {
            if (child.getSize(direction) > child.getMinSize(direction)) {
                activelyModifying.appendAssumeCapacity(child);
            }
        }
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

pub fn growAndShrink(
    arena: std.mem.Allocator,
    node: *Node,
) !void {
    if (node.children == .nodes) {
        const children = node.children.nodes;
        const direction = node.style.direction;

        var remaining = node.getSize(direction);
        for (children.items) |*child| {
            if (child.style.placement == .standard) {
                if (direction.perpendicular() == .topToBottom) {
                    if (child.style.height == .grow or (child.size[1] > node.size[1] and child.minSize[1] < child.size[1])) {
                        child.size[1] = @max(@min(node.size[1], child.maxSize[1]), child.minSize[1]);
                    }
                } else if (direction.perpendicular() == .leftToRight) {
                    if (child.style.width == .grow or (child.size[0] > node.size[0] and child.minSize[0] < child.size[0])) {
                        child.size[0] = @max(@min(node.size[0], child.maxSize[0]), child.minSize[0]);
                    }
                }
                child.applyRatios();
                remaining -= child.getSize(direction);
            }
        }

        var activelyModifying = try std.ArrayList(*Node).initCapacity(arena, children.items.len);
        growChildren(children.items, &activelyModifying, direction, &remaining);
        shrinkChildren(children.items, &activelyModifying, direction, &remaining);
        for (children.items) |*child| {
            try growAndShrink(arena, child);
        }
    }
}

pub fn wrap(arena: std.mem.Allocator, node: *Node) !void {
    switch (node.children) {
        .nodes => |nodes| {
            for (nodes.items) |*child| {
                try wrap(arena, child);
            }
        },
        .glyphs => |glyphs| {
            if (node.style.textWrapping == .none) {
                return;
            }
            const Line = struct {
                startIndex: usize,
                endIndex: usize,
            };
            var lines = try std.ArrayList(Line).initCapacity(arena, 4);

            const lineWidth = node.size[0];
            var cursor: Vec2 = @splat(0.0);
            var lineStartIndex: usize = 0;
            switch (node.style.textWrapping) {
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
                    switch (node.style.alignment.x) {
                        .start => {},
                        .center => glyph.position[0] += (lineWidth - width) / 2.0,
                        .end => glyph.position[0] += lineWidth - width,
                    }
                }
            }
            node.size[1] = cursor[1] + glyphs.lineHeight;
        },
    }
}

fn applyParentPercentageSizes(node: *Node, parentSize: Vec2) void {
    if (node.style.width == .percentage) {
        node.size[0] = node.style.width.percentage * parentSize[0];
    }
    if (node.style.height == .percentage) {
        node.size[1] = node.style.height.percentage * parentSize[1];
    }

    node.size[0] = @min(@max(node.size[0], node.minSize[0]), node.maxSize[0]);
    node.size[1] = @min(@max(node.size[1], node.minSize[1]), node.maxSize[1]);

    switch (node.children) {
        .nodes => |nodes| {
            for (nodes.items) |*child| {
                applyParentPercentageSizes(child, node.size);
            }
        },
        else => {},
    }
}

pub fn applyRatios(node: *Node) void {
    node.applyRatios();
    switch (node.children) {
        .nodes => |nodes| {
            for (nodes.items) |*child| {
                applyRatios(child);
            }
        },
        else => {},
    }
}

pub fn fit(node: *Node) void {
    switch (node.children) {
        .nodes => |nodes| {
            inline for (Direction.array) |direction| {
                const fittingBase = node.fittingBase(direction);
                const preferredSize = node.style.getPreferredSize(direction);

                if (preferredSize == .fit) {
                    node.setSize(direction, fittingBase);
                }
                if (node.shouldFitMin(direction)) {
                    node.setMinSize(direction, fittingBase);
                }
            }
            for (nodes.items) |*child| {
                fit(child);
                node.fitChild(child);
            }
        },
        else => {},
    }
}

fn place(node: *Node) void {
    node.position += node.style.translate;
    switch (node.children) {
        .nodes => |nodes| {
            const direction = node.style.direction;
            const hAlign = node.style.alignment.x;
            const vAlign = node.style.alignment.y;

            const availableSize = .{
                node.size[0] - (node.style.padding.x[0] + node.style.padding.x[1]) - (node.style.borderWidth.x[0] + node.style.borderWidth.x[1]),
                node.size[1] - (node.style.padding.y[0] + node.style.padding.y[1]) - (node.style.borderWidth.y[0] + node.style.borderWidth.y[1]),
            };

            var childrenSize: Vec2 = @splat(0.0);
            for (nodes.items) |child| {
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
                node.style.padding.x[0] + node.style.borderWidth.x[0],
                node.style.padding.y[0] + node.style.borderWidth.y[0],
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

            for (nodes.items) |*child| {
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

pub const LayoutTreeIterator = struct {
    stack: std.ArrayList(*const Node),
    allocator: std.mem.Allocator,

    root: *const Node,

    pub fn init(allocator: std.mem.Allocator, root: *const Node) !@This() {
        var iterator = @This(){
            .stack = try std.ArrayList(*const Node).initCapacity(allocator, 16),
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

    pub fn next(self: *@This()) !?*const Node {
        if (self.stack.items.len == 0) {
            return null;
        }
        if (self.stack.pop()) |current| {
            if (current.children == .nodes) {
                for (current.children.nodes.items) |*child| {
                    try self.stack.append(self.allocator, child);
                }
            }
            return current;
        } else {
            return null;
        }
    }
};

pub fn layout() !*Node {
    const context = forbear.getContext();

    std.debug.assert(context.frameMeta != null);
    if (context.frameMeta.?.err) |err| return err;
    if (context.frameMeta.?.rootNode) |*node| {
        const viewportSize = context.frameMeta.?.viewportSize;
        const arena = context.frameMeta.?.arena;

        if (node.style.width == .grow) {
            node.size[0] = @min(@max(viewportSize[0], node.minSize[0]), node.maxSize[0]);
        }
        if (node.style.height == .grow) {
            node.size[1] = @min(@max(viewportSize[1], node.minSize[1]), node.maxSize[1]);
        }

        applyParentPercentageSizes(node, viewportSize);
        applyRatios(node);
        try growAndShrink(arena, node);

        try wrap(arena, node);
        fit(node);

        applyParentPercentageSizes(node, viewportSize);
        applyRatios(node);
        try growAndShrink(arena, node);

        place(node);
        makeAbsolute(node, @as(Vec2, @splat(-1.0)) * context.scrollPosition);

        return node;
    } else {
        std.log.err("You need to define a root node before layouting, any node will suffice.", .{});
        return error.NoRootFrameNode;
    }
}

fn testBaseStyle() BaseStyle {
    return .{
        .font = undefined,
        .color = .{ 0.0, 0.0, 0.0, 1.0 },
        .fontSize = 16.0,
        .fontWeight = 400,
        .lineHeight = 1.0,
        .textWrapping = .none,
        .blendMode = .normal,
        .cursor = .default,
    };
}

fn testStyle(incompleteStyle: IncompleteStyle) Style {
    return incompleteStyle.completeWith(testBaseStyle());
}

fn testNode(key: u64, position: Vec2, size: Vec2, style: IncompleteStyle) Node {
    return .{
        .key = key,
        .position = position,
        .z = 0,
        .size = size,
        .minSize = .{ 0.0, 0.0 },
        .maxSize = .{ std.math.inf(f32), std.math.inf(f32) },
        .children = .{ .nodes = .empty },
        .style = testStyle(style),
    };
}

fn expectVec2(expected: Vec2, actual: Vec2) !void {
    try std.testing.expectApproxEqAbs(expected[0], actual[0], 0.001);
    try std.testing.expectApproxEqAbs(expected[1], actual[1], 0.001);
}

test "makeAbsolute - standard nodes accumulate, manual nodes keep local positions, glyphs inherit absolute parent" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var standardGrandchildren = try std.ArrayList(Node).initCapacity(arenaAllocator, 1);
    standardGrandchildren.appendAssumeCapacity(testNode(3, .{ 1.0, 2.0 }, .{ 3.0, 4.0 }, .{}));

    var standardChild = testNode(2, .{ 5.0, 6.0 }, .{ 20.0, 10.0 }, .{});
    standardChild.children = .{ .nodes = standardGrandchildren };

    var manualGrandchildren = try std.ArrayList(Node).initCapacity(arenaAllocator, 1);
    manualGrandchildren.appendAssumeCapacity(testNode(5, .{ 2.0, 3.0 }, .{ 4.0, 5.0 }, .{}));

    var manualChild = testNode(4, .{ 7.0, 8.0 }, .{ 12.0, 13.0 }, .{
        .placement = .{ .manual = .{ 7.0, 8.0 } },
    });
    manualChild.children = .{ .nodes = manualGrandchildren };

    const glyphs = try arenaAllocator.alloc(LayoutGlyph, 2);
    glyphs[0] = .{
        .index = 0,
        .position = .{ 1.0, 1.0 },
        .text = "a",
        .advance = .{ 4.0, 0.0 },
        .offset = .{ 0.0, 0.0 },
    };
    glyphs[1] = .{
        .index = 1,
        .position = .{ 2.0, 3.0 },
        .text = "b",
        .advance = .{ 4.0, 0.0 },
        .offset = .{ 0.0, 0.0 },
    };

    var glyphChild = testNode(6, .{ 4.0, 5.0 }, .{ 8.0, 9.0 }, .{});
    glyphChild.children = .{ .glyphs = .{
        .slice = glyphs,
        .lineHeight = 10.0,
    } };

    var children = try std.ArrayList(Node).initCapacity(arenaAllocator, 3);
    children.appendAssumeCapacity(standardChild);
    children.appendAssumeCapacity(manualChild);
    children.appendAssumeCapacity(glyphChild);

    var root = testNode(1, .{ 10.0, 20.0 }, .{ 100.0, 100.0 }, .{});
    root.children = .{ .nodes = children };

    makeAbsolute(&root, .{ 0.0, 0.0 });

    try expectVec2(.{ 10.0, 20.0 }, root.position);

    const absoluteChildren = root.children.nodes.items;
    try expectVec2(.{ 15.0, 26.0 }, absoluteChildren[0].position);
    try expectVec2(.{ 16.0, 28.0 }, absoluteChildren[0].children.nodes.items[0].position);

    try expectVec2(.{ 7.0, 8.0 }, absoluteChildren[1].position);
    try expectVec2(.{ 9.0, 11.0 }, absoluteChildren[1].children.nodes.items[0].position);

    try expectVec2(.{ 14.0, 25.0 }, absoluteChildren[2].position);
    try expectVec2(.{ 15.0, 26.0 }, absoluteChildren[2].children.glyphs.slice[0].position);
    try expectVec2(.{ 16.0, 28.0 }, absoluteChildren[2].children.glyphs.slice[1].position);
}

test "applyParentPercentageSizes - resolves percentages, clamps limits, preserves fixed sizes, and recurses" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var grandChildren = try std.ArrayList(Node).initCapacity(arenaAllocator, 1);
    grandChildren.appendAssumeCapacity(.{
        .key = 3,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 0.0, 0.0 },
        .minSize = .{ 0.0, 0.0 },
        .maxSize = .{ std.math.inf(f32), std.math.inf(f32) },
        .children = .{ .nodes = .empty },
        .style = testStyle(.{
            .width = .{ .percentage = 0.5 },
            .height = .{ .percentage = 0.5 },
        }),
    });

    const percentageChild = Node{
        .key = 2,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 0.0, 0.0 },
        .minSize = .{ 0.0, 60.0 },
        .maxSize = .{ 100.0, std.math.inf(f32) },
        .children = .{ .nodes = grandChildren },
        .style = testStyle(.{
            .width = .{ .percentage = 0.9 },
            .height = .{ .percentage = 0.5 },
        }),
    };

    const fixedChild = Node{
        .key = 4,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 33.0, 44.0 },
        .minSize = .{ 33.0, 44.0 },
        .maxSize = .{ 33.0, 44.0 },
        .children = .{ .nodes = .empty },
        .style = testStyle(.{
            .width = .{ .fixed = 33.0 },
            .height = .{ .fixed = 44.0 },
        }),
    };

    var children = try std.ArrayList(Node).initCapacity(arenaAllocator, 2);
    children.appendAssumeCapacity(percentageChild);
    children.appendAssumeCapacity(fixedChild);

    var root = Node{
        .key = 1,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = .{ 200.0, 100.0 },
        .minSize = .{ 200.0, 100.0 },
        .maxSize = .{ 200.0, 100.0 },
        .children = .{ .nodes = children },
        .style = testStyle(.{
            .width = .{ .fixed = 200.0 },
            .height = .{ .fixed = 100.0 },
        }),
    };

    applyParentPercentageSizes(&root, .{ 200.0, 100.0 });

    try expectVec2(.{ 100.0, 60.0 }, root.children.nodes.items[0].size);
    try expectVec2(.{ 50.0, 30.0 }, root.children.nodes.items[0].children.nodes.items[0].size);
    try expectVec2(.{ 33.0, 44.0 }, root.children.nodes.items[1].size);
}

test "place - horizontal alignment combinations position children along both axes" {
    const cases = [_]struct {
        alignment: Alignment,
        expectedFirst: Vec2,
        expectedSecond: Vec2,
    }{
        .{ .alignment = .topLeft, .expectedFirst = .{ 0.0, 0.0 }, .expectedSecond = .{ 10.0, 0.0 } },
        .{ .alignment = .topCenter, .expectedFirst = .{ 35.0, 0.0 }, .expectedSecond = .{ 45.0, 0.0 } },
        .{ .alignment = .topRight, .expectedFirst = .{ 70.0, 0.0 }, .expectedSecond = .{ 80.0, 0.0 } },
        .{ .alignment = .centerLeft, .expectedFirst = .{ 0.0, 25.0 }, .expectedSecond = .{ 10.0, 20.0 } },
        .{ .alignment = .center, .expectedFirst = .{ 35.0, 25.0 }, .expectedSecond = .{ 45.0, 20.0 } },
        .{ .alignment = .centerRight, .expectedFirst = .{ 70.0, 25.0 }, .expectedSecond = .{ 80.0, 20.0 } },
        .{ .alignment = .bottomLeft, .expectedFirst = .{ 0.0, 50.0 }, .expectedSecond = .{ 10.0, 40.0 } },
        .{ .alignment = .bottomCenter, .expectedFirst = .{ 35.0, 50.0 }, .expectedSecond = .{ 45.0, 40.0 } },
        .{ .alignment = .bottomRight, .expectedFirst = .{ 70.0, 50.0 }, .expectedSecond = .{ 80.0, 40.0 } },
    };

    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    for (cases) |case| {
        var children = try std.ArrayList(Node).initCapacity(arenaAllocator, 2);
        children.appendAssumeCapacity(testNode(1, .{ 0.0, 0.0 }, .{ 10.0, 10.0 }, .{}));
        children.appendAssumeCapacity(testNode(2, .{ 0.0, 0.0 }, .{ 20.0, 20.0 }, .{}));

        var parent = testNode(0, .{ 0.0, 0.0 }, .{ 100.0, 60.0 }, .{
            .direction = .leftToRight,
            .alignment = case.alignment,
            .width = .{ .fixed = 100.0 },
            .height = .{ .fixed = 60.0 },
        });
        parent.children = .{ .nodes = children };

        place(&parent);

        try expectVec2(case.expectedFirst, parent.children.nodes.items[0].position);
        try expectVec2(case.expectedSecond, parent.children.nodes.items[1].position);
        _ = arena.reset(.retain_capacity);
    }
}

test "place - vertical alignment combinations position children along both axes" {
    const cases = [_]struct {
        alignment: Alignment,
        expectedFirst: Vec2,
        expectedSecond: Vec2,
    }{
        .{ .alignment = .topLeft, .expectedFirst = .{ 0.0, 0.0 }, .expectedSecond = .{ 0.0, 10.0 } },
        .{ .alignment = .topCenter, .expectedFirst = .{ 45.0, 0.0 }, .expectedSecond = .{ 40.0, 10.0 } },
        .{ .alignment = .topRight, .expectedFirst = .{ 90.0, 0.0 }, .expectedSecond = .{ 80.0, 10.0 } },
        .{ .alignment = .centerLeft, .expectedFirst = .{ 0.0, 15.0 }, .expectedSecond = .{ 0.0, 25.0 } },
        .{ .alignment = .center, .expectedFirst = .{ 45.0, 15.0 }, .expectedSecond = .{ 40.0, 25.0 } },
        .{ .alignment = .centerRight, .expectedFirst = .{ 90.0, 15.0 }, .expectedSecond = .{ 80.0, 25.0 } },
        .{ .alignment = .bottomLeft, .expectedFirst = .{ 0.0, 30.0 }, .expectedSecond = .{ 0.0, 40.0 } },
        .{ .alignment = .bottomCenter, .expectedFirst = .{ 45.0, 30.0 }, .expectedSecond = .{ 40.0, 40.0 } },
        .{ .alignment = .bottomRight, .expectedFirst = .{ 90.0, 30.0 }, .expectedSecond = .{ 80.0, 40.0 } },
    };

    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    for (cases) |case| {
        var children = try std.ArrayList(Node).initCapacity(arenaAllocator, 2);
        children.appendAssumeCapacity(testNode(1, .{ 0.0, 0.0 }, .{ 10.0, 10.0 }, .{}));
        children.appendAssumeCapacity(testNode(2, .{ 0.0, 0.0 }, .{ 20.0, 20.0 }, .{}));

        var parent = testNode(0, .{ 0.0, 0.0 }, .{ 100.0, 60.0 }, .{
            .direction = .topToBottom,
            .alignment = case.alignment,
            .width = .{ .fixed = 100.0 },
            .height = .{ .fixed = 60.0 },
        });
        parent.children = .{ .nodes = children };

        place(&parent);

        try expectVec2(case.expectedFirst, parent.children.nodes.items[0].position);
        try expectVec2(case.expectedSecond, parent.children.nodes.items[1].position);
        _ = arena.reset(.retain_capacity);
    }
}

test "place - padding, border, margin, translate, and manual nodes interact as expected" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var manualChildren = try std.ArrayList(Node).initCapacity(arenaAllocator, 1);
    manualChildren.appendAssumeCapacity(testNode(4, .{ 0.0, 0.0 }, .{ 5.0, 5.0 }, .{}));

    var children = try std.ArrayList(Node).initCapacity(arenaAllocator, 3);
    children.appendAssumeCapacity(testNode(1, .{ 0.0, 0.0 }, .{ 10.0, 6.0 }, .{
        .translate = .{ 1.0, 2.0 },
        .margin = .{ .x = .{ 2.0, 3.0 }, .y = .{ 0.0, 0.0 } },
    }));
    children.appendAssumeCapacity(.{
        .key = 2,
        .position = .{ 30.0, 5.0 },
        .z = 0,
        .size = .{ 9.0, 9.0 },
        .minSize = .{ 0.0, 0.0 },
        .maxSize = .{ std.math.inf(f32), std.math.inf(f32) },
        .children = .{ .nodes = manualChildren },
        .style = testStyle(.{
            .placement = .{ .manual = .{ 30.0, 5.0 } },
        }),
    });
    children.appendAssumeCapacity(testNode(3, .{ 0.0, 0.0 }, .{ 8.0, 6.0 }, .{
        .margin = .{ .x = .{ 4.0, 1.0 }, .y = .{ 0.0, 0.0 } },
    }));

    var parent = testNode(0, .{ 0.0, 0.0 }, .{ 100.0, 40.0 }, .{
        .direction = .leftToRight,
        .translate = .{ 4.0, 7.0 },
        .padding = .{ .x = .{ 3.0, 0.0 }, .y = .{ 4.0, 0.0 } },
        .borderWidth = .{ .x = .{ 2.0, 0.0 }, .y = .{ 1.0, 0.0 } },
        .width = .{ .fixed = 100.0 },
        .height = .{ .fixed = 40.0 },
    });
    parent.children = .{ .nodes = children };

    place(&parent);
    makeAbsolute(&parent, .{ 0.0, 0.0 });

    try expectVec2(.{ 4.0, 7.0 }, parent.position);

    const placedChildren = parent.children.nodes.items;
    try expectVec2(.{ 12.0, 14.0 }, placedChildren[0].position);
    try expectVec2(.{ 30.0, 5.0 }, placedChildren[1].position);
    try expectVec2(.{ 28.0, 12.0 }, placedChildren[2].position);
    try expectVec2(.{ 30.0, 5.0 }, placedChildren[1].children.nodes.items[0].position);
}

test "LayoutTreeIterator - stack traversal visits all nodes, reset restarts, and single-node trees exhaust" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var single = testNode(1, .{ 0.0, 0.0 }, .{ 1.0, 1.0 }, .{});
    var singleIterator = try LayoutTreeIterator.init(arenaAllocator, &single);
    defer singleIterator.deinit();

    try std.testing.expectEqual(@as(?*const Node, &single), try singleIterator.next());
    try std.testing.expectEqual(@as(?*const Node, null), try singleIterator.next());

    var branchChildren = try std.ArrayList(Node).initCapacity(arenaAllocator, 1);
    branchChildren.appendAssumeCapacity(testNode(4, .{ 0.0, 0.0 }, .{ 1.0, 1.0 }, .{}));

    var branch = testNode(2, .{ 0.0, 0.0 }, .{ 1.0, 1.0 }, .{});
    branch.children = .{ .nodes = branchChildren };

    var rootChildren = try std.ArrayList(Node).initCapacity(arenaAllocator, 3);
    rootChildren.appendAssumeCapacity(testNode(3, .{ 0.0, 0.0 }, .{ 1.0, 1.0 }, .{}));
    rootChildren.appendAssumeCapacity(branch);
    rootChildren.appendAssumeCapacity(testNode(5, .{ 0.0, 0.0 }, .{ 1.0, 1.0 }, .{}));

    var root = testNode(0, .{ 0.0, 0.0 }, .{ 1.0, 1.0 }, .{});
    root.children = .{ .nodes = rootChildren };

    var iterator = try LayoutTreeIterator.init(arenaAllocator, &root);
    defer iterator.deinit();

    const expectedOrder = [_]u64{ 0, 5, 2, 4, 3 };
    for (expectedOrder) |expectedKey| {
        const next = (try iterator.next()).?;
        try std.testing.expectEqual(expectedKey, next.key);
    }
    try std.testing.expectEqual(@as(?*const Node, null), try iterator.next());

    try iterator.reset();
    for (expectedOrder) |expectedKey| {
        const next = (try iterator.next()).?;
        try std.testing.expectEqual(expectedKey, next.key);
    }
}
