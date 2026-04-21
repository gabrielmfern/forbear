const std = @import("std");

const forbear = @import("root.zig");
const Font = @import("font.zig");
const Graphics = @import("graphics.zig");
const Cursor = @import("window/root.zig").Cursor;
const layouting = @import("layouting.zig");

const Vec4 = @Vector(4, f32);
const Vec2 = @Vector(2, f32);

pub const Direction = enum {
    horizontal,
    vertical,

    pub fn perpendicular(self: @This()) @This() {
        return switch (self) {
            .horizontal => .vertical,
            .vertical => .horizontal,
        };
    }

    pub const array = [_]Direction{ .horizontal, .vertical };
};

pub const Sizing = union(enum) {
    fit,
    fixed: f32,
    /// A ratio with respect to the opposite axis.
    ratio: f32,
    grow,
};

pub const Shadow = struct {
    pub const Offset = Padding;

    offset: Offset,
    blurRadius: f32,
    spread: f32,
    color: Vec4,
};

pub const Alignment = enum {
    start,
    center,
    end,
};

/// Will modify the min size of layout boxes that wrap text accordingly
/// character => largest character
/// word => largest word
/// none => all in one line
pub const TextWrapping = enum {
    character,
    /// Uses a simple greedy algorithm to break on word boundaries
    word,
    none,
};

pub const Overflow = enum {
    visible,
    wrap,
};

pub const Padding = struct {
    x: Vec2,
    y: Vec2,

    pub fn get(self: @This(), direction: Direction) Vec2 {
        return switch (direction) {
            .horizontal => self.x,
            .vertical => self.y,
        };
    }

    pub inline fn all(value: f32) @This() {
        return .{
            .x = @splat(value),
            .y = @splat(value),
        };
    }

    /// `inLine` because `inline` is a reserved keyword in Zig
    pub inline fn inLine(value: f32) @This() {
        return .{
            .x = @splat(value),
            .y = @splat(0.0),
        };
    }

    pub fn withInLine(self: @This(), value: f32) @This() {
        return .{
            .x = @splat(value),
            .y = self.y,
        };
    }

    pub inline fn block(value: f32) @This() {
        return .{
            .x = @splat(0.0),
            .y = @splat(value),
        };
    }

    pub fn withBlock(self: @This(), value: f32) @This() {
        return .{
            .x = self.x,
            .y = @splat(value),
        };
    }

    pub inline fn left(value: f32) @This() {
        return .{
            .x = .{ value, 0.0 },
            .y = @splat(0.0),
        };
    }

    pub fn withLeft(self: @This(), value: f32) @This() {
        return .{
            .x = .{ value, self.x[1] },
            .y = self.y,
        };
    }

    pub inline fn right(value: f32) @This() {
        return .{
            .x = .{ 0.0, value },
            .y = @splat(0.0),
        };
    }

    pub fn withRight(self: @This(), value: f32) @This() {
        return .{
            .x = .{ self.x[0], value },
            .y = self.y,
        };
    }

    pub inline fn top(value: f32) @This() {
        return .{
            .x = @splat(0.0),
            .y = .{ value, 0.0 },
        };
    }

    pub fn withTop(self: @This(), value: f32) @This() {
        return .{
            .x = self.x,
            .y = .{ value, self.y[1] },
        };
    }

    pub inline fn bottom(value: f32) @This() {
        return .{
            .x = @splat(0.0),
            .y = .{ 0.0, value },
        };
    }

    pub fn withBottom(self: @This(), value: f32) @This() {
        return .{
            .x = self.x,
            .y = .{ self.y[0], value },
        };
    }
};

pub const Margin = Padding;

pub const BorderWidth = Padding;

pub const BlendMode = enum(u32) {
    normal = 0,
    multiply = 1,
};

pub const Filter = enum(u32) {
    default = 0,
    grayscale = 1,
};

