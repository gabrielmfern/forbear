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
                if (child.style.width == .percentage) {
                    child.size[0] = child.style.width.percentage * node.size[0];
                }
                if (child.style.height == .percentage) {
                    child.size[1] = child.style.height.percentage * node.size[1];
                }
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

pub fn wrapGlyphs(arena: std.mem.Allocator, node: *Node) !void {
    std.debug.assert(node.children == .glyphs);
    if (node.style.textWrapping == .none) {
        return;
    }

    const glyphs = node.children.glyphs;

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
    const addition = node.size[1] - cursor[1] - glyphs.lineHeight;
    node.size[1] = cursor[1] + glyphs.lineHeight;
    if (node.style.width == .ratio) {
        node.size[0] = node.size[1] * node.style.width.ratio;
    }

    updateFittingForAncestors(node, addition);
}

/// Iterates upwards in the ancestry of the node, adding `addition` if in the
/// right direction, or calculating the max otherwise. Also updates the
/// minSizes accordingly, though (?) there shouldn't be a growth or shrinking after
/// this
pub fn updateFittingForAncestors(node: *Node, addition: f32) void {
    inline for (Direction.array) |direction| {
        const minSize = node.getMinSize(direction);
        const size = node.getSize(direction);
        const margin = node.style.margin.get(direction);

        var ancestorOpt = node.parent;
        while (ancestorOpt) |ancestor| {
            const ancestorSize = ancestor.getSize(direction);
            const ancestorMinSize = ancestor.getMinSize(direction);
            if (ancestor.shouldFitMin(direction)) {
                if (ancestor.style.direction == direction) {
                    // just addition is fine since it should already be here
                    ancestor.addMinSize(direction, addition);
                } else {
                    ancestor.setMinSize(direction, @max(
                        ancestorMinSize,
                        minSize + margin[0] + margin[1],
                    ));
                }
            }

            if (ancestor.style.getPreferredSize(direction) == .fit) {
                if (ancestor.style.direction == direction) {
                    // just addition is fine since it should already be here
                    ancestor.addSize(direction, addition);
                } else {
                    // TODO: ensure the max and min sizes here
                    // TODO: also add the padding and margins of nodes
                    ancestor.setSize(direction, @max(
                        ancestorSize,
                        size + margin[0] + margin[1],
                    ));
                }
                const perpendicularPreferredSize = ancestor.style.getPreferredSize(direction.perpendicular());
                if (perpendicularPreferredSize == .ratio) {
                    ancestor.setSize(direction, ancestorSize * perpendicularPreferredSize.ratio);
                }
            } else {
                // means the streak should be ended as only a sequence of fits
                // would continue increasing
                break;
            }

            ancestorOpt = ancestor.parent;
        }
    }
}

