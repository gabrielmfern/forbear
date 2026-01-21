const std = @import("std");
const builtin = @import("builtin");

pub const c = @import("c.zig").c;
pub const Font = @import("font.zig");
pub const Graphics = @import("graphics.zig");
pub const Image = @import("graphics.zig").Image;
const layouting = @import("layouting.zig");
pub const layout = layouting.layout;
pub const LayoutBox = layouting.LayoutBox;
const nodeImport = @import("node.zig");
pub const Node = nodeImport.Node;
pub const Component = nodeImport.Component;
pub const component = nodeImport.component;
pub const ComponentProps = nodeImport.ComponentProps;
pub const Element = nodeImport.Element;
pub const ElementProps = nodeImport.DivProps;
pub const div = nodeImport.div;
pub const children = nodeImport.children;
pub const Window = @import("window/root.zig").Window;

const Vec2 = @Vector(2, f32);

const Context = @This();

var context: ?@This() = null;

allocator: std.mem.Allocator,
mousePosition: Vec2,
hoveredElementKey: ?u64,

// TODO: The alignment here is probably messed up, we should find a way to fix
// it later
/// A literal string of bytes that have the size of some state, and the
componentStates: std.AutoHashMap(u64, []align(@alignOf(usize)) u8),
componentResolutionState: ?ComponentResolutionState,

const ComponentResolutionState = struct {
    stateByteCursor: usize,
    key: u64,
};

pub fn init(allocator: std.mem.Allocator) !void {
    if (context != null) {
        return error.AlreadyInitialized;
    }

    context = @This(){
        .mousePosition = .{ 0.0, 0.0 },
        .hoveredElementKey = null,
        .allocator = allocator,
        .componentStates = .init(allocator),
        .componentResolutionState = null,
    };
}

const TreeNode = struct {
    key: u64,
    node: Node,
};

const Resolver = struct {
    path: []usize,

    fn resolve(self: @This(), node: Node) !TreeNode {
        const forbear = getContext();

        var hasher = std.hash.Wyhash.init(0);
        hasher.update(std.mem.asBytes(self.path.items));
        switch (node) {
            .component => |comp| {
                hasher.update(std.mem.asBytes(&comp.id));
                const key = hasher.final();

                const previousComponentResolutionState = forbear.componentResolutionState;
                forbear.componentResolutionState = .{
                    .key = key,
                    .stateByteCursor = 0,
                };
                const componentNode = try comp.function(comp.props);
                forbear.componentResolutionState = previousComponentResolutionState;
                return .{
                    .key = key,
                    .node = componentNode,
                };
            },
            .element => {
                // you are here: starting to implement the recursivity of
                // component resolution. you just finished implementing
                // components being called themselves jkust above
                for (node.element.children) || {
                }
                return .{
                    .key = hasher.final(),
                    .node = node,
                };
            },
            .text => |text| {
                hasher.update(text);
                return .{
                    .key = hasher.final(),
                    .node = node,
                };
            },
        }
    }
};

pub fn resolve(node: Node) TreeNode {
}

const stateAlignment: std.mem.Alignment = .@"8";

// TODO: in debug mode, we should be adding some guard rail here to make sure
// of warning the user if they called the hook in an unexpected order, as it
// can cause undefined behavior as is right now
pub fn useState(T: type, initialValue: T) !*T {
    const self = getContext();
    if (self.componentResolutionState) |*state| {
        const stateResult = try self.componentStates.getOrPut(state.key);
        const alignedCursor = std.mem.alignForward(usize, state.stateByteCursor, @alignOf(T));
        const requiredLen = alignedCursor + @sizeOf(T);
        defer state.stateByteCursor = requiredLen;
        if (stateResult.found_existing) {
            if (alignedCursor < stateResult.value_ptr.*.len) {
                return @ptrCast(@alignCast(stateResult.value_ptr.*[alignedCursor..requiredLen]));
            }
            stateResult.value_ptr.* = try self.allocator.realloc(stateResult.value_ptr.*, requiredLen);
        } else {
            stateResult.value_ptr.* = try self.allocator.alignedAlloc(u8, stateAlignment, requiredLen);
        }
        @memcpy(
            stateResult.value_ptr.*[alignedCursor..requiredLen],
            std.mem.asBytes(&initialValue),
        );
        return @ptrCast(@alignCast(stateResult.value_ptr.*[alignedCursor..requiredLen]));
    } else {
        if (!builtin.is_test) {
            std.log.err("You might be calling useState outside of a component, and forbear cannot track state there.", .{});
        }
        return error.NoComponentContext;
    }
}