pub const CompleteStyle = struct {
    background: Background,
    blendMode: BlendMode,
    filter: Filter,

    color: Vec4,
    borderRadius: f32,
    borderColor: Vec4,
    borderWidth: BorderWidth,

    shadow: ?Shadow = null,

    font: *Font,
    /// Will do nothing if the font is not a variable font. If you don't have a
    /// variable font, you should use different fonts for different weights.
    fontWeight: u32,
    fontSize: f32,
    lineHeight: f32,
    textWrapping: TextWrapping,
    cursor: Cursor,

    overflow: Overflow,
    placement: Placement,
    zIndex: ?u16 = null,

    minWidth: ?f32 = null,
    maxWidth: ?f32 = null,
    width: Sizing,
    maxHeight: ?f32 = null,
    minHeight: ?f32 = null,
    height: Sizing,

    translate: Vec2,

    padding: Padding,
    margin: Margin,

    direction: Direction,
    xJustification: Alignment,
    yJustification: Alignment,

    pub fn getPreferredSize(self: @This(), direction: Direction) Sizing {
        if (direction == .horizontal) {
            return self.width;
        }
        return self.height;
    }

    pub fn getMinSize(self: @This(), direction: Direction) ?f32 {
        if (direction == .horizontal) {
            return self.minWidth;
        }
        return self.minHeight;
    }
};

pub const BaseStyle = struct {
    font: *Font,
    color: Vec4,
    fontSize: f32,
    fontWeight: u32,
    lineHeight: f32,
    textWrapping: TextWrapping,
    blendMode: BlendMode,
    filter: Filter = .default,
    cursor: Cursor,

    pub fn from(style: CompleteStyle) @This() {
        return @This(){
            .font = style.font,
            .color = style.color,
            .fontSize = style.fontSize,
            .fontWeight = style.fontWeight,
            .lineHeight = style.lineHeight,
            .textWrapping = style.textWrapping,
            .blendMode = style.blendMode,
            .filter = style.filter,
            .cursor = style.cursor,
        };
    }
};

pub const GradientStop = extern struct {
    color: Vec4,
    /// Position along the gradient in the [0, 1] range.
    position: f32,
};

pub const Background = union(enum) {
    image: *Graphics.Image,
    color: Vec4,
    /// A linear gradient from the left to the right of the element. Stops
    /// define where each color sits along the gradient; positions are
    /// expected to be monotonically increasing within the [0, 1] range.
    gradient: []const GradientStop,
};

pub const Placement = union(enum) {
    /// The default: the node participates in its parent's layout flow and
    /// contributes to the parent's fit size and sibling positioning.
    flow,
    /// Pinned to the viewport at the given coordinates. Unaffected by
    /// scrolling. Does not participate in the parent's layout flow.
    fixed: Vec2,
    /// Positioned in the viewport's coordinate space like `fixed`, but
    /// respects the root scroll offset (so it moves with the document as the
    /// user scrolls). Does not participate in the parent's layout flow.
    absolute: Vec2,
    /// Positioned relative to the parent's top-left corner. Inherits scroll
    /// via the parent's resolved position. Does not participate in the
    /// parent's layout flow, but is useful for anchoring overlays, tooltips,
    /// or decorations next to a specific parent.
    relative: Vec2,
};