/// does not change the size of children, but recursively updates the sizes of parents
pub fn wrapAndPlace(arena: std.mem.Allocator, node: *Node) !void {
    switch (node.children) {
        .nodes => |children| {
            var cursor = node.position + Vec2{
                node.style.padding.x[0],
                node.style.padding.y[0],
            };

            const Line = struct {
                start: usize,
                end: usize,
                width: f32,
                height: f32,
            };

            // Kept track so that they can be aligned
            var lines = std.ArrayList(Line).empty;

            var currentLine = Line{
                .start = 0,
                .end = 1,
                .width = 0.0,
                .height = 0.0,
            };

            const nodeHeightBeforeIteration = node.size[1];

            // place elements, wrapping in .leftToRight if overflow is .wrap, appending the line information to `lines`
            for (children.items) |*child| {
                if (node.style.direction == .leftToRight) {
                    if (node.style.overflow == .wrap) {
                        const remainingSpace = node.size[0] - (cursor[0] + node.style.padding.x[1]);
                        if (child.style.margin.x[0] + child.size[0] + child.style.margin.x[1] > remainingSpace) {
                            // breaks the line
                            cursor[1] += node.size[1] + child.style.margin.y[0];
                            // TODO: where does the bottom margin get used in this flow? I believe we're missing something
                            node.size[1] += node.size[1] + child.style.margin.y[0];
                            cursor[0] = node.style.padding.x[0];
                            try lines.append(arena, currentLine);
                            currentLine.start = currentLine.end - 1;
                            currentLine.width = 0;
                            currentLine.height = 0;
                        }
                    }
                    cursor[0] += child.style.margin.x[0];
                    child.position = cursor;
                    cursor[0] += child.size[0] + child.style.margin.x[1];

                    currentLine.end += 1;
                    currentLine.width += child.style.margin.x[0] + child.size[0] + child.style.margin.x[1];
                    currentLine.height = @max(
                        currentLine.height,
                        child.size[1] + child.style.margin.y[0] + child.style.margin.y[1],
                    );
                } else if (node.style.direction == .topToBottom) {
                    cursor[1] += child.style.margin.y[0];
                    child.position = cursor;
                    cursor[1] += child.size[1] + child.style.margin.y[1];
                }
            }

            // 2. update consecutive ancestors with a fit height
            const addition = node.size[1] - nodeHeightBeforeIteration;
            updateFittingForAncestors(node, addition);

            // 3. alignment
            const availableSize = Vec2{
                node.size[0] - node.style.padding.x[0] - node.style.padding.x[1],
                node.size[1] - node.style.padding.y[0] - node.style.padding.y[1],
            };
            if (node.style.direction == .leftToRight) {
                for (lines.items) |line| {
                    const horizontalAlignmentOffset = switch (node.style.alignment.x) {
                        .start => 0.0,
                        .center => (availableSize[0] - line.width) / 2.0,
                        .end => availableSize[0] - line.width,
                    };
                    for (children.items[line.start .. line.end]) |*child| {
                        child.position[0] += horizontalAlignmentOffset;
                        child.position[1] += switch (node.style.alignment.y) {
                            .start => 0.0,
                            .center => (line.height - child.size[1]) / 2.0,
                            .end => line.height - child.size[1],
                        };
                        try wrapAndPlace(arena, child);
                    }
                }
            } else if (node.style.direction == .topToBottom) {
                const verticalAlignmentOffset = switch (node.style.alignment.y) {
                    .start => 0.0,
                    .center => (availableSize[1] - cursor[1]) / 2.0,
                    .end => availableSize[1] - cursor[1],
                };
                for (children.items) |*child| {
                    child.position[0] += switch (node.style.alignment.y) {
                        .start => 0.0,
                        .center => (availableSize[0] - child.size[1]) / 2.0,
                        .end => availableSize[0] - child.size[1],
                    };
                    child.position[1] += verticalAlignmentOffset;
                    try wrapAndPlace(arena, child);
                }
            }
        },
        .glyphs => {
            try wrapGlyphs(arena, node);
        },
    }
}

pub fn layout() !*Node {
    const context = forbear.getContext();

    std.debug.assert(context.frameMeta != null);
    if (context.frameMeta.?.err) |err| return err;
    if (context.frameMeta.?.rootNode) |*node| {
        const viewportSize = context.frameMeta.?.viewportSize;
        const arena = context.frameMeta.?.arena;

        // what should this do, not considering any side effects? let's think from first principles
        // 1. grow and shrink
        // 2. place in absolute positions and wrap
        //
        // the side effects can be done minimally inside of the functions. what
        // really needs to be done if height fitting for consecutive height
        // fitting ancestors, and aspect ratio maintenance.

        if (node.style.width == .grow) {
            node.size[0] = @min(@max(viewportSize[0], node.minSize[0]), node.maxSize[0]);
        }
        if (node.style.height == .grow) {
            node.size[1] = @min(@max(viewportSize[1], node.minSize[1]), node.maxSize[1]);
        }
        try growAndShrink(arena, node);

        try wrapAndPlace(arena, node);

        return node;
    } else {
        std.log.err("You need to define a root node before layouting, any node will suffice.", .{});
        return error.NoRootFrameNode;
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