test "State creation with manual handling" {
    try init(std.testing.allocator);
    defer deinit();
    const self = getContext();
    {
        // First run that should allocate RAM, and still allow reading and writing the values
        self.componentResolutionState = ComponentResolutionState{
            .stateByteCursor = 0,
            .key = 1,
        };
        const state1 = try useState(i32, 42);
        try std.testing.expectEqual(@sizeOf(i32), self.componentStates.get(1).?.len);
        const state2 = try useState(f32, 3.14);
        try std.testing.expectEqual(@sizeOf(i32) + @sizeOf(f32), self.componentStates.get(1).?.len);
        try std.testing.expectEqual(42, state1.*);
        try std.testing.expectEqual(3.14, state2.*);
        state1.* = 100;
        state2.* = 6.28;
        try std.testing.expectEqual(100, state1.*);
        try std.testing.expectEqual(6.28, state2.*);
    }
    {
        // Second run that should not allcoate new memory
        self.componentResolutionState = ComponentResolutionState{
            .stateByteCursor = 0,
            .key = 1,
        };
        const state1 = try useState(i32, 42);
        try std.testing.expectEqual(@sizeOf(i32) + @sizeOf(f32), self.componentStates.get(1).?.len);
        const state2 = try useState(f32, 3.14);
        try std.testing.expectEqual(@sizeOf(i32) + @sizeOf(f32), self.componentStates.get(1).?.len);
        try std.testing.expectEqual(100, state1.*);
        try std.testing.expectEqual(6.28, state2.*);
    }
    {
        self.componentResolutionState = null;
        try std.testing.expectError(error.NoComponentContext, useState(i32, 42));
    }
}

pub fn update(root: *const LayoutBox, arena: std.mem.Allocator) !void {
    const self = getContext();

    var iterator = try layouting.LayoutTreeIterator.init(arena, root);
    var previouslyHoveredLayoutBox: ?*const LayoutBox = null;

    var highestHoveredLayoutBox: ?*const LayoutBox = null;
    while (try iterator.next()) |layoutBox| {
        if (layoutBox.position[0] <= self.mousePosition[0] and layoutBox.position[1] <= self.mousePosition[1] and layoutBox.position[0] + layoutBox.size[0] >= self.mousePosition[0] and layoutBox.position[1] + layoutBox.size[1] >= self.mousePosition[1]) {
            if (highestHoveredLayoutBox) |hoveredBox| {
                if (layoutBox.z > hoveredBox.z) {
                    highestHoveredLayoutBox = layoutBox;
                }
            } else {
                highestHoveredLayoutBox = layoutBox;
            }
        }
        if (layoutBox.key == self.hoveredElementKey) {
            previouslyHoveredLayoutBox = layoutBox;
        }
    }
    if (highestHoveredLayoutBox) |hoveredBox| {
        if (hoveredBox.key != self.hoveredElementKey) {
            if (previouslyHoveredLayoutBox) |prevBox| {
                if (prevBox.handlers.onMouseOut) |onMouseOut| {
                    try onMouseOut.handler(self.mousePosition, onMouseOut.data);
                }
            }
        }
        if (hoveredBox.handlers.onMouseOver) |onMouseOver| {
            try onMouseOver.handler(self.mousePosition, onMouseOver.data);
            self.hoveredElementKey = hoveredBox.key;
        }
    }
}

pub fn setHandlers(window: *Window) void {
    const self = getContext();

    window.setPointerMotion(
        &(struct {
            fn handler(_: *Window, time: u32, x: i32, y: i32, data: *anyopaque) void {
                _ = time;
                const ctx: *Context = @ptrCast(@alignCast(data));
                ctx.mousePosition = .{ @floatFromInt(x), @floatFromInt(y) };
            }
        }).handler,
        @ptrCast(@alignCast(self)),
    );
}

pub fn deinit() void {
    const self = getContext();
    std.debug.assert(self.componentResolutionState == null);
    var nodeStatesIterator = self.componentStates.valueIterator();
    while (nodeStatesIterator.next()) |states| {
        self.allocator.free(states.*);
    }
    self.componentStates.deinit();
    context = null;
}

pub fn getContext() *@This() {
    return &context.?;
}