pub const Style = struct {
    background: ?Background = null,
    blendMode: ?BlendMode = null,
    filter: ?Filter = null,

    color: ?Vec4 = null,
    borderRadius: ?f32 = null,
    borderColor: ?Vec4 = null,
    borderWidth: ?BorderWidth = null,

    shadow: ?Shadow = null,

    font: ?*Font = null,
    fontWeight: ?u32 = null,
    fontSize: ?f32 = null,
    lineHeight: ?f32 = null,
    textWrapping: ?TextWrapping = null,

    cursor: ?Cursor = null,

    overflow: ?Overflow = null,
    placement: ?Placement = null,
    zIndex: ?u16 = null,

    minWidth: ?f32 = null,
    maxWidth: ?f32 = null,
    width: ?Sizing = null,
    minHeight: ?f32 = null,
    maxHeight: ?f32 = null,
    height: ?Sizing = null,

    translate: ?Vec2 = null,

    padding: ?Padding = null,
    margin: ?Margin = null,

    xJustification: ?Alignment = null,
    yJustification: ?Alignment = null,
    direction: ?Direction = null,

    pub fn overwrite(self: @This(), other: @This()) @This() {
        return .{
            .background = self.background orelse other.background,
            .blendMode = self.blendMode orelse other.blendMode,
            .filter = self.filter orelse other.filter,

            .color = self.color orelse other.color,
            .borderRadius = self.borderRadius orelse other.borderRadius,
            .borderColor = self.borderColor orelse other.borderColor,
            .borderWidth = self.borderWidth orelse other.borderWidth,

            .shadow = if (self.shadow) |s| s else other.shadow,

            .font = self.font orelse other.font,
            .fontWeight = self.fontWeight orelse other.fontWeight,
            .fontSize = self.fontSize orelse other.fontSize,
            .lineHeight = self.lineHeight orelse other.lineHeight,
            .textWrapping = self.textWrapping orelse other.textWrapping,
            .cursor = self.cursor orelse other.cursor,

            .overflow = self.overflow orelse other.overflow,
            .placement = self.placement orelse other.placement,
            .zIndex = self.zIndex orelse other.zIndex,

            .minWidth = self.minWidth orelse other.minWidth,
            .maxWidth = self.maxWidth orelse other.maxWidth,
            .width = self.width orelse other.width,
            .minHeight = self.minHeight orelse other.minHeight,
            .maxHeight = self.maxHeight orelse other.maxHeight,
            .height = self.height orelse other.height,

            .translate = self.translate orelse other.translate,

            .padding = self.padding orelse other.padding,
            .margin = self.margin orelse other.margin,

            .xJustification = self.xJustification orelse other.xJustification,
            .yJustification = self.yJustification orelse other.yJustification,
            .direction = self.direction orelse other.direction,
        };
    }

    pub fn completeWith(self: @This(), base: BaseStyle) CompleteStyle {
        return CompleteStyle{
            .background = self.background orelse .{ .color = Vec4{ 0.0, 0.0, 0.0, 0.0 } },
            .blendMode = self.blendMode orelse base.blendMode,
            .filter = self.filter orelse base.filter,

            .color = self.color orelse base.color,

            .borderRadius = self.borderRadius orelse 0.0,
            .borderColor = self.borderColor orelse Vec4{ 0.0, 0.0, 0.0, 0.0 },
            .borderWidth = self.borderWidth orelse .all(0.0),

            .shadow = self.shadow,

            .font = self.font orelse base.font,
            .fontWeight = self.fontWeight orelse base.fontWeight,
            .fontSize = self.fontSize orelse base.fontSize,
            .lineHeight = self.lineHeight orelse base.lineHeight,
            .textWrapping = self.textWrapping orelse base.textWrapping,
            .cursor = self.cursor orelse base.cursor,

            .overflow = self.overflow orelse .visible,
            .placement = self.placement orelse .flow,
            .zIndex = self.zIndex,

            .minWidth = self.minWidth,
            .maxWidth = self.maxWidth,
            .width = self.width orelse .fit,

            .minHeight = self.minHeight,
            .maxHeight = self.maxHeight,
            .height = self.height orelse .fit,

            .translate = self.translate orelse @splat(0.0),

            .padding = self.padding orelse .all(0.0),
            .margin = self.margin orelse .all(0.0),

            .direction = self.direction orelse .horizontal,
            .xJustification = self.xJustification orelse .start,
            .yJustification = self.yJustification orelse .start,
        };
    }
};

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

/// Utilizies a flat tree structure where ndoes can reference one another by
/// using indices, this way keeping stable references without using pointers.
pub const NodeTree = struct {
    list: std.ArrayList(Node),

    pub const empty = @This(){ .list = .empty };

    pub const Walker = struct {
        start: usize,
        current: ?usize,
        tree: *const NodeTree,

        pub fn reset(self: *@This()) void {
            self.current = null;
        }

        fn nextOutside(self: *@This(), index: usize) ?usize {
            const node = self.tree.at(index);
            if (node.nextSibling) |nextSibling| {
                return nextSibling;
            } else if (node.parent) |parentIndex| {
                return self.nextOutside(parentIndex);
            } else {
                return null;
            }
        }

        pub fn next(self: *@This()) ?*Node {
            if (self.current) |current| {
                const node = self.tree.at(current);
                if (node.firstChild) |firstChild| {
                    self.current = firstChild;
                } else {
                    self.current = self.nextOutside(current);
                }
            } else {
                self.current = self.start;
            }

            const idx = self.current orelse return null;
            return self.tree.at(idx);
        }
    };

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.list.deinit(allocator);
    }

    pub fn clearRetainingCapacity(self: *@This()) void {
        self.list.clearRetainingCapacity();
    }

    pub fn walk(self: *@This()) Walker {
        return Walker{
            .start = 0,
            .current = null,
            .tree = self,
        };
    }

    pub fn at(self: @This(), index: usize) *Node {
        return &self.list.items[index];
    }

    pub fn dump(self: *const @This(), writer: *std.Io.Writer) !void {
        if (self.list.items.len > 0) {
            try self.list.items[0].layoutDump(writer, 0, 0);
            try writer.flush();
        }
    }

    pub fn putNode(
        self: *@This(),
        allocator: std.mem.Allocator,
        parentOpt: ?usize,
    ) !struct { ptr: *Node, index: usize } {
        const index = self.list.items.len;
        if (index != 0 and parentOpt == null) {
            return error.MultipleRootsAreNotAllowed;
        }

        var node = Node{
            .tree = self,

            .parent = parentOpt,
            .firstChild = null,
            .lastChild = null,
            .previousSibling = null,
            .nextSibling = null,

            .key = undefined,

            .position = undefined,
            .z = undefined,
            .size = undefined,
            .maxSize = undefined,
            .minSize = undefined,

            .style = undefined,
        };
        if (parentOpt) |parentIndex| {
            const parent = self.at(parentIndex);
            if (parent.lastChild) |old_last| {
                self.at(old_last).nextSibling = index;
            }
            node.previousSibling = parent.lastChild;
            if (parent.firstChild == null) {
                parent.firstChild = index;
            }
            parent.lastChild = index;
        }
        try self.list.append(allocator, node);
        return .{ .ptr = self.at(index), .index = index };
    }

    pub fn fitAncestors(self: *@This(), nodeIndex: usize, child: *const Node) void {
        var currentIndexOpt = self.at(nodeIndex).parent;
        while (currentIndexOpt) |currentIndex| {
            const current = self.at(currentIndex);
            current.fitChild(child);
            currentIndexOpt = current.parent;
        }
    }

    test {
        const gpa = std.testing.allocator;
        var tree = NodeTree.empty;
        defer tree.deinit(gpa);

        _ = try tree.putNode(gpa, null); // root 0
        _ = try tree.putNode(gpa, 0); // 1
        _ = try tree.putNode(gpa, 0); // 2
        _ = try tree.putNode(gpa, 1); // 3
        _ = try tree.putNode(gpa, 0); // 4
        _ = try tree.putNode(gpa, 1); // 5
        _ = try tree.putNode(gpa, 0); // 6
        _ = try tree.putNode(gpa, 0); // 7

        var walker = tree.walk();
        for (0..10) |_| {
            try std.testing.expect(walker.next() != null);
            try std.testing.expectEqual(0, walker.current);
            try std.testing.expect(walker.next() != null);
            try std.testing.expectEqual(1, walker.current);
            try std.testing.expect(walker.next() != null);
            try std.testing.expectEqual(3, walker.current);
            try std.testing.expect(walker.next() != null);
            try std.testing.expectEqual(5, walker.current);
            try std.testing.expect(walker.next() != null);
            try std.testing.expectEqual(2, walker.current);
            try std.testing.expect(walker.next() != null);
            try std.testing.expectEqual(4, walker.current);
            try std.testing.expect(walker.next() != null);
            try std.testing.expectEqual(6, walker.current);
            try std.testing.expect(walker.next() != null);
            try std.testing.expectEqual(7, walker.current);
            try std.testing.expect(walker.next() == null);
            try std.testing.expectEqual(null, walker.current);
        }
    }
};

pub const Node = struct {
    tree: *NodeTree,

    parent: ?usize = null,
    firstChild: ?usize = null,
    lastChild: ?usize = null,
    nextSibling: ?usize = null,
    previousSibling: ?usize = null,
    glyphs: ?Glyphs = null,

    key: u64,

    position: Vec2,
    z: u16,
    size: Vec2,
    maxSize: Vec2,
    minSize: Vec2,

    style: CompleteStyle,

    pub fn shouldFitMin(self: @This(), direction: Direction) bool {
        const preferredSize = self.style.getPreferredSize(direction);
        return preferredSize != .fixed and self.style.getMinSize(direction) == null;
    }

    pub fn fitChild(self: *@This(), child: *const Node) void {
        if (child.style.placement != .flow) return;

        // Early exit if parent doesn't fit in either direction
        const fitH = self.style.width == .fit or self.shouldFitMin(.horizontal);
        const fitV = self.style.height == .fit or self.shouldFitMin(.vertical);
        if (!fitH and !fitV) return;

        const wraps = self.style.overflow == .wrap and self.style.direction == .horizontal;

        inline for (Direction.array) |fitDirection| {
            const preferredSize = self.style.getPreferredSize(fitDirection);
            const layoutDirection = self.style.direction;
            const marginVector = child.style.margin.get(fitDirection);
            const margins = marginVector[0] + marginVector[1];

            const contribution = margins + child.getSize(fitDirection);
            // For vertical minSize: use max(size, minSize) to capture wrapped text height
            // For horizontal minSize: use minSize only to avoid unwrapped text width bloat
            // Text wrapping changes height, not width, so this distinction matters.
            const minContribution = margins + if (fitDirection == .vertical)
                @max(child.getSize(fitDirection), child.getMinSize(fitDirection))
            else
                child.getMinSize(fitDirection);

            if (layoutDirection == fitDirection) {
                if (wraps) {
                    // With wrapping, inline-axis min is the widest single
                    // child (any child could end up alone on a line).
                    if (preferredSize == .fit) {
                        self.setSize(fitDirection, @max(
                            self.getSize(fitDirection),
                            contribution + self.fittingBase(fitDirection),
                        ));
                    }
                    if (self.shouldFitMin(fitDirection)) {
                        self.setMinSize(fitDirection, @max(
                            self.getMinSize(fitDirection),
                            minContribution + self.fittingBase(fitDirection),
                        ));
                    }
                } else {
                    if (preferredSize == .fit) {
                        // TODO: ensure the max and min sizes here
                        self.addSize(fitDirection, contribution);
                    }
                    if (self.shouldFitMin(fitDirection)) {
                        // Main axis: use minSize to avoid unwrapped text bloat
                        self.addMinSize(fitDirection, minContribution);
                    }
                }
            } else {
                // cross axis fitting
                if (preferredSize == .fit) {
                    // TODO: ensure the max and min sizes here
                    self.setSize(fitDirection, @max(
                        contribution + self.fittingBase(fitDirection),
                        self.getSize(fitDirection),
                    ));
                }
                if (self.shouldFitMin(fitDirection)) {
                    self.setMinSize(fitDirection, @max(
                        minContribution + self.fittingBase(fitDirection),
                        self.getMinSize(fitDirection),
                    ));
                }
            }
        }
    }

    /// The size of the element + the margins around it
    pub fn getOuterSize(self: @This(), direction: Direction) f32 {
        return self.getSize(direction) + self.style.margin.get(direction)[0] + self.style.margin.get(direction)[1];
    }

    pub fn fittingBase(self: @This(), direction: Direction) f32 {
        const paddingVector = self.style.padding.get(direction);
        const padding = paddingVector[0] + paddingVector[1];

        const borderWidthVector = self.style.borderWidth.get(direction);
        const border = borderWidthVector[0] + borderWidthVector[1];

        return padding + border;
    }

    pub fn debugPrint(self: @This(), indent: usize) void {
        for (0..indent) |_| {
            std.debug.print("  ", .{});
        }
        std.debug.print("node (key: {}, pos: {}, size: {}, z: {})\n", .{ self.key, self.position, self.size, self.z });
        if (self.glyphs) |glyphs| {
            for (glyphs.slice) |glyph| {
                for (0..indent + 1) |_| {
                    std.debug.print("  ", .{});
                }
                std.debug.print("Glyph (index: {}, pos: {}, text: \"{s}\")\n", .{ glyph.index, glyph.position, glyph.text });
            }
        }
        var childIndex = self.firstChild;
        while (childIndex) |idx| {
            const child = self.tree.at(idx);
            child.debugPrint(indent + 1);
            childIndex = child.nextSibling;
        }
    }

    fn formatSizing(sizing: Sizing) [24]u8 {
        var buf: [24]u8 = undefined;
        @memset(&buf, 0);
        const result = switch (sizing) {
            .fit => std.fmt.bufPrint(&buf, "fit", .{}),
            .grow => std.fmt.bufPrint(&buf, "grow", .{}),
            .fixed => |v| std.fmt.bufPrint(&buf, "fixed({d:.1})", .{v}),
            .ratio => |v| std.fmt.bufPrint(&buf, "ratio({d:.2})", .{v}),
        };
        _ = result catch {};
        return buf;
    }

    fn writeIndent(writer: *std.Io.Writer, indent: usize) !void {
        for (0..indent) |_| {
            try writer.writeAll("  ");
        }
    }

    pub fn layoutDump(self: *const @This(), writer: *std.Io.Writer, idx: usize, indent: usize) !void {
        // Line 1: index, direction, overflow, placement
        try writeIndent(writer, indent);
        try writer.print("[{d}] dir={s}  overflow={s}  placement={s}\n", .{
            idx,
            @tagName(self.style.direction),
            @tagName(self.style.overflow),
            @tagName(self.style.placement),
        });

        // Line 2: sizing, justification
        try writeIndent(writer, indent);
        const wBuf = formatSizing(self.style.width);
        const hBuf = formatSizing(self.style.height);
        try writer.print("  w={s}  h={s}  justification={s},{s}\n", .{
            std.mem.sliceTo(&wBuf, 0),
            std.mem.sliceTo(&hBuf, 0),
            @tagName(self.style.xJustification),
            @tagName(self.style.yJustification),
        });

        // Line 3: size, min, max
        try writeIndent(writer, indent);
        try writer.print("  size=[{d:.1}, {d:.1}]  min=[{d:.1}, {d:.1}]  max=[{d:.1}, {d:.1}]\n", .{
            self.size[0],    self.size[1],
            self.minSize[0], self.minSize[1],
            self.maxSize[0], self.maxSize[1],
        });

        // Line 4: position
        try writeIndent(writer, indent);
        try writer.print("  pos=[{d:.1}, {d:.1}]\n", .{ self.position[0], self.position[1] });

        // Line 5: padding, margin
        try writeIndent(writer, indent);
        try writer.print("  padding=x[{d:.1},{d:.1}] y[{d:.1},{d:.1}]  margin=x[{d:.1},{d:.1}] y[{d:.1},{d:.1}]\n", .{
            self.style.padding.x[0], self.style.padding.x[1],
            self.style.padding.y[0], self.style.padding.y[1],
            self.style.margin.x[0],  self.style.margin.x[1],
            self.style.margin.y[0],  self.style.margin.y[1],
        });

        // Line 6: fittingBase
        try writeIndent(writer, indent);
        try writer.print("  fittingBase: x={d:.1}  y={d:.1}\n", .{
            self.fittingBase(.horizontal),
            self.fittingBase(.vertical),
        });

        // Line 7: glyphs (if present)
        if (self.glyphs) |glyphs| {
            var lineCount: usize = 1;
            if (glyphs.slice.len > 0) {
                var prevY = glyphs.slice[0].position[1];
                for (glyphs.slice[1..]) |glyph| {
                    if (glyph.position[1] != prevY) {
                        lineCount += 1;
                        prevY = glyph.position[1];
                    }
                }
            } else {
                lineCount = 0;
            }
            try writeIndent(writer, indent);
            try writer.print("  glyphs={d} ({d} lines)\n", .{ glyphs.slice.len, lineCount });
        }

        // Recurse into children
        var childIdx = self.firstChild;
        while (childIdx) |ci| {
            const child = self.tree.at(ci);
            try child.layoutDump(writer, ci, indent + 1);
            childIdx = child.nextSibling;
        }
    }

    pub fn setMinSize(self: *@This(), direction: Direction, size: f32) void {
        if (direction == .horizontal) {
            self.minSize[0] = size;
        } else {
            self.minSize[1] = size;
        }
    }

    pub fn addMinSize(self: *@This(), direction: Direction, increment: f32) void {
        if (direction == .horizontal) {
            self.minSize[0] += increment;
        } else {
            self.minSize[1] += increment;
        }
    }

    pub fn setSize(self: *@This(), direction: Direction, size: f32) void {
        if (direction == .horizontal) {
            self.size[0] = size;
        } else {
            self.size[1] = size;
        }
    }

    pub fn addSize(self: *@This(), direction: Direction, increment: f32) void {
        if (direction == .horizontal) {
            self.size[0] += increment;
        } else {
            self.size[1] += increment;
        }
    }

    pub fn getMinSize(self: @This(), direction: Direction) f32 {
        if (direction == .horizontal) {
            return self.minSize[0];
        }
        return self.minSize[1];
    }

    pub fn getMaxSize(self: @This(), direction: Direction) f32 {
        if (direction == .horizontal) {
            return self.maxSize[0];
        }
        return self.maxSize[1];
    }

    pub fn getSize(self: @This(), direction: Direction) f32 {
        if (direction == .horizontal) {
            return self.size[0];
        }
        return self.size[1];
    }
};

pub const Element = struct {
    style: Style,
    children: std.ArrayList(Node) = .empty,
};
